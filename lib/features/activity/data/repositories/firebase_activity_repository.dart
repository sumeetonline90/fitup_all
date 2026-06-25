import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/activity_stats.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/utils/activity_step_aggregation.dart';
import '../datasources/activity_local_datasource.dart';
import '../models/activity_model.dart';
import '../models/sleep_log_model.dart';

/// Firestore + local Drift / in-memory (offline-first).
class FirebaseActivityRepository implements ActivityRepository {
  FirebaseActivityRepository(
    this._firestore,
    this._local, {
    FitcoinAwardService? fitcoinAwardService,
    int? dailyStepGoal,
  }) : _fitcoinAwards = fitcoinAwardService,
       _dailyStepGoal = dailyStepGoal ?? _defaultStepGoal;

  final FirebaseFirestore _firestore;
  final ActivityLocalDataSource _local;
  final FitcoinAwardService? _fitcoinAwards;
  int _dailyStepGoal;

  static const int _defaultStepGoal = 8000;

  /// Allow updating the goal from user profile at runtime.
  set dailyStepGoal(int value) => _dailyStepGoal = value;

  static int _estimatedStepsFromDistance(double meters) =>
      (meters / 0.78).round().clamp(0, 200000);

  CollectionReference<Map<String, dynamic>> _activitiesCol(String userId) {
    return _firestore.collection('users').doc(userId).collection('activities');
  }

  CollectionReference<Map<String, dynamic>> _sleepCol(String userId) {
    return _firestore.collection('users').doc(userId).collection('sleepLogs');
  }

  String _encodeSyncPayload(Map<String, dynamic> data) {
    return jsonEncode(
      data,
      toEncodable: (Object? o) {
        if (o is Timestamp) {
          return o.millisecondsSinceEpoch;
        }
        return o;
      },
    );
  }

  Query<Map<String, dynamic>> _todayQuery(String userId) {
    final DateTime n = DateTime.now();
    final DateTime start = DateTime(n.year, n.month, n.day);
    final DateTime end = start.add(const Duration(days: 1));
    return _activitiesCol(userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startTime', isLessThan: Timestamp.fromDate(end));
  }

  @override
  Future<Either<Failure, Activity>> saveActivity(Activity activity) async {
    final ActivityModel model = ActivityModel.fromEntity(activity);

    // Step 1: Local write MUST succeed — if it fails the data is NOT saved.
    try {
      await _local.saveActivityLocal(activity, synced: false);
      await _local.enqueueSync(
        id: activity.id,
        userId: activity.userId,
        resourceType: 'activity',
        payloadJson: _encodeSyncPayload(model.toFirestore()),
      );
    } catch (e, st) {
      LoggerService.e('saveActivity local write failed', e, st);
      return Left<Failure, Activity>(
        const CacheFailure('Failed to save activity. Please try again.'),
      );
    }

    // Step 2: Remote sync — best-effort; data is already safe locally.
    try {
      await _activitiesCol(
        activity.userId,
      ).doc(activity.id).set(model.toFirestore());
      await _local.markActivitySynced(activity.id);
      await _local.dequeueSync(activity.id);
      unawaited(_maybeAwardDailyStepGoal(activity.userId));
      unawaited(_awardActivityFitcoins(activity));
    } catch (e, st) {
      LoggerService.e('saveActivity remote failed; kept locally', e, st);
    }
    return Right<Failure, Activity>(activity);
  }

  Future<void> _maybeAwardDailyStepGoal(String userId) async {
    final FitcoinAwardService? awards = _fitcoinAwards;
    if (awards == null) return;

    final DateTime n = DateTime.now();
    final DateTime start = DateTime(n.year, n.month, n.day);
    final Either<Failure, List<Activity>> res = await getActivities(
      userId,
      from: start,
      to: n,
    );
    await res.fold((_) async {}, (List<Activity> list) async {
      // Separate passive (Health Connect) entries from GPS-tracked sessions
      final List<Activity> passive = <Activity>[];
      final List<Activity> tracked = <Activity>[];
      for (final Activity a in list) {
        if (a.id.startsWith('passive_steps_')) {
          passive.add(a);
        } else {
          tracked.add(a);
        }
      }

      // Use the higher of: passive total OR tracked total (not both summed)
      // to avoid double-counting steps from the same physical activity.
      int passiveSteps = 0;
      for (final Activity a in passive) {
        passiveSteps +=
            a.steps ?? _estimatedStepsFromDistance(a.distanceMeters);
      }
      int trackedSteps = 0;
      for (final Activity a in tracked) {
        trackedSteps +=
            a.steps ?? _estimatedStepsFromDistance(a.distanceMeters);
      }

      final int steps = passiveSteps > trackedSteps
          ? passiveSteps
          : trackedSteps;
      if (steps >= _dailyStepGoal) {
        await awards.onDailyStepGoalReached(userId);
      }
    });
  }

  Future<void> _awardActivityFitcoins(Activity activity) async {
    final FitcoinAwardService? awards = _fitcoinAwards;
    if (awards == null) return;
    if (activity.id.startsWith('passive_steps_')) return;
    try {
      await awards.onActivityCompleted(activity.userId, activity);
    } catch (e, st) {
      LoggerService.e('_awardActivityFitcoins', e, st);
    }
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities(
    String userId, {
    DateTime? from,
    DateTime? to,
    ActivityType? type,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _activitiesCol(userId);
      if (from != null) {
        q = q.where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        );
      }
      if (to != null) {
        q = q.where('startTime', isLessThan: Timestamp.fromDate(to));
      }
      final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
      final List<Activity> remoteList = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                ActivityModel.fromFirestore(d).toEntity(),
          )
          .toList();

      // Fetch local activities to include passive steps
      final List<Activity> localList = await _local.queryActivities(
        userId,
        from: from,
        to: to,
        type: type,
      );

      final Map<String, Activity> merged = <String, Activity>{};
      for (final Activity a in localList) {
        merged[a.id] = a;
      }
      for (final Activity a in remoteList) {
        merged[a.id] = a;
      }

      List<Activity> list = merged.values.toList();
      if (type != null) {
        list = list.where((Activity a) => a.type == type).toList();
      }
      return Right<Failure, List<Activity>>(list);
    } catch (e, st) {
      LoggerService.e('getActivities remote failed; trying local', e, st);
      try {
        final List<Activity> local = await _local.queryActivities(
          userId,
          from: from,
          to: to,
          type: type,
        );
        return Right<Failure, List<Activity>>(local);
      } catch (localErr, localSt) {
        LoggerService.e(
          'getActivities local fallback also failed',
          localErr,
          localSt,
        );
        return Left<Failure, List<Activity>>(
          const CacheFailure(
            'Unable to load activities. Please check your connection.',
          ),
        );
      }
    }
  }

