import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'activity_type.dart';

export 'activity_type.dart';

part 'activity.freezed.dart';

/// Single tracked activity session (domain).
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String userId,
    required ActivityType type,
    required DateTime startTime,
    DateTime? endTime,
    required double distanceMeters,
    required int durationSeconds,
    required double caloriesBurnt,
    @Default(<LatLng>[]) List<LatLng> routePoints,
    int? steps,
    double? avgPace,
    double? avgSpeed,
    int? avgHeartRate,
    @Default(0) int gpsDropSeconds,

    /// Number of "strong → weak/lost → strong" GPS interruption cycles.
    @Default(0) int gpsDropInterruptions,

    /// Distance estimated via dead reckoning when GPS was lost.
    @Default(0) double deadReckoningMeters,
  }) = _Activity;
}
