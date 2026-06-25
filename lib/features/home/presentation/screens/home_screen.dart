import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/module_top_header.dart';
import '../../../activity/domain/entities/activity.dart';
import '../../../activity/domain/entities/activity_stats.dart';
import '../../../activity/domain/utils/activity_step_aggregation.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../community/presentation/providers/community_providers.dart';
import '../../../fitcoins/domain/entities/fitcoin_wallet.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../diet/domain/entities/diet_summary.dart';
import '../../../diet/domain/entities/meal.dart';
import '../../../diet/presentation/providers/diet_providers.dart';
import '../../../health/presentation/health_ui_models.dart';
import '../../../health/presentation/providers/health_providers.dart';
import '../../../mental_wellbeing/domain/entities/mood_level.dart';
import '../../../mental_wellbeing/presentation/providers/mental_wellbeing_providers.dart';
import '../../../insights/domain/entities/correlation_alert.dart';
import '../../../insights/domain/entities/holistic_plan.dart';
import '../../../insights/presentation/providers/insights_providers.dart';
import '../../../insights/presentation/providers/holistic_plan_ui_providers.dart';
import '../../../insights/presentation/utils/holistic_plan_ui_actions.dart';
import '../../../insights/presentation/utils/plan_summary_formatter.dart';
import '../../../insights/presentation/widgets/daily_briefing_card.dart';
import '../../../workout/domain/entities/workout.dart';
import '../../../workout/domain/utils/workout_stats_utils.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../widgets/module_card.dart';
import '../../../../core/database/health_sync_metadata_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/providers/permission_providers.dart';
import '../../../activity/data/datasources/activity_local_datasource.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../../../services/health_connect_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/permission_service.dart';

