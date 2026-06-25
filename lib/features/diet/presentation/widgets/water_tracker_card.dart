import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Water tracker with +/− glass stepper (250 ml per glass).
class WaterTrackerCard extends StatefulWidget {
  const WaterTrackerCard({
    super.key,
    required this.currentMl,
    required this.targetMl,
    this.onAddMl,
    this.onRemoveMl,
  });

  final double currentMl;
  final double targetMl;
  final void Function(double ml)? onAddMl;
  final void Function(double ml)? onRemoveMl;

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard>
    with SingleTickerProviderStateMixin {
  static const double _glassMl = 250;

  late AnimationController _pulse;
  double _flashOpacity = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _bump() {
    setState(() => _flashOpacity = 1);
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _flashOpacity = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double ratio = widget.targetMl <= 0
        ? 0
        : (widget.currentMl / widget.targetMl).clamp(0.0, 1.0);
    final int glasses = (widget.currentMl / _glassMl).round();

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      glowColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('Water', style: AppTextStyles.headlineMedium),
              Text(
                '${widget.currentMl.round()} / ${widget.targetMl.round()} ml',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Semantics(
              label: 'Water level ${(ratio * 100).round()} percent',
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      CustomPaint(
                        size: const Size(120, 180),
                        painter: _WaterGlassPainter(
                          fillFraction: ratio,
                          wave: _pulse.value,
                          waterColor: AppColors.secondary,
                          glassBorder: AppColors.glassBorder,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _flashOpacity,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          '+',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _StepperButton(
                icon: Icons.remove_rounded,
                tooltip: 'Remove 1 glass (250 ml)',
                enabled: widget.currentMl > 0,
                onPressed: () {
                  widget.onRemoveMl?.call(_glassMl);
                },
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$glasses',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 36,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    glasses == 1 ? 'glass' : 'glasses',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              _StepperButton(
                icon: Icons.add_rounded,
                tooltip: 'Add 1 glass (250 ml)',
                enabled: true,
                onPressed: () {
                  widget.onAddMl?.call(_glassMl);
                  _bump();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              icon,
              color: enabled ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  _WaterGlassPainter({
    required this.fillFraction,
    required this.wave,
    required this.waterColor,
    required this.glassBorder,
  });

  final double fillFraction;
  final double wave;
  final Color waterColor;
  final Color glassBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect outer = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );
    final Paint border = Paint()
      ..color = glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(outer, border);

    final double h = size.height * fillFraction.clamp(0.0, 1.0);
    if (h <= 0) {
      return;
    }
    final double waveY = 4 * wave;
    final Path water = Path()
      ..moveTo(4, size.height - h + waveY)
      ..quadraticBezierTo(
        size.width / 2,
        size.height - h - 6 + waveY,
        size.width - 4,
        size.height - h + waveY,
      )
      ..lineTo(size.width - 4, size.height - 4)
      ..lineTo(4, size.height - 4)
      ..close();

    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          waterColor.withValues(alpha: 0.45),
          waterColor.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.save();
    canvas.clipRRect(outer);
    canvas.drawPath(water, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction ||
        oldDelegate.wave != wave;
  }
}
