import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/lab_report_scan.dart';
import '../entities/medication_log.dart';
import '../entities/menstrual_cycle.dart';
import '../entities/vital_entry.dart';
import '../entities/vital_type.dart';
import '../entities/health_summary.dart';

abstract class HealthRepository {
  Future<Either<Failure, VitalEntry>> saveVitalEntry(VitalEntry entry);
  Future<Either<Failure, Unit>> deleteVitalEntry(
    String userId,
    String vitalEntryId,
  );

  Future<Either<Failure, List<VitalEntry>>> getVitalsForType(
    String userId,
    VitalType type, {
    int limit = 30,
  });

  Future<Either<Failure, HealthSummary>> getHealthSummary(String userId);

  Stream<Either<Failure, List<VitalEntry>>> watchRecentVitals(
    String userId, {
    int limit = 10,
  });

  Future<Either<Failure, LabReportScan>> saveLabReportScan(LabReportScan scan);

  Future<Either<Failure, List<LabReportScan>>> getLabReportHistory(
    String userId,
  );

  Future<Either<Failure, MedicationLog>> saveMedication(MedicationLog log);

  Future<Either<Failure, List<MedicationLog>>> getActiveMedications(
    String userId,
  );

  /// [userId] required for Firestore path `users/{userId}/medications/{id}`.
  Future<Either<Failure, Unit>> deleteMedication(
    String userId,
    String medicationId,
  );

  Future<Either<Failure, MenstrualCycle>> saveMenstrualCycle(
    MenstrualCycle cycle,
  );

  Future<Either<Failure, List<MenstrualCycle>>> getMenstrualHistory(
    String userId, {
    int limit = 6,
  });

  Future<Either<Failure, Unit>> updateMenstrualCycle(MenstrualCycle cycle);
}
