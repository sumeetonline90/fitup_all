import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/database/fitup_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/food_database_service.dart';
import '../../../../services/logger_service.dart';
import '../../domain/entities/food.dart';
import '../../domain/repositories/food_repository.dart';
import '../datasources/food_seed_data.dart';
import '../models/food_model.dart';

/// Local Drift cache + Open Food Facts via [FoodDatabaseService].
///
/// Custom food ids must be `custom_{userId}_{suffix}` for Firestore path.
class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(
    this._firestore,
    this._off,
    this._db,
  );

  final FirebaseFirestore _firestore;
  final FoodDatabaseService _off;
  final FitupDatabase? _db;

  static const Duration _searchTtl = Duration(hours: 1);
  static const int _recentMax = 20;

  String? _userIdFromCustomFoodId(String id) {
    if (!id.startsWith('custom_')) {
      return null;
    }
    final List<String> parts = id.split('_');
    if (parts.length < 3) {
      return null;
    }
    return parts[1];
  }

  String _searchCacheKey(String query) => 'q_${query.toLowerCase().trim()}';

  Future<void> _appendRecent(String userId, Food food) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    const String prefix = 'recent_';
    final FoodCatalogCacheRow? row = await (db.select(db.foodCatalogCache)
          ..where(($FoodCatalogCacheTable t) => t.id.equals('$prefix$userId')))
        .getSingleOrNull();
    List<Food> list = <Food>[];
    if (row != null) {
      try {
        final List<dynamic> raw =
            jsonDecode(row.payloadJson) as List<dynamic>;
        list = raw
            .map(
              (dynamic e) => FoodModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ).toEntity(),
            )
            .toList();
      } catch (_) {}
    }
    final List<Food> next = <Food>[
      food,
      ...list.where((Food f) => f.id != food.id),
    ].take(_recentMax).toList();
    final String json = jsonEncode(
      next.map((Food f) => FoodModel.fromEntity(f).toJson()).toList(),
    );
    await db.into(db.foodCatalogCache).insertOnConflictUpdate(
          FoodCatalogCacheCompanion.insert(
            id: '$prefix$userId',
            payloadJson: json,
            cachedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<Either<Failure, Food?>> getFoodByBarcode(String barcode) async {
    try {
      final Food? food = await _off.fetchProductByBarcode(barcode);
      return Right<Failure, Food?>(food);
    } catch (e, st) {
      LoggerService.e('getFoodByBarcode', e, st);
      return Left<Failure, Food?>(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Food>>> getFrequentFoods(String userId) async {
    return _readFoodList('freq_$userId');
  }

  @override
  Future<Either<Failure, List<Food>>> getRecentFoods(String userId) async {
    return _readFoodList('recent_$userId');
  }

  Future<Either<Failure, List<Food>>> _readFoodList(String id) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return const Right<Failure, List<Food>>(<Food>[]);
    }
    final FoodCatalogCacheRow? row = await (db.select(db.foodCatalogCache)
          ..where(($FoodCatalogCacheTable t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return const Right<Failure, List<Food>>(<Food>[]);
    }
    try {
      final List<dynamic> list =
          jsonDecode(row.payloadJson) as List<dynamic>;
      final List<Food> out = <Food>[];
      for (final dynamic e in list) {
        if (e is Map<String, dynamic>) {
          out.add(FoodModel.fromJson(e).toEntity());
        }
      }
      return Right<Failure, List<Food>>(out);
    } catch (e, st) {
      LoggerService.e('_readFoodList', e, st);
      return Left<Failure, List<Food>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Food>> saveCustomFood(Food food) async {
    final String? userId = _userIdFromCustomFoodId(food.id);
    if (userId == null) {
      return const Left<Failure, Food>(
        ServerFailure('Custom food id must be custom_{userId}_...'),
      );
    }
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_foods')
          .doc(food.id)
          .set(FoodModel.fromEntity(food).toJson());
      final FitupDatabase? db = _db;
      if (db != null) {
        final String json = jsonEncode(FoodModel.fromEntity(food).toJson());
        await db.into(db.foodCatalogCache).insertOnConflictUpdate(
              FoodCatalogCacheCompanion.insert(
                id: food.id,
                payloadJson: json,
                cachedAt: DateTime.now(),
              ),
            );
      }
      await _appendRecent(userId, food);
      return Right<Failure, Food>(food);
    } catch (e, st) {
      LoggerService.e('saveCustomFood', e, st);
      return Left<Failure, Food>(ServerFailure(e.toString()));
    }
  }

  /// Returns seed foods whose name contains [q] (case-insensitive).
  List<Food> _searchSeedDatabase(String q, {int limit = 15}) {
    final String lower = q.toLowerCase();
    final List<Food> matches = <Food>[];
    for (final Food food in kFoodSeedDatabase) {
      if (food.name.toLowerCase().contains(lower)) {
        matches.add(food);
        if (matches.length >= limit) {
          break;
        }
      }
    }
    return matches;
  }

  @override
  Future<Either<Failure, List<Food>>> searchFood(
    String query, {
    int limit = 25,
    bool isIndian = false,
  }) async {
    final String q = query.trim();
    if (q.isEmpty) {
      return const Right<Failure, List<Food>>(<Food>[]);
    }

    // 1. Instant local seed matches (always available offline).
    final List<Food> seedResults = _searchSeedDatabase(q, limit: limit);

    // 2. Check Drift cache.
    final FitupDatabase? db = _db;
    final String key = _searchCacheKey(q);
    if (db != null) {
      final FoodSearchCacheRow? cached = await (db.select(db.foodSearchCache)
            ..where(($FoodSearchCacheTable t) => t.cacheKey.equals(key)))
          .getSingleOrNull();
      if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
        try {
          final List<dynamic> list =
              jsonDecode(cached.resultsJson) as List<dynamic>;
          final List<Food> foods = list
              .map(
                (dynamic e) =>
                    FoodModel.fromJson(Map<String, dynamic>.from(e as Map))
                        .toEntity(),
              )
              .toList();
          return Right<Failure, List<Food>>(
            _mergeFoodLists(seedResults, foods, limit),
          );
        } catch (_) {}
      }
    }

    // 3. Open Food Facts API.
    try {
      final List<Food> apiResults = await _off.searchProducts(
        q,
        limit: limit,
        preferIndian: isIndian,
      );
      final List<Food> merged = _mergeFoodLists(seedResults, apiResults, limit);
      if (db != null) {
        final String json = jsonEncode(
          merged.map((Food f) => FoodModel.fromEntity(f).toJson()).toList(),
        );
        await db.into(db.foodSearchCache).insertOnConflictUpdate(
              FoodSearchCacheCompanion.insert(
                cacheKey: key,
                userId: '',
                resultsJson: json,
                expiresAt: DateTime.now().add(_searchTtl),
              ),
            );
      }
      return Right<Failure, List<Food>>(merged);
    } catch (e, st) {
      LoggerService.e('searchFood', e, st);
      if (seedResults.isNotEmpty) {
        return Right<Failure, List<Food>>(seedResults);
      }
      return Left<Failure, List<Food>>(ServerFailure(e.toString()));
    }
  }

  /// Merge seed (local) results first, then append API results (deduped by
  /// case-insensitive name match).
  List<Food> _mergeFoodLists(
    List<Food> seedResults,
    List<Food> apiResults,
    int limit,
  ) {
    final Set<String> seenNames = <String>{
      for (final Food f in seedResults) f.name.toLowerCase(),
    };
    final List<Food> merged = <Food>[...seedResults];
    for (final Food food in apiResults) {
      if (!seenNames.contains(food.name.toLowerCase())) {
        merged.add(food);
        seenNames.add(food.name.toLowerCase());
      }
      if (merged.length >= limit) {
        break;
      }
    }
    return merged;
  }
}
