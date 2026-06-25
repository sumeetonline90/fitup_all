import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_type.dart';
import 'package:fitup/features/mental_wellbeing/domain/survey_definitions.dart';
import 'package:fitup/features/mental_wellbeing/domain/survey_scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PHQ-9', () {
    test('total and severity bands', () {
      expect(
        SurveyScoring.scoreSurvey(SurveyType.phq9, List<int>.filled(9, 0)),
        (total: 0, severity: SurveySeverity.minimal),
      );
      expect(
        SurveyScoring.scoreSurvey(SurveyType.phq9, List<int>.filled(9, 1)),
        (total: 9, severity: SurveySeverity.mild),
      );
      expect(
        SurveyScoring.scoreSurvey(SurveyType.phq9, List<int>.filled(9, 2)),
        (total: 18, severity: SurveySeverity.moderatelySevere),
      );
      expect(
        SurveyScoring.scoreSurvey(SurveyType.phq9, List<int>.filled(9, 3)),
        (total: 27, severity: SurveySeverity.severe),
      );
    });
  });

  group('GAD-7', () {
    test('total and severity bands', () {
      expect(
        SurveyScoring.scoreSurvey(SurveyType.gad7, List<int>.filled(7, 0)),
        (total: 0, severity: SurveySeverity.minimal),
      );
      expect(
        SurveyScoring.scoreSurvey(SurveyType.gad7, List<int>.filled(7, 1)),
        (total: 7, severity: SurveySeverity.mild),
      );
      expect(
        SurveyScoring.scoreSurvey(SurveyType.gad7, List<int>.filled(7, 3)),
        (total: 21, severity: SurveySeverity.severe),
      );
    });
  });

  group('PSS-10', () {
    test('reverse-scores questions 4,5,7,8 (0-based indices 3,4,6,7)', () {
      final List<int> allZero = List<int>.filled(
        SurveyDefinitions.pss10Questions.length,
        0,
      );
      int expected = 0;
      for (int i = 0; i < allZero.length; i++) {
        expected += SurveyScoring.scorePssItem(i, allZero[i]);
      }
      expect(expected, 16);

      final List<int> allFour = List<int>.filled(
        SurveyDefinitions.pss10Questions.length,
        4,
      );
      int expectedMax = 0;
      for (int i = 0; i < allFour.length; i++) {
        expectedMax += SurveyScoring.scorePssItem(i, allFour[i]);
      }
      expect(expectedMax, 24);
    });

    test('severity bands', () {
      // Low perceived stress: high scores on reverse items → contribution 0.
      final List<int> low = <int>[0, 0, 0, 4, 4, 0, 4, 4, 0, 0];
      final ({int total, SurveySeverity severity}) a =
          SurveyScoring.scoreSurvey(SurveyType.pss10, low);
      expect(a.total, 0);
      expect(a.severity, SurveySeverity.minimal);

      final ({int total, SurveySeverity severity}) b =
          SurveyScoring.scoreSurvey(SurveyType.pss10, List<int>.filled(10, 2));
      expect(b.severity, SurveySeverity.moderate);

      // Max PSS-10: high on forward items, 0 on reverse (reverse-scored as 4).
      final List<int> highStress = <int>[4, 4, 4, 0, 0, 4, 0, 0, 4, 4];
      final ({int total, SurveySeverity severity}) c =
          SurveyScoring.scoreSurvey(SurveyType.pss10, highStress);
      expect(c.total, 40);
      expect(c.severity, SurveySeverity.severe);
    });
  });
}
