import '../../domain/entities/food_item.dart';

/// JSON DTO for [FoodItem] (nested in meals + AI).
class FoodItemModel {
  FoodItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
    this.sugar,
    this.servingSize,
    this.barcode,
    this.isCustom,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sodium;
  final double? sugar;
  final String? servingSize;
  final String? barcode;
  final bool? isCustom;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'g',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble(),
      sodium: (json['sodium'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      servingSize: json['servingSize'] as String?,
      barcode: json['barcode'] as String?,
      isCustom: json['isCustom'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      if (fiber != null) 'fiber': fiber,
      if (sodium != null) 'sodium': sodium,
      if (sugar != null) 'sugar': sugar,
      if (servingSize != null) 'servingSize': servingSize,
      if (barcode != null) 'barcode': barcode,
      if (isCustom != null) 'isCustom': isCustom,
    };
  }

  FoodItem toEntity() {
    return FoodItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
      sugar: sugar,
      servingSize: servingSize,
      barcode: barcode,
      isCustom: isCustom ?? false,
    );
  }

  factory FoodItemModel.fromEntity(FoodItem e) {
    return FoodItemModel(
      id: e.id,
      name: e.name,
      quantity: e.quantity,
      unit: e.unit,
      calories: e.calories,
      protein: e.protein,
      carbs: e.carbs,
      fat: e.fat,
      fiber: e.fiber,
      sodium: e.sodium,
      sugar: e.sugar,
      servingSize: e.servingSize,
      barcode: e.barcode,
      isCustom: e.isCustom,
    );
  }
}
