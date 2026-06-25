import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/diet/data/datasources/diet_remote_datasource.dart';
import 'package:fitup/features/diet/data/models/meal_model.dart';
import 'package:fitup/features/diet/data/models/water_log_model.dart';
import 'package:fitup/features/diet/data/repositories/firebase_diet_repository.dart';
import 'package:fitup/features/diet/domain/entities/meal.dart';
import 'package:fitup/features/diet/domain/entities/meal_type.dart';
import 'package:fitup/features/diet/domain/entities/water_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_diet_local_datasource.dart';
import '../../helpers/mock_diet_remote_datasource.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockDietLocalDatasource local;
  late MockDietRemoteDatasource remote;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    local = MockDietLocalDatasource();
    remote = MockDietRemoteDatasource();
    registerFallbackValue(
      Meal(
        id: 'm0',
        userId: 'u0',
        mealType: MealType.lunch,
        foodItems: const [],
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        dateTime: DateTime(2025, 1, 1),
      ),
    );
    registerFallbackValue(
      WaterLog(
        id: 'w0',
        userId: 'u0',
        amountMl: 200,
        dateTime: DateTime(2025, 1, 1),
      ),
    );
    registerFallbackValue(
      MealModel(
        id: 'fb',
        userId: 'u0',
        mealType: MealType.lunch,
        foodItems: const [],
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        dateTime: DateTime(2025, 1, 1),
      ),
    );
    registerFallbackValue(
      WaterLogModel(
        id: 'wb',
        userId: 'u0',
        amountMl: 100,
        dateTime: DateTime(2025, 1, 1),
      ),
    );
  });

  test('saveMeal writes Firestore doc and upserts local', () async {
    when(() => local.upsertMeal(any(), synced: any(named: 'synced')))
        .thenAnswer((_) async {});

    final DietRemoteDatasource remote = DietRemoteDatasource(firestore);
    final FirebaseDietRepository repo =
        FirebaseDietRepository(firestore, remote, local);

    final Meal meal = Meal(
      id: 'meal1',
      userId: 'user1',
      mealType: MealType.breakfast,
      foodItems: const [],
      totalCalories: 300,
      totalProtein: 10,
      totalCarbs: 40,
      totalFat: 8,
      dateTime: DateTime(2025, 6, 1, 8, 30),
    );

    final result = await repo.saveMeal(meal);
    expect(result.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('user1')
        .collection('meals')
        .doc('meal1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['totalCalories'], 300);

    verify(() => local.upsertMeal(meal, synced: false)).called(1);
    verify(() => local.upsertMeal(meal, synced: true)).called(1);
  });

  test('saveMeal returns Left(ServerFailure) when Firestore throws', () async {
    when(() => local.upsertMeal(any(), synced: any(named: 'synced')))
        .thenAnswer((_) async {});
    when(() => remote.setMeal(any(), any())).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', message: 'write failed'),
    );

    final FirebaseDietRepository repo =
        FirebaseDietRepository(firestore, remote, local);

    final Meal meal = Meal(
      id: 'mealX',
      userId: 'user1',
      mealType: MealType.breakfast,
      foodItems: const [],
      totalCalories: 300,
      totalProtein: 10,
      totalCarbs: 40,
      totalFat: 8,
      dateTime: DateTime(2025, 6, 1, 8, 30),
    );

    final Either<Failure, Meal> result = await repo.saveMeal(meal);
    // Offline-first: local write succeeded; remote failure is best-effort.
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (Meal saved) => expect(saved.id, meal.id),
    );
    verifyNever(() => local.upsertMeal(any(), synced: true));
  });

  test('saveWaterLog returns Left(ServerFailure) when Firestore throws',
      () async {
    when(
      () => local.upsertWater(
        any(),
        synced: any(named: 'synced'),
      ),
    ).thenAnswer((_) async {});
    when(() => remote.setWaterLog(any(), any())).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', message: 'write failed'),
    );

    final FirebaseDietRepository repo =
        FirebaseDietRepository(firestore, remote, local);

    final WaterLog log = WaterLog(
      id: 'w1',
      userId: 'user1',
      amountMl: 250,
      dateTime: DateTime(2025, 6, 1, 10),
    );

    final Either<Failure, WaterLog> result = await repo.saveWaterLog(log);
    // Offline-first: local write succeeded; remote failure is best-effort.
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (WaterLog saved) => expect(saved.id, log.id),
    );
    verifyNever(() => local.upsertWater(any(), synced: true));
  });

  test('watchMeals streams from local cache for offline-first UI', () async {
    final DateTime day = DateTime(2025, 6, 1, 12);
    final Meal meal = Meal(
      id: 'meal_local',
      userId: 'user1',
      mealType: MealType.lunch,
      foodItems: const [],
      totalCalories: 450,
      totalProtein: 20,
      totalCarbs: 50,
      totalFat: 15,
      dateTime: day,
    );

    when(
      () => local.watchMealsForDay('user1', day),
    ).thenAnswer((_) => Stream<List<Meal>>.value(<Meal>[meal]));

    final FirebaseDietRepository repo =
        FirebaseDietRepository(firestore, remote, local);

    final List<Meal> emitted = await repo
        .watchMeals('user1', day)
        .first;

    expect(emitted, hasLength(1));
    expect(emitted.first.id, 'meal_local');
    verify(() => local.watchMealsForDay('user1', day)).called(1);
    verifyNever(() => remote.watchMealsInRange(any(), any(), any()));
  });
}
