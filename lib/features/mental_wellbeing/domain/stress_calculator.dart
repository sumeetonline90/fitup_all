import 'entities/stress_level.dart';

/// Weighted 0–100 stress estimate from normalized component scores (0–100 each).
/// Higher [hrvNorm] means better HRV → lower stress contribution.
class StressCalculator {
  StressCalculator._();

  static const double weight = 0.25;

  static double computeRawStress({
    double? hrvNorm,
    double? sleepNorm,
    double? moodNorm,
    double? surveyNorm,
  }) {
    double use(double? v) => (v ?? 50).clamp(0, 100);
    final double h = use(hrvNorm);
    final double s = use(sleepNorm);
    final double m = use(moodNorm);
    final double su = use(surveyNorm);
    return (100 - h) * weight +
        (100 - s) * weight +
        (100 - m) * weight +
        (100 - su) * weight;
  }

  static StressLevel levelFor(double stress0to100) {
    final double s = stress0to100.clamp(0, 100);
    if (s < 30) {
      return StressLevel.low;
    }
    if (s < 55) {
      return StressLevel.moderate;
    }
    if (s < 80) {
      return StressLevel.high;
    }
    return StressLevel.critical;
  }

  /// Map mood storage 1–5 (very bad → very good) to stress contribution (0–100, higher = calmer).
  static double moodToCalmNorm(int mood1to5) {
    final int m = mood1to5.clamp(1, 5);
    return ((m - 1) / 4) * 100;
  }

  /// Map PHQ-9 / GAD-7 total to survey stress norm (higher score → higher stress → lower "calm" norm).
  static double phqGadTotalToStressNorm(int total, {required int maxScore}) {
    final double t = total.clamp(0, maxScore).toDouble();
    return 100 - (t / maxScore) * 100;
  }
}
