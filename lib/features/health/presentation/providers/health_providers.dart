import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/ai_input_sanitizer.dart';
import '../../../../services/ai_service.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/flow_intensity.dart';
import '../../domain/entities/health_summary.dart';
import '../../domain/entities/health_summary_body_metrics.dart';
import '../../domain/entities/health_user_profile_context.dart';
import '../../domain/entities/lab_report_scan.dart';
import '../../domain/entities/medication_log.dart';
import '../../domain/entities/menstrual_cycle.dart';
import '../../domain/entities/medication_reminder_time.dart';
import '../../domain/entities/vital_entry.dart';
import '../../domain/entities/vital_source.dart';
import '../../domain/entities/vital_reference.dart';
import '../../domain/entities/vital_status.dart';
import '../../domain/entities/vital_type.dart';
import '../../domain/entities/vital_type_extension.dart';
import '../../domain/repositories/health_repository.dart';
import '../../data/lab_metric_mapper.dart';
import '../../domain/usecases/get_health_summary.dart';
import '../../domain/usecases/get_vital_trends.dart';
import '../../domain/usecases/log_menstrual_cycle.dart';
import '../../domain/usecases/log_vital.dart';
import '../../domain/usecases/scan_lab_report.dart';
import '../../../../services/models/extracted_vital.dart';
import '../../data/lab_text_pre_parser.dart';
import '../health_ui_models.dart';

part 'health_providers.g.dart';

FitupUser? _userFromAuth(AsyncValue<FitupUser?> auth) {
  return switch (auth) {
    AsyncData<FitupUser?>(:final value) => value,
    _ => null,
  };
}

FitupUser? _currentUser(Ref ref) => _userFromAuth(ref.watch(authStateProvider));

UserProfile? _profileForSignedInUser(Ref ref, String userId) {
  final UserProfile? p = ref.watch(userProfileProvider).value;
  if (p == null || p.userId != userId) {
    return null;
  }
  return p;
}

VitalLogSource _vitalDomainSourceToLog(VitalSource s) {
  return switch (s) {
    VitalSource.labUpload => VitalLogSource.labUpload,
    VitalSource.profileSync => VitalLogSource.profileSync,
    VitalSource.manual || VitalSource.healthConnect => VitalLogSource.manual,
  };
}

VitalReadingEntry _vitalEntryToReading(VitalEntry v) {
  return VitalReadingEntry(
    id: v.id,
    type: v.type,
    value: v.value,
    recordedAt: v.recordedAt,
    source: _vitalDomainSourceToLog(v.source),
    notes: v.notes,
  );
}

String _ageGroupLabel(DateTime? dob) {
  if (dob == null) {
    return 'unspecified';
  }
  final DateTime now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  if (age < 13) {
    return 'child';
  }
  if (age < 18) {
    return 'teen';
  }
  if (age < 30) {
    return 'young_adult';
  }
  if (age < 45) {
    return 'adult';
  }
  if (age < 60) {
    return 'middle_age';
  }
  return 'older_adult';
}

MedicationUi _medicationToUi(MedicationLog m) {
  DateTime? nextReminder;
  final MedicationReminderTime? rt = m.reminderTime;
  if (rt != null) {
    final DateTime n = DateTime.now();
    nextReminder = DateTime(n.year, n.month, n.day, rt.hour, rt.minute);
  }
  return MedicationUi(
    id: m.id,
    name: m.medicationName,
    dose: m.dose,
    frequency: m.frequency,
    startDate: m.startDate,
    nextReminder: nextReminder,
  );
}

@riverpod
HealthRepository healthRepository(Ref ref) => getIt<HealthRepository>();

@riverpod
AiService aiService(Ref ref) => getIt<AiService>();

/// Recent vitals from Firestore (newest first).
@riverpod
Stream<List<VitalEntry>> recentVitals(Ref ref) {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    return Stream<List<VitalEntry>>.value(<VitalEntry>[]);
  }
  return ref
      .read(healthRepositoryProvider)
      .watchRecentVitals(u.id, limit: 100)
      .map(
        (Either<Failure, List<VitalEntry>> e) => e.fold(
          (Failure _) => <VitalEntry>[],
          (List<VitalEntry> list) => list,
        ),
      );
}

