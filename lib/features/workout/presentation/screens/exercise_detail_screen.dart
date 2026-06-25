import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_util.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_providers.dart';

Future<void> _launchExerciseVideo(String? url) async {
  if (url == null || url.isEmpty) {
    return;
  }
  await UrlLauncherUtil.launch(url);
}

/// Detail view for a single exercise from the catalog.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Exercise?> exAsync =
        ref.watch(exerciseByIdProvider(exerciseId));
    final AsyncValue<List<PersonalRecord>> prAsync =
        ref.watch(personalRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Exercise', style: AppTextStyles.headlineMedium),
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
      body: exAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => Center(
          child: Text('Could not load exercise.', style: AppTextStyles.bodyMedium),
        ),
        data: (Exercise? ex) {
          if (ex == null) {
            return Center(
              child: Text('Exercise not found', style: AppTextStyles.bodyMedium),
            );
          }
          double? prKg;
          final List<PersonalRecord> prs = prAsync.maybeWhen(
            data: (List<PersonalRecord> list) => list,
            orElse: () => <PersonalRecord>[],
          );
          for (final PersonalRecord p in prs) {
            if (p.exerciseId == ex.id && p.maxWeightKg != null) {
              prKg = p.maxWeightKg;
              break;
            }
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(ex.name, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(ex.description, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ex.muscleGroups
                    .map(
                      (MuscleGroup m) => Chip(
                        label: Text(m.name, style: AppTextStyles.labelSmall),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'Difficulty: ${ex.difficulty.name}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                'Equipment: ${ex.equipment.map((Equipment e) => e.name).join(', ')}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                '~${ex.caloriesPerMinute.toStringAsFixed(1)} kcal/min (estimate)',
                style: AppTextStyles.bodySmall,
              ),
              if (prKg != null && prKg > 0) ...<Widget>[
                const SizedBox(height: 12),
                GlassCard(
                  child: Text(
                    'Your previous best: ${prKg.toStringAsFixed(1)} kg',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('How to', style: AppTextStyles.labelSmall),
              const SizedBox(height: 8),
              ...ex.instructions.asMap().entries.map(
                    (MapEntry<int, String> e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${e.key + 1}. ',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Expanded(
                            child: Text(e.value, style: AppTextStyles.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (ex.videoUrl != null && ex.videoUrl!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Open exercise video',
                  child: NeonButton(
                    label: 'Watch video',
                    icon: Icons.play_circle_outline,
                    onPressed: () => _launchExerciseVideo(ex.videoUrl),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
