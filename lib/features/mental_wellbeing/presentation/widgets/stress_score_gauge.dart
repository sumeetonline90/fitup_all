import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Arc stroke color for [score] (shared with [StressScoreGauge] painter).
Color stressGaugeArcColorForScore(int score) {
  final int s = score.clamp(0, 100);
  if (s > 75) {
    return AppColors.error;
  }
  if (s > 50) {
    return AppColors.primary;
  }
  if (s > 25) {
    return AppColors.primaryContainer;
  }
  return AppColors.secondary;
}

/// Circular gauge 0–100 with green → amber → red sweep.
class StressScoreGauge extends StatelessWidget {
  const StressScoreGauge({super.key, required this.score, this.size = 140});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int clamped = score.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(progress: clamped / 100, score: clamped),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.score});

  final double progress;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 8;
    final Paint track = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 1.25,
      math.pi * 1.5,
      false,
      track,
    );
    final Paint fill = Paint()
      ..color = stressGaugeArcColorForScore(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi * 1.25,
      math.pi * 1.5 * progress,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.score != score;
  }
}
