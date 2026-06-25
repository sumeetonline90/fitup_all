import 'package:freezed_annotation/freezed_annotation.dart';

part 'food_item.freezed.dart';

/// Single food line on a logged meal.
@freezed
abstract class FoodItem with _$FoodItem {
  const factory FoodItem({
    required String id,
    required String name,
    required double quantity,
    required String unit,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    double? fiber,
    double? sodium,
    double? sugar,
    String? servingSize,
    String? barcode,
    @Default(false) bool isCustom,
  }) = _FoodItem;
}
