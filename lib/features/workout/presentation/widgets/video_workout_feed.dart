import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_type.dart';
import '../../domain/entities/muscle_group.dart';
import '../providers/workout_providers.dart';
import 'video_workout_card.dart';
import 'video_workout_log_sheet.dart';

/// Maps each health goal to the most relevant exercise types and muscle groups.
Map<String, bool Function(Exercise)> _goalFilters(List<HealthGoal> goals) {
  final Map<String, bool Function(Exercise)> sections =
      <String, bool Function(Exercise)>{};

  for (final HealthGoal g in goals) {
    switch (g) {
      case HealthGoal.loseWeight:
        sections['For Weight Loss'] = (Exercise e) =>
            e.type == WorkoutExerciseType.cardio ||
            e.muscleGroups.contains(MuscleGroup.fullBody);
      case HealthGoal.buildMuscle:
        sections['For Muscle Building'] = (Exercise e) =>
            e.type == WorkoutExerciseType.strength;
      case HealthGoal.improveFitness:
        sections['For Fitness'] = (Exercise e) =>
            e.type == WorkoutExerciseType.cardio ||
            e.type == WorkoutExerciseType.strength;
      case HealthGoal.mentalWellbeing:
        sections['For Wellbeing'] = (Exercise e) =>
            e.type == WorkoutExerciseType.flexibility ||
            e.type == WorkoutExerciseType.balance;
      case HealthGoal.improveOverallHealth:
        sections['For Overall Health'] = (Exercise e) => true;
      case HealthGoal.manageHealthCondition:
        sections['Low Impact'] = (Exercise e) =>
            e.type == WorkoutExerciseType.flexibility ||
            e.type == WorkoutExerciseType.balance ||
            e.muscleGroups.contains(MuscleGroup.core);
    }
  }

  if (sections.isEmpty) {
    sections['Recommended'] = (_) => true;
  }

  return sections;
}

/// Feed of video workout cards grouped by user goals with type filter chips.
class VideoWorkoutFeed extends ConsumerStatefulWidget {
  const VideoWorkoutFeed({super.key});

  @override
  ConsumerState<VideoWorkoutFeed> createState() => _VideoWorkoutFeedState();
}

class _VideoWorkoutFeedState extends ConsumerState<VideoWorkoutFeed> {
  WorkoutExerciseType? _selectedType;
  bool _refreshed = false;

  @override
  Widget build(BuildContext context) {
    // Background-refresh exercise video URLs from Firestore once per screen visit.
    if (!_refreshed) {
      _refreshed = true;
      ref.read(refreshExerciseLibraryProvider.future).then((_) {
        if (mounted) {
          ref.invalidate(
            exerciseLibraryProvider(const ExerciseLibraryParams(limit: 200)),
          );
        }
      });
    }

    final AsyncValue<UserProfile> profileAsync =
        ref.watch(userProfileProvider);
    final AsyncValue<List<Exercise>> exercisesAsync = ref.watch(
      exerciseLibraryProvider(const ExerciseLibraryParams(limit: 200)),
    );

    final List<HealthGoal> goals = profileAsync.maybeWhen(
      data: (UserProfile p) => p.goals,
      orElse: () => <HealthGoal>[],
    );

    final List<Exercise> allExercises = exercisesAsync.maybeWhen(
      data: (List<Exercise> e) => e,
      orElse: () => <Exercise>[],
    );

    if (allExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    // Apply type filter first
    final List<Exercise> typeFiltered = _selectedType == null
        ? allExercises
        : allExercises
            .where((Exercise e) => e.type == _selectedType)
            .toList();

    final Map<String, bool Function(Exercise)> goalSections =
        _goalFilters(goals);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Video Workouts',
            style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
          ),
        ),
        // Type filter chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              _TypeChip(
                label: 'All',
                selected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              _TypeChip(
                label: 'Strength',
                selected: _selectedType == WorkoutExerciseType.strength,
                onTap: () => setState(
                    () => _selectedType = WorkoutExerciseType.strength),
              ),
              _TypeChip(
                label: 'Cardio',
                selected: _selectedType == WorkoutExerciseType.cardio,
                onTap: () => setState(
                    () => _selectedType = WorkoutExerciseType.cardio),
              ),
              _TypeChip(
                label: 'Flexibility',
                selected: _selectedType == WorkoutExerciseType.flexibility,
                onTap: () => setState(
                    () => _selectedType = WorkoutExerciseType.flexibility),
              ),
              _TypeChip(
                label: 'Balance',
                selected: _selectedType == WorkoutExerciseType.balance,
                onTap: () => setState(
                    () => _selectedType = WorkoutExerciseType.balance),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Goal sections
        ...goalSections.entries.map((MapEntry<String, bool Function(Exercise)> entry) {
          final List<Exercise> matched = typeFiltered
              .where(entry.value)
              .where((Exercise e) =>
                  e.videoUrl != null && e.videoUrl!.isNotEmpty)
              .toList();

          if (matched.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 4),
                child: Text(
                  entry.key,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
              ...matched.take(6).map(
                    (Exercise ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: VideoWorkoutCard(
                        exercise: ex,
                        onLog: () async {
                          final ScaffoldMessengerState messenger =
                              ScaffoldMessenger.of(context);
                          final bool saved =
                              await showVideoWorkoutLogSheet(
                            context,
                            exercise: ex,
                          );
                          if (saved) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${ex.name} logged!',
                                  style: AppTextStyles.bodyLarge,
                                ),
                                backgroundColor: AppColors.surfaceContainer,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
            ],
          );
        }),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.2)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: selected ? AppColors.secondary : AppColors.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