  @override
  Stream<List<Activity>> watchTodayActivities(String userId) {
    final StreamController<List<Activity>> controller =
        StreamController<List<Activity>>.broadcast();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? fireSub;
    StreamSubscription<List<Activity>>? localSub;
    bool switched = false;

    void subscribeLocal() {
      if (switched) {
        return;
      }
      switched = true;
      fireSub?.cancel();
      localSub = _local.watchTodayActivities(userId).listen(controller.add);
    }

    fireSub = _todayQuery(userId).snapshots().listen((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      final List<Activity> remoteList = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                ActivityModel.fromFirestore(d).toEntity(),
          )
          .toList();

      final DateTime now = DateTime.now();
      final DateTime start = DateTime(now.year, now.month, now.day);
      final DateTime end = start.add(const Duration(days: 1));

      final List<Activity> localList = await _local.queryActivities(
        userId,
        from: start,
        to: end,
      );

      final Map<String, Activity> merged = <String, Activity>{};
      for (final Activity a in localList) {
        merged[a.id] = a;
      }
      for (final Activity a in remoteList) {
        merged[a.id] = a;
      }

      controller.add(merged.values.toList());
    }, onError: (Object _, StackTrace __) => subscribeLocal());

    controller.onCancel = () {
      fireSub?.cancel();
      localSub?.cancel();
      controller.close();
    };
    return controller.stream;
  }

  @override
  Future<Either<Failure, ActivityStats>> getStats(
    String userId,
    DateTime from,
    DateTime to,
  ) async {
    final Either<Failure, List<Activity>> res = await getActivities(
      userId,
      from: from,
      to: to,
    );
    return res.fold(Left<Failure, ActivityStats>.new, (List<Activity> list) {
      final Set<String> days = <String>{};
      for (final Activity a in list) {
        final DateTime d = DateTime(
          a.startTime.year,
          a.startTime.month,
          a.startTime.day,
        );
        days.add('${d.year}-${d.month}-${d.day}');
      }
      final Map<DateTime, int> stepDays = stepsByDayNoDoubleCount(list);
      final int totalSteps = stepDays.values.fold<int>(
        0,
        (int p, int daySteps) => p + daySteps,
      );
      final double totalDistance = list.fold<double>(
        0,
        (double p, Activity a) => p + a.distanceMeters,
      );
      final double totalCal = list.fold<double>(
        0,
        (double p, Activity a) => p + a.caloriesBurnt,
      );
      final int totalDur = list.fold<int>(
        0,
        (int p, Activity a) => p + a.durationSeconds,
      );
      final List<Activity> recent = List<Activity>.from(list)
        ..sort((Activity a, Activity b) => b.startTime.compareTo(a.startTime));
      return Right<Failure, ActivityStats>(
        ActivityStats(
          totalSteps: totalSteps,
          totalDistanceMeters: totalDistance,
          totalCaloriesBurnt: totalCal,
          totalDurationSeconds: totalDur,
          activeDays: days.length,
          recentActivities: recent.take(20).toList(),
        ),
      );
    });
  }

  @override
  Future<Either<Failure, void>> deleteActivity(String activityId) async {
    try {
      await _local.deleteActivityLocal(activityId);
      final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collectionGroup('activities')
          .where(FieldPath.documentId, isEqualTo: activityId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return const Right<Failure, void>(null);
      }
      await snap.docs.first.reference.delete();
      return const Right<Failure, void>(null);
    } catch (e, st) {
      LoggerService.e('deleteActivity', e, st);
      return Left<Failure, void>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SleepLog>> saveSleepLog(SleepLog log) async {
    final SleepLogModel model = SleepLogModel(
      id: log.id,
      userId: log.userId,
      bedtime: log.bedtime,
      wakeTime: log.wakeTime,
      durationMinutes: log.durationMinutes,
      quality: log.quality,
      source: log.source,
    );

    // Step 1: Local write MUST succeed — if it fails the data is NOT saved.
    try {
      await _local.saveSleepLogLocal(log, synced: false);
      await _local.enqueueSync(
        id: log.id,
        userId: log.userId,
        resourceType: 'sleep',
        payloadJson: _encodeSyncPayload(model.toFirestore()),
      );
    } catch (e, st) {
      LoggerService.e('saveSleepLog local write failed', e, st);
      return Left<Failure, SleepLog>(
        const CacheFailure('Failed to save sleep log. Please try again.'),
      );
    }

    // Step 2: Remote sync — best-effort; data is already safe locally.
    try {
      await _sleepCol(log.userId).doc(log.id).set(model.toFirestore());
      await _local.markSleepSynced(log.id);
      await _local.dequeueSync(log.id);
    } catch (e, st) {
      LoggerService.e('saveSleepLog remote failed; kept locally', e, st);
      // Data is safe in local DB and sync queue; caller sees success.
    }
    return Right<Failure, SleepLog>(log);
  }

  @override
  Future<Either<Failure, List<SleepLog>>> getSleepLogs(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _sleepCol(userId);
      if (from != null) {
        q = q.where(
          'bedtime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(from),
        );
      }
      if (to != null) {
        q = q.where('wakeTime', isLessThanOrEqualTo: Timestamp.fromDate(to));
      }
      final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
      final List<SleepLog> remoteList = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                SleepLogModel.fromFirestore(d).toEntity(),
          )
          .toList();

      final List<SleepLog> localList = await _local.querySleepLogs(
        userId,
        from: from,
        to: to,
      );

      final Map<String, SleepLog> merged = <String, SleepLog>{};
      for (final SleepLog s in localList) {
        merged[s.id] = s;
      }
      for (final SleepLog s in remoteList) {
        merged[s.id] = s;
      }

      return Right<Failure, List<SleepLog>>(merged.values.toList());
    } catch (e, st) {
      LoggerService.e('getSleepLogs remote failed; trying local', e, st);
      try {
        final List<SleepLog> local = await _local.querySleepLogs(
          userId,
          from: from,
          to: to,
        );
        return Right<Failure, List<SleepLog>>(local);
      } catch (localErr, localSt) {
        LoggerService.e(
          'getSleepLogs local fallback also failed',
          localErr,
          localSt,
        );
        return Left<Failure, List<SleepLog>>(
          const CacheFailure(
            'Unable to load sleep logs. Please check your connection.',
          ),
        );
      }
    }
  }
}
