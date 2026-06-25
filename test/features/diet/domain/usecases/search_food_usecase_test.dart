import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/diet/domain/entities/food.dart';
import 'package:fitup/features/diet/domain/repositories/food_repository.dart';
import 'package:fitup/features/diet/domain/usecases/search_food_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFoodRepository extends Mock implements FoodRepository {}

void main() {
  late _MockFoodRepository repo;
  late SearchFoodUseCase useCase;

  setUp(() {
    repo = _MockFoodRepository();
    useCase = SearchFoodUseCase(repo);
  });

  test('delegates search with flags', () async {
    final List<Food> foods = <Food>[
      const Food(
        id: 'f1',
        name: 'Dal',
        servingSize: '100',
        servingUnit: 'g',
        caloriesPer100g: 120,
        proteinPer100g: 6,
        carbsPer100g: 15,
        fatPer100g: 3,
        category: 'indian',
        isIndian: true,
        source: FoodSource.ifct,
      ),
    ];
    when(
      () => repo.searchFood(
        'dal',
        limit: 10,
        isIndian: true,
      ),
    ).thenAnswer((_) async => Right<Failure, List<Food>>(foods));

    final result = await useCase('dal', limit: 10, isIndian: true);
    expect(result, Right<Failure, List<Food>>(foods));
    verify(
      () => repo.searchFood('dal', limit: 10, isIndian: true),
    ).called(1);
  });
}
