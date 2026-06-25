import 'dart:convert';

import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/stress_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';

String encodeHolisticContext(HolisticContext c) =>
    jsonEncode(_holisticContextToMap(c));

HolisticContext decodeHolisticContext(String raw) {
  final Object? d = jsonDecode(raw);
  if (d is! Map<String, dynamic>) {
    return const HolisticContext();
  }
  return _holisticContextFromMap(d);
}

Map<String, dynamic> _holisticContextToMap(HolisticContext c) {
  return <String, dynamic>{
    'stepsYesterday': c.stepsYesterday,
    'caloriesBurnedYesterday': c.caloriesBurnedYesterday,
    'activeMinutesYesterday': c.activeMinutesYesterday,
    'avgStepsLast7Days': c.avgStepsLast7Days,
    'sleepMinutesLastNight': c.sleepMinutesLastNight,
    'sleepQualityScoreLastNight': c.sleepQualityScoreLastNight,
    'workoutSessionsThisWeek': c.workoutSessionsThisWeek,
    'totalCaloriesBurnedThisWeek': c.totalCaloriesBurnedThisWeek,
    'avgCaloriesLast7Days': c.avgCaloriesLast7Days,
    'avgProteinGramsLast7Days': c.avgProteinGramsLast7Days,
    'avgCarbsGramsLast7Days': c.avgCarbsGramsLast7Days,
    'avgFatGramsLast7Days': c.avgFatGramsLast7Days,
    'avgWaterMlLast7Days': c.avgWaterMlLast7Days,
    'mealsLoggedToday': c.mealsLoggedToday,
    'currentWorkoutGoal': c.currentWorkoutGoal,
    'currentFitnessLevel': c.currentFitnessLevel,
    'workoutTypesThisWeek': c.workoutTypesThisWeek,
    'hasRestDayToday': c.hasRestDayToday,
    'outOfRangeVitals': c.outOfRangeVitals
        .map(
          (OutOfRangeVital v) => <String, dynamic>{
            'vitalName': v.vitalName,
            'status': v.status,
            'recordedAt': v.recordedAt.toIso8601String(),
          },
        )
        .toList(),
    'activeMedicationNames': c.activeMedicationNames,
    'uricAcidLatest': c.uricAcidLatest,
    'ldlLatest': c.ldlLatest,
    'fastingBloodSugarLatest': c.fastingBloodSugarLatest,
    'avgBloodGlucoseLatest': c.avgBloodGlucoseLatest,
    'vitaminDLatest': c.vitaminDLatest,
    'vitaminB12Latest': c.vitaminB12Latest,
    'todayMood': c.todayMood?.name,
    'avgMoodLast7Days': c.avgMoodLast7Days?.name,
    'currentStressScore': c.currentStressScore,
    'stressLevel': c.stressLevel?.name,
    'phq9Severity': c.phq9Severity?.name,
    'gad7Severity': c.gad7Severity?.name,
    'breathingSessionsThisWeek': c.breathingSessionsThisWeek,
    'meditationMinutesThisWeek': c.meditationMinutesThisWeek,
    'wearableHrvMsLatest': c.wearableHrvMsLatest,
    'wearableStepsToday': c.wearableStepsToday,
    'primaryGoal': c.primaryGoal,
    'ageGroup': c.ageGroup,
    'gender': c.gender,
    'bodyWeightKgLatest': c.bodyWeightKgLatest,
    'heightCmLatest': c.heightCmLatest,
    'bmiLatest': c.bmiLatest,

    'joinedEventsCount': c.joinedEventsCount,
    'activeChallengesCount': c.activeChallengesCount,
    'activeCommunityTargets': c.activeCommunityTargets,
  };
}

