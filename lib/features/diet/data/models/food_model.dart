import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/food.dart';

/// Firestore / cache DTO for [Food].
class FoodModel {
  FoodModel({
    required this.id,
    required this.name,
    this.brand,
    this.servingSize,
    this.servingUnit,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
    this.sodiumPer100g,
    this.sugarPer100g,
    required this.category,
    this.isIndian,
    this.barcode,
    required this.source,
  });

  final String id;
  final String name;
  final String? brand;
  final String? servingSize;
  final String? servingUnit;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;
  final double? sodiumPer100g;
  final double? sugarPer100g;
  final String category;
  final bool? isIndian;
  final String? barcode;
  final FoodSource source;

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String?,
      servingSize: json['servingSize'] as String?,
      servingUnit: json['servingUnit'] as String?,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
      fiberPer100g: (json['fiberPer100g'] as num?)?.toDouble(),
      sodiumPer100g: (json['sodiumPer100g'] as num?)?.toDouble(),
      sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
      category: json['category'] as String? ?? 'general',
      isIndian: json['isIndian'] as bool?,
      barcode: json['barcode'] as String?,
      source: _parseSource(json['source'] as String?),
    );
  }

  factory FoodModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FoodModel.fromJson(<String, dynamic>{...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (brand != null) 'brand': brand,
      if (servingSize != null) 'servingSize': servingSize,
      if (servingUnit != null) 'servingUnit': servingUnit,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
      if (fiberPer100g != null) 'fiberPer100g': fiberPer100g,
      if (sodiumPer100g != null) 'sodiumPer100g': sodiumPer100g,
      if (sugarPer100g != null) 'sugarPer100g': sugarPer100g,
      'category': category,
      if (isIndian != null) 'isIndian': isIndian,
      if (barcode != null) 'barcode': barcode,
      'source': source.name,
    };
  }

  Food toEntity() {
    return Food(
      id: id,
      name: name,
      brand: brand,
      servingSize: servingSize,
      servingUnit: servingUnit,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      fiberPer100g: fiberPer100g,
      sodiumPer100g: sodiumPer100g,
      sugarPer100g: sugarPer100g,
      category: category,
      isIndian: isIndian ?? false,
      barcode: barcode,
      source: source,
    );
  }

  factory FoodModel.fromEntity(Food f) {
    return FoodModel(
      id: f.id,
      name: f.name,
      brand: f.brand,
      servingSize: f.servingSize,
      servingUnit: f.servingUnit,
      caloriesPer100g: f.caloriesPer100g,
      proteinPer100g: f.proteinPer100g,
      carbsPer100g: f.carbsPer100g,
      fatPer100g: f.fatPer100g,
      fiberPer100g: f.fiberPer100g,
      sodiumPer100g: f.sodiumPer100g,
      sugarPer100g: f.sugarPer100g,
      category: f.category,
      isIndian: f.isIndian,
      barcode: f.barcode,
      source: f.source,
    );
  }

  static FoodSource _parseSource(String? raw) {
    if (raw == null) {
      return FoodSource.custom;
    }
    return FoodSource.values.firstWhere(
      (FoodSource e) => e.name == raw,
      orElse: () => FoodSource.custom,
    );
  }
}
