import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sleep_log.dart';

/// Firestore DTO for [SleepLog].
class SleepLogModel {
  SleepLogModel({
    required this.id,
    required this.userId,
    required this.bedtime,
    required this.wakeTime,
    required this.durationMinutes,
    this.quality,
    required this.source,
  });

  final String id;
  final String userId;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int durationMinutes;
  final double? quality;
  final String source;

  factory SleepLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return SleepLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      bedtime: _readDate(data['bedtime']),
      wakeTime: _readDate(data['wakeTime']),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      quality: (data['quality'] as num?)?.toDouble(),
      source: data['source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'bedtime': Timestamp.fromDate(bedtime),
      'wakeTime': Timestamp.fromDate(wakeTime),
      'durationMinutes': durationMinutes,
      if (quality != null) 'quality': quality,
      'source': source,
    };
  }

  SleepLog toEntity() {
    return SleepLog(
      id: id,
      userId: userId,
      bedtime: bedtime,
      wakeTime: wakeTime,
      durationMinutes: durationMinutes,
      quality: quality,
      source: source,
    );
  }

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) {
      return v.toDate();
    }
    if (v is DateTime) {
      return v;
    }
    return DateTime.now();
  }
}
