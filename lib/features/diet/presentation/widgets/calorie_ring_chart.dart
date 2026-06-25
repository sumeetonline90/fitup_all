import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Large ring: consumed vs target with zone coloring (under / near / over).
class CalorieRingChart extends StatelessWidget {
  const CalorieRingChart({
    super.key,
    required this.consumed,
    required this.target,
    this.size = 200,
    this.strokeWidth = 14,
  });

  final double consumed;
  final double target;
  final double size;
  final double strokeWidth;

  double get _ratio => target <= 0 ? 0 : (consumed / target).clamp(0.0, 1.5);

  Color get _ringColor {
    if (target <= 0) {
      return AppColors.onSurfaceVariant;
    }
    final double r = consumed / target;
    if (r < 0.85) {
      return AppColors.primaryContainer;
    }
    if (r < 1.0) {
      return AppColors.primary;
    }
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final String centerMain = consumed.round().toString();
    final String centerSub = target.round().toString();

    return Semantics(
      label: 'Calories $centerMain of $centerSub target',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: _ratio.clamp(0.0, 1.0),
                trackColor: AppColors.surfaceContainerHighest,
                progressColor: _ringColor,
                strokeWidth: strokeWidth,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  centerMain,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 40,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '/ $centerSub',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'kcal',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = (size.width / 2) - strokeWidth;
    const double start = -math.pi / 2;
    const double sweep = math.pi * 2;

    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Paint prog = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          progressColor,
          progressColor.withValues(alpha: 0.65),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: c, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      false,
      track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep * progress,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
