import 'package:freezed_annotation/freezed_annotation.dart';

import 'meal.dart';

part 'diet_summary.freezed.dart';

/// Aggregated nutrition for a calendar day.
@freezed
abstract class DietSummary with _$DietSummary {
  const factory DietSummary({
    required double totalCalories,
    required double targetCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    @Default(0) double totalFiber,
    @Default(0) double totalSugar,
    @Default(0) double totalSodium,
    required double totalWater,
    required double targetWater,
    required List<Meal> meals,
    required DateTime date,
  }) = _DietSummary;
}
