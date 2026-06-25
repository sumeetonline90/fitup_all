import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/workout.dart';
import '../providers/workout_providers.dart';

/// Chronological workout logs from the repository.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutLog>> logs =
        ref.watch(workoutLogsProvider(const WorkoutLogRange()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text('Workout history', style: AppTextStyles.headlineMedium),
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
      body: logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => Center(
          child: Text(
            'Could not load history.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (List<WorkoutLog> list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No workouts logged yet.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int i) {
              final WorkoutLog l = list[i];
              final String dateStr = DateFormat.yMMMd().format(l.startTime);
              final int min = l.endTime.difference(l.startTime).inMinutes;
              return GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(l.sessionName, style: AppTextStyles.bodyLarge),
                    Text(
                      '$dateStr · $min min · ${l.totalCaloriesBurnt.round()} kcal',
                      style: AppTextStyles.bodySmall,
                    ),
                    if (l.fitcoinsEarned > 0)
                      Text(
                        '+${l.fitcoinsEarned} FTC',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryContainer,
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
}