/// Stitch dashboard — mock metrics until modules connect to Firestore.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _lastAutoDashboardRefreshAt;
  bool _permissionFlowStarted = false;
  bool _showAiInsights = false;
  bool _planBusy = false;
  int _availabilityIdx = 1; // 0=Low, 1=Medium, 2=High
  int _intensityIdx = 1; // 0=Easy, 1=Balanced, 2=Push
  DateTime _holisticPlanStartDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Trigger permission requests after the first frame so the activity is
    // fully attached and the Health Connect launcher is registered.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeRequestPermissions(),
    );
    // If auth is already resolved (e.g. returning to Home), refresh dashboard
    // without requiring pull-to-refresh (listener below skips same user id).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final String? uid = ref
          .read(authStateProvider)
          .maybeWhen(data: (FitupUser? u) => u?.id, orElse: () => null);
      if (uid != null) {
        unawaited(_onRefresh(isUserPull: false));
      }
    });
  }

  /// Requests missing permissions one-by-one using native system dialogs.
  /// Only runs once per HomeScreen lifetime.
  Future<void> _maybeRequestPermissions() async {
    if (_permissionFlowStarted || !mounted) return;
    _permissionFlowStarted = true;

    final permService = ref.read(permissionServiceProvider);
    final AppPermissionState state = await permService.getPermissionState();
    LoggerService.i(
      'HomeScreen._maybeRequestPermissions '
      'location=${state.locationGranted} '
      'health=${state.healthGranted} '
      'notification=${state.notificationGranted}',
    );

    if (!state.locationGranted) {
      LoggerService.i('HomeScreen: requesting location');
      await permService.requestLocation();
    }

    if (!mounted) return;

    if (!state.healthGranted) {
      await _waitUntilResumed();
      if (!mounted) return;

      // Show a rationale dialog before opening the native Health Connect UI
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text('Health Connect', style: AppTextStyles.headlineMedium),
          content: Text(
            'Fitup needs access to Google Health Connect to track your steps, sleep, and workouts.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Not Now',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Continue',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      if (proceed == true && mounted) {
        // Wait for the Activity to fully re-attach after the dialog closes
        await Future<void>.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        LoggerService.i('HomeScreen: requesting health permissions');
        final bool granted = await permService.requestHealthPermissions();

        // Check if granted, and if so, trigger an immediate sync
        if (granted && mounted) {
          LoggerService.i(
            'HomeScreen: Health permissions granted, syncing data...',
          );
          await _onRefresh(isUserPull: true);
        }
      }
    }

    if (!mounted) return;

    if (!state.notificationGranted) {
      LoggerService.i('HomeScreen: requesting notifications');
      await permService.requestNotifications();
    }

    // Refresh the provider so UI reflects updated state.
    if (mounted) {
      ref.invalidate(permissionStateProvider);
    }
  }

  /// Health Connect permission UI requires a resumed foreground activity.
  Future<void> _waitUntilResumed() async {
    final WidgetsBinding binding = WidgetsBinding.instance;
    AppLifecycleState? state = binding.lifecycleState;
    int retries = 0;
    while (mounted && state != AppLifecycleState.resumed && retries < 20) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      state = binding.lifecycleState;
      retries++;
    }
    LoggerService.i(
      'HomeScreen._waitUntilResumed lifecycle=$state retries=$retries',
    );
  }

  /// Re-sync Health Connect data then invalidate dashboard providers.
  ///
  /// [isUserPull] is false for launch / auth-driven refreshes; those are
  /// debounced briefly so auth resolution does not run the pipeline twice.
  Future<void> _onRefresh({bool isUserPull = false}) async {
    final DateTime now = DateTime.now();
    if (!isUserPull) {
      if (_lastAutoDashboardRefreshAt != null &&
          now.difference(_lastAutoDashboardRefreshAt!) <
              const Duration(milliseconds: 900)) {
        return;
      }
      _lastAutoDashboardRefreshAt = now;
    }
    LoggerService.i('HomeScreen._onRefresh started');
    try {
      final authState = ref.read(authStateProvider);
      final String? uid = authState.maybeWhen(
        data: (u) => u?.id,
        orElse: () => null,
      );
      if (uid != null) {
        await getIt<HealthConnectService>().syncHistoricalSteps(
          userId: uid,
          localDs: getIt<ActivityLocalDataSource>(),
          fitcoinService: getIt<FitcoinAwardService>(),
          metadataDao: getIt<HealthSyncMetadataDao>(),
          activityRepository: getIt<ActivityRepository>(),
          force: true,
        );
      }
    } catch (e, st) {
      LoggerService.e('HomeScreen._onRefresh syncHistoricalSteps', e, st);
    }

    if (!mounted) return;

    // Invalidate every provider that feeds the dashboard cards.
    ref
      ..invalidate(weeklyStatsProvider)
      ..invalidate(dailySummaryProvider)
      ..invalidate(workoutSummaryProvider)
      ..invalidate(workoutLogsProvider(const WorkoutLogRange()))
      ..invalidate(todayCaloriesBurntProvider)
      ..invalidate(activeWorkoutPlanProvider)
      ..invalidate(activeHolisticPlanProvider)
      ..invalidate(recentWorkoutsProvider)
      ..invalidate(healthSummaryProvider)
      ..invalidate(currentStressScoreProvider)
      ..invalidate(dailyMoodProvider)
      ..invalidate(userProfileProvider)
      ..invalidate(insightAlertsProvider)
      ..invalidate(permissionStateProvider);

    LoggerService.i('HomeScreen._onRefresh done');
  }

  Future<String?> _collectHolisticPlanInput(BuildContext context) async {
    final Map<String, bool> includeModules = <String, bool>{
      'activity': true,
      'diet': true,
      'workout': true,
      'health': true,
      'mental': true,
      'community': false,
    };

    bool confirmedModules = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setDialog) {
                return AlertDialog(
                  title: const Text('Step 1/3: Include modules'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: includeModules.entries
                          .map(
                            (MapEntry<String, bool> e) => CheckboxListTile(
                              value: e.value,
                              onChanged: (bool? v) => setDialog(() {
                                includeModules[e.key] = v ?? false;
                              }),
                              title: Text(e.key.toUpperCase()),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        confirmedModules = true;
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Next'),
                    ),
                  ],
                );
              },
        );
      },
    );
    if (!confirmedModules) {
      return null;
    }

    String weightTarget = '';
    String fitnessTarget = '';
    String mentalTarget = '';
    String healthVitalTarget = '';
    String activityGoal = '';
    String dietGoal = '';
    String workoutGoal = '';
    String communityGoal = '';
    final List<String> selectedPriorityTargets = <String>[];
    const List<String> priorityTargetOptions = <String>[
      'Weight loss',
      'Stamina build-up',
      'Better sleep',
      'Improve recovery',
      'Increase daily activity',
      'Improve diet quality',
      'Stress reduction',
    ];

    bool confirmedTargets = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext _, void Function(void Function()) setDialogState) {
            return AlertDialog(
              title: const Text('Step 2/3: Optional targets'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        onChanged: (String value) => weightTarget = value,
                        decoration: const InputDecoration(
                          labelText: 'Target weight (optional)',
                        ),
                      ),
                      TextFormField(
                        onChanged: (String value) => fitnessTarget = value,
                        decoration: const InputDecoration(
                          labelText: 'Target fitness outcome (optional)',
                        ),
                      ),
                      TextFormField(
                        onChanged: (String value) => mentalTarget = value,
                        decoration: const InputDecoration(
                          labelText: 'Mental wellbeing target (optional)',
                        ),
                      ),
                      TextFormField(
                        onChanged: (String value) => healthVitalTarget = value,
                        decoration: const InputDecoration(
                          labelText: 'Vitals to normalize (optional)',
                        ),
                      ),
                      if (includeModules['activity'] == true)
                        TextFormField(
                          onChanged: (String value) => activityGoal = value,
                          decoration: const InputDecoration(
                            labelText:
                                'Activity focus (stamina/endurance/etc) (optional)',
                          ),
                        ),
                      if (includeModules['diet'] == true)
                        TextFormField(
                          onChanged: (String value) => dietGoal = value,
                          decoration: const InputDecoration(
                            labelText: 'Diet focus (optional)',
                          ),
                        ),
                      if (includeModules['workout'] == true)
                        TextFormField(
                          onChanged: (String value) => workoutGoal = value,
                          decoration: const InputDecoration(
                            labelText: 'Workout focus (optional)',
                          ),
                        ),
                      if (includeModules['community'] == true)
                        TextFormField(
                          onChanged: (String value) => communityGoal = value,
                          decoration: const InputDecoration(
                            labelText: 'Community/events focus (optional)',
                          ),
                        ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select your priority targets',
                          style: AppTextStyles.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: priorityTargetOptions
                            .map(
                              (String target) => FilterChip(
                                label: Text(target),
                                selected: selectedPriorityTargets.contains(
                                  target,
                                ),
                                onSelected: (bool selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      if (!selectedPriorityTargets.contains(
                                        target,
                                      )) {
                                        selectedPriorityTargets.add(target);
                                      }
                                    } else {
                                      selectedPriorityTargets.remove(target);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    confirmedTargets = true;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!confirmedTargets) {
      return null;
    }

    final List<String> included = includeModules.entries
        .where((MapEntry<String, bool> e) => e.value)
        .map((MapEntry<String, bool> e) => e.key)
        .toList();
    final List<String> excluded = includeModules.entries
        .where((MapEntry<String, bool> e) => !e.value)
        .map((MapEntry<String, bool> e) => e.key)
        .toList();

    final String summary =
        'Included modules: ${included.join(", ")}. '
        'Excluded modules: ${excluded.join(", ")}. '
        'Target weight: ${weightTarget.trim()}. '
        'Fitness target: ${fitnessTarget.trim()}. '
        'Mental target: ${mentalTarget.trim()}. '
        'Vital normalization target: ${healthVitalTarget.trim()}. '
        'Activity focus: ${activityGoal.trim()}. '
        'Diet focus: ${dietGoal.trim()}. '
        'Workout focus: ${workoutGoal.trim()}. '
        'Community focus: ${communityGoal.trim()}. '
        'Priority targets: ${selectedPriorityTargets.join(", ")}.';
    return summary;
  }

  void _showOverallPlanSheet(BuildContext context, HolisticPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerHigh,
      builder: (BuildContext sheetContext) {
        final List<String> moduleLines = <String>[
          ...plan.modulePlans.entries.map((entry) {
            final String label = entry.key.name.toUpperCase();
            final List<String> summaryLines = modulePlanChecklist(
              plan: plan,
              moduleKey: entry.key,
            );
            return '$label: ${summaryLines.join(' | ')}';
          }),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Overall Holistic Plan',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${DateFormat.yMd().format(plan.startDate)} → ${DateFormat.yMd().format(plan.endDate)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Text('Major goals', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 6),
                  ...(plan.majorGoals.isEmpty
                      ? <Widget>[
                          Text(
                            'No major goals yet',
                            style: AppTextStyles.bodySmall,
                          ),
                        ]
                      : plan.majorGoals
                            .map(
                              (g) =>
                                  Text('• $g', style: AppTextStyles.bodySmall),
                            )
                            .toList()),
                  const SizedBox(height: 14),
                  Text('Daily targets', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Steps: ${plan.dailyTargets.dailyStepGoal}  |  Calories: ${plan.dailyTargets.dailyCalorieGoal}\n'
                    'Sleep: ${plan.dailyTargets.dailySleepGoalMinutes} min  |  Water: ${plan.dailyTargets.dailyWaterGoalMl} ml\n'
                    'Workout: ${plan.dailyTargets.dailyWorkoutGoalMinutes} min',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Text('Module summaries', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 6),
                  ...moduleLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $line', style: AppTextStyles.bodySmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<FitupUser?>>(authStateProvider, (
      AsyncValue<FitupUser?>? prev,
      AsyncValue<FitupUser?> next,
    ) {
      final FitupUser? nextUser = next.maybeWhen(
        data: (FitupUser? u) => u,
        orElse: () => null,
      );
      if (nextUser == null) {
        return;
      }
      final FitupUser? prevUser = prev?.maybeWhen(
        data: (FitupUser? u) => u,
        orElse: () => null,
      );
      if (prevUser?.id == nextUser.id) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(_onRefresh(isUserPull: false));
      });
    });

    final AsyncValue<ActivityStats> weekly = ref.watch(weeklyStatsProvider);
    final AsyncValue<DietSummary> dietSummary = ref.watch(dailySummaryProvider);
    final AsyncValue<List<WorkoutLog>> workoutLogsHome = ref.watch(
      workoutLogsProvider(const WorkoutLogRange()),
    );
    final AsyncValue<WorkoutPlan?> workoutPlan = ref.watch(
      activeWorkoutPlanProvider,
    );
    final AsyncValue<double> todayWorkoutCalories = ref.watch(
      todayCaloriesBurntProvider,
    );
    final int dailyBurnTarget = ref
        .watch(userProfileProvider)
        .maybeWhen(
          data: (UserProfile profile) => profile.dailyCalorieGoal ?? 500,
          orElse: () => 500,
        );
    final AsyncValue<HealthSummaryUi> healthAsync = ref.watch(
      healthSummaryProvider,
    );
    final AsyncValue<int> stress = ref.watch(currentStressScoreProvider);
    final MoodLogUi? moodToday = ref.watch(dailyMoodProvider);
    final AsyncValue<HolisticPlan?> holisticPlanAsync = ref.watch(
      activeHolisticPlanProvider,
    );

    String activityPrimary = '—';
    String activitySecondary = 'Daily goal —';
    double? activityProgress;
    weekly.when(
      data: (ActivityStats stats) {
        final ({int steps, double calories}) t = _todayFromStats(stats);
        const int goal = 8000;
        activityPrimary =
            '${_fmtSteps(t.steps)} steps · ${t.calories.round()} kcal';
        final int pct = goal > 0
            ? (t.steps / goal * 100).clamp(0, 100).round()
            : 0;
        activitySecondary = 'Daily goal $pct%';
        activityProgress = (t.steps / goal).clamp(0.0, 1.0);
      },
      loading: () {
        activityPrimary = '…';
        activitySecondary = 'Loading activity…';
        activityProgress = null;
      },
      error: (Object _, StackTrace __) {
        activityPrimary = 'Activity unavailable';
        activitySecondary = 'Open Activity tab to retry';
        activityProgress = null;
      },
    );

    String dietPrimary = '—';
    String dietSecondary = '—';
    double? dietRingProgress;
    dietSummary.when(
      data: (DietSummary s) {
        dietPrimary =
            '${s.totalCalories.round()} / ${s.targetCalories.round()} cal';
        dietSecondary =
            '${_fmtWaterL(s.totalWater)} · ${_lastMealLine(s.meals)}';
        final double tgt = s.targetCalories;
        if (tgt > 0) {
          dietRingProgress = (s.totalCalories / tgt).clamp(0.0, 1.0);
        }
      },
      loading: () {
        dietPrimary = '…';
        dietSecondary = 'Loading diet…';
        dietRingProgress = null;
      },
      error: (Object _, StackTrace __) {
        dietPrimary = 'Diet unavailable';
        dietSecondary = 'Open Diet tab to retry';
        dietRingProgress = null;
      },
    );

    String workoutPrimary = '…';
    String workoutSecondary = '—';
    double? workoutRingProgress;
    workoutLogsHome.when(
      data: (List<WorkoutLog> logs) {
        final DateTime now = DateTime.now();
        final int week = WorkoutStatsUtils.weekSessionCountSinceMonday(
          logs,
          now,
        );
        final int streak = WorkoutStatsUtils.currentStreakDays(logs, now);
        final int weeklyTgt = workoutPlan.maybeWhen(
          data: (WorkoutPlan? p) => p?.daysPerWeek ?? 4,
          orElse: () => 4,
        );
        final double todayKcal = todayWorkoutCalories.maybeWhen(
          data: (double kcal) => kcal,
          orElse: () => 0,
        );
        workoutPrimary = '${todayKcal.round()} / $dailyBurnTarget kcal';
        if (dailyBurnTarget > 0) {
          workoutRingProgress = (todayKcal / dailyBurnTarget).clamp(0.0, 1.0);
        }

        final String todayLine = todayWorkoutCalories.when(
          data: (double kcal) => 'Today: ${kcal.round()} kcal',
          loading: () => 'Today: … kcal',
          error: (Object _, StackTrace __) => 'Today: — kcal',
        );
        final List<WorkoutLog> sorted = List<WorkoutLog>.of(logs)
          ..sort(
            (WorkoutLog a, WorkoutLog b) => b.startTime.compareTo(a.startTime),
          );
        if (sorted.isNotEmpty) {
          final WorkoutLog w = sorted.first;
          workoutSecondary =
              'Week $week/$weeklyTgt · Last: ${w.sessionName} · '
              '${DateFormat.MMMd().format(w.startTime)} · '
              '$todayLine · ${streak}d streak';
        } else {
          workoutSecondary =
              'Week $week/$weeklyTgt · $todayLine · Streak $streak days';
        }
      },
      loading: () {
        workoutPrimary = '…';
        workoutSecondary = 'Loading workout…';
        workoutRingProgress = null;
      },
      error: (Object _, StackTrace __) {
        workoutPrimary = 'Workout unavailable';
        workoutSecondary = 'Open Workout tab to retry';
        workoutRingProgress = null;
      },
    );
    String healthPrimary = '—';
    String healthSecondary = '—';
    healthPrimary = healthAsync.maybeWhen(
      data: (HealthSummaryUi s) =>
          '${s.needAttentionCount} vitals need attention',
      orElse: () => '—',
    );
    final String stressLine = stress.maybeWhen(
      data: (int s) => 'Stress: ${_stressHomeLabel(s)}',
      orElse: () => 'Stress: —',
    );
    final String moodLine = moodToday == null
        ? 'No mood logged today'
        : 'Mood ${_moodEmojiHome(moodToday)}';
    healthSecondary = healthAsync.maybeWhen(
      data: (HealthSummaryUi s) =>
          '${s.vitalsLoggedCount} logged · ${s.needAttentionCount} attention',
      orElse: () => 'Vitals summary unavailable',
    );
    final String mentalPrimary = moodLine;
    final String mentalSecondary = stressLine;

    final AsyncValue<FitcoinWallet> fitcoinWallet = ref.watch(
      fitcoinWalletStreamProvider,
    );
    final SubscriptionTier tier =
        ref.watch(subscriptionTierProvider).value ?? SubscriptionTier.free;
    final NumberFormat fcFmt = NumberFormat('#,###');
    String fitcoinPrimary = '…';
    String fitcoinSecondary = 'Loading…';
    fitcoinWallet.when(
      data: (FitcoinWallet w) {
        fitcoinPrimary = '${fcFmt.format(w.balance)} FC';
        fitcoinSecondary = w.earnedThisWeek > 0
            ? '+${fcFmt.format(w.earnedThisWeek)} FC this week'
            : 'Earn in Community';
      },
      loading: () {
        fitcoinPrimary = '…';
        fitcoinSecondary = 'Loading…';
      },
      error: (Object _, StackTrace __) {
        fitcoinPrimary = '—';
        fitcoinSecondary = 'Open Community to retry';
      },
    );

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _onRefresh(isUserPull: true),
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Column(
                    children: <Widget>[
                      if (tier == SubscriptionTier.pro)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: AppColors.secondaryToPrimaryGradient,
                            ),
                            child: Text(
                              'PRO',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.background,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ModuleTopHeader(
                        actions: <Widget>[
                          IconButton(
                            onPressed: () => context.push('/profile'),
                            icon: const Icon(Icons.person_outline),
                            color: AppColors.onSurfaceVariant,
                            tooltip: 'Profile',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: Builder(
                  builder: (BuildContext context) {
                    final double w = MediaQuery.of(context).size.width;
                    final int cols = w >= 1024 ? 3 : (w >= 768 ? 2 : 1);
                    final double aspect = cols == 1 ? 1.35 : (cols == 2 ? 1.25 : 1.15);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: aspect,
                      ),
                  delegate: SliverChildListDelegate(<Widget>[
                    ModuleCard(
                      title: 'Activity',
                      icon: Icons.fitness_center,
                      primaryMetric: activityPrimary,
                      secondaryMetric: activitySecondary,
                      accentColor: AppColors.secondary,
                      progress: activityProgress,
                      ringProgress: activityProgress,
                      onTap: () => context.push('/activity'),
                    ),
                    ModuleCard(
                      title: 'Diet & Fuel',
                      icon: Icons.restaurant,
                      primaryMetric: dietPrimary,
                      secondaryMetric: dietSecondary,
                      accentColor: AppColors.primaryContainer,
                      ringProgress: dietRingProgress,
                      onTap: () => context.push('/diet'),
                    ),
                    ModuleCard(
                      title: 'Workout',
                      icon: Icons.sports_gymnastics,
                      primaryMetric: workoutPrimary,
                      secondaryMetric: workoutSecondary,
                      accentColor: AppColors.tertiary,
                      ringProgress: workoutRingProgress,
                      onTap: () => context.push('/workout'),
                    ),
                    ModuleCard(
                      title: 'Health & Vitals',
                      icon: Icons.monitor_heart,
                      primaryMetric: healthPrimary,
                      secondaryMetric: healthSecondary,
                      accentColor: AppColors.secondary,
                      onTap: () => context.push('/health'),
                    ),
                    ModuleCard(
                      title: 'Mental Wellbeing',
                      icon: Icons.self_improvement_outlined,
                      primaryMetric: mentalPrimary,
                      secondaryMetric: mentalSecondary,
                      accentColor: AppColors.tertiary,
                      onTap: () => context.push('/mental'),
                    ),
                    ModuleCard(
                      title: 'Fitcoins',
                      icon: Icons.stars_rounded,
                      primaryMetric: fitcoinPrimary,
                      secondaryMetric: fitcoinSecondary,
                      accentColor: AppColors.primaryContainer,
                      onTap: () => context.push('/community'),
                    ),
                  ]),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Holistic Plan',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: holisticPlanAsync.when(
                          loading: () => const SizedBox(
                            height: 22,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => Text(
                            'Holistic plan unavailable',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          data: (HolisticPlan? plan) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  plan == null
                                      ? 'Create a holistic plan to unlock daily targets'
                                      : 'Active: ${DateFormat.yMd().format(plan.startDate)} → ${DateFormat.yMd().format(plan.endDate)}',
                                  style: AppTextStyles.bodyLarge,
                                ),
                                if (plan != null) ...<Widget>[
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showOverallPlanSheet(context, plan),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                      ),
                                      label: const Text('View overall plan'),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: _planBusy
                                            ? null
                                            : () async {
                                                final DateTime?
                                                picked = await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      _holisticPlanStartDate,
                                                  firstDate: DateTime.now()
                                                      .subtract(
                                                        const Duration(
                                                          days: 365,
                                                        ),
                                                      ),
                                                  lastDate: DateTime.now().add(
                                                    const Duration(days: 365),
                                                  ),
                                                );
                                                if (picked == null) return;
                                                setState(() {
                                                  _holisticPlanStartDate =
                                                      picked;
                                                });
                                              },
                                        child: Text(
                                          'Start: ${DateFormat.yMd().format(_holisticPlanStartDate)}',
                                          style: AppTextStyles.labelLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Choose availability',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    ChoiceChip(
                                      label: const Text('Low'),
                                      selected: _availabilityIdx == 0,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _availabilityIdx = 0,
                                            ),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Medium'),
                                      selected: _availabilityIdx == 1,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _availabilityIdx = 1,
                                            ),
                                    ),
                                    ChoiceChip(
                                      label: const Text('High'),
                                      selected: _availabilityIdx == 2,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _availabilityIdx = 2,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Choose intensity',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    ChoiceChip(
                                      label: const Text('Easy'),
                                      selected: _intensityIdx == 0,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _intensityIdx = 0,
                                            ),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Balanced'),
                                      selected: _intensityIdx == 1,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _intensityIdx = 1,
                                            ),
                                    ),
                                    ChoiceChip(
                                      label: const Text('Push'),
                                      selected: _intensityIdx == 2,
                                      onSelected: _planBusy
                                          ? null
                                          : (_) => setState(
                                              () => _intensityIdx = 2,
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.auto_awesome),
                                    onPressed: _planBusy
                                        ? null
                                        : () async {
                                            final user = ref
                                                .read(authStateProvider)
                                                .value;
                                            if (user == null) return;
                                            setState(() {
                                              _planBusy = true;
                                            });

                                            final int durationDays =
                                                computeHolisticPlanDurationDays(
                                                  availabilityIdx:
                                                      _availabilityIdx,
                                                  intensityIdx: _intensityIdx,
                                                  targetRatio: 1.0,
                                                );
                                            final String? userPlanInput =
                                                await _collectHolisticPlanInput(
                                                  context,
                                                );
                                            if (userPlanInput == null) {
                                              if (!context.mounted) return;
                                              setState(() {
                                                _planBusy = false;
                                              });
                                              return;
                                            }

                                            final res =
                                                await generateHolisticPlanAndSyncProfile(
                                                  user: user,
                                                  startDate:
                                                      _holisticPlanStartDate,
                                                  durationDays: durationDays,
                                                  userPlanInput: userPlanInput,
                                                );

                                            if (!context.mounted) return;
                                            setState(() {
                                              _planBusy = false;
                                            });

                                            await res.fold(
                                              (f) async {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      f.message ??
                                                          'Holistic plan generation failed',
                                                    ),
                                                  ),
                                                );
                                              },
                                              (_) async {
                                                ref.invalidate(
                                                  activeHolisticPlanProvider,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Holistic plan updated',
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                    label: Text(
                                      plan == null
                                          ? 'Create holistic plan'
                                          : 'Regenerate holistic plan',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'This plan cascades into module targets.',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'AI Insights',
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_showAiInsights) ...<Widget>[
                        DailyBriefingCard(
                          compact: true,
                          onTapSeeAll: () => context.push('/insights'),
                        ),
                        const SizedBox(height: 12),
                        Consumer(
                          builder:
                              (BuildContext context, WidgetRef ref, Widget? _) {
                                final AsyncValue<List<CorrelationAlert>>
                                alerts = ref.watch(insightAlertsProvider);
                                return alerts.when(
                                  data: (List<CorrelationAlert> list) {
                                    if (list.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: InkWell(
                                        onTap: () => context.push('/insights'),
                                        borderRadius: BorderRadius.circular(16),
                                        child: GlassCard(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              const Icon(
                                                Icons.hub_outlined,
                                                color: AppColors.secondary,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  '${list.length} Cross-Module Insights',
                                                  style:
                                                      AppTextStyles.bodyLarge,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.chevron_right,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                        ),
                      ] else ...<Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAiInsights = true;
                              });
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Generate Daily Briefing'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary.withValues(
                                alpha: 0.22,
                              ),
                              foregroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/insights/chat'),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Chat with AI Coach'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.22,
                            ),
                            foregroundColor: AppColors.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }
}

String _fmtWaterL(double totalMl) {
  if (totalMl <= 0) {
    return 'Water 0 L';
  }
  final double l = totalMl / 1000;
  return 'Water ${l.toStringAsFixed(1)} L';
}

String _lastMealLine(List<Meal> meals) {
  if (meals.isEmpty) {
    return 'No meals logged today';
  }
  final Meal last = meals.reduce(
    (Meal a, Meal b) => a.dateTime.isAfter(b.dateTime) ? a : b,
  );
  final String hm =
      '${last.dateTime.hour.toString().padLeft(2, '0')}:'
      '${last.dateTime.minute.toString().padLeft(2, '0')}';
  return 'Last meal $hm · ${last.totalCalories.round()} kcal';
}

String _stressHomeLabel(int s) {
  if (s < 25) {
    return 'Low';
  }
  if (s < 50) {
    return 'Moderate';
  }
  if (s < 75) {
    return 'High';
  }
  return 'Critical';
}

String _moodEmojiHome(MoodLogUi m) {
  return switch (m.level) {
    MoodLevel.veryBad => '😫',
    MoodLevel.bad => '😕',
    MoodLevel.neutral => '😐',
    MoodLevel.good => '🙂',
    MoodLevel.veryGood => '😄',
  };
}

String _fmtSteps(int n) {
  return n.toString();
}

({int steps, double calories}) _todayFromStats(ActivityStats stats) {
  final DateTime today = DateTime.now();
  final DateTime d0 = DateTime(today.year, today.month, today.day);
  final Map<DateTime, int> stepsByDay = stepsByDayNoDoubleCount(
    stats.recentActivities,
  );
  final int steps = stepsByDay[d0] ?? 0;
  double calories = 0;
  for (final Activity a in stats.recentActivities) {
    final DateTime ad = DateTime(
      a.startTime.year,
      a.startTime.month,
      a.startTime.day,
    );
    if (ad == d0) {
      calories += a.caloriesBurnt;
    }
  }
  return (steps: steps, calories: calories);
}
