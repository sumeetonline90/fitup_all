class CommunityChallenge {
  const CommunityChallenge({
    required this.id,
    required this.title,
    required this.metricLabel,
    required this.endsAt,
    required this.yourScore,
    required this.opponentScore,
    required this.opponentName,
    required this.yourRank,
  });

  final String id;
  final String title;
  final String metricLabel;
  final DateTime endsAt;
  final int yourScore;
  final int opponentScore;
  final String opponentName;
  final int yourRank;
}
