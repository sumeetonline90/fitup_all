import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/fitup_database.dart';
import '../../../../services/location_service.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/sleep_log.dart';
import 'activity_local_datasource.dart';

/// Drift-backed offline store for activity + sleep.
class DriftActivityLocalDataSource implements ActivityLocalDataSource {
  DriftActivityLocalDataSource(this._db);

  final FitupDatabase _db;

  @override
  Future<void> dequeueSync(String id) async {
    await (_db.delete(_db.syncQueue)..where(($SyncQueueTable t) => t.id.equals(id))).go();
  }

  @override
  Future<void> enqueueSync({
    required String id,
    required String userId,
    required String resourceType,
    required String payloadJson,
  }) async {
    await _db.into(_db.syncQueue).insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: id,
            userId: userId,
            resourceType: resourceType,
            payloadJson: payloadJson,
          ),
        );
  }

  @override
  Future<void> markActivitySynced(String activityId) async {
    await (_db.update(_db.activities)
          ..where(($ActivitiesTable t) => t.id.equals(activityId)))
        .write(const ActivitiesCompanion(synced: Value<bool>(true)));
  }

  @override
  Future<void> markSleepSynced(String sleepId) async {
    await (_db.update(_db.sleepLogs)..where(($SleepLogsTable t) => t.id.equals(sleepId)))
        .write(const SleepLogsCompanion(synced: Value<bool>(true)));
  }

  @override
  Future<List<Activity>> queryActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  }) async {
    return _queryActivitiesImpl(userId, from: from, to: to, type: type);
  }

  Future<List<Activity>> _queryActivitiesImpl(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  }) async {
    final SimpleSelectStatement<$ActivitiesTable, ActivityRow> q =
        _db.select(_db.activities)
          ..where(($ActivitiesTable t) {
            Expression<bool> p = t.userId.equals(userId);
            if (from != null) {
              final DateTime startFrom = from;
              p = p & t.startTime.isBiggerOrEqualValue(startFrom);
            }
            if (to != null) {
              final DateTime endTo = to;
              p = p & t.startTime.isSmallerOrEqualValue(endTo);
            }
            if (type != null) {
              final ActivityType filterType = type;
              p = p & t.type.equals(filterType.name);
            }
            return p;
          });
    final List<ActivityRow> rows = await q.get();
    return rows.map(_rowToActivity).toList();
  }

  @override
  Future<List<SleepLog>> querySleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final SimpleSelectStatement<$SleepLogsTable, SleepLogRow> q =
        _db.select(_db.sleepLogs)
          ..where(($SleepLogsTable t) {
            Expression<bool> p = t.userId.equals(userId);
            if (from != null) {
              final DateTime startFrom = from;
              p = p & t.bedtime.isBiggerOrEqualValue(startFrom);
            }
            if (to != null) {
              final DateTime endTo = to;
              p = p & t.wakeTime.isSmallerOrEqualValue(endTo);
            }
            return p;
          });
    final List<SleepLogRow> rows = await q.get();
    return rows.map(_rowToSleepLog).toList();
  }

  @override
  Future<void> saveActivityLocal(Activity activity, {required bool synced}) async {
    await _db.into(_db.activities).insertOnConflictUpdate(
          ActivitiesCompanion.insert(
            id: activity.id,
            userId: activity.userId,
            type: activity.type.name,
            startTime: activity.startTime,
            endTime: Value(activity.endTime),
            distanceMeters: activity.distanceMeters,
            durationSeconds: activity.durationSeconds,
            caloriesBurnt: activity.caloriesBurnt,
            routePointsJson: Value<String>(_encodeRoute(activity.routePoints)),
            steps: Value(activity.steps),
            avgPace: Value(activity.avgPace),
            avgSpeed: Value(activity.avgSpeed),
            avgHeartRate: Value(activity.avgHeartRate),
            gpsDropSeconds: Value(activity.gpsDropSeconds),
            gpsDropInterruptions: Value(activity.gpsDropInterruptions),
            synced: Value(synced),
          ),
        );
  }

  /// Inserts or updates a synthetic passive-steps record for the given day.
  ///
  /// Uses a stable ID `passive_steps_{userId}_{yyyyMMdd}` so re-syncing is
  /// idempotent.
  @override
  Future<void> upsertPassiveStepsForDate({
    required DateTime date,
    required int steps,
    required String userId,
  }) async {
    final String dateKey = DateFormat('yyyyMMdd').format(date);
    final String stableId = 'passive_steps_${userId}_$dateKey';

    // Avg stride length (approx). Used to backfill distance and calories.
    final double distanceMeters = steps * 0.78;
    final int durationSeconds =
        const Duration(hours: 23, minutes: 59).inSeconds;

    await _db.into(_db.activities).insertOnConflictUpdate(
          ActivitiesCompanion.insert(
            id: stableId,
            userId: userId,
            type: ActivityType.walk.name,
            startTime: date,
            endTime: Value(date.add(const Duration(hours: 23, minutes: 59))),
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            caloriesBurnt:
                LocationService.calculateCalories(ActivityType.walk, distanceMeters, 70),
            routePointsJson: const Value<String>('[]'),
            steps: Value(steps),
            avgPace: const Value.absent(),
            avgSpeed: const Value.absent(),
            avgHeartRate: const Value.absent(),
            gpsDropSeconds: const Value<int>(0),
            gpsDropInterruptions: const Value<int>(0),
            synced: const Value<bool>(false),
          ),
        );
  }

  @override
  Future<void> saveSleepLogLocal(SleepLog log, {required bool synced}) async {
    await _db.into(_db.sleepLogs).insertOnConflictUpdate(
          SleepLogsCompanion.insert(
            id: log.id,
            userId: log.userId,
            bedtime: log.bedtime,
            wakeTime: log.wakeTime,
            durationMinutes: log.durationMinutes,
            quality: Value(log.quality),
            source: log.source,
            synced: Value(synced),
          ),
        );
  }

  @override
  Future<void> deleteActivityLocal(String activityId) async {
    await (_db.delete(_db.activities)
          ..where(($ActivitiesTable t) => t.id.equals(activityId)))
        .go();
  }

  @override
  Stream<List<Activity>> watchTodayActivities(String userId) {
    final DateTime start = _startOfToday();
    final DateTime end = start.add(const Duration(days: 1));
    final SimpleSelectStatement<$ActivitiesTable, ActivityRow> q =
        _db.select(_db.activities)
          ..where(
            ($ActivitiesTable t) =>
                t.userId.equals(userId) &
                t.startTime.isBiggerOrEqualValue(start) &
                t.startTime.isSmallerThanValue(end),
          );
    return q
        .watch()
        .map((List<ActivityRow> rows) => rows.map(_rowToActivity).toList());
  }

  String _encodeRoute(List<LatLng> points) {
    return jsonEncode(
      points
          .map(
            (LatLng p) => <String, double>{'lat': p.latitude, 'lng': p.longitude},
          )
          .toList(),
    );
  }

  Activity _rowToActivity(ActivityRow row) {
    return Activity(
      id: row.id,
      userId: row.userId,
      type: ActivityType.values.firstWhere(
        (ActivityType e) => e.name == row.type,
        orElse: () => ActivityType.walk,
      ),
      startTime: row.startTime,
      endTime: row.endTime,
      distanceMeters: row.distanceMeters,
      durationSeconds: row.durationSeconds,
      caloriesBurnt: row.caloriesBurnt,
      routePoints: _decodeRoute(row.routePointsJson),
      steps: row.steps,
      avgPace: row.avgPace,
      avgSpeed: row.avgSpeed,
      avgHeartRate: row.avgHeartRate,
      gpsDropSeconds: row.gpsDropSeconds,
      gpsDropInterruptions: row.gpsDropInterruptions,
    );
  }

  List<LatLng> _decodeRoute(String jsonStr) {
    if (jsonStr.isEmpty) {
      return <LatLng>[];
    }
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((dynamic e) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map);
      return LatLng(
        (m['lat'] as num).toDouble(),
        (m['lng'] as num).toDouble(),
      );
    }).toList();
  }

  SleepLog _rowToSleepLog(SleepLogRow row) {
    return SleepLog(
      id: row.id,
      userId: row.userId,
      bedtime: row.bedtime,
      wakeTime: row.wakeTime,
      durationMinutes: row.durationMinutes,
      quality: row.quality,
      source: row.source,
    );
  }

  DateTime _startOfToday() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
