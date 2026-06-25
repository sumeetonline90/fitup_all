import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';

/// Offline exercise catalog, PR cache, workout log queue.
abstract class WorkoutLocalDatasource {
  Future<void> upsertExerciseCache(Exercise exercise);

  Future<List<Exercise>> getAllCachedExercises();

  Future<void> markExerciseLibrarySeeded();

  Future<bool> isExerciseLibrarySeeded();

  Future<void> upsertPersonalRecordCache(PersonalRecord record);

  Future<List<PersonalRecord>> getCachedPersonalRecords(String userId);

  Future<void> cacheGeneratedWorkoutPlan({
    required String userId,
    required String payloadJson,
    required DateTime expiresAt,
  });

  Future<String?> getCachedWorkoutPlanJson(String userId);

  Future<void> upsertWorkoutLogLocal(WorkoutLog log, {required bool synced});

  Future<List<WorkoutLog>> getWorkoutLogsLocal(String userId);
}
