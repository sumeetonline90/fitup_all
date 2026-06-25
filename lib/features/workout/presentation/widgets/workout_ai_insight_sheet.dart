import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../providers/workout_providers.dart';

/// Bottom sheet: AI workout analysis (Gemini).
Future<void> showWorkoutAiInsightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const WorkoutAiInsightSheet(),
  );
}

class WorkoutAiInsightSheet extends ConsumerStatefulWidget {
  const WorkoutAiInsightSheet({super.key});

  @override
  ConsumerState<WorkoutAiInsightSheet> createState() =>
      _WorkoutAiInsightSheetState();
}

class _WorkoutAiInsightSheetState extends ConsumerState<WorkoutAiInsightSheet> {
  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<String> insight =
        ref.watch(workoutInsightProvider(const <String>[]));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (BuildContext context, ScrollController scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
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
              Row(
                children: <Widget>[
                  Text('💪', style: AppTextStyles.headlineMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Workout Analysis',
                      style: AppTextStyles.headlineMedium,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Refresh workout insight',
                    child: IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => ref.invalidate(
                        workoutInsightProvider(const <String>[]),
                      ),
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              insight.when(
                loading: () => const _LoadingBody(),
                error: (Object e, StackTrace _) => Text(
                  'Could not load insight.',
                  style: AppTextStyles.bodyMedium,
                ),
                data: (String text) => Text(
                  text,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Ask AI about this'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(
                    '/insights/chat',
                    extra: <String, String>{'moduleContext': 'Workout'},
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Suggestions are not medical advice.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const ShimmerLoading(height: 20, borderRadius: 8),
        const SizedBox(height: 12),
        const ShimmerLoading(height: 60, borderRadius: 12),
        const SizedBox(height: 12),
        const ShimmerLoading(height: 60, borderRadius: 12),
        const SizedBox(height: 12),
        Text(
          'AI is analyzing your training…',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
