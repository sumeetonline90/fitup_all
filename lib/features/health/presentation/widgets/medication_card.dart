import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../health_ui_models.dart';

/// One active medication row for lists and dashboards.
class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.medication,
    this.onLongPress,
  });

  final MedicationUi medication;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final String? next = medication.nextReminder == null
        ? null
        : 'Next: ${DateFormat.jm().format(medication.nextReminder!)}';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: onLongPress,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(Icons.medication_outlined, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    medication.name,
                    style: AppTextStyles.headlineMedium.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${medication.dose} · ${medication.frequency}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (next != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(next, style: AppTextStyles.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
