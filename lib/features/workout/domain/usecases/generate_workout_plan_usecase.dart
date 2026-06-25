import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../entities/equipment.dart';
import '../entities/exercise.dart';
import '../entities/workout.dart';
import '../entities/workout_user_profile.dart';
import '../repositories/exercise_repository.dart';
import '../repositories/workout_repository.dart';

class GenerateWorkoutPlanUseCase {
  GenerateWorkoutPlanUseCase(
    this._ai,
    this._workouts,
    this._exercises,
  );

  final AiService _ai;
  final WorkoutRepository _workouts;
  final ExerciseRepository _exercises;

  Future<Either<Failure, WorkoutPlan>> call({
    required WorkoutUserProfile profile,
    required List<String> goals,
    required List<Equipment> equipment,
    required String fitnessLevel,
    required int daysPerWeek,
  }) async {
    final Either<Failure, List<Exercise>> lib =
        await _exercises.getExercises(limit: 300);
    return lib.fold(
      (Failure f) async => Left<Failure, WorkoutPlan>(f),
      (List<Exercise> exercises) async {
        final Either<Failure, WorkoutPlan> generated =
            await _ai.generateWorkoutPlan(
          profile: profile,
          goals: goals,
          equipment: equipment,
          fitnessLevel: fitnessLevel,
          daysPerWeek: daysPerWeek,
          approvedExerciseNames:
              exercises.map((Exercise e) => e.name).toList(),
        );
        return generated.fold(
          (Failure f) async => Left<Failure, WorkoutPlan>(f),
          (WorkoutPlan plan) async => await _workouts.saveWorkoutPlan(plan),
        );
      },
    );
  }
}
