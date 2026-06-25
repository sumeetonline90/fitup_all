import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/onboarding_state.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_body_metrics_page.dart';
import '../widgets/onboarding_diet_prefs_page.dart';
import '../widgets/onboarding_fitness_level_page.dart';
import '../widgets/onboarding_goals_page.dart';
import '../widgets/onboarding_health_conditions_page.dart';

/// Five-step onboarding wizard (HTML prototype).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const List<String> _hints = <String>[
    'Select at least one goal to continue.',
    'Accurate metrics improve calorie and BMI estimates.',
    'You can change diet preferences anytime in Settings.',
    'Activity level helps us tune workouts and recovery.',
    'Review and tap Finish — welcome to Fitup.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<OnboardingState> async =
        ref.watch(onboardingNotifierProvider);
    return async.when(
      loading: () => const ColoredBox(
        color: AppColors.background,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => ColoredBox(
        color: AppColors.background,
        child: Center(child: Text('Could not load onboarding: $e')),
      ),
      data: (OnboardingState _) => const _OnboardingWizardBody(),
    );
  }
}

class _OnboardingWizardBody extends ConsumerWidget {
  const _OnboardingWizardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OnboardingState s =
        ref.watch(onboardingNotifierProvider).requireValue;
    final OnboardingNotifier n = ref.read(onboardingNotifierProvider.notifier);
    final int step = s.currentStep.clamp(0, 4);
    final double progress = (step + 1) / 5;

    Future<void> next() async {
      if (step < 4) {
        n.nextStep();
        return;
      }
      final bool ok = await n.complete();
      if (!context.mounted) {
        return;
      }
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save profile. Try again.')),
        );
        return;
      }
      context.go('/home');
    }

    Future<void> skip() async {
      final bool ok = await n.skip();
      if (!context.mounted) {
        return;
      }
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save profile. Try again.')),
        );
        return;
      }
      context.go('/home');
    }

    final bool canContinue =
        step == 0 ? s.goals.isNotEmpty : true;

    return ColoredBox(
      color: AppColors.background,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -80,
            top: -100,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      AppColors.primaryContainer.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: <Widget>[
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: step > 0 ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: step == 0,
                          child: IconButton(
                            onPressed: step > 0 ? n.prevStep : null,
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(5, (int i) {
                            final bool active = i == step;
                            final bool done = i < step;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: active ? 28 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: done || active
                                    ? AppColors.primaryContainer
                                    : AppColors.surfaceContainerHighest,
                                boxShadow: active
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color: AppColors.primaryContainer
                                              .withValues(alpha: 0.45),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                      TextButton(
                        onPressed: skip,
                        child: Text(
                          'Skip',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints bc) {
                      return Stack(
                        children: <Widget>[
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            width: bc.maxWidth * progress,
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: AppColors.secondaryToPrimaryGradient,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (Widget child, Animation<double> anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<int>(step),
                        child: _pageFor(step),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: FilledButton(
                          onPressed: canContinue ? next : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            step == 4 ? 'Start My Journey →' : 'Continue',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        OnboardingScreen._hints[step],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(int step) {
    switch (step) {
      case 0:
        return const OnboardingGoalsPage();
      case 1:
        return const OnboardingBodyMetricsPage();
      case 2:
        return const OnboardingDietPrefsPage();
      case 3:
        return const OnboardingFitnessLevelPage();
      case 4:
      default:
        return const OnboardingHealthConditionsPage();
    }
  }
}
