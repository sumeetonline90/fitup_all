import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

/// Step 2 — gender, DOB, height, weight, units.
class OnboardingBodyMetricsPage extends ConsumerStatefulWidget {
  const OnboardingBodyMetricsPage({super.key});

  @override
  ConsumerState<OnboardingBodyMetricsPage> createState() =>
      _OnboardingBodyMetricsPageState();
}

class _OnboardingBodyMetricsPageState
    extends ConsumerState<OnboardingBodyMetricsPage> {
  late TextEditingController _h;
  late TextEditingController _w;
  late TextEditingController _tw;

  @override
  void initState() {
    super.initState();
    final OnboardingState s =
        ref.read(onboardingNotifierProvider).requireValue;
    _h = TextEditingController(text: s.heightCm.toStringAsFixed(0));
    _w = TextEditingController(text: s.weightKg.toStringAsFixed(1));
    _tw = TextEditingController(
      text: s.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _h.dispose();
    _w.dispose();
    _tw.dispose();
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
        Text('Step 2 of 5', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 8),
        Text(
          'Your body metrics',
          style: AppTextStyles.headlineLarge.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 12),
        Text(
          'We use this to calculate calories, BMI, and personalised targets.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text('Gender', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: ProfileGender.values.map((ProfileGender g) {
            final bool sel = s.gender == g;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => n.setBodyMetrics(gender: g),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel
                              ? AppColors.primaryContainer
                              : AppColors.glassBorder,
                        ),
                        color: sel
                            ? AppColors.primaryContainer.withValues(alpha: 0.08)
                            : AppColors.surfaceContainer.withValues(alpha: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _genderLabel(g),
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 13,
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Text('Date of birth', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            s.dateOfBirth == null
                ? 'Select date'
                : MaterialLocalizations.of(context).formatFullDate(
                    s.dateOfBirth!,
                  ),
            style: AppTextStyles.bodyLarge,
          ),
          trailing: const Icon(Icons.calendar_month, color: AppColors.secondary),
          onTap: () async {
            final DateTime now = DateTime.now();
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: s.dateOfBirth ?? DateTime(now.year - 25),
              firstDate: DateTime(1900),
              lastDate: now,
            );
            if (picked != null) {
              n.setBodyMetrics(dateOfBirth: picked);
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _metricField(
                label: s.useMetricUnits ? 'Height (cm)' : 'Height (ft)',
                controller: _h,
                onChanged: (String v) {
                  final double? x = double.tryParse(v);
                  if (x != null) {
                    n.setBodyMetrics(heightCm: x);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricField(
                label: s.useMetricUnits ? 'Weight (kg)' : 'Weight (lb)',
                controller: _w,
                onChanged: (String v) {
                  final double? x = double.tryParse(v);
                  if (x != null) {
                    n.setBodyMetrics(weightKg: x);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricField(
          label: 'Target weight (optional)',
          controller: _tw,
          onChanged: (String v) {
            final double? x = double.tryParse(v);
            n.setBodyMetrics(targetWeightKg: x);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Text('Units', style: AppTextStyles.labelLarge),
            const Spacer(),
            ToggleButtons(
              isSelected: <bool>[
                s.useMetricUnits,
                !s.useMetricUnits,
              ],
              onPressed: (int i) {
                n.setBodyMetrics(useMetricUnits: i == 0);
              },
              borderRadius: BorderRadius.circular(999),
              selectedColor: AppColors.primaryContainer,
              fillColor: AppColors.primaryContainer.withValues(alpha: 0.2),
              color: AppColors.onSurfaceVariant,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Metric'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Imperial'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _genderLabel(ProfileGender g) => switch (g) {
        ProfileGender.male => 'Male',
        ProfileGender.female => 'Female',
        ProfileGender.other => 'Other',
      };

  Widget _metricField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTextStyles.labelSmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainer.withValues(alpha: 0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.glassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryContainer),
            ),
          ),
        ),
      ],
    );
  }
}
