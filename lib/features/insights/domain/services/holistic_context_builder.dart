import 'package:fitup/features/activity/domain/entities/activity.dart';
import 'package:fitup/features/activity/domain/entities/sleep_log.dart';
import 'package:fitup/features/activity/domain/repositories/activity_repository.dart';
import 'package:fitup/features/diet/domain/entities/diet_summary.dart';
import 'package:fitup/features/diet/domain/entities/meal.dart';
import 'package:fitup/features/diet/domain/repositories/diet_repository.dart';
import 'package:fitup/features/health/domain/entities/health_summary.dart';
import 'package:fitup/features/health/domain/entities/health_summary_body_metrics.dart';
import 'package:fitup/features/health/domain/entities/vital_entry.dart';
import 'package:fitup/features/health/domain/entities/vital_reference_range.dart';
import 'package:fitup/features/health/domain/entities/vital_type.dart';
import 'package:fitup/features/health/domain/entities/vital_type_extension.dart';
import 'package:fitup/features/health/domain/repositories/health_repository.dart';
import 'package:fitup/features/profile/domain/entities/user_profile.dart';
import 'package:fitup/features/profile/domain/repositories/profile_repository.dart';
import 'package:fitup/features/community/domain/entities/challenge.dart';
import 'package:fitup/features/community/domain/entities/community_event.dart';
import 'package:fitup/features/community/domain/repositories/community_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mental_wellbeing_summary.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_entry.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/stress_score.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_result.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_type.dart';
import 'package:fitup/features/mental_wellbeing/domain/repositories/mental_wellbeing_repository.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/services/ai_input_sanitizer.dart';
import 'package:fitup/services/health_connect_service.dart';
import 'package:flutter/foundation.dart';

/// Aggregates anonymized cross-module context for AI (no Gemini calls).
class HolisticContextBuilder {
  const HolisticContextBuilder({
    required ActivityRepository activityRepo,
    required DietRepository dietRepo,
    required WorkoutRepository workoutRepo,
    required HealthRepository healthRepo,
    required MentalWellbeingRepository mentalRepo,
    required CommunityRepository communityRepo,
    required HealthConnectService healthConnect,
    required ProfileRepository profileRepo,
  }) : _activityRepo = activityRepo,
       _dietRepo = dietRepo,
       _workoutRepo = workoutRepo,
       _healthRepo = healthRepo,
       _mentalRepo = mentalRepo,
       _communityRepo = communityRepo,
       _healthConnect = healthConnect,
       _profileRepo = profileRepo;

  final ActivityRepository _activityRepo;
  final DietRepository _dietRepo;
  final WorkoutRepository _workoutRepo;
  final HealthRepository _healthRepo;
  final MentalWellbeingRepository _mentalRepo;
  final CommunityRepository _communityRepo;
  final HealthConnectService _healthConnect;
  final ProfileRepository _profileRepo;

