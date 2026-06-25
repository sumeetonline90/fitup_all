import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/core/database/health_sync_metadata_dao.dart';
import 'package:fitup/features/activity/data/datasources/drift_activity_local_datasource.dart';
import 'package:fitup/features/activity/data/datasources/activity_local_datasource.dart';
import 'package:fitup/features/activity/domain/entities/activity.dart';
import 'package:fitup/features/activity/domain/entities/sleep_log.dart';
import 'package:fitup/features/fitcoins/domain/entities/fitcoin_transaction.dart';
import 'package:fitup/features/fitcoins/domain/repositories/fitcoin_repository.dart';
import 'package:fitup/features/fitcoins/domain/services/fitcoin_award_service.dart';
import 'package:fitup/services/health_connect_service.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealth extends Mock implements Health {}

class _MockFitcoinRepo extends Mock implements FitcoinRepository {}

class _SpyActivityLocalDataSource implements ActivityLocalDataSource {
  final List<({DateTime date, int steps, String userId})> upserts =
      <({DateTime date, int steps, String userId})>[];

  @override
  Future<void> upsertPassiveStepsForDate({
    required DateTime date,
    required int steps,
    required String userId,
  }) async {
    upserts.add((date: date, steps: steps, userId: userId));
  }

  @override
  Future<void> saveActivityLocal(Activity activity, {required bool synced}) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteActivityLocal(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Activity>> queryActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Activity>> watchTodayActivities(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<List<SleepLog>> querySleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveSleepLogLocal(SleepLog log, {required bool synced}) {
    throw UnimplementedError();
  }

  @override
  Future<void> enqueueSync({
    required String id,
    required String userId,
    required String resourceType,
    required String payloadJson,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> dequeueSync(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> markActivitySynced(String activityId) {
    throw UnimplementedError();
  }

  @override
  Future<void> markSleepSynced(String sleepId) {
    throw UnimplementedError();
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(EarnSource.dailyLogin);
    registerFallbackValue(DateTime(2000, 1, 1));
  });

  test('getStepsForDateRange returns correct map', () async {
    final _MockHealth h = _MockHealth();
    when(() => h.hasPermissions(any())).thenAnswer((_) async => true);

    final DateTime d1 = DateTime(2026, 3, 1);
    final DateTime d2 = DateTime(2026, 3, 2);
    final DateTime d3 = DateTime(2026, 3, 3);

    when(() => h.getTotalStepsInInterval(d1, d2)).thenAnswer(
      (_) async => 500,
    );
    when(() => h.getTotalStepsInInterval(d2, d3)).thenAnswer(
      (_) async => 0,
    );
    when(() => h.getTotalStepsInInterval(d3, DateTime(2026, 3, 4)))
        .thenAnswer((_) async => 9000);

    final HealthConnectService s = HealthConnectService(health: h);

    final Map<DateTime, int> out = await s.getStepsForDateRange(d1, d3);

    expect(out, <DateTime, int>{
      d1: 500,
      d3: 9000,
    });
  });

  test('syncHistoricalSteps skips sync if lastSync < 1 hour ago', () async {
    final FitupDatabase db = FitupDatabase(NativeDatabase.memory());
    final HealthSyncMetadataDao metaDao = HealthSyncMetadataDao(db);

    await metaDao.upsert(
      lastStepSyncAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    final _MockHealth h = _MockHealth();
    when(() => h.hasPermissions(any())).thenAnswer((_) async => true);

    final HealthConnectService s = HealthConnectService(health: h);
    final _SpyActivityLocalDataSource local = _SpyActivityLocalDataSource();
    final _MockFitcoinRepo repo = _MockFitcoinRepo();
    final FitcoinAwardService fitcoins =
        FitcoinAwardService(repo, database: db);

    await s.syncHistoricalSteps(
      userId: 'u1',
      localDs: local,
      fitcoinService: fitcoins,
      metadataDao: metaDao,
    );

    verifyNever(() => h.getTotalStepsInInterval(any(), any()));
    expect(local.upserts, isEmpty);
    await db.close();
  });

  test('syncHistoricalSteps awards Fitcoins only for days >= 8000 steps',
      () async {
    final FitupDatabase db = FitupDatabase(NativeDatabase.memory());
    final HealthSyncMetadataDao metaDao = HealthSyncMetadataDao(db);

    final DateTime lastSync = DateTime.now().subtract(const Duration(days: 2));
    await metaDao.upsert(lastStepSyncAt: lastSync);

    final _MockHealth h = _MockHealth();
    when(() => h.hasPermissions(any())).thenAnswer((_) async => true);

    final DateTime d1 = DateTime(lastSync.year, lastSync.month, lastSync.day);
    final DateTime d2 = d1.add(const Duration(days: 1));
    final DateTime d3 = d2.add(const Duration(days: 1));
    when(() => h.getTotalStepsInInterval(d1, d1.add(const Duration(days: 1))))
        .thenAnswer((_) async => 5000);
    when(() => h.getTotalStepsInInterval(d2, d2.add(const Duration(days: 1))))
        .thenAnswer((_) async => 8000);
    when(() => h.getTotalStepsInInterval(d3, d3.add(const Duration(days: 1))))
        .thenAnswer((_) async => 12000);

    final HealthConnectService s = HealthConnectService(health: h);
    final _SpyActivityLocalDataSource local = _SpyActivityLocalDataSource();
    final _MockFitcoinRepo repo = _MockFitcoinRepo();
    final FitcoinAwardService fitcoins =
        FitcoinAwardService(repo, database: db);

    when(() => repo.awardCoins(
          userId: any(named: 'userId'),
          source: any(named: 'source'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => Right<Failure, FitcoinTransaction>(
          FitcoinTransaction(
            id: 'tx1',
            userId: 'u1',
            type: TransactionType.earned,
            source: EarnSource.dailyStepGoal,
            amount: 50,
            description: 'Daily step goal achieved',
            createdAt: DateTime.now(),
            synced: true,
          ),
        ));

    await s.syncHistoricalSteps(
      userId: 'u1',
      localDs: local,
      fitcoinService: fitcoins,
      metadataDao: metaDao,
    );

    // We only award on days >= 8000 steps; day1 is 5000.
    verify(() => repo.awardCoins(
          userId: 'u1',
          source: EarnSource.dailyStepGoal,
          amount: 50,
          description: 'Daily step goal achieved',
          idempotencyKey: any(named: 'idempotencyKey'),
        )).called(2);

    // Ensure at least one upsert happened for each non-zero step day.
    expect(local.upserts.length, greaterThanOrEqualTo(2));
    await db.close();
  });

  test('syncHistoricalSteps does NOT double-award for same day', () async {
    final FitupDatabase db = FitupDatabase(NativeDatabase.memory());
    final HealthSyncMetadataDao metaDao = HealthSyncMetadataDao(db);

    final _MockHealth h = _MockHealth();
    when(() => h.hasPermissions(any())).thenAnswer((_) async => true);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    // Service normalizes the range to calendar days and then calls:
    //  - getTotalStepsInInterval(yesterday, today)
    //  - getTotalStepsInInterval(today, tomorrow)
    when(() => h.getTotalStepsInInterval(yesterday, today))
        .thenAnswer((_) async => 9000);
    when(() => h.getTotalStepsInInterval(today, today.add(const Duration(days: 1))))
        .thenAnswer((_) async => 0);

    final HealthConnectService s = HealthConnectService(health: h);

    final _SpyActivityLocalDataSource local = _SpyActivityLocalDataSource();
    final _MockFitcoinRepo repo = _MockFitcoinRepo();

    when(() => repo.awardCoins(
          userId: any(named: 'userId'),
          source: any(named: 'source'),
          amount: any(named: 'amount'),
          description: any(named: 'description'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => Right<Failure, FitcoinTransaction>(
          FitcoinTransaction(
            id: 'tx_d1',
            userId: 'u1',
            type: TransactionType.earned,
            source: EarnSource.dailyStepGoal,
            amount: 50,
            description: 'Daily step goal achieved',
            createdAt: DateTime.now(),
            synced: true,
          ),
        ));

    final FitcoinAwardService fitcoins =
        FitcoinAwardService(repo, database: db);

    // 1st run: lastSync is old, so it should award once.
    await metaDao.upsert(
      lastStepSyncAt: yesterday,
    );
    await s.syncHistoricalSteps(
      userId: 'u1',
      localDs: local,
      fitcoinService: fitcoins,
      metadataDao: metaDao,
    );

    // 2nd run: still allow sync, but idempotency should prevent any second
    // remote award call.
    await metaDao.upsert(
      lastStepSyncAt: yesterday,
    );
    await s.syncHistoricalSteps(
      userId: 'u1',
      localDs: local,
      fitcoinService: fitcoins,
      metadataDao: metaDao,
    );

    verify(() => repo.awardCoins(
          userId: 'u1',
          source: EarnSource.dailyStepGoal,
          amount: 50,
          description: 'Daily step goal achieved',
          idempotencyKey: any(named: 'idempotencyKey'),
        )).called(1);

    await db.close();
  });

  test('upsertPassiveStepsForDate is idempotent (stable ID)', () async {
    final FitupDatabase db = FitupDatabase(NativeDatabase.memory());
    final DriftActivityLocalDataSource local = DriftActivityLocalDataSource(db);

    final DateTime d = DateTime(2026, 3, 10);
    await local.upsertPassiveStepsForDate(date: d, steps: 1000, userId: 'u1');
    await local.upsertPassiveStepsForDate(date: d, steps: 2000, userId: 'u1');

    final List<Activity> rows = await local.queryActivities(
      'u1',
      from: d,
      to: d.add(const Duration(days: 1)),
    );
    expect(rows, hasLength(1));
    expect(rows.first.steps, 2000);

    await db.close();
  });
}

