import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fitup_chip.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

const List<String> _conditions = <String>[
  'Diabetes',
  'Hypertension',
  'Thyroid',
  'Asthma',
  'Heart condition',
  'PCOS',
];

/// Step 5 — disclaimer, conditions, medications, summary.
class OnboardingHealthConditionsPage extends ConsumerStatefulWidget {
  const OnboardingHealthConditionsPage({super.key});

  @override
  ConsumerState<OnboardingHealthConditionsPage> createState() =>
      _OnboardingHealthConditionsPageState();
}

class _OnboardingHealthConditionsPageState
    extends ConsumerState<OnboardingHealthConditionsPage> {
  late TextEditingController _meds;

  @override
  void initState() {
    super.initState();
    _meds = TextEditingController(
      text: ref.read(onboardingNotifierProvider).value?.medicationsNote ?? '',
    );
  }

  @override
  void dispose() {
    _meds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingState s =
        ref.watch(onboardingNotifierProvider).requireValue;
    final OnboardingNotifier n = ref.read(onboardingNotifierProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Step 5 of 5', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Health & safety',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.info_outline, color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fitup offers general wellness insights only — not medical '
                  'diagnosis. Consult a clinician for treatment decisions.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Conditions (optional)', style: AppTextStyles.labelLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _conditions.map((String c) {
            final bool sel = s.healthConditions.contains(c);
            return FitupChip(
              label: c,
              selected: sel,
              selectedColor: AppColors.tertiary,
              onTap: () {
                final List<String> next = List<String>.from(s.healthConditions);
                if (sel) {
                  next.remove(c);
                } else {
                  next.add(c);
                }
                n.setHealthConditions(conditions: next);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Medications / notes', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _meds,
          onChanged: (String v) {
            n.setHealthConditions(medicationsNote: v);
          },
          maxLines: 3,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Optional — stored privately',
            hintStyle: AppTextStyles.bodyMedium,
            filled: true,
            fillColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'You are all set',
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                '${s.goals.length} goals · ${_fitLabel(s.fitnessLevel)} · '
                '${s.dietType.label}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fitLabel(FitnessLevel f) => switch (f) {
        FitnessLevel.beginner => 'Beginner',
        FitnessLevel.intermediate => 'Intermediate',
        FitnessLevel.advanced => 'Advanced',
      };
}
