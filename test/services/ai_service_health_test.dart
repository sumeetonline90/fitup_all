import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_type.dart';
import 'package:fitup/services/ai_health_prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labReportVisionPrompt does not contain userId', () {
    final String p = labReportVisionPrompt();
    expect(p.toLowerCase().contains('userid'), isFalse);
    expect(p.toLowerCase().contains('user_id'), isFalse);
  });

  test('getSurveyInsight prompt does not contain raw answer values', () {
    final String p = surveyInsightPrompt(
      SurveyType.phq9,
      SurveySeverity.moderate,
    );
    expect(p.toLowerCase().contains('answers'), isFalse);
    expect(p.contains('totalScore'), isFalse);
    expect(RegExp(r'\[\s*\d').hasMatch(p), isFalse);
    expect(p.contains('phq9'), isTrue);
    expect(p.contains('moderate'), isTrue);
  });

  test('healthContextInsightPrompt uses hedging language', () {
    final String p = healthContextInsightPrompt(
      ageGroup: '30s',
      fitnessLevel: 'intermediate',
      vitalsLines: 'TSH: 2.0',
      medicationsLines: 'None',
    );
    expect(p.toLowerCase().contains('you may want to'), isTrue);
  });
}