  Future<HolisticContext> buildFor(String userId) async {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime yesterdayStart = todayStart.subtract(
      const Duration(days: 1),
    );
    final DateTime yesterdayEnd = todayStart;
    final DateTime sevenDaysAgo = todayStart.subtract(const Duration(days: 7));
    final DateTime weekStart = _mondayOfDate(todayStart);

    final List<Object?> raw = await Future.wait<Object?>(<Future<Object?>>[
      _safe(
        () => _loadActivitySlice(
          userId,
          yesterdayStart,
          yesterdayEnd,
          sevenDaysAgo,
          todayStart,
          now,
        ),
      ),
      _safe(() => _loadDietSlice(userId, todayStart, sevenDaysAgo)),
      _safe(() => _loadWorkoutSlice(userId, weekStart, now, todayStart)),
      _safe(() => _loadHealthSlice(userId)),
      _safe(() => _loadMentalSlice(userId, now)),
      _safe(() => _loadCommunitySlice(userId, now)),
      _safe(_loadWearableSlice),
    ], eagerError: false);

    final _ActivitySlice? a = raw[0] as _ActivitySlice?;
    final _DietSlice? d = raw[1] as _DietSlice?;
    final _WorkoutSlice? w = raw[2] as _WorkoutSlice?;
    final _HealthSlice? h = raw[3] as _HealthSlice?;
    final _MentalSlice? m = raw[4] as _MentalSlice?;
    final _CommunitySlice? c = raw[5] as _CommunitySlice?;
    final _WearableSlice? wear = raw[6] as _WearableSlice?;

    return HolisticContext(
      stepsYesterday: a?.stepsYesterday,
      caloriesBurnedYesterday: a?.caloriesYesterday,
      activeMinutesYesterday: a?.activeMinutesYesterday,
      avgStepsLast7Days: a?.avgSteps7d,
      sleepMinutesLastNight: a?.sleepMinutesLastNight,
      sleepQualityScoreLastNight: a?.sleepQualityLastNight,
      workoutSessionsThisWeek: w?.sessionsThisWeek,
      totalCaloriesBurnedThisWeek: w?.caloriesThisWeek,
      avgCaloriesLast7Days: d?.avgCalories7d,
      avgProteinGramsLast7Days: d?.avgProtein7d,
      avgCarbsGramsLast7Days: d?.avgCarbs7d,
      avgFatGramsLast7Days: d?.avgFat7d,
      avgWaterMlLast7Days: d?.avgWater7d,
      mealsLoggedToday: d?.mealsLoggedToday,
      currentWorkoutGoal: w?.primaryGoal,
      currentFitnessLevel: w?.fitnessLevel,
      workoutTypesThisWeek: w?.workoutTypes ?? const <String>[],
      hasRestDayToday: w?.hasRestDayToday,
      outOfRangeVitals: h?.outOfRange ?? const <OutOfRangeVital>[],
      activeMedicationNames: h?.medNames ?? const <String>[],
      uricAcidLatest: h?.uricAcid,
      ldlLatest: h?.ldl,
      fastingBloodSugarLatest: h?.fbs,
      avgBloodGlucoseLatest: h?.avgGlu,
      vitaminDLatest: h?.vitD,
      vitaminB12Latest: h?.b12,
      todayMood: m?.todayMood ?? m?.summary?.latestMood?.mood,
      avgMoodLast7Days: m?.avgMood7d,
      currentStressScore: m?.stress?.score,
      stressLevel: m?.stress?.level,
      phq9Severity: m?.phq9Severity,
      gad7Severity: m?.gad7Severity,
      breathingSessionsThisWeek: m?.summary?.breathingSessionsThisWeek,
      meditationMinutesThisWeek: m?.summary?.meditationMinutesThisWeek,
      wearableHrvMsLatest: wear?.hrvMs,
      wearableStepsToday: wear?.stepsToday,
      primaryGoal: null,
      ageGroup: null,
      gender: null,
      bodyWeightKgLatest: h?.bodyWeightKg,
      heightCmLatest: h?.heightCm,
      bmiLatest: h?.bmi,

      joinedEventsCount: c?.joinedEventsCount,
      activeChallengesCount: c?.activeChallengesCount,
      activeCommunityTargets: c?.activeTargets ?? const <String>[],
    );
  }

