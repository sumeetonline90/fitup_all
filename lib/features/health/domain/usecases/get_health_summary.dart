import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/health_summary.dart';
import '../repositories/health_repository.dart';

class GetHealthSummaryUseCase {
  GetHealthSummaryUseCase(this._repository);

  final HealthRepository _repository;

  Future<Either<Failure, HealthSummary>> call(String userId) {
    return _repository.getHealthSummary(userId);
  }
}
