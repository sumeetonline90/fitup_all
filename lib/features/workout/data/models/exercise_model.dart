import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/muscle_group.dart';

/// Firestore DTO for `exercises/{exerciseId}` and cache JSON.
class ExerciseModel {
  ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroups,
    required this.equipment,
    required this.difficulty,
    required this.type,
    required this.instructions,
    this.videoUrl,
    this.thumbnailUrl,
    required this.caloriesPerMinute,
  });

  factory ExerciseModel.fromEntity(Exercise e) {
    return ExerciseModel(
      id: e.id,
      name: e.name,
      description: e.description,
      muscleGroups: e.muscleGroups.map((MuscleGroup m) => m.name).toList(),
      equipment: e.equipment.map((Equipment x) => x.name).toList(),
      difficulty: e.difficulty.name,
      type: e.type.name,
      instructions: e.instructions,
      videoUrl: e.videoUrl,
      thumbnailUrl: e.thumbnailUrl,
      caloriesPerMinute: e.caloriesPerMinute,
    );
  }

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      muscleGroups: (json['muscleGroups'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      difficulty: json['difficulty'] as String? ?? 'beginner',
      type: json['type'] as String? ?? 'strength',
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      caloriesPerMinute: (json['caloriesPerMinute'] as num?)?.toDouble() ?? 5,
    );
  }

  factory ExerciseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> json = doc.data() ?? <String, dynamic>{};
    return ExerciseModel.fromJson(<String, dynamic>{
      'id': doc.id,
      ...json,
    });
  }

  final String id;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final List<String> equipment;
  final String difficulty;
  final String type;
  final List<String> instructions;
  final String? videoUrl;
  final String? thumbnailUrl;
  final double caloriesPerMinute;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'muscleGroups': muscleGroups,
      'equipment': equipment,
      'difficulty': difficulty,
      'type': type,
      'instructions': instructions,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'caloriesPerMinute': caloriesPerMinute,
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  Exercise toEntity() {
    return Exercise(
      id: id,
      name: name,
      description: description,
      muscleGroups: muscleGroups
          .map(
            (String s) =>
                MuscleGroup.values.firstWhere(
                  (MuscleGroup v) => v.name == s,
                  orElse: () => MuscleGroup.fullBody,
                ),
          )
          .toList(),
      equipment: equipment
          .map(
            (String s) =>
                Equipment.values.firstWhere(
                  (Equipment v) => v.name == s,
                  orElse: () => Equipment.none,
                ),
          )
          .toList(),
      difficulty: DifficultyLevel.values.firstWhere(
        (DifficultyLevel v) => v.name == difficulty,
        orElse: () => DifficultyLevel.beginner,
      ),
      type: WorkoutExerciseType.values.firstWhere(
        (WorkoutExerciseType v) => v.name == type,
        orElse: () => WorkoutExerciseType.strength,
      ),
      instructions: instructions,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caloriesPerMinute: caloriesPerMinute,
    );
  }
}
