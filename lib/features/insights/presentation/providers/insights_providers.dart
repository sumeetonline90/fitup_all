import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../activity/domain/entities/activity_stats.dart';
import '../../../activity/domain/entities/sleep_log.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../../diet/domain/entities/diet_summary.dart';
import '../../../diet/domain/entities/water_log.dart';
import '../../../diet/domain/repositories/diet_repository.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/repositories/workout_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/correlation_alert.dart';
import '../../domain/entities/daily_briefing.dart';
import '../../domain/entities/holistic_plan.dart';
import '../../domain/entities/holistic_context.dart';
import '../../domain/entities/goal_adjustment.dart';
import '../../domain/entities/weekly_report.dart';
import '../../domain/repositories/holistic_plan_repository.dart';
import '../../domain/services/holistic_context_builder.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../domain/services/weekly_report_pro_gate.dart';
import '../../../../services/ai_service.dart';

export 'insight_providers.dart';

FitupUser? _fitupUserFromAuth(AsyncValue<FitupUser?> auth) {
  return switch (auth) {
    AsyncData<FitupUser?>(:final value) => value,
    _ => null,
  };
}

/// Global [InsightRepository] from get_it.
final insightRepositoryProvider = Provider<InsightRepository>(
  (Ref ref) => getIt<InsightRepository>(),
);

/// Remote Config hook: set `remoteConfigAllowsAutoPro` when wired (ADR-016).
final weeklyReportProGateProvider = Provider<WeeklyReportProGate>(
  (Ref ref) => const WeeklyReportProGate(),
);

/// Daily morning briefing (cached per calendar day in repository).
final dailyBriefingProvider =
    AsyncNotifierProvider<DailyBriefingNotifier, DailyBriefing>(
      DailyBriefingNotifier.new,
    );

class DailyBriefingNotifier extends AsyncNotifier<DailyBriefing> {
  @override
  Future<DailyBriefing> build() async {
    final FitupUser? user = _fitupUserFromAuth(ref.watch(authStateProvider));
    if (user == null) {
      throw StateError('Not signed in');
    }
    final InsightRepository repo = ref.watch(insightRepositoryProvider);
    final result = await repo.getDailyBriefing(user.id);
    return result.fold(
      (Object f) => throw Exception(f.toString()),
      (DailyBriefing b) => b,
    );
  }

  Future<void> refreshBriefing() async {
    final FitupUser? user = _fitupUserFromAuth(ref.read(authStateProvider));
    if (user == null) {
      return;
    }
    state = const AsyncLoading<DailyBriefing>();
    state = await AsyncValue.guard(() async {
      final InsightRepository repo = ref.read(insightRepositoryProvider);
      final result = await repo.generateDailyBriefing(user.id);
      return result.fold(
        (Object f) => throw Exception(f.toString()),
        (DailyBriefing b) => b,
      );
    });
  }
}

/// Cross-module correlation alerts (rule engine); dismiss persists in-session.
final insightAlertsProvider =
    AsyncNotifierProvider<InsightAlertsNotifier, List<CorrelationAlert>>(
      InsightAlertsNotifier.new,
    );

/// Orchestration doc name for [insightAlertsProvider].
final AsyncNotifierProvider<InsightAlertsNotifier, List<CorrelationAlert>>
activeAlertsProvider = insightAlertsProvider;

class InsightAlertsNotifier extends AsyncNotifier<List<CorrelationAlert>> {
  @override
  Future<List<CorrelationAlert>> build() async {
    final FitupUser? user = _fitupUserFromAuth(ref.watch(authStateProvider));
    if (user == null) {
      return <CorrelationAlert>[];
    }
    final InsightRepository repo = ref.watch(insightRepositoryProvider);
    final result = await repo.getActiveAlerts(user.id);
    return result.fold(
      (_) => <CorrelationAlert>[],
      (List<CorrelationAlert> a) => a,
    );
  }

  Future<void> dismiss(String id) async {
    final FitupUser? user = _fitupUserFromAuth(ref.read(authStateProvider));
    if (user == null) {
      return;
    }
    await ref.read(insightRepositoryProvider).dismissAlert(user.id, id);
    final List<CorrelationAlert> current = state.value ?? <CorrelationAlert>[];
    state = AsyncData<List<CorrelationAlert>>(
      current.where((CorrelationAlert a) => a.id != id).toList(),
    );
  }
}

/// Current week holistic report (Pro); cached in repository.
final weeklyHolisticReportProvider =
    AsyncNotifierProvider<WeeklyHolisticReportNotifier, WeeklyReport>(
      WeeklyHolisticReportNotifier.new,
    );

/// Orchestration doc name for [weeklyHolisticReportProvider].
final AsyncNotifierProvider<WeeklyHolisticReportNotifier, WeeklyReport>
weeklyReportProvider = weeklyHolisticReportProvider;

