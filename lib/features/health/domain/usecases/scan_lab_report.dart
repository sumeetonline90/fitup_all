import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../entities/lab_scan_status.dart';
import '../entities/lab_report_scan.dart';
import '../entities/vital_entry.dart';
import '../repositories/health_repository.dart';

class ScanLabReportUseCase {
  ScanLabReportUseCase(this._ai, this._health);

  final AiService _ai;
  final HealthRepository _health;

  Future<Either<Failure, LabReportScan>> call({
    required String userId,
    required String scanId,
    required Uint8List imageBytes,
  }) async {
    final Either<Failure, List<VitalEntry>> extracted =
        await _ai.analyzeLabReportAsVitalEntries(
      imageBytes,
      userId: userId,
    );
    Failure? exFail;
    List<VitalEntry>? vitals;
    extracted.fold(
      (Failure f) => exFail = f,
      (List<VitalEntry> v) => vitals = v,
    );
    if (exFail != null) {
      return Left<Failure, LabReportScan>(exFail!);
    }
    final List<VitalEntry> list = vitals ?? <VitalEntry>[];
    final LabReportScan scan = LabReportScan(
      id: scanId,
      userId: userId,
      scannedAt: DateTime.now(),
      extractedVitals: list,
      status: LabScanStatus.completed,
    );
    final Either<Failure, LabReportScan> saved =
        await _health.saveLabReportScan(scan);
    Failure? saveFail;
    LabReportScan? scanOut;
    saved.fold(
      (Failure f) => saveFail = f,
      (LabReportScan s) => scanOut = s,
    );
    if (saveFail != null) {
      return Left<Failure, LabReportScan>(saveFail!);
    }
    for (final VitalEntry v in list) {
      final Either<Failure, VitalEntry> vr =
          await _health.saveVitalEntry(v);
      Failure? vf;
      vr.fold((Failure f) => vf = f, (_) {});
      if (vf != null) {
        return Left<Failure, LabReportScan>(vf!);
      }
    }
    return Right<Failure, LabReportScan>(scanOut!);
  }
}