/// Same stream as UI rows for the health dashboard lists.
@riverpod
Stream<List<VitalReadingEntry>> vitalReadingEntries(Ref ref) {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    return Stream<List<VitalReadingEntry>>.value(<VitalReadingEntry>[]);
  }
  return ref
      .read(healthRepositoryProvider)
      .watchRecentVitals(u.id, limit: 100)
      .map(
        (Either<Failure, List<VitalEntry>> e) => e.fold(
          (Failure _) => <VitalReadingEntry>[],
          (List<VitalEntry> list) => list.map(_vitalEntryToReading).toList(),
        ),
      );
}

@riverpod
Future<List<VitalEntry>> vitalTrend(Ref ref, VitalType type) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final GetVitalTrendsUseCase uc = GetVitalTrendsUseCase(
    ref.read(healthRepositoryProvider),
  );
  final Either<Failure, List<VitalEntry>> r = await uc(u.id, type);
  return r.fold((Failure f) => throw f, (List<VitalEntry> list) => list);
}

@riverpod
Future<List<VitalReadingEntry>> vitalReadingsForType(
  Ref ref,
  VitalType type,
) async {
  final List<VitalEntry> list = await ref.watch(
    vitalTrendProvider(type).future,
  );
  return list.map(_vitalEntryToReading).toList();
}

@riverpod
Future<HealthSummary> healthSummaryData(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  ref.watch(userProfileProvider);
  final UserProfile? profile = _profileForSignedInUser(ref, u.id);
  final GetHealthSummaryUseCase uc = GetHealthSummaryUseCase(
    ref.read(healthRepositoryProvider),
  );
  final Either<Failure, HealthSummary> r = await uc(u.id);
  return r.fold(
    (Failure f) => throw f,
    (HealthSummary s) => mergeHealthSummaryWithProfileBodyMetrics(
      base: s,
      userId: u.id,
      profile: profile,
    ),
  );
}

@riverpod
Future<HealthSummaryUi> healthSummary(Ref ref) async {
  final HealthSummary s = await ref.watch(healthSummaryDataProvider.future);
  int logged = 0;
  for (final VitalEntry? e in s.latestVitals.values) {
    if (e != null && !e.type.isDerived) {
      logged++;
    }
  }
  final List<VitalSummaryTile> tiles = VitalType.values.map((VitalType t) {
    final VitalEntry? e = s.latestVitals[t];
    if (e == null) {
      return VitalSummaryTile(
        type: t,
        status: VitalStatus.unknown,
        hasData: false,
      );
    }
    return VitalSummaryTile(
      type: t,
      latestValue: e.value,
      recordedAt: e.recordedAt,
      status: statusForReading(t, e.value),
      hasData: true,
    );
  }).toList();
  return HealthSummaryUi(
    vitalsLoggedCount: logged,
    needAttentionCount: s.vitalsNeedingAttention,
    tiles: tiles,
  );
}

@riverpod
Future<String> healthInsight(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final HealthSummary summary = await ref.watch(
    healthSummaryDataProvider.future,
  );
  final UserProfile? p = _profileForSignedInUser(ref, u.id);
  final String bodyRaw = bodyMetricsLinesFromSummary(summary);
  final String bodyBlock = bodyRaw.isEmpty
      ? ''
      : AiInputSanitizer.sanitizeContextSnippet(bodyRaw, maxLength: 220);
  final Either<Failure, String> r = await ref
      .read(aiServiceProvider)
      .getHealthInsight(
        cacheUserId: u.id,
        summary: summary,
        profile: HealthUserProfileContext(
          ageGroupLabel: _ageGroupLabel(p?.dateOfBirth),
          fitnessLevel: p?.fitnessLevel.name ?? 'unspecified',
          bodyMetricsLines: bodyBlock,
        ),
      );
  return r.fold((Failure f) => throw f, (String text) => text);
}

@riverpod
class VitalLoggerNotifier extends _$VitalLoggerNotifier {
  @override
  void build() {}

  /// Persists profile weight/height as vitals (no write-back to profile).
  Future<void> syncBodyVitalsFromProfile(UserProfile profile) async {
    if (profile.userId.isEmpty) {
      return;
    }
    final DateTime at = profile.updatedAt ?? DateTime.now();
    if (profile.weightKg != null) {
      await logVital(
        type: VitalType.bodyWeight,
        value: profile.weightKg!,
        recordedAt: at,
        source: VitalLogSource.profileSync,
      );
    }
    if (profile.heightCm != null) {
      await logVital(
        type: VitalType.heightCm,
        value: profile.heightCm!,
        recordedAt: at,
        source: VitalLogSource.profileSync,
      );
    }
  }

