import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/stress_score.dart';
import '../repositories/mental_wellbeing_repository.dart';

class GetStressScoreUseCase {
  GetStressScoreUseCase(this._repository);

  final MentalWellbeingRepository _repository;

  Future<Either<Failure, StressScore>> call(String userId) {
    return _repository.calculateAndSaveStressScore(userId);
  }
}
