import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/health/data/datasources/health_remote_datasource.dart';
import 'package:fitup/features/health/data/lab_metric_mapper.dart';
import 'package:fitup/features/health/data/models/vital_entry_model.dart';
import 'package:fitup/features/health/data/repositories/firebase_health_repository.dart';
import 'package:fitup/features/health/domain/entities/flow_intensity.dart';
import 'package:fitup/features/health/domain/entities/menstrual_cycle.dart';
import 'package:fitup/features/health/domain/entities/vital_entry.dart';
import 'package:fitup/features/health/domain/entities/vital_source.dart';
import 'package:fitup/features/health/domain/entities/vital_type.dart';
import 'package:fitup/services/models/extracted_vital.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_health_local_datasource.dart';
import '../../helpers/mock_health_remote_datasource.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockHealthLocalDatasource mockLocal;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    mockLocal = MockHealthLocalDatasource();
    registerFallbackValue(
      VitalEntry(
        id: 'v0',
        userId: 'u0',
        type: VitalType.heartRate,
        value: 72,
        unit: 'bpm',
        recordedAt: DateTime(2025, 1, 1),
        source: VitalSource.manual,
      ),
    );
    registerFallbackValue(
      VitalEntryModel(
        id: 'x',
        userId: 'u0',
        type: VitalType.heartRate,
        value: 0,
        unit: 'bpm',
        recordedAt: DateTime(2020),
        source: VitalSource.manual,
      ),
    );
  });

  VitalEntry sampleVital(String id) => VitalEntry(
    id: id,
    userId: 'user1',
    type: VitalType.tsh,
    value: 2.1,
    unit: 'µIU/mL',
    recordedAt: DateTime(2025, 6, 1, 10),
    source: VitalSource.manual,
  );

  test(
      'saveMenstrualCycle writes local unsynced then synced and Firestore doc',
      () async {
    final FakeHealthLocalDatasource recording = FakeHealthLocalDatasource();
    final HealthRemoteDatasource remote = HealthRemoteDatasource(firestore);
    final FirebaseHealthRepository repo = FirebaseHealthRepository(
      remote,
      recording,
    );
    final MenstrualCycle c = MenstrualCycle(
      id: 'm1',
      userId: 'user1',
      cycleStart: DateTime(2025, 6, 1),
      flowIntensity: FlowIntensity.medium,
      symptoms: const <String>['Cramps'],
    );
    final Either<Failure, MenstrualCycle> result = await repo.saveMenstrualCycle(c);
    expect(result.isRight(), isTrue);
    expect(recording.menstrualSyncedFlags, <bool>[false, true]);

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('user1')
        .collection('menstrualCycles')
        .doc('m1')
        .get();
    expect(doc.exists, isTrue);
  });

  test('saveVitalEntry returns Right on success', () async {
    when(
      () => mockLocal.upsertVital(any(), synced: any(named: 'synced')),
    ).thenAnswer((_) async {});
    when(() => mockLocal.markVitalSynced(any())).thenAnswer((_) async {});

    final HealthRemoteDatasource remote = HealthRemoteDatasource(firestore);
    final FirebaseHealthRepository repo = FirebaseHealthRepository(
      remote,
      mockLocal,
    );

    final VitalEntry e = sampleVital('v1');
    final Either<Failure, VitalEntry> result = await repo.saveVitalEntry(e);
    expect(result.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('user1')
        .collection('vitals')
        .doc('v1')
        .get();
    expect(doc.exists, isTrue);
    expect((doc.data()!['value'] as num).toDouble(), 2.1);
  });

  test(
    'saveVitalEntry returns Left(ServerFailure) when Firestore throws',
    () async {
      final MockHealthRemoteDatasource remote = MockHealthRemoteDatasource();
      when(
        () => mockLocal.upsertVital(any(), synced: any(named: 'synced')),
      ).thenAnswer((_) async {});
      when(() => remote.setVital(any(), any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', message: 'write failed'),
      );

      final FirebaseHealthRepository repo = FirebaseHealthRepository(
        remote,
        mockLocal,
      );

      final Either<Failure, VitalEntry> result = await repo.saveVitalEntry(
        sampleVital('v2'),
      );
      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    },
  );

  test(
    'saveVitalEntry writes to local (unsynced) before Firestore then marks synced',
    () async {
      final FakeHealthLocalDatasource recording = FakeHealthLocalDatasource();
      when(
        () => mockLocal.upsertVital(any(), synced: any(named: 'synced')),
      ).thenAnswer((invocation) async {
        final VitalEntry e = invocation.positionalArguments[0] as VitalEntry;
        final bool synced =
            invocation.namedArguments[const Symbol('synced')] as bool;
        await recording.upsertVital(e, synced: synced);
      });
      when(() => mockLocal.markVitalSynced(any())).thenAnswer((
        invocation,
      ) async {
        final String id = invocation.positionalArguments[0] as String;
        await recording.markVitalSynced(id);
      });

      final HealthRemoteDatasource remote = HealthRemoteDatasource(firestore);
      final FirebaseHealthRepository repo = FirebaseHealthRepository(
        remote,
        mockLocal,
      );

      final VitalEntry e = sampleVital('v-order');
      await repo.saveVitalEntry(e);

      expect(recording.upsertSyncedFlags.length, 1);
      expect(recording.upsertSyncedFlags[0], isFalse);
      expect(recording.markSyncedIds, <String>['v-order']);
      expect(recording.upsertCalls.single.id, 'v-order');
    },
  );

  test('Gemini-style lab JSON maps to VitalEntry list via mapper', () {
    const String raw =
        '[{"metric_name":"TSH-Ultrasensitive","value":3.2,"unit":"µIU/mL"}]';
    final Object? decoded = jsonDecode(raw);
    expect(decoded, isA<List<dynamic>>());
    final List<dynamic> list = decoded! as List<dynamic>;
    final List<VitalEntry> out = <VitalEntry>[];
    for (final dynamic item in list) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(item as Map);
      final String name = m['metric_name'] as String;
      final double val = (m['value'] as num).toDouble();
      final VitalType? vt = mapLabMetricToVitalType(name);
      expect(vt, VitalType.tsh);
      final VitalEntry? ve = extractedToVitalEntry(
        extracted: ExtractedVital(
          metricName: name,
          value: val,
          unit: m['unit'] as String? ?? '',
        ),
        type: vt!,
        userId: 'user1',
        entryId: 'lab-user1-0',
      );
      expect(ve, isNotNull);
      out.add(ve!);
    }
    expect(out.length, 1);
    expect(out.first.type, VitalType.tsh);
    expect(out.first.value, 3.2);
    expect(out.first.source, VitalSource.labUpload);
  });
}
