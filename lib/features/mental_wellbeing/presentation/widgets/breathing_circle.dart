import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Animated breathing orb with phase label and countdown.
class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.scale,
    required this.phaseLabel,
    required this.secondsLeft,
    required this.phaseProgress,
  });

  /// 0.6–1.0 typical scale for the inner orb.
  final double scale;
  final String phaseLabel;
  final int secondsLeft;
  final double phaseProgress;

  @override
  Widget build(BuildContext context) {
    final double side = 220 * scale.clamp(0.4, 1.2);
    final List<Color> gradientColors = switch (phaseLabel) {
      'Inhale' => <Color>[
        AppColors.secondary,
        AppColors.secondaryDim.withValues(alpha: 0.35),
      ],
      'Hold' => <Color>[
        AppColors.primary,
        AppColors.primaryContainer.withValues(alpha: 0.45),
      ],
      _ => <Color>[
        AppColors.tertiary,
        AppColors.tertiaryContainer.withValues(alpha: 0.45),
      ],
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size(260, 260),
                painter: _RingPainter(progress: phaseProgress),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                width: side,
                height: side,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: gradientColors),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(phaseLabel, style: AppTextStyles.headlineMedium),
                  Text(
                    '$secondsLeft',
                    style: AppTextStyles.headlineLarge.copyWith(fontSize: 42),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 4;
    final Paint bg = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, r, bg);
    final Paint fg = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -3.14159 / 2,
      3.14159 * 2 * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
