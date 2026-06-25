import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Seven-day calorie bars with target reference; tap reports day index.
class WeeklyNutritionChart extends StatelessWidget {
  const WeeklyNutritionChart({
    super.key,
    required this.dailyCalories,
    required this.targetCalories,
    this.onDayTap,
    this.height = 200,
  });

  /// Length 7 (Mon–Sun), calories per day.
  final List<double> dailyCalories;
  final double targetCalories;
  final void Function(int dayIndex)? onDayTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (dailyCalories.length != 7) {
      return const SizedBox.shrink();
    }
    final double maxY = <double>[
      ...dailyCalories,
      targetCalories,
    ].reduce((double a, double b) => a > b ? a : b);

    return Semantics(
      label: 'Weekly calories chart, tap a bar for day detail',
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.12,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: ExtraLinesData(
              horizontalLines: targetCalories > 0
                  ? <HorizontalLine>[
                      HorizontalLine(
                        y: targetCalories,
                        color: AppColors.secondary.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: <int>[4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: AppTextStyles.bodySmall,
                          labelResolver: (_) => 'Target',
                        ),
                      ),
                    ]
                  : <HorizontalLine>[],
            ),
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
                  reservedSize: 36,
                  getTitlesWidget: (double v, TitleMeta m) {
                    return Text(
                      v.round().toString(),
                      style: AppTextStyles.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (double v, TitleMeta m) {
                    const List<String> days = <String>[
                      'M',
                      'T',
                      'W',
                      'T',
                      'F',
                      'S',
                      'S',
                    ];
                    final int i = v.toInt().clamp(0, 6);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(days[i], style: AppTextStyles.bodySmall),
                    );
                  },
                ),
              ),
            ),
            barGroups: List<BarChartGroupData>.generate(7, (int i) {
              final double cal = dailyCalories[i];
              final bool over =
                  targetCalories > 0 && cal > targetCalories;
              final Color c = over ? AppColors.error : AppColors.secondary;
              return BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: cal,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    color: c,
                  ),
                ],
              );
            }),
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: (FlTouchEvent event, BarTouchResponse? r) {
                final int? x = r?.spot?.touchedBarGroupIndex;
                if (x != null) {
                  onDayTap?.call(x);
                }
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem:
                    (BarChartGroupData g, int gIndex, BarChartRodData rod, int i) {
                  return BarTooltipItem(
                    '${rod.toY.round()} kcal',
                    AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
