import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';
import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';

/// Deterministic cross-module rules (runs before Gemini). ADR-017: screening-style
/// copy only — no diagnoses or clinical labels.
class ConflictDetector {
  const ConflictDetector();

  List<CorrelationAlert> detectFrom(HolisticContext ctx) {
    final List<CorrelationAlert> alerts = <CorrelationAlert>[];
    final DateTime now = DateTime.now();

    if ((ctx.sleepMinutesLastNight ?? 999) < 360 &&
        (ctx.workoutSessionsThisWeek ?? 0) >= 4) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-sleep-training',
          type: AlertType.conflict,
          severity: AlertSeverity.warning,
          title: 'Heavy training with limited sleep recovery',
          message:
              'Your logged sleep is on the low side while training often this week. '
              'You may want to prioritize rest and recovery — something to discuss '
              'with your clinician if it persists.',
          modules: <String>['Activity', 'Mental'],
          generatedAt: now,
        ),
      );
    }

    if ((ctx.uricAcidLatest ?? 0) > 7.3 &&
        ctx.workoutTypesThisWeek.any(
          (String t) => t.toLowerCase().contains('run'),
        )) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-uric-acid-run',
          type: AlertType.conflict,
          severity: AlertSeverity.warning,
          title: 'Uric acid above typical band + running',
          message:
              'Your recent uric acid reading is outside a common reference band for '
              'some labs. Joint-friendly activity choices may warrant discussion with '
              'your clinician.',
          modules: <String>['Health', 'Activity'],
          generatedAt: now,
        ),
      );
    }

    if ((ctx.vitaminDLatest ?? 30) < 20 &&
        ctx.todayMood != null &&
        (ctx.todayMood!.index <= MoodLevel.bad.index)) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-vitd-mood',
          type: AlertType.recommendation,
          severity: AlertSeverity.info,
          title: 'Low vitamin D reading and lower mood check-in',
          message:
              'Vitamin D can relate to how people feel, but many factors matter. '
              'Interpretation of your level may warrant discussion with your clinician.',
          modules: <String>['Health', 'Mental'],
          generatedAt: now,
        ),
      );
    }

    if ((ctx.vitaminB12Latest ?? 999) < 211 &&
        ctx.currentStressScore != null &&
        ctx.currentStressScore! > 60) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-b12-stress',
          type: AlertType.recommendation,
          severity: AlertSeverity.info,
          title: 'B12 below typical band + elevated stress score',
          message:
              'Your B12 is below a common lab reference band in some guidelines. '
              'Fatigue and stress have many causes — consider reviewing results with '
              'your clinician rather than self-treating.',
          modules: <String>['Health', 'Mental'],
          generatedAt: now,
        ),
      );
    }

    if ((ctx.ldlLatest ?? 0) > 130 && (ctx.avgFatGramsLast7Days ?? 0) > 80) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-ldl-fat',
          type: AlertType.recommendation,
          severity: AlertSeverity.warning,
          title: 'LDL pattern + higher fat intake (logged)',
          message:
              'Your logged fat intake is relatively high alongside an LDL reading '
              'outside a typical target band for some people. Diet patterns are worth '
              'reviewing with your clinician or a registered dietitian.',
          modules: <String>['Health', 'Diet'],
          generatedAt: now,
        ),
      );
    }

    if ((ctx.currentStressScore ?? 0) > 65 &&
        (ctx.workoutSessionsThisWeek ?? 0) == 0) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-stress-no-activity',
          type: AlertType.encouragement,
          severity: AlertSeverity.info,
          title: 'Movement may support stress balance',
          message:
              'Many people find light activity helpful for stress. Even a short walk '
              'could be something to try when it feels right for you.',
          modules: <String>['Mental', 'Activity'],
          generatedAt: now,
        ),
      );
    }

    final double? glucose =
        ctx.fastingBloodSugarLatest ?? ctx.avgBloodGlucoseLatest;
    if ((glucose ?? 0) > 100 && (ctx.avgCarbsGramsLast7Days ?? 0) > 300) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-fbs-carbs',
          type: AlertType.recommendation,
          severity: AlertSeverity.warning,
          title: 'Glucose reading + high logged carbohydrate intake',
          message:
              'Your glucose-related reading is above a common fasting reference band '
              'for some labs, alongside high logged carbs. Screening apps are not '
              'diagnostic — results may warrant discussion with your clinician.',
          modules: <String>['Health', 'Diet'],
          generatedAt: now,
        ),
      );
    }

    if (ctx.phq9Severity != null &&
        ctx.phq9Severity!.index >= SurveySeverity.moderate.index &&
        (ctx.meditationMinutesThisWeek ?? 0) == 0 &&
        (ctx.breathingSessionsThisWeek ?? 0) == 0) {
      alerts.add(
        CorrelationAlert(
          id: 'rule-phq9-wellness-tools',
          type: AlertType.recommendation,
          severity: AlertSeverity.info,
          title: 'Wellness tools you might try',
          message:
              'Breathing exercises or short guided sessions are optional supports — '
              'not a substitute for care. If symptoms are difficult, consider reaching '
              'out to a qualified professional.',
          modules: <String>['Mental'],
          generatedAt: now,
        ),
      );
    }

    return alerts;
  }
}
