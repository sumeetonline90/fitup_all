import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/barcode_scanner_service.dart';
import '../../../../services/models/meal_analysis_result.dart';
import '../../../activity/domain/entities/activity_stats.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/datasources/food_seed_data.dart';
import '../../domain/entities/diet_summary.dart';
import '../../domain/entities/food.dart';
import '../../domain/entities/meal.dart';
import '../../domain/entities/water_log.dart';
import '../../domain/repositories/diet_repository.dart';
import '../../domain/repositories/food_repository.dart';
import '../../domain/usecases/get_daily_summary_usecase.dart';
import '../../domain/usecases/get_weekly_nutrition_usecase.dart';
import '../../domain/usecases/log_meal_usecase.dart';
import '../../domain/usecases/log_water_usecase.dart';
import '../../domain/usecases/scan_barcode_usecase.dart';
import '../../domain/usecases/search_food_usecase.dart';

part 'diet_providers.g.dart';

/// Matches [FirebaseDietRepository] defaults until profile goals exist.
const double _kFallbackTargetCalories = 2000;

/// Calendar day key for Riverpod families (`yyyy-MM-dd`).
String dietDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _dietDateFromKey(String dateKey) {
  final List<String> p = dateKey.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

void _invalidateDietDay(Ref ref, DateTime mealOrWaterTime) {
  final String key = dietDateKey(mealOrWaterTime);
  ref.invalidate(mealsForDayProvider(key));
  ref.invalidate(dailySummaryForDateProvider(key));
  ref.invalidate(waterLogsForDateProvider(key));
  ref.invalidate(dietInsightForProvider(key));
  ref.invalidate(weeklyNutritionProvider);
  ref.invalidate(todayMealsProvider);
  ref.invalidate(dailySummaryProvider);
  ref.invalidate(waterLogsProvider);
  ref.invalidate(dietInsightProvider);
}

@riverpod
DietRepository dietRepository(Ref ref) => getIt<DietRepository>();

@riverpod
FoodRepository foodRepository(Ref ref) => getIt<FoodRepository>();

@riverpod
BarcodeScannerService barcodeScannerService(Ref ref) =>
    getIt<BarcodeScannerService>();

@riverpod
Stream<List<Meal>> mealsForDay(Ref ref, String dateKey) {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return Stream<List<Meal>>.value(<Meal>[]);
  }
  final DateTime day = _dietDateFromKey(dateKey);
  return ref.read(dietRepositoryProvider).watchMeals(user.id, day);
}

@riverpod
Stream<List<Meal>> todayMeals(Ref ref) {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return Stream<List<Meal>>.value(<Meal>[]);
  }
  return ref.read(dietRepositoryProvider).watchMeals(user.id, DateTime.now());
}

@riverpod
Future<DietSummary> dailySummaryForDate(Ref ref, String dateKey) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    throw const AuthFailure('Not logged in');
  }
  // Recompute calories/macros when local meal or water logs change.
  ref.watch(mealsForDayProvider(dateKey));
  ref.watch(waterLogsForDateProvider(dateKey));
  final GetDailySummaryUseCase uc = GetDailySummaryUseCase(
    ref.read(dietRepositoryProvider),
  );
  final Either<Failure, DietSummary> r = await uc(
    user.id,
    _dietDateFromKey(dateKey),
  );
  return r.fold((Failure f) => throw f, (DietSummary s) => s);
}

@riverpod
Future<DietSummary> dailySummary(Ref ref) async {
  return ref.read(
    dailySummaryForDateProvider(dietDateKey(DateTime.now())).future,
  );
}

@riverpod
Future<Map<String, DietSummary>> weeklyNutrition(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <String, DietSummary>{};
  }
  final GetWeeklyNutritionUseCase uc = GetWeeklyNutritionUseCase(
    ref.read(dietRepositoryProvider),
  );
  final Either<Failure, Map<String, DietSummary>> r = await uc(user.id);
  return r.fold(
    (_) => <String, DietSummary>{},
    (Map<String, DietSummary> m) => m,
  );
}

@riverpod
Future<List<WaterLog>> waterLogsForDate(Ref ref, String dateKey) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <WaterLog>[];
  }
  final Either<Failure, List<WaterLog>> r = await ref
      .read(dietRepositoryProvider)
      .getWaterLogs(user.id, _dietDateFromKey(dateKey));
  return r.fold((_) => <WaterLog>[], (List<WaterLog> list) => list);
}

@riverpod
Future<List<WaterLog>> waterLogs(Ref ref) async {
  return ref.read(waterLogsForDateProvider(dietDateKey(DateTime.now())).future);
}

/// Debounced remote search (Open Food Facts + cache).
@riverpod
Future<List<Food>> foodSearch(Ref ref, String query) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final String q = query.trim();
  if (q.isEmpty) {
    return <Food>[];
  }
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <Food>[];
  }
  final SearchFoodUseCase uc = SearchFoodUseCase(
    ref.read(foodRepositoryProvider),
  );
  final Either<Failure, List<Food>> indianOnly = await uc(
    q,
    limit: 25,
    isIndian: true,
  );
  final List<Food> indianFoods = indianOnly.fold(
    (_) => <Food>[],
    (List<Food> list) => list,
  );
  if (indianFoods.isNotEmpty) {
    return indianFoods;
  }
  final Either<Failure, List<Food>> r = await uc(q, limit: 25, isIndian: false);
  return r.fold((_) => <Food>[], (List<Food> list) => list);
}

