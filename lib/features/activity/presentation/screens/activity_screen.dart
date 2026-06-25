import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart' show Either, Left;

import '../../../../core/database/health_sync_metadata_dao.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../services/health_connect_service.dart';
import '../../../../services/logger_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';
import '../../../../features/insights/presentation/providers/holistic_plan_ui_providers.dart';
import '../../../../features/insights/presentation/utils/holistic_plan_ui_actions.dart';
import '../../../../features/insights/presentation/utils/plan_summary_formatter.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/activity_local_datasource.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../../../services/models/ai_insight.dart';
import '../../../../shared/widgets/ai_insight_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/module_top_header.dart';
import '../../domain/entities/activity.dart';
import '../../domain/entities/sleep_log.dart';
import '../../domain/utils/activity_step_aggregation.dart';
import '../providers/activity_providers.dart';

/// Activity dashboard — Stitch `activity_dashboard` wired to providers.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

enum _GraphPeriod { week, month }

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  static const int _dailyStepGoal = 8000;
  _GraphPeriod _period = _GraphPeriod.week;
  DateTime _anchor = DateTime.now();

  DateTime _holisticPlanStartDate = DateTime.now();
  bool _planActionBusy = false;
  int _activityPresetIdx = 1; // 0=Easy, 1=Balanced, 2=Push
  int _availabilityIdx = 1; // 0=Low, 1=Medium, 2=High

  Future<void> _onRefresh() async {
    LoggerService.i('ActivityScreen._onRefresh started');
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
      LoggerService.e('ActivityScreen._onRefresh syncHistoricalSteps', e, st);
    }
    if (!mounted) return;
    ref
      ..invalidate(todayActivitiesProvider)
      ..invalidate(recentTrackedActivitiesProvider)
      ..invalidate(activityRangeProvider(_periodRange(_anchor, _period)))
      ..invalidate(
        sleepRangeProvider((
          from: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ).subtract(const Duration(days: 6)),
          to: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ).add(const Duration(days: 1)),
        )),
      );
    LoggerService.i('ActivityScreen._onRefresh done');
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Activity>> todayAsync = ref.watch(
      todayActivitiesProvider,
    );
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));
    final ({DateTime from, DateTime to}) range = _periodRange(_anchor, _period);
    final AsyncValue<List<Activity>> rangeAsync = ref.watch(
      activityRangeProvider(range),
    );
    final DateTime sleepStart = todayStart.subtract(const Duration(days: 6));
    final AsyncValue<List<SleepLog>> sleepAsync = ref.watch(
      sleepRangeProvider((from: sleepStart, to: tomorrowStart)),
    );
    final int goal =
        ref.watch(userProfileProvider).value?.dailyStepGoal ?? _dailyStepGoal;
    final AsyncValue<List<Activity>> recentAsync = ref.watch(
      recentTrackedActivitiesProvider,
    );
    final AsyncValue<HolisticPlan?> holisticAsync = ref.watch(
      activeHolisticPlanProvider,
    );

    if (todayAsync.isLoading || sleepAsync.isLoading) {
      return const ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ShimmerLoading(height: 24),
                SizedBox(height: 16),
                ShimmerLoading(height: 120),
                SizedBox(height: 16),
                ShimmerLoading(height: 160),
                SizedBox(height: 16),
                ShimmerLoading(height: 140),
                SizedBox(height: 16),
                ShimmerLoading(height: 200),
              ],
            ),
          ),
        ),
      );
    }

    if (todayAsync.hasError || rangeAsync.hasError || sleepAsync.hasError) {
      return ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: true,
          bottom: false,
          child: ErrorState(
            message: 'Could not load activity data.',
            onRetry: () {
              ref.invalidate(todayActivitiesProvider);
              ref.invalidate(recentTrackedActivitiesProvider);
              ref.invalidate(activityRangeProvider(range));
              ref.invalidate(
                sleepRangeProvider((from: sleepStart, to: tomorrowStart)),
              );
            },
          ),
        ),
      );
    }

    final List<Activity> today = todayAsync.value ?? const <Activity>[];
    final List<Activity> periodActivities =
        rangeAsync.value ?? const <Activity>[];
    final List<SleepLog> sleepLogs = sleepAsync.value ?? const <SleepLog>[];
    final _PeriodSeries periodSeries = _seriesFor(
      periodActivities,
      _period,
      _anchor,
    );

    final int steps = _sumStepsToday(today);
    final double distKm = _sumDistanceTodayKm(today);
    final int cal = _sumCaloriesToday(today).round();
    final String dateChip = DateFormat('EEE, MMM d').format(now);

    final List<Activity> sortedToday = List<Activity>.from(today)
      ..removeWhere(_isPassiveActivity)
      ..sort((Activity a, Activity b) => b.startTime.compareTo(a.startTime));
    final List<Activity> recentActivities = recentAsync.maybeWhen(
      data: (List<Activity> list) => list,
      orElse: () => sortedToday.take(5).toList(),
    );
    final List<double> sleep7Days = _sleepMinutes7Days(sleepLogs, now);

    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: <Widget>[
            RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: ModuleTopHeader(
                        actions: <Widget>[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                dateChip,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: NeonOutlineButton(
                        label: 'Move AI',
                        onPressed: () => _openActivityInsight(context, ref),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: _StatGlassCard(
                              child: _StepsArc(steps: steps, goal: goal),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatGlassCard(
                              child: _DistanceBlock(km: distKm),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatGlassCard(
                              child: _CaloriesBlock(kcal: cal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (!kIsWeb) ...<Widget>[
                            NeonButton(
                              label: 'Start Activity',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () => context.push('/activity/start'),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Run • Walk • Cycle • Swim',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall,
                            ),
                          ] else ...<Widget>[
                            GlassCard(
                              glowColor: AppColors.secondary,
                              child: Row(
                                children: <Widget>[
                                  const Icon(
                                    Icons.phone_android_rounded,
                                    color: AppColors.secondary,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Available on Mobile',
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                color: AppColors.secondary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'GPS activity tracking is available on the Fitup mobile app. Your mobile data syncs here automatically.',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: holisticAsync.when(
                          loading: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'AI Plan',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              const SizedBox(
                                height: 22,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ],
                          ),
                          error: (Object _, StackTrace __) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'AI Plan unavailable',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Manual logging still works.',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          data: (HolisticPlan? activePlan) {
                            final List<double> mult = <double>[0.9, 1.0, 1.15];
                            final int chosenSteps =
                                (goal * mult[_activityPresetIdx]).round().clamp(
                                  1500,
                                  40000,
                                );

                            return Column(
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
                                                ? 'Generate a plan to get daily targets.'
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
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            if (_planActionBusy) {
                                              return;
                                            }
                                            final DateTime? picked =
                                                await showDatePicker(
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
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose intensity',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      ChoiceChip(
                                        label: const Text('Easy'),
                                        selected: _activityPresetIdx == 0,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 0,
                                        ),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Balanced'),
                                        selected: _activityPresetIdx == 1,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 1,
                                        ),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Push'),
                                        selected: _activityPresetIdx == 2,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 2,
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
                                  const SizedBox(height: 2),
                                  Text(
                                    'Activity plan summary',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  ...modulePlanChecklist(
                                    plan: activePlan,
                                    moduleKey: PlanModuleKey.activity,
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
                                        selected: _activityPresetIdx == 0,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 0,
                                        ),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Balanced'),
                                        selected: _activityPresetIdx == 1,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 1,
                                        ),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Push'),
                                        selected: _activityPresetIdx == 2,
                                        onSelected: (_) => setState(
                                          () => _activityPresetIdx = 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Daily step target: $chosenSteps',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  NeonOutlineButton(
                                    label: _planActionBusy
                                        ? 'Updating…'
                                        : 'Amend activity plan',
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
                                          switch (_activityPresetIdx) {
                                            0 => 'Easy',
                                            1 => 'Balanced',
                                            2 => 'Push',
                                            _ => 'Balanced',
                                          };

                                      final int currentStepsTarget =
                                          activePlan.dailyTargets.dailyStepGoal;
                                      final double targetRatio =
                                          currentStepsTarget > 0
                                          ? chosenSteps / currentStepsTarget
                                          : 1.0;
                                      final bool majorChange =
                                          targetRatio >= 1.3 ||
                                          targetRatio <= 0.7;

                                      final String amendment =
                                          'Availability: $availabilityText. Intensity: $intensityText. '
                                          'Set dailyStepGoal to $chosenSteps steps/day. '
                                          'Prefer consistency-focused walking and gradual progression.';

                                      Either<Failure, HolisticPlan> res;
                                      if (!majorChange) {
                                        res =
                                            await amendActivePlanModuleAndSyncProfile(
                                              user: user,
                                              activePlan: activePlan,
                                              moduleKey: PlanModuleKey.activity,
                                              moduleAmendment: amendment,
                                            );
                                      } else {
                                        final bool?
                                        changeDates = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Change plan dates too?',
                                              ),
                                              content: const Text(
                                                'Your new target is a significant shift. You can keep the same dates or regenerate the plan with a new duration based on your availability/intensity.',
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    dialogContext,
                                                  ).pop(false),
                                                  child: const Text(
                                                    'Keep dates',
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(
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
                                                availabilityIdx:
                                                    _availabilityIdx,
                                                intensityIdx:
                                                    _activityPresetIdx,
                                                targetRatio: targetRatio,
                                              );

                                          final Either<Failure, HolisticPlan>
                                          genRes =
                                              await generateHolisticPlanAndSyncProfile(
                                                user: user,
                                                startDate: activePlan.startDate,
                                                durationDays: durationDays,
                                              );

                                          res = await genRes
                                              .fold<
                                                Future<
                                                  Either<Failure, HolisticPlan>
                                                >
                                              >((Failure f) async => Left(f), (
                                                HolisticPlan generatedPlan,
                                              ) async {
                                                return await amendActivePlanModuleAndSyncProfile(
                                                  user: user,
                                                  activePlan: generatedPlan,
                                                  moduleKey:
                                                      PlanModuleKey.activity,
                                                  moduleAmendment: amendment,
                                                );
                                              });
                                        } else {
                                          res =
                                              await amendActivePlanModuleAndSyncProfile(
                                                user: user,
                                                activePlan: activePlan,
                                                moduleKey:
                                                    PlanModuleKey.activity,
                                                moduleAmendment: amendment,
                                              );
                                        }
                                      }
                                      if (!context.mounted) return;
                                      setState(() => _planActionBusy = false);
                                      res.fold(
                                        (Failure f) =>
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  f.message ??
                                                      'Plan update failed',
                                                ),
                                              ),
                                            ),
                                        (_) {
                                          ref.invalidate(
                                            activeHolisticPlanProvider,
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Activity plan updated',
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  _period == _GraphPeriod.week
                                      ? 'This Week'
                                      : 'This Month',
                                  style: AppTextStyles.headlineMedium,
                                ),
                                if (rangeAsync.isLoading) ...<Widget>[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                _PeriodToggle(
                                  period: _period,
                                  onChanged: (_GraphPeriod p) {
                                    setState(() {
                                      _period = p;
                                      _anchor = DateTime.now();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _RangeNav(
                              label: _periodLabel(_period, _anchor),
                              onPrev: () => setState(
                                () => _anchor = _period == _GraphPeriod.week
                                    ? _anchor.subtract(const Duration(days: 7))
                                    : DateTime(
                                        _anchor.year,
                                        _anchor.month - 1,
                                        1,
                                      ),
                              ),
                              onNext: _canGoNext(_period, _anchor, now)
                                  ? () => setState(
                                      () =>
                                          _anchor = _period == _GraphPeriod.week
                                          ? _anchor.add(const Duration(days: 7))
                                          : DateTime(
                                              _anchor.year,
                                              _anchor.month + 1,
                                              1,
                                            ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: _StepsBars(
                                values: periodSeries.values,
                                labels: periodSeries.labels,
                                goalValue: _period == _GraphPeriod.week
                                    ? goal.toDouble()
                                    : (goal *
                                              DateUtils.getDaysInMonth(
                                                _anchor.year,
                                                _anchor.month,
                                              ))
                                          .toDouble(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                _SummaryChip(
                                  label: 'Steps',
                                  value: _formatKSteps(
                                    periodActivities.fold<double>(
                                      0,
                                      (double acc, Activity a) =>
                                          acc +
                                          (a.steps ??
                                              _estimatedStepsFromDistance(
                                                a.distanceMeters,
                                              )),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _SummaryChip(
                                  label: 'Distance',
                                  value:
                                      '${(periodActivities.fold<double>(0, (double acc, Activity a) => acc + a.distanceMeters) / 1000).toStringAsFixed(1)} km',
                                ),
                                const SizedBox(width: 8),
                                _SummaryChip(
                                  label: 'Active days',
                                  value: '${_activeDays(periodActivities)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Recent Activities',
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (recentAsync.isLoading && recentActivities.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: ShimmerLoading(height: 72),
                      ),
                    )
                  else if (recentActivities.isEmpty)
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 150,
                        child: EmptyState(
                          message: 'No activities yet',
                          icon: Icons.directions_run_outlined,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        final Activity a = recentActivities[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              ref
                                  .read(selectedActivityDetailProvider.notifier)
                                  .select(a);
                              context.push('/activity/session', extra: a);
                            },
                            child: GlassCard(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: <Widget>[
                                  _TypeIcon(type: a.type),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          a.type.label,
                                          style: AppTextStyles.headlineMedium
                                              .copyWith(fontSize: 17),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(a.distanceMeters / 1000).toStringAsFixed(1)} km'
                                          ' • ${_formatDurationShort(a.durationSeconds)}'
                                          ' • ${_formatActivityDate(a.startTime)}',
                                          style: AppTextStyles.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: recentActivities.length),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text('Sleep', style: AppTextStyles.headlineMedium),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: GlassCard(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Last 7 Days',
                              style: AppTextStyles.labelSmall,
                            ),
                            if (kIsWeb) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                'Sleep sync from Health Connect / HealthKit is '
                                'available on mobile. Open the app on your phone '
                                'to sync.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: _SleepBars(values: sleep7Days),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Avg sleep',
                                  style: AppTextStyles.bodySmall,
                                ),
                                Text(
                                  '${(sleep7Days.reduce((double a, double b) => a + b) / 7 / 60).toStringAsFixed(1)} h',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                      child: OutlinedButton(
                        onPressed: () async {
                          await context.push('/activity/sleep');
                          if (!mounted) {
                            return;
                          }
                          ref.invalidate(
                            sleepRangeProvider((
                              from: sleepStart,
                              to: tomorrowStart,
                            )),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Log Sleep',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openActivityInsight(BuildContext context, WidgetRef ref) {
  ref.invalidate(activityInsightProvider(null));
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) => Consumer(
      builder: (BuildContext context, WidgetRef ref, _) {
        final AsyncValue<AiInsight> async = ref.watch(
          activityInsightProvider(null),
        );
        return async.when(
          loading: () =>
              const AiInsightSheet(module: 'activity', insight: null),
          data: (AiInsight insight) =>
              AiInsightSheet(module: 'activity', insight: insight),
          error: (Object e, StackTrace _) {
            Future<void>.delayed(Duration.zero, () {
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not load insight right now. Please try again.',
                    ),
                  ),
                );
              }
            });
            return const SizedBox.shrink();
          },
        );
      },
    ),
  );
}

int _estimatedStepsFromDistance(double meters) => (meters / 0.78).round();

int _sumStepsToday(List<Activity> list) {
  final DateTime today = DateTime.now();
  final DateTime d0 = DateTime(today.year, today.month, today.day);
  final Map<DateTime, int> byDay = stepsByDayNoDoubleCount(list);
  return byDay[d0] ?? 0;
}

double _sumDistanceTodayKm(List<Activity> list) {
  final DateTime today = DateTime.now();
  final DateTime d0 = DateTime(today.year, today.month, today.day);
  double meters = 0;
  for (final Activity a in list) {
    final DateTime ad = DateTime(
      a.startTime.year,
      a.startTime.month,
      a.startTime.day,
    );
    if (ad == d0) {
      meters += a.distanceMeters;
    }
  }
  return meters / 1000;
}

double _sumCaloriesToday(List<Activity> list) {
  final DateTime today = DateTime.now();
  final DateTime d0 = DateTime(today.year, today.month, today.day);
  double total = 0;
  for (final Activity a in list) {
    final DateTime ad = DateTime(
      a.startTime.year,
      a.startTime.month,
      a.startTime.day,
    );
    if (ad == d0) {
      total += a.caloriesBurnt;
    }
  }
  return total;
}

String _formatKSteps(double n) {
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}k';
  }
  return n.round().toString();
}

String _formatActivityDate(DateTime t) {
  final DateTime now = DateTime.now();
  final DateTime d = DateTime(t.year, t.month, t.day);
  final DateTime nd = DateTime(now.year, now.month, now.day);
  if (d == nd) {
    return 'Today';
  }
  final DateTime yest = nd.subtract(const Duration(days: 1));
  if (d == yest) {
    return 'Yesterday';
  }
  return '${t.month}/${t.day}';
}

String _formatDurationShort(int seconds) {
  final int m = seconds ~/ 60;
  final int h = m ~/ 60;
  if (h > 0) {
    return '${h}h ${m % 60}m';
  }
  if (m > 0) {
    return '$m min';
  }
  return '${seconds}s';
}

class _StatGlassCard extends StatelessWidget {
  const _StatGlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: SizedBox(height: 136, child: Center(child: child)),
    );
  }
}

class _StepsArc extends StatelessWidget {
  const _StepsArc({required this.steps, required this.goal});

  final int steps;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final double p = (steps / goal).clamp(0.0, 1.0);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 66,
          width: 66,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(66, 66),
                painter: _ArcPainter(
                  progress: p,
                  trackColor: AppColors.surfaceContainerHighest,
                  progressColor: AppColors.secondary,
                ),
              ),
              const Icon(
                Icons.directions_walk,
                color: AppColors.secondary,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatNumber(steps),
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(
          '/ ${_formatNumber(goal)} goal',
          style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'STEPS',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    final String s = n.toString();
    final StringBuffer buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int fromEnd = s.length - i;
      if (i > 0 && fromEnd % 3 == 0) {
        buf.write(',');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.width / 2 - 4;
    const double stroke = 6;
    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final Paint prog = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const double start = -3.14159 * 0.85;
    const double sweep = 3.14159 * 1.7;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep * progress,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DistanceBlock extends StatelessWidget {
  const _DistanceBlock({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Icon(Icons.map_outlined, color: AppColors.secondary, size: 28),
        const SizedBox(height: 6),
        Text(
          '${km.toStringAsFixed(1)} km',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 18,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'DISTANCE',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _CaloriesBlock extends StatelessWidget {
  const _CaloriesBlock({required this.kcal});

  final int kcal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppColors.tertiary,
          size: 28,
        ),
        const SizedBox(height: 6),
        Text(
          '$kcal kcal',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: 18,
            color: AppColors.tertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'CALORIES',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 9,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StepsBars extends StatelessWidget {
  const _StepsBars({
    required this.values,
    required this.labels,
    required this.goalValue,
  });

  final List<double> values;
  final List<String> labels;
  final double goalValue;

  @override
  Widget build(BuildContext context) {
    final double maxBar = values.isEmpty
        ? 1
        : values.reduce((double a, double b) => a > b ? a : b);
    final double maxY = (maxBar > goalValue ? maxBar : goalValue) * 1.15;

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: <HorizontalLine>[
            HorizontalLine(
              y: goalValue,
              color: AppColors.secondary.withValues(alpha: 0.8),
              strokeWidth: 1.5,
              dashArray: const <int>[4, 4],
            ),
          ],
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double v, TitleMeta m) {
                final int i = v.toInt().clamp(0, labels.length - 1);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[i], style: AppTextStyles.bodySmall),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(values.length, (int i) {
          final double v = values[i];
          final bool active = v > 0;
          return BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: v,
                width: 10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                color: active
                    ? AppColors.secondary
                    : AppColors.surfaceContainerHighest,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 14),
            ),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final ActivityType type;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (type) {
      ActivityType.run => Icons.directions_run_rounded,
      ActivityType.walk => Icons.directions_walk_rounded,
      ActivityType.cycle => Icons.directions_bike_rounded,
      ActivityType.swim => Icons.pool_rounded,
    };
    final Color color = switch (type) {
      ActivityType.run => AppColors.secondary,
      ActivityType.walk => AppColors.primary,
      ActivityType.cycle => AppColors.secondary,
      ActivityType.swim => AppColors.tertiary,
    };
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _SleepBars extends StatelessWidget {
  const _SleepBars({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final double maxY = values.isEmpty
        ? 1
        : values.reduce((double a, double b) => a > b ? a : b) * 1.2;
    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (double value, TitleMeta meta) {
                const List<String> days = <String>[
                  'M',
                  'T',
                  'W',
                  'T',
                  'F',
                  'S',
                  'S',
                ];
                final int i = value.toInt().clamp(0, 6);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(days[i], style: AppTextStyles.bodySmall),
                );
              },
            ),
          ),
        ),
        barGroups: List<BarChartGroupData>.generate(values.length, (int i) {
          return BarChartGroupData(
            x: i,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: values[i],
                width: 10,
                color: AppColors.tertiary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RangeNav extends StatelessWidget {
  const _RangeNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge,
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.period, required this.onChanged});

  final _GraphPeriod period;
  final ValueChanged<_GraphPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _toggleChip(
            label: 'Week',
            selected: period == _GraphPeriod.week,
            onTap: () => onChanged(_GraphPeriod.week),
          ),
          _toggleChip(
            label: 'Month',
            selected: period == _GraphPeriod.month,
            onTap: () => onChanged(_GraphPeriod.month),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.secondary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSeries {
  const _PeriodSeries({required this.labels, required this.values});
  final List<String> labels;
  final List<double> values;
}

({DateTime from, DateTime to}) _periodRange(
  DateTime anchor,
  _GraphPeriod period,
) {
  if (period == _GraphPeriod.week) {
    final DateTime weekStart = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
    ).subtract(Duration(days: anchor.weekday - 1));
    return (from: weekStart, to: weekStart.add(const Duration(days: 7)));
  }
  final DateTime monthStart = DateTime(anchor.year, anchor.month, 1);
  return (from: monthStart, to: DateTime(anchor.year, anchor.month + 1, 1));
}

_PeriodSeries _seriesFor(
  List<Activity> activities,
  _GraphPeriod period,
  DateTime anchor,
) {
  final Map<DateTime, int> stepDays = stepsByDayNoDoubleCount(activities);
  final Map<DateTime, double> byDay = <DateTime, double>{
    for (final MapEntry<DateTime, int> e in stepDays.entries)
      e.key: e.value.toDouble(),
  };
  if (period == _GraphPeriod.week) {
    final DateTime start = _periodRange(anchor, period).from;
    final List<double> values = List<double>.generate(7, (int i) {
      final DateTime d = start.add(Duration(days: i));
      return byDay[d] ?? 0;
    });
    return _PeriodSeries(
      labels: const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      values: values,
    );
  }
  final int daysInMonth = DateUtils.getDaysInMonth(anchor.year, anchor.month);
  final int weekCount = ((daysInMonth + 6) / 7).floor();
  final List<double> weekBuckets = List<double>.filled(weekCount, 0);
  for (int day = 1; day <= daysInMonth; day++) {
    final DateTime d = DateTime(anchor.year, anchor.month, day);
    final int bucket = ((day - 1) / 7).floor().clamp(0, weekCount - 1);
    weekBuckets[bucket] += byDay[d] ?? 0;
  }
  final List<String> labels = List<String>.generate(
    weekCount,
    (int i) => 'W${i + 1}',
  );
  return _PeriodSeries(labels: labels, values: weekBuckets);
}

String _periodLabel(_GraphPeriod period, DateTime anchor) {
  if (period == _GraphPeriod.week) {
    final DateTime start = _periodRange(anchor, period).from;
    final DateTime end = start.add(const Duration(days: 6));
    return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
  }
  return DateFormat('MMMM yyyy').format(anchor);
}

bool _canGoNext(_GraphPeriod period, DateTime anchor, DateTime now) {
  if (period == _GraphPeriod.week) {
    final DateTime currentWeekStart = _periodRange(now, _GraphPeriod.week).from;
    final DateTime selectedWeekStart = _periodRange(
      anchor,
      _GraphPeriod.week,
    ).from;
    return selectedWeekStart.isBefore(currentWeekStart);
  }
  final DateTime currentMonthStart = DateTime(now.year, now.month, 1);
  final DateTime selectedMonthStart = DateTime(anchor.year, anchor.month, 1);
  return selectedMonthStart.isBefore(currentMonthStart);
}

int _activeDays(List<Activity> list) {
  final Set<DateTime> days = <DateTime>{};
  for (final Activity a in list) {
    days.add(DateTime(a.startTime.year, a.startTime.month, a.startTime.day));
  }
  return days.length;
}

bool _isPassiveActivity(Activity a) => a.id.startsWith('passive_steps_');

List<double> _sleepMinutes7Days(List<SleepLog> logs, DateTime now) {
  final DateTime start = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 6));
  final List<double> values = List<double>.filled(7, 0);
  for (final SleepLog l in logs) {
    final DateTime day = DateTime(
      l.wakeTime.year,
      l.wakeTime.month,
      l.wakeTime.day,
    );
    final int idx = day.difference(start).inDays;
    if (idx >= 0 && idx < 7) {
      values[idx] += l.durationMinutes.toDouble();
    }
  }
  return values;
}
