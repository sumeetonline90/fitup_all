import '../../domain/entities/activity.dart';

/// Formatting and copy for activity summaries and live HUD (run, walk, cycle, swim).
abstract final class ActivitySessionMetrics {
  ActivitySessionMetrics._();

  /// `HH:MM:SS` for session duration.
  static String durationHms(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  static String formatPaceMinPerKm(double minPerKm) {
    if (minPerKm <= 0) {
      return '—';
    }
    final int mins = minPerKm.floor();
    final int sec = ((minPerKm - mins) * 60).round().clamp(0, 59);
    return '$mins:${sec.toString().padLeft(2, '0')} /km';
  }

  static String formatPaceMinPer100m(double minPer100m) {
    if (minPer100m <= 0) {
      return '—';
    }
    final int mins = minPer100m.floor();
    final int sec = ((minPer100m - mins) * 60).round().clamp(0, 59);
    return '$mins:${sec.toString().padLeft(2, '0')} /100m';
  }

  /// Swim pace (min/100 m) from distance and elapsed time.
  static double swimPaceMinPer100m(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 1) {
      return 0;
    }
    return (durationSeconds / 60.0) / (distanceMeters / 100.0);
  }

  /// Run/walk pace (min/km) when [avgPace] is missing but distance/time exist.
  static double inferredPaceMinPerKm(Activity a) {
    if (a.distanceMeters <= 1) {
      return 0;
    }
    return (a.durationSeconds / 60.0) / (a.distanceMeters / 1000.0);
  }

  static String distanceLabel(ActivityType type, double distanceMeters) {
    if (type == ActivityType.swim) {
      if (distanceMeters < 1000) {
        return '${distanceMeters.round()} m';
      }
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  static String headline(ActivityType type, String firstName) {
    final String n =
        firstName.trim().isEmpty ? 'there' : firstName.trim();
    return switch (type) {
      ActivityType.run =>
        'Incredible session, $n! Every mile counts.',
      ActivityType.walk =>
        'Great walk, $n! Steady progress adds up.',
      ActivityType.cycle =>
        'Solid ride, $n! Keep the wheels turning.',
      ActivityType.swim =>
        'Strong swim, $n! Every length matters.',
    };
  }

  /// Primary speed/pace label for HUD and summary cards.
  static String primaryMetricLabel(ActivityType type) {
    return switch (type) {
      ActivityType.run => 'AVG PACE',
      ActivityType.walk => 'AVG PACE',
      ActivityType.cycle => 'AVG SPEED',
      ActivityType.swim => 'PACE',
    };
  }

  /// Distance column label (swim often read in meters).
  static String distanceColumnLabel(ActivityType type) {
    return switch (type) {
      ActivityType.swim => 'DISTANCE',
      _ => 'DISTANCE',
    };
  }

  static String locationSubtitle(ActivityType type, int routePointCount) {
    if (routePointCount == 0) {
      return switch (type) {
        ActivityType.swim => 'Pool or open water',
        _ => 'No GPS path recorded',
      };
    }
    return 'Outdoor route';
  }
}
