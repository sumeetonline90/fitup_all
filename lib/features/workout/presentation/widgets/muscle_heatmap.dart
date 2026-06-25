import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/muscle_group.dart';

/// Maps [MuscleGroup] counts to simplified UI regions (front/back diagram).
Map<String, int> muscleGroupsToRegionCounts(Map<MuscleGroup, int> freq) {
  int g(MuscleGroup mg) => freq[mg] ?? 0;
  return <String, int>{
    'chest': g(MuscleGroup.chest),
    'back': g(MuscleGroup.back),
    'shoulders': g(MuscleGroup.shoulders),
    'biceps': g(MuscleGroup.biceps),
    'triceps': g(MuscleGroup.triceps),
    'core': g(MuscleGroup.core),
    'glutes': g(MuscleGroup.glutes),
    'legs': g(MuscleGroup.quadriceps) +
        g(MuscleGroup.hamstrings) +
        g(MuscleGroup.calves),
  };
}

typedef MuscleFrequencyMap = Map<String, int>;

/// Simplified front/back silhouette with muscle regions colored by frequency.
class MuscleHeatmap extends StatefulWidget {
  const MuscleHeatmap({
    super.key,
    required this.muscleGroupFrequency,
    this.height = 280,
  });

  /// Per-muscle training frequency; aggregated for the body diagram.
  final Map<MuscleGroup, int> muscleGroupFrequency;
  final double height;

  @override
  State<MuscleHeatmap> createState() => _MuscleHeatmapState();
}

class _MuscleHeatmapState extends State<MuscleHeatmap> {
  bool _front = true;
  String? _tooltip;

  MuscleFrequencyMap get _regionCounts =>
      muscleGroupsToRegionCounts(widget.muscleGroupFrequency);

  Color _colorForCount(int? n) {
    final int c = n ?? 0;
    if (c <= 0) {
      return AppColors.surfaceContainerHighest;
    }
    if (c <= 2) {
      return AppColors.primaryContainer.withValues(alpha: 0.35);
    }
    if (c <= 4) {
      return AppColors.secondary.withValues(alpha: 0.55);
    }
    return AppColors.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              button: true,
              label: 'Front body view',
              child: FilterChip(
                label: Text('Front', style: AppTextStyles.labelSmall),
                selected: _front,
                onSelected: (_) => setState(() => _front = true),
                selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                checkmarkColor: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Back body view',
              child: FilterChip(
                label: Text('Back', style: AppTextStyles.labelSmall),
                selected: !_front,
                onSelected: (_) => setState(() => _front = false),
                selectedColor: AppColors.secondary.withValues(alpha: 0.25),
                checkmarkColor: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _tooltip ?? 'Focus areas this week',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Muscle group heatmap',
          child: SizedBox(
            height: widget.height,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (TapUpDetails d) {
                    final String? id = _hitTest(
                      d.localPosition,
                      Size(c.maxWidth, widget.height),
                      _front,
                    );
                    if (id != null) {
                      final int count = _regionCounts[id] ?? 0;
                      setState(
                        () => _tooltip =
                            '${_labelForId(id)}: $count sessions this week',
                      );
                    }
                  },
                  child: CustomPaint(
                    size: Size(c.maxWidth, widget.height),
                    painter: _MuscleHeatmapPainter(
                      front: _front,
                      frequencyByMuscle: _regionCounts,
                      colorForCount: _colorForCount,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

String _labelForId(String id) {
  return switch (id) {
    'chest' => 'Chest',
    'back' => 'Back',
    'shoulders' => 'Shoulders',
    'biceps' => 'Biceps',
    'triceps' => 'Triceps',
    'core' => 'Core',
    'legs' => 'Legs',
    'glutes' => 'Glutes',
    _ => id,
  };
}

String? _hitTest(Offset p, Size size, bool front) {
  final double w = size.width;
  final double h = size.height;
  final double cx = w / 2;
  final Rect head = Rect.fromCircle(center: Offset(cx, h * 0.08), radius: h * 0.05);
  if (head.contains(p)) {
    return null;
  }
  if (front) {
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.22),
      width: w * 0.38,
      height: h * 0.12,
    ).contains(p)) {
      return 'chest';
    }
    if (Rect.fromCenter(
      center: Offset(cx - w * 0.14, h * 0.18),
      width: w * 0.1,
      height: h * 0.08,
    ).contains(p)) {
      return 'shoulders';
    }
    if (Rect.fromCenter(
      center: Offset(cx + w * 0.14, h * 0.18),
      width: w * 0.1,
      height: h * 0.08,
    ).contains(p)) {
      return 'shoulders';
    }
    if (Rect.fromCenter(
      center: Offset(cx - w * 0.2, h * 0.32),
      width: w * 0.08,
      height: h * 0.14,
    ).contains(p)) {
      return 'biceps';
    }
    if (Rect.fromCenter(
      center: Offset(cx + w * 0.2, h * 0.32),
      width: w * 0.08,
      height: h * 0.14,
    ).contains(p)) {
      return 'biceps';
    }
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.42),
      width: w * 0.28,
      height: h * 0.1,
    ).contains(p)) {
      return 'core';
    }
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.68),
      width: w * 0.22,
      height: h * 0.28,
    ).contains(p)) {
      return 'legs';
    }
  } else {
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.24),
      width: w * 0.4,
      height: h * 0.14,
    ).contains(p)) {
      return 'back';
    }
    if (Rect.fromCenter(
      center: Offset(cx - w * 0.16, h * 0.18),
      width: w * 0.1,
      height: h * 0.08,
    ).contains(p)) {
      return 'shoulders';
    }
    if (Rect.fromCenter(
      center: Offset(cx + w * 0.16, h * 0.18),
      width: w * 0.1,
      height: h * 0.08,
    ).contains(p)) {
      return 'shoulders';
    }
    if (Rect.fromCenter(
      center: Offset(cx - w * 0.18, h * 0.34),
      width: w * 0.1,
      height: h * 0.12,
    ).contains(p)) {
      return 'triceps';
    }
    if (Rect.fromCenter(
      center: Offset(cx + w * 0.18, h * 0.34),
      width: w * 0.1,
      height: h * 0.12,
    ).contains(p)) {
      return 'triceps';
    }
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.72),
      width: w * 0.28,
      height: h * 0.2,
    ).contains(p)) {
      return 'glutes';
    }
    if (Rect.fromCenter(
      center: Offset(cx, h * 0.88),
      width: w * 0.18,
      height: h * 0.12,
    ).contains(p)) {
      return 'legs';
    }
  }
  return null;
}

