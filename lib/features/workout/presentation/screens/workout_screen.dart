import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dartz/dartz.dart' show Either, Left;
import 'package:intl/intl.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/module_top_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';
import '../../../../features/insights/presentation/providers/holistic_plan_ui_providers.dart';
import '../../../../features/insights/presentation/utils/holistic_plan_ui_actions.dart';
import '../../../../features/insights/presentation/utils/plan_summary_formatter.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_providers.dart';
import '../widgets/daily_calorie_burn_ring.dart';
import '../widgets/muscle_heatmap.dart';
import '../widgets/video_workout_feed.dart';
import '../widgets/workout_ai_insight_sheet.dart';

/// Workout hub: daily calorie ring, plan, video feed, heatmap, recent logs.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  static const List<String> _dow = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  DateTime _holisticPlanStartDate = DateTime.now();
  bool _planActionBusy = false;
  int _workoutPresetIdx = 1; // 0=Easy, 1=Balanced, 2=Push
  int _availabilityIdx = 1; // 0=Low, 1=Medium, 2=High

  WorkoutSession? _sessionForToday(WorkoutPlan plan) {
    final int wd = DateTime.now().weekday;
    for (final WorkoutSession s in plan.sessions) {
      if (s.dayOfWeek == wd) {
        return s;
      }
    }
    return plan.sessions.isNotEmpty ? plan.sessions.first : null;
  }

  List<bool> _weekFromLogs(List<WorkoutLog> logs) {
    final DateTime now = DateTime.now();
    final DateTime monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final Set<int> done = <int>{};
    for (final WorkoutLog l in logs) {
      final DateTime d =
          DateTime(l.startTime.year, l.startTime.month, l.startTime.day);
      if (!d.isBefore(monday)) {
        done.add(d.weekday - 1);
      }
    }
    return List<bool>.generate(7, (int i) => done.contains(i));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<WorkoutPlan?> planAsync =
        ref.watch(activeWorkoutPlanProvider);
    final AsyncValue<WorkoutSummary> summaryAsync =
        ref.watch(workoutSummaryProvider);
    final AsyncValue<Map<MuscleGroup, int>> heatAsync =
        ref.watch(muscleGroupFrequencyProvider);
    final AsyncValue<List<WorkoutLog>> recentAsync =
        ref.watch(recentWorkoutsProvider);
    final AsyncValue<double> todayCal =
        ref.watch(todayCaloriesBurntProvider);
    final AsyncValue<UserProfile> profileAsync =
        ref.watch(userProfileProvider);
    final AsyncValue<HolisticPlan?> holisticAsync =
        ref.watch(activeHolisticPlanProvider);

    final DateTime today = DateTime.now();
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final DateTime monday = todayDate.subtract(
      Duration(days: todayDate.weekday - 1),
    );
    final AsyncValue<List<WorkoutLog>> weekLogsAsync = ref.watch(
      workoutLogsProvider(WorkoutLogRange(from: monday, to: todayDate)),
    );

    final bool loading = planAsync.isLoading ||
        summaryAsync.isLoading ||
        heatAsync.isLoading ||
        recentAsync.isLoading ||
        weekLogsAsync.isLoading;

    if (loading) {
      return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: true,
          bottom: false,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ModuleTopHeader(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    const ShimmerLoading(height: 100, borderRadius: 16),
                    const SizedBox(height: 12),
                    const ShimmerLoading(height: 88, borderRadius: 16),
                    const SizedBox(height: 12),
                    const ShimmerLoading(height: 200, borderRadius: 16),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (summaryAsync.hasError || heatAsync.hasError) {
      return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: true,
          bottom: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.cloud_off_outlined,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load workouts',
                      style: AppTextStyles.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Retry loading workouts',
                      child: NeonButton(
                        label: 'Retry',
                        icon: Icons.refresh,
                        onPressed: () {
                          ref.invalidate(workoutSummaryProvider);
                          ref.invalidate(muscleGroupFrequencyProvider);
                          ref.invalidate(recentWorkoutsProvider);
                          ref.invalidate(activeWorkoutPlanProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final WorkoutPlan? plan = planAsync.maybeWhen(
      data: (WorkoutPlan? p) => p,
      orElse: () => null,
    );
    final WorkoutSummary stats = summaryAsync.requireValue;
    final Map<MuscleGroup, int> heat = heatAsync.requireValue;
    final List<WorkoutLog> recent = recentAsync.maybeWhen(
      data: (List<WorkoutLog> l) => l,
      orElse: () => <WorkoutLog>[],
    );
    final List<WorkoutLog> weekLogs = weekLogsAsync.maybeWhen(
      data: (List<WorkoutLog> l) => l,
      orElse: () => <WorkoutLog>[],
    );
    final WorkoutSession? todaySession =
        plan != null ? _sessionForToday(plan) : null;
    final int targetSessions = plan?.daysPerWeek ?? 4;
    final List<bool> weekDone = _weekFromLogs(weekLogs);
    final int todayIdx = todayDate.weekday - 1;

    final double todayBurned = todayCal.maybeWhen(
      data: (double v) => v,
      orElse: () => 0.0,
    );
    final int calorieTarget = profileAsync.maybeWhen(
      data: (UserProfile p) => p.dailyCalorieGoal ?? 500,
      orElse: () => 500,
    );
    final int workoutDailyGoalMinutes = profileAsync.maybeWhen(
      data: (UserProfile p) => p.dailyWorkoutGoalMinutes ?? 30,
      orElse: () => 30,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Semantics(
        label: 'Log custom workout',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/workout/log-custom'),
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.background,
          icon: const Icon(Icons.add),
          label: Text('Log workout', style: AppTextStyles.labelSmall),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: <Widget>[
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: <Widget>[
                    const ModuleTopHeader(),
                    const SizedBox(height: 8),
                    NeonOutlineButton(
                      label: 'Burn AI',
                      onPressed: () {
                        ref.invalidate(
                          workoutInsightProvider(const <String>[]),
                        );
                        showWorkoutAiInsightSheet(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'History',
                          icon: const Icon(Icons.history),
                          onPressed: () => context.push('/workout/history'),
                        ),
                        Semantics(
                          label: 'Streak ${stats.currentStreak} days',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    AppColors.tertiary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('🔥', style: AppTextStyles.bodySmall),
                                const SizedBox(width: 4),
                                Text(
                                  '${stats.currentStreak} days',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  holisticAsync.when(
                    loading: () => GlassCard(
                      glowColor: AppColors.secondary,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),
                    error: (Object _, StackTrace __) => GlassCard(
                      glowColor: AppColors.error,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('AI Plan unavailable'),
                      ),
                    ),
                    data: (HolisticPlan? activePlan) {
                      final List<double> mult = <double>[0.9, 1.0, 1.15];
                      final int chosenMinutes = (workoutDailyGoalMinutes * mult[_workoutPresetIdx])
                          .round()
                          .clamp(5, 180);

                      return GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        glowColor: AppColors.primaryContainer,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.auto_awesome, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'AI Plan',
                                        style: AppTextStyles.headlineMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activePlan == null
                                            ? 'Generate a plan for daily workout minutes.'
                                            : 'Active: ${DateFormat.yMd().format(activePlan.startDate)} → ${DateFormat.yMd().format(activePlan.endDate)}',
                                        style: AppTextStyles.bodySmall,
                                        maxLines: 2,
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (activePlan == null) ...<Widget>[
                              OutlinedButton(
                                onPressed: () async {
                                  if (_planActionBusy) {
                                    return;
                                  }
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: _holisticPlanStartDate,
                                          firstDate: DateTime.now().subtract(
                                            const Duration(days: 365),
                                          ),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                        );
                                        if (picked == null) return;
                                        setState(() {
                                          _holisticPlanStartDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                          );
                                        });
                                      },
                                child: Text(
                                  'Start: ${DateFormat.yMd().format(_holisticPlanStartDate)}',
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),
                              Text(
                                'Choose availability',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ChoiceChip(
                                    label: const Text('Low'),
                                    selected: _availabilityIdx == 0,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 0,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Medium'),
                                    selected: _availabilityIdx == 1,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 1,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('High'),
                                    selected: _availabilityIdx == 2,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Choose intensity (targets)',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ChoiceChip(
                                    label: const Text('Easy'),
                                    selected: _workoutPresetIdx == 0,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 0,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Balanced'),
                                    selected: _workoutPresetIdx == 1,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 1,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Push'),
                                    selected: _workoutPresetIdx == 2,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              NeonOutlineButton(
                                label: _planActionBusy
                                    ? 'Please wait…'
                                    : 'Create holistic plan on Home',
                                onPressed: () {
                                  if (_planActionBusy) return;
                                  context.push('/home');
                                },
                              ),
                            ] else ...<Widget>[
                              Text(
                                'Workout plan summary',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              ...modulePlanChecklist(
                                plan: activePlan,
                                moduleKey: PlanModuleKey.workout,
                              ).map(
                                (String line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $line',
                                    style: AppTextStyles.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Choose availability',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ChoiceChip(
                                    label: const Text('Low'),
                                    selected: _availabilityIdx == 0,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 0,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Medium'),
                                    selected: _availabilityIdx == 1,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 1,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('High'),
                                    selected: _availabilityIdx == 2,
                                    onSelected: (_) => setState(
                                      () => _availabilityIdx = 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Choose daily workout minutes',
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  ChoiceChip(
                                    label: const Text('Easy'),
                                    selected: _workoutPresetIdx == 0,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 0,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Balanced'),
                                    selected: _workoutPresetIdx == 1,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 1,
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('Push'),
                                    selected: _workoutPresetIdx == 2,
                                    onSelected: (_) => setState(
                                      () => _workoutPresetIdx = 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Daily target: $chosenMinutes min',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              NeonOutlineButton(
                                label: _planActionBusy
                                    ? 'Updating…'
                                    : 'Amend workout plan',
                                onPressed: () async {
                                  if (_planActionBusy) return;
                                        final FitupUser? user = ref
                                            .read(authStateProvider)
                                            .value;
                                        if (user == null) return;
                                        setState(() => _planActionBusy = true);

                                        final String availabilityText =
                                            switch (_availabilityIdx) {
                                          0 => 'Low',
                                          1 => 'Medium',
                                          2 => 'High',
                                          _ => 'Medium',
                                        };
                                        final String intensityText =
                                            switch (_workoutPresetIdx) {
                                          0 => 'Easy',
                                          1 => 'Balanced',
                                          2 => 'Push',
                                          _ => 'Balanced',
                                        };

                                        final int currentWorkoutTarget =
                                            activePlan.dailyTargets
                                                .dailyWorkoutGoalMinutes;
                                        final double targetRatio =
                                            currentWorkoutTarget > 0
                                                ? chosenMinutes /
                                                    currentWorkoutTarget
                                                : 1.0;
                                        final bool majorChange =
                                            targetRatio >= 1.3 ||
                                                targetRatio <= 0.7;

                                        final String amendment =
                                            'Availability: $availabilityText. Intensity: $intensityText. '
                                            'Set dailyWorkoutGoalMinutes to $chosenMinutes minutes/day. '
                                            'Prefer consistent workouts and gradual progression.';

                                        Either<Failure, HolisticPlan> res;
                                        if (!majorChange) {
                                          res =
                                              await amendActivePlanModuleAndSyncProfile(
                                            user: user,
                                            activePlan: activePlan,
                                            moduleKey: PlanModuleKey.workout,
                                            moduleAmendment: amendment,
                                          );
                                        } else {
                                          final bool? changeDates =
                                              await showDialog<bool>(
                                            context: context,
                                            builder:
                                                (BuildContext dialogContext) {
                                              return AlertDialog(
                                                title: const Text(
                                                  'Change plan dates too?',
                                                ),
                                                content: const Text(
                                                  'Your new target is a significant shift. You can keep the same dates or regenerate the plan with a new duration based on your availability/intensity.',
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(false),
                                                    child: const Text(
                                                      'Keep dates',
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(true),
                                                    child: const Text(
                                                      'Change dates',
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          if (changeDates == true) {
                                            final int durationDays =
                                                computeHolisticPlanDurationDays(
                                              availabilityIdx: _availabilityIdx,
                                              intensityIdx: _workoutPresetIdx,
                                              targetRatio: targetRatio,
                                            );
                                            final Either<Failure, HolisticPlan>
                                                genRes =
                                                await generateHolisticPlanAndSyncProfile(
                                              user: user,
                                              startDate: activePlan.startDate,
                                              durationDays: durationDays,
                                            );

                                            res = await genRes.fold<
                                                Future<Either<Failure, HolisticPlan>>>(
                                              (Failure f) async => Left(f),
                                              (HolisticPlan generatedPlan) async {
                                                return await amendActivePlanModuleAndSyncProfile(
                                                  user: user,
                                                  activePlan: generatedPlan,
                                                  moduleKey: PlanModuleKey.workout,
                                                  moduleAmendment: amendment,
                                                );
                                              },
                                            );
                                          } else {
                                            res =
                                                await amendActivePlanModuleAndSyncProfile(
                                              user: user,
                                              activePlan: activePlan,
                                              moduleKey: PlanModuleKey.workout,
                                              moduleAmendment: amendment,
                                            );
                                          }
                                        }
                                        if (!context.mounted) return;
                                        setState(() => _planActionBusy = false);

                                        res.fold(
                                          (Failure f) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  f.message ??
                                                      'Plan update failed',
                                                ),
                                              ),
                                            );
                                          },
                                          (_) {
                                            ref.invalidate(
                                              activeHolisticPlanProvider,
                                            );
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text('Workout plan updated'),
                                              ),
                                            );
                                          },
                                        );
                                      },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // 1. Daily calorie burn ring
                  DailyCalorieBurnRing(
                    burned: todayBurned,
                    target: calorieTarget,
                  ),
                  const SizedBox(height: 16),

                  // 2. Active plan block (compact)
                  if (plan != null)
                    GlassCard(
                      glowColor: AppColors.primaryContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  plan.name,
                                  style: AppTextStyles.headlineMedium
                                      .copyWith(fontSize: 18),
                                ),
                              ),
                              if (plan.isAIGenerated)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('This week',
                              style: AppTextStyles.bodySmall),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children:
                                List<Widget>.generate(7, (int i) {
                              final bool done =
                                  i < weekDone.length ? weekDone[i] : false;
                              final bool isToday = i == todayIdx;
                              return Semantics(
                                label:
                                    'Day ${_dow[i]} ${done ? 'completed' : 'not completed'}${isToday ? ', today' : ''}',
                                child: Column(
                                  children: <Widget>[
                                    Text(_dow[i],
                                        style: AppTextStyles.bodySmall),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isToday
                                              ? AppColors.secondary
                                              : AppColors.outlineVariant,
                                          width: isToday ? 2 : 1,
                                        ),
                                        color: done
                                            ? AppColors.primaryContainer
                                                .withValues(alpha: 0.35)
                                            : AppColors
                                                .surfaceContainerHigh,
                                      ),
                                      child: done
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppColors
                                                  .primaryContainer,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (todaySession != null)
                            Semantics(
                              button: true,
                              label: "Start today's session",
                              child: NeonButton(
                                label: "Start today's session",
                                icon: Icons.play_arrow,
                                onPressed: () => context.push(
                                  '/workout/session/${todaySession.id}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 3. Mini stats row
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Sessions',
                          value:
                              '${stats.thisWeekSessions} / $targetSessions',
                          semantic:
                              'Sessions completed ${stats.thisWeekSessions} of $targetSessions',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Total min',
                          value: '${stats.totalMinutes}',
                          semantic:
                              'Total workout minutes logged ${stats.totalMinutes}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          label: 'Total kcal',
                          value: '${stats.totalCalories.round()}',
                          semantic:
                              'Total calories from workouts ${stats.totalCalories.round()}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Video workout feed (goal-based)
                  const VideoWorkoutFeed(),
                  const SizedBox(height: 16),

                  // 5. Muscle heatmap
                  GlassCard(
                    child: MuscleHeatmap(muscleGroupFrequency: heat),
                  ),
                  const SizedBox(height: 8),

                  // 6. Recent workouts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Recent workouts',
                          style: AppTextStyles.labelSmall),
                      Semantics(
                        button: true,
                        label: 'Open exercise library',
                        child: TextButton(
                          onPressed: () =>
                              context.push('/workout/exercises'),
                          child: Text(
                            'Library',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty)
                    Text(
                      'No workouts yet. Watch a video and log your first workout!',
                      style: AppTextStyles.bodyMedium,
                    )
                  else
                    ...recent.map(
                      (WorkoutLog w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RecentWorkoutTile(log: w),
                      ),
                    ),
                  const SizedBox(height: 12),

                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.semantic,
  });

  final String label;
  final String value;
  final String semantic;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantic,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Text(value,
                style:
                    AppTextStyles.headlineMedium.copyWith(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _RecentWorkoutTile extends StatefulWidget {
  const _RecentWorkoutTile({required this.log});

  final WorkoutLog log;

  @override
  State<_RecentWorkoutTile> createState() => _RecentWorkoutTileState();
}

class _RecentWorkoutTileState extends State<_RecentWorkoutTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final WorkoutLog w = widget.log;
    final String dateStr = DateFormat.MMMd().format(w.startTime);
    final int min = w.endTime.difference(w.startTime).inMinutes;
    return Semantics(
      button: true,
      label: '${w.sessionName} on $dateStr',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _open = !_open),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      w.sessionName,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
              Text(
                '$dateStr · $min min · ${w.totalCaloriesBurnt.round()} kcal',
                style: AppTextStyles.bodySmall,
              ),
              if (_open) ...<Widget>[
                const SizedBox(height: 8),
                ...w.completedSets.map(
                  (CompletedSet s) => Text(
                    '• ${s.exerciseName} set ${s.setNumber}',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
