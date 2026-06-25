import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Centered app mark — dark rounded plate behind logo for transparent PNGs.
class FitupLogo extends StatelessWidget {
  const FitupLogo({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(size * 0.22),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.bolt,
              size: size * 0.45,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
