import 'package:freezed_annotation/freezed_annotation.dart';

import 'equipment.dart';
import 'muscle_group.dart';

part 'workout.freezed.dart';

@freezed
abstract class WorkoutPlan with _$WorkoutPlan {
  const factory WorkoutPlan({
    required String id,
    required String userId,
    required String name,
    required String description,
    required List<String> goals,
    required String fitnessLevel,
    required List<Equipment> equipment,
    required int daysPerWeek,
    required List<WorkoutSession> sessions,
    @Default(false) bool isAIGenerated,
    required DateTime createdAt,
    @Default(false) bool isActive,
  }) = _WorkoutPlan;
}

@freezed
abstract class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required String name,
    int? dayOfWeek,
    required List<SessionExercise> exercises,
    required int estimatedDurationMinutes,
    required List<MuscleGroup> targetMuscleGroups,
  }) = _WorkoutSession;
}

@freezed
abstract class SessionExercise with _$SessionExercise {
  const factory SessionExercise({
    required String exerciseId,
    required String exerciseName,
    required int sets,
    int? reps,
    int? durationSeconds,
    required int restSeconds,
    double? weightKg,
    String? notes,
  }) = _SessionExercise;
}

@freezed
abstract class WorkoutLog with _$WorkoutLog {
  const factory WorkoutLog({
    required String id,
    required String userId,
    required String sessionId,
    required String sessionName,
    required DateTime startTime,
    required DateTime endTime,
    required List<CompletedSet> completedSets,
    required double totalCaloriesBurnt,
    String? notes,
    @Default(0) int fitcoinsEarned,
  }) = _WorkoutLog;
}

@freezed
abstract class CompletedSet with _$CompletedSet {
  const factory CompletedSet({
    required String exerciseId,
    required String exerciseName,
    required int setNumber,
    int? reps,
    int? durationSeconds,
    double? weightKg,
    @Default(false) bool isPersonalRecord,
  }) = _CompletedSet;
}

@freezed
abstract class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    double? maxWeightKg,
    int? maxReps,
    required DateTime achievedAt,
  }) = _PersonalRecord;
}

@freezed
abstract class WorkoutSummary with _$WorkoutSummary {
  const factory WorkoutSummary({
    required int totalSessions,
    required int totalMinutes,
    required double totalCalories,
    required Map<MuscleGroup, int> muscleGroupFrequency,
    required int currentStreak,
    required int thisWeekSessions,
  }) = _WorkoutSummary;
}
