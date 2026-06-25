import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitup/features/activity/domain/entities/activity.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_transaction.dart';
import 'package:fitup/features/fitcoins/domain/repositories/fitcoin_repository.dart';
import 'package:fitup/services/logger_service.dart';

/// Awards Fitcoins from cross-module hooks. Failures are logged only — never thrown.
class FitcoinAwardService {
  FitcoinAwardService(this._repo, {FitupDatabase? database}) : _db = database;

  final FitcoinRepository _repo;
  final FitupDatabase? _db;

  static const Map<EarnSource, int> _defaultAmounts = <EarnSource, int>{
    EarnSource.dailyStepGoal: 50,
    EarnSource.workoutCompleted: 25,
    EarnSource.allMealsLogged: 20,
    EarnSource.weeklyStreakBonus: 100,
    EarnSource.dailyLogin: 5,
    EarnSource.waterGoalMet: 15,
    EarnSource.loginStreakMilestone: 25,
    EarnSource.labScanUploaded: 30,
    EarnSource.eventJoined: 10,
    EarnSource.eventCompleted: 150,
    EarnSource.challengeWon: 200,
    EarnSource.referralSuccess: 200,
    EarnSource.manualBonus: 0,
  };

  static String _safeId(String key) => key.replaceAll('/', '_');

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Future<void> _safeAward({
    required String userId,
    required EarnSource source,
    required int amount,
    required String description,
    required String idempotencyKey,
  }) async {
    if (amount <= 0) {
      return;
    }
    try {
      final Either<Failure, FitcoinTransaction> r =
          await awardCoins(
            userId: userId,
            source: source,
            amount: amount,
            description: description,
            idempotencyKey: idempotencyKey,
          );
      r.fold(
        (Failure f) => LoggerService.e(
          'FitcoinAwardService.$source',
          f,
          StackTrace.current,
        ),
        (_) {},
      );
    } catch (e, st) {
      LoggerService.e('FitcoinAwardService.$source', e, st);
    }
  }

  /// Main award entry used by sync / backfill logic.
  ///
  /// Returns:
  /// - `Left(...)` for already-awarded duplicates / validation errors.
  /// - `Right(pendingTx)` when remote write fails; caller can retry later.
  Future<Either<Failure, FitcoinTransaction>> awardCoins({
    required String userId,
    required EarnSource source,
    required int amount,
    required String description,
    required String idempotencyKey,
  }) async {
    if (amount <= 0) {
      return Left(ValidationFailure('Amount must be positive'));
    }
    if (_db == null) {
      // No local DB: we can only try remote.
      return _repo.awardCoins(
        userId: userId,
        source: source,
        amount: amount,
        description: description,
        idempotencyKey: idempotencyKey,
      );
    }

    final FitupDatabase db = _db;
    final String safeKey = _safeId(idempotencyKey);
    final DateTime now = DateTime.now();

    // 1) Local idempotency cache check (avoids any network call).
    final FitcoinIdempotencyCacheRow? idr = await (db.select(db.fitcoinIdempotencyCache)
          ..where(
            ($FitcoinIdempotencyCacheTable t) =>
                t.keyId.equals(safeKey) & t.userId.equals(userId),
          ))
        .getSingleOrNull();
    if (idr != null) {
      final FitcoinTransactionCacheRow? tr = await (db.select(db.fitcoinTransactionsCache)
            ..where(($FitcoinTransactionsCacheTable t) => t.id.equals(idr.transactionId)))
          .getSingleOrNull();
      if (tr != null) {
        return Right(_txFromCacheRow(tr));
      }
    }

    // 2) Try remote award.
    final Either<Failure, FitcoinTransaction> remote = await _repo.awardCoins(
      userId: userId,
      source: source,
      amount: amount,
      description: description,
      idempotencyKey: idempotencyKey,
    );

    return remote.fold(
      (Failure failure) async {
        // 3) On failure enqueue + mirror a pending transaction locally.
        final FitcoinAwardQueueData? existing = await (db
                .select(db.fitcoinAwardQueue)
                  ..where(($FitcoinAwardQueueTable t) =>
                      t.idempotencyKey.equals(safeKey)))
            .getSingleOrNull();
        final int retryCount = existing?.retryCount ?? 0;

        final String pendingTxId = 'pending_${safeKey}';
        final FitcoinTransaction pending = FitcoinTransaction(
          id: pendingTxId,
          userId: userId,
          type: TransactionType.earned,
          source: source,
          amount: amount,
          description: description,
          createdAt: now,
          synced: false,
        );

        await db.into(db.fitcoinAwardQueue).insertOnConflictUpdate(
              FitcoinAwardQueueCompanion.insert(
                idempotencyKey: safeKey,
                userId: userId,
                source: source.name,
                amount: amount,
                description: description,
                queuedAt: now,
                retryCount: Value<int>(retryCount),
              ),
            );
        await db.into(db.fitcoinTransactionsCache)
            .insertOnConflictUpdate(
          FitcoinTransactionsCacheCompanion.insert(
            id: pendingTxId,
            userId: pending.userId,
            type: TransactionType.earned.name,
            source: Value<String?>(source.name),
            amount: amount,
            description: description,
            createdAt: pending.createdAt,
            idempotencyKey: Value<String?>(safeKey),
            synced: const Value<bool>(false),
          ),
        );

        return Right(pending);
      },
      (FitcoinTransaction tx) async {
        // 4) On success cache idempotency locally (important for tests /
        // mocked repos).
        await _cacheIdempotencyLocally(
          db: db,
          userId: userId,
          safeKey: safeKey,
          tx: tx,
        );
        return Right(tx);
      },
    );
  }

