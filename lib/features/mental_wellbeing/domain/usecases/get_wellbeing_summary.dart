import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/mental_wellbeing_summary.dart';
import '../repositories/mental_wellbeing_repository.dart';

class GetWellbeingSummaryUseCase {
  GetWellbeingSummaryUseCase(this._repository);

  final MentalWellbeingRepository _repository;

  Future<Either<Failure, MentalWellbeingSummary>> call(String userId) {
    return _repository.getMentalWellbeingSummary(userId);
  }
}
