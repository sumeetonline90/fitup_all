import 'medication_log.dart';
import 'vital_entry.dart';
import 'vital_type.dart';

class HealthSummary {
  const HealthSummary({
    required this.latestVitals,
    required this.trends,
    required this.activeMedications,
    required this.vitalsInNormalRange,
    required this.vitalsNeedingAttention,
  });

  final Map<VitalType, VitalEntry?> latestVitals;
  final Map<VitalType, List<VitalEntry>> trends;
  final List<MedicationLog> activeMedications;
  final int vitalsInNormalRange;
  final int vitalsNeedingAttention;
}
