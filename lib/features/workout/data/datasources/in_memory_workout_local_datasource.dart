import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import 'workout_local_datasource.dart';

/// Web / test fallback.
class InMemoryWorkoutLocalDatasource implements WorkoutLocalDatasource {
  final Map<String, Exercise> _exercises = <String, Exercise>{};
  bool _seeded = false;
  final Map<String, PersonalRecord> _prs = <String, PersonalRecord>{};
  String? _planJson;
  DateTime? _planExp;
  final Map<String, WorkoutLog> _logs = <String, WorkoutLog>{};

  @override
  Future<void> upsertExerciseCache(Exercise exercise) async {
    _exercises[exercise.id] = exercise;
  }

  @override
  Future<List<Exercise>> getAllCachedExercises() async {
    return _exercises.values.toList();
  }

  @override
  Future<void> markExerciseLibrarySeeded() async {
    _seeded = true;
  }

  @override
  Future<bool> isExerciseLibrarySeeded() async => _seeded;

  @override
  Future<void> upsertPersonalRecordCache(PersonalRecord record) async {
    _prs['${record.userId}|${record.exerciseId}'] = record;
  }

  @override
  Future<List<PersonalRecord>> getCachedPersonalRecords(String userId) async {
    return _prs.values.where((PersonalRecord p) => p.userId == userId).toList();
  }

  @override
  Future<void> cacheGeneratedWorkoutPlan({
    required String userId,
    required String payloadJson,
    required DateTime expiresAt,
  }) async {
    _planJson = payloadJson;
    _planExp = expiresAt;
  }

  @override
  Future<String?> getCachedWorkoutPlanJson(String userId) async {
    if (_planJson == null || _planExp == null || _planExp!.isBefore(DateTime.now())) {
      return null;
    }
    return _planJson;
  }

  @override
  Future<void> upsertWorkoutLogLocal(WorkoutLog log, {required bool synced}) async {
    _logs[log.id] = log;
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsLocal(String userId) async {
    return _logs.values.where((WorkoutLog l) => l.userId == userId).toList();
  }
}