  Future<void> _pushBodyMetricToProfile({
    required String userId,
    required VitalType type,
    required double value,
    required DateTime updatedAt,
  }) async {
    final Either<Failure, UserProfile> loaded = await ref
        .read(profileRepositoryProvider)
        .getProfile(userId);
    await loaded.fold((Failure _) async {}, (UserProfile p) async {
      final UserProfile next = p.copyWith(
        weightKg: type == VitalType.bodyWeight ? value : p.weightKg,
        heightCm: type == VitalType.heightCm ? value : p.heightCm,
        updatedAt: updatedAt,
      );
      await ref.read(profileRepositoryProvider).updateProfile(next);
    });
  }

  /// Persists a vital for the signed-in user.
  Future<bool> logVital({
    required VitalType type,
    required double value,
    required DateTime recordedAt,
    required VitalLogSource source,
    String? notes,
  }) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return false;
    }
    final VitalSource src = switch (source) {
      VitalLogSource.labUpload => VitalSource.labUpload,
      VitalLogSource.profileSync => VitalSource.profileSync,
      VitalLogSource.manual => VitalSource.manual,
    };
    final VitalEntry entry = VitalEntry(
      id: 'v-${DateTime.now().microsecondsSinceEpoch}',
      userId: u.id,
      type: type,
      value: value,
      unit: type.unit,
      recordedAt: recordedAt,
      source: src,
      notes: notes,
    );
    final LogVitalUseCase uc = LogVitalUseCase(
      ref.read(healthRepositoryProvider),
    );
    final Either<Failure, VitalEntry> r = await uc(entry);
    return r.fold((Failure _) async => false, (VitalEntry _) async {
      ref.invalidate(healthSummaryDataProvider);
      ref.invalidate(healthSummaryProvider);
      ref.invalidate(recentVitalsProvider);
      ref.invalidate(vitalReadingEntriesProvider);
      if (source != VitalLogSource.profileSync &&
          (type == VitalType.bodyWeight || type == VitalType.heightCm)) {
        await _pushBodyMetricToProfile(
          userId: u.id,
          type: type,
          value: value,
          updatedAt: recordedAt,
        );
      }
      return true;
    });
  }

  /// Deletes one vital entry for the signed-in user and refreshes health UI.
  Future<bool> deleteVital(String vitalEntryId) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return false;
    }
    final Either<Failure, Unit> r = await ref
        .read(healthRepositoryProvider)
        .deleteVitalEntry(u.id, vitalEntryId);
    return r.fold((Failure _) => false, (Unit _) {
      ref.invalidate(healthSummaryDataProvider);
      ref.invalidate(healthSummaryProvider);
      ref.invalidate(recentVitalsProvider);
      ref.invalidate(vitalReadingEntriesProvider);
      return true;
    });
  }
}

@riverpod
Future<List<MedicationLog>> activeMedicationLogs(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final Either<Failure, List<MedicationLog>> r = await ref
      .read(healthRepositoryProvider)
      .getActiveMedications(u.id);
  return r.fold((Failure f) => throw f, (List<MedicationLog> list) => list);
}

@riverpod
Future<List<MedicationUi>> activeMedications(Ref ref) async {
  final List<MedicationLog> logs = await ref.watch(
    activeMedicationLogsProvider.future,
  );
  return logs.map(_medicationToUi).toList();
}

@riverpod
class MedicationNotifier extends _$MedicationNotifier {
  @override
  void build() {}

