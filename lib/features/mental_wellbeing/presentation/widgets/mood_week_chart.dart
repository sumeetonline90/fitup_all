import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Seven-day mood bar chart (heights 0–4).
class MoodWeekChart extends StatelessWidget {
  const MoodWeekChart({super.key, required this.levels});

  final List<int> levels;

  @override
  Widget build(BuildContext context) {
    if (levels.length != 7) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 4,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (double v, TitleMeta m) {
                  if (v != v.roundToDouble()) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${v.toInt()}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (double v, TitleMeta m) {
                  const List<String> d = <String>[
                    'M',
                    'T',
                    'W',
                    'T',
                    'F',
                    'S',
                    'S',
                  ];
                  final int i = v.toInt();
                  if (i < 0 || i >= 7) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      d[i],
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List<BarChartGroupData>.generate(7, (int i) {
            final int h = levels[i].clamp(0, 4);
            final Color col = h <= 1
                ? AppColors.error.withValues(alpha: 0.85)
                : h == 2
                ? AppColors.primary
                : h == 3
                ? AppColors.secondary
                : AppColors.primaryContainer;
            return BarChartGroupData(
              x: i,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: h.toDouble(),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  color: col,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
