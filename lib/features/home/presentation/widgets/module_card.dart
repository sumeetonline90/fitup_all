import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Bento dashboard tile — glass + accent glow.
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryMetric,
    required this.secondaryMetric,
    required this.accentColor,
    this.onTap,
    this.progress,
    this.ringProgress,
    this.semanticsLabel,
  });

  final String title;
  final IconData icon;
  final String primaryMetric;
  final String secondaryMetric;
  final Color accentColor;
  final VoidCallback? onTap;

  /// 0–1 for optional linear progress (e.g. steps vs goal).
  final double? progress;

  /// Optional top-right circular progress (0–1), same scale as [progress].
  final double? ringProgress;

  /// Overrides the default TalkBack/VoiceOver label for the tappable region.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final String defaultLabel = '$title. $primaryMetric. $secondaryMetric';
    return Material(
      color: Colors.transparent,
      child: Semantics(
        button: onTap != null,
        label: semanticsLabel ?? defaultLabel,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: GlassCard(
            glowColor: accentColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: accentColor, size: 28),
                    ),
                    if (ringProgress != null)
                      _ModuleRingGauge(
                        progress: ringProgress!.clamp(0.0, 1.0),
                        color: accentColor,
                      )
                    else
                      const Icon(
                        Icons.north_east,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  primaryMetric,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(secondaryMetric, style: AppTextStyles.bodyMedium),
                if (progress != null) ...<Widget>[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      backgroundColor: AppColors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 6,
                    ),
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

class _ModuleRingGauge extends StatelessWidget {
  const _ModuleRingGauge({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int pct = (progress * 100).clamp(0, 100).round();
    return Semantics(
      label: '$pct percent',
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3.5,
                backgroundColor: AppColors.surfaceContainerHighest,
                color: color,
              ),
            ),
            Text(
              '$pct%',
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
