import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/equipment.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';

/// Firestore DTOs for workout plans and logs.
class WorkoutPlanModel {
  WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.goals,
    required this.fitnessLevel,
    required this.equipment,
    required this.daysPerWeek,
    required this.sessions,
    required this.isAIGenerated,
    required this.createdAt,
    required this.isActive,
  });

  factory WorkoutPlanModel.fromEntity(WorkoutPlan e) {
    return WorkoutPlanModel(
      id: e.id,
      userId: e.userId,
      name: e.name,
      description: e.description,
      goals: e.goals,
      fitnessLevel: e.fitnessLevel,
      equipment: e.equipment.map((Equipment x) => x.name).toList(),
      daysPerWeek: e.daysPerWeek,
      sessions: e.sessions.map(WorkoutSessionModel.fromEntity).toList(),
      isAIGenerated: e.isAIGenerated,
      createdAt: e.createdAt,
      isActive: e.isActive,
    );
  }

  factory WorkoutPlanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> json = doc.data() ?? <String, dynamic>{};
    return WorkoutPlanModel.fromJson(<String, dynamic>{
      'id': doc.id,
      ...json,
    });
  }

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      goals: (json['goals'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      fitnessLevel: json['fitnessLevel'] as String? ?? 'beginner',
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? 3,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map(
                (dynamic e) => WorkoutSessionModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const <WorkoutSessionModel>[],
      isAIGenerated: json['isAIGenerated'] as bool? ?? false,
      createdAt: _readDate(json['createdAt']),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> goals;
  final String fitnessLevel;
  final List<String> equipment;
  final int daysPerWeek;
  final List<WorkoutSessionModel> sessions;
  final bool isAIGenerated;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'goals': goals,
      'fitnessLevel': fitnessLevel,
      'equipment': equipment,
      'daysPerWeek': daysPerWeek,
      'sessions': sessions.map((WorkoutSessionModel s) => s.toJson()).toList(),
      'isAIGenerated': isAIGenerated,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  WorkoutPlan toEntity() {
    return WorkoutPlan(
      id: id,
      userId: userId,
      name: name,
      description: description,
      goals: goals,
      fitnessLevel: fitnessLevel,
      equipment: equipment
          .map(
            (String s) => Equipment.values.firstWhere(
              (Equipment v) => v.name == s,
              orElse: () => Equipment.none,
            ),
          )
          .toList(),
      daysPerWeek: daysPerWeek,
      sessions: sessions.map((WorkoutSessionModel s) => s.toEntity()).toList(),
      isAIGenerated: isAIGenerated,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}

class WorkoutSessionModel {
  WorkoutSessionModel({
    required this.id,
    required this.name,
    this.dayOfWeek,
    required this.exercises,
    required this.estimatedDurationMinutes,
    required this.targetMuscleGroups,
  });

  factory WorkoutSessionModel.fromEntity(WorkoutSession e) {
    return WorkoutSessionModel(
      id: e.id,
      name: e.name,
      dayOfWeek: e.dayOfWeek,
      exercises: e.exercises.map(SessionExerciseModel.fromEntity).toList(),
      estimatedDurationMinutes: e.estimatedDurationMinutes,
      targetMuscleGroups:
          e.targetMuscleGroups.map((MuscleGroup m) => m.name).toList(),
    );
  }

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map(
                (dynamic e) => SessionExerciseModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const <SessionExerciseModel>[],
      estimatedDurationMinutes:
          (json['estimatedDurationMinutes'] as num?)?.toInt() ?? 30,
      targetMuscleGroups: (json['targetMuscleGroups'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  final String id;
  final String name;
  final int? dayOfWeek;
  final List<SessionExerciseModel> exercises;
  final int estimatedDurationMinutes;
  final List<String> targetMuscleGroups;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'exercises': exercises.map((SessionExerciseModel e) => e.toJson()).toList(),
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'targetMuscleGroups': targetMuscleGroups,
    };
  }

  WorkoutSession toEntity() {
    return WorkoutSession(
      id: id,
      name: name,
      dayOfWeek: dayOfWeek,
      exercises: exercises.map((SessionExerciseModel e) => e.toEntity()).toList(),
      estimatedDurationMinutes: estimatedDurationMinutes,
      targetMuscleGroups: targetMuscleGroups
          .map(
            (String s) => MuscleGroup.values.firstWhere(
              (MuscleGroup v) => v.name == s,
              orElse: () => MuscleGroup.fullBody,
            ),
          )
          .toList(),
    );
  }
}

class SessionExerciseModel {
  SessionExerciseModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.reps,
    this.durationSeconds,
    required this.restSeconds,
    this.weightKg,
    this.notes,
  });

  factory SessionExerciseModel.fromEntity(SessionExercise e) {
    return SessionExerciseModel(
      exerciseId: e.exerciseId,
      exerciseName: e.exerciseName,
      sets: e.sets,
      reps: e.reps,
      durationSeconds: e.durationSeconds,
      restSeconds: e.restSeconds,
      weightKg: e.weightKg,
      notes: e.notes,
    );
  }

  factory SessionExerciseModel.fromJson(Map<String, dynamic> json) {
    return SessionExerciseModel(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 60,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int restSeconds;
  final double? weightKg;
  final String? notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restSeconds': restSeconds,
      'weightKg': weightKg,
      'notes': notes,
    };
  }

  SessionExercise toEntity() {
    return SessionExercise(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      restSeconds: restSeconds,
      weightKg: weightKg,
      notes: notes,
    );
  }
}

class WorkoutLogModel {
  WorkoutLogModel({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.completedSets,
    required this.totalCaloriesBurnt,
    this.notes,
    required this.fitcoinsEarned,
  });

  factory WorkoutLogModel.fromEntity(WorkoutLog e) {
    return WorkoutLogModel(
      id: e.id,
      userId: e.userId,
      sessionId: e.sessionId,
      sessionName: e.sessionName,
      startTime: e.startTime,
      endTime: e.endTime,
      completedSets: e.completedSets.map(CompletedSetModel.fromEntity).toList(),
      totalCaloriesBurnt: e.totalCaloriesBurnt,
      notes: e.notes,
      fitcoinsEarned: e.fitcoinsEarned,
    );
  }

  factory WorkoutLogModel.fromJson(Map<String, dynamic> json) {
    return WorkoutLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sessionId: json['sessionId'] as String,
      sessionName: json['sessionName'] as String,
      startTime: _readDate(json['startTime']),
      endTime: _readDate(json['endTime']),
      completedSets: (json['completedSets'] as List<dynamic>?)
              ?.map(
                (dynamic e) => CompletedSetModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList() ??
          const <CompletedSetModel>[],
      totalCaloriesBurnt: (json['totalCaloriesBurnt'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      fitcoinsEarned: (json['fitcoinsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  factory WorkoutLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> json = doc.data() ?? <String, dynamic>{};
    return WorkoutLogModel.fromJson(<String, dynamic>{'id': doc.id, ...json});
  }

  final String id;
  final String userId;
  final String sessionId;
  final String sessionName;
  final DateTime startTime;
  final DateTime endTime;
  final List<CompletedSetModel> completedSets;
  final double totalCaloriesBurnt;
  final String? notes;
  final int fitcoinsEarned;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'sessionId': sessionId,
      'sessionName': sessionName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'completedSets':
          completedSets.map((CompletedSetModel c) => c.toJson()).toList(),
      'totalCaloriesBurnt': totalCaloriesBurnt,
      'notes': notes,
      'fitcoinsEarned': fitcoinsEarned,
    };
  }

  WorkoutLog toEntity() {
    return WorkoutLog(
      id: id,
      userId: userId,
      sessionId: sessionId,
      sessionName: sessionName,
      startTime: startTime,
      endTime: endTime,
      completedSets:
          completedSets.map((CompletedSetModel c) => c.toEntity()).toList(),
      totalCaloriesBurnt: totalCaloriesBurnt,
      notes: notes,
      fitcoinsEarned: fitcoinsEarned,
    );
  }
}

class CompletedSetModel {
  CompletedSetModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    this.reps,
    this.durationSeconds,
    this.weightKg,
    required this.isPersonalRecord,
  });

  factory CompletedSetModel.fromEntity(CompletedSet e) {
    return CompletedSetModel(
      exerciseId: e.exerciseId,
      exerciseName: e.exerciseName,
      setNumber: e.setNumber,
      reps: e.reps,
      durationSeconds: e.durationSeconds,
      weightKg: e.weightKg,
      isPersonalRecord: e.isPersonalRecord,
    );
  }

  factory CompletedSetModel.fromJson(Map<String, dynamic> json) {
    return CompletedSetModel(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      reps: (json['reps'] as num?)?.toInt(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      isPersonalRecord: json['isPersonalRecord'] as bool? ?? false,
    );
  }

  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int? reps;
  final int? durationSeconds;
  final double? weightKg;
  final bool isPersonalRecord;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'weightKg': weightKg,
      'isPersonalRecord': isPersonalRecord,
    };
  }

  CompletedSet toEntity() {
    return CompletedSet(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps,
      durationSeconds: durationSeconds,
      weightKg: weightKg,
      isPersonalRecord: isPersonalRecord,
    );
  }
}

class PersonalRecordModel {
  PersonalRecordModel({
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    this.maxWeightKg,
    this.maxReps,
    required this.achievedAt,
  });

  factory PersonalRecordModel.fromEntity(PersonalRecord e) {
    return PersonalRecordModel(
      userId: e.userId,
      exerciseId: e.exerciseId,
      exerciseName: e.exerciseName,
      maxWeightKg: e.maxWeightKg,
      maxReps: e.maxReps,
      achievedAt: e.achievedAt,
    );
  }

  factory PersonalRecordModel.fromJson(Map<String, dynamic> json) {
    return PersonalRecordModel(
      userId: json['userId'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      maxWeightKg: (json['maxWeightKg'] as num?)?.toDouble(),
      maxReps: (json['maxReps'] as num?)?.toInt(),
      achievedAt: _readDate(json['achievedAt']),
    );
  }

  factory PersonalRecordModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> json = doc.data() ?? <String, dynamic>{};
    return PersonalRecordModel.fromJson(<String, dynamic>{
      'exerciseId': doc.id,
      ...json,
    });
  }

  final String userId;
  final String exerciseId;
  final String exerciseName;
  final double? maxWeightKg;
  final int? maxReps;
  final DateTime achievedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'maxWeightKg': maxWeightKg,
      'maxReps': maxReps,
      'achievedAt': Timestamp.fromDate(achievedAt),
    };
  }

  PersonalRecord toEntity() {
    return PersonalRecord(
      userId: userId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      maxWeightKg: maxWeightKg,
      maxReps: maxReps,
      achievedAt: achievedAt,
    );
  }
}

DateTime _readDate(Object? raw) {
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String) {
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
  return DateTime.now();
}
