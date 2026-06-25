import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/workout_local_datasource.dart';
import '../exercise_seed.dart';
import '../models/exercise_model.dart';

/// Local seed + optional Firestore `exercises/` + per-user custom exercises.
class ExerciseRepositoryImpl implements ExerciseRepository {
  ExerciseRepositoryImpl(
    this._firestore,
    this._local,
  );

  final FirebaseFirestore _firestore;
  final WorkoutLocalDatasource _local;

  CollectionReference<Map<String, dynamic>> _custom(String userId) =>
      _firestore.collection('users').doc(userId).collection('custom_exercises');

  CollectionReference<Map<String, dynamic>> get _global =>
      _firestore.collection('exercises');

  Future<void> _ensureSeeded() async {
    if (await _local.isExerciseLibrarySeeded()) {
      return;
    }
    for (final Exercise e in buildBundledExerciseSeed()) {
      await _local.upsertExerciseCache(e);
    }
    await _local.markExerciseLibrarySeeded();
  }

  @override
  Future<void> seedExercises() async {
    try {
      await _ensureSeeded();
      // Merge-write: creates docs that don't exist yet without overwriting
      // fields (like videoUrl) that an admin may have edited in the console.
      final WriteBatch batch = _firestore.batch();
      for (final Exercise e in buildBundledExerciseSeed()) {
        batch.set(
          _global.doc(e.id),
          ExerciseModel.fromEntity(e).toFirestore(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    } catch (e, st) {
      LoggerService.e('seedExercises', e, st);
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> getExercises({
    MuscleGroup? muscleGroup,
    Equipment? equipment,
    DifficultyLevel? difficulty,
    int limit = 200,
  }) async {
    try {
      await _ensureSeeded();
      List<Exercise> list = await _local.getAllCachedExercises();
      if (muscleGroup != null) {
        list = list
            .where((Exercise e) => e.muscleGroups.contains(muscleGroup))
            .toList();
      }
      if (equipment != null) {
        list =
            list.where((Exercise e) => e.equipment.contains(equipment)).toList();
      }
      if (difficulty != null) {
        list = list.where((Exercise e) => e.difficulty == difficulty).toList();
      }
      if (list.length > limit) {
        list = list.take(limit).toList();
      }
      return Right<Failure, List<Exercise>>(list);
    } catch (e, st) {
      LoggerService.e('getExercises', e, st);
      return Left<Failure, List<Exercise>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exercise?>> getExerciseById(String id) async {
    try {
      await _ensureSeeded();
      final List<Exercise> all = await _local.getAllCachedExercises();
      for (final Exercise e in all) {
        if (e.id == id) {
          return Right<Failure, Exercise?>(e);
        }
      }
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _global.doc(id).get();
      if (doc.exists) {
        final Exercise e = ExerciseModel.fromFirestore(doc).toEntity();
        await _local.upsertExerciseCache(e);
        return Right<Failure, Exercise?>(e);
      }
      return const Right<Failure, Exercise?>(null);
    } catch (e, st) {
      LoggerService.e('getExerciseById', e, st);
      return Left<Failure, Exercise?>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Exercise>>> searchExercises(String query) async {
    try {
      await _ensureSeeded();
      final String q = query.trim().toLowerCase();
      if (q.isEmpty) {
        return const Right<Failure, List<Exercise>>(<Exercise>[]);
      }
      final List<Exercise> all = await _local.getAllCachedExercises();
      final List<Exercise> out = all
          .where(
            (Exercise e) =>
                e.name.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q),
          )
          .take(50)
          .toList();
      return Right<Failure, List<Exercise>>(out);
    } catch (e, st) {
      LoggerService.e('searchExercises', e, st);
      return Left<Failure, List<Exercise>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> refreshExercisesFromRemote() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _global.get();
      int updated = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snap.docs) {
        final Exercise remote = ExerciseModel.fromFirestore(doc).toEntity();
        await _local.upsertExerciseCache(remote);
        updated++;
      }
      return Right<Failure, int>(updated);
    } catch (e, st) {
      LoggerService.e('refreshExercisesFromRemote', e, st);
      return Left<Failure, int>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Exercise>> saveCustomExercise(Exercise exercise) async {
    try {
      if (!exercise.id.startsWith('custom_')) {
        return const Left<Failure, Exercise>(
          ServerFailure('Custom exercise id must start with custom_'),
        );
      }
      final List<String> parts = exercise.id.split('_');
      if (parts.length < 3) {
        return const Left<Failure, Exercise>(
          ServerFailure('Invalid custom id format custom_{userId}_...'),
        );
      }
      final String userId = parts[1];
      await _custom(userId).doc(exercise.id).set(ExerciseModel.fromEntity(exercise).toJson());
      await _local.upsertExerciseCache(exercise);
      return Right<Failure, Exercise>(exercise);
    } catch (e, st) {
      LoggerService.e('saveCustomExercise', e, st);
      return Left<Failure, Exercise>(ServerFailure(e.toString()));
    }
  }
}
