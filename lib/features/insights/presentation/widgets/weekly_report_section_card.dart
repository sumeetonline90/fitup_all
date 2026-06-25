import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Titled glass block for weekly report sections.
class WeeklyReportSectionCard extends StatelessWidget {
  const WeeklyReportSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.titleColor,
  });

  final String title;
  final Widget child;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 18,
              color: titleColor ?? AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
