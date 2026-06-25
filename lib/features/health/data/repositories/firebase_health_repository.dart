import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart' show Either, Left, Right, Unit, unit;

import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../domain/entities/health_summary.dart';
import '../../domain/entities/lab_report_scan.dart';
import '../../domain/entities/lab_scan_status.dart';
import '../../domain/entities/medication_log.dart';
import '../../domain/entities/medication_reminder_time.dart';
import '../../domain/entities/menstrual_cycle.dart';
import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_reference_range.dart';
import '../../domain/entities/flow_intensity.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../../domain/repositories/health_repository.dart';
import '../datasources/health_local_datasource.dart';
import '../datasources/health_remote_datasource.dart';
import '../models/vital_entry_model.dart';

Failure _mapFirebase(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

Map<String, dynamic> _medicationToMap(MedicationLog m) {
  return <String, dynamic>{
    'id': m.id,
    'userId': m.userId,
    'medicationName': m.medicationName,
    'dose': m.dose,
    'frequency': m.frequency,
    'isActive': m.isActive,
    'startDate': Timestamp.fromDate(m.startDate),
    'endDate': m.endDate != null ? Timestamp.fromDate(m.endDate!) : null,
    'reminderHour': m.reminderTime?.hour,
    'reminderMinute': m.reminderTime?.minute,
  };
}

MedicationLog _medicationFromMap(Map<String, dynamic> j) {
  return MedicationLog(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
    medicationName: j['medicationName'] as String? ?? '',
    dose: j['dose'] as String? ?? '',
    frequency: j['frequency'] as String? ?? '',
    isActive: j['isActive'] as bool? ?? true,
    startDate: _readTs(j['startDate']) ?? DateTime.now(),
    endDate: _readTs(j['endDate']),
    reminderTime: j['reminderHour'] != null && j['reminderMinute'] != null
        ? MedicationReminderTime(
            hour: (j['reminderHour'] as num).toInt(),
            minute: (j['reminderMinute'] as num).toInt(),
          )
        : null,
  );
}

Map<String, dynamic> _menstrualToMap(MenstrualCycle c) {
  return <String, dynamic>{
    'id': c.id,
    'userId': c.userId,
    'cycleStart': Timestamp.fromDate(c.cycleStart),
    'cycleEnd': c.cycleEnd != null ? Timestamp.fromDate(c.cycleEnd!) : null,
    'cycleLength': c.cycleLength,
    'flowIntensity': c.flowIntensity?.name,
    'symptoms': c.symptoms,
    'notes': c.notes,
  };
}

/// JSON-safe map for Drift `payloadJson` (no Firestore [Timestamp]).
Map<String, dynamic> _menstrualToLocalJsonMap(MenstrualCycle c) {
  return <String, dynamic>{
    'id': c.id,
    'userId': c.userId,
    'cycleStart': c.cycleStart.toIso8601String(),
    'cycleEnd': c.cycleEnd?.toIso8601String(),
    'cycleLength': c.cycleLength,
    'flowIntensity': c.flowIntensity?.name,
    'symptoms': c.symptoms,
    'notes': c.notes,
  };
}

MenstrualCycle _menstrualFromMap(Map<String, dynamic> j) {
  return MenstrualCycle(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
    cycleStart: _readTs(j['cycleStart']) ?? DateTime.now(),
    cycleEnd: _readTs(j['cycleEnd']),
    cycleLength: (j['cycleLength'] as num?)?.toInt(),
    flowIntensity: j['flowIntensity'] != null
        ? FlowIntensity.values.firstWhere(
            (FlowIntensity f) => f.name == j['flowIntensity'],
            orElse: () => FlowIntensity.medium,
          )
        : null,
    symptoms:
        (j['symptoms'] as List<dynamic>?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
    notes: j['notes'] as String?,
  );
}

DateTime? _readTs(Object? raw) {
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  return null;
}

Map<String, dynamic> _labScanToFirestore(LabReportScan s) {
  return <String, dynamic>{
    'id': s.id,
    'userId': s.userId,
    'scannedAt': Timestamp.fromDate(s.scannedAt),
    'status': s.status.name,
    'rawText': s.rawText,
    'extractedVitals': s.extractedVitals
        .map((VitalEntry v) => VitalEntryModel.fromEntity(v).toFirestore())
        .toList(),
  };
}

LabReportScan _labScanFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final Map<String, dynamic> j = doc.data() ?? <String, dynamic>{};
  final List<dynamic> rawList =
      j['extractedVitals'] as List<dynamic>? ?? <dynamic>[];
  final List<VitalEntry> vitals = rawList.map((dynamic e) {
    final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map);
    return VitalEntryModel.fromJsonMap(m).toEntity();
  }).toList();
  return LabReportScan(
    id: doc.id,
    userId: j['userId'] as String? ?? '',
    scannedAt: _readTs(j['scannedAt']) ?? DateTime.now(),
    extractedVitals: vitals,
    rawText: j['rawText'] as String?,
    status: LabScanStatus.values.firstWhere(
      (LabScanStatus s) => s.name == (j['status'] as String? ?? 'completed'),
      orElse: () => LabScanStatus.completed,
    ),
  );
}

