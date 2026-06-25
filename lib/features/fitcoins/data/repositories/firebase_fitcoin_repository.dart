import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_transaction.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_wallet.dart';
import 'package:fitup/features/fitcoins/domain/repositories/fitcoin_repository.dart';
import 'package:fitup/services/logger_service.dart';

Failure _mapErr(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

String _safeId(String key) => key.replaceAll('/', '_');

/// Firestore wallet + transactions; Drift mirror when [database] is non-null.
class FirebaseFitcoinRepository implements FitcoinRepository {
  FirebaseFitcoinRepository(
    this._firestore, {
    FitupDatabase? database,
  }) : _db = database;

  final FirebaseFirestore _firestore;
  final FitupDatabase? _db;

  DocumentReference<Map<String, dynamic>> _walletRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('fitcoin_wallet').doc('wallet');

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('fitcoin_transactions');

  CollectionReference<Map<String, dynamic>> _awardsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('fitcoin_awards');

  FitcoinWallet _walletFromDoc(String userId, DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic>? m = d.data();
    return FitcoinWallet(
      userId: userId,
      balance: (m?['balance'] as num?)?.toInt() ?? 0,
      totalEarned: (m?['totalEarned'] as num?)?.toInt() ?? 0,
      totalSpent: (m?['totalSpent'] as num?)?.toInt() ?? 0,
      updatedAt: (m?['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  FitcoinTransaction _txFromDoc(
    String userId,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final Map<String, dynamic> m = d.data();
    return FitcoinTransaction(
      id: d.id,
      userId: userId,
      type: TransactionType.values.firstWhere(
        (TransactionType e) => e.name == (m['type'] as String? ?? 'earned'),
        orElse: () => TransactionType.earned,
      ),
      source: m['source'] != null
          ? EarnSource.values.firstWhere(
              (EarnSource e) => e.name == m['source'],
              orElse: () => EarnSource.manualBonus,
            )
          : null,
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      description: m['description'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      synced: true,
    );
  }

  FitcoinTransaction _txFromCacheRow(FitcoinTransactionCacheRow r) {
    return FitcoinTransaction(
      id: r.id,
      userId: r.userId,
      type: TransactionType.values.firstWhere(
        (TransactionType e) => e.name == r.type,
        orElse: () => TransactionType.earned,
      ),
      source: r.source != null
          ? EarnSource.values.firstWhere(
              (EarnSource e) => e.name == r.source,
              orElse: () => EarnSource.manualBonus,
            )
          : null,
      amount: r.amount,
      description: r.description,
      createdAt: r.createdAt,
      synced: r.synced,
    );
  }

  Future<void> _mirrorWalletToDrift(FitcoinWallet w, {required bool synced}) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    await db.into(db.fitcoinWalletCache).insertOnConflictUpdate(
          FitcoinWalletCacheCompanion.insert(
            userId: w.userId,
            balance: w.balance,
            totalEarned: w.totalEarned,
            totalSpent: w.totalSpent,
            updatedAt: w.updatedAt,
            synced: Value<bool>(synced),
          ),
        );
  }

  Future<void> _mirrorTxToDrift(
    FitcoinTransaction t, {
    String? idempotencyKey,
    required bool synced,
  }) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    await db.into(db.fitcoinTransactionsCache).insertOnConflictUpdate(
          FitcoinTransactionsCacheCompanion.insert(
            id: t.id,
            userId: t.userId,
            type: t.type.name,
            source: Value<String?>(t.source?.name),
            amount: t.amount,
            description: t.description,
            createdAt: t.createdAt,
            idempotencyKey: Value<String?>(idempotencyKey),
            synced: Value<bool>(synced),
          ),
        );
  }

  Future<void> _mirrorIdempotency(
    String userId,
    String key,
    String transactionId,
    DateTime at,
  ) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    await db.into(db.fitcoinIdempotencyCache).insertOnConflictUpdate(
          FitcoinIdempotencyCacheCompanion.insert(
            keyId: key,
            userId: userId,
            transactionId: transactionId,
            createdAt: at,
          ),
        );
  }

  @override
  Future<Either<Failure, FitcoinWallet>> getWallet(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> d =
          await _walletRef(userId).get();
      if (!d.exists) {
        final FitcoinWallet w = FitcoinWallet(
          userId: userId,
          balance: 0,
          totalEarned: 0,
          totalSpent: 0,
          updatedAt: DateTime.now(),
        );
        await _mirrorWalletToDrift(w, synced: false);
        return Right<Failure, FitcoinWallet>(w);
      }
      final FitcoinWallet w = _walletFromDoc(userId, d);
      await _mirrorWalletToDrift(w, synced: true);
      return Right<Failure, FitcoinWallet>(w);
    } catch (e, st) {
      LoggerService.e('getWallet', e, st);
      final FitupDatabase? db = _db;
      if (db != null) {
        final FitcoinWalletCacheRow? row = await (db.select(db.fitcoinWalletCache)
              ..where(($FitcoinWalletCacheTable t) => t.userId.equals(userId)))
            .getSingleOrNull();
        if (row != null) {
          return Right<Failure, FitcoinWallet>(
            FitcoinWallet(
              userId: row.userId,
              balance: row.balance,
              totalEarned: row.totalEarned,
              totalSpent: row.totalSpent,
              updatedAt: row.updatedAt,
            ),
          );
        }
      }
      return Left<Failure, FitcoinWallet>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, List<FitcoinTransaction>>> getTransactions(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _txCol(userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final List<FitcoinTransaction> list = snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) => _txFromDoc(userId, d))
          .toList();
      return Right<Failure, List<FitcoinTransaction>>(list);
    } catch (e, st) {
      LoggerService.e('getTransactions', e, st);
      final FitupDatabase? db = _db;
      if (db != null) {
        final List<FitcoinTransactionCacheRow> rows =
            await (db.select(db.fitcoinTransactionsCache)
                  ..where(($FitcoinTransactionsCacheTable t) => t.userId.equals(userId))
                  ..orderBy(<OrderClauseGenerator<$FitcoinTransactionsCacheTable>>[
                    ($FitcoinTransactionsCacheTable t) => OrderingTerm(
                          expression: t.createdAt,
                          mode: OrderingMode.desc,
                        ),
                  ])
                  ..limit(limit))
                .get();
        return Right<Failure, List<FitcoinTransaction>>(
          rows.map(_txFromCacheRow).toList(),
        );
      }
      return Left<Failure, List<FitcoinTransaction>>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, FitcoinTransaction>> awardCoins({
    required String userId,
    required EarnSource source,
    required int amount,
    required String description,
    String? idempotencyKey,
  }) async {
    if (amount <= 0) {
      return Left<Failure, FitcoinTransaction>(
        ValidationFailure('Amount must be positive'),
      );
    }
    final String? safeKey =
        idempotencyKey != null ? _safeId(idempotencyKey) : null;
    final FitupDatabase? db = _db;
    if (db != null && safeKey != null) {
      final FitcoinIdempotencyCacheRow? idr =
          await (db.select(db.fitcoinIdempotencyCache)
                ..where(($FitcoinIdempotencyCacheTable t) => t.keyId.equals(safeKey)))
              .getSingleOrNull();
      if (idr != null) {
        final FitcoinTransactionCacheRow? tr =
            await (db.select(db.fitcoinTransactionsCache)
                  ..where(($FitcoinTransactionsCacheTable t) => t.id.equals(idr.transactionId)))
                .getSingleOrNull();
        if (tr != null) {
          return Right<Failure, FitcoinTransaction>(_txFromCacheRow(tr));
        }
      }
    }

    final String txId = 'fc_${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final DateTime now = DateTime.now();

    try {
      bool duplicate = false;
      await _firestore.runTransaction((Transaction t) async {
        final DocumentReference<Map<String, dynamic>> walletDoc =
            _walletRef(userId);
        if (safeKey != null) {
          final DocumentReference<Map<String, dynamic>> awardDoc =
              _awardsCol(userId).doc(safeKey);
          final DocumentSnapshot<Map<String, dynamic>> ad = await t.get(awardDoc);
          if (ad.exists) {
            duplicate = true;
            return;
          }
        }

        final DocumentSnapshot<Map<String, dynamic>> w = await t.get(walletDoc);
        final int bal = (w.data()?['balance'] as num?)?.toInt() ?? 0;
        final int earned = (w.data()?['totalEarned'] as num?)?.toInt() ?? 0;
        final int spent = (w.data()?['totalSpent'] as num?)?.toInt() ?? 0;

        t.set(
          walletDoc,
          <String, dynamic>{
            'userId': userId,
            'balance': bal + amount,
            'totalEarned': earned + amount,
            'totalSpent': spent,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        t.set(_txCol(userId).doc(txId), <String, dynamic>{
          'type': TransactionType.earned.name,
          'source': source.name,
          'amount': amount,
          'description': description,
          'createdAt': Timestamp.fromDate(now),
        });

        if (safeKey != null) {
          t.set(
            _awardsCol(userId).doc(safeKey),
            <String, dynamic>{
              'transactionId': txId,
              'createdAt': Timestamp.fromDate(now),
            },
          );
        }
      });

      if (duplicate && safeKey != null) {
        final DocumentSnapshot<Map<String, dynamic>> ar =
            await _awardsCol(userId).doc(safeKey).get();
        final String? tid = ar.data()?['transactionId'] as String?;
        if (tid != null) {
          final DocumentSnapshot<Map<String, dynamic>> tr =
              await _txCol(userId).doc(tid).get();
          if (tr.exists) {
            final FitcoinTransaction out = FitcoinTransaction(
              id: tid,
              userId: userId,
              type: TransactionType.earned,
              source: source,
              amount: amount,
              description: description,
              createdAt: (tr.data()?['createdAt'] as Timestamp?)?.toDate() ?? now,
              synced: true,
            );
            await _mirrorTxToDrift(out, idempotencyKey: safeKey, synced: true);
            await _mirrorIdempotency(userId, safeKey, tid, out.createdAt);
            return Right<Failure, FitcoinTransaction>(out);
          }
        }
        return Left<Failure, FitcoinTransaction>(
          ValidationFailure('Duplicate award'),
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> wSnap =
          await _walletRef(userId).get();
      final FitcoinWallet w = _walletFromDoc(userId, wSnap);
      await _mirrorWalletToDrift(w, synced: true);

      final FitcoinTransaction out = FitcoinTransaction(
        id: txId,
        userId: userId,
        type: TransactionType.earned,
        source: source,
        amount: amount,
        description: description,
        createdAt: now,
        synced: true,
      );
      await _mirrorTxToDrift(out, idempotencyKey: safeKey, synced: true);
      if (safeKey != null) {
        await _mirrorIdempotency(userId, safeKey, txId, now);
      }
      return Right<Failure, FitcoinTransaction>(out);
    } catch (e, st) {
      LoggerService.e('awardCoins', e, st);
      return Left<Failure, FitcoinTransaction>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, FitcoinTransaction>> redeemCoins({
    required String userId,
    required int amount,
    required String description,
  }) async {
    if (amount <= 0) {
      return Left<Failure, FitcoinTransaction>(
        ValidationFailure('Amount must be positive'),
      );
    }
    final String txId = 'fr_${userId}_${DateTime.now().microsecondsSinceEpoch}';
    final DateTime now = DateTime.now();
    try {
      await _firestore.runTransaction((Transaction t) async {
        final DocumentReference<Map<String, dynamic>> walletDoc =
            _walletRef(userId);
        final DocumentSnapshot<Map<String, dynamic>> w = await t.get(walletDoc);
        final int bal = (w.data()?['balance'] as num?)?.toInt() ?? 0;
        if (bal < amount) {
          throw InsufficientBalanceFailure(
            currentBalance: bal,
            required: amount,
          );
        }
        final int earned = (w.data()?['totalEarned'] as num?)?.toInt() ?? 0;
        final int spent = (w.data()?['totalSpent'] as num?)?.toInt() ?? 0;

        t.set(
          walletDoc,
          <String, dynamic>{
            'userId': userId,
            'balance': bal - amount,
            'totalEarned': earned,
            'totalSpent': spent + amount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        t.set(_txCol(userId).doc(txId), <String, dynamic>{
          'type': TransactionType.redeemed.name,
          'amount': amount,
          'description': description,
          'createdAt': Timestamp.fromDate(now),
        });
      });

      final DocumentSnapshot<Map<String, dynamic>> wSnap =
          await _walletRef(userId).get();
      final FitcoinWallet w = _walletFromDoc(userId, wSnap);
      await _mirrorWalletToDrift(w, synced: true);

      final FitcoinTransaction out = FitcoinTransaction(
        id: txId,
        userId: userId,
        type: TransactionType.redeemed,
        source: null,
        amount: amount,
        description: description,
        createdAt: now,
        synced: true,
      );
      await _mirrorTxToDrift(out, synced: true);
      return Right<Failure, FitcoinTransaction>(out);
    } catch (e, st) {
      LoggerService.e('redeemCoins', e, st);
      if (e is InsufficientBalanceFailure) {
        return Left<Failure, FitcoinTransaction>(e);
      }
      return Left<Failure, FitcoinTransaction>(_mapErr(e));
    }
  }

  @override
  Stream<FitcoinWallet> watchWallet(String userId) {
    return _walletRef(userId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> d) {
        if (!d.exists) {
          return FitcoinWallet(
            userId: userId,
            balance: 0,
            totalEarned: 0,
            totalSpent: 0,
            updatedAt: DateTime.now(),
          );
        }
        return _walletFromDoc(userId, d);
      },
    );
  }

  @override
  Stream<List<FitcoinTransaction>> watchTransactions(
    String userId, {
    int limit = 40,
  }) {
    return _txCol(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    _txFromDoc(userId, d),
              )
              .toList(),
        );
  }
}
