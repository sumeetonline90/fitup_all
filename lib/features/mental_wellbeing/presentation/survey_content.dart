import '../domain/entities/survey_type.dart';

class SurveyQuestion {
  const SurveyQuestion({required this.text});

  final String text;
}

List<SurveyQuestion> questionsFor(SurveyType type) {
  return switch (type) {
    SurveyType.phq9 => const <SurveyQuestion>[
      SurveyQuestion(text: 'Little interest or pleasure in doing things?'),
      SurveyQuestion(text: 'Feeling down, depressed, or hopeless?'),
      SurveyQuestion(
        text: 'Trouble falling or staying asleep, or sleeping too much?',
      ),
      SurveyQuestion(text: 'Feeling tired or having little energy?'),
      SurveyQuestion(text: 'Poor appetite or overeating?'),
      SurveyQuestion(
        text:
            'Feeling bad about yourself — or that you are a failure or have let yourself or your family down?',
      ),
      SurveyQuestion(
        text:
            'Trouble concentrating on things, such as reading the newspaper or watching television?',
      ),
      SurveyQuestion(
        text:
            'Moving or speaking so slowly that other people could have noticed? Or being fidgety or restless?',
      ),
      SurveyQuestion(
        text:
            'Thoughts that you would be better off dead, or of hurting yourself?',
      ),
    ],
    SurveyType.gad7 => const <SurveyQuestion>[
      SurveyQuestion(text: 'Feeling nervous, anxious, or on edge?'),
      SurveyQuestion(text: 'Not being able to stop or control worrying?'),
      SurveyQuestion(text: 'Worrying too much about different things?'),
      SurveyQuestion(text: 'Trouble relaxing?'),
      SurveyQuestion(text: 'Being so restless that it is hard to sit still?'),
      SurveyQuestion(text: 'Becoming easily annoyed or irritable?'),
      SurveyQuestion(
        text: 'Feeling afraid, as if something awful might happen?',
      ),
    ],
    SurveyType.pss10 => const <SurveyQuestion>[
      SurveyQuestion(
        text:
            'In the last month, how often have you been upset because of something that happened unexpectedly?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt that you were unable to control the important things in your life?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt nervous and stressed?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt confident about your ability to handle personal problems?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt that things were going your way?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you found that you could not cope with all the things you had to do?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you been able to control irritations in your life?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt that you were on top of things?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you been angered because of things outside your control?',
      ),
      SurveyQuestion(
        text:
            'In the last month, how often have you felt difficulties were piling up so high that you could not overcome them?',
      ),
    ],
  };
}

/// PHQ-9 / GAD-7 style 0–3 labels.
List<String> likert03Labels() => const <String>[
  'Not at all',
  'Several days',
  'More than half the days',
  'Nearly every day',
];

/// PSS 0–4 (reverse scoring handled only in total for demo — simplified).
List<String> likert04Labels() => const <String>[
  'Never',
  'Almost never',
  'Sometimes',
  'Fairly often',
  'Very often',
];

String severityLabel(SurveyType type, int score) {
  return switch (type) {
    SurveyType.phq9 => switch (score) {
      <= 4 => 'Minimal Depression Symptoms',
      <= 9 => 'Mild Depression Symptoms',
      <= 14 => 'Moderate Depression Risk',
      <= 19 => 'Moderately Severe Depression Risk',
      _ => 'Severe Depression Risk',
    },
    SurveyType.gad7 => switch (score) {
      <= 4 => 'Minimal Anxiety',
      <= 9 => 'Mild Anxiety',
      <= 14 => 'Moderate Anxiety',
      _ => 'Severe Anxiety',
    },
    SurveyType.pss10 => switch (score) {
      <= 13 => 'Low Perceived Stress',
      <= 26 => 'Moderate Perceived Stress',
      _ => 'High Perceived Stress',
    },
  };
}
