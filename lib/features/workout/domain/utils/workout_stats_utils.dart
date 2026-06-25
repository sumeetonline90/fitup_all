import '../entities/workout.dart';

/// Calendar-based workout aggregates using an explicit [now] (local time).
///
/// Passing [DateTime.now()] from UI [build] keeps “today” and “this week”
/// correct when the device date changes without new logs.
class WorkoutStatsUtils {
  WorkoutStatsUtils._();

  static DateTime _startOfLocalDay(DateTime t) =>
      DateTime(t.year, t.month, t.day);

  /// Monday 00:00 local (ISO week aligned with existing repository logic).
  static DateTime startOfWeekMonday(DateTime now) {
    final DateTime d = _startOfLocalDay(now);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  /// Workout logs whose [WorkoutLog.startTime] falls on the local calendar day
  /// of [now].
  static int todaySessionCount(List<WorkoutLog> logs, DateTime now) {
    final DateTime start = _startOfLocalDay(now);
    final DateTime end = start.add(const Duration(days: 1));
    return logs
        .where(
          (WorkoutLog l) =>
              !l.startTime.isBefore(start) && l.startTime.isBefore(end),
        )
        .length;
  }

  /// Distinct sessions (logs) on or after Monday of the week containing [now].
  static int weekSessionCountSinceMonday(List<WorkoutLog> logs, DateTime now) {
    final DateTime monday = startOfWeekMonday(now);
    return logs.where((WorkoutLog l) {
      final DateTime d = _startOfLocalDay(l.startTime);
      return !d.isBefore(monday);
    }).length;
  }

  /// Consecutive local days with at least one workout, counting backward from
  /// [now]’s calendar day.
  static int currentStreakDays(List<WorkoutLog> logs, DateTime now) {
    final Set<String> days = <String>{};
    for (final WorkoutLog l in logs) {
      final DateTime d = _startOfLocalDay(l.startTime);
      days.add('${d.year}-${d.month}-${d.day}');
    }
    int streak = 0;
    DateTime cursor = _startOfLocalDay(now);
    while (days.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
