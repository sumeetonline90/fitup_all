import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';
import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/insights/domain/services/conflict_detector.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const ConflictDetector detector = ConflictDetector();

  test(
    'detects sleep + training conflict when sleep < 6h and sessions >= 4',
    () {
      final List<CorrelationAlert> alerts = detector.detectFrom(
        const HolisticContext(
          sleepMinutesLastNight: 300,
          workoutSessionsThisWeek: 4,
        ),
      );
      expect(alerts, isNotEmpty);
      final CorrelationAlert a = alerts.firstWhere(
        (CorrelationAlert x) => x.id == 'rule-sleep-training',
      );
      expect(a.title, 'Heavy training with limited sleep recovery');
      expect(a.message, contains('clinician'));
    },
  );

  test(
    'detects high avg blood glucose + high carbs when fasting sugar absent',
    () {
      final List<CorrelationAlert> alerts = detector.detectFrom(
        const HolisticContext(
          avgBloodGlucoseLatest: 115,
          avgCarbsGramsLast7Days: 320,
        ),
      );
      expect(alerts, isNotEmpty);
      expect(
        alerts.any(
          (CorrelationAlert a) => a.title.contains('Glucose reading'),
        ),
        isTrue,
      );
      expect(
        alerts.every(
          (CorrelationAlert a) =>
              !a.message.toLowerCase().contains('prediabetes'),
        ),
        isTrue,
      );
    },
  );

  test('detects high uric acid + running conflict', () {
    final List<CorrelationAlert> alerts = detector.detectFrom(
      const HolisticContext(
        uricAcidLatest: 7.5,
        workoutTypesThisWeek: <String>['Outdoor Running'],
      ),
    );
    expect(alerts, isNotEmpty);
    expect(
      alerts.any(
        (CorrelationAlert a) =>
            a.title.toLowerCase().contains('uric acid'),
      ),
      isTrue,
    );
  });

  test('detects low vitamin D + bad mood recommendation', () {
    final List<CorrelationAlert> alerts = detector.detectFrom(
      const HolisticContext(vitaminDLatest: 15, todayMood: MoodLevel.bad),
    );
    expect(alerts, isNotEmpty);
    final CorrelationAlert a = alerts.firstWhere(
      (CorrelationAlert x) => x.id == 'rule-vitd-mood',
    );
    expect(a.title.toLowerCase(), contains('vitamin d'));
    expect(a.message.toLowerCase(), isNot(contains('deficiency')));
  });

  test('B12 rule avoids deficiency-detected phrasing', () {
    final List<CorrelationAlert> alerts = detector.detectFrom(
      const HolisticContext(
        vitaminB12Latest: 200,
        currentStressScore: 70,
      ),
    );
    final CorrelationAlert a = alerts.firstWhere(
      (CorrelationAlert x) => x.id == 'rule-b12-stress',
    );
    expect(a.title.toLowerCase(), isNot(contains('detected')));
    expect(a.message, contains('clinician'));
  });

  test('returns empty list when all metrics are healthy', () {
    final List<CorrelationAlert> alerts = detector.detectFrom(
      const HolisticContext(
        sleepMinutesLastNight: 480,
        workoutSessionsThisWeek: 2,
        uricAcidLatest: 6,
        vitaminDLatest: 35,
        todayMood: MoodLevel.good,
        vitaminB12Latest: 400,
        currentStressScore: 20,
        ldlLatest: 90,
        avgFatGramsLast7Days: 50,
        fastingBloodSugarLatest: 90,
        avgCarbsGramsLast7Days: 200,
        phq9Severity: SurveySeverity.minimal,
        meditationMinutesThisWeek: 10,
        breathingSessionsThisWeek: 1,
      ),
    );
    expect(alerts, isEmpty);
  });

  test('handles null fields gracefully — no throws', () {
    expect(() => detector.detectFrom(const HolisticContext()), returnsNormally);
    final List<CorrelationAlert> alerts = detector.detectFrom(
      const HolisticContext(),
    );
    expect(alerts, isA<List<CorrelationAlert>>());
  });
}
