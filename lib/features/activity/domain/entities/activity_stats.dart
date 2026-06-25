import 'package:freezed_annotation/freezed_annotation.dart';

import 'activity.dart';

part 'activity_stats.freezed.dart';

/// Aggregated stats for a date range.
@freezed
abstract class ActivityStats with _$ActivityStats {
  const factory ActivityStats({
    required int totalSteps,
    required double totalDistanceMeters,
    required double totalCaloriesBurnt,
    required int totalDurationSeconds,
    required int activeDays,
    required List<Activity> recentActivities,
  }) = _ActivityStats;

  factory ActivityStats.empty() => const ActivityStats(
        totalSteps: 0,
        totalDistanceMeters: 0,
        totalCaloriesBurnt: 0,
        totalDurationSeconds: 0,
        activeDays: 0,
        recentActivities: <Activity>[],
      );
}
