class GoalAdjustment {
  const GoalAdjustment({
    required this.id,
    required this.userId,
    required this.currentGoal,
    required this.suggestion,
    required this.rationale,
    required this.generatedAt,
    this.isAccepted = false,
  });

  final String id;
  final String userId;
  final String currentGoal;
  final String suggestion;
  final String rationale;
  final DateTime generatedAt;
  final bool isAccepted;
}
