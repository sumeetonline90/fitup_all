import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart' show Either, Left;
import 'package:shimmer/shimmer.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_outline_button.dart';
import '../../../../features/insights/domain/entities/holistic_plan.dart';
import '../../../../features/insights/presentation/providers/holistic_plan_ui_providers.dart';
import '../../../../features/insights/presentation/utils/holistic_plan_ui_actions.dart';
import '../../../../features/insights/presentation/utils/plan_summary_formatter.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/mood_level.dart';
import '../../domain/entities/survey_type.dart';
import '../providers/mental_wellbeing_providers.dart';
import '../widgets/mood_emoji_selector.dart';
import '../widgets/mood_week_chart.dart';
import '../widgets/stress_score_gauge.dart';
import '../../../../shared/widgets/module_top_header.dart';

const List<String> _moodTags = <String>[
  'Stressed',
  'Anxious',
  'Calm',
  'Energetic',
  'Sad',
  'Grateful',
];

String _stressWord(int s) {
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

String _emojiForMood(MoodLogUi log) {
  return switch (log.level) {
    MoodLevel.veryBad => '😫',
    MoodLevel.bad => '😕',
    MoodLevel.neutral => '😐',
    MoodLevel.good => '🙂',
    MoodLevel.veryGood => '😄',
  };
}

/// Mental wellbeing hub (mood, stress, surveys, tools).
class MentalWellbeingScreen extends ConsumerStatefulWidget {
  const MentalWellbeingScreen({super.key});

  @override
  ConsumerState<MentalWellbeingScreen> createState() =>
      _MentalWellbeingScreenState();
}

class _MentalWellbeingScreenState extends ConsumerState<MentalWellbeingScreen> {
  MoodLevel? _picked;
  final TextEditingController _journal = TextEditingController();
  final Set<String> _tags = <String>{};

  DateTime _holisticPlanStartDate = DateTime.now();
  bool _planActionBusy = false;
  int _sleepPresetIdx = 1; // 0=Easy, 1=Balanced, 2=Push
  int _availabilityIdx = 1; // 0=Low, 1=Medium, 2=High

  @override
  void dispose() {
    _journal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MoodLogUi? today = ref.watch(dailyMoodProvider);
    final AsyncValue<int> stress = ref.watch(currentStressScoreProvider);
    final List<int> week = ref.watch(moodWeekLevelsProvider);
    final AsyncValue<List<SurveyResultUi>> historyAsync = ref.watch(
      surveyHistoryProvider,
    );
    final List<SurveyResultUi> history = historyAsync.maybeWhen(
      data: (List<SurveyResultUi> l) => l,
      orElse: () => <SurveyResultUi>[],
    );

    final AsyncValue<dynamic> profileAsync = ref.watch(userProfileProvider);
    final int baseSleepMinutes = profileAsync.maybeWhen(
      data: (dynamic p) => p.dailySleepGoalMinutes ?? 420,
      orElse: () => 420,
    );
    final AsyncValue<HolisticPlan?> holisticAsync =
        ref.watch(activeHolisticPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
          const ModuleTopHeader(),
          const SizedBox(height: 8),
          NeonOutlineButton(
            label: 'Wellbeing AI',
            onPressed: () => _showMentalInsightSheet(context),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: holisticAsync.when(
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const <Widget>[
                  Text(
                    'AI Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
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
                  const SizedBox(height: 6),
                  Text(
                    'Manual wellbeing tools still work.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              data: (HolisticPlan? activePlan) {
                final List<double> mult = <double>[0.9, 1.0, 1.15];
                final int chosenSleep = (baseSleepMinutes *
                        mult[_sleepPresetIdx])
                    .round()
                    .clamp(240, 720);

                Future<void> onGenerate() async {
                  final FitupUser? user = ref.read(authStateProvider).value;
                  if (user == null || _planActionBusy) return;

                  setState(() => _planActionBusy = true);

                  final String availabilityText = switch (_availabilityIdx) {
                    0 => 'Low',
                    1 => 'Medium',
                    2 => 'High',
                    _ => 'Medium',
                  };
                  final String intensityText = switch (_sleepPresetIdx) {
                    0 => 'Easy',
                    1 => 'Balanced',
                    2 => 'Push',
                    _ => 'Balanced',
                  };

                  final double baseTarget = baseSleepMinutes > 0
                      ? baseSleepMinutes.toDouble()
                      : 1.0;
                  final double targetRatio = chosenSleep / baseTarget;
                  final int durationDays = computeHolisticPlanDurationDays(
                    availabilityIdx: _availabilityIdx,
                    intensityIdx: _sleepPresetIdx,
                    targetRatio: targetRatio,
                  );

                  final Either<Failure, HolisticPlan> res =
                      await generateHolisticPlanAndSyncProfile(
                    user: user,
                    startDate: _holisticPlanStartDate,
                    durationDays: durationDays,
                  );
                  if (!mounted) return;

                  await res.fold<Future<void>>(
                    (Failure f) async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            f.message ?? 'Plan generation failed',
                          ),
                        ),
                      );
                    },
                    (HolisticPlan generatedPlan) async {
                      final String amendment =
                          'Availability: $availabilityText. Intensity: $intensityText. '
                          'Set dailySleepGoalMinutes to $chosenSleep minutes/day. '
                          'Prefer consistent bedtime routine and gradual sleep improvements.';

                      final Either<Failure, HolisticPlan> amendRes =
                          await amendActivePlanModuleAndSyncProfile(
                        user: user,
                        activePlan: generatedPlan,
                        moduleKey: PlanModuleKey.mental,
                        moduleAmendment: amendment,
                      );

                      amendRes.fold(
                        (Failure f) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                f.message ?? 'Plan update failed',
                              ),
                            ),
                          );
                        },
                        (_) {
                          ref.invalidate(activeHolisticPlanProvider);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mental plan generated'),
                            ),
                          );
                        },
                      );
                    },
                  );

                  if (!mounted) return;
                  setState(() => _planActionBusy = false);
                }

                Future<void> onAmend(HolisticPlan plan) async {
                  final FitupUser? user = ref.read(authStateProvider).value;
                  if (user == null || _planActionBusy) return;
                  setState(() => _planActionBusy = true);

                  final String availabilityText = switch (_availabilityIdx) {
                    0 => 'Low',
                    1 => 'Medium',
                    2 => 'High',
                    _ => 'Medium',
                  };
                  final String intensityText = switch (_sleepPresetIdx) {
                    0 => 'Easy',
                    1 => 'Balanced',
                    2 => 'Push',
                    _ => 'Balanced',
                  };

                  final int currentSleepTarget =
                      plan.dailyTargets.dailySleepGoalMinutes;
                  final double targetRatio = currentSleepTarget > 0
                      ? chosenSleep / currentSleepTarget
                      : 1.0;
                  final bool majorChange = targetRatio >= 1.3 ||
                      targetRatio <= 0.7;

                  final String amendment =
                      'Availability: $availabilityText. Intensity: $intensityText. '
                      'Set dailySleepGoalMinutes to $chosenSleep minutes/day. '
                      'Prefer consistent bedtime routine and gradual sleep improvements.';

                  Either<Failure, HolisticPlan> res;

                  if (!majorChange) {
                    res = await amendActivePlanModuleAndSyncProfile(
                      user: user,
                      activePlan: plan,
                      moduleKey: PlanModuleKey.mental,
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
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Keep dates'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Change dates'),
                            ),
                          ],
                        );
                      },
                    );

                    if (changeDates == true) {
                      final int durationDays = computeHolisticPlanDurationDays(
                        availabilityIdx: _availabilityIdx,
                        intensityIdx: _sleepPresetIdx,
                        targetRatio: targetRatio,
                      );

                      final Either<Failure, HolisticPlan> genRes =
                          await generateHolisticPlanAndSyncProfile(
                        user: user,
                        startDate: plan.startDate,
                        durationDays: durationDays,
                      );

                      res = await genRes.fold<
                          Future<Either<Failure, HolisticPlan>>>(
                        (Failure f) async => Left(f),
                        (HolisticPlan generatedPlan) async {
                          return await amendActivePlanModuleAndSyncProfile(
                            user: user,
                            activePlan: generatedPlan,
                            moduleKey: PlanModuleKey.mental,
                            moduleAmendment: amendment,
                          );
                        },
                      );
                    } else {
                      res = await amendActivePlanModuleAndSyncProfile(
                        user: user,
                        activePlan: plan,
                        moduleKey: PlanModuleKey.mental,
                        moduleAmendment: amendment,
                      );
                    }
                  }
                  if (!mounted) return;
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
                        const SnackBar(content: Text('Mental plan updated')),
                      );
                    },
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.auto_awesome, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'AI Plan',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activePlan == null
                                    ? 'Generate a plan for daily sleep targets.'
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
                        onPressed: _planActionBusy
                            ? null
                            : () async {
                                final DateTime? picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate: _holisticPlanStartDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 365)),
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
                            selected: _sleepPresetIdx == 0,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 0,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Balanced'),
                            selected: _sleepPresetIdx == 1,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 1,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Push'),
                            selected: _sleepPresetIdx == 2,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 2,
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
                        'Sleep focus plan',
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      ...modulePlanChecklist(
                        plan: activePlan,
                        moduleKey: PlanModuleKey.mental,
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
                        'Choose daily sleep goal',
                        style: AppTextStyles.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          ChoiceChip(
                            label: const Text('Easy'),
                            selected: _sleepPresetIdx == 0,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 0,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Balanced'),
                            selected: _sleepPresetIdx == 1,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 1,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Push'),
                            selected: _sleepPresetIdx == 2,
                            onSelected: (_) => setState(
                              () => _sleepPresetIdx = 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Daily sleep target: $chosenSleep min',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      NeonOutlineButton(
                        label: _planActionBusy
                            ? 'Updating…'
                            : 'Amend mental plan',
                        onPressed: () {
                          if (_planActionBusy) return;
                          onAmend(activePlan);
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: today == null
                ? _buildMoodCheckIn(context)
                : _buildMoodLogged(today),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: stress.when(
              data: (int s) => Row(
                children: <Widget>[
                  StressScoreGauge(score: s),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Stress Level: ${_stressWord(s)}',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Based on HRV, sleep, mood, and recent survey',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    color: AppColors.secondary,
                    onPressed: () => ref.invalidate(currentStressScoreProvider),
                  ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (Object _, StackTrace __) => Text(
                'Stress score unavailable',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Surveys', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          _SurveyCard(
            title: 'PHQ-9 (Depression)',
            type: SurveyType.phq9,
            history: history,
            onTake: () =>
                context.push('/mental/survey/${SurveyType.phq9.name}'),
          ),
          _SurveyCard(
            title: 'GAD-7 (Anxiety)',
            type: SurveyType.gad7,
            history: history,
            onTake: () =>
                context.push('/mental/survey/${SurveyType.gad7.name}'),
          ),
          _SurveyCard(
            title: 'PSS-10 (Stress)',
            type: SurveyType.pss10,
            history: history,
            onTake: () =>
                context.push('/mental/survey/${SurveyType.pss10.name}'),
          ),
          const SizedBox(height: 16),
          Text('Wellness tools', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                _ToolCard(
                  title: 'Breathing',
                  icon: Icons.air,
                  onTap: () => context.push('/mental/breathing'),
                ),
                _ToolCard(
                  title: 'Meditation',
                  icon: Icons.spa_outlined,
                  onTap: () => context.push('/mental/meditation'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('7-day mood', style: AppTextStyles.labelSmall),
          const SizedBox(height: 8),
          MoodWeekChart(levels: week),
          ],
        ),
      ),
    );
  }

  Future<void> _showMentalInsightSheet(BuildContext context) async {
    ref.invalidate(mentalWellbeingInsightProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => Consumer(
        builder: (BuildContext context, WidgetRef ref, _) {
          final AsyncValue<String> insight =
              ref.watch(mentalWellbeingInsightProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (BuildContext context, ScrollController controller) {
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'AI Wellbeing Insight',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    insight.when(
                      data: (String t) => Text(t, style: AppTextStyles.bodyMedium),
                      loading: () => Shimmer.fromColors(
                        baseColor: AppColors.surfaceContainer,
                        highlightColor: AppColors.surfaceContainerHigh,
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Container(height: 56, color: AppColors.onSurface),
                        ),
                      ),
                      error: (Object _, StackTrace __) => Text(
                        'Insight unavailable',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMoodLogged(MoodLogUi log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(_emojiForMood(log), style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logged at ${DateFormat.jm().format(log.loggedAt)}',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],
        ),
        if (log.journal != null && log.journal!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(log.journal!, style: AppTextStyles.bodySmall, maxLines: 3),
        ],
      ],
    );
  }

  Widget _buildMoodCheckIn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('How are you feeling?', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 12),
        MoodEmojiSelector(
          onMoodSelected: (MoodLevel l) => setState(() => _picked = l),
        ),
        if (_picked != null) ...<Widget>[
          const SizedBox(height: 12),
          TextField(
            controller: _journal,
            maxLength: 200,
            maxLines: 2,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              labelText: 'Journal (optional)',
              filled: true,
              fillColor: AppColors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _moodTags.map((String t) {
              final bool on = _tags.contains(t);
              return FilterChip(
                label: Text(t),
                selected: on,
                onSelected: (bool v) {
                  setState(() {
                    if (v) {
                      _tags.add(t);
                    } else {
                      _tags.remove(t);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Center(
            child: NeonOutlineButton(
              label: 'Save Mood',
              onPressed: () async {
                await ref
                    .read(moodLoggerProvider.notifier)
                    .logMood(
                      level: _picked!,
                      journal: _journal.text.trim().isEmpty
                          ? null
                          : _journal.text.trim(),
                      tags: _tags.toList(),
                    );
                if (context.mounted) {
                  setState(() {
                    _picked = null;
                    _journal.clear();
                    _tags.clear();
                  });
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({
    required this.title,
    required this.type,
    required this.history,
    required this.onTake,
  });

  final String title;
  final SurveyType type;
  final List<SurveyResultUi> history;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    SurveyResultUi? last;
    for (final SurveyResultUi r in history) {
      if (r.type == type) {
        last = r;
        break;
      }
    }
    final String subtitle = last == null
        ? 'Not taken yet'
        : 'Last: ${last.score}/${surveyMaxScore(type)} · '
              '${DateFormat.yMMMd().format(last.takenAt)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            NeonOutlineButton(label: 'Take Survey', onPressed: onTake),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.secondary, size: 28),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
