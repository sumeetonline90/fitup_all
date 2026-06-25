import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/difficulty_level.dart';
import '../entities/equipment.dart';
import '../entities/exercise.dart';
import '../entities/muscle_group.dart';

/// Exercise catalog (shared + custom per user in Firestore).
abstract class ExerciseRepository {
  Future<Either<Failure, List<Exercise>>> getExercises({
    MuscleGroup? muscleGroup,
    Equipment? equipment,
    DifficultyLevel? difficulty,
    int limit,
  });

  Future<Either<Failure, Exercise?>> getExerciseById(String id);

  Future<Either<Failure, List<Exercise>>> searchExercises(String query);

  Future<Either<Failure, Exercise>> saveCustomExercise(Exercise exercise);

  /// Seeds local Drift cache + Firestore `exercises` when empty (first launch).
  Future<void> seedExercises();

  /// Pulls latest exercises from Firestore `exercises/` and merges into local cache.
  /// Call periodically so admin-side video URL updates propagate to the client.
  Future<Either<Failure, int>> refreshExercisesFromRemote();
}
