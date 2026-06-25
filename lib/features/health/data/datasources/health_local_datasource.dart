import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_type.dart';

abstract class HealthLocalDatasource {
  Future<void> upsertVital(VitalEntry entry, {required bool synced});

  Future<void> markVitalSynced(String vitalId);
  Future<void> deleteVitalLocal(String vitalId);

  Future<List<VitalEntry>> queryVitals(
    String userId, {
    VitalType? type,
    int limit = 100,
  });

  Future<void> upsertLabReportJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime scannedAt,
    required String status,
    required bool synced,
  });

  Future<void> upsertMedicationJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  });

  Future<void> deleteMedicationLocal(String medicationId);

  Future<void> upsertMenstrualJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  });

  Future<void> setHealthInsightCache({
    required String userId,
    required String text,
    required DateTime expiresAt,
  });

  Future<({String text, DateTime expiresAt})?> getHealthInsightCache(
    String userId,
  );
}
