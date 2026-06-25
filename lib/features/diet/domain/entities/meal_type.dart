/// Meal slot in a day.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

/// UI labels and routing helpers.
extension MealTypeLabel on MealType {
  /// Display title (e.g. Breakfast).
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };

  /// Short label for chips.
  String get shortLabel => switch (this) {
        MealType.breakfast => 'B',
        MealType.lunch => 'L',
        MealType.dinner => 'D',
        MealType.snack => 'S',
      };
}

/// Parses [MealType.name] from a route/query segment.
MealType mealTypeFromRouteParam(String? raw) {
  if (raw == null || raw.isEmpty) {
    return MealType.breakfast;
  }
  final String lower = raw.toLowerCase().trim();
  for (final MealType m in MealType.values) {
    if (m.name == lower) {
      return m;
    }
  }
  return MealType.breakfast;
}
