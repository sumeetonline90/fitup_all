import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/vital_entry.dart';
import '../entities/vital_type.dart';
import '../repositories/health_repository.dart';

class GetVitalTrendsUseCase {
  GetVitalTrendsUseCase(this._repository);

  final HealthRepository _repository;

  Future<Either<Failure, List<VitalEntry>>> call(
    String userId,
    VitalType type, {
    int limit = 30,
  }) async {
    final Either<Failure, List<VitalEntry>> r =
        await _repository.getVitalsForType(userId, type, limit: limit);
    return r.map(
      (List<VitalEntry> list) => List<VitalEntry>.from(list)
        ..sort((VitalEntry a, VitalEntry b) => b.recordedAt.compareTo(a.recordedAt)),
    );
  }
}
