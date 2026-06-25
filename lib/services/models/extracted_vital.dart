/// One row parsed from lab report vision (before mapping to [VitalType]).
class ExtractedVital {
  const ExtractedVital({
    required this.metricName,
    required this.value,
    required this.unit,
    this.referenceRangeMentioned,
    this.typeKey,
  });

  final String metricName;
  final double value;
  final String unit;
  final String? referenceRangeMentioned;

  /// When set, matches [VitalType.name] from strict JSON (`type` field).
  final String? typeKey;
}
