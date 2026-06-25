import '../entities/activity.dart';

int _estimatedStepsFromDistance(double meters) => (meters / 0.78).round();

/// Returns true for synthetic passive step records created by Health sync.
bool isPassiveStepsActivity(Activity a) => a.id.startsWith('passive_steps_');

/// Builds day->steps map while avoiding passive + tracked double counting.
///
/// Rule per day:
/// - `activeSteps` = sum of non-passive activities.
/// - `passiveSteps` = sum of passive synthetic entries.
/// - result = max(activeSteps, passiveSteps).
Map<DateTime, int> stepsByDayNoDoubleCount(List<Activity> activities) {
  final Map<DateTime, int> activeByDay = <DateTime, int>{};
  final Map<DateTime, int> passiveByDay = <DateTime, int>{};

  for (final Activity a in activities) {
    final DateTime day = DateTime(
      a.startTime.year,
      a.startTime.month,
      a.startTime.day,
    );
    final int steps = a.steps ?? _estimatedStepsFromDistance(a.distanceMeters);
    if (isPassiveStepsActivity(a)) {
      passiveByDay.update(day, (int v) => v + steps, ifAbsent: () => steps);
    } else {
      activeByDay.update(day, (int v) => v + steps, ifAbsent: () => steps);
    }
  }

  final Set<DateTime> allDays = <DateTime>{
    ...activeByDay.keys,
    ...passiveByDay.keys,
  };
  final Map<DateTime, int> result = <DateTime, int>{};
  for (final DateTime d in allDays) {
    final int active = activeByDay[d] ?? 0;
    final int passive = passiveByDay[d] ?? 0;
    result[d] = active >= passive ? active : passive;
  }
  return result;
}
