import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/diet_summary.dart';
import '../repositories/diet_repository.dart';

class GetDailySummaryUseCase {
  GetDailySummaryUseCase(this._repository);

  final DietRepository _repository;

  Future<Either<Failure, DietSummary>> call(String userId, DateTime date) =>
      _repository.getDailySummary(userId, date);
}
