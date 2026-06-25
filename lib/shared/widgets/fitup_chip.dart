import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Selectable pill chip (onboarding, profile, edit).
class FitupChip extends StatelessWidget {
  const FitupChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.leadingIcon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final IconData? leadingIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color accent = selectedColor ?? AppColors.primaryContainer;
    return Semantics(
      selected: selected,
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 18,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? accent : AppColors.glassBorder,
              ),
              color: selected
                  ? accent.withValues(alpha: 0.12)
                  : AppColors.surfaceContainer.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: selected ? accent : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontSize: compact ? 12 : 14,
                    color: selected ? accent : AppColors.onBackground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