  Future<_CommunitySlice?> _loadCommunitySlice(
    String userId,
    DateTime now,
  ) async {
    final Either<Failure, List<CommunityEvent>> joinedRes =
        await _communityRepo.getJoinedEvents(userId);
    final List<CommunityEvent> joined = joinedRes.fold(
      (Failure _) => <CommunityEvent>[],
      (List<CommunityEvent> l) => l,
    );

    final List<CommunityEvent> relevantEvents = joined.where((CommunityEvent e) {
      if (e.status == EventStatus.completed || e.status == EventStatus.cancelled) {
        return false;
      }
      // Consider public + private equally; AI prompt is anonymized.
      return true;
    }).toList();

    final int joinedEventsCount = relevantEvents.length;

    final List<String> targets = <String>[];
    for (final CommunityEvent e in relevantEvents) {
      if (targets.length >= 8) break;
      switch (e.type) {
        case EventType.stepChallenge:
          if (e.targetSteps != null) {
            targets.add('Step challenge target: ${e.targetSteps} steps');
          }
          break;
        case EventType.walkingChallenge:
          if (e.targetDistanceKm != null) {
            targets.add(
              'Walking challenge target: ${e.targetDistanceKm!.toStringAsFixed(1)} km',
            );
          }
          break;
        default:
          targets.add('${e.type.name} event (target value not provided)');
      }
    }

    final Either<Failure, List<Challenge>> challengesRes =
        await _communityRepo.getActiveChallenges(userId);
    final List<Challenge> activeChallenges = challengesRes.fold(
      (Failure _) => <Challenge>[],
      (List<Challenge> l) => l,
    );

    for (final Challenge c in activeChallenges) {
      if (targets.length >= 10) break;
      final String metric = switch (c.metric) {
        ChallengeMetric.steps => 'steps',
        ChallengeMetric.distance => 'distance',
        ChallengeMetric.workouts => 'workouts',
        ChallengeMetric.caloriesBurned => 'kcal burned',
        ChallengeMetric.fitcoins => 'fitcoins',
      };
      targets.add('Duel target: ${metric} = ${c.targetValue}');
    }

    return _CommunitySlice(
      joinedEventsCount: joinedEventsCount,
      activeChallengesCount: activeChallenges.length,
      activeTargets: targets,
    );
  }

  Future<_WearableSlice?> _loadWearableSlice() async {
    if (kIsWeb) {
      return null;
    }
    final double? hrv = await _healthConnect.getLatestHrvMs();
    final int steps = await _healthConnect.getTodaySteps();
    if (hrv == null && steps <= 0) {
      return null;
    }
    return _WearableSlice(hrvMs: hrv, stepsToday: steps > 0 ? steps : null);
  }

