import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/menstrual_cycle.dart';
import '../repositories/health_repository.dart';

class LogMenstrualCycleUseCase {
  LogMenstrualCycleUseCase(this._repository);

  final HealthRepository _repository;

  Future<Either<Failure, MenstrualCycle>> call(MenstrualCycle cycle) {
    return _repository.saveMenstrualCycle(cycle);
  }
}
