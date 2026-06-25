import 'package:freezed_annotation/freezed_annotation.dart';

part 'food.freezed.dart';

/// Food catalog entry (per 100g macros + metadata).
enum FoodSource {
  usda,
  ifct,
  openFoodFacts,
  custom,
  aiGenerated,
}

@freezed
abstract class Food with _$Food {
  const factory Food({
    required String id,
    required String name,
    String? brand,
    String? servingSize,
    String? servingUnit,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    double? fiberPer100g,
    double? sodiumPer100g,
    double? sugarPer100g,
    required String category,
    @Default(false) bool isIndian,
    String? barcode,
    required FoodSource source,
  }) = _Food;
}
