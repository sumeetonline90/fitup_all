import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/diet_summary.dart';
import '../entities/meal.dart';
import '../entities/water_log.dart';

/// Remote + local diet persistence.
abstract class DietRepository {
  Future<Either<Failure, Meal>> saveMeal(Meal meal);

  Future<Either<Failure, List<Meal>>> getMeals(String userId, DateTime date);

  Future<Either<Failure, List<Meal>>> getMealsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  Future<Either<Failure, void>> deleteMeal(String mealId);

  Future<Either<Failure, DietSummary>> getDailySummary(
    String userId,
    DateTime date,
  );

  Future<Either<Failure, WaterLog>> saveWaterLog(WaterLog log);

  Future<Either<Failure, void>> deleteWaterLog(
    String userId,
    String waterLogId,
  );

  /// Removes exactly one glass (250 ml) from the day's water logs, newest first.
  Future<Either<Failure, void>> removeOneGlassOfWater(
    String userId,
    DateTime date,
  );

  Future<Either<Failure, List<WaterLog>>> getWaterLogs(
    String userId,
    DateTime date,
  );

  Future<Either<Failure, Map<String, DietSummary>>> getWeeklyNutrition(
    String userId,
  );

  /// Real-time meals for a calendar day (local + Firestore).
  Stream<List<Meal>> watchMeals(String userId, DateTime date);
}
