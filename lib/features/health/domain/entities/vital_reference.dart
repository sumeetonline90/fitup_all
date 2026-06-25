import 'vital_status.dart';
import 'vital_type.dart';
import 'vital_type_extension.dart';

/// Typical lab reference window for UI hints (not medical advice).
class VitalRefRange {
  const VitalRefRange(this.min, this.max);

  final double min;
  final double max;
}

VitalRefRange? normalRangeFor(VitalType type) {
  return switch (type) {
    VitalType.fastingBloodSugar => const VitalRefRange(70, 99),
    VitalType.hba1c => const VitalRefRange(4, 5.6),
    VitalType.totalCholesterol => const VitalRefRange(0, 200),
    VitalType.ldlCholesterol => const VitalRefRange(0, 100),
    VitalType.hdlCholesterol => const VitalRefRange(40, 999),
    VitalType.triglycerides => const VitalRefRange(0, 150),
    VitalType.tsh => const VitalRefRange(0.4, 4.0),
    VitalType.heartRate => const VitalRefRange(60, 100),
    VitalType.spO2 => const VitalRefRange(95, 100),
    VitalType.bodyTemperature => const VitalRefRange(36.1, 37.2),
    VitalType.hemoglobin => const VitalRefRange(12, 17.5),
    _ => null,
  };
}

String referenceHintText(VitalType type) {
  final VitalRefRange? r = normalRangeFor(type);
  if (r == null) {
    return 'Consult your lab report for reference ranges.';
  }
  return 'Normal range (typical): ${r.min}–${r.max} ${type.unit}';
}

VitalStatus statusForReading(VitalType type, double value) {
  final VitalRefRange? r = normalRangeFor(type);
  if (r == null) {
    return VitalStatus.unknown;
  }
  if (value >= r.min && value <= r.max) {
    return VitalStatus.normal;
  }
  final double span = r.max - r.min;
  final double lowBand = r.min - span * 0.15;
  final double highBand = r.max + span * 0.15;
  if (value >= lowBand && value < r.min || value > r.max && value <= highBand) {
    return VitalStatus.borderline;
  }
  return VitalStatus.elevated;
}
