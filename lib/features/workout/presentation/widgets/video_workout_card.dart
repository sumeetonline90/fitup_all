import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/url_launcher_util.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';

/// Card showing a YouTube thumbnail, exercise metadata, and a log button.
class VideoWorkoutCard extends StatelessWidget {
  const VideoWorkoutCard({
    super.key,
    required this.exercise,
    required this.onLog,
  });

  final Exercise exercise;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final bool hasVideo =
        exercise.videoUrl != null && exercise.videoUrl!.isNotEmpty;
    final bool hasThumb =
        exercise.thumbnailUrl != null && exercise.thumbnailUrl!.isNotEmpty;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Thumbnail with play overlay
          GestureDetector(
            onTap: hasVideo
                ? () => UrlLauncherUtil.launch(exercise.videoUrl!)
                : null,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    if (hasThumb)
                      CachedNetworkImage(
                        imageUrl: exercise.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.surfaceContainerHighest,
                          child: const Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.surfaceContainerHighest,
                        child: const Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    // Gradient scrim
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasVideo)
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: AppColors.secondary.withValues(alpha: 0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.background,
                            size: 32,
                          ),
                        ),
                      ),
                    // Kcal badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '~${exercise.caloriesPerMinute.round()} kcal/min',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Info + log button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  exercise.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: exercise.muscleGroups.take(3).map(
                    (MuscleGroup mg) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mg.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    button: true,
                    label: 'Log ${exercise.name} workout',
                    child: ElevatedButton.icon(
                      onPressed: onLog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Log This Workout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: AppTextStyles.labelLarge.copyWith(
                          fontSize: 13,
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
    );
  }
}
