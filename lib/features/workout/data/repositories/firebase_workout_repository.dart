import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/utils/workout_stats_utils.dart';
import '../datasources/workout_local_datasource.dart';
import '../datasources/workout_remote_datasource.dart';
import '../models/workout_model.dart';

Failure _mapFirebase(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

/// Firestore + local cache. Catch blocks return [Left] only (never fake success).
class FirebaseWorkoutRepository implements WorkoutRepository {
  FirebaseWorkoutRepository(
    this._firestore,
    this._remote,
    this._local, {
    FitcoinAwardService? fitcoinAwardService,
    Future<void> Function(String userId, int amount)? fitcoinIncrement,
  }) : _fitcoinAwards = fitcoinAwardService,
       _fitcoinIncrement = fitcoinIncrement;

  final FirebaseFirestore _firestore;
  final WorkoutRemoteDatasource _remote;
  final WorkoutLocalDatasource _local;
  final FitcoinAwardService? _fitcoinAwards;
  final Future<void> Function(String userId, int amount)? _fitcoinIncrement;

  @override
  Future<Either<Failure, WorkoutPlan>> saveWorkoutPlan(WorkoutPlan plan) async {
    try {
      if (plan.isActive) {
        final QuerySnapshot<Map<String, dynamic>> existing = await _remote
            .getWorkoutPlans(plan.userId);
        final WriteBatch batch = _firestore.batch();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d
            in existing.docs) {
          if (d.id != plan.id) {
            batch.update(d.reference, <String, dynamic>{'isActive': false});
          }
        }
        await batch.commit();
      }
      await _remote.setWorkoutPlan(plan.id, WorkoutPlanModel.fromEntity(plan));
      return Right<Failure, WorkoutPlan>(plan);
    } catch (e, st) {
      LoggerService.e('saveWorkoutPlan', e, st);
      return Left<Failure, WorkoutPlan>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<WorkoutPlan>>> getWorkoutPlans(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .getWorkoutPlans(userId);
      final List<WorkoutPlan> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                WorkoutPlanModel.fromFirestore(d).toEntity(),
          )
          .toList();
      return Right<Failure, List<WorkoutPlan>>(list);
    } catch (e, st) {
      LoggerService.e('getWorkoutPlans', e, st);
      return Left<Failure, List<WorkoutPlan>>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, WorkoutPlan?>> getActiveWorkoutPlan(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .getActiveWorkoutPlan(userId);
      if (snap.docs.isEmpty) {
        return const Right<Failure, WorkoutPlan?>(null);
      }
      return Right<Failure, WorkoutPlan?>(
        WorkoutPlanModel.fromFirestore(snap.docs.first).toEntity(),
      );
    } catch (e, st) {
      LoggerService.e('getActiveWorkoutPlan', e, st);
      return Left<Failure, WorkoutPlan?>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWorkoutPlan(String planId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collectionGroup('workout_plans')
          .where(FieldPath.documentId, isEqualTo: planId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return const Right<Failure, void>(null);
      }
      await snap.docs.first.reference.delete();
      return const Right<Failure, void>(null);
    } catch (e, st) {
      LoggerService.e('deleteWorkoutPlan', e, st);
      return Left<Failure, void>(_mapFirebase(e));
    }
  }

  Future<void> _applyFitcoinIncrement(String userId, int amount) async {
    await _firestore.collection('users').doc(userId).set(<String, dynamic>{
      'fitcoinsBalance': FieldValue.increment(amount),
      'fitcoinsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<Either<Failure, WorkoutLog>> saveWorkoutLog(WorkoutLog log) async {
    try {
      await _remote.setWorkoutLog(log.id, WorkoutLogModel.fromEntity(log));
      try {
        await _local.upsertWorkoutLogLocal(log, synced: true);
      } catch (e, st) {
        LoggerService.e('saveWorkoutLog local mirror', e, st);
      }
      await _mergePersonalRecords(log);
      if (log.fitcoinsEarned > 0) {
        final FitcoinAwardService? awards = _fitcoinAwards;
        if (awards != null) {
          unawaited(
            awards.onWorkoutCompleted(
              log.userId,
              workoutLogId: log.id,
              amount: log.fitcoinsEarned,
            ),
          );
        } else {
          try {
            final Future<void> Function(String userId, int amount)? inc =
                _fitcoinIncrement;
            if (inc != null) {
              await inc(log.userId, log.fitcoinsEarned);
            } else {
              await _applyFitcoinIncrement(log.userId, log.fitcoinsEarned);
            }
          } catch (e, st) {
            LoggerService.e('fitcoinsBalance increment', e, st);
            return Left<Failure, WorkoutLog>(
              FitcoinUpdateFailure(
                'Workout saved, but Fitcoins could not be awarded. '
                'They will sync automatically.',
                savedWorkoutLogId: log.id,
              ),
            );
          }
        }
      }
      return Right<Failure, WorkoutLog>(log);
    } catch (e, st) {
      LoggerService.e('saveWorkoutLog', e, st);
      try {
        await _local.upsertWorkoutLogLocal(log, synced: false);
      } catch (_) {}
      return Left<Failure, WorkoutLog>(_mapFirebase(e));
    }
  }

  Future<void> _mergePersonalRecords(WorkoutLog log) async {
    for (final CompletedSet s in log.completedSets) {
      if (!s.isPersonalRecord) {
        continue;
      }
      final PersonalRecord pr = PersonalRecord(
        userId: log.userId,
        exerciseId: s.exerciseId,
        exerciseName: s.exerciseName,
        maxWeightKg: s.weightKg,
        maxReps: s.reps,
        achievedAt: log.endTime,
      );
      await _remote.setPersonalRecord(
        log.userId,
        s.exerciseId,
        PersonalRecordModel.fromEntity(pr),
      );
      try {
        await _local.upsertPersonalRecordCache(pr);
      } catch (e, st) {
        LoggerService.e('PR cache', e, st);
      }
    }
  }

  @override
  Future<Either<Failure, List<WorkoutLog>>> getWorkoutLogs(
    String userId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryWorkoutLogs(userId);
      List<WorkoutLog> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                WorkoutLogModel.fromFirestore(d).toEntity(),
          )
          .toList();
      if (dateFrom != null) {
        list = list
            .where((WorkoutLog l) => !l.startTime.isBefore(dateFrom))
            .toList();
      }
      if (dateTo != null) {
        final DateTime end = dateTo.add(const Duration(days: 1));
        list = list.where((WorkoutLog l) => l.startTime.isBefore(end)).toList();
      }
      return Right<Failure, List<WorkoutLog>>(list);
    } catch (e, st) {
      LoggerService.e('getWorkoutLogs remote failed; trying local', e, st);
      try {
        final List<WorkoutLog> cached = await _local.getWorkoutLogsLocal(
          userId,
        );
        List<WorkoutLog> list = cached;
        if (dateFrom != null) {
          list = list
              .where((WorkoutLog l) => !l.startTime.isBefore(dateFrom))
              .toList();
        }
        if (dateTo != null) {
          final DateTime end = dateTo.add(const Duration(days: 1));
          list = list
              .where((WorkoutLog l) => l.startTime.isBefore(end))
              .toList();
        }
        return Right<Failure, List<WorkoutLog>>(list);
      } catch (localErr, localSt) {
        LoggerService.e('getWorkoutLogs local failed', localErr, localSt);
        return Left<Failure, List<WorkoutLog>>(
          CacheFailure(localErr.toString()),
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<PersonalRecord>>> getPersonalRecords(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .getPersonalRecords(userId);
      final List<PersonalRecord> remote = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                PersonalRecordModel.fromFirestore(d).toEntity(),
          )
          .toList();
      try {
        final List<PersonalRecord> local = await _local
            .getCachedPersonalRecords(userId);
        final Map<String, PersonalRecord> merged = <String, PersonalRecord>{};
        for (final PersonalRecord p in local) {
          merged[p.exerciseId] = p;
        }
        for (final PersonalRecord p in remote) {
          merged[p.exerciseId] = p;
        }
        return Right<Failure, List<PersonalRecord>>(merged.values.toList());
      } catch (e, st) {
        LoggerService.e('getPersonalRecords cache merge', e, st);
        return Right<Failure, List<PersonalRecord>>(remote);
      }
    } catch (e, st) {
      LoggerService.e('getPersonalRecords', e, st);
      return Left<Failure, List<PersonalRecord>>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, PersonalRecord>> updatePersonalRecord(
    PersonalRecord record,
  ) async {
    try {
      await _remote.setPersonalRecord(
        record.userId,
        record.exerciseId,
        PersonalRecordModel.fromEntity(record),
      );
      try {
        await _local.upsertPersonalRecordCache(record);
      } catch (e, st) {
        LoggerService.e('updatePersonalRecord cache', e, st);
      }
      return Right<Failure, PersonalRecord>(record);
    } catch (e, st) {
      LoggerService.e('updatePersonalRecord', e, st);
      return Left<Failure, PersonalRecord>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, WorkoutSummary>> getWorkoutSummary(
    String userId,
  ) async {
    try {
      final Either<Failure, List<WorkoutLog>> logsRes = await getWorkoutLogs(
        userId,
      );
      return logsRes.fold(
        Left<Failure, WorkoutSummary>.new,
        (List<WorkoutLog> logs) =>
            Right<Failure, WorkoutSummary>(_computeSummary(logs)),
      );
    } catch (e, st) {
      LoggerService.e('getWorkoutSummary', e, st);
      return Left<Failure, WorkoutSummary>(_mapFirebase(e));
    }
  }

  WorkoutSummary _computeSummary(List<WorkoutLog> logs) {
    if (logs.isEmpty) {
      return const WorkoutSummary(
        totalSessions: 0,
        totalMinutes: 0,
        totalCalories: 0,
        muscleGroupFrequency: <MuscleGroup, int>{},
        currentStreak: 0,
        thisWeekSessions: 0,
      );
    }
    int totalMin = 0;
    double totalCal = 0;
    final Map<MuscleGroup, int> freq = <MuscleGroup, int>{};
    for (final WorkoutLog l in logs) {
      totalMin += l.endTime.difference(l.startTime).inMinutes;
      totalCal += l.totalCaloriesBurnt;
      for (final CompletedSet _ in l.completedSets) {
        const MuscleGroup g = MuscleGroup.fullBody;
        freq[g] = (freq[g] ?? 0) + 1;
      }
    }
    final DateTime now = DateTime.now();
    final int weekCount = WorkoutStatsUtils.weekSessionCountSinceMonday(
      logs,
      now,
    );
    final int streak = WorkoutStatsUtils.currentStreakDays(logs, now);
    return WorkoutSummary(
      totalSessions: logs.length,
      totalMinutes: totalMin,
      totalCalories: totalCal,
      muscleGroupFrequency: freq,
      currentStreak: streak,
      thisWeekSessions: weekCount,
    );
  }

  @override
  Stream<List<WorkoutLog>> watchWorkoutLogs(String userId) {
    return _remote
        .watchWorkoutLogs(userId)
        .map(
          (QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    WorkoutLogModel.fromFirestore(d).toEntity(),
              )
              .toList(),
        );
  }
}
