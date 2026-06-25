import 'dart:convert';

/// Parsed Pro-model weekly holistic report (before persistence).
class WeeklyReportContent {
  const WeeklyReportContent({
    required this.executiveSummary,
    required this.activityInsight,
    required this.dietInsight,
    required this.workoutInsight,
    required this.healthInsight,
    required this.mentalInsight,
    required this.wins,
    required this.focusAreas,
    required this.goalProgress,
  });

  final String executiveSummary;
  final String activityInsight;
  final String dietInsight;
  final String workoutInsight;
  final String healthInsight;
  final String mentalInsight;
  final List<String> wins;
  final List<String> focusAreas;
  final String goalProgress;
}

/// Parses Gemini weekly JSON; throws [FormatException] if not a valid object.
WeeklyReportContent parseWeeklyReportContentFromModel(String raw) {
  String slice = raw.trim();
  final int lb = slice.indexOf('{');
  final int rb = slice.lastIndexOf('}');
  if (lb >= 0 && rb > lb) {
    slice = slice.substring(lb, rb + 1);
  }
  final Object? decoded = jsonDecode(slice);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Weekly report: expected JSON object');
  }
  final Map<String, dynamic> m = decoded;
  List<String> strList(String k) {
    final Object? v = m[k];
    if (v is List<dynamic>) {
      return v.map((dynamic e) => e.toString()).toList();
    }
    return <String>[];
  }

  return WeeklyReportContent(
    executiveSummary: m['executiveSummary']?.toString() ?? '',
    activityInsight: m['activityInsight']?.toString() ?? '',
    dietInsight: m['dietInsight']?.toString() ?? '',
    workoutInsight: m['workoutInsight']?.toString() ?? '',
    healthInsight: m['healthInsight']?.toString() ?? '',
    mentalInsight: m['mentalInsight']?.toString() ?? '',
    wins: strList('wins'),
    focusAreas: strList('focusAreas'),
    goalProgress: m['goalProgress']?.toString() ?? '',
  );
}
