import 'correlation_alert.dart';

class WeeklyReport {
  const WeeklyReport({
    required this.id,
    required this.userId,
    required this.weekStarting,
    required this.generatedAt,
    required this.executiveSummary,
    required this.moduleInsights,
    required this.wins,
    required this.focusAreas,
    required this.crossModuleInsights,
    required this.goalProgressText,
    this.isPlaceholder = false,
  });

  final String id;
  final String userId;
  final DateTime weekStarting;
  final DateTime generatedAt;
  final String executiveSummary;
  final Map<String, String> moduleInsights;
  final List<String> wins;
  final List<String> focusAreas;
  final List<CorrelationAlert> crossModuleInsights;
  final String goalProgressText;

  /// No Pro generation ran; show CTA instead of full report (ADR-016).
  final bool isPlaceholder;

  /// Shown when cache is empty and auto Pro is not allowed (hub cold watch).
  factory WeeklyReport.placeholder(String userId, DateTime weekStartingMonday) {
    final String wk =
        '${weekStartingMonday.year.toString().padLeft(4, '0')}-'
        '${weekStartingMonday.month.toString().padLeft(2, '0')}-'
        '${weekStartingMonday.day.toString().padLeft(2, '0')}';
    return WeeklyReport(
      id: 'wk-placeholder-$userId-$wk',
      userId: userId,
      weekStarting: weekStartingMonday,
      generatedAt: DateTime.now(),
      executiveSummary:
          'Your weekly holistic report uses a richer model and is generated '
          'only when you tap below, or automatically on Sundays when enabled. '
          'Nothing has been sent yet.',
      moduleInsights: const <String, String>{},
      wins: const <String>[],
      focusAreas: const <String>[],
      crossModuleInsights: const <CorrelationAlert>[],
      goalProgressText: '',
      isPlaceholder: true,
    );
  }
}
