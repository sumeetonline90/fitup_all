import '../../domain/entities/meal.dart';
import '../../domain/entities/water_log.dart';

/// Offline diet cache.
abstract class DietLocalDatasource {
  Future<void> upsertMeal(Meal meal, {required bool synced});

  Future<void> deleteMealLocal(String mealId);

  Future<List<Meal>> getMealsForDay(String userId, DateTime date);

  Stream<List<Meal>> watchMealsForDay(String userId, DateTime date);

  Future<void> upsertWater(WaterLog log, {required bool synced});

  Future<void> deleteWaterLogLocal(String waterLogId);

  Future<List<WaterLog>> getWaterForDay(String userId, DateTime date);
}
