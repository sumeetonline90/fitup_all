import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal.dart';
import '../repositories/diet_repository.dart';

class LogMealUseCase {
  LogMealUseCase(this._repository);

  final DietRepository _repository;

  Future<Either<Failure, Meal>> call(Meal meal) => _repository.saveMeal(meal);
}
