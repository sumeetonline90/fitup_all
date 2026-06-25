enum BreathingPattern { box478, relaxing478, deep552 }

extension BreathingPatternX on BreathingPattern {
  String get title => switch (this) {
    BreathingPattern.box478 => 'Box Breathing',
    BreathingPattern.relaxing478 => '4-7-8 Breathing',
    BreathingPattern.deep552 => 'Deep Breathing',
  };

  String get subtitle => switch (this) {
    BreathingPattern.box478 => '4s inhale · 4s hold · 4s exhale · 4s hold',
    BreathingPattern.relaxing478 => '4s inhale · 7s hold · 8s exhale',
    BreathingPattern.deep552 => '5s inhale · 2s hold · 5s exhale',
  };

  /// Phase durations in seconds: inhale, hold1, exhale, hold2 (0 if unused).
  List<int> get phaseSeconds => switch (this) {
    BreathingPattern.box478 => <int>[4, 4, 4, 4],
    BreathingPattern.relaxing478 => <int>[4, 7, 8, 0],
    BreathingPattern.deep552 => <int>[5, 2, 5, 0],
  };

  int get cyclesTarget => 8;
}

BreathingPattern? breathingPatternFromName(String? n) {
  if (n == null) {
    return null;
  }
  for (final BreathingPattern p in BreathingPattern.values) {
    if (p.name == n) {
      return p;
    }
  }
  return null;
}
