import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/food.dart';
import '../repositories/food_repository.dart';

class SearchFoodUseCase {
  SearchFoodUseCase(this._repository);

  final FoodRepository _repository;

  Future<Either<Failure, List<Food>>> call(
    String query, {
    int limit = 25,
    bool isIndian = false,
  }) =>
      _repository.searchFood(query, limit: limit, isIndian: isIndian);
}
