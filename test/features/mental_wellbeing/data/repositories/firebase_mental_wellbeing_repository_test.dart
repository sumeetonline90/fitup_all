import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/activity/domain/repositories/activity_repository.dart';
import 'package:fitup/features/mental_wellbeing/data/datasources/mental_wellbeing_remote_datasource.dart';
import 'package:fitup/features/mental_wellbeing/data/repositories/firebase_mental_wellbeing_repository.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_entry.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/mood_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/stress_level.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_result.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_severity.dart';
import 'package:fitup/features/mental_wellbeing/domain/entities/survey_type.dart';
import 'package:fitup/features/mental_wellbeing/domain/stress_calculator.dart';
import 'package:fitup/services/ai_service.dart';
import 'package:fitup/services/health_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_mental_wellbeing_local_datasource.dart';
import '../../helpers/mock_mental_wellbeing_remote_datasource.dart';

class _MockActivityRepository extends Mock implements ActivityRepository {}

class _MockHealthConnect extends Mock implements HealthConnectService {}

class _MockAiService extends Mock implements AiService {}

void main() {
  late FakeFirebaseFirestore firestore;
  late MockMentalWellbeingLocalDatasource local;
  late _MockActivityRepository activity;
  late _MockHealthConnect health;
  late _MockAiService ai;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    local = MockMentalWellbeingLocalDatasource();
    activity = _MockActivityRepository();
    health = _MockHealthConnect();
    ai = _MockAiService();
    registerFallbackValue(
      MoodEntry(
        id: 'm0',
        userId: 'u0',
        mood: MoodLevel.neutral,
        journal: null,
        recordedAt: DateTime(2025, 1, 1),
        tags: const <String>[],
      ),
    );
    registerFallbackValue(
      SurveyResult(
        id: 's0',
        userId: 'u0',
        type: SurveyType.phq9,
        answers: const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        totalScore: 0,
        severity: SurveySeverity.minimal,
        completedAt: DateTime(2025, 1, 1),
      ),
    );
  });

  test('saveMoodEntry returns Left on Firestore error', () async {
    final MockMentalWellbeingRemoteDatasource remote =
        MockMentalWellbeingRemoteDatasource();
    when(
      () => local.upsertMood(any(), synced: any(named: 'synced')),
    ).thenAnswer((_) async {});
    when(() => remote.setMood(any(), any(), any())).thenThrow(
      FirebaseException(plugin: 'cloud_firestore', message: 'denied'),
    );

    final FirebaseMentalWellbeingRepository repo =
        FirebaseMentalWellbeingRepository(remote, local, activity, health, ai);

    final MoodEntry entry = MoodEntry(
      id: 'm1',
      userId: 'u1',
      mood: MoodLevel.good,
      journal: 'ok',
      recordedAt: DateTime(2025, 6, 1),
      tags: const <String>['calm'],
    );

    final Either<Failure, MoodEntry> out = await repo.saveMoodEntry(entry);
    expect(out.isLeft(), isTrue);
    out.fold(
      (Failure f) => expect(f, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test('saveSurveyResult persists PHQ-9 total score to Firestore', () async {
    when(
      () => local.upsertSurvey(any(), synced: any(named: 'synced')),
    ).thenAnswer((_) async {});

    final MentalWellbeingRemoteDatasource remote =
        MentalWellbeingRemoteDatasource(firestore);
    final FirebaseMentalWellbeingRepository repo =
        FirebaseMentalWellbeingRepository(remote, local, activity, health, ai);

    const List<int> answers = <int>[1, 1, 1, 1, 1, 1, 1, 1, 1];
    final SurveyResult result = SurveyResult(
      id: 'srv1',
      userId: 'u1',
      type: SurveyType.phq9,
      answers: answers,
      totalScore: 9,
      severity: SurveySeverity.mild,
      completedAt: DateTime(2025, 6, 2),
    );

    final Either<Failure, SurveyResult> saved = await repo.saveSurveyResult(
      result,
    );
    expect(saved.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('surveys')
        .doc('srv1')
        .get();
    expect(doc.exists, isTrue);
    expect((doc.data()!['totalScore'] as num).toInt(), 9);
    expect(doc.data()!['type'], 'phq9');
  });

  group('calculateStressScore weighted formula', () {
    test('returns weighted average of normalized inputs', () {
      final double raw = StressCalculator.computeRawStress(
        hrvNorm: 80,
        sleepNorm: 60,
        moodNorm: 40,
        surveyNorm: 20,
      );
      expect(
        raw,
        closeTo(
          (100 - 80) * 0.25 +
              (100 - 60) * 0.25 +
              (100 - 40) * 0.25 +
              (100 - 20) * 0.25,
          0.001,
        ),
      );
    });

    test('defaults missing components to 50 (neutral stress contribution)', () {
      final double raw = StressCalculator.computeRawStress();
      expect(raw, closeTo(50, 0.001));
    });

    test('levelFor maps score bands', () {
      expect(StressCalculator.levelFor(10), StressLevel.low);
      expect(StressCalculator.levelFor(40), StressLevel.moderate);
      expect(StressCalculator.levelFor(70), StressLevel.high);
      expect(StressCalculator.levelFor(90), StressLevel.critical);
    });
  });
}