class _MuscleHeatmapPainter extends CustomPainter {
  _MuscleHeatmapPainter({
    required this.front,
    required this.frequencyByMuscle,
    required this.colorForCount,
  });

  final bool front;
  final MuscleFrequencyMap frequencyByMuscle;
  final Color Function(int? n) colorForCount;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    final Paint outline = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    void drawOval(Rect r, String muscleId) {
      final int? n = frequencyByMuscle[muscleId];
      final Paint fill = Paint()
        ..color = colorForCount(n)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.2)), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.2)), outline);
    }

    canvas.drawCircle(Offset(cx, h * 0.08), h * 0.05, outline);

    if (front) {
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.22), width: w * 0.38, height: h * 0.12),
        'chest',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.14, h * 0.18), width: w * 0.12, height: h * 0.08),
        'shoulders',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.14, h * 0.18), width: w * 0.12, height: h * 0.08),
        'shoulders',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.2, h * 0.32), width: w * 0.1, height: h * 0.14),
        'biceps',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.2, h * 0.32), width: w * 0.1, height: h * 0.14),
        'biceps',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.42), width: w * 0.28, height: h * 0.1),
        'core',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.68), width: w * 0.24, height: h * 0.28),
        'legs',
      );
    } else {
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.24), width: w * 0.4, height: h * 0.14),
        'back',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.16, h * 0.18), width: w * 0.12, height: h * 0.08),
        'shoulders',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.16, h * 0.18), width: w * 0.12, height: h * 0.08),
        'shoulders',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx - w * 0.18, h * 0.34), width: w * 0.12, height: h * 0.12),
        'triceps',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx + w * 0.18, h * 0.34), width: w * 0.12, height: h * 0.12),
        'triceps',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.72), width: w * 0.3, height: h * 0.2),
        'glutes',
      );
      drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.88), width: w * 0.2, height: h * 0.12),
        'legs',
      );
    }

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'Tap a region',
        style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(8, h - 18));
  }

  @override
  bool shouldRepaint(covariant _MuscleHeatmapPainter oldDelegate) {
    return oldDelegate.front != front ||
        oldDelegate.frequencyByMuscle != frequencyByMuscle;
  }
}
