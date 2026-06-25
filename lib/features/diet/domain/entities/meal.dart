import 'package:freezed_annotation/freezed_annotation.dart';

import 'food_item.dart';
import 'meal_type.dart';

part 'meal.freezed.dart';

/// Logged meal with line items and optional AI note.
@freezed
abstract class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String userId,
    required MealType mealType,
    required List<FoodItem> foodItems,
    required double totalCalories,
    required double totalProtein,
    required double totalCarbs,
    required double totalFat,
    required DateTime dateTime,
    String? notes,
    String? photoUrl,
    String? aiInsight,
  }) = _Meal;
}
