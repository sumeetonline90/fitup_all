import 'package:fitup/features/diet/domain/entities/food_item.dart';
import 'package:fitup/features/diet/domain/entities/meal.dart';
import 'package:fitup/features/diet/domain/entities/meal_type.dart';
import 'package:fitup/features/diet/presentation/screens/meal_log_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forSlot merges food items from multiple meals', () {
    final Meal breakfast = Meal(
      id: 'm1',
      userId: 'u1',
      mealType: MealType.breakfast,
      foodItems: const <FoodItem>[
        FoodItem(
          id: 'f1',
          name: 'Oats',
          quantity: 100,
          unit: 'g',
          calories: 150,
          protein: 5,
          carbs: 27,
          fat: 3,
        ),
      ],
      totalCalories: 150,
      totalProtein: 5,
      totalCarbs: 27,
      totalFat: 3,
      dateTime: DateTime(2025, 6, 22, 8),
    );
    final Meal snack = Meal(
      id: 'm2',
      userId: 'u1',
      mealType: MealType.breakfast,
      foodItems: const <FoodItem>[
        FoodItem(
          id: 'f2',
          name: 'Banana',
          quantity: 120,
          unit: 'g',
          calories: 105,
          protein: 1,
          carbs: 27,
          fat: 0,
        ),
      ],
      totalCalories: 105,
      totalProtein: 1,
      totalCarbs: 27,
      totalFat: 0,
      dateTime: DateTime(2025, 6, 22, 8, 30),
    );

    final MealLogRouteExtra extra =
        MealLogRouteExtra.forSlot(<Meal>[breakfast, snack]);

    expect(extra.meal.id, 'm1');
    expect(extra.meal.foodItems, hasLength(2));
    expect(extra.meal.totalCalories, 255);
    expect(extra.supersededMealIds, <String>['m2']);
  });

  test('forSlot keeps single meal id with no superseded ids', () {
    final Meal lunch = Meal(
      id: 'm3',
      userId: 'u1',
      mealType: MealType.lunch,
      foodItems: const <FoodItem>[
        FoodItem(
          id: 'f3',
          name: 'Rice',
          quantity: 200,
          unit: 'g',
          calories: 260,
          protein: 5,
          carbs: 58,
          fat: 1,
        ),
      ],
      totalCalories: 260,
      totalProtein: 5,
      totalCarbs: 58,
      totalFat: 1,
      dateTime: DateTime(2025, 6, 22, 13),
    );

    final MealLogRouteExtra extra = MealLogRouteExtra.forSlot(<Meal>[lunch]);

    expect(extra.meal.id, 'm3');
    expect(extra.supersededMealIds, isEmpty);
  });
}
