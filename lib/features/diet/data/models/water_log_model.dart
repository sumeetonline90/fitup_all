import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/water_log.dart';

class WaterLogModel {
  WaterLogModel({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.dateTime,
  });

  final String id;
  final String userId;
  final double amountMl;
  final DateTime dateTime;

  factory WaterLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return WaterLogModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      amountMl: (data['amountMl'] as num?)?.toDouble() ?? 0,
      dateTime: _readDate(data['dateTime']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'amountMl': amountMl,
      'dateTime': Timestamp.fromDate(dateTime),
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'amountMl': amountMl,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory WaterLogModel.fromJson(Map<String, dynamic> json) {
    return WaterLogModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      amountMl: (json['amountMl'] as num?)?.toDouble() ?? 0,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  WaterLog toEntity() {
    return WaterLog(
      id: id,
      userId: userId,
      amountMl: amountMl,
      dateTime: dateTime,
    );
  }

  factory WaterLogModel.fromEntity(WaterLog w) {
    return WaterLogModel(
      id: w.id,
      userId: w.userId,
      amountMl: w.amountMl,
      dateTime: w.dateTime,
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
