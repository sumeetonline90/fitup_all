import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Secondary CTA — cyber outline (Neon Fluidic).
class NeonOutlineButton extends StatelessWidget {
  const NeonOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
      ),
      child: Text(label, style: AppTextStyles.labelLarge),
    );
  }
}
