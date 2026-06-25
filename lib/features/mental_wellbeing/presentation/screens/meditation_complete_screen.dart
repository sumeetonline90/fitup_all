import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/neon_outline_button.dart';

/// Shown after a completed meditation timer.
class MeditationCompleteScreen extends StatelessWidget {
  const MeditationCompleteScreen({super.key, required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(),
              Text(
                'You meditated for $minutes minutes 🧘',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  'assets/animations/celebration.json',
                  repeat: false,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.self_improvement,
                    size: 120,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const Spacer(),
              NeonOutlineButton(
                label: 'Back to Wellbeing',
                onPressed: () => context.go('/mental'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
