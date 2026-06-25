import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/food.dart';

/// Food search + catalog (cache + remote).
abstract class FoodRepository {
  Future<Either<Failure, List<Food>>> searchFood(
    String query, {
    int limit,
    bool isIndian,
  });

  Future<Either<Failure, Food?>> getFoodByBarcode(String barcode);

  Future<Either<Failure, Food>> saveCustomFood(Food food);

  Future<Either<Failure, List<Food>>> getRecentFoods(String userId);

  Future<Either<Failure, List<Food>>> getFrequentFoods(String userId);
}
