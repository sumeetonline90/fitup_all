import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/vital_entry.dart';
import '../entities/vital_type_extension.dart';
import '../repositories/health_repository.dart';

class LogVitalUseCase {
  LogVitalUseCase(this._repository);

  final HealthRepository _repository;

  Future<Either<Failure, VitalEntry>> call(VitalEntry entry) async {
    if (entry.type.isDerived) {
      return const Left<Failure, VitalEntry>(
        ValidationFailure('This vital is calculated automatically'),
      );
    }
    if (entry.value.isNaN || entry.value.isInfinite) {
      return const Left<Failure, VitalEntry>(ValidationFailure('Invalid value'));
    }
    if (entry.value.abs() > 1e9) {
      return const Left<Failure, VitalEntry>(
        ValidationFailure('Value outside plausible range'),
      );
    }
    return _repository.saveVitalEntry(entry);
  }
}
