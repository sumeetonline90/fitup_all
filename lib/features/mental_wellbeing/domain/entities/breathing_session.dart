import 'breathing_type.dart';

class BreathingSession {
  const BreathingSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.durationSeconds,
    required this.cyclesCompleted,
    required this.completedAt,
  });

  final String id;
  final String userId;
  final BreathingType type;
  final int durationSeconds;
  final int cyclesCompleted;
  final DateTime completedAt;
}
