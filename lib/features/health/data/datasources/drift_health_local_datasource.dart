import 'package:drift/drift.dart';

import '../../../../core/database/fitup_database.dart';
import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_source.dart';
import '../../domain/entities/vital_type.dart';
import '../models/vital_entry_model.dart';
import 'health_local_datasource.dart';

class DriftHealthLocalDatasource implements HealthLocalDatasource {
  DriftHealthLocalDatasource(this._db);

  final FitupDatabase _db;

  @override
  Future<void> upsertVital(VitalEntry entry, {required bool synced}) async {
    final VitalEntryModel m = VitalEntryModel.fromEntity(entry);
    await _db
        .into(_db.healthVitals)
        .insertOnConflictUpdate(
          HealthVitalsCompanion.insert(
            id: m.id,
            userId: m.userId,
            type: m.type.name,
            value: m.value,
            unit: m.unit,
            recordedAt: m.recordedAt,
            source: m.source.name,
            notes: Value<String?>(m.notes),
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> markVitalSynced(String vitalId) async {
    await (_db.update(_db.healthVitals)
          ..where(($HealthVitalsTable t) => t.id.equals(vitalId)))
        .write(const HealthVitalsCompanion(synced: Value<bool>(true)));
  }

  @override
  Future<void> deleteVitalLocal(String vitalId) async {
    await (_db.delete(
      _db.healthVitals,
    )..where(($HealthVitalsTable t) => t.id.equals(vitalId))).go();
  }

  @override
  Future<List<VitalEntry>> queryVitals(
    String userId, {
    VitalType? type,
    int limit = 100,
  }) async {
    final SimpleSelectStatement<$HealthVitalsTable, HealthVitalRow> q =
        _db.select(_db.healthVitals)
          ..where(($HealthVitalsTable t) {
            Expression<bool> e = t.userId.equals(userId);
            if (type != null) {
              e = e & t.type.equals(type.name);
            }
            return e;
          })
          ..orderBy(<OrderClauseGenerator<$HealthVitalsTable>>[
            ($HealthVitalsTable t) =>
                OrderingTerm(expression: t.recordedAt, mode: OrderingMode.desc),
          ])
          ..limit(limit);
    final List<HealthVitalRow> rows = await q.get();
    return rows.map(_rowToVital).toList();
  }

  VitalEntry _rowToVital(HealthVitalRow r) {
    return VitalEntry(
      id: r.id,
      userId: r.userId,
      type: VitalType.values.firstWhere(
        (VitalType t) => t.name == r.type,
        orElse: () => VitalType.heartRate,
      ),
      value: r.value,
      unit: r.unit,
      recordedAt: r.recordedAt,
      source: VitalSource.values.firstWhere(
        (VitalSource s) => s.name == r.source,
        orElse: () => VitalSource.manual,
      ),
      notes: r.notes,
    );
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
    await _db
        .into(_db.healthLabReports)
        .insertOnConflictUpdate(
          HealthLabReportsCompanion.insert(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            scannedAt: scannedAt,
            status: status,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> upsertMedicationJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {
    await _db
        .into(_db.healthMedications)
        .insertOnConflictUpdate(
          HealthMedicationsCompanion.insert(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> deleteMedicationLocal(String medicationId) async {
    await (_db.delete(
      _db.healthMedications,
    )..where(($HealthMedicationsTable t) => t.id.equals(medicationId))).go();
  }

  @override
  Future<void> upsertMenstrualJson({
    required String id,
    required String userId,
    required String payloadJson,
    required bool synced,
  }) async {
    await _db
        .into(_db.healthMenstrualCycles)
        .insertOnConflictUpdate(
          HealthMenstrualCyclesCompanion.insert(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> setHealthInsightCache({
    required String userId,
    required String text,
    required DateTime expiresAt,
  }) async {
    await _db
        .into(_db.healthInsightCache)
        .insertOnConflictUpdate(
          HealthInsightCacheCompanion.insert(
            userId: userId,
            summaryText: text,
            expiresAt: expiresAt,
          ),
        );
  }

  @override
  Future<({String text, DateTime expiresAt})?> getHealthInsightCache(
    String userId,
  ) async {
    final HealthInsightCacheRow? row =
        await (_db.select(_db.healthInsightCache)
              ..where(($HealthInsightCacheTable t) => t.userId.equals(userId)))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return (text: row.summaryText, expiresAt: row.expiresAt);
  }
}
