import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/exercise.dart';
import '../repositories/exercise_repository.dart';

class SearchExercisesUseCase {
  SearchExercisesUseCase(this._repository);

  final ExerciseRepository _repository;

  Future<Either<Failure, List<Exercise>>> call(String query) =>
      _repository.searchExercises(query);
}
