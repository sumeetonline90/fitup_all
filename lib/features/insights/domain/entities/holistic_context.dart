import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/stress_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';

/// Aggregated snapshot for AI analysis. No user ids or PII.
class HolisticContext {
  const HolisticContext({
    this.stepsYesterday,
    this.caloriesBurnedYesterday,
    this.activeMinutesYesterday,
    this.avgStepsLast7Days,
    this.sleepMinutesLastNight,
    this.sleepQualityScoreLastNight,
    this.workoutSessionsThisWeek,
    this.totalCaloriesBurnedThisWeek,
    this.avgCaloriesLast7Days,
    this.avgProteinGramsLast7Days,
    this.avgCarbsGramsLast7Days,
    this.avgFatGramsLast7Days,
    this.avgWaterMlLast7Days,
    this.mealsLoggedToday,
    this.currentWorkoutGoal,
    this.currentFitnessLevel,
    this.workoutTypesThisWeek = const <String>[],
    this.hasRestDayToday,
    this.outOfRangeVitals = const <OutOfRangeVital>[],
    this.activeMedicationNames = const <String>[],
    this.uricAcidLatest,
    this.ldlLatest,
    this.fastingBloodSugarLatest,
    this.avgBloodGlucoseLatest,
    this.vitaminDLatest,
    this.vitaminB12Latest,
    this.todayMood,
    this.avgMoodLast7Days,
    this.currentStressScore,
    this.stressLevel,
    this.phq9Severity,
    this.gad7Severity,
    this.breathingSessionsThisWeek,
    this.meditationMinutesThisWeek,
    this.wearableHrvMsLatest,
    this.wearableStepsToday,
    this.primaryGoal,
    this.ageGroup,
    this.gender,
    this.bodyWeightKgLatest,
    this.heightCmLatest,
    this.bmiLatest,

    /// Joined community events (public + private) currently relevant to the user.
    this.joinedEventsCount,

    /// Active public/private duels the user is participating in.
    this.activeChallengesCount,

    /// Compact, anonymized strings describing active community targets (no organizer names).
    this.activeCommunityTargets = const <String>[],
  });

  final int? stepsYesterday;
  final double? caloriesBurnedYesterday;
  final int? activeMinutesYesterday;
  final double? avgStepsLast7Days;
  final int? sleepMinutesLastNight;
  final double? sleepQualityScoreLastNight;
  final int? workoutSessionsThisWeek;
  final double? totalCaloriesBurnedThisWeek;

  final double? avgCaloriesLast7Days;
  final double? avgProteinGramsLast7Days;
  final double? avgCarbsGramsLast7Days;
  final double? avgFatGramsLast7Days;
  final double? avgWaterMlLast7Days;
  final bool? mealsLoggedToday;

  final String? currentWorkoutGoal;
  final String? currentFitnessLevel;
  final List<String> workoutTypesThisWeek;
  final bool? hasRestDayToday;

  final List<OutOfRangeVital> outOfRangeVitals;
  final List<String> activeMedicationNames;
  final double? uricAcidLatest;
  final double? ldlLatest;
  final double? fastingBloodSugarLatest;
  final double? avgBloodGlucoseLatest;
  final double? vitaminDLatest;
  final double? vitaminB12Latest;

  final MoodLevel? todayMood;
  final MoodLevel? avgMoodLast7Days;
  final double? currentStressScore;
  final StressLevel? stressLevel;
  final SurveySeverity? phq9Severity;
  final SurveySeverity? gad7Severity;
  final int? breathingSessionsThisWeek;
  final int? meditationMinutesThisWeek;

  /// Latest HRV sample (ms) from Health Connect / HealthKit when available.
  final double? wearableHrvMsLatest;

  /// Steps today from wearable pipeline (0 treated as unknown in prompts).
  final int? wearableStepsToday;

  final String? primaryGoal;
  final String? ageGroup;
  final String? gender;

  /// Latest body weight (kg) after profile + vitals merge.
  final double? bodyWeightKgLatest;

  /// Latest height (cm) after profile + vitals merge.
  final double? heightCmLatest;

  /// BMI (kg/m²) derived from latest weight and height when both known.
  final double? bmiLatest;

  /// Joined community events (public + private) currently relevant to the user.
  final int? joinedEventsCount;

  /// Active public/private duels the user is participating in.
  final int? activeChallengesCount;

  /// Compact, anonymized strings describing active community targets (no organizer names).
  final List<String> activeCommunityTargets;
}

/// Display name + band only (no raw values).
class OutOfRangeVital {
  const OutOfRangeVital({
    required this.vitalName,
    required this.status,
    required this.recordedAt,
  });

  final String vitalName;
  final String status;
  final DateTime recordedAt;
}
