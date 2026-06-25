import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/fitup_database.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/water_log.dart';
import '../models/meal_model.dart';
import 'diet_local_datasource.dart';

/// Drift-backed offline diet cache.
class DriftDietLocalDatasource implements DietLocalDatasource {
  DriftDietLocalDatasource(this._db);

  final FitupDatabase _db;

  @override
  Future<void> deleteMealLocal(String mealId) async {
    await (_db.delete(_db.dietMealCache)
          ..where(($DietMealCacheTable t) => t.id.equals(mealId)))
        .go();
  }

  @override
  Future<List<Meal>> getMealsForDay(String userId, DateTime date) async {
    final DateTime start = DateTime(date.year, date.month, date.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<DietMealCacheRow> rows = await (_db.select(_db.dietMealCache)
          ..where(
            ($DietMealCacheTable t) =>
                t.userId.equals(userId) &
                t.loggedAt.isBiggerOrEqualValue(start) &
                t.loggedAt.isSmallerThanValue(end),
          ))
        .get();
    return rows.map(_mealFromRow).toList();
  }

  @override
  Stream<List<Meal>> watchMealsForDay(String userId, DateTime date) {
    final DateTime start = DateTime(date.year, date.month, date.day);
    final DateTime end = start.add(const Duration(days: 1));
    return (_db.select(_db.dietMealCache)
          ..where(
            ($DietMealCacheTable t) =>
                t.userId.equals(userId) &
                t.loggedAt.isBiggerOrEqualValue(start) &
                t.loggedAt.isSmallerThanValue(end),
          ))
        .watch()
        .map((List<DietMealCacheRow> rows) => rows.map(_mealFromRow).toList());
  }

  Meal _mealFromRow(DietMealCacheRow row) {
    final Map<String, dynamic> map =
        jsonDecode(row.payloadJson) as Map<String, dynamic>;
    return MealModel.fromJson(map).toEntity();
  }

  @override
  Future<void> upsertMeal(Meal meal, {required bool synced}) async {
    final String json = jsonEncode(MealModel.fromEntity(meal).toJson());
    await _db.into(_db.dietMealCache).insertOnConflictUpdate(
          DietMealCacheCompanion.insert(
            id: meal.id,
            userId: meal.userId,
            payloadJson: json,
            loggedAt: meal.dateTime,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<List<WaterLog>> getWaterForDay(String userId, DateTime date) async {
    final DateTime start = DateTime(date.year, date.month, date.day);
    final DateTime end = start.add(const Duration(days: 1));
    final List<WaterLogCacheRow> rows = await (_db.select(_db.waterLogCache)
          ..where(
            ($WaterLogCacheTable t) =>
                t.userId.equals(userId) &
                t.loggedAt.isBiggerOrEqualValue(start) &
                t.loggedAt.isSmallerThanValue(end),
          ))
        .get();
    return rows
        .map(
          (WaterLogCacheRow r) => WaterLog(
            id: r.id,
            userId: r.userId,
            amountMl: r.amountMl,
            dateTime: r.loggedAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> upsertWater(WaterLog log, {required bool synced}) async {
    await _db.into(_db.waterLogCache).insertOnConflictUpdate(
          WaterLogCacheCompanion.insert(
            id: log.id,
            userId: log.userId,
            amountMl: log.amountMl,
            loggedAt: log.dateTime,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> deleteWaterLogLocal(String waterLogId) async {
    await (_db.delete(_db.waterLogCache)
          ..where(($WaterLogCacheTable t) => t.id.equals(waterLogId)))
        .go();
  }
}
