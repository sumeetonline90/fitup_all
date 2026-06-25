import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/diet/domain/entities/meal.dart';
import 'package:fitup/features/diet/domain/entities/meal_type.dart';
import 'package:fitup/features/diet/domain/repositories/diet_repository.dart';
import 'package:fitup/features/diet/domain/usecases/log_meal_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDietRepository extends Mock implements DietRepository {}

void main() {
  late _MockDietRepository repo;
  late LogMealUseCase useCase;

  setUp(() {
    repo = _MockDietRepository();
    useCase = LogMealUseCase(repo);
    registerFallbackValue(
      Meal(
        id: 'm',
        userId: 'u',
        mealType: MealType.snack,
        foodItems: const [],
        totalCalories: 1,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        dateTime: DateTime(2025, 1, 1),
      ),
    );
  });

  test('delegates to repository', () async {
    final Meal meal = Meal(
      id: 'm1',
      userId: 'u1',
      mealType: MealType.lunch,
      foodItems: const [],
      totalCalories: 400,
      totalProtein: 20,
      totalCarbs: 30,
      totalFat: 10,
      dateTime: DateTime(2025, 2, 2, 13),
    );
    when(() => repo.saveMeal(meal)).thenAnswer(
      (_) async => Right<Failure, Meal>(meal),
    );

    final result = await useCase(meal);
    expect(result, Right<Failure, Meal>(meal));
    verify(() => repo.saveMeal(meal)).called(1);
  });
}