  Future<void> addMedication({
    required String name,
    required String dose,
    required String frequency,
    DateTime? reminderTime,
  }) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return;
    }
    MedicationReminderTime? rt;
    if (reminderTime != null) {
      rt = MedicationReminderTime(
        hour: reminderTime.hour,
        minute: reminderTime.minute,
      );
    }
    final MedicationLog log = MedicationLog(
      id: 'med-${DateTime.now().microsecondsSinceEpoch}',
      userId: u.id,
      medicationName: name,
      dose: dose,
      frequency: frequency,
      reminderTime: rt,
      isActive: true,
      startDate: DateTime.now(),
      endDate: null,
    );
    await ref.read(healthRepositoryProvider).saveMedication(log);
    ref.invalidate(activeMedicationLogsProvider);
    ref.invalidate(activeMedicationsProvider);
    ref.invalidate(healthSummaryDataProvider);
    ref.invalidate(healthSummaryProvider);
  }

  Future<void> deleteMedication(String id) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return;
    }
    await ref.read(healthRepositoryProvider).deleteMedication(u.id, id);
    ref.invalidate(activeMedicationLogsProvider);
    ref.invalidate(activeMedicationsProvider);
    ref.invalidate(healthSummaryDataProvider);
    ref.invalidate(healthSummaryProvider);
  }
}

@riverpod
class LabScanNotifier extends _$LabScanNotifier {
  @override
  void build() {}

  List<ExtractedVitalRow> _rowsFromExtracted(
    List<ExtractedVital> aiList, {
    List<LocalLabReading> localReadings = const <LocalLabReading>[],
  }) {
    final List<ExtractedVitalRow> mapped = aiList
        .map(
          (ExtractedVital ex) => ExtractedVitalRow(
            name: ex.metricName,
            value: ex.value,
            unit: ex.unit,
            mappedType: mappedTypeFromExtracted(ex),
          ),
        )
        .toList();
    final Set<VitalType> aiTypes = <VitalType>{};
    for (final ExtractedVitalRow r in mapped) {
      if (r.mappedType != null) {
        aiTypes.add(r.mappedType!);
      }
    }
    for (final LocalLabReading lr in localReadings) {
      if (aiTypes.contains(lr.type)) continue;
      mapped.add(
        ExtractedVitalRow(
          name: lr.type.displayName,
          value: lr.value,
          unit: lr.unit,
          mappedType: lr.type,
        ),
      );
      aiTypes.add(lr.type);
    }
    return markDuplicateVitalRows(mapped);
  }

  /// AI extraction only — for lab UI preview before user picks rows to save.
  Future<Either<Failure, List<ExtractedVitalRow>>> extractLabReportRows(
    Uint8List imageBytes,
  ) async {
    final Either<Failure, List<ExtractedVital>> r = await ref
        .read(aiServiceProvider)
        .analyzeLabReport(imageBytes);
    return r.fold(
      (Failure f) => Left<Failure, List<ExtractedVitalRow>>(f),
      (List<ExtractedVital> list) =>
          Right<Failure, List<ExtractedVitalRow>>(_rowsFromExtracted(list)),
    );
  }

  /// AI extraction from pre-extracted PDF text (preferred — lower cost).
  /// Also runs the local regex pre-parser to fill any gaps AI missed.
  Future<Either<Failure, List<ExtractedVitalRow>>> extractLabReportRowsFromText(
    String reportText, {
    List<LocalLabReading> localReadings = const <LocalLabReading>[],
  }) async {
    final Either<Failure, List<ExtractedVital>> r = await ref
        .read(aiServiceProvider)
        .analyzeLabReportText(reportText);
    return r.fold(
      (Failure f) => Left<Failure, List<ExtractedVitalRow>>(f),
      (List<ExtractedVital> list) => Right<Failure, List<ExtractedVitalRow>>(
        _rowsFromExtracted(list, localReadings: localReadings),
      ),
    );
  }

  /// AI extraction from a PDF report file for lab UI preview (multimodal fallback).
  Future<Either<Failure, List<ExtractedVitalRow>>> extractLabReportRowsFromPdf(
    Uint8List pdfBytes,
  ) async {
    final Either<Failure, List<ExtractedVital>> r = await ref
        .read(aiServiceProvider)
        .analyzeLabReportPdf(pdfBytes);
    return r.fold(
      (Failure f) => Left<Failure, List<ExtractedVitalRow>>(f),
      (List<ExtractedVital> list) =>
          Right<Failure, List<ExtractedVitalRow>>(_rowsFromExtracted(list)),
    );
  }

