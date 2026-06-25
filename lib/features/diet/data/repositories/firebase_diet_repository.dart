import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../fitcoins/domain/services/fitcoin_award_service.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/entities/diet_summary.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_type.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/repositories/diet_repository.dart';
import '../datasources/diet_local_datasource.dart';
import '../datasources/diet_remote_datasource.dart';
import '../models/meal_model.dart';
import '../models/water_log_model.dart';

/// Default targets until profile module supplies goals.
const double kDefaultTargetCalories = 2000;
const double kDefaultTargetWaterMl = 2500;

/// Firestore + local Drift / in-memory.
class FirebaseDietRepository implements DietRepository {
  FirebaseDietRepository(
    this._firestore,
    this._remote,
    this._local, {
    FitcoinAwardService? fitcoinAwardService,
    ProfileRepository? profileRepository,
  }) : _fitcoinAwards = fitcoinAwardService,
       _profileRepository = profileRepository;

  final FirebaseFirestore _firestore;
  final DietRemoteDatasource _remote;
  final DietLocalDatasource _local;
  final FitcoinAwardService? _fitcoinAwards;
  final ProfileRepository? _profileRepository;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _endOfDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

  @override
  Future<Either<Failure, void>> deleteMeal(String mealId) async {
    try {
      await _local.deleteMealLocal(mealId);
      final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
          .collectionGroup('meals')
          .where(FieldPath.documentId, isEqualTo: mealId)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.delete();
      }
      return const Right<Failure, void>(null);
    } catch (e, st) {
      LoggerService.e('deleteMeal', e, st);
      return Left<Failure, void>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWaterLog(
    String userId,
    String waterLogId,
  ) async {
    try {
      await _local.deleteWaterLogLocal(waterLogId);
      try {
        await _remote.deleteWaterLog(userId, waterLogId);
      } catch (e, st) {
        LoggerService.e('deleteWaterLog remote failed; removed locally', e, st);
      }
      return const Right<Failure, void>(null);
    } catch (e, st) {
      LoggerService.e('deleteWaterLog', e, st);
      return Left<Failure, void>(_mapException(e));
    }
  }

  static const double _kGlassMl = 250;

  @override
  Future<Either<Failure, void>> removeOneGlassOfWater(
    String userId,
    DateTime date,
  ) async {
    final Either<Failure, List<WaterLog>> logsRes = await getWaterLogs(
      userId,
      date,
    );
    return await logsRes.fold<Future<Either<Failure, void>>>(
      (Failure f) async => Left<Failure, void>(f),
      (List<WaterLog> logs) async {
        final double total = logs.fold<double>(
          0,
          (double a, WaterLog w) => a + w.amountMl,
        );
        if (total < _kGlassMl - 0.01) {
          return const Right<Failure, void>(null);
        }
        final List<WaterLog> sorted = List<WaterLog>.from(logs)
          ..sort((WaterLog a, WaterLog b) => b.dateTime.compareTo(a.dateTime));
        double remaining = _kGlassMl;
        for (final WaterLog w in sorted) {
          if (remaining < 0.01) {
            break;
          }
          if (w.amountMl > remaining + 0.01) {
            final WaterLog updated = w.copyWith(
              amountMl: w.amountMl - remaining,
            );
            return (await saveWaterLog(updated)).fold(
              Left<Failure, void>.new,
              (WaterLog _) => const Right<Failure, void>(null),
            );
          }
          remaining -= w.amountMl;
          final Either<Failure, void> del = await deleteWaterLog(userId, w.id);
          if (del.isLeft()) {
            return del;
          }
        }
        return const Right<Failure, void>(null);
      },
    );
  }

  @override
  Future<Either<Failure, DietSummary>> getDailySummary(
    String userId,
    DateTime date,
  ) async {
    // Web has only an in-memory local cache that starts empty each page load,
    // so prefer Firestore there. Mobile keeps the offline-first local path.
    if (kIsWeb) {
      final Either<Failure, List<Meal>> mealsRes = await getMeals(userId, date);
      final Either<Failure, List<WaterLog>> waterRes = await getWaterLogs(
        userId,
        date,
      );
      return mealsRes.fold(
        Left<Failure, DietSummary>.new,
        (List<Meal> meals) => waterRes.fold(
          Left<Failure, DietSummary>.new,
          (List<WaterLog> w) =>
              Right<Failure, DietSummary>(_summarize(meals, w, date)),
        ),
      );
    }
    try {
      final List<Meal> meals = await _local.getMealsForDay(userId, date);
      final List<WaterLog> waterLogs = await _local.getWaterForDay(
        userId,
        date,
      );

      final double waterSum = waterLogs.fold<double>(
        0,
        (double p, WaterLog x) => p + x.amountMl,
      );
      final double totalCal = meals.fold<double>(
        0,
        (double p, Meal m) => p + m.totalCalories,
      );
      final double totalP = meals.fold<double>(
        0,
        (double p, Meal m) => p + m.totalProtein,
      );
      final double totalC = meals.fold<double>(
        0,
        (double p, Meal m) => p + m.totalCarbs,
      );
      final double totalF = meals.fold<double>(
        0,
        (double p, Meal m) => p + m.totalFat,
      );

      double fiber = 0;
      double sugar = 0;
      double sodium = 0;
      for (final Meal m in meals) {
        for (final FoodItem item in m.foodItems) {
          fiber += item.fiber ?? 0;
          sugar += item.sugar ?? 0;
          sodium += item.sodium ?? 0;
        }
      }

      return Right<Failure, DietSummary>(
        DietSummary(
          totalCalories: totalCal,
          targetCalories: kDefaultTargetCalories,
          totalProtein: totalP,
          totalCarbs: totalC,
          totalFat: totalF,
          totalFiber: fiber,
          totalSugar: sugar,
          totalSodium: sodium,
          totalWater: waterSum,
          targetWater: kDefaultTargetWaterMl,
          meals: meals,
          date: _startOfDay(date),
        ),
      );
    } catch (e, st) {
      LoggerService.e('getDailySummary local failed; trying remote', e, st);
      final Either<Failure, List<Meal>> mealsRes = await getMeals(userId, date);
      final Either<Failure, List<WaterLog>> waterRes = await getWaterLogs(
        userId,
        date,
      );
      return mealsRes.fold(
        Left<Failure, DietSummary>.new,
        (List<Meal> meals) =>
            waterRes.fold(Left<Failure, DietSummary>.new, (List<WaterLog> w) {
              final double waterSum = w.fold<double>(
                0,
                (double p, WaterLog x) => p + x.amountMl,
              );
              final double totalCal = meals.fold<double>(
                0,
                (double p, Meal m) => p + m.totalCalories,
              );
              final double totalP = meals.fold<double>(
                0,
                (double p, Meal m) => p + m.totalProtein,
              );
              final double totalC = meals.fold<double>(
                0,
                (double p, Meal m) => p + m.totalCarbs,
              );
              final double totalF = meals.fold<double>(
                0,
                (double p, Meal m) => p + m.totalFat,
              );
              double fiber = 0;
              double sugar = 0;
              double sodium = 0;
              for (final Meal m in meals) {
                for (final FoodItem item in m.foodItems) {
                  fiber += item.fiber ?? 0;
                  sugar += item.sugar ?? 0;
                  sodium += item.sodium ?? 0;
                }
              }
              return Right<Failure, DietSummary>(
                DietSummary(
                  totalCalories: totalCal,
                  targetCalories: kDefaultTargetCalories,
                  totalProtein: totalP,
                  totalCarbs: totalC,
                  totalFat: totalF,
                  totalFiber: fiber,
                  totalSugar: sugar,
                  totalSodium: sodium,
                  totalWater: waterSum,
                  targetWater: kDefaultTargetWaterMl,
                  meals: meals,
                  date: _startOfDay(date),
                ),
              );
            }),
      );
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getMeals(
    String userId,
    DateTime date,
  ) async {
    final DateTime s = _startOfDay(date);
    final DateTime e = _endOfDay(date);
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryMealsInRange(userId, s, e);
      final List<Meal> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                MealModel.fromFirestore(d).toEntity(),
          )
          .toList();
      return Right<Failure, List<Meal>>(list);
    } catch (e, st) {
      LoggerService.e('getMeals remote failed; trying local', e, st);
      try {
        return Right<Failure, List<Meal>>(
          await _local.getMealsForDay(userId, date),
        );
      } catch (localErr, localSt) {
        LoggerService.e('getMeals local failed', localErr, localSt);
        return Left<Failure, List<Meal>>(
          const CacheFailure(
            'Unable to load meals. Please check your connection.',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getMealsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryMealsInRange(userId, startDate, endDate);
      final List<Meal> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                MealModel.fromFirestore(d).toEntity(),
          )
          .toList();
      return Right<Failure, List<Meal>>(list);
    } catch (e, st) {
      LoggerService.e('getMealsByDateRange', e, st);
      return Left<Failure, List<Meal>>(_mapException(e));
    }
  }

  @override
  Future<Either<Failure, Map<String, DietSummary>>> getWeeklyNutrition(
    String userId,
  ) async {
    final Map<String, DietSummary> out = <String, DietSummary>{};
    final DateTime today = _startOfDay(DateTime.now());
    for (int i = 6; i >= 0; i--) {
      final DateTime d = today.subtract(Duration(days: i));
      final Either<Failure, DietSummary> r = await getDailySummary(userId, d);
      r.fold((_) {}, (DietSummary s) {
        out[_dateKey(d)] = s;
      });
    }
    return Right<Failure, Map<String, DietSummary>>(out);
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Failure _mapException(Object e) {
    if (e is FirebaseException) {
      return ServerFailure(e.message ?? e.code);
    }
    final String typeName = e.runtimeType.toString();
    if (typeName.contains('Drift') || typeName.contains('Sqlite')) {
      return CacheFailure(e.toString());
    }
    return UnexpectedFailure(e.toString());
  }

  @override
  Future<Either<Failure, List<WaterLog>>> getWaterLogs(
    String userId,
    DateTime date,
  ) async {
    final DateTime s = _startOfDay(date);
    final DateTime e = _endOfDay(date);
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryWaterForDay(userId, s, e);
      final List<WaterLog> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                WaterLogModel.fromFirestore(d).toEntity(),
          )
          .toList();
      return Right<Failure, List<WaterLog>>(list);
    } catch (e, st) {
      LoggerService.e('getWaterLogs remote failed; trying local', e, st);
      try {
        return Right<Failure, List<WaterLog>>(
          await _local.getWaterForDay(userId, date),
        );
      } catch (localErr, localSt) {
        LoggerService.e('getWaterLogs local failed', localErr, localSt);
        return Left<Failure, List<WaterLog>>(
          const CacheFailure(
            'Unable to load water logs. Please check your connection.',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, Meal>> saveMeal(Meal meal) async {
    final MealModel model = MealModel.fromEntity(meal);
    // Step 1: Local write MUST succeed — if it fails, the data is NOT saved.
    try {
      await _local.upsertMeal(meal, synced: false);
    } catch (e, st) {
      LoggerService.e('saveMeal local write failed', e, st);
      return Left<Failure, Meal>(
        const CacheFailure('Failed to save. Please try again.'),
      );
    }

    // Step 2: Remote sync best-effort — local data is already safe.
    try {
      await _remote.setMeal(meal.id, model);
      await _local.upsertMeal(meal, synced: true);
      unawaited(_maybeAwardAllMainMeals(meal.userId, meal.dateTime));
    } catch (e, st) {
      LoggerService.e('saveMeal remote failed; kept locally', e, st);
    }

    return Right<Failure, Meal>(meal);
  }

  Future<void> _maybeAwardAllMainMeals(
    String userId,
    DateTime dayAnchor,
  ) async {
    final FitcoinAwardService? awards = _fitcoinAwards;
    if (awards == null) {
      return;
    }
    final Either<Failure, List<Meal>> res = await getMeals(userId, dayAnchor);
    await res.fold((_) async {}, (List<Meal> meals) async {
      final Set<MealType> types = meals.map((Meal m) => m.mealType).toSet();
      if (types.contains(MealType.breakfast) &&
          types.contains(MealType.lunch) &&
          types.contains(MealType.dinner)) {
        await awards.onAllMealsLogged(userId);
      }
    });
  }

  @override
  Future<Either<Failure, WaterLog>> saveWaterLog(WaterLog log) async {
    final WaterLogModel model = WaterLogModel.fromEntity(log);
    // Step 1: Local write MUST succeed — if it fails, the data is NOT saved.
    try {
      await _local.upsertWater(log, synced: false);
    } catch (e, st) {
      LoggerService.e('saveWaterLog local write failed', e, st);
      return Left<Failure, WaterLog>(
        const CacheFailure('Failed to save. Please try again.'),
      );
    }

    // Step 2: Remote sync best-effort — local data is already safe.
    try {
      await _remote.setWaterLog(log.id, model);
      await _local.upsertWater(log, synced: true);
      unawaited(_maybeAwardWaterGoal(log.userId, log.dateTime));
    } catch (e, st) {
      LoggerService.e('saveWaterLog remote failed; kept locally', e, st);
    }

    return Right<Failure, WaterLog>(log);
  }

  Future<void> _maybeAwardWaterGoal(String userId, DateTime dayAnchor) async {
    final FitcoinAwardService? awards = _fitcoinAwards;
    final ProfileRepository? profiles = _profileRepository;
    if (awards == null || profiles == null) {
      return;
    }
    final Either<Failure, UserProfile> profileRes = await profiles.getProfile(
      userId,
    );
    await profileRes.fold((_) async {}, (UserProfile p) async {
      final int? goalMl = p.dailyWaterGoalMl;
      if (goalMl == null || goalMl <= 0) {
        return;
      }
      final Either<Failure, List<WaterLog>> logsRes = await getWaterLogs(
        userId,
        dayAnchor,
      );
      await logsRes.fold((_) async {}, (List<WaterLog> logs) async {
        final double total = logs.fold<double>(
          0,
          (double a, WaterLog w) => a + w.amountMl,
        );
        if (total >= goalMl) {
          await awards.onWaterGoalReachedForDay(userId, dayAnchor);
        }
      });
    });
  }

  @override
  Stream<List<Meal>> watchMeals(String userId, DateTime date) {
    // Offline-first: UI must react to local writes immediately after logMeal.
    // Remote Firestore snapshots lag or fail when sync is best-effort.
    return _local.watchMealsForDay(userId, date);
  }

  DietSummary _summarize(
    List<Meal> meals,
    List<WaterLog> waterLogs,
    DateTime date,
  ) {
    final double waterSum = waterLogs.fold<double>(
      0,
      (double p, WaterLog x) => p + x.amountMl,
    );
    final double totalCal = meals.fold<double>(
      0,
      (double p, Meal m) => p + m.totalCalories,
    );
    final double totalP = meals.fold<double>(
      0,
      (double p, Meal m) => p + m.totalProtein,
    );
    final double totalC = meals.fold<double>(
      0,
      (double p, Meal m) => p + m.totalCarbs,
    );
    final double totalF = meals.fold<double>(
      0,
      (double p, Meal m) => p + m.totalFat,
    );
    double fiber = 0;
    double sugar = 0;
    double sodium = 0;
    for (final Meal m in meals) {
      for (final FoodItem item in m.foodItems) {
        fiber += item.fiber ?? 0;
        sugar += item.sugar ?? 0;
        sodium += item.sodium ?? 0;
      }
    }
    return DietSummary(
      totalCalories: totalCal,
      targetCalories: kDefaultTargetCalories,
      totalProtein: totalP,
      totalCarbs: totalC,
      totalFat: totalF,
      totalFiber: fiber,
      totalSugar: sugar,
      totalSodium: sodium,
      totalWater: waterSum,
      targetWater: kDefaultTargetWaterMl,
      meals: meals,
      date: _startOfDay(date),
    );
  }
}
