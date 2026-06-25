import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/diet_summary.dart';
import '../repositories/diet_repository.dart';

class GetWeeklyNutritionUseCase {
  GetWeeklyNutritionUseCase(this._repository);

  final DietRepository _repository;

  Future<Either<Failure, Map<String, DietSummary>>> call(String userId) =>
      _repository.getWeeklyNutrition(userId);
}
