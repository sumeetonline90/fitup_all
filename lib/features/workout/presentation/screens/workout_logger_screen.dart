import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_providers.dart';

/// Quick-log screen for free-form workouts with calorie estimation.
class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  const WorkoutLoggerScreen({super.key});

  @override
  ConsumerState<WorkoutLoggerScreen> createState() =>
      _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  double _minutes = 30;
  bool _saving = false;

  static const double _defaultKcalPerMin = 8;

  double get _estimatedCalories => _defaultKcalPerMin * _minutes;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;

    final String? userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(minutes: _minutes.round()));

    final WorkoutLog log = WorkoutLog(
      id: '${userId}_q_${now.millisecondsSinceEpoch}',
      userId: userId,
      sessionId: 'quick_log',
      sessionName: _title.text.trim(),
      startTime: start,
      endTime: now,
      completedSets: const <CompletedSet>[],
      totalCaloriesBurnt: _estimatedCalories,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    final result =
        await ref.read(workoutLoggerProvider.notifier).saveLog(log);

    result.fold(
      (_) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save workout',
                  style: AppTextStyles.bodyLarge),
            ),
          );
        }
      },
      (_) {
        ref.invalidate(workoutSummaryProvider);
        ref.invalidate(recentWorkoutsProvider);
        ref.invalidate(todayCaloriesBurntProvider);
        ref.invalidate(workoutLogsProvider(const WorkoutLogRange()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Workout saved!', style: AppTextStyles.bodyLarge),
              backgroundColor: AppColors.surfaceContainer,
            ),
          );
          context.pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Log workout', style: AppTextStyles.headlineMedium),
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Quick log', style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _title,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Workout name',
                    labelStyle: AppTextStyles.bodySmall,
                    hintText: 'e.g. Morning run + core',
                    hintStyle: AppTextStyles.bodyMedium,
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                  ),
                ),
                const SizedBox(height: 16),
                // Duration slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Duration', style: AppTextStyles.bodyMedium),
                    Text(
                      '${_minutes.round()} min',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _minutes,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: AppColors.secondary,
                  inactiveColor: AppColors.surfaceContainerHighest,
                  onChanged: (double v) => setState(() => _minutes = v),
                ),
                const SizedBox(height: 8),
                // Calorie estimate
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('Est. Calories', style: AppTextStyles.bodyMedium),
                      Text(
                        '${_estimatedCalories.round()} kcal',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  style: AppTextStyles.bodyLarge,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: AppTextStyles.bodySmall,
                    filled: true,
                    fillColor: AppColors.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'Save workout log',
            child: NeonButton(
              label: _saving ? 'Saving…' : 'Save log',
              icon: Icons.save_outlined,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
