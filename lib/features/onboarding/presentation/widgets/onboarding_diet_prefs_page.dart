import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fitup_chip.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

const List<String> _cuisines = <String>[
  'Indian',
  'Italian',
  'Chinese',
  'Mexican',
  'Mediterranean',
  'Japanese',
];

const List<String> _allergies = <String>[
  'Nuts',
  'Dairy',
  'Gluten',
  'Shellfish',
  'Eggs',
  'Soy',
];

/// Step 3 — diet type + cuisines + allergies.
class OnboardingDietPrefsPage extends ConsumerWidget {
  const OnboardingDietPrefsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState s =
        ref.watch(onboardingNotifierProvider).requireValue;
    final OnboardingNotifier n = ref.read(onboardingNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Step 3 of 5', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Diet preferences',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'Helps us tailor meal ideas and macro targets.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text('Diet type', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DietType.values.map((DietType d) {
            return FitupChip(
              label: d.label,
              selected: s.dietType == d,
              onTap: () => n.setDietPrefs(dietType: d),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Cuisines you enjoy', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _cuisines.map((String c) {
            final bool sel = s.cuisines.contains(c);
            return FitupChip(
              label: c,
              selected: sel,
              onTap: () {
                final List<String> next = List<String>.from(s.cuisines);
                if (sel) {
                  next.remove(c);
                } else {
                  next.add(c);
                }
                n.setDietPrefs(cuisines: next);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Allergies', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allergies.map((String a) {
            final bool sel = s.allergies.contains(a);
            return FitupChip(
              label: a,
              selected: sel,
              selectedColor: AppColors.tertiary,
              onTap: () {
                final List<String> next = List<String>.from(s.allergies);
                if (sel) {
                  next.remove(a);
                } else {
                  next.add(a);
                }
                n.setDietPrefs(allergies: next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
