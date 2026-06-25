import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_providers.dart';

/// Shows a bottom sheet for quick-logging a video workout with calorie estimation.
Future<bool> showVideoWorkoutLogSheet(
  BuildContext context, {
  required Exercise exercise,
}) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _VideoWorkoutLogSheet(exercise: exercise),
  );
  return saved ?? false;
}

class _VideoWorkoutLogSheet extends ConsumerStatefulWidget {
  const _VideoWorkoutLogSheet({required this.exercise});

  final Exercise exercise;

  @override
  ConsumerState<_VideoWorkoutLogSheet> createState() =>
      _VideoWorkoutLogSheetState();
}

class _VideoWorkoutLogSheetState
    extends ConsumerState<_VideoWorkoutLogSheet> {
  double _minutes = 15;
  final TextEditingController _notes = TextEditingController();
  bool _saving = false;

  double get _estimatedCalories =>
      widget.exercise.caloriesPerMinute * _minutes;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;

    setState(() => _saving = true);

    final DateTime now = DateTime.now();
    final DateTime start = now.subtract(Duration(minutes: _minutes.round()));
    final WorkoutLog log = WorkoutLog(
      id: '${userId}_v_${now.millisecondsSinceEpoch}',
      userId: userId,
      sessionId: 'video_${widget.exercise.id}',
      sessionName: widget.exercise.name,
      startTime: start,
      endTime: now,
      completedSets: <CompletedSet>[
        CompletedSet(
          exerciseId: widget.exercise.id,
          exerciseName: widget.exercise.name,
          setNumber: 1,
          reps: 1,
          durationSeconds: (_minutes * 60).round(),
        ),
      ],
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
              content: Text(
                'Could not save workout',
                style: AppTextStyles.bodyLarge,
              ),
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
          Navigator.of(context).pop(true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Log: ${widget.exercise.name}',
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Duration slider
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Calorie estimate
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Est. Calories', style: AppTextStyles.bodyMedium),
                  Text(
                    '${_estimatedCalories.round()} kcal',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 20,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Notes
            TextField(
              controller: _notes,
              style: AppTextStyles.bodyLarge,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                hintStyle: AppTextStyles.bodyMedium,
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Log workout',
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTextStyles.labelLarge,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : const Text('Log Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
