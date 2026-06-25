import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_type.dart';
import 'health_local_datasource.dart';

class InMemoryHealthLocalDatasource implements HealthLocalDatasource {
  final Map<String, VitalEntry> _vitals = <String, VitalEntry>{};
  final Map<String, Map<String, dynamic>> _labs =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _meds =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> _menstrual =
      <String, Map<String, dynamic>>{};
  final Map<String, ({String text, DateTime expiresAt})> _insight =
      <String, ({String text, DateTime expiresAt})>{};

  @override
  Future<void> upsertVital(VitalEntry entry, {required bool synced}) async {
    _vitals[entry.id] = entry;
  }

  @override
  Future<void> markVitalSynced(String vitalId) async {}

  @override
  Future<void> deleteVitalLocal(String vitalId) async {
    _vitals.remove(vitalId);
  }

  @override
  Future<List<VitalEntry>> queryVitals(
    String userId, {
    VitalType? type,
    int limit = 100,
  }) async {
    List<VitalEntry> list = _vitals.values
        .where((VitalEntry v) => v.userId == userId)
        .where((VitalEntry v) => type == null || v.type == type)
        .toList();
    list.sort(
      (VitalEntry a, VitalEntry b) => b.recordedAt.compareTo(a.recordedAt),
    );
    if (list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }

  @override
  Future<void> upsertLabReportJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime scannedAt,
    required String status,
    required bool synced,
  }) async {
    _labs[id] = <String, dynamic>{
      'userId': userId,
      'payloadJson': payloadJson,
      'scannedAt': scannedAt,
      'status': status,
    };
  }

  @override
  Future<void> upsertMedicationJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {
    _meds[id] = <String, dynamic>{'userId': userId, 'payloadJson': payloadJson};
  }

  @override
  Future<void> deleteMedicationLocal(String medicationId) async {
    _meds.remove(medicationId);
  }

  @override
  Future<void> upsertMenstrualJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {
    _menstrual[id] = <String, dynamic>{
      'userId': userId,
      'payloadJson': payloadJson,
    };
  }

  @override
  Future<void> setHealthInsightCache({
    required String userId,
    required String text,
    required DateTime expiresAt,
  }) async {
    _insight[userId] = (text: text, expiresAt: expiresAt);
  }

  @override
  Future<({String text, DateTime expiresAt})?> getHealthInsightCache(
    String userId,
  ) async {
    return _insight[userId];
  }
}
