enum LeaderboardPeriod { week, month, allTime }

enum LeaderboardMetric { steps, workouts, fitcoins, challenges }

class LeaderboardRow {
  const LeaderboardRow({
    required this.rank,
    required this.displayName,
    required this.handle,
    required this.metricValue,
    required this.avatarInitials,
    this.trend = 0,
  });

  final int rank;
  final String displayName;
  final String handle;
  final int metricValue;
  final String avatarInitials;

  /// -1 down, 0 flat, +1 up
  final int trend;
}

class LeaderboardPodium {
  const LeaderboardPodium({
    required this.first,
    required this.second,
    required this.third,
  });

  final LeaderboardRow first;
  final LeaderboardRow second;
  final LeaderboardRow third;
}
