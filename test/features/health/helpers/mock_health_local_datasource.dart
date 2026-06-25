import 'package:fitup/features/health/data/datasources/health_local_datasource.dart';
import 'package:fitup/features/health/domain/entities/vital_entry.dart';
import 'package:fitup/features/health/domain/entities/vital_type.dart';
import 'package:mocktail/mocktail.dart';

class MockHealthLocalDatasource extends Mock implements HealthLocalDatasource {}

/// Minimal fake for tests that only need vital upsert + sync mark.
class FakeHealthLocalDatasource implements HealthLocalDatasource {
  final List<VitalEntry> upsertCalls = <VitalEntry>[];
  final List<bool> upsertSyncedFlags = <bool>[];
  final List<String> markSyncedIds = <String>[];
  final List<bool> menstrualSyncedFlags = <bool>[];
  final List<String> deleteVitalLocalIds = <String>[];

  @override
  Future<void> deleteMedicationLocal(String medicationId) async {}

  @override
  Future<({String text, DateTime expiresAt})?> getHealthInsightCache(
    String userId,
  ) async => null;

  @override
  Future<void> markVitalSynced(String vitalId) async {
    markSyncedIds.add(vitalId);
  }

  @override
  Future<void> deleteVitalLocal(String vitalId) async {
    deleteVitalLocalIds.add(vitalId);
  }

  @override
  Future<List<VitalEntry>> queryVitals(
    String userId, {
    VitalType? type,
    int limit = 100,
  }) async => <VitalEntry>[];

  @override
  Future<void> setHealthInsightCache({
    required String userId,
    required String text,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> upsertLabReportJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime scannedAt,
    required String status,
    required bool synced,
  }) async {}

  @override
  Future<void> upsertMedicationJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {}

  @override
  Future<void> upsertMenstrualJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {
    menstrualSyncedFlags.add(synced);
  }

  @override
  Future<void> upsertVital(VitalEntry entry, {required bool synced}) async {
    upsertCalls.add(entry);
    upsertSyncedFlags.add(synced);
  }
}
