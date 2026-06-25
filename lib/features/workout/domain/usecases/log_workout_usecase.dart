import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class LogWorkoutUseCase {
  LogWorkoutUseCase(this._repository);

  final WorkoutRepository _repository;

  Future<Either<Failure, WorkoutLog>> call(WorkoutLog log) =>
      _repository.saveWorkoutLog(log);
}