  Future<Object?> _safe(Future<Object?> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      debugPrint('HolisticContextBuilder: $e $st');
      return null;
    }
  }

  Future<_ActivitySlice> _loadActivitySlice(
    String userId,
    DateTime yesterdayStart,
    DateTime yesterdayEnd,
    DateTime sevenDaysAgo,
    DateTime todayStart,
    DateTime now,
  ) async {
    final List<Activity> yActs = await _activityRepo
        .getActivities(userId, from: yesterdayStart, to: yesterdayEnd)
        .then((r) => r.fold((_) => <Activity>[], (List<Activity> l) => l));
    int stepsY = 0;
    double calY = 0;
    int activeMinY = 0;
    bool anySteps = false;
    for (final Activity a in yActs) {
      calY += a.caloriesBurnt;
      activeMinY += a.durationSeconds ~/ 60;
      if (a.steps != null) {
        stepsY += a.steps!;
        anySteps = true;
      }
    }

    final List<Activity> weekActs = await _activityRepo
        .getActivities(userId, from: sevenDaysAgo, to: now)
        .then((r) => r.fold((_) => <Activity>[], (List<Activity> l) => l));
    final Map<int, int> stepsByDay = <int, int>{};
    for (final Activity a in weekActs) {
      if (a.steps != null) {
        final int k = _dayKey(a.startTime);
        stepsByDay[k] = (stepsByDay[k] ?? 0) + a.steps!;
      }
    }
    double? avgSteps;
    if (stepsByDay.isNotEmpty) {
      avgSteps = stepsByDay.values.reduce((int a, int b) => a + b) / 7.0;
    }

    List<SleepLog> sleepLogs = await _activityRepo
        .getSleepLogs(
          userId,
          from: todayStart.subtract(const Duration(days: 1)),
          to: now,
        )
        .then((r) => r.fold((_) => <SleepLog>[], (List<SleepLog> l) => l));

    if (sleepLogs.isEmpty && !kIsWeb) {
      sleepLogs = await _healthConnect.getSleepData(
        todayStart.subtract(const Duration(days: 2)),
        now,
      );
    }

    SleepLog? lastNight;
    for (final SleepLog s in sleepLogs) {
      if (_sameCalendarDay(s.wakeTime, now) ||
          s.wakeTime.isAfter(todayStart.subtract(const Duration(hours: 12)))) {
        if (lastNight == null || s.wakeTime.isAfter(lastNight.wakeTime)) {
          lastNight = s;
        }
      }
    }
    lastNight ??= sleepLogs.isNotEmpty
        ? sleepLogs.reduce(
            (SleepLog a, SleepLog b) => a.wakeTime.isAfter(b.wakeTime) ? a : b,
          )
        : null;

    double? qual;
    if (lastNight?.quality != null) {
      qual = lastNight!.quality! * 10;
    }

    return _ActivitySlice(
      stepsYesterday: anySteps ? stepsY : null,
      caloriesYesterday: calY > 0 ? calY : null,
      activeMinutesYesterday: activeMinY > 0 ? activeMinY : null,
      avgSteps7d: avgSteps,
      sleepMinutesLastNight: lastNight?.durationMinutes,
      sleepQualityLastNight: qual,
    );
  }

  Future<_DietSlice> _loadDietSlice(
    String userId,
    DateTime todayStart,
    DateTime sevenDaysAgo,
  ) async {
    final Map<String, DietSummary> weekly = await _dietRepo
        .getWeeklyNutrition(userId)
        .then((r) => r.fold((_) => <String, DietSummary>{}, (m) => m));

    double sumCal = 0, sumP = 0, sumC = 0, sumF = 0, sumW = 0;
    int n = 0;
    for (final DietSummary s in weekly.values) {
      sumCal += s.totalCalories;
      sumP += s.totalProtein;
      sumC += s.totalCarbs;
      sumF += s.totalFat;
      sumW += s.totalWater;
      n++;
    }

    final List<Meal> mealsToday = await _dietRepo
        .getMeals(userId, todayStart)
        .then((r) => r.fold((_) => <Meal>[], (List<Meal> l) => l));

    return _DietSlice(
      avgCalories7d: n > 0 ? sumCal / n : null,
      avgProtein7d: n > 0 ? sumP / n : null,
      avgCarbs7d: n > 0 ? sumC / n : null,
      avgFat7d: n > 0 ? sumF / n : null,
      avgWater7d: n > 0 ? sumW / n : null,
      mealsLoggedToday: mealsToday.isNotEmpty,
    );
  }

  Future<_WorkoutSlice> _loadWorkoutSlice(
    String userId,
    DateTime weekStart,
    DateTime now,
    DateTime todayStart,
  ) async {
    final List<WorkoutLog> logs = await _workoutRepo
        .getWorkoutLogs(userId, dateFrom: weekStart, dateTo: now)
        .then((r) => r.fold((_) => <WorkoutLog>[], (List<WorkoutLog> l) => l));

    final WorkoutPlan? plan = await _workoutRepo
        .getActiveWorkoutPlan(userId)
        .then((r) => r.fold((_) => null, (WorkoutPlan? p) => p));

    String? goal;
    String? level;
    bool? restToday;
    if (plan != null) {
      level = plan.fitnessLevel;
      if (plan.goals.isNotEmpty) {
        goal = plan.goals.first;
      }
      final int wd = now.weekday;
      final bool hasSessionToday = plan.sessions.any(
        (WorkoutSession s) => s.dayOfWeek == wd,
      );
      restToday = !hasSessionToday;
    }

    double calWeek = 0;
    final Set<String> types = <String>{};
    for (final WorkoutLog log in logs) {
      calWeek += log.totalCaloriesBurnt;
      final String name = log.sessionName.toLowerCase();
      if (name.contains('run') ||
          name.contains('jog') ||
          name.contains('walk') ||
          name.contains('cardio') ||
          name.contains('cycle')) {
        types.add('Cardio');
      } else {
        types.add('Strength');
      }
      for (final CompletedSet cs in log.completedSets) {
        final String en = cs.exerciseName.toLowerCase();
        if (en.contains('run') || en.contains('cycle') || en.contains('walk')) {
          types.add('Run');
        }
      }
    }

    return _WorkoutSlice(
      sessionsThisWeek: logs.length,
      caloriesThisWeek: calWeek > 0 ? calWeek : null,
      primaryGoal: goal,
      fitnessLevel: level,
      workoutTypes: types.toList(),
      hasRestDayToday: restToday,
    );
  }

  Future<_HealthSlice> _loadHealthSlice(String userId) async {
    final HealthSummary? summary = await _healthRepo
        .getHealthSummary(userId)
        .then((r) => r.fold((_) => null, (HealthSummary s) => s));
    if (summary == null) {
      return const _HealthSlice();
    }
    final UserProfile? profile = await _profileRepo
        .getProfile(userId)
        .then((r) => r.fold((_) => null, (UserProfile p) => p));
    final HealthSummary merged = mergeHealthSummaryWithProfileBodyMetrics(
      base: summary,
      userId: userId,
      profile: profile,
    );

    final List<OutOfRangeVital> oor = <OutOfRangeVital>[];
    for (final MapEntry<VitalType, VitalEntry?> e
        in merged.latestVitals.entries) {
      final VitalEntry? v = e.value;
      if (v == null) {
        continue;
      }
      if (v.type.isDerived && v.type != VitalType.bmi) {
        continue;
      }
      final RangeStatus st = VitalReferenceRanges.statusFor(v.type, v.value);
      if (st == RangeStatus.normal) {
        continue;
      }
      oor.add(
        OutOfRangeVital(
          vitalName: v.type.displayName,
          status: _statusLabel(st),
          recordedAt: v.recordedAt,
        ),
      );
    }

    final List<String> medNames = merged.activeMedications
        .map((m) => _sanitizeMedicationName(m.medicationName))
        .where((String s) => s.isNotEmpty)
        .toList();

    double? uric, ldl, fbs, avgGlu, vd, b12;
    uric = merged.latestVitals[VitalType.uricAcid]?.value;
    ldl = merged.latestVitals[VitalType.ldlCholesterol]?.value;
    fbs = merged.latestVitals[VitalType.fastingBloodSugar]?.value;
    avgGlu = merged.latestVitals[VitalType.avgBloodGlucose]?.value;
    vd = merged.latestVitals[VitalType.vitaminD]?.value;
    b12 = merged.latestVitals[VitalType.vitaminB12]?.value;

    return _HealthSlice(
      outOfRange: oor,
      medNames: medNames,
      uricAcid: uric,
      ldl: ldl,
      fbs: fbs,
      avgGlu: avgGlu,
      vitD: vd,
      b12: b12,
      bodyWeightKg: merged.latestVitals[VitalType.bodyWeight]?.value,
      heightCm: merged.latestVitals[VitalType.heightCm]?.value,
      bmi: merged.latestVitals[VitalType.bmi]?.value,
    );
  }

  Future<_MentalSlice> _loadMentalSlice(String userId, DateTime now) async {
    final MentalWellbeingSummary? summary = await _mentalRepo
        .getMentalWellbeingSummary(userId)
        .then((r) => r.fold((_) => null, (MentalWellbeingSummary s) => s));

    MoodLevel? todayMood;
    final List<MoodEntry> moods = (await _mentalRepo.getMoodHistory(
      userId,
      days: 3,
    )).fold((_) => <MoodEntry>[], (List<MoodEntry> l) => l);
    for (final MoodEntry e in moods) {
      if (_sameCalendarDay(e.recordedAt, now)) {
        todayMood = e.mood;
        break;
      }
    }

    MoodLevel? avgMood;
    final List<MoodEntry> week = summary?.weeklyMoods ?? moods;
    if (week.isNotEmpty) {
      final double avgIdx =
          week.map((MoodEntry e) => e.mood.index).reduce((a, b) => a + b) /
          week.length;
      avgMood = MoodLevel.values[avgIdx.round().clamp(0, 4)];
    }

    SurveySeverity? phq9s;
    SurveySeverity? gad7s;
    SurveyResult? phqRes = summary?.latestPhq9;
    phqRes ??= (await _mentalRepo.getLatestSurvey(
      userId,
      SurveyType.phq9,
    )).fold((_) => null, (SurveyResult? s) => s);
    if (phqRes != null &&
        now.difference(phqRes.completedAt) <= const Duration(days: 14)) {
      phq9s = phqRes.severity;
    }
    SurveyResult? gadRes = summary?.latestGad7;
    gadRes ??= (await _mentalRepo.getLatestSurvey(
      userId,
      SurveyType.gad7,
    )).fold((_) => null, (SurveyResult? s) => s);
    if (gadRes != null &&
        now.difference(gadRes.completedAt) <= const Duration(days: 14)) {
      gad7s = gadRes.severity;
    }

    return _MentalSlice(
      summary: summary,
      todayMood: todayMood,
      avgMood7d: avgMood,
      stress: summary?.currentStressScore,
      phq9Severity: phq9s,
      gad7Severity: gad7s,
    );
  }

  static String _statusLabel(RangeStatus s) {
    return switch (s) {
      RangeStatus.normal => 'Normal',
      RangeStatus.borderline => 'Borderline',
      RangeStatus.elevated => 'Elevated',
      RangeStatus.low => 'Low',
      RangeStatus.critical => 'Critical',
    };
  }

  static String _sanitizeMedicationName(String raw) {
    String s = AiInputSanitizer.sanitizeContextSnippet(raw, maxLength: 120);
    final int slash = s.indexOf('/');
    if (slash >= 0) {
      s = s.substring(0, slash).trim();
    }
    final int plus = s.indexOf('+');
    if (plus >= 0) {
      s = s.substring(0, plus).trim();
    }
    return s.trim();
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _mondayOfDate(DateTime d) {
    final int fromMon = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: fromMon));
  }
}