  Future<void> _cacheIdempotencyLocally({
    required FitupDatabase db,
    required String userId,
    required String safeKey,
    required FitcoinTransaction tx,
  }) async {
    await db.into(db.fitcoinTransactionsCache).insertOnConflictUpdate(
          FitcoinTransactionsCacheCompanion.insert(
            id: tx.id,
            userId: userId,
            type: tx.type.name,
            source: Value<String?>(tx.source?.name),
            amount: tx.amount,
            description: tx.description,
            createdAt: tx.createdAt,
            idempotencyKey: Value<String?>(safeKey),
            synced: Value<bool>(true),
          ),
        );

    await db.into(db.fitcoinIdempotencyCache).insertOnConflictUpdate(
          FitcoinIdempotencyCacheCompanion.insert(
            keyId: safeKey,
            userId: userId,
            transactionId: tx.id,
            createdAt: tx.createdAt,
          ),
        );
  }

  FitcoinTransaction _txFromCacheRow(FitcoinTransactionCacheRow row) {
    return FitcoinTransaction(
      id: row.id,
      userId: row.userId,
      type: TransactionType.values.firstWhere(
        (TransactionType e) => e.name == row.type,
        orElse: () => TransactionType.earned,
      ),
      source: row.source != null
          ? EarnSource.values.firstWhere(
              (EarnSource e) => e.name == row.source,
              orElse: () => EarnSource.manualBonus,
            )
          : null,
      amount: row.amount,
      description: row.description,
      createdAt: row.createdAt,
      synced: row.synced,
    );
  }

  Future<void> onDailyStepGoalReached(String userId) async {
    await onDailyStepGoalReachedForDate(userId, DateTime.now());
  }

  /// Date-scoped daily step goal (used by historical backfill).
  Future<void> onDailyStepGoalReachedForDate(
    String userId,
    DateTime date,
  ) async {
    final String key =
        '${userId}_${EarnSource.dailyStepGoal.name}_${_dayKey(date)}';
    await _safeAward(
      userId: userId,
      source: EarnSource.dailyStepGoal,
      amount: _defaultAmounts[EarnSource.dailyStepGoal]!,
      description: 'Daily step goal achieved',
      idempotencyKey: key,
    );
  }

