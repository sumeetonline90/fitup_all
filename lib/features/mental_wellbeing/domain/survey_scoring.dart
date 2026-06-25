import 'entities/survey_severity.dart';
import 'entities/survey_type.dart';
import 'survey_definitions.dart';

/// Validates answers and computes totals + severity bands (screening-oriented).
class SurveyScoring {
  SurveyScoring._();

  static int totalPhq9(List<int> answers) {
    if (answers.length != SurveyDefinitions.phq9Questions.length) {
      throw ArgumentError('PHQ-9 requires 9 answers');
    }
    return answers.fold<int>(0, (int s, int a) => s + a.clamp(0, 3));
  }

  static SurveySeverity severityPhq9(int total) {
    if (total <= 4) {
      return SurveySeverity.minimal;
    }
    if (total <= 9) {
      return SurveySeverity.mild;
    }
    if (total <= 14) {
      return SurveySeverity.moderate;
    }
    if (total <= 19) {
      return SurveySeverity.moderatelySevere;
    }
    return SurveySeverity.severe;
  }

  static int totalGad7(List<int> answers) {
    if (answers.length != SurveyDefinitions.gad7Questions.length) {
      throw ArgumentError('GAD-7 requires 7 answers');
    }
    return answers.fold<int>(0, (int s, int a) => s + a.clamp(0, 3));
  }

  static SurveySeverity severityGad7(int total) {
    if (total <= 4) {
      return SurveySeverity.minimal;
    }
    if (total <= 9) {
      return SurveySeverity.mild;
    }
    if (total <= 14) {
      return SurveySeverity.moderate;
    }
    return SurveySeverity.severe;
  }

  static int scorePssItem(int index, int raw) {
    final int c = raw.clamp(0, 4);
    if (SurveyDefinitions.pss10ReverseIndices.contains(index)) {
      return 4 - c;
    }
    return c;
  }

  static int totalPss10(List<int> answers) {
    if (answers.length != SurveyDefinitions.pss10Questions.length) {
      throw ArgumentError('PSS-10 requires 10 answers');
    }
    int sum = 0;
    for (int i = 0; i < answers.length; i++) {
      sum += scorePssItem(i, answers[i]);
    }
    return sum;
  }

  static SurveySeverity severityPss10(int total) {
    if (total <= 13) {
      return SurveySeverity.minimal;
    }
    if (total <= 26) {
      return SurveySeverity.moderate;
    }
    return SurveySeverity.severe;
  }

  static ({int total, SurveySeverity severity}) scoreSurvey(
    SurveyType type,
    List<int> answers,
  ) {
    switch (type) {
      case SurveyType.phq9:
        final int t = totalPhq9(answers);
        return (total: t, severity: severityPhq9(t));
      case SurveyType.gad7:
        final int t = totalGad7(answers);
        return (total: t, severity: severityGad7(t));
      case SurveyType.pss10:
        final int t = totalPss10(answers);
        return (total: t, severity: severityPss10(t));
    }
  }
}
