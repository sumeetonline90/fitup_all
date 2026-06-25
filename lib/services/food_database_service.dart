import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../core/constants/env_config.dart';
import '../core/database/fitup_database.dart';
import '../features/diet/domain/entities/food.dart';
import '../features/diet/data/models/food_model.dart';
import 'logger_service.dart';

/// Open Food Facts + optional Gemini fallback + Drift catalog cache.
class FoodDatabaseService {
  FoodDatabaseService({
    http.Client? httpClient,
    FitupDatabase? database,
  })  : _http = httpClient ?? http.Client(),
        _db = database;

  final http.Client _http;
  final FitupDatabase? _db;

  static const String _offProductBase =
      'https://world.openfoodfacts.org/api/v2/product';
  static const String _offSearch =
      'https://world.openfoodfacts.org/cgi/search.pl';

  GenerativeModel get _flash => GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: EnvConfig.geminiApiKey,
      );

  /// Fetch product by barcode; cache in [FoodCatalogCache] when DB available.
  Future<Food?> fetchProductByBarcode(String barcode) async {
    final String trimmed = barcode.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final String cacheId = 'off_$trimmed';
    final Food? cached = await _readCatalogCache(cacheId);
    if (cached != null) {
      return cached;
    }
    try {
      final http.Response res = await _http.get(
        Uri.parse('$_offProductBase/$trimmed.json'),
      );
      if (res.statusCode != 200) {
        return _geminiFallbackBarcode(trimmed);
      }
      final Object? decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return _geminiFallbackBarcode(trimmed);
      }
      final Food? food = _parseOffProduct(decoded, trimmed);
      if (food != null) {
        await _writeCatalogCache(food);
        return food;
      }
      return _geminiFallbackBarcode(trimmed);
    } catch (e, st) {
      LoggerService.e('OFF barcode', e, st);
      return _geminiFallbackBarcode(trimmed);
    }
  }

  /// Text search (Open Food Facts search.pl).
  Future<List<Food>> searchProducts(
    String query, {
    int limit = 20,
    bool preferIndian = false,
  }) async {
    final String q = query.trim();
    if (q.isEmpty) {
      return <Food>[];
    }
    try {
      final Uri uri = Uri.parse(_offSearch).replace(
        queryParameters: <String, String>{
          'search_terms': q,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': limit.toString(),
        },
      );
      final http.Response res = await _http.get(uri);
      if (res.statusCode != 200) {
        return <Food>[];
      }
      final Object? decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        return <Food>[];
      }
      final Object? rawProducts = decoded['products'];
      final List<dynamic> products =
          rawProducts is List<dynamic> ? rawProducts : <dynamic>[];
      final List<Food> out = <Food>[];
      for (final dynamic p in products) {
        if (p is! Map<String, dynamic>) {
          continue;
        }
        final Food? f = _parseOffSearchHit(p);
        if (f != null) {
          if (preferIndian && !f.isIndian) {
            continue;
          }
          out.add(f);
        }
        if (out.length >= limit) {
          break;
        }
      }
      return out;
    } catch (e, st) {
      LoggerService.e('OFF search', e, st);
      return <Food>[];
    }
  }

  Food? _parseOffProduct(Map<String, dynamic> root, String barcode) {
    final Object? status = root['status'];
    if (status is num && status != 1) {
      return null;
    }
    final Map<String, dynamic>? product =
        root['product'] as Map<String, dynamic>?;
    if (product == null) {
      return null;
    }
    final Map<String, dynamic>? nut =
        product['nutriments'] as Map<String, dynamic>?;
    final String name =
        (product['product_name'] as String?)?.trim().isNotEmpty == true
            ? product['product_name'] as String
            : 'Unknown product';
    final String? brand = product['brands'] as String?;
    final bool isIndian = _isIndianProduct(product);
    final double kcal = _num(nut, 'energy-kcal_100g', 'energy_100g') ?? 0;
    final double prot = _num(nut, 'proteins_100g') ?? 0;
    final double carbs = _num(nut, 'carbohydrates_100g') ?? 0;
    final double fat = _num(nut, 'fat_100g') ?? 0;
    final double? fiber = _num(nut, 'fiber_100g');
    final double? sodium = _num(nut, 'sodium_100g');
    final double? sugar = _num(nut, 'sugars_100g');
    return Food(
      id: 'off_$barcode',
      name: name,
      brand: brand,
      servingSize: product['serving_size'] as String?,
      servingUnit: 'g',
      caloriesPer100g: kcal,
      proteinPer100g: prot,
      carbsPer100g: carbs,
      fatPer100g: fat,
      fiberPer100g: fiber,
      sodiumPer100g: sodium,
      sugarPer100g: sugar,
      category: (product['categories'] as String?) ?? 'packaged',
      isIndian: isIndian,
      barcode: barcode,
      source: FoodSource.openFoodFacts,
    );
  }

  Food? _parseOffSearchHit(Map<String, dynamic> p) {
    final String? code = p['code'] as String?;
    if (code == null) {
      return null;
    }
    final Map<String, dynamic> wrapped = <String, dynamic>{
      'status': 1,
      'product': p,
    };
    return _parseOffProduct(wrapped, code);
  }

  bool _isIndianProduct(Map<String, dynamic> product) {
    final Object? rawTags = product['countries_tags'];
    final List<dynamic> tags =
        rawTags is List<dynamic> ? rawTags : <dynamic>[];
    return tags.any(
      (dynamic e) => e.toString().toLowerCase().contains('india'),
    );
  }

  double? _num(Map<String, dynamic>? nut, String a, [String? b]) {
    if (nut == null) {
      return null;
    }
    final Object? v = nut[a] ?? (b != null ? nut[b] : null);
    if (v is num) {
      return v.toDouble();
    }
    return null;
  }

  Future<Food?> _geminiFallbackBarcode(String barcode) async {
    try {
      final GenerateContentResponse res = await _flash.generateContent(
        <Content>[
          Content.text(
            'A packaged food barcode $barcode was not found in Open Food Facts. '
            'Respond with JSON only: '
            '{"name":"...","caloriesPer100g":0,"proteinPer100g":0,"carbohydratesPer100g":0,"fatPer100g":0,"category":"unknown","isIndian":false} '
            'Use plausible estimates for a generic packaged snack; do not claim medical truth.',
          ),
        ],
      );
      final String? t = res.text;
      if (t == null) {
        return null;
      }
      final int start = t.indexOf('{');
      final int end = t.lastIndexOf('}');
      if (start < 0 || end <= start) {
        return null;
      }
      final Map<String, dynamic> map =
          jsonDecode(t.substring(start, end + 1)) as Map<String, dynamic>;
      final Food food = Food(
        id: 'ai_$barcode',
        name: map['name'] as String? ?? 'Packaged food',
        caloriesPer100g: (map['caloriesPer100g'] as num?)?.toDouble() ?? 0,
        proteinPer100g: (map['proteinPer100g'] as num?)?.toDouble() ?? 0,
        carbsPer100g:
            (map['carbohydratesPer100g'] as num?)?.toDouble() ?? 0,
        fatPer100g: (map['fatPer100g'] as num?)?.toDouble() ?? 0,
        category: map['category'] as String? ?? 'unknown',
        isIndian: map['isIndian'] as bool? ?? false,
        barcode: barcode,
        source: FoodSource.aiGenerated,
      );
      await _writeCatalogCache(food);
      return food;
    } catch (e, st) {
      LoggerService.e('Gemini food fallback', e, st);
      return null;
    }
  }

  Future<Food?> _readCatalogCache(String id) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return null;
    }
    final FoodCatalogCacheRow? row = await (db.select(db.foodCatalogCache)
          ..where(($FoodCatalogCacheTable t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return FoodModel.fromJson(
      jsonDecode(row.payloadJson) as Map<String, dynamic>,
    ).toEntity();
  }

  Future<void> _writeCatalogCache(Food food) async {
    final FitupDatabase? db = _db;
    if (db == null) {
      return;
    }
    final String json = jsonEncode(FoodModel.fromEntity(food).toJson());
    await db.into(db.foodCatalogCache).insertOnConflictUpdate(
          FoodCatalogCacheCompanion.insert(
            id: food.id,
            payloadJson: json,
            cachedAt: DateTime.now(),
          ),
        );
  }

  void dispose() {
    _http.close();
  }
}
