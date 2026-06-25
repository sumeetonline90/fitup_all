import 'package:fitup/features/diet/data/datasources/in_memory_diet_local_datasource.dart';
import 'package:fitup/features/diet/domain/entities/meal.dart';
import 'package:fitup/features/diet/domain/entities/meal_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDietLocalDatasource ds;

  setUp(() {
    ds = InMemoryDietLocalDatasource();
  });

  test('watchMealsForDay emits after upsertMeal', () async {
    final DateTime day = DateTime(2026, 6, 22);
    final List<List<Meal>> emissions = <List<Meal>>[];
    final subscription = ds
        .watchMealsForDay('user1', day)
        .listen(emissions.add);

    await Future<void>.delayed(Duration.zero);
    expect(emissions, hasLength(1));
    expect(emissions.last, isEmpty);

    final Meal meal = Meal(
      id: 'meal1',
      userId: 'user1',
      mealType: MealType.lunch,
      foodItems: const [],
      totalCalories: 500,
      totalProtein: 20,
      totalCarbs: 60,
      totalFat: 10,
      dateTime: DateTime(2026, 6, 22, 12),
    );
    await ds.upsertMeal(meal, synced: false);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(2));
    expect(emissions.last, hasLength(1));
    expect(emissions.last.first.id, 'meal1');

    await subscription.cancel();
  });
}