@riverpod
class MealLoggerNotifier extends _$MealLoggerNotifier {
  @override
  FutureOr<void> build() {}

  Future<Either<Failure, Meal>> logMeal(
    Meal meal, {
    List<String> supersededMealIds = const <String>[],
  }) async {
    final LogMealUseCase uc = LogMealUseCase(ref.read(dietRepositoryProvider));
    final Either<Failure, Meal> r = await uc(meal);
    await r.fold((_) async {}, (Meal m) async {
      _invalidateDietDay(ref, m.dateTime);
      for (final String id in supersededMealIds) {
        await ref.read(dietRepositoryProvider).deleteMeal(id);
      }
      if (supersededMealIds.isNotEmpty) {
        _invalidateDietDay(ref, m.dateTime);
      }
    });
    return r;
  }
}

@riverpod
class WaterLoggerNotifier extends _$WaterLoggerNotifier {
  @override
  FutureOr<void> build() {}

  Future<Either<Failure, WaterLog>> logWater(WaterLog log) async {
    final LogWaterUseCase uc = LogWaterUseCase(
      ref.read(dietRepositoryProvider),
    );
    final Either<Failure, WaterLog> r = await uc(log);
    r.fold((_) {}, (WaterLog w) {
      _invalidateDietDay(ref, w.dateTime);
    });
    return r;
  }

  Future<Either<Failure, void>> deleteWaterLog(
    String userId,
    String waterLogId,
    DateTime day,
  ) async {
    final Either<Failure, void> r = await ref
        .read(dietRepositoryProvider)
        .deleteWaterLog(userId, waterLogId);
    r.fold((_) {}, (_) {
      _invalidateDietDay(ref, day);
    });
    return r;
  }
}

@riverpod
Future<Food?> barcodeScan(Ref ref, String barcode) async {
  if (barcode.trim().isEmpty) {
    return null;
  }
  final ScanBarcodeUseCase uc = ScanBarcodeUseCase(
    ref.read(foodRepositoryProvider),
  );
  final Either<Failure, Food?> r = await uc(barcode.trim());
  return r.fold((_) => null, (Food? f) => f);
}

@riverpod
Future<MealAnalysisResult> mealPhotoAnalysis(
  Ref ref,
  Uint8List imageBytes,
) async {
  return ref.read(aiServiceProvider).analyzeMealPhoto(imageBytes);
}

@riverpod
Future<String> dietInsightFor(Ref ref, String dateKey) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return 'Sign in to see diet insights.';
  }
  final DateTime day = _dietDateFromKey(dateKey);
  final Either<Failure, DietSummary> sumRes = await GetDailySummaryUseCase(
    ref.read(dietRepositoryProvider),
  )(user.id, day);
  final List<Meal> meals = sumRes.fold(
    (_) => <Meal>[],
    (DietSummary s) => s.meals,
  );
  final double targetCal = sumRes.fold(
    (_) => _kFallbackTargetCalories,
    (DietSummary s) => s.targetCalories,
  );
  final userProfile = ref.read(userProfileProvider).value;
  final Either<Failure, ActivityStats> stats = await ref
      .read(activityRepositoryProvider)
      .getStats(
        user.id,
        DateTime.now().subtract(const Duration(days: 1)),
        DateTime.now(),
      );
  final String activityData = stats.fold(
    (_) => 'No activity summary.',
    (ActivityStats s) =>
        'Recent steps: ${s.totalSteps}, distanceKm: '
        '${(s.totalDistanceMeters / 1000).toStringAsFixed(1)}',
  );
  return ref
      .read(aiServiceProvider)
      .getDietInsight(
        meals: meals,
        userGoals: <String, String>{
          'calories': '${targetCal.round()} kcal daily target',
          if (userProfile?.targetWeightKg != null)
            'target_weight':
                '${userProfile!.targetWeightKg!.toStringAsFixed(1)} kg',
          if (userProfile?.targetWeightDate != null)
            'target_date':
                '${userProfile!.targetWeightDate!.toLocal().toString().split(' ').first}',
        },
        activityData: activityData,
        healthData: 'Not connected in this build.',
      );
}

@riverpod
Future<String> dietInsight(Ref ref) async {
  return ref.read(dietInsightForProvider(dietDateKey(DateTime.now())).future);
}

@riverpod
Future<List<Food>> recentFoods(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <Food>[];
  }
  final Either<Failure, List<Food>> r = await ref
      .read(foodRepositoryProvider)
      .getRecentFoods(user.id);
  return r.fold((_) => <Food>[], (List<Food> list) => list);
}

@riverpod
Future<List<Food>> frequentFoods(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <Food>[];
  }
  final Either<Failure, List<Food>> r = await ref
      .read(foodRepositoryProvider)
      .getFrequentFoods(user.id);
  return r.fold((_) => <Food>[], (List<Food> list) => list);
}

/// Curated popular items from the local seed database.
@riverpod
List<Food> commonFoods(Ref ref) {
  final Set<String> ids = kCommonFoodSeedIds.toSet();
  return kFoodSeedDatabase.where((Food f) => ids.contains(f.id)).toList();
}
