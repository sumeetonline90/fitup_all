import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../core/error/failures.dart';
import '../features/activity/domain/entities/sleep_log.dart';
import '../features/activity/domain/entities/activity.dart';
import '../features/activity/data/datasources/activity_local_datasource.dart';
import '../features/activity/domain/repositories/activity_repository.dart';
import '../features/fitcoins/domain/services/fitcoin_award_service.dart';
import '../core/database/health_sync_metadata_dao.dart';
import './logger_service.dart';

/// Android Health Connect + Apple HealthKit (mobile).
///
/// [Health] is instantiated eagerly so the native ActivityResultLauncher
/// is registered before any permission request is made.
class HealthConnectService {
  HealthConnectService({Health? health}) : _health = health ?? _createHealth();

  final Health? _health;

  /// Returns a [Health] instance on mobile, null on web.
  static Health? _createHealth() => kIsWeb ? null : Health();

  // Minimal set — only types that have matching <uses-permission> entries in
  // AndroidManifest.xml. Requesting a type without a manifest declaration
  // causes Android to silently reject the entire requestAuthorization call.
  static const List<HealthDataType> _dataTypes = <HealthDataType>[
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.WORKOUT,
    HealthDataType.WATER,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  /// Checks whether Health Connect has authorization for critical step data.
  Future<bool> hasPermissions() async {
    if (kIsWeb || _health == null) return false;
    try {
      await _health.configure();
      final bool? permitted = await _health.hasPermissions(_dataTypes);
      return permitted == true;
    } catch (_) {
      return false;
    }
  }

  /// Requests Health Connect permissions.
  ///
  /// On Android, this opens the Health Connect consent screen.
  /// Returns true if all requested permissions were granted.
  ///
  /// The native `health` plugin registers its ActivityResultLauncher inside
  /// `onAttachedToActivity`. If `requestAuthorization` is called before that
  /// callback fires, the plugin returns false without showing any UI.
  /// We use progressive back-off (500ms → 1s → 2s) with up to 3 attempts.
  Future<bool> requestPermissions() async {
    if (kIsWeb || _health == null) return false;
    try {
      await _health.configure();

      if (Platform.isAndroid) {
        final HealthConnectSdkStatus? status =
            await _health.getHealthConnectSdkStatus();
        LoggerService.i(
          'HealthConnectService.requestPermissions sdkStatus=$status',
        );
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          LoggerService.i(
            'HealthConnectService.requestPermissions '
            'Health Connect not installed — opening Play Store',
          );
          await _health.installHealthConnect();
          return false;
        }
      }

      LoggerService.i(
        'HealthConnectService.requestPermissions '
        'requesting ${_dataTypes.length} types',
      );

      const List<int> delaysMs = <int>[500, 1000, 2000];
      for (int attempt = 0; attempt < delaysMs.length; attempt++) {
        await Future<void>.delayed(
          Duration(milliseconds: delaysMs[attempt]),
        );
        try {
          final bool ok = await _health.requestAuthorization(
            _dataTypes,
            permissions: _dataTypes
                .map((_) => HealthDataAccess.READ_WRITE)
                .toList(),
          );
          LoggerService.i(
            'HealthConnectService.requestPermissions '
            'attempt=${attempt + 1} ok=$ok',
          );
          if (ok) return true;
        } catch (e) {
          LoggerService.e(
            'HealthConnectService.requestPermissions '
            'attempt=${attempt + 1} threw',
            e,
            StackTrace.current,
          );
        }
      }
      return false;
    } catch (e, st) {
      LoggerService.e(
        'HealthConnectService.requestPermissions failed',
        e,
        st,
      );
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    if (kIsWeb || _health == null) return 0;
    try {
      await _health.configure();
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day);
      final int? n = await _health.getTotalStepsInInterval(start, now);
      return n ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Fetches step totals for each calendar day in the range [from, to].
  ///
  /// Returns a map of `{date → stepCount}` for days where steps > 0.
  /// Used for back-filling missed days after multi-day app absence.
  Future<Map<DateTime, int>> getStepsForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    if (kIsWeb || _health == null) return <DateTime, int>{};

    try {
      await _health.configure();
      final bool? permitted = await _health.hasPermissions(<HealthDataType>[
        HealthDataType.STEPS,
      ]);
      if (permitted != true) {
        return <DateTime, int>{};
      }

      final Map<DateTime, int> result = <DateTime, int>{};
      DateTime cursor = DateTime(from.year, from.month, from.day);
      final DateTime endDay = DateTime(to.year, to.month, to.day);

      while (!cursor.isAfter(endDay)) {
        final DateTime nextDay = cursor.add(const Duration(days: 1));
        final DateTime dayEnd = nextDay.isAfter(to) ? to : nextDay;
        if (!dayEnd.isAfter(cursor)) {
          cursor = nextDay;
          continue;
        }
        final int? steps = await _health.getTotalStepsInInterval(
          cursor,
          dayEnd,
        );
        if (steps != null && steps > 0) {
          result[cursor] = steps;
        }
        cursor = nextDay;
      }
      return result;
    } catch (e, st) {
      LoggerService.e(
        'HealthConnectService.getStepsForDateRange failed',
        e,
        st,
      );
      return <DateTime, int>{};
    }
  }

  /// On app launch, checks last sync time, fetches missing days, saves to
  /// Drift, and awards Fitcoins for days where steps >= 8,000.
  ///
  /// Idempotency is enforced by Fitcoin award idempotency keys.
  Future<void> syncHistoricalSteps({
    required String userId,
    required ActivityLocalDataSource localDs,
    required FitcoinAwardService fitcoinService,
    required HealthSyncMetadataDao metadataDao,
    ActivityRepository? activityRepository,
    bool force = false,
  }) async {
    if (kIsWeb || _health == null) return;

    final meta = await metadataDao.get();
    final DateTime lastSync = meta?.lastStepSyncAt ??
        DateTime.now().subtract(const Duration(days: 7));
    final DateTime now = DateTime.now();

    // Only back-fill if last sync was > 1 hour ago to avoid hammering on
    // every launch, unless forced.
    if (!force && now.difference(lastSync).inHours < 1) {
      return;
    }

    final Map<DateTime, int> missedDays = await getStepsForDateRange(
      lastSync,
      now,
    );

    // If we got no data but we expected some, it might be a permission issue.
    // We still update the sync time so we don't hammer the API, but force=true
    // from pull-to-refresh will bypass this anyway.
    for (final MapEntry<DateTime, int> entry in missedDays.entries) {
      final DateTime date = entry.key;
      final int steps = entry.value;
      final DateTime dayStart = DateTime(date.year, date.month, date.day);
      final DateTime dayEnd = dayStart.add(const Duration(days: 1));
      final String dateKey =
          '${dayStart.year}${dayStart.month.toString().padLeft(2, '0')}${dayStart.day.toString().padLeft(2, '0')}';
      int existingPassiveSteps = 0;
      if (activityRepository != null) {
        final existingEither = await activityRepository.getActivities(
          userId,
          from: dayStart,
          to: dayEnd,
        );
        existingEither.fold((_) {}, (List<Activity> list) {
          for (final Activity a in list) {
            if (a.id.startsWith('passive_steps_')) {
              existingPassiveSteps += a.steps ?? 0;
            }
          }
        });
      }
      final int effectiveSteps =
          steps > existingPassiveSteps ? steps : existingPassiveSteps;
      final Activity passiveActivity = Activity(
        id: 'passive_steps_${userId}_$dateKey',
        userId: userId,
        type: ActivityType.walk,
        startTime: dayStart,
        endTime: dayStart.add(const Duration(hours: 23, minutes: 59)),
        distanceMeters: effectiveSteps * 0.78,
        durationSeconds: const Duration(hours: 23, minutes: 59).inSeconds,
        caloriesBurnt: 70 * ((effectiveSteps * 0.78) / 1000.0) * 0.6,
        steps: effectiveSteps,
      );

      bool persisted = false;
      if (activityRepository != null) {
        final saveRes = await activityRepository.saveActivity(passiveActivity);
        saveRes.fold(
          (Failure f) {
            LoggerService.e(
              'syncHistoricalSteps saveActivity failed',
              f,
              StackTrace.current,
            );
          },
          (_) => persisted = true,
        );
      } else {
        final List<Activity> existing = await localDs.queryActivities(
          userId,
          from: dayStart,
          to: dayEnd,
        );
        int existingPassiveStepsLocal = 0;
        for (final Activity a in existing) {
          if (a.id.startsWith('passive_steps_')) {
            existingPassiveStepsLocal += a.steps ?? 0;
          }
        }
        final int effectiveStepsLocal = steps > existingPassiveStepsLocal
            ? steps
            : existingPassiveStepsLocal;
        await localDs.upsertPassiveStepsForDate(
          userId: userId,
          date: date,
          steps: effectiveStepsLocal,
        );
        persisted = true;
      }

      if (persisted && effectiveSteps >= 8000) {
        await fitcoinService.onDailyStepGoalReachedForDate(userId, date);
      }
    }

    await metadataDao.upsert(lastStepSyncAt: now);
  }

  Future<List<SleepLog>> getSleepData(DateTime from, DateTime to) async {
    if (kIsWeb || _health == null) return <SleepLog>[];
    try {
      await _health.configure();
      final List<HealthDataPoint> points =
          await _health.getHealthDataFromTypes(
        types: <HealthDataType>[HealthDataType.SLEEP_SESSION],
        startTime: from,
        endTime: to,
      );
      final String source = Platform.isAndroid ? 'health_connect' : 'healthkit';
      return points.map((HealthDataPoint p) {
        final int minutes = p.dateTo.difference(p.dateFrom).inMinutes;
        return SleepLog(
          id: p.uuid,
          userId: '',
          bedtime: p.dateFrom,
          wakeTime: p.dateTo,
          durationMinutes: minutes > 0 ? minutes : 1,
          quality: null,
          source: source,
        );
      }).toList();
    } catch (_) {
      return <SleepLog>[];
    }
  }

  Future<int?> getCurrentHeartRate() async {
    if (kIsWeb || _health == null) return null;
    try {
      await _health.configure();
      final DateTime now = DateTime.now();
      final List<HealthDataPoint> points = await _health.getHealthDataFromTypes(
        types: <HealthDataType>[HealthDataType.HEART_RATE],
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now,
      );
      if (points.isEmpty) {
        return null;
      }
      final HealthValue v = points.last.value;
      if (v is NumericHealthValue) {
        return v.numericValue.round();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<double> getTodayCalories() async {
    if (kIsWeb || _health == null) return 0;
    try {
      await _health.configure();
      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day);
      final List<HealthDataPoint> points =
          await _health.getHealthDataFromTypes(
        types: <HealthDataType>[HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: start,
        endTime: now,
      );
      double sum = 0;
      for (final HealthDataPoint p in points) {
        final HealthValue v = p.value;
        if (v is NumericHealthValue) {
          sum += v.numericValue.toDouble();
        }
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  /// Latest HRV sample in ms from the last 24h, if the platform exposes it.
  Future<double?> getLatestHrvMs() async {
    if (kIsWeb || _health == null) return null;
    try {
      await _health.configure();
      final DateTime now = DateTime.now();
      final List<HealthDataType> hrvTypes = HealthDataType.values
          .where(
            (HealthDataType t) =>
                t.name.contains('HEART_RATE_VARIABILITY') ||
                t.name.contains('HRV'),
          )
          .toList();
      if (hrvTypes.isEmpty) {
        return null;
      }
      final List<HealthDataPoint> points =
          await _health.getHealthDataFromTypes(
        types: hrvTypes,
        startTime: now.subtract(const Duration(hours: 24)),
        endTime: now,
      );
      if (points.isEmpty) {
        return null;
      }
      final HealthValue v = points.last.value;
      if (v is NumericHealthValue) {
        return v.numericValue.toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