class FirebaseHealthRepository implements HealthRepository {
  FirebaseHealthRepository(
    this._remote,
    this._local, {
    FitcoinAwardService? fitcoinAwardService,
  }) : _fitcoinAwards = fitcoinAwardService;

  final HealthRemoteDatasource _remote;
  final HealthLocalDatasource _local;
  final FitcoinAwardService? _fitcoinAwards;

  @override
  Future<Either<Failure, VitalEntry>> saveVitalEntry(VitalEntry entry) async {
    try {
      await _local.upsertVital(entry, synced: false);
      final VitalEntryModel model = VitalEntryModel.fromEntity(entry);
      await _remote.setVital(entry.userId, model);
      await _local.markVitalSynced(entry.id);
      return Right<Failure, VitalEntry>(entry);
    } catch (e, st) {
      LoggerService.e('saveVitalEntry', e, st);
      return Left<Failure, VitalEntry>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteVitalEntry(
    String userId,
    String vitalEntryId,
  ) async {
    try {
      await _local.deleteVitalLocal(vitalEntryId);
      await _remote.deleteVital(userId, vitalEntryId);
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('deleteVitalEntry', e, st);
      return Left<Failure, Unit>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<VitalEntry>>> getVitalsForType(
    String userId,
    VitalType type, {
    int limit = 30,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryAllVitals(userId, 500);
      final List<VitalEntry> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                VitalEntryModel.fromFirestore(d).toEntity(),
          )
          .where((VitalEntry v) => v.type == type)
          .take(limit)
          .toList();
      return Right<Failure, List<VitalEntry>>(list);
    } catch (e, st) {
      LoggerService.e('getVitalsForType', e, st);
      try {
        final List<VitalEntry> local = await _local.queryVitals(
          userId,
          type: type,
          limit: limit,
        );
        return Right<Failure, List<VitalEntry>>(local);
      } catch (e2, st2) {
        LoggerService.e('getVitalsForType local', e2, st2);
        return Left<Failure, List<VitalEntry>>(_mapFirebase(e));
      }
    }
  }

  @override
  Future<Either<Failure, HealthSummary>> getHealthSummary(String userId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryAllVitals(userId, 800);
      final List<VitalEntry> all = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                VitalEntryModel.fromFirestore(d).toEntity(),
          )
          .toList();
      final Map<VitalType, VitalEntry?> latest = <VitalType, VitalEntry?>{};
      final Map<VitalType, List<VitalEntry>> trends =
          <VitalType, List<VitalEntry>>{};
      for (final VitalEntry v in all) {
        if (v.type.isDerived) {
          continue;
        }
        final VitalEntry? cur = latest[v.type];
        if (cur == null || v.recordedAt.isAfter(cur.recordedAt)) {
          latest[v.type] = v;
        }
        trends.putIfAbsent(v.type, () => <VitalEntry>[]);
        if (trends[v.type]!.length < 30) {
          trends[v.type]!.add(v);
        }
      }
      int normal = 0;
      int attention = 0;
      for (final VitalEntry? e in latest.values) {
        if (e == null) {
          continue;
        }
        final RangeStatus st = VitalReferenceRanges.statusFor(e.type, e.value);
        if (st == RangeStatus.normal) {
          normal++;
        } else {
          attention++;
        }
      }
      final Either<Failure, List<MedicationLog>> meds =
          await getActiveMedications(userId);
      final List<MedicationLog> active = meds.fold(
        (_) => <MedicationLog>[],
        (List<MedicationLog> m) => m,
      );
      return Right<Failure, HealthSummary>(
        HealthSummary(
          latestVitals: latest,
          trends: trends,
          activeMedications: active,
          vitalsInNormalRange: normal,
          vitalsNeedingAttention: attention,
        ),
      );
    } catch (e, st) {
      LoggerService.e('getHealthSummary', e, st);
      return Left<Failure, HealthSummary>(_mapFirebase(e));
    }
  }

  @override
  Stream<Either<Failure, List<VitalEntry>>> watchRecentVitals(
    String userId, {
    int limit = 10,
  }) {
    return _remote.watchRecentVitals(userId, limit).map((
      QuerySnapshot<Map<String, dynamic>> snap,
    ) {
      try {
        final List<VitalEntry> list = snap.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  VitalEntryModel.fromFirestore(d).toEntity(),
            )
            .toList();
        return Right<Failure, List<VitalEntry>>(list);
      } catch (e, st) {
        LoggerService.e('watchRecentVitals', e, st);
        return Left<Failure, List<VitalEntry>>(_mapFirebase(e));
      }
    });
  }

