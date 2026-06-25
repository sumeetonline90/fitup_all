/// Structured AI response for module / holistic insights.
class AiInsight {
  const AiInsight({
    required this.summary,
    required this.details,
    required this.suggestions,
    this.disclaimer =
        'This is not medical advice. Consult a healthcare professional.',
  });

  final String summary;
  final List<String> details;
  final List<String> suggestions;
  final String disclaimer;
}
