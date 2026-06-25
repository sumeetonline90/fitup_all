import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Circular progress ring showing today's calorie burn vs daily target.
class DailyCalorieBurnRing extends StatelessWidget {
  const DailyCalorieBurnRing({
    super.key,
    required this.burned,
    required this.target,
  });

  final double burned;
  final int target;

  @override
  Widget build(BuildContext context) {
    final double pct = target > 0 ? (burned / target).clamp(0.0, 1.5) : 0;

    return GlassCard(
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _RingPainter(pct),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      burned.round().toString(),
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 22,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Today's Burn",
                  style: AppTextStyles.headlineMedium.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  '${burned.round()} / $target kcal',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  pct >= 1.0 ? 'Goal reached!' : '${(pct * 100).round()}% of daily goal',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pct >= 1.0 ? AppColors.primaryContainer : AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 8;
    final Rect rect = Offset.zero & size;
    final Rect inset = rect.deflate(strokeWidth / 2);

    final Paint bg = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, -math.pi / 2, 2 * math.pi, false, bg);

    if (progress <= 0) return;

    final Paint fg = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[AppColors.secondary, AppColors.primaryContainer],
      ).createShader(inset)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(inset, -math.pi / 2, sweep, false, fg);

    // Neon glow layer
    final Paint glow = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[AppColors.secondary, AppColors.primaryContainer],
      ).createShader(inset)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(inset, -math.pi / 2, sweep, false, glow);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.progress != progress;
}
