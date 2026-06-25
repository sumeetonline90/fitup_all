import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/breathing_pattern.dart';

/// Pick a breathing technique.
class BreathingScreen extends StatelessWidget {
  const BreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Breathing', style: AppTextStyles.headlineMedium),
        backgroundColor: AppColors.surfaceContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final BreathingPattern p in BreathingPattern.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () =>
                    context.push('/mental/breathing/session', extra: p),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(p.title, style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 6),
                      Text(p.subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
