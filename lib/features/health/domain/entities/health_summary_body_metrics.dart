import '../../../profile/domain/entities/user_profile.dart';
import 'health_summary.dart';
import 'vital_entry.dart';
import 'vital_reference_range.dart';
import 'vital_source.dart';
import 'vital_type.dart';
import 'vital_type_extension.dart';

/// BMI from weight (kg) and height (cm). Returns null if height invalid.
double? computeBmiKgM2(double weightKg, double heightCm) {
  if (heightCm <= 0) {
    return null;
  }
  final double m = heightCm / 100.0;
  return weightKg / (m * m);
}

/// Writes or clears [VitalType.bmi] in [latest] from weight + height entries.
void injectComputedBmiIntoLatest(
  Map<VitalType, VitalEntry?> latest,
  String userId,
) {
  final VitalEntry? w = latest[VitalType.bodyWeight];
  final VitalEntry? h = latest[VitalType.heightCm];
  if (w == null || h == null || h.value <= 0) {
    latest[VitalType.bmi] = null;
    return;
  }
  final double? b = computeBmiKgM2(w.value, h.value);
  if (b == null) {
    latest[VitalType.bmi] = null;
    return;
  }
  final DateTime at = w.recordedAt.isAfter(h.recordedAt)
      ? w.recordedAt
      : h.recordedAt;
  latest[VitalType.bmi] = VitalEntry(
    id: 'computed-bmi-${DateTime.now().microsecondsSinceEpoch}',
    userId: userId,
    type: VitalType.bmi,
    value: double.parse(b.toStringAsFixed(1)),
    unit: VitalType.bmi.unit,
    recordedAt: at,
    source: VitalSource.manual,
    notes: 'Derived from latest weight and height',
  );
}

/// Counts non-derived vitals by reference range (excludes derived types).
({int normal, int attention}) countVitalRangeStats(
  Map<VitalType, VitalEntry?> latest,
) {
  int normal = 0;
  int attention = 0;
  for (final VitalEntry? e in latest.values) {
    if (e == null || e.type.isDerived) {
      continue;
    }
    final RangeStatus st = VitalReferenceRanges.statusFor(e.type, e.value);
    if (st == RangeStatus.normal) {
      normal++;
    } else {
      attention++;
    }
  }
  return (normal: normal, attention: attention);
}

/// Fills missing weight/height from [profile], injects BMI, recomputes counts.
HealthSummary mergeHealthSummaryWithProfileBodyMetrics({
  required HealthSummary base,
  required String userId,
  UserProfile? profile,
}) {
  final Map<VitalType, VitalEntry?> latest = <VitalType, VitalEntry?>{
    for (final MapEntry<VitalType, VitalEntry?> e in base.latestVitals.entries)
      e.key: e.value,
  };
  final DateTime? profAt = profile?.updatedAt;
  if (latest[VitalType.bodyWeight] == null &&
      profile != null &&
      profile.weightKg != null) {
    latest[VitalType.bodyWeight] = VitalEntry(
      id: 'profile-fill-bodyWeight',
      userId: userId,
      type: VitalType.bodyWeight,
      value: profile.weightKg!,
      unit: VitalType.bodyWeight.unit,
      recordedAt: profAt ?? DateTime.now(),
      source: VitalSource.profileSync,
      notes: 'From profile',
    );
  }
  if (latest[VitalType.heightCm] == null &&
      profile != null &&
      profile.heightCm != null) {
    latest[VitalType.heightCm] = VitalEntry(
      id: 'profile-fill-heightCm',
      userId: userId,
      type: VitalType.heightCm,
      value: profile.heightCm!,
      unit: VitalType.heightCm.unit,
      recordedAt: profAt ?? DateTime.now(),
      source: VitalSource.profileSync,
      notes: 'From profile',
    );
  }
  injectComputedBmiIntoLatest(latest, userId);
  final ({int normal, int attention}) counts = countVitalRangeStats(latest);
  return HealthSummary(
    latestVitals: latest,
    trends: base.trends,
    activeMedications: base.activeMedications,
    vitalsInNormalRange: counts.normal,
    vitalsNeedingAttention: counts.attention,
  );
}

/// Compact weight / height / BMI lines for AI prompts (numeric only).
String bodyMetricsLinesFromSummary(HealthSummary summary) {
  final StringBuffer sb = StringBuffer();
  final VitalEntry? w = summary.latestVitals[VitalType.bodyWeight];
  final VitalEntry? h = summary.latestVitals[VitalType.heightCm];
  final VitalEntry? b = summary.latestVitals[VitalType.bmi];
  if (w != null) {
    sb.writeln('Weight ${w.value} kg');
  }
  if (h != null) {
    sb.writeln('Height ${h.value} cm');
  }
  if (b != null) {
    sb.writeln('BMI ${b.value}');
  }
  return sb.toString().trim();
}
