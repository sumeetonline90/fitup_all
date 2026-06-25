import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/water_log.dart';
import '../repositories/diet_repository.dart';

class LogWaterUseCase {
  LogWaterUseCase(this._repository);

  final DietRepository _repository;

  Future<Either<Failure, WaterLog>> call(WaterLog log) =>
      _repository.saveWaterLog(log);
}
