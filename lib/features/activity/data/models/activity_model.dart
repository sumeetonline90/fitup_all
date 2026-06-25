import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:fitup/features/activity/domain/entities/activity.dart';

/// Firestore DTO for [Activity].
class ActivityModel {
  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.caloriesBurnt,
    required this.routePoints,
    this.steps,
    this.avgPace,
    this.avgSpeed,
    this.avgHeartRate,
    this.gpsDropSeconds,
    this.gpsDropInterruptions,
    this.deadReckoningMeters,
  });

  final String id;
  final String userId;
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final int durationSeconds;
  final double caloriesBurnt;
  final List<LatLng> routePoints;
  final int? steps;
  final double? avgPace;
  final double? avgSpeed;
  final int? avgHeartRate;
  final int? gpsDropSeconds;
  final int? gpsDropInterruptions;
  final double? deadReckoningMeters;

  factory ActivityModel.fromEntity(Activity a) {
    return ActivityModel(
      id: a.id,
      userId: a.userId,
      type: a.type,
      startTime: a.startTime,
      endTime: a.endTime,
      distanceMeters: a.distanceMeters,
      durationSeconds: a.durationSeconds,
      caloriesBurnt: a.caloriesBurnt,
      routePoints: a.routePoints,
      steps: a.steps,
      avgPace: a.avgPace,
      avgSpeed: a.avgSpeed,
      avgHeartRate: a.avgHeartRate,
      gpsDropSeconds: a.gpsDropSeconds,
      gpsDropInterruptions: a.gpsDropInterruptions,
      deadReckoningMeters: a.deadReckoningMeters,
    );
  }

  factory ActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final List<dynamic> rawPoints =
        (data['routePoints'] as List<dynamic>?) ?? <dynamic>[];
    final List<LatLng> points = rawPoints.map((dynamic e) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(e as Map);
      final double lat = (m['lat'] as num).toDouble();
      final double lng = (m['lng'] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();

    return ActivityModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      startTime: _readDate(data['startTime']),
      endTime: data['endTime'] != null ? _readDate(data['endTime']) : null,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toInt() ?? 0,
      caloriesBurnt: (data['caloriesBurnt'] as num?)?.toDouble() ?? 0,
      routePoints: points,
      steps: (data['steps'] as num?)?.toInt(),
      avgPace: (data['avgPace'] as num?)?.toDouble(),
      avgSpeed: (data['avgSpeed'] as num?)?.toDouble(),
      avgHeartRate: (data['avgHeartRate'] as num?)?.toInt(),
      gpsDropSeconds: (data['gpsDropSeconds'] as num?)?.toInt() ?? 0,
      gpsDropInterruptions:
          (data['gpsDropInterruptions'] as num?)?.toInt() ?? 0,
      deadReckoningMeters:
          (data['deadReckoningMeters'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'type': type.name,
      'startTime': Timestamp.fromDate(startTime),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'caloriesBurnt': caloriesBurnt,
      'routePoints': routePoints
          .map((LatLng p) => <String, double>{'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      if (steps != null) 'steps': steps,
      if (avgPace != null) 'avgPace': avgPace,
      if (avgSpeed != null) 'avgSpeed': avgSpeed,
      if (avgHeartRate != null) 'avgHeartRate': avgHeartRate,
      'gpsDropSeconds': gpsDropSeconds ?? 0,
      'gpsDropInterruptions': gpsDropInterruptions ?? 0,
      if (deadReckoningMeters != null && deadReckoningMeters! > 0)
        'deadReckoningMeters': deadReckoningMeters,
    };
  }

  Activity toEntity() {
    return Activity(
      id: id,
      userId: userId,
      type: type,
      startTime: startTime,
      endTime: endTime,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      caloriesBurnt: caloriesBurnt,
      routePoints: routePoints,
      steps: steps,
      avgPace: avgPace,
      avgSpeed: avgSpeed,
      avgHeartRate: avgHeartRate,
      gpsDropSeconds: gpsDropSeconds ?? 0,
      gpsDropInterruptions: gpsDropInterruptions ?? 0,
      deadReckoningMeters: deadReckoningMeters ?? 0,
    );
  }

  static ActivityType _parseType(String? raw) {
    if (raw == null) {
      return ActivityType.walk;
    }
    if (raw == 'jog') {
      return ActivityType.run;
    }
    return ActivityType.values.firstWhere(
      (ActivityType e) => e.name == raw,
      orElse: () => ActivityType.walk,
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
