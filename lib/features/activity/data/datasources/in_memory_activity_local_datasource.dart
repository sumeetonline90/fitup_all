import 'dart:async';

import 'package:intl/intl.dart';

import '../../domain/entities/activity.dart';
import '../../domain/entities/sleep_log.dart';
import 'activity_local_datasource.dart';
import '../../../../services/location_service.dart';

/// Web / test fallback: keeps activity + sleep in memory.
class InMemoryActivityLocalDataSource implements ActivityLocalDataSource {
  final Map<String, Activity> _activities = <String, Activity>{};
  final Map<String, SleepLog> _sleep = <String, SleepLog>{};
  final StreamController<void> _tick = StreamController<void>.broadcast();

  DateTime _startOfToday() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isToday(DateTime t, DateTime start) {
    return !t.isBefore(start) && t.isBefore(start.add(const Duration(days: 1)));
  }

  @override
  Future<void> dequeueSync(String id) async {}

  @override
  Future<void> enqueueSync({
    required String id,
    required String userId,
    required String resourceType,
    required String payloadJson,
  }) async {}

  @override
  Future<void> markActivitySynced(String activityId) async {}

  @override
  Future<void> markSleepSynced(String sleepId) async {}

  @override
  Future<List<Activity>> queryActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  }) async {
    return _activities.values.where((Activity a) {
      if (a.userId != userId) {
        return false;
      }
      if (from != null && a.startTime.isBefore(from)) {
        return false;
      }
      if (to != null && a.startTime.isAfter(to)) {
        return false;
      }
      if (type != null && a.type != type) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<SleepLog>> querySleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    return _sleep.values.where((SleepLog s) {
      if (s.userId != userId) {
        return false;
      }
      if (from != null && s.bedtime.isBefore(from)) {
        return false;
      }
      if (to != null && s.wakeTime.isAfter(to)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> saveActivityLocal(Activity activity, {required bool synced}) async {
    _activities[activity.id] = activity;
    _tick.add(null);
  }

  @override
  Future<void> upsertPassiveStepsForDate({
    required DateTime date,
    required int steps,
    required String userId,
  }) async {
    final String dateKey = DateFormat('yyyyMMdd').format(date);
    final String stableId = 'passive_steps_${userId}_$dateKey';

    final double distanceMeters = steps * 0.78;
    final int durationSeconds =
        const Duration(hours: 23, minutes: 59).inSeconds;

    _activities[stableId] = Activity(
      id: stableId,
      userId: userId,
      type: ActivityType.walk,
      startTime: date,
      endTime: date.add(const Duration(hours: 23, minutes: 59)),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      caloriesBurnt:
          LocationService.calculateCalories(ActivityType.walk, distanceMeters, 70),
      steps: steps,
    );
    _tick.add(null);
  }

  @override
  Future<void> saveSleepLogLocal(SleepLog log, {required bool synced}) async {
    _sleep[log.id] = log;
  }

  @override
  Future<void> deleteActivityLocal(String activityId) async {
    _activities.remove(activityId);
    _tick.add(null);
  }

  @override
  Stream<List<Activity>> watchTodayActivities(String userId) async* {
    final DateTime start = _startOfToday();
    yield _todayList(userId, start);
    yield* _tick.stream.asyncMap((_) async => _todayList(userId, start));
  }

  List<Activity> _todayList(String userId, DateTime start) {
    return _activities.values
        .where(
          (Activity a) => a.userId == userId && _isToday(a.startTime, start),
        )
        .toList();
  }
}
