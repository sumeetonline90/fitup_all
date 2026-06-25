enum MoodLevel { veryBad, bad, neutral, good, veryGood }

extension MoodLevelStorage on MoodLevel {
  /// 1–5 for persistence.
  int get storageValue => index + 1;
}

/// Maps stored 1–5 to [MoodLevel].
MoodLevel moodLevelFromStorageValue(int v) {
  final int i = v < 1 ? 1 : (v > 5 ? 5 : v);
  return MoodLevel.values[i - 1];
}
