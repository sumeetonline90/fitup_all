import '../domain/entities/food_item.dart';

/// Picked from photo flow with portion.
class PhotoFoodPick {
  const PhotoFoodPick({required this.food, required this.grams});

  final CatalogFood food;
  final double grams;

  FoodItem toFoodItem() => food.toFoodItem(grams: grams);
}

/// Lightweight catalog row for search / barcode / photo flows (UI mock).
class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g,
  });

  final String id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? fiberPer100g;

  /// Builds a line item for [grams] of this food.
  FoodItem toFoodItem({required double grams}) {
    final double s = grams / 100.0;
    return FoodItem(
      id: 'item-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      quantity: grams,
      unit: 'g',
      calories: caloriesPer100g * s,
      protein: proteinPer100g * s,
      carbs: carbsPer100g * s,
      fat: fatPer100g * s,
      fiber: fiberPer100g != null ? fiberPer100g! * s : null,
    );
  }
}

/// Demo foods for search / recent / frequent tabs.
final List<CatalogFood> kMockCatalogFoods = <CatalogFood>[
  const CatalogFood(
    id: 'm1',
    name: 'Masoor Dal (cooked)',
    brand: 'Home',
    caloriesPer100g: 116,
    proteinPer100g: 9,
    carbsPer100g: 20,
    fatPer100g: 0.4,
    fiberPer100g: 8,
  ),
  const CatalogFood(
    id: 'm2',
    name: 'Basmati Rice (cooked)',
    brand: 'India Gate',
    caloriesPer100g: 130,
    proteinPer100g: 2.7,
    carbsPer100g: 28,
    fatPer100g: 0.3,
  ),
  const CatalogFood(
    id: 'm3',
    name: 'Paneer',
    brand: 'Amul',
    caloriesPer100g: 265,
    proteinPer100g: 18,
    carbsPer100g: 2,
    fatPer100g: 20,
  ),
  const CatalogFood(
    id: 'm4',
    name: 'Roti (whole wheat)',
    brand: null,
    caloriesPer100g: 297,
    proteinPer100g: 11,
    carbsPer100g: 46,
    fatPer100g: 7,
    fiberPer100g: 7,
  ),
];
