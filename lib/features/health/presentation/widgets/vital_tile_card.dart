import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_category.dart';
import '../../domain/entities/vital_status.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';
import 'vital_status_colors.dart';

IconData vitalTypeIcon(VitalType t) {
  if (t.name.contains('blood') ||
      t.name.contains('Cholesterol') ||
      t.name.contains('glucose') ||
      t.name.contains('Sugar') ||
      t == VitalType.hba1c) {
    return Icons.bloodtype_outlined;
  }
  if (t.category.name.contains('thyroid')) {
    return Icons.medical_information_outlined;
  }
  if (t.category.name.contains('vitals') ||
      t == VitalType.heartRate ||
      t == VitalType.spO2) {
    return Icons.monitor_heart_outlined;
  }
  return Icons.analytics_outlined;
}

/// Summary tile for one [VitalType] on the health grid.
class VitalTileCard extends StatelessWidget {
  const VitalTileCard({super.key, required this.tile, required this.onTap});

  final VitalSummaryTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final VitalType t = tile.type;
    final _VitalPalette palette = _paletteFor(t.category);
    final Color valueColor = tile.status == VitalStatus.unknown
        ? AppColors.onSurface
        : palette.value;
    return Semantics(
      button: true,
      label:
          '${t.displayName}. ${tile.hasData ? '${tile.latestValue} ${t.unit}' : 'No data'}. Tap to see trend.',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                palette.background.withValues(alpha: 0.22),
                AppColors.surfaceContainerHigh,
              ],
            ),
            border: Border.all(color: palette.border.withValues(alpha: 0.45)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: palette.background.withValues(alpha: 0.25),
                blurRadius: 14,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(vitalTypeIcon(t), color: palette.icon, size: 22),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: vitalStatusColor(tile.status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.displayName,
                  style: AppTextStyles.labelSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (tile.hasData && tile.latestValue != null)
                  Text(
                    '${tile.latestValue!.toStringAsFixed(tile.latestValue! == tile.latestValue!.roundToDouble() ? 0 : 1)} ${t.unit}',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 16,
                      color: valueColor,
                    ),
                  )
                else
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: palette.icon,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Log first reading',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: palette.icon,
                          ),
                        ),
                      ),
                    ],
                  ),
                Text(
                  'Tap to see trend',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalPalette {
  const _VitalPalette({
    required this.background,
    required this.border,
    required this.icon,
    required this.value,
  });

  final Color background;
  final Color border;
  final Color icon;
  final Color value;
}

_VitalPalette _paletteFor(VitalCategory c) {
  return switch (c) {
    VitalCategory.vitalsAndWearable => const _VitalPalette(
      background: AppColors.secondary,
      border: AppColors.secondaryDim,
      icon: AppColors.secondary,
      value: AppColors.primary,
    ),
    VitalCategory.bloodSugar => const _VitalPalette(
      background: AppColors.tertiary,
      border: AppColors.tertiaryContainer,
      icon: AppColors.tertiary,
      value: AppColors.primary,
    ),
    VitalCategory.lipids => const _VitalPalette(
      background: AppColors.warningAmber,
      border: AppColors.warningAmber,
      icon: AppColors.warningAmber,
      value: AppColors.primary,
    ),
    VitalCategory.thyroid => const _VitalPalette(
      background: AppColors.primaryContainer,
      border: AppColors.primaryDim,
      icon: AppColors.primaryContainer,
      value: AppColors.primary,
    ),
    VitalCategory.vitaminsAndIron => const _VitalPalette(
      background: AppColors.secondaryDim,
      border: AppColors.secondary,
      icon: AppColors.secondary,
      value: AppColors.primary,
    ),
    VitalCategory.liver => const _VitalPalette(
      background: AppColors.tertiaryContainer,
      border: AppColors.tertiary,
      icon: AppColors.tertiary,
      value: AppColors.primary,
    ),
    VitalCategory.kidney => const _VitalPalette(
      background: AppColors.primaryDim,
      border: AppColors.primaryContainer,
      icon: AppColors.primaryContainer,
      value: AppColors.primary,
    ),
    VitalCategory.bloodCount => const _VitalPalette(
      background: AppColors.secondary,
      border: AppColors.secondary,
      icon: AppColors.secondary,
      value: AppColors.primary,
    ),
    VitalCategory.electrolytes => const _VitalPalette(
      background: AppColors.warningAmber,
      border: AppColors.warningAmber,
      icon: AppColors.warningAmber,
      value: AppColors.primary,
    ),
  };
}
