import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/correlation_alert.dart';

/// Cross-module insight row with severity accent and optional dismiss.
class CorrelationAlertCard extends StatefulWidget {
  const CorrelationAlertCard({super.key, required this.alert, this.onDismiss});

  final CorrelationAlert alert;
  final VoidCallback? onDismiss;

  @override
  State<CorrelationAlertCard> createState() => _CorrelationAlertCardState();
}

class _CorrelationAlertCardState extends State<CorrelationAlertCard> {
  bool _expanded = false;

  Color _borderColor(AlertSeverity s) {
    return switch (s) {
      AlertSeverity.info => AppColors.secondary,
      AlertSeverity.warning => AppColors.warningAmber,
      AlertSeverity.critical => AppColors.tertiary,
    };
  }

  IconData _typeIcon(AlertType t) {
    return switch (t) {
      AlertType.conflict => Icons.warning_amber_rounded,
      AlertType.recommendation => Icons.lightbulb_outline_rounded,
      AlertType.encouragement => Icons.favorite_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final CorrelationAlert a = widget.alert;
    final Color border = _borderColor(a.severity);
    return Semantics(
      label: '${a.title}. ${a.severity.name} ${a.type.name}',
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          key: const Key('correlation-accent-border'),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: border, width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(_typeIcon(a.type), color: border, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.onDismiss != null)
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: widget.onDismiss,
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  a.message,
                  style: AppTextStyles.bodySmall,
                  maxLines: _expanded ? null : 3,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                if (a.message.length > 120 || a.message.split('\n').length > 3)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Show less' : 'Show more'),
                  ),
                if (a.modules.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: a.modules
                        .map(
                          (String m) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(m, style: AppTextStyles.labelSmall),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
