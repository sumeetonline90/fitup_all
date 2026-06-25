import 'lab_scan_status.dart';
import 'vital_entry.dart';

class LabReportScan {
  const LabReportScan({
    required this.id,
    required this.userId,
    required this.scannedAt,
    required this.extractedVitals,
    required this.status,
    this.rawText,
  });

  final String id;
  final String userId;
  final DateTime scannedAt;
  final List<VitalEntry> extractedVitals;
  final String? rawText;
  final LabScanStatus status;
}