class _ActivitySlice {
  const _ActivitySlice({
    this.stepsYesterday,
    this.caloriesYesterday,
    this.activeMinutesYesterday,
    this.avgSteps7d,
    this.sleepMinutesLastNight,
    this.sleepQualityLastNight,
  });

  final int? stepsYesterday;
  final double? caloriesYesterday;
  final int? activeMinutesYesterday;
  final double? avgSteps7d;
  final int? sleepMinutesLastNight;
  final double? sleepQualityLastNight;
}

class _DietSlice {
  const _DietSlice({
    this.avgCalories7d,
    this.avgProtein7d,
    this.avgCarbs7d,
    this.avgFat7d,
    this.avgWater7d,
    this.mealsLoggedToday,
  });

  final double? avgCalories7d;
  final double? avgProtein7d;
  final double? avgCarbs7d;
  final double? avgFat7d;
  final double? avgWater7d;
  final bool? mealsLoggedToday;
}

class _WorkoutSlice {
  const _WorkoutSlice({
    this.sessionsThisWeek,
    this.caloriesThisWeek,
    this.primaryGoal,
    this.fitnessLevel,
    this.workoutTypes,
    this.hasRestDayToday,
  });

  final int? sessionsThisWeek;
  final double? caloriesThisWeek;
  final String? primaryGoal;
  final String? fitnessLevel;
  final List<String>? workoutTypes;
  final bool? hasRestDayToday;
}