  /// [workoutLogId] scopes idempotency per session (tiers use [amount]).
  Future<void> onWorkoutCompleted(
    String userId, {
    String? workoutLogId,
    int? amount,
  }) async {
    final int amt = amount ?? _defaultAmounts[EarnSource.workoutCompleted]!;
    final String key = workoutLogId != null && workoutLogId.isNotEmpty
        ? '${userId}_${EarnSource.workoutCompleted.name}_$workoutLogId'
        : '${userId}_${EarnSource.workoutCompleted.name}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.workoutCompleted,
      amount: amt,
      description: 'Workout session completed',
      idempotencyKey: key,
    );
  }

  Future<void> onAllMealsLogged(String userId) async {
    final String key =
        '${userId}_${EarnSource.allMealsLogged.name}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.allMealsLogged,
      amount: _defaultAmounts[EarnSource.allMealsLogged]!,
      description: 'All main meals logged today',
      idempotencyKey: key,
    );
  }

  Future<void> onStreakReached(String userId, int days) async {
    final String key =
        '${userId}_${EarnSource.weeklyStreakBonus.name}_${days}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.weeklyStreakBonus,
      amount: _defaultAmounts[EarnSource.weeklyStreakBonus]!,
      description: '$days-day activity streak bonus',
      idempotencyKey: key,
    );
  }

  Future<void> onDailyLogin(String userId) async {
    final String key =
        '${userId}_${EarnSource.dailyLogin.name}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.dailyLogin,
      amount: _defaultAmounts[EarnSource.dailyLogin]!,
      description: 'Daily login bonus',
      idempotencyKey: key,
    );
    await _maybeAwardLoginStreakMilestone(userId);
  }

  static const String _kLoginStreakPrefix = 'fitup_login_streak_v2_';

  /// Awards [loginStreakMilestone] on days 3, 7, 14, 30 of consecutive logins.
  Future<void> _maybeAwardLoginStreakMilestone(String userId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String lastKey = '${_kLoginStreakPrefix}last_$userId';
      final String countKey = '${_kLoginStreakPrefix}count_$userId';
      final String? lastStr = prefs.getString(lastKey);
      final DateTime today = DateTime.now();
      final DateTime todayDate = DateTime(today.year, today.month, today.day);
      DateTime? lastLoginDay;
      if (lastStr != null && lastStr.length >= 10) {
        final List<String> p = lastStr.split('-');
        if (p.length == 3) {
          final int? y = int.tryParse(p[0]);
          final int? m = int.tryParse(p[1]);
          final int? d = int.tryParse(p[2]);
          if (y != null && m != null && d != null) {
            lastLoginDay = DateTime(y, m, d);
          }
        }
      }
      int streak = prefs.getInt(countKey) ?? 0;
      if (lastLoginDay == null) {
        streak = 1;
      } else {
        final int diffDays = todayDate.difference(lastLoginDay).inDays;
        if (diffDays == 0) {
          return;
        }
        if (diffDays == 1) {
          streak += 1;
        } else {
          streak = 1;
        }
      }
      await prefs.setString(
        lastKey,
        '${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-'
        '${todayDate.day.toString().padLeft(2, '0')}',
      );
      await prefs.setInt(countKey, streak);

      const List<int> milestones = <int>[3, 7, 14, 30];
      if (!milestones.contains(streak)) {
        return;
      }
      final String mKey =
          '${userId}_${EarnSource.loginStreakMilestone.name}_${streak}_${_dayKey(todayDate)}';
      await _safeAward(
        userId: userId,
        source: EarnSource.loginStreakMilestone,
        amount: _defaultAmounts[EarnSource.loginStreakMilestone]!,
        description: '$streak-day login streak',
        idempotencyKey: mKey,
      );
    } catch (e, st) {
      LoggerService.e('FitcoinAwardService._maybeAwardLoginStreakMilestone', e, st);
    }
  }

  /// When total water for [date] meets goal (caller checks totals vs profile).
  Future<void> onWaterGoalReachedForDay(
    String userId,
    DateTime date,
  ) async {
    final String key =
        '${userId}_${EarnSource.waterGoalMet.name}_${_dayKey(date)}';
    await _safeAward(
      userId: userId,
      source: EarnSource.waterGoalMet,
      amount: _defaultAmounts[EarnSource.waterGoalMet]!,
      description: 'Daily water goal reached',
      idempotencyKey: key,
    );
  }

  Future<void> onLabScanUploaded(String userId) async {
    final String key =
        '${userId}_${EarnSource.labScanUploaded.name}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.labScanUploaded,
      amount: _defaultAmounts[EarnSource.labScanUploaded]!,
      description: 'Lab report uploaded',
      idempotencyKey: key,
    );
  }

  Future<void> onEventCompleted(String userId, String eventId) async {
    final String key =
        '${userId}_${EarnSource.eventCompleted.name}_$eventId';
    await _safeAward(
      userId: userId,
      source: EarnSource.eventCompleted,
      amount: _defaultAmounts[EarnSource.eventCompleted]!,
      description: 'Community event completed',
      idempotencyKey: key,
    );
  }

  /// Join reward — idempotent per user+event (ADR-021).
  Future<void> onEventJoined(String userId, String eventId) async {
    final String key =
        '${userId}_${EarnSource.eventJoined.name}_$eventId';
    await _safeAward(
      userId: userId,
      source: EarnSource.eventJoined,
      amount: _defaultAmounts[EarnSource.eventJoined]!,
      description: 'Joined community event',
      idempotencyKey: key,
    );
  }

  Future<void> onChallengeWon(String userId, String challengeId) async {
    final String key =
        '${userId}_${EarnSource.challengeWon.name}_$challengeId';
    await _safeAward(
      userId: userId,
      source: EarnSource.challengeWon,
      amount: _defaultAmounts[EarnSource.challengeWon]!,
      description: 'Challenge won',
      idempotencyKey: key,
    );
  }

  Future<void> onReferralSuccess(String userId) async {
    final String key =
        '${userId}_${EarnSource.referralSuccess.name}_${_dayKey(DateTime.now())}';
    await _safeAward(
      userId: userId,
      source: EarnSource.referralSuccess,
      amount: _defaultAmounts[EarnSource.referralSuccess]!,
      description: 'Referral completed signup',
      idempotencyKey: key,
    );
  }

  /// Tiered fitcoin reward based on activity metrics.
  /// Range: 10 - 100 coins.
  static int calculateActivityReward(Activity activity) {
    int coins = 10;
    final double km = activity.distanceMeters / 1000;
    coins += (km * 5).round().clamp(0, 50);
    final int mins = activity.durationSeconds ~/ 60;
    coins += (mins * 0.5).round().clamp(0, 25);
    final int cal = activity.caloriesBurnt.round();
    coins += (cal ~/ 20).clamp(0, 25);
    return coins.clamp(10, 100);
  }

  /// Award fitcoins for a completed tracked activity. Idempotent per activity ID.
  Future<void> onActivityCompleted(String userId, Activity activity) async {
    final int amount = calculateActivityReward(activity);
    final String key =
        '${userId}_${EarnSource.workoutCompleted.name}_${activity.id}';
    await _safeAward(
      userId: userId,
      source: EarnSource.workoutCompleted,
      amount: amount,
      description: '${activity.type.label} activity completed',
      idempotencyKey: key,
    );
  }
}