class WeeklyHolisticReportNotifier extends AsyncNotifier<WeeklyReport> {
  @override
  Future<WeeklyReport> build() async {
    final FitupUser? user = _fitupUserFromAuth(ref.watch(authStateProvider));
    if (user == null) {
      throw StateError('Not signed in');
    }
    final InsightRepository repo = ref.watch(insightRepositoryProvider);
    final WeeklyReportProGate gate = ref.watch(weeklyReportProGateProvider);
    final DateTime now = DateTime.now();
    final result = await repo.getWeeklyReport(
      user.id,
      now,
      allowProIfStale: gate.shouldAllowAutoPro(now),
    );
    return result.fold(
      (Object f) => throw Exception(f.toString()),
      (WeeklyReport w) => w,
    );
  }

  /// Explicit user action — always allows Gemini Pro for the current week.
  Future<void> generateThisWeekReport() async {
    final FitupUser? user = _fitupUserFromAuth(ref.read(authStateProvider));
    if (user == null) {
      return;
    }
    state = const AsyncLoading<WeeklyReport>();
    state = await AsyncValue.guard(() async {
      final InsightRepository repo = ref.read(insightRepositoryProvider);
      final result = await repo.generateWeeklyReport(user.id);
      return result.fold(
        (Object f) => throw Exception(f.toString()),
        (WeeklyReport w) => w,
      );
    });
  }
}

/// Optional AI goal nudge (Flash).
final goalAdjustmentProvider = FutureProvider<GoalAdjustment?>((Ref ref) async {
  final FitupUser? user = _fitupUserFromAuth(ref.watch(authStateProvider));
  if (user == null) {
    return null;
  }

  final HolisticPlanRepository planRepo = getIt<HolisticPlanRepository>();
  final Either<Failure, HolisticPlan?> activeEither =
      await planRepo.getActivePlan(user.id);
  final HolisticPlan? activePlan = activeEither.fold(
    (Failure _) => null,
    (HolisticPlan? p) => p,
  );

  // No active plan yet → fall back to the legacy goal adjustment.
  if (activePlan == null) {
    final InsightRepository repo = ref.watch(insightRepositoryProvider);
    final Either<Failure, GoalAdjustment?> result =
        await repo.getLatestGoalAdjustment(user.id);
    return result.fold((_) => null, (GoalAdjustment? g) => g);
  }

  try {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);
    final DateTime end = start.add(const Duration(days: 1));
    final String dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final ActivityRepository activityRepo = getIt<ActivityRepository>();
    final DietRepository dietRepo = getIt<DietRepository>();
    final WorkoutRepository workoutRepo = getIt<WorkoutRepository>();
    final AiService ai = getIt<AiService>();

    final HolisticContext ctx =
        await getIt<HolisticContextBuilder>().buildFor(user.id);

    final Either<Failure, PlanDailyCheck?> existingEither =
        await planRepo.getDailyCheck(
      userId: user.id,
      holisticPlanId: activePlan.id,
      dateKey: dateKey,
    );
    final PlanDailyCheck? existing = existingEither.fold(
      (_) => null,
      (PlanDailyCheck? v) => v,
    );

    // If already on track, stay quiet.
    if (existing != null && existing.onTrack) {
      return null;
    }

    final int steps = await activityRepo.getStats(user.id, start, end).then(
      (Either<Failure, ActivityStats> r) =>
          r.fold((Failure _) => 0, (ActivityStats s) => s.totalSteps),
    );

    final double totalCalories = await dietRepo.getDailySummary(
      user.id,
      now,
    ).then(
      (Either<Failure, DietSummary> r) =>
          r.fold((Failure _) => 0, (DietSummary s) => s.totalCalories),
    );

    final List<WaterLog> waterLogs =
        await dietRepo.getWaterLogs(user.id, now).then(
              (Either<Failure, List<WaterLog>> r) => r.fold(
                (Failure _) => <WaterLog>[],
                (List<WaterLog> l) => l,
              ),
            );
    final double waterMl = waterLogs.fold<double>(
      0,
      (double p, WaterLog w) => p + w.amountMl,
    );

    final List<SleepLog> sleepLogs = await activityRepo.getSleepLogs(
      user.id,
      from: start,
      to: end,
    ).then(
      (Either<Failure, List<SleepLog>> r) => r.fold(
        (Failure _) => <SleepLog>[],
        (List<SleepLog> l) => l,
      ),
    );
    final int sleepMinutes =
        sleepLogs.fold<int>(0, (int p, SleepLog s) => p + s.durationMinutes);

    final List<WorkoutLog> workoutLogs = await workoutRepo.getWorkoutLogs(
      user.id,
      dateFrom: start,
      dateTo: end,
    ).then(
      (Either<Failure, List<WorkoutLog>> r) => r.fold(
        (Failure _) => <WorkoutLog>[],
        (List<WorkoutLog> l) => l,
      ),
    );
    final int workoutMinutes = workoutLogs.fold<int>(
      0,
      (int p, WorkoutLog l) =>
          p + l.endTime.difference(l.startTime).inMinutes,
    );

    final bool stepsCompleted = activePlan.dailyTargets.dailyStepGoal > 0 &&
        steps >= activePlan.dailyTargets.dailyStepGoal;
    final bool caloriesCompleted = activePlan.dailyTargets.dailyCalorieGoal > 0 &&
        totalCalories <=
            (activePlan.dailyTargets.dailyCalorieGoal * 1.05);
    final bool sleepCompleted =
        activePlan.dailyTargets.dailySleepGoalMinutes > 0 &&
            sleepMinutes >= activePlan.dailyTargets.dailySleepGoalMinutes;
    final bool waterCompleted = activePlan.dailyTargets.dailyWaterGoalMl > 0 &&
        waterMl >= activePlan.dailyTargets.dailyWaterGoalMl;
    final bool workoutCompleted =
        activePlan.dailyTargets.dailyWorkoutGoalMinutes > 0 &&
            workoutMinutes >= activePlan.dailyTargets.dailyWorkoutGoalMinutes;

    final String checkId = 'check_${activePlan.id}_$dateKey';
    final PlanDailyCheck computed = PlanDailyCheck(
      id: checkId,
      userId: user.id,
      holisticPlanId: activePlan.id,
      dateKey: dateKey,
      stepsCompleted: stepsCompleted,
      caloriesCompleted: caloriesCompleted,
      sleepCompleted: sleepCompleted,
      waterCompleted: waterCompleted,
      workoutCompleted: workoutCompleted,
      nudgeText: existing?.nudgeText ?? '',
      updatedAt: now,
    );

    final Either<Failure, ({String suggestion, String rationale})?>
        nudgeEither = await ai.suggestPlanNudge(
      ctx: ctx,
      plan: activePlan,
      check: computed,
    );

    final ({String suggestion, String rationale})? nudge = nudgeEither.fold(
      (_) => null,
      (v) => v,
    );

    final PlanDailyCheck toSave = PlanDailyCheck(
      id: computed.id,
      userId: computed.userId,
      holisticPlanId: computed.holisticPlanId,
      dateKey: computed.dateKey,
      stepsCompleted: computed.stepsCompleted,
      caloriesCompleted: computed.caloriesCompleted,
      sleepCompleted: computed.sleepCompleted,
      waterCompleted: computed.waterCompleted,
      workoutCompleted: computed.workoutCompleted,
      nudgeText: nudge?.suggestion ?? '',
      updatedAt: now,
    );
    await planRepo.upsertDailyCheck(userId: user.id, check: toSave);

    if (nudge == null) {
      return null;
    }

    return GoalAdjustment(
      id: 'plan-ga-$dateKey',
      userId: user.id,
      currentGoal: 'Holistic plan adherence',
      suggestion: nudge.suggestion,
      rationale: nudge.rationale,
      generatedAt: now,
    );
  } catch (_) {
    return null;
  }
});

