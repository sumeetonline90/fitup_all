/// Cached AI meal-plan suggestion (hedging language only).
class DietPlanSuggestion {
  const DietPlanSuggestion({
    required this.summary,
    required this.mealIdeas,
    this.disclaimer =
        'This is not medical advice. Consider discussing changes with a professional.',
  });

  final String summary;
  final List<String> mealIdeas;
  final String disclaimer;

  factory DietPlanSuggestion.fromJson(Map<String, dynamic> json) {
    return DietPlanSuggestion(
      summary: json['summary'] as String? ?? '',
      mealIdeas: (json['mealIdeas'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      disclaimer: json['disclaimer'] as String? ??
          'This is not medical advice. Consider discussing changes with a professional.',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary,
      'mealIdeas': mealIdeas,
      'disclaimer': disclaimer,
    };
  }
}
