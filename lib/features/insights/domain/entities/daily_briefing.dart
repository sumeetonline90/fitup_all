import 'correlation_alert.dart';
import 'holistic_context.dart';

class DailyBriefing {
  const DailyBriefing({
    required this.id,
    required this.userId,
    required this.generatedAt,
    required this.morningText,
    required this.todaysGoals,
    required this.alerts,
    required this.contextSnapshot,
  });

  final String id;
  final String userId;
  final DateTime generatedAt;
  final String morningText;
  final List<String> todaysGoals;
  final List<CorrelationAlert> alerts;
  final HolisticContext contextSnapshot;
}
