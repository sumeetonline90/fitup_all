import '../../domain/entities/equipment.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';

String _id(String prefix, int index) =>
    '${prefix}_${index}_${DateTime.now().microsecondsSinceEpoch}';

/// Maps Gemini JSON into domain [WorkoutPlan] (best-effort).
WorkoutPlan parseAiWorkoutPlanJson({
  required Map<String, dynamic> json,
  required String userId,
  required bool isAiGenerated,
}) {
  final String planId = _id('plan', 0);
  final List<dynamic> sessionsRaw = json['sessions'] as List<dynamic>? ?? <dynamic>[];
  final List<WorkoutSession> sessions = <WorkoutSession>[];
  int si = 0;
  for (final dynamic s in sessionsRaw) {
    if (s is! Map<String, dynamic>) {
      continue;
    }
    final String sid = _id('sess', si);
    final List<dynamic> exRaw = s['exercises'] as List<dynamic>? ?? <dynamic>[];
    final List<SessionExercise> exercises = <SessionExercise>[];
    for (final dynamic e in exRaw) {
      if (e is! Map<String, dynamic>) {
        continue;
      }
      exercises.add(
        SessionExercise(
          exerciseId: e['exerciseId'] as String? ?? 'unknown',
          exerciseName: e['exerciseName'] as String? ?? 'Exercise',
          sets: (e['sets'] as num?)?.toInt() ?? 3,
          reps: (e['reps'] as num?)?.toInt(),
          durationSeconds: (e['durationSeconds'] as num?)?.toInt(),
          restSeconds: (e['restSeconds'] as num?)?.toInt() ?? 60,
          weightKg: (e['weightKg'] as num?)?.toDouble(),
          notes: e['notes'] as String?,
        ),
      );
    }
    sessions.add(
      WorkoutSession(
        id: sid,
        name: s['name'] as String? ?? 'Session ${si + 1}',
        dayOfWeek: (s['dayOfWeek'] as num?)?.toInt(),
        exercises: exercises,
        estimatedDurationMinutes:
            (s['estimatedDurationMinutes'] as num?)?.toInt() ?? 45,
        targetMuscleGroups: _parseMuscleList(s['targetMuscleGroups']),
      ),
    );
    si++;
  }
  return WorkoutPlan(
    id: planId,
    userId: userId,
    name: json['name'] as String? ?? 'AI Workout Plan',
    description: json['description'] as String? ?? '',
    goals: (json['goals'] as List<dynamic>?)?.map((dynamic e) => e.toString()).toList() ??
        const <String>[],
    fitnessLevel: json['fitnessLevel'] as String? ?? 'beginner',
    equipment: _parseEquipmentList(json['equipment']),
    daysPerWeek: (json['daysPerWeek'] as num?)?.toInt() ?? sessions.length,
    sessions: sessions,
    isAIGenerated: isAiGenerated,
    createdAt: DateTime.now(),
    isActive: json['isActive'] as bool? ?? true,
  );
}

List<MuscleGroup> _parseMuscleList(Object? raw) {
  if (raw is! List<dynamic>) {
    return <MuscleGroup>[MuscleGroup.fullBody];
  }
  final List<MuscleGroup> out = <MuscleGroup>[];
  for (final dynamic e in raw) {
    final String s = e.toString();
    try {
      out.add(
        MuscleGroup.values.firstWhere(
          (MuscleGroup v) => v.name == s,
        ),
      );
    } catch (_) {}
  }
  return out.isEmpty ? <MuscleGroup>[MuscleGroup.fullBody] : out;
}

List<Equipment> _parseEquipmentList(Object? raw) {
  if (raw is! List<dynamic>) {
    return <Equipment>[Equipment.none];
  }
  final List<Equipment> out = <Equipment>[];
  for (final dynamic e in raw) {
    final String s = e.toString();
    try {
      out.add(
        Equipment.values.firstWhere(
          (Equipment v) => v.name == s,
        ),
      );
    } catch (_) {}
  }
  return out.isEmpty ? <Equipment>[Equipment.none] : out;
}
