import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Single module narrative inside weekly report tabs.
class ModuleInsightTab extends StatelessWidget {
  const ModuleInsightTab({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassCard(
        child: Text(
          text.isEmpty ? 'No insight for this module yet.' : text,
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }
}
