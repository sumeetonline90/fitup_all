import 'dart:async';

import '../../domain/entities/meal.dart';
import '../../domain/entities/water_log.dart';
import 'diet_local_datasource.dart';

/// Web / test fallback.
class InMemoryDietLocalDatasource implements DietLocalDatasource {
  final Map<String, Meal> _meals = <String, Meal>{};
  final Map<String, WaterLog> _water = <String, WaterLog>{};
  final StreamController<void> _mealTick = StreamController<void>.broadcast();

  @override
  Future<void> deleteMealLocal(String mealId) async {
    _meals.remove(mealId);
    _mealTick.add(null);
  }

  @override
  Future<void> deleteWaterLogLocal(String waterLogId) async {
    _water.remove(waterLogId);
  }

  @override
  Future<List<Meal>> getMealsForDay(String userId, DateTime date) async {
    final DateTime s = DateTime(date.year, date.month, date.day);
    final DateTime e = s.add(const Duration(days: 1));
    return _meals.values
        .where(
          (Meal m) =>
              m.userId == userId &&
              !m.dateTime.isBefore(s) &&
              m.dateTime.isBefore(e),
        )
        .toList();
  }

  @override
  Stream<List<Meal>> watchMealsForDay(String userId, DateTime date) async* {
    yield await getMealsForDay(userId, date);
    yield* _mealTick.stream.asyncMap(
      (_) => getMealsForDay(userId, date),
    );
  }

  @override
  Future<void> upsertMeal(Meal meal, {required bool synced}) async {
    _meals[meal.id] = meal;
    _mealTick.add(null);
  }

  @override
  Future<List<WaterLog>> getWaterForDay(String userId, DateTime date) async {
    final DateTime s = DateTime(date.year, date.month, date.day);
    final DateTime e = s.add(const Duration(days: 1));
    return _water.values
        .where(
          (WaterLog w) =>
              w.userId == userId &&
              !w.dateTime.isBefore(s) &&
              w.dateTime.isBefore(e),
        )
        .toList();
  }

  @override
  Future<void> upsertWater(WaterLog log, {required bool synced}) async {
    _water[log.id] = log;
  }
}
