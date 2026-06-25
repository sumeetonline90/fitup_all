import '../../features/diet/domain/entities/food_item.dart';

/// Vision / text parsing output for meal logging.
class MealAnalysisResult {
  const MealAnalysisResult({
    required this.items,
    this.note,
  });

  final List<FoodItem> items;
  final String? note;
}