  /// Full pipeline: vision → Firestore lab doc + vitals.
  Future<Either<Failure, LabReportScan>> scanLabReport(
    Uint8List imageBytes,
  ) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return const Left<Failure, LabReportScan>(AuthFailure('Not logged in'));
    }
    final ScanLabReportUseCase uc = ScanLabReportUseCase(
      ref.read(aiServiceProvider),
      ref.read(healthRepositoryProvider),
    );
    final Either<Failure, LabReportScan> r = await uc(
      userId: u.id,
      scanId: 'scan-${DateTime.now().microsecondsSinceEpoch}',
      imageBytes: imageBytes,
    );
    r.fold((_) {}, (_) {
      ref.invalidate(healthSummaryDataProvider);
      ref.invalidate(healthSummaryProvider);
      ref.invalidate(recentVitalsProvider);
      ref.invalidate(vitalReadingEntriesProvider);
    });
    return r;
  }

  /// Saves manually edited rows from the lab UI (e.g. mock flow).
  Future<bool> saveSelectedVitals(List<ExtractedVitalRow> rows) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return false;
    }
    final LogVitalUseCase uc = LogVitalUseCase(
      ref.read(healthRepositoryProvider),
    );
    final DateTime now = DateTime.now();
    int i = 0;
    final Set<VitalType> savedTypes = <VitalType>{};
    for (final ExtractedVitalRow r in rows) {
      if (!r.included || r.mappedType == null) {
        continue;
      }
      final VitalType t = r.mappedType!;
      if (savedTypes.contains(t)) {
        continue;
      }
      savedTypes.add(t);
      final VitalEntry entry = VitalEntry(
        id: 'labpick-${DateTime.now().microsecondsSinceEpoch}-$i',
        userId: u.id,
        type: t,
        value: r.value,
        unit: t.unit,
        recordedAt: now,
        source: VitalSource.labUpload,
        notes: 'From lab scan: ${r.name}',
      );
      i++;
      final Either<Failure, VitalEntry> res = await uc(entry);
      final bool ok = res.fold((Failure _) => false, (VitalEntry _) => true);
      if (!ok) {
        return false;
      }
    }
    ref.invalidate(healthSummaryDataProvider);
    ref.invalidate(healthSummaryProvider);
    ref.invalidate(recentVitalsProvider);
    ref.invalidate(vitalReadingEntriesProvider);
    return true;
  }
}

/// Persisted menstrual cycles (Firestore + Drift via [HealthRepository]).
@riverpod
Future<List<MenstrualCycle>> menstrualHistory(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    return <MenstrualCycle>[];
  }
  final Either<Failure, List<MenstrualCycle>> r = await ref
      .read(healthRepositoryProvider)
      .getMenstrualHistory(u.id, limit: 36);
  return r.fold(
    (Failure _) => <MenstrualCycle>[],
    (List<MenstrualCycle> list) => list,
  );
}

@riverpod
class MenstrualCycleLogNotifier extends _$MenstrualCycleLogNotifier {
  @override
  void build() {}

  /// Persists one cycle log via [LogMenstrualCycleUseCase] / [HealthRepository].
  Future<Either<Failure, MenstrualCycle>> saveCycleLog({
    required DateTime startDate,
    required String flowIntensityLabel,
    required List<String> symptoms,
    String? notes,
  }) async {
    final FitupUser? u = _userFromAuth(ref.read(authStateProvider));
    if (u == null) {
      return const Left<Failure, MenstrualCycle>(AuthFailure('Not logged in'));
    }
    final FlowIntensity intensity = switch (flowIntensityLabel.toLowerCase()) {
      'light' => FlowIntensity.light,
      'heavy' => FlowIntensity.heavy,
      _ => FlowIntensity.medium,
    };
    final DateTime start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final MenstrualCycle cycle = MenstrualCycle(
      id: 'mc-${DateTime.now().microsecondsSinceEpoch}',
      userId: u.id,
      cycleStart: start,
      flowIntensity: intensity,
      symptoms: symptoms,
      notes: notes,
    );
    final LogMenstrualCycleUseCase uc = LogMenstrualCycleUseCase(
      ref.read(healthRepositoryProvider),
    );
    final Either<Failure, MenstrualCycle> r = await uc(cycle);
    r.fold((_) {}, (_) {
      ref.invalidate(menstrualHistoryProvider);
      ref.invalidate(healthSummaryDataProvider);
      ref.invalidate(healthSummaryProvider);
    });
    return r;
  }
}
