/// Anonymized profile snippet for AI health prompts (no userId).
class HealthUserProfileContext {
  const HealthUserProfileContext({
    required this.ageGroupLabel,
    required this.fitnessLevel,
    this.bodyMetricsLines = '',
  });

  final String ageGroupLabel;
  final String fitnessLevel;

  /// Weight / height / BMI lines for holistic prompts (no raw PII beyond metrics).
  final String bodyMetricsLines;
}
