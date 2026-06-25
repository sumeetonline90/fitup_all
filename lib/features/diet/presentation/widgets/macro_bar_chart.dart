import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Three horizontal macro bars: protein, carbs, fat.
class MacroBarChart extends StatelessWidget {
  const MacroBarChart({
    super.key,
    required this.proteinG,
    required this.proteinTargetG,
    required this.carbsG,
    required this.carbsTargetG,
    required this.fatG,
    required this.fatTargetG,
  });

  final double proteinG;
  final double proteinTargetG;
  final double carbsG;
  final double carbsTargetG;
  final double fatG;
  final double fatTargetG;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Macronutrients breakdown',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MacroRow(
            label: 'Protein',
            current: proteinG,
            target: proteinTargetG,
            fillColor: AppColors.secondary,
            tooltip: 'Protein grams',
          ),
          const SizedBox(height: 10),
          _MacroRow(
            label: 'Carbs',
            current: carbsG,
            target: carbsTargetG,
            fillColor: AppColors.tertiary,
            tooltip: 'Carbohydrate grams',
          ),
          const SizedBox(height: 10),
          _MacroRow(
            label: 'Fat',
            current: fatG,
            target: fatTargetG,
            fillColor: AppColors.primary,
            tooltip: 'Fat grams',
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
    required this.fillColor,
    required this.tooltip,
  });

  final String label;
  final double current;
  final double target;
  final Color fillColor;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final double t = target <= 0 ? 1 : target;
    final double p = (current / t).clamp(0.0, 1.0);

    return Tooltip(
      message: tooltip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(label, style: AppTextStyles.labelSmall),
              Text(
                '${current.round()}g / ${target.round()}g',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: p),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double v, Widget? child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
