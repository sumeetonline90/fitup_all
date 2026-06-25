import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated pill toggle — track + thumb use [AppColors].
class FitupToggle extends StatelessWidget {
  const FitupToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final Color on = activeColor ?? AppColors.primaryContainer;
    return Semantics(
      toggled: value,
      label: 'Toggle',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: value
                ? on.withValues(alpha: 0.35)
                : AppColors.surfaceContainerHighest,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? on : AppColors.onSurfaceVariant,
                boxShadow: value
                    ? <BoxShadow>[
                        BoxShadow(
                          color: on.withValues(alpha: 0.45),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