HolisticContext _holisticContextFromMap(Map<String, dynamic> m) {
  MoodLevel? mood(String? k) {
    final String? s = m[k] as String?;
    if (s == null) {
      return null;
    }
    return MoodLevel.values.firstWhere(
      (MoodLevel e) => e.name == s,
      orElse: () => MoodLevel.neutral,
    );
  }

  StressLevel? stress(String? s) {
    if (s == null) {
      return null;
    }
    return StressLevel.values.firstWhere(
      (StressLevel e) => e.name == s,
      orElse: () => StressLevel.low,
    );
  }

  SurveySeverity? surv(String? s) {
    if (s == null) {
      return null;
    }
    return SurveySeverity.values.firstWhere(
      (SurveySeverity e) => e.name == s,
      orElse: () => SurveySeverity.minimal,
    );
  }

  final List<dynamic>? oorRaw = m['outOfRangeVitals'] as List<dynamic>?;
  final List<OutOfRangeVital> oor = <OutOfRangeVital>[];
  if (oorRaw != null) {
    for (final dynamic e in oorRaw) {
      if (e is Map<String, dynamic>) {
        oor.add(
          OutOfRangeVital(
            vitalName: e['vitalName'] as String? ?? '',
            status: e['status'] as String? ?? '',
            recordedAt:
                DateTime.tryParse(e['recordedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      }
    }
  }

  final List<dynamic>? wRaw = m['workoutTypesThisWeek'] as List<dynamic>?;
  final List<String> wTypes =
      wRaw?.map((dynamic e) => e.toString()).toList() ?? const <String>[];

  final List<dynamic>? medRaw = m['activeMedicationNames'] as List<dynamic>?;
  final List<String> meds =
      medRaw?.map((dynamic e) => e.toString()).toList() ?? const <String>[];

  return HolisticContext(
    stepsYesterday: (m['stepsYesterday'] as num?)?.toInt(),
    caloriesBurnedYesterday: (m['caloriesBurnedYesterday'] as num?)?.toDouble(),
    activeMinutesYesterday: (m['activeMinutesYesterday'] as num?)?.toInt(),
    avgStepsLast7Days: (m['avgStepsLast7Days'] as num?)?.toDouble(),
    sleepMinutesLastNight: (m['sleepMinutesLastNight'] as num?)?.toInt(),
    sleepQualityScoreLastNight: (m['sleepQualityScoreLastNight'] as num?)
        ?.toDouble(),
    workoutSessionsThisWeek: (m['workoutSessionsThisWeek'] as num?)?.toInt(),
    totalCaloriesBurnedThisWeek: (m['totalCaloriesBurnedThisWeek'] as num?)
        ?.toDouble(),
    avgCaloriesLast7Days: (m['avgCaloriesLast7Days'] as num?)?.toDouble(),
    avgProteinGramsLast7Days: (m['avgProteinGramsLast7Days'] as num?)
        ?.toDouble(),
    avgCarbsGramsLast7Days: (m['avgCarbsGramsLast7Days'] as num?)?.toDouble(),
    avgFatGramsLast7Days: (m['avgFatGramsLast7Days'] as num?)?.toDouble(),
    avgWaterMlLast7Days: (m['avgWaterMlLast7Days'] as num?)?.toDouble(),
    mealsLoggedToday: m['mealsLoggedToday'] as bool?,
    currentWorkoutGoal: m['currentWorkoutGoal'] as String?,
    currentFitnessLevel: m['currentFitnessLevel'] as String?,
    workoutTypesThisWeek: wTypes,
    hasRestDayToday: m['hasRestDayToday'] as bool?,
    outOfRangeVitals: oor,
    activeMedicationNames: meds,
    uricAcidLatest: (m['uricAcidLatest'] as num?)?.toDouble(),
    ldlLatest: (m['ldlLatest'] as num?)?.toDouble(),
    fastingBloodSugarLatest: (m['fastingBloodSugarLatest'] as num?)?.toDouble(),
    avgBloodGlucoseLatest: (m['avgBloodGlucoseLatest'] as num?)?.toDouble(),
    vitaminDLatest: (m['vitaminDLatest'] as num?)?.toDouble(),
    vitaminB12Latest: (m['vitaminB12Latest'] as num?)?.toDouble(),
    todayMood: mood('todayMood'),
    avgMoodLast7Days: mood('avgMoodLast7Days'),
    currentStressScore: (m['currentStressScore'] as num?)?.toDouble(),
    stressLevel: stress(m['stressLevel'] as String?),
    phq9Severity: surv(m['phq9Severity'] as String?),
    gad7Severity: surv(m['gad7Severity'] as String?),
    breathingSessionsThisWeek: (m['breathingSessionsThisWeek'] as num?)
        ?.toInt(),
    meditationMinutesThisWeek: (m['meditationMinutesThisWeek'] as num?)
        ?.toInt(),
    wearableHrvMsLatest: (m['wearableHrvMsLatest'] as num?)?.toDouble(),
    wearableStepsToday: (m['wearableStepsToday'] as num?)?.toInt(),
    primaryGoal: m['primaryGoal'] as String?,
    ageGroup: m['ageGroup'] as String?,
    gender: m['gender'] as String?,
    bodyWeightKgLatest: (m['bodyWeightKgLatest'] as num?)?.toDouble(),
    heightCmLatest: (m['heightCmLatest'] as num?)?.toDouble(),
    bmiLatest: (m['bmiLatest'] as num?)?.toDouble(),

    joinedEventsCount: (m['joinedEventsCount'] as num?)?.toInt(),
    activeChallengesCount: (m['activeChallengesCount'] as num?)?.toInt(),
    activeCommunityTargets: (m['activeCommunityTargets'] as List<dynamic>?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
  );
}
