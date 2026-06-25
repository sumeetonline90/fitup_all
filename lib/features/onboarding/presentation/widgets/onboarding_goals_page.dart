import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

/// Step 1 — multi-select health goals.
class OnboardingGoalsPage extends ConsumerWidget {
  const OnboardingGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState s =
        ref.watch(onboardingNotifierProvider).requireValue;
    final OnboardingNotifier n = ref.read(onboardingNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Step 1 of 5',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
            children: <InlineSpan>[
              const TextSpan(text: 'What are your\n'),
              TextSpan(
                text: 'health goals?',
                style: AppTextStyles.headlineLarge.copyWith(
                  fontSize: 28,
                  color: AppColors.primaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pick all that apply — Fitup builds your personalised plan around them.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...HealthGoal.values.map((HealthGoal g) {
          final bool sel = s.goals.contains(g);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => n.toggleGoal(g),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderRadius: 16,
                glowColor: sel ? AppColors.primaryContainer : null,
                child: Row(
                  children: <Widget>[
                    Icon(
                      _iconFor(g),
                      color: sel ? AppColors.primaryContainer : AppColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            g.title,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g.subtitle,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  IconData _iconFor(HealthGoal g) {
    return switch (g) {
      HealthGoal.loseWeight => Icons.monitor_weight_outlined,
      HealthGoal.buildMuscle => Icons.fitness_center,
      HealthGoal.improveOverallHealth => Icons.favorite_outline,
      HealthGoal.mentalWellbeing => Icons.self_improvement_outlined,
      HealthGoal.improveFitness => Icons.directions_run,
      HealthGoal.manageHealthCondition => Icons.medical_services_outlined,
    };
  }
}
