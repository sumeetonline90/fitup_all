import 'stress_level.dart';

class StressScore {
  const StressScore({
    required this.userId,
    required this.calculatedAt,
    required this.score,
    required this.level,
    required this.aiInsight,
    this.hrvScore,
    this.sleepScore,
    this.moodScore,
    this.surveyScore,
    this.id,
  });

  final String? id;
  final String userId;
  final DateTime calculatedAt;
  final double score;
  final StressLevel level;
  final double? hrvScore;
  final double? sleepScore;
  final double? moodScore;
  final double? surveyScore;
  final String aiInsight;
}
