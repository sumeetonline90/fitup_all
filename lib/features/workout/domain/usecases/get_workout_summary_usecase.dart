import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/workout.dart';
import '../repositories/workout_repository.dart';

class GetWorkoutSummaryUseCase {
  GetWorkoutSummaryUseCase(this._repository);

  final WorkoutRepository _repository;

  Future<Either<Failure, WorkoutSummary>> call(String userId) =>
      _repository.getWorkoutSummary(userId);
}
