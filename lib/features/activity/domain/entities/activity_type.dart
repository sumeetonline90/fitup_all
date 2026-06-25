/// Outdoor / cardio activity kinds tracked in Fitup.
enum ActivityType {
  run,
  walk,
  cycle,
  swim,
}

/// Display label for UI (Space Grotesk headlines use plain strings).
extension ActivityTypeLabel on ActivityType {
  /// Short title e.g. "Run", "Walk".
  String get label => switch (this) {
        ActivityType.run => 'Run',
        ActivityType.walk => 'Walk',
        ActivityType.cycle => 'Cycle',
        ActivityType.swim => 'Swim',
      };
}
