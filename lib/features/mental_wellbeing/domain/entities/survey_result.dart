import 'survey_severity.dart';
import 'survey_type.dart';

class SurveyResult {
  const SurveyResult({
    required this.id,
    required this.userId,
    required this.type,
    required this.answers,
    required this.totalScore,
    required this.severity,
    required this.completedAt,
    this.aiGuidance,
  });

  final String id;
  final String userId;
  final SurveyType type;
  final List<int> answers;
  final int totalScore;
  final SurveySeverity severity;
  final DateTime completedAt;
  final String? aiGuidance;
}
