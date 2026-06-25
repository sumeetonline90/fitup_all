import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_source.dart';
import '../../domain/entities/vital_type.dart';

class VitalEntryModel {
  VitalEntryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
    required this.source,
    this.notes,
  });

  factory VitalEntryModel.fromEntity(VitalEntry e) {
    return VitalEntryModel(
      id: e.id,
      userId: e.userId,
      type: e.type,
      value: e.value,
      unit: e.unit,
      recordedAt: e.recordedAt,
      source: e.source,
      notes: e.notes,
    );
  }

  factory VitalEntryModel.fromJsonMap(Map<String, dynamic> j) {
    return VitalEntryModel(
      id: j['id'] as String? ?? '',
      userId: j['userId'] as String? ?? '',
      type: VitalType.values.firstWhere(
        (VitalType t) => t.name == (j['type'] as String? ?? ''),
        orElse: () => VitalType.heartRate,
      ),
      value: (j['value'] as num?)?.toDouble() ?? 0,
      unit: j['unit'] as String? ?? '',
      recordedAt: _readDate(j['recordedAt']),
      source: VitalSource.values.firstWhere(
        (VitalSource s) => s.name == (j['source'] as String? ?? 'manual'),
        orElse: () => VitalSource.manual,
      ),
      notes: j['notes'] as String?,
    );
  }

  factory VitalEntryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> j = doc.data() ?? <String, dynamic>{};
    return VitalEntryModel(
      id: doc.id,
      userId: j['userId'] as String? ?? '',
      type: VitalType.values.firstWhere(
        (VitalType t) => t.name == (j['type'] as String? ?? ''),
        orElse: () => VitalType.heartRate,
      ),
      value: (j['value'] as num?)?.toDouble() ?? 0,
      unit: j['unit'] as String? ?? '',
      recordedAt: _readDate(j['recordedAt']),
      source: VitalSource.values.firstWhere(
        (VitalSource s) => s.name == (j['source'] as String? ?? 'manual'),
        orElse: () => VitalSource.manual,
      ),
      notes: j['notes'] as String?,
    );
  }

  final String id;
  final String userId;
  final VitalType type;
  final double value;
  final String unit;
  final DateTime recordedAt;
  final VitalSource source;
  final String? notes;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'type': type.name,
      'value': value,
      'unit': unit,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'source': source.name,
      'notes': notes,
    };
  }

  VitalEntry toEntity() {
    return VitalEntry(
      id: id,
      userId: userId,
      type: type,
      value: value,
      unit: unit,
      recordedAt: recordedAt,
      source: source,
      notes: notes,
    );
  }

  static DateTime _readDate(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return DateTime.now();
  }
}
