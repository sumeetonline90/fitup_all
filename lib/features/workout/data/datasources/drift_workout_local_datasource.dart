import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../../core/database/fitup_database.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import 'workout_local_datasource.dart';

/// Drift-backed workout cache (mobile/desktop).
class DriftWorkoutLocalDatasource implements WorkoutLocalDatasource {
  DriftWorkoutLocalDatasource(this._db);

  final FitupDatabase _db;

  static const String _metaSeedId = '__workout_seed_meta__';

  @override
  Future<void> upsertExerciseCache(Exercise exercise) async {
    final ExerciseModel m = ExerciseModel.fromEntity(exercise);
    await _db.into(_db.exerciseLibraryCache).insertOnConflictUpdate(
          ExerciseLibraryCacheCompanion.insert(
            id: exercise.id,
            payloadJson: jsonEncode(m.toJson()),
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<List<Exercise>> getAllCachedExercises() async {
    final List<ExerciseLibraryCacheRow> rows =
        await _db.select(_db.exerciseLibraryCache).get();
    final List<Exercise> out = <Exercise>[];
    for (final ExerciseLibraryCacheRow r in rows) {
      if (r.id == _metaSeedId) {
        continue;
      }
      try {
        final Map<String, dynamic> map =
            jsonDecode(r.payloadJson) as Map<String, dynamic>;
        out.add(ExerciseModel.fromJson(map).toEntity());
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<void> markExerciseLibrarySeeded() async {
    await _db.into(_db.exerciseLibraryCache).insertOnConflictUpdate(
          ExerciseLibraryCacheCompanion.insert(
            id: _metaSeedId,
            payloadJson: '{"seeded":true}',
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<bool> isExerciseLibrarySeeded() async {
    final ExerciseLibraryCacheRow? row = await (_db
            .select(_db.exerciseLibraryCache)
          ..where(($ExerciseLibraryCacheTable t) => t.id.equals(_metaSeedId)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> upsertPersonalRecordCache(PersonalRecord record) async {
    final PersonalRecordModel m = PersonalRecordModel.fromEntity(record);
    final String id = '${record.userId}|${record.exerciseId}';
    await _db.into(_db.personalRecordCache).insertOnConflictUpdate(
          PersonalRecordCacheCompanion.insert(
            id: id,
            userId: record.userId,
            exerciseId: record.exerciseId,
            payloadJson: jsonEncode(m.toJson()),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<List<PersonalRecord>> getCachedPersonalRecords(String userId) async {
    final List<PersonalRecordCacheRow> rows = await (_db
            .select(_db.personalRecordCache)
          ..where(($PersonalRecordCacheTable t) => t.userId.equals(userId)))
        .get();
    final List<PersonalRecord> out = <PersonalRecord>[];
    for (final PersonalRecordCacheRow r in rows) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(r.payloadJson) as Map<String, dynamic>;
        out.add(PersonalRecordModel.fromJson(map).toEntity());
      } catch (_) {}
    }
    return out;
  }

  @override
  Future<void> cacheGeneratedWorkoutPlan({
    required String userId,
    required String payloadJson,
    required DateTime expiresAt,
  }) async {
    await _db.into(_db.workoutPlanCache).insertOnConflictUpdate(
          WorkoutPlanCacheCompanion.insert(
            userId: userId,
            payloadJson: payloadJson,
            expiresAt: expiresAt,
          ),
        );
  }

  @override
  Future<String?> getCachedWorkoutPlanJson(String userId) async {
    final WorkoutPlanCacheRow? row = await (_db.select(_db.workoutPlanCache)
          ..where(($WorkoutPlanCacheTable t) => t.userId.equals(userId)))
        .getSingleOrNull();
    if (row == null || row.expiresAt.isBefore(DateTime.now())) {
      return null;
    }
    return row.payloadJson;
  }

  @override
  Future<void> upsertWorkoutLogLocal(WorkoutLog log, {required bool synced}) async {
    final WorkoutLogModel m = WorkoutLogModel.fromEntity(log);
    await _db.into(_db.workoutLogCache).insertOnConflictUpdate(
          WorkoutLogCacheCompanion.insert(
            id: log.id,
            userId: log.userId,
            payloadJson: jsonEncode(m.toJson()),
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<List<WorkoutLog>> getWorkoutLogsLocal(String userId) async {
    final List<WorkoutLogCacheRow> rows = await (_db.select(_db.workoutLogCache)
          ..where(($WorkoutLogCacheTable t) => t.userId.equals(userId)))
        .get();
    final List<WorkoutLog> out = <WorkoutLog>[];
    for (final WorkoutLogCacheRow r in rows) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(r.payloadJson) as Map<String, dynamic>;
        out.add(WorkoutLogModel.fromJson(map).toEntity());
      } catch (_) {}
    }
    return out;
  }
}
