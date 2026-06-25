enum ChallengeType { oneVsOne, group }

enum ChallengeMetric { steps, distance, workouts, caloriesBurned, fitcoins }

enum ChallengeStatus { pending, active, completed, cancelled }

class Challenge {
  const Challenge({
    required this.id,
    required this.challengeCode,
    required this.creatorId,
    required this.type,
    required this.metric,
    required this.status,
    required this.title,
    required this.targetValue,
    required this.startsAt,
    required this.endsAt,
    required this.participantIds,
    required this.scores,
    this.winnerId,
    required this.fitcoinsReward,
    required this.createdAt,
  });

  final String id;
  final String challengeCode;
  final String creatorId;
  final ChallengeType type;
  final ChallengeMetric metric;
  final ChallengeStatus status;
  final String title;
  final int targetValue;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<String> participantIds;
  final Map<String, int> scores;
  final String? winnerId;
  final int fitcoinsReward;
  final DateTime createdAt;
}