class _HealthSlice {
  const _HealthSlice({
    this.outOfRange = const <OutOfRangeVital>[],
    this.medNames = const <String>[],
    this.uricAcid,
    this.ldl,
    this.fbs,
    this.avgGlu,
    this.vitD,
    this.b12,
    this.bodyWeightKg,
    this.heightCm,
    this.bmi,
  });

  final List<OutOfRangeVital> outOfRange;
  final List<String> medNames;
  final double? uricAcid;
  final double? ldl;
  final double? fbs;
  final double? avgGlu;
  final double? vitD;
  final double? b12;
  final double? bodyWeightKg;
  final double? heightCm;
  final double? bmi;
}

class _WearableSlice {
  const _WearableSlice({this.hrvMs, this.stepsToday});

  final double? hrvMs;
  final int? stepsToday;
}

class _MentalSlice {
  const _MentalSlice({
    this.summary,
    this.todayMood,
    this.avgMood7d,
    this.stress,
    this.phq9Severity,
    this.gad7Severity,
  });

  final MentalWellbeingSummary? summary;
  final MoodLevel? todayMood;
  final MoodLevel? avgMood7d;
  final StressScore? stress;
  final SurveySeverity? phq9Severity;
  final SurveySeverity? gad7Severity;
}

class _CommunitySlice {
  const _CommunitySlice({
    required this.joinedEventsCount,
    required this.activeChallengesCount,
    required this.activeTargets,
  });

  final int joinedEventsCount;
  final int activeChallengesCount;
  final List<String> activeTargets;
}
