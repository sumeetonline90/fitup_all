import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';

/// One AI-extracted vital row with include toggle and type chip.
class LabScanResultTile extends StatelessWidget {
  const LabScanResultTile({
    super.key,
    required this.row,
    required this.onIncludedChanged,
  });

  final ExtractedVitalRow row;
  final ValueChanged<bool> onIncludedChanged;

  @override
  Widget build(BuildContext context) {
    final VitalType? mapped = row.mappedType;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Checkbox(
            value: row.included,
            onChanged: (bool? v) => onIncludedChanged(v ?? false),
            activeColor: AppColors.secondary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  row.name,
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.value.toStringAsFixed(row.value == row.value.roundToDouble() ? 0 : 1)} ${row.unit}',
                  style: AppTextStyles.bodyMedium,
                ),
                if (row.isDuplicate) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    'Duplicate mapping — uncheck or keep the value you prefer.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warningAmber,
                    ),
                  ),
                ],
                if (mapped != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Chip(
                    label: Text(
                      mapped.displayName,
                      style: AppTextStyles.labelSmall,
                    ),
                    backgroundColor: AppColors.surfaceContainer.withValues(
                      alpha: 0.8,
                    ),
                    side: BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
