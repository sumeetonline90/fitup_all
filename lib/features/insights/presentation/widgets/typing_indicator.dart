import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Three-dot pulse while the coach responds.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40),
      child: Row(
        children: <Widget>[
          Text('Fitup AI is thinking', style: AppTextStyles.bodySmall),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _c,
            builder: (BuildContext context, Widget? child) {
              final double t = _c.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (int i) {
                  final double o = ((t + i * 0.2) % 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Opacity(
                      opacity: 0.25 + 0.75 * o,
                      child: Text(
                        '·',
                        style: AppTextStyles.headlineMedium.copyWith(
                          height: 1,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
