import 'vital_source.dart';
import 'vital_type.dart';

class VitalEntry {
  const VitalEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
    required this.userId,
    this.notes,
  });

  final String id;
  final VitalType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final VitalSource source;
  final String? notes;
  final String userId;
}