/// Coach chat transcript (in-memory per app session).
final insightChatMessagesProvider = FutureProvider<List<ChatMessage>>((
  Ref ref,
) async {
  final FitupUser? user = _fitupUserFromAuth(ref.watch(authStateProvider));
  if (user == null) {
    return <ChatMessage>[];
  }
  final InsightRepository repo = ref.watch(insightRepositoryProvider);
  final result = await repo.getChatHistory(user.id);
  return result.fold((_) => <ChatMessage>[], (List<ChatMessage> m) => m);
});

/// True while the coach request is in flight.
final insightChatTypingProvider =
    NotifierProvider<InsightChatTypingNotifier, bool>(
      InsightChatTypingNotifier.new,
    );

class InsightChatTypingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Updates typing flag (only callable on the notifier, not via external `.state`).
  void setTyping(bool value) => state = value;
}

/// After user collapses the disclaimer, stays hidden (persisted).
final aiChatDisclaimerCollapsedProvider =
    AsyncNotifierProvider<AiChatDisclaimerNotifier, bool>(
      AiChatDisclaimerNotifier.new,
    );

class AiChatDisclaimerNotifier extends AsyncNotifier<bool> {
  static const String _prefsKey = 'fitup_ai_chat_disclaimer_collapsed';

  @override
  Future<bool> build() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    return p.getBool(_prefsKey) ?? false;
  }

  Future<void> collapse() async {
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKey, true);
    state = const AsyncData<bool>(true);
  }
}
