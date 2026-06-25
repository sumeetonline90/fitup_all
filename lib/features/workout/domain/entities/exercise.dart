import 'package:freezed_annotation/freezed_annotation.dart';

import 'difficulty_level.dart';
import 'equipment.dart';
import 'exercise_type.dart';
import 'muscle_group.dart';

part 'exercise.freezed.dart';

/// Library exercise definition (catalog + custom).
@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    required String description,
    required List<MuscleGroup> muscleGroups,
    required List<Equipment> equipment,
    required DifficultyLevel difficulty,
    required WorkoutExerciseType type,
    required List<String> instructions,
    String? videoUrl,
    String? thumbnailUrl,
    required double caloriesPerMinute,
  }) = _Exercise;
}
