import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_input_sanitizer.dart';
import '../entities/medication_log.dart';
import '../repositories/health_repository.dart';

class AddMedicationUseCase {
  AddMedicationUseCase(this._repository);

  final HealthRepository _repository;

  Future<Either<Failure, MedicationLog>> call(MedicationLog log) {
    final String name =
        AiInputSanitizer.sanitizeContextSnippet(log.medicationName, maxLength: 200);
    final String dose =
        AiInputSanitizer.sanitizeContextSnippet(log.dose, maxLength: 80);
    final String freq =
        AiInputSanitizer.sanitizeContextSnippet(log.frequency, maxLength: 120);
    if (name.isEmpty) {
      return Future<Either<Failure, MedicationLog>>.value(
        const Left<Failure, MedicationLog>(ValidationFailure('Name required')),
      );
    }
    return _repository.saveMedication(
      MedicationLog(
        id: log.id,
        userId: log.userId,
        medicationName: name,
        dose: dose,
        frequency: freq,
        reminderTime: log.reminderTime,
        isActive: log.isActive,
        startDate: log.startDate,
        endDate: log.endDate,
      ),
    );
  }
}
