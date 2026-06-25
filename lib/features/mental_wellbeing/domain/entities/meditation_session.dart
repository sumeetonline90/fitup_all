class MeditationSession {
  const MeditationSession({
    required this.id,
    required this.userId,
    required this.durationSeconds,
    required this.completedAt,
    required this.completed,
    this.ambientSound,
  });

  final String id;
  final String userId;
  final int durationSeconds;
  final String? ambientSound;
  final DateTime completedAt;
  final bool completed;
}
