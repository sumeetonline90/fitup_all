import '../entities/breathing_type.dart';

/// Phase durations in seconds for UI timers (informational).
class BreathingPattern {
  const BreathingPattern({
    required this.type,
    required this.inhaleSeconds,
    required this.holdAfterInhaleSeconds,
    required this.exhaleSeconds,
    required this.holdAfterExhaleSeconds,
  });

  final BreathingType type;
  final int inhaleSeconds;
  final int holdAfterInhaleSeconds;
  final int exhaleSeconds;
  final int holdAfterExhaleSeconds;
}

class StartBreathingSessionUseCase {
  BreathingPattern call(BreathingType type) {
    switch (type) {
      case BreathingType.boxBreathing:
        return const BreathingPattern(
          type: BreathingType.boxBreathing,
          inhaleSeconds: 4,
          holdAfterInhaleSeconds: 4,
          exhaleSeconds: 4,
          holdAfterExhaleSeconds: 4,
        );
      case BreathingType.fourSevenEight:
        return const BreathingPattern(
          type: BreathingType.fourSevenEight,
          inhaleSeconds: 4,
          holdAfterInhaleSeconds: 7,
          exhaleSeconds: 8,
          holdAfterExhaleSeconds: 0,
        );
      case BreathingType.deepBreathing:
        return const BreathingPattern(
          type: BreathingType.deepBreathing,
          inhaleSeconds: 4,
          holdAfterInhaleSeconds: 2,
          exhaleSeconds: 6,
          holdAfterExhaleSeconds: 0,
        );
    }
  }
}