  @override
  Future<Either<Failure, LabReportScan>> saveLabReportScan(
    LabReportScan scan,
  ) async {
    try {
      final Map<String, dynamic> data = _labScanToFirestore(scan);
      final String payload = jsonEncode(data);
      await _local.upsertLabReportJson(
        id: scan.id,
        userId: scan.userId,
        payloadJson: payload,
        scannedAt: scan.scannedAt,
        status: scan.status.name,
        synced: false,
      );
      await _remote.setLabReport(scan.userId, scan.id, data);
      await _local.upsertLabReportJson(
        id: scan.id,
        userId: scan.userId,
        payloadJson: payload,
        scannedAt: scan.scannedAt,
        status: scan.status.name,
        synced: true,
      );
      if (scan.status == LabScanStatus.completed) {
        final FitcoinAwardService? awards = _fitcoinAwards;
        if (awards != null) {
          unawaited(awards.onLabScanUploaded(scan.userId));
        }
      }
      return Right<Failure, LabReportScan>(scan);
    } catch (e, st) {
      LoggerService.e('saveLabReportScan', e, st);
      return Left<Failure, LabReportScan>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<LabReportScan>>> getLabReportHistory(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryLabReports(userId);
      final List<LabReportScan> list = snap.docs.map(_labScanFromDoc).toList();
      return Right<Failure, List<LabReportScan>>(list);
    } catch (e, st) {
      LoggerService.e('getLabReportHistory', e, st);
      return Left<Failure, List<LabReportScan>>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, MedicationLog>> saveMedication(
    MedicationLog log,
  ) async {
    try {
      final Map<String, dynamic> data = _medicationToMap(log);
      final String payload = jsonEncode(data);
      await _local.upsertMedicationJson(
        id: log.id,
        userId: log.userId,
        payloadJson: payload,
        synced: false,
      );
      await _remote.setMedication(log.userId, log.id, data);
      await _local.upsertMedicationJson(
        id: log.id,
        userId: log.userId,
        payloadJson: payload,
        synced: true,
      );
      return Right<Failure, MedicationLog>(log);
    } catch (e, st) {
      LoggerService.e('saveMedication', e, st);
      return Left<Failure, MedicationLog>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<MedicationLog>>> getActiveMedications(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryActiveMedications(userId);
      final List<MedicationLog> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                _medicationFromMap(<String, dynamic>{'id': d.id, ...d.data()}),
          )
          .toList();
      return Right<Failure, List<MedicationLog>>(list);
    } catch (e, st) {
      LoggerService.e('getActiveMedications', e, st);
      return Left<Failure, List<MedicationLog>>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMedication(
    String userId,
    String medicationId,
  ) async {
    try {
      await _local.deleteMedicationLocal(medicationId);
      await _remote.deleteMedication(userId, medicationId);
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('deleteMedication', e, st);
      return Left<Failure, Unit>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, MenstrualCycle>> saveMenstrualCycle(
    MenstrualCycle cycle,
  ) async {
    try {
      final Map<String, dynamic> data = _menstrualToMap(cycle);
      final String payload = jsonEncode(_menstrualToLocalJsonMap(cycle));
      await _local.upsertMenstrualJson(
        id: cycle.id,
        userId: cycle.userId,
        payloadJson: payload,
        synced: false,
      );
      await _remote.setMenstrual(cycle.userId, cycle.id, data);
      await _local.upsertMenstrualJson(
        id: cycle.id,
        userId: cycle.userId,
        payloadJson: payload,
        synced: true,
      );
      return Right<Failure, MenstrualCycle>(cycle);
    } catch (e, st) {
      LoggerService.e('saveMenstrualCycle', e, st);
      return Left<Failure, MenstrualCycle>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<MenstrualCycle>>> getMenstrualHistory(
    String userId, {
    int limit = 6,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryMenstrual(userId, limit);
      final List<MenstrualCycle> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                _menstrualFromMap(<String, dynamic>{'id': d.id, ...d.data()}),
          )
          .toList();
      return Right<Failure, List<MenstrualCycle>>(list);
    } catch (e, st) {
      LoggerService.e('getMenstrualHistory', e, st);
      return Left<Failure, List<MenstrualCycle>>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateMenstrualCycle(
    MenstrualCycle cycle,
  ) async {
    try {
      await _remote.setMenstrual(
        cycle.userId,
        cycle.id,
        _menstrualToMap(cycle),
      );
      final String payload = jsonEncode(_menstrualToLocalJsonMap(cycle));
      await _local.upsertMenstrualJson(
        id: cycle.id,
        userId: cycle.userId,
        payloadJson: payload,
        synced: true,
      );
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('updateMenstrualCycle', e, st);
      return Left<Failure, Unit>(_mapFirebase(e));
    }
  }
}
