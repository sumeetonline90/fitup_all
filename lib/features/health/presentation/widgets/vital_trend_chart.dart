import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/vital_reference.dart';
import '../../domain/entities/vital_status.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../health_ui_models.dart';
import 'vital_status_colors.dart';

/// Line chart for vital history with optional normal-range band.
class VitalTrendChart extends StatelessWidget {
  const VitalTrendChart({
    super.key,
    required this.type,
    required this.entriesAscending,
    this.touchedIndex,
    this.onTouch,
  });

  final VitalType type;
  final List<VitalReadingEntry> entriesAscending;
  final int? touchedIndex;
  final void Function(int index)? onTouch;

  @override
  Widget build(BuildContext context) {
    if (entriesAscending.isEmpty) {
      return Center(
        child: Text(
          'No readings yet',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final List<double> ys =
        entriesAscending.map((VitalReadingEntry e) => e.value).toList();
    double minY = ys.reduce((double a, double b) => a < b ? a : b);
    double maxY = ys.reduce((double a, double b) => a > b ? a : b);
    final VitalRefRange? band = normalRangeFor(type);
    if (band != null) {
      minY = minY < band.min ? minY : band.min;
      maxY = maxY > band.max ? maxY : band.max;
    }
    double pad = (maxY - minY).abs() < 1e-6 ? 1.0 : (maxY - minY) * 0.12;
    minY -= pad;
    maxY += pad;

    final List<FlSpot> spots = List<FlSpot>.generate(
      entriesAscending.length,
      (int i) => FlSpot(i.toDouble(), entriesAscending[i].value),
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (entriesAscending.length - 1).toDouble().clamp(0, double.infinity),
        minY: minY,
        maxY: maxY,
        rangeAnnotations: band == null
            ? const RangeAnnotations()
            : RangeAnnotations(
                horizontalRangeAnnotations: <HorizontalRangeAnnotation>[
                  HorizontalRangeAnnotation(
                    y1: band.min,
                    y2: band.max,
                    color: AppColors.primaryContainer.withValues(alpha: 0.22),
                  ),
                ],
              ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
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
              reservedSize: 40,
              getTitlesWidget: (double v, TitleMeta m) => Text(
                v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1),
                style: TextStyle(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (double v, TitleMeta m) {
                final int i = v.round();
                if (i < 0 || i >= entriesAscending.length) {
                  return const SizedBox.shrink();
                }
                final DateTime d = entriesAscending[i].recordedAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat.MMMd().format(d),
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent e, LineTouchResponse? r) {
            final List<LineBarSpot>? list = r?.lineBarSpots;
            if (list == null || list.isEmpty) {
              return;
            }
            onTouch?.call(list.first.spotIndex);
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> spots) {
              return spots.map((LineBarSpot s) {
                final VitalReadingEntry en = entriesAscending[s.spotIndex];
                final VitalStatus st = statusForReading(type, en.value);
                final String statusLabel = switch (st) {
                  VitalStatus.normal => 'Normal',
                  VitalStatus.borderline => 'Borderline',
                  VitalStatus.elevated => 'Elevated',
                  VitalStatus.unknown => 'Unknown',
                };
                return LineTooltipItem(
                  '${DateFormat.yMMMd().format(en.recordedAt)}\n'
                  '${en.value.toStringAsFixed(1)} ${type.unit}\n'
                  '$statusLabel',
                  TextStyle(color: AppColors.onSurface, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (FlSpot spot, double xPct, LineChartBarData bar,
                  int index) {
                final VitalReadingEntry en = entriesAscending[index];
                final VitalStatus st = statusForReading(type, en.value);
                return FlDotCirclePainter(
                  radius: touchedIndex == index ? 7 : 5,
                  color: vitalStatusColor(st),
                  strokeWidth: 2,
                  strokeColor: AppColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.secondary.withValues(alpha: 0.25),
                  AppColors.secondary.withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
