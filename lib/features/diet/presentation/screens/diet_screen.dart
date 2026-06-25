import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart' show Either, Left;

import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/entities/diet_summary.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/water_log.dart';
import '../providers/diet_providers.dart';
import 'meal_log_screen.dart';
import '../widgets/ai_diet_insight_sheet.dart';
import '../widgets/calorie_ring_chart.dart';
import '../widgets/macro_bar_chart.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/water_tracker_card.dart';
import '../../../../shared/widgets/module_top_header.dart';
import '../../../../shared/layout/app_breakpoints.dart';
import '../widgets/weekly_nutrition_chart.dart';
import '../../../../features/insights/presentation/providers/holistic_plan_ui_providers.dart';
import '../../../../features/insights/presentation/utils/holistic_plan_ui_actions.dart';
import '../../../../features/insights/presentation/utils/plan_summary_formatter.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';

/// Diet hub: daily summary, water, meal slots, AI insight.
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  DateTime _day = DateTime.now();
  bool _welcomeVisible = true;
  final Set<String> _pendingWaterLogIds = <String>{};
  double _optimisticWaterDeltaMl = 0;

  DateTime _holisticPlanStartDate = DateTime.now();
  bool _planActionBusy = false;
  int _caloriePresetIdx = 1; // 0=Easy, 1=Balanced, 2=Push
  int _waterPresetIdx = 1;
  int _availabilityIdx = 1; // 0=Low, 1=Medium, 2=High

  bool get _isToday {
    final DateTime n = DateTime.now();
    return _day.year == n.year && _day.month == n.month && _day.day == n.day;
  }

  bool get _isYesterday {
    final DateTime y = DateTime.now().subtract(const Duration(days: 1));
    return _day.year == y.year && _day.month == y.month && _day.day == y.day;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.secondary,
              surface: AppColors.surfaceContainer,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _day = picked);
    }
  }

  void _setDay(DateTime d) {
    setState(() {
      _day = DateTime(d.year, d.month, d.day);
      _optimisticWaterDeltaMl = 0;
      _pendingWaterLogIds.clear();
    });
  }

  void _refreshDay() {
    final String key = dietDateKey(_day);
    ref.invalidate(dailySummaryForDateProvider(key));
    ref.invalidate(mealsForDayProvider(key));
    ref.invalidate(waterLogsForDateProvider(key));
    ref.invalidate(dietInsightForProvider(key));
    ref.invalidate(weeklyNutritionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final String key = dietDateKey(_day);
    final AsyncValue<DietSummary> summaryAsync = ref.watch(
      dailySummaryForDateProvider(key),
    );
    final AsyncValue<List<Meal>> mealsAsync = ref.watch(
      mealsForDayProvider(key),
    );
    final AsyncValue<List<WaterLog>> waterLogsAsync = ref.watch(
      waterLogsForDateProvider(key),
    );
    final AsyncValue<Map<String, DietSummary>> weekAsync = ref.watch(
      weeklyNutritionProvider,
    );

    final bool hideModuleHeader =
        kIsWeb && MediaQuery.sizeOf(context).width >= kMobileBreak;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Semantics(
        label: 'Log meal',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () async {
            await showMealTypeSelector(context);
            if (!mounted) return;
            _refreshDay();
          },
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.background,
          icon: const Icon(Icons.add),
          label: Text('Log Meal', style: AppTextStyles.labelSmall),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          top: !hideModuleHeader,
          bottom: false,
          child: summaryAsync.when(
            loading: () => _buildShimmerBody(hideModuleHeader: hideModuleHeader),
            error: (Object e, StackTrace st) => _buildError(e),
            data: (DietSummary summary) {
              final List<Meal> meals = mealsAsync.maybeWhen(
                data: (List<Meal> streamed) =>
                    streamed.isNotEmpty ? streamed : summary.meals,
                orElse: () => summary.meals,
              );
              final List<double> weekCals = weekAsync.maybeWhen(
                data: (Map<String, DietSummary> m) => _rollingWeekCalories(m),
                orElse: () => List<double>.filled(7, 0),
              );
              return _buildBody(
                summary: summary,
                meals: meals,
                waterLogs: waterLogsAsync.maybeWhen(
                  data: (List<WaterLog> logs) => logs,
                  orElse: () => <WaterLog>[],
                ),
                weekCalories: weekCals,
                hideModuleHeader: hideModuleHeader,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load diet data',
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  e is Failure
                      ? (e.message ?? 'Something went wrong. Please try again.')
                      : 'Something went wrong. Please try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                NeonButton(
                  label: 'Retry',
                  icon: Icons.refresh,
                  onPressed: _refreshDay,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBody({required bool hideModuleHeader}) {
    return CustomScrollView(
      slivers: <Widget>[
        if (!hideModuleHeader)
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
              const ShimmerLoading(height: 220, borderRadius: 20),
              const SizedBox(height: 16),
              const ShimmerLoading(height: 160, borderRadius: 20),
              const SizedBox(height: 16),
              const ShimmerLoading(height: 88, borderRadius: 16),
              const SizedBox(height: 12),
              const ShimmerLoading(height: 88, borderRadius: 16),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBody({
    required DietSummary summary,
    required List<Meal> meals,
    required List<WaterLog> waterLogs,
    required List<double> weekCalories,
    required bool hideModuleHeader,
  }) {
    final double targetCal = summary.targetCalories;
    final double consumedCal = summary.totalCalories;
    final double remaining = targetCal - consumedCal;
    final String calLine = remaining >= 0
        ? '${remaining.round()} cal remaining'
        : '${(-remaining).round()} cal over';

    final ({double p, double c, double f}) macroTargets = _macroTargets(
      targetCal,
    );
    final double currentWaterMl =
        waterLogs.fold<double>(
          0,
          (double sum, WaterLog w) => sum + w.amountMl,
        ) +
        _optimisticWaterDeltaMl;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, hideModuleHeader ? 16 : 12, 16, 8),
            child: Column(
              children: <Widget>[
                if (!hideModuleHeader) ...<Widget>[
                  const ModuleTopHeader(),
                  const SizedBox(height: 8),
                ],
                NeonOutlineButton(
                  label: 'Diet AI',
                  onPressed: () {
                    final String key = dietDateKey(_day);
                    ref.invalidate(dietInsightForProvider(key));
                    showAiDietInsightSheet(context, dateKey: key);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => _setDay(DateTime.now()),
                      child: Text(
                        'Today',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _isToday
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final DateTime y = DateTime.now().subtract(
                          const Duration(days: 1),
                        );
                        _setDay(y);
                      },
                      child: Text(
                        'Yesterday',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _isYesterday
                              ? AppColors.secondary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Pick date',
                      icon: const Icon(Icons.calendar_month_outlined),
                      color: AppColors.secondary,
                      onPressed: _pickDate,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Builder(
              builder: (BuildContext context) {
                final AsyncValue<HolisticPlan?> holisticAsync =
                    ref.watch(activeHolisticPlanProvider);
                final int baseCal = summary.targetCalories.round();
                final int baseWaterMl = summary.targetWater.round();

                final List<double> mult = <double>[0.9, 1.0, 1.15];
                final int chosenCal = (baseCal * mult[_caloriePresetIdx])
                    .round()
                    .clamp(1200, 4000);
                final int chosenWaterMl =
                    (baseWaterMl * mult[_waterPresetIdx])
                        .round()
                        .clamp(500, 5000);

                Future<void> onAmendPlan(HolisticPlan activePlan) async {
                  final FitupUser? user =
                      ref.read(authStateProvider).value;
                  if (user == null) return;
                  setState(() => _planActionBusy = true);

                  final String availabilityText = switch (_availabilityIdx) {
                    0 => 'Low',
                    1 => 'Medium',
                    2 => 'High',
                    _ => 'Medium',
                  };
                  final String intensityText = switch (_caloriePresetIdx) {
                    0 => 'Easy',
                    1 => 'Balanced',
                    2 => 'Push',
                    _ => 'Balanced',
                  };

                  final int currentCalTarget = activePlan
                      .dailyTargets.dailyCalorieGoal;
                  final int currentWaterTarget = activePlan
                      .dailyTargets.dailyWaterGoalMl;
                  final double ratioCal = currentCalTarget > 0
                      ? chosenCal / currentCalTarget
                      : 1.0;
                  final double ratioWater = currentWaterTarget > 0
                      ? chosenWaterMl / currentWaterTarget
                      : 1.0;
                  final double avgRatio = (ratioCal + ratioWater) / 2.0;
                  final bool majorChange = ratioCal >= 1.3 ||
                      ratioCal <= 0.7 ||
                      ratioWater >= 1.3 ||
                      ratioWater <= 0.7;

                  final String amendment =
                      'Availability: $availabilityText. Intensity: $intensityText. '
                      'Set dailyCalorieGoal to $chosenCal kcal/day and dailyWaterGoalMl to $chosenWaterMl ml/day. '
                      'Prefer consistency-focused hydration and steady calorie adherence.';

                  Either<Failure, HolisticPlan> res;
                  if (!majorChange) {
                    res =
                        await amendActivePlanModuleAndSyncProfile(
                      user: user,
                      activePlan: activePlan,
                      moduleKey: PlanModuleKey.diet,
                      moduleAmendment: amendment,
                    );
                  } else {
                    final bool? changeDates = await showDialog<bool>(
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
                              onPressed: () => Navigator.of(dialogContext)
                                  .pop(false),
                              child: const Text(
                                'Keep dates',
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext)
                                  .pop(true),
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
                        intensityIdx: _caloriePresetIdx,
                        targetRatio: avgRatio,
                      );

                      final Either<Failure, HolisticPlan> genRes =
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
                            moduleKey: PlanModuleKey.diet,
                            moduleAmendment: amendment,
                          );
                        },
                      );
                    } else {
                      res =
                          await amendActivePlanModuleAndSyncProfile(
                        user: user,
                        activePlan: activePlan,
                        moduleKey: PlanModuleKey.diet,
                        moduleAmendment: amendment,
                      );
                    }
                  }

                  if (!context.mounted) return;
                  setState(() => _planActionBusy = false);

                  res.fold(
                    (Failure f) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(f.message ?? 'Plan update failed'),
                        ),
                      );
                    },
                    (_) {
                      ref.invalidate(activeHolisticPlanProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diet plan updated')),
                      );
                    },
                  );
                }

                return GlassCard(
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
                          'Manual diet logging still works.',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    data: (HolisticPlan? activePlan) {
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
                              'Choose calorie target',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ChoiceChip(
                                  label: const Text('Easy'),
                                  selected: _caloriePresetIdx == 0,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 0,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Balanced'),
                                  selected: _caloriePresetIdx == 1,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 1,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Push'),
                                  selected: _caloriePresetIdx == 2,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Choose water goal',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ChoiceChip(
                                  label: const Text('Easy'),
                                  selected: _waterPresetIdx == 0,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 0,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Balanced'),
                                  selected: _waterPresetIdx == 1,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 1,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Push'),
                                  selected: _waterPresetIdx == 2,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                              'Diet plan summary',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            ...modulePlanChecklist(
                              plan: activePlan,
                              moduleKey: PlanModuleKey.diet,
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
                              'Choose calorie target',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ChoiceChip(
                                  label: const Text('Easy'),
                                  selected: _caloriePresetIdx == 0,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 0,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Balanced'),
                                  selected: _caloriePresetIdx == 1,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 1,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Push'),
                                  selected: _caloriePresetIdx == 2,
                                  onSelected: (_) => setState(
                                    () => _caloriePresetIdx = 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Choose water goal',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                ChoiceChip(
                                  label: const Text('Easy'),
                                  selected: _waterPresetIdx == 0,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 0,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Balanced'),
                                  selected: _waterPresetIdx == 1,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 1,
                                  ),
                                ),
                                ChoiceChip(
                                  label: const Text('Push'),
                                  selected: _waterPresetIdx == 2,
                                  onSelected: (_) => setState(
                                    () => _waterPresetIdx = 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Daily: $chosenCal kcal · $chosenWaterMl ml',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            NeonOutlineButton(
                              label: _planActionBusy
                                  ? 'Updating…'
                                  : 'Amend diet plan',
                              onPressed: () {
                                if (_planActionBusy) return;
                                onAmendPlan(activePlan);
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        if (_welcomeVisible)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GlassCard(
                glowColor: AppColors.secondary,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.waving_hand_outlined,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Welcome to Diet',
                            style: AppTextStyles.headlineMedium.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Log meals and water to see insights. Data syncs to '
                            'your account.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.onSurfaceVariant,
                      onPressed: () => setState(() => _welcomeVisible = false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              Text(_dateHeading(_day), style: AppTextStyles.bodySmall),
              const SizedBox(height: 12),
              GlassCard(
                glowColor: AppColors.primaryContainer,
                child: Column(
                  children: <Widget>[
                    CalorieRingChart(consumed: consumedCal, target: targetCal),
                    const SizedBox(height: 8),
                    MacroBarChart(
                      proteinG: summary.totalProtein,
                      proteinTargetG: macroTargets.p,
                      carbsG: summary.totalCarbs,
                      carbsTargetG: macroTargets.c,
                      fatG: summary.totalFat,
                      fatTargetG: macroTargets.f,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      calLine,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: remaining >= 0
                            ? AppColors.primaryContainer
                            : AppColors.error,
                      ),
                    ),
                    if (summary.totalFiber > 0 ||
                        summary.totalSugar > 0 ||
                        summary.totalSodium > 0) ...<Widget>[
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.outlineVariant),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _MicroChip(
                            label: 'Fiber',
                            value: '${summary.totalFiber.toStringAsFixed(1)}g',
                          ),
                          _MicroChip(
                            label: 'Sugar',
                            value: '${summary.totalSugar.toStringAsFixed(1)}g',
                          ),
                          _MicroChip(
                            label: 'Sodium',
                            value:
                                '${summary.totalSodium.toStringAsFixed(0)}mg',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              WaterTrackerCard(
                currentMl: currentWaterMl < 0 ? 0 : currentWaterMl,
                targetMl: summary.targetWater,
                onAddMl: (double ml) => _onAddWater(ml),
                onRemoveMl: currentWaterMl > 0
                    ? (double ml) => _onRemoveWater(ml)
                    : null,
              ),
              const SizedBox(height: 8),
              Text('This week', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              GlassCard(
                child: WeeklyNutritionChart(
                  dailyCalories: weekCalories.length == 7
                      ? weekCalories
                      : List<double>.filled(7, 0),
                  targetCalories: targetCal,
                  onDayTap: (int i) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Day ${i + 1}: open calendar to view that date.',
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ...MealType.values.map(
                (MealType t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MealSlotCard(
                    mealType: t,
                    meals: meals.where((Meal m) => m.mealType == t).toList(),
                    onTap: () async {
                      final List<Meal> slotMeals =
                          meals.where((Meal m) => m.mealType == t).toList();
                      if (slotMeals.isEmpty) {
                        await context.push('/diet/log/${t.name}');
                      } else {
                        await context.push(
                          '/diet/log/${t.name}',
                          extra: MealLogRouteExtra.forSlot(slotMeals),
                        );
                      }
                      if (!mounted) return;
                      _refreshDay();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 96),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _onAddWater(double ml) async {
    final String? uid = ref
        .read(authStateProvider)
        .maybeWhen(data: (FitupUser? u) => u?.id, orElse: () => null);
    if (uid == null) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime logTime = DateTime(
      _day.year,
      _day.month,
      _day.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
    final WaterLog log = WaterLog(
      id: 'w_${now.microsecondsSinceEpoch}',
      userId: uid,
      amountMl: ml,
      dateTime: logTime,
    );
    setState(() {
      _optimisticWaterDeltaMl += ml;
      _pendingWaterLogIds.add(log.id);
    });
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(waterLoggerProvider.notifier).logWater(log);
    result.fold(
      (Failure failure) {
        if (!mounted) {
          return;
        }
        setState(() {
          _optimisticWaterDeltaMl -= ml;
          _pendingWaterLogIds.remove(log.id);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failure.message ?? 'Could not log water. Please try again.',
            ),
          ),
        );
      },
      (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _optimisticWaterDeltaMl -= ml;
          _pendingWaterLogIds.remove(log.id);
        });
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${ml.round()} ml added'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                _undoWaterLog(log);
              },
            ),
          ),
        );
      },
    );
  }

  void _onRemoveWater(double ml) {
    final String key = dietDateKey(_day);
    final List<WaterLog> logs = ref
        .read(waterLogsForDateProvider(key))
        .maybeWhen(data: (List<WaterLog> l) => l, orElse: () => <WaterLog>[]);
    if (logs.isEmpty) {
      return;
    }
    final WaterLog last = logs.last;
    _undoWaterLog(last);
  }

  Future<void> _undoWaterLog(WaterLog log) async {
    if (_pendingWaterLogIds.contains(log.id)) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _optimisticWaterDeltaMl -= log.amountMl;
      _pendingWaterLogIds.add(log.id);
    });
    final result = await ref
        .read(waterLoggerProvider.notifier)
        .deleteWaterLog(log.userId, log.id, log.dateTime);
    if (!mounted) {
      return;
    }
    result.fold(
      (Failure failure) {
        setState(() {
          _optimisticWaterDeltaMl += log.amountMl;
          _pendingWaterLogIds.remove(log.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message ??
                  'Could not undo water entry. Please try again.',
            ),
          ),
        );
      },
      (_) {
        setState(() {
          _optimisticWaterDeltaMl += log.amountMl;
          _pendingWaterLogIds.remove(log.id);
        });
      },
    );
  }

  String _dateHeading(DateTime d) {
    if (_isToday) {
      return 'Today';
    }
    if (_isYesterday) {
      return 'Yesterday';
    }
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

List<double> _rollingWeekCalories(Map<String, DietSummary> m) {
  final DateTime today = DateTime.now();
  final List<double> out = <double>[];
  for (int i = 6; i >= 0; i--) {
    final DateTime d = today.subtract(Duration(days: i));
    final String k = dietDateKey(d);
    out.add(m[k]?.totalCalories ?? 0);
  }
  return out;
}

({double p, double c, double f}) _macroTargets(double targetCalories) {
  return (
    p: targetCalories * 0.30 / 4,
    c: targetCalories * 0.45 / 4,
    f: targetCalories * 0.25 / 9,
  );
}

class _MealSlotCard extends StatelessWidget {
  const _MealSlotCard({
    required this.mealType,
    required this.meals,
    required this.onTap,
  });

  final MealType mealType;
  final List<Meal> meals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool empty = meals.isEmpty;
    double calories = 0;
    final List<FoodItem> items = <FoodItem>[];
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    for (final Meal m in meals) {
      calories += m.totalCalories;
      protein += m.totalProtein;
      carbs += m.totalCarbs;
      fat += m.totalFat;
      for (final item in m.foodItems) {
        items.add(item);
      }
    }
    return Semantics(
      button: true,
      label:
          '${mealType.label} meal, ${empty ? 'empty' : '${items.length} items'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassCard(
          glowColor: AppColors.secondary.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      mealType.label,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (empty)
                    const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.secondary,
                    )
                  else ...<Widget>[
                    Text(
                      '${calories.round()} kcal · ${items.length} items',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (empty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.touch_app_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap to log ${mealType.label.toLowerCase()}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ] else ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'P ${protein.round()}g · C ${carbs.round()}g · F ${fat.round()}g',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                for (final FoodItem item in items.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item.name} · ${item.calories.round()} kcal · '
                      'P ${item.protein.round()} C ${item.carbs.round()} F ${item.fat.round()}'
                      '${item.fiber != null ? ' · Fi ${item.fiber!.toStringAsFixed(1)}g' : ''}'
                      '${item.sugar != null ? ' · Su ${item.sugar!.toStringAsFixed(1)}g' : ''}'
                      '${item.sodium != null ? ' · Na ${item.sodium!.toStringAsFixed(1)}mg' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                if (items.length > 4)
                  Text(
                    '+${items.length - 4} more',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
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

class _MicroChip extends StatelessWidget {
  const _MicroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
