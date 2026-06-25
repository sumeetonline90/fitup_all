import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/workout.dart';
import '../widgets/workout_ai_insight_sheet.dart';

/// Post-workout summary with PRs and Fitcoins from [WorkoutLog].
class WorkoutCompleteScreen extends StatefulWidget {
  const WorkoutCompleteScreen({super.key, required this.log});

  final WorkoutLog log;

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _formatDur(Duration d) {
    final int m = d.inMinutes;
    final int s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final WorkoutLog a = widget.log;
    final Duration dur = a.endTime.difference(a.startTime);
    final List<String> prLines = <String>[];
    for (final CompletedSet s in a.completedSets) {
      if (s.isPersonalRecord) {
        prLines.add(
          '${s.exerciseName} — ${s.weightKg?.toStringAsFixed(1) ?? '—'} kg',
        );
      }
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Column(
                children: <Widget>[
                  Semantics(
                    label: 'Workout complete',
                    child: Text(
                      'Workout complete! 💪',
                      style: AppTextStyles.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.emoji_events_outlined,
                      size: 56, color: AppColors.primaryContainer),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(a.sessionName, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Duration: ${_formatDur(dur)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    'Calories (est.): ${a.totalCaloriesBurnt.round()} kcal',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    'Sets logged: ${a.completedSets.length}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Divider(height: 24),
                  Text('Exercises', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 8),
                  ..._linesByExercise(a.completedSets),
                ],
              ),
            ),
            if (prLines.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('New personal records', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              ...prLines.map(
                (String line) => ListTile(
                  leading: const Text('🏆'),
                  title: Text(line, style: AppTextStyles.bodyMedium),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GlassCard(
              glowColor: AppColors.primaryContainer,
              child: Row(
                children: <Widget>[
                  Semantics(
                    label: 'Fitcoins earned',
                    child: Image.asset(
                      'assets/images/fitcoins.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.stars_outlined,
                        color: AppColors.primaryContainer,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '+${a.fitcoinsEarned} FTC',
                    style: AppTextStyles.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Semantics(
              button: true,
              label: 'Open AI workout insight',
              child: OutlinedButton.icon(
                onPressed: () => showWorkoutAiInsightSheet(context),
                icon: const Icon(Icons.auto_awesome, color: AppColors.secondary),
                label: Text(
                  'AI insight for this session',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'Back to workouts',
              child: NeonButton(
                label: 'Back to workouts',
                icon: Icons.fitness_center,
                onPressed: () => context.go('/workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _linesByExercise(List<CompletedSet> sets) {
    final Map<String, List<CompletedSet>> byEx = <String, List<CompletedSet>>{};
    for (final CompletedSet s in sets) {
      byEx.putIfAbsent(s.exerciseId, () => <CompletedSet>[]).add(s);
    }
    final List<Widget> out = <Widget>[];
    for (final List<CompletedSet> group in byEx.values) {
      if (group.isEmpty) {
        continue;
      }
      group.sort(
        (CompletedSet a, CompletedSet b) => a.setNumber.compareTo(b.setNumber),
      );
      out.add(Text(group.first.exerciseName, style: AppTextStyles.bodyLarge));
      for (final CompletedSet s in group) {
        out.add(
          Text(
            '  Set ${s.setNumber}: ${s.reps ?? 0} reps × '
            '${s.weightKg?.toStringAsFixed(1) ?? '—'} kg',
            style: AppTextStyles.bodySmall,
          ),
        );
      }
    }
    return out;
  }
}
