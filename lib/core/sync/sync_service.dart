import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_transaction.dart';
import 'package:fitup/features/fitcoins/domain/services/fitcoin_award_service.dart';
import 'package:fitup/features/profile/domain/repositories/profile_repository.dart';
import 'package:fitup/services/logger_service.dart';

/// Retries [ProfileRepository.flushPendingProfileToRemote] when connectivity returns.
class SyncService {
  SyncService(
    this._profileRepository,
    this._connectivity,
    this._firestore,
    {
    FitcoinAwardService? fitcoinAwardService,
    FitupDatabase? database,
  })  : _fitcoinAwardService = fitcoinAwardService,
        _db = database;

  final ProfileRepository _profileRepository;
  final Connectivity _connectivity;
  final FirebaseFirestore _firestore;
  final FitcoinAwardService? _fitcoinAwardService;
  final FitupDatabase? _db;

  final Set<String> _pendingProfileUserIds = <String>{};
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncingPendingAwards = false;

  /// Enqueue after a Firestore write failed but local cache was updated.
  void enqueueProfileSync(String userId) {
    _pendingProfileUserIds.add(userId);
    unawaited(_tryFlushProfile(userId));
  }

  void startListening() {
    _sub?.cancel();
    _sub = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> r) {
      if (_isOnline(r)) {
        for (final String uid in _pendingProfileUserIds.toList()) {
          unawaited(_tryFlushProfile(uid));
        }
        unawaited(syncPendingAwards());
        unawaited(syncPendingActivityAndSleep());
      }
    });
    unawaited(syncPendingActivityAndSleep());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
  }

  bool _isOnline(List<ConnectivityResult> r) {
    return r.any(
      (ConnectivityResult c) =>
          c != ConnectivityResult.none && c != ConnectivityResult.bluetooth,
    );
  }

  Future<void> _tryFlushProfile(String userId) async {
    if (!_pendingProfileUserIds.contains(userId)) {
      return;
    }
    final List<ConnectivityResult> check = await _connectivity.checkConnectivity();
    if (!_isOnline(check)) {
      return;
    }
    final Either<Failure, Unit> r =
        await _profileRepository.flushPendingProfileToRemote(userId);
    r.fold(
      (Failure f) {
        LoggerService.w('flushPendingProfileToRemote', f.message ?? f.toString());
      },
      (_) {
        _pendingProfileUserIds.remove(userId);
      },
    );
  }

  /// Retries any queued Fitcoin awards. Called when connectivity restores.
  Future<void> syncPendingAwards() async {
    if (_db == null || _fitcoinAwardService == null) {
      return;
    }
    if (_syncingPendingAwards) {
      return;
    }
    final FitupDatabase db = _db;
    final FitcoinAwardService awardService = _fitcoinAwardService;
    _syncingPendingAwards = true;
    try {
      final List<FitcoinAwardQueueData> pending = await (db
              .select(db.fitcoinAwardQueue)
                ..where(
                  ($FitcoinAwardQueueTable t) =>
                      t.retryCount.isSmallerOrEqualValue(10),
                ))
          .get();

      for (final FitcoinAwardQueueData award in pending) {
        final EarnSource source = EarnSource.values.firstWhere(
          (EarnSource e) => e.name == award.source,
          orElse: () => EarnSource.manualBonus,
        );

        final Either<Failure, FitcoinTransaction> result =
            await awardService.awardCoins(
              userId: award.userId,
              source: source,
              amount: award.amount,
              description: award.description,
              idempotencyKey: award.idempotencyKey,
            );

        await result.fold(
          (Failure _) async {
            // For duplicates / validation errors, stop retrying.
            await _removeAward(db, award.idempotencyKey);
          },
          (FitcoinTransaction tx) async {
            if (tx.synced) {
              await _removeAward(db, award.idempotencyKey);
            } else {
              await _incrementOrRemoveAward(db, award);
            }
          },
        );
      }
    } catch (e, st) {
      LoggerService.e('syncPendingAwards', e, st);
    } finally {
      _syncingPendingAwards = false;
    }
  }

  Future<void> _incrementOrRemoveAward(
    FitupDatabase db,
    FitcoinAwardQueueData award,
  ) async {
    final int next = award.retryCount + 1;
    if (next >= 10) {
      await _removeAward(db, award.idempotencyKey);
      return;
    }
    await (db.update(db.fitcoinAwardQueue)..where(
      ($FitcoinAwardQueueTable t) => t.idempotencyKey.equals(award.idempotencyKey)))
        .write(
      FitcoinAwardQueueCompanion(
        retryCount: Value<int>(next),
      ),
    );
  }

  Future<void> _removeAward(FitupDatabase db, String idempotencyKey) async {
    await (db.delete(db.fitcoinAwardQueue)
          ..where(
            ($FitcoinAwardQueueTable t) =>
                t.idempotencyKey.equals(idempotencyKey),
          ))
        .go();

    // Remove only pending transactions to avoid altering already synced rows.
    await (db.delete(db.fitcoinTransactionsCache)
          ..where(
            ($FitcoinTransactionsCacheTable t) =>
                t.idempotencyKey.equals(idempotencyKey) &
                t.synced.equals(false),
          ))
        .go();
  }

  /// Flushes queued offline activity/sleep writes to Firestore.
  Future<void> syncPendingActivityAndSleep() async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    try {
      final List<SyncQueueRow> pending = await (db.select(db.syncQueue)
            ..where(
              ($SyncQueueTable t) =>
                  t.resourceType.equals('activity') |
                  t.resourceType.equals('sleep'),
            ))
          .get();
      for (final SyncQueueRow row in pending) {
        final Map<String, dynamic> payload =
            _decodeAndHydrateTimestamps(row.payloadJson, row.resourceType);
        try {
          if (row.resourceType == 'activity') {
            await _firestore
                .collection('users')
                .doc(row.userId)
                .collection('activities')
                .doc(row.id)
                .set(payload, SetOptions(merge: true));
            await (db.update(db.activities)
                  ..where(($ActivitiesTable t) => t.id.equals(row.id)))
                .write(const ActivitiesCompanion(synced: Value<bool>(true)));
          } else {
            await _firestore
                .collection('users')
                .doc(row.userId)
                .collection('sleepLogs')
                .doc(row.id)
                .set(payload, SetOptions(merge: true));
            await (db.update(db.sleepLogs)
                  ..where(($SleepLogsTable t) => t.id.equals(row.id)))
                .write(const SleepLogsCompanion(synced: Value<bool>(true)));
          }
          await (db.delete(db.syncQueue)
                ..where(($SyncQueueTable t) => t.id.equals(row.id)))
              .go();
        } catch (e, st) {
          LoggerService.e('syncPendingActivityAndSleep row=${row.id}', e, st);
        }
      }
    } catch (e, st) {
      LoggerService.e('syncPendingActivityAndSleep', e, st);
    }
  }

  Map<String, dynamic> _decodeAndHydrateTimestamps(
    String payloadJson,
    String resourceType,
  ) {
    final Map<String, dynamic> map =
        (jsonDecode(payloadJson) as Map).cast<String, dynamic>();
    if (resourceType == 'activity') {
      _coerceTimestampField(map, 'startTime');
      _coerceTimestampField(map, 'endTime');
      _coerceTimestampField(map, 'createdAt');
      _coerceTimestampField(map, 'updatedAt');
    } else if (resourceType == 'sleep') {
      _coerceTimestampField(map, 'bedtime');
      _coerceTimestampField(map, 'wakeTime');
      _coerceTimestampField(map, 'createdAt');
      _coerceTimestampField(map, 'updatedAt');
    }
    return map;
  }

  void _coerceTimestampField(Map<String, dynamic> map, String key) {
    final dynamic value = map[key];
    if (value is int) {
      map[key] = Timestamp.fromMillisecondsSinceEpoch(value);
    } else if (value is num) {
      map[key] = Timestamp.fromMillisecondsSinceEpoch(value.toInt());
    }
  }
}
