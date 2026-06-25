import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/workout.dart';

/// Workout plans, logs, PRs, and aggregates.
abstract class WorkoutRepository {
  Future<Either<Failure, WorkoutPlan>> saveWorkoutPlan(WorkoutPlan plan);

  Future<Either<Failure, List<WorkoutPlan>>> getWorkoutPlans(String userId);

  Future<Either<Failure, WorkoutPlan?>> getActiveWorkoutPlan(String userId);

  Future<Either<Failure, void>> deleteWorkoutPlan(String planId);

  Future<Either<Failure, WorkoutLog>> saveWorkoutLog(WorkoutLog log);

  Future<Either<Failure, List<WorkoutLog>>> getWorkoutLogs(
    String userId, {
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<Either<Failure, List<PersonalRecord>>> getPersonalRecords(
    String userId,
  );

  Future<Either<Failure, PersonalRecord>> updatePersonalRecord(
    PersonalRecord record,
  );

  Future<Either<Failure, WorkoutSummary>> getWorkoutSummary(String userId);

  Stream<List<WorkoutLog>> watchWorkoutLogs(String userId);
}
