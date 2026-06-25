import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

/// Step 4 — fitness level + activity level.
class OnboardingFitnessLevelPage extends ConsumerWidget {
  const OnboardingFitnessLevelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState s =
        ref.watch(onboardingNotifierProvider).requireValue;
    final OnboardingNotifier n = ref.read(onboardingNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Step 4 of 5', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Fitness & activity',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'We calibrate intensity and recovery around your baseline.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text('Experience level', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        ...FitnessLevel.values.map((FitnessLevel f) {
          final bool sel = s.fitnessLevel == f;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => n.setFitness(f, s.activityLevel),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                glowColor: sel ? AppColors.secondary : null,
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.bolt_outlined,
                      color: sel ? AppColors.secondary : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _fitLabel(f),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          Text(
                            _fitSub(f),
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
        const SizedBox(height: 8),
        Text('Typical day', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ActivityLevel.values.map((ActivityLevel a) {
            final bool sel = s.activityLevel == a;
            return ChoiceChip(
              label: Text(a.label),
              selected: sel,
              onSelected: (_) => n.setFitness(s.fitnessLevel, a),
              selectedColor: AppColors.primaryContainer.withValues(alpha: 0.25),
              labelStyle: AppTextStyles.labelLarge.copyWith(
                color: sel ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _fitLabel(FitnessLevel f) => switch (f) {
        FitnessLevel.beginner => 'Beginner',
        FitnessLevel.intermediate => 'Intermediate',
        FitnessLevel.advanced => 'Advanced',
      };

  String _fitSub(FitnessLevel f) => switch (f) {
        FitnessLevel.beginner => 'New to structured training',
        FitnessLevel.intermediate => 'Consistent training',
        FitnessLevel.advanced => 'High volume or performance',
      };
}
