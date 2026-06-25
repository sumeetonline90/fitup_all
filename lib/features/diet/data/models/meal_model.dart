import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/meal.dart';
import '../../domain/entities/meal_type.dart';
import 'food_item_model.dart';

/// Firestore DTO for [Meal].
class MealModel {
  MealModel({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.foodItems,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.dateTime,
    this.notes,
    this.photoUrl,
    this.aiInsight,
  });

  final String id;
  final String userId;
  final MealType mealType;
  final List<FoodItemModel> foodItems;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime dateTime;
  final String? notes;
  final String? photoUrl;
  final String? aiInsight;

  factory MealModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final List<dynamic> raw = (data['foodItems'] as List<dynamic>?) ?? <dynamic>[];
    return MealModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      mealType: _parseMealType(data['mealType'] as String?),
      foodItems: raw
          .map((dynamic e) => FoodItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0,
      totalProtein: (data['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (data['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (data['totalFat'] as num?)?.toDouble() ?? 0,
      dateTime: _readDate(data['dateTime']),
      notes: data['notes'] as String?,
      photoUrl: data['photoUrl'] as String?,
      aiInsight: data['aiInsight'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'userId': userId,
      'mealType': mealType.name,
      'foodItems': foodItems.map((FoodItemModel e) => e.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'dateTime': Timestamp.fromDate(dateTime),
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (aiInsight != null) 'aiInsight': aiInsight,
    };
  }

  Meal toEntity() {
    return Meal(
      id: id,
      userId: userId,
      mealType: mealType,
      foodItems: foodItems.map((FoodItemModel e) => e.toEntity()).toList(),
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      dateTime: dateTime,
      notes: notes,
      photoUrl: photoUrl,
      aiInsight: aiInsight,
    );
  }

  factory MealModel.fromEntity(Meal m) {
    return MealModel(
      id: m.id,
      userId: m.userId,
      mealType: m.mealType,
      foodItems: m.foodItems.map(FoodItemModel.fromEntity).toList(),
      totalCalories: m.totalCalories,
      totalProtein: m.totalProtein,
      totalCarbs: m.totalCarbs,
      totalFat: m.totalFat,
      dateTime: m.dateTime,
      notes: m.notes,
      photoUrl: m.photoUrl,
      aiInsight: m.aiInsight,
    );
  }

  /// Local JSON (ISO dates) for Drift cache.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'mealType': mealType.name,
      'foodItems': foodItems.map((FoodItemModel e) => e.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'dateTime': dateTime.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (aiInsight != null) 'aiInsight': aiInsight,
    };
  }

  factory MealModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw =
        (json['foodItems'] as List<dynamic>?) ?? <dynamic>[];
    return MealModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      mealType: _parseMealType(json['mealType'] as String?),
      foodItems: raw
          .map(
            (dynamic e) =>
                FoodItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
      dateTime: DateTime.parse(json['dateTime'] as String),
      notes: json['notes'] as String?,
      photoUrl: json['photoUrl'] as String?,
      aiInsight: json['aiInsight'] as String?,
    );
  }

  static MealType _parseMealType(String? raw) {
    if (raw == null) {
      return MealType.snack;
    }
    return MealType.values.firstWhere(
      (MealType e) => e.name == raw,
      orElse: () => MealType.snack,
    );
  }

  static DateTime _readDate(dynamic v) {
    if (v is Timestamp) {
      return v.toDate();
    }
    if (v is DateTime) {
      return v;
    }
    return DateTime.now();
  }
}
