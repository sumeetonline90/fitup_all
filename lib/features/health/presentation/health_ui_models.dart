import '../domain/entities/menstrual_cycle.dart';
import '../domain/entities/vital_status.dart';
import '../domain/entities/vital_type.dart';

/// Single tile on the health dashboard grid.
class VitalSummaryTile {
  const VitalSummaryTile({
    required this.type,
    this.latestValue,
    this.recordedAt,
    required this.status,
    required this.hasData,
  });

  final VitalType type;
  final double? latestValue;
  final DateTime? recordedAt;
  final VitalStatus status;
  final bool hasData;
}

class HealthSummaryUi {
  const HealthSummaryUi({
    required this.vitalsLoggedCount,
    required this.needAttentionCount,
    required this.tiles,
  });

  final int vitalsLoggedCount;
  final int needAttentionCount;
  final List<VitalSummaryTile> tiles;
}

enum VitalLogSource { manual, labUpload, profileSync }

class VitalReadingEntry {
  const VitalReadingEntry({
    required this.id,
    required this.type,
    required this.value,
    required this.recordedAt,
    required this.source,
    this.notes,
  });

  final String id;
  final VitalType type;
  final double value;
  final DateTime recordedAt;
  final VitalLogSource source;
  final String? notes;
}

class MedicationUi {
  const MedicationUi({
    required this.id,
    required this.name,
    required this.dose,
    required this.frequency,
    required this.startDate,
    this.nextReminder,
  });

  final String id;
  final String name;
  final String dose;
  final String frequency;
  final DateTime startDate;
  final DateTime? nextReminder;
}

class ExtractedVitalRow {
  ExtractedVitalRow({
    required this.name,
    required this.value,
    required this.unit,
    this.mappedType,
    this.included = true,
    this.isDuplicate = false,
  });

  final String name;
  final double value;
  final String unit;
  final VitalType? mappedType;
  bool included;

  /// True when another row maps to the same [VitalType] earlier in the list.
  final bool isDuplicate;
}

/// Marks duplicate [VitalType] rows: first occurrence stays included; later
/// duplicates default to unchecked and [isDuplicate] true.
List<ExtractedVitalRow> markDuplicateVitalRows(List<ExtractedVitalRow> rows) {
  final Set<VitalType> seen = <VitalType>{};
  return rows.map((ExtractedVitalRow r) {
    final VitalType? t = r.mappedType;
    if (t == null) {
      return ExtractedVitalRow(
        name: r.name,
        value: r.value,
        unit: r.unit,
        mappedType: r.mappedType,
        included: r.included,
        isDuplicate: false,
      );
    }
    final bool dup = seen.contains(t);
    if (!dup) {
      seen.add(t);
    }
    return ExtractedVitalRow(
      name: r.name,
      value: r.value,
      unit: r.unit,
      mappedType: r.mappedType,
      included: dup ? false : r.included,
      isDuplicate: dup,
    );
  }).toList();
}

class MenstrualDayUi {
  const MenstrualDayUi({required this.date, required this.phase});

  final DateTime date;
  final MenstrualPhase phase;
}

enum MenstrualPhase { none, period, fertile, ovulation }

class MenstrualStateData {
  MenstrualStateData({required this.periodDayKeys, required this.cycleAnchor});

  final Set<String> periodDayKeys;
  final DateTime cycleAnchor;
}

/// Normalized calendar key `yyyy-MM-dd`.
String menstrualDayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Builds calendar UI state from persisted [MenstrualCycle] rows (cycle starts = period days).
MenstrualStateData menstrualStateFromHistory(List<MenstrualCycle> cycles) {
  final Set<String> periodDayKeys = <String>{};
  DateTime? latestStart;
  for (final MenstrualCycle c in cycles) {
    final DateTime start = DateTime(
      c.cycleStart.year,
      c.cycleStart.month,
      c.cycleStart.day,
    );
    periodDayKeys.add(menstrualDayKey(start));
    if (latestStart == null || start.isAfter(latestStart)) {
      latestStart = start;
    }
  }
  final DateTime now = DateTime.now();
  final DateTime anchor = latestStart ?? DateTime(now.year, now.month, now.day);
  return MenstrualStateData(periodDayKeys: periodDayKeys, cycleAnchor: anchor);
}

/// Phase estimate from anchor + 28-day model (same heuristic as legacy in-memory notifier).
MenstrualPhase menstrualPhaseFor(MenstrualStateData state, DateTime day) {
  final DateTime d = DateTime(day.year, day.month, day.day);
  final String k = menstrualDayKey(d);
  if (state.periodDayKeys.contains(k)) {
    return MenstrualPhase.period;
  }
  final int diff = d
      .difference(
        DateTime(
          state.cycleAnchor.year,
          state.cycleAnchor.month,
          state.cycleAnchor.day,
        ),
      )
      .inDays;
  final int m = diff % 28;
  if (m < 0) {
    return MenstrualPhase.none;
  }
  if (m == 13) {
    return MenstrualPhase.ovulation;
  }
  if (m >= 10 && m <= 16) {
    return MenstrualPhase.fertile;
  }
  return MenstrualPhase.none;
}
