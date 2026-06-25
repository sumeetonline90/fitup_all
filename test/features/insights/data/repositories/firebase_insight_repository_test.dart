import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/insights/data/datasources/in_memory_insight_local_datasource.dart';
import 'package:fitup/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:fitup/features/insights/data/insight_alert_codec.dart';
import 'package:fitup/features/insights/data/insight_context_codec.dart';
import 'package:fitup/features/insights/data/repositories/firebase_insight_repository.dart';
import 'package:fitup/features/insights/domain/entities/chat_message.dart';
import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';
import 'package:fitup/features/insights/domain/entities/daily_briefing.dart';
import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/insights/domain/entities/weekly_report.dart';
import 'package:fitup/features/insights/domain/services/conflict_detector.dart';
import 'package:fitup/features/insights/domain/services/holistic_context_builder.dart';
import 'package:fitup/services/ai_service.dart';
import 'package:fitup/services/models/weekly_report_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiService {}

class MockHolisticContextBuilder extends Mock implements HolisticContextBuilder {}

class ChatThrowingRemote extends InsightRemoteDatasource {
  ChatThrowingRemote(super.firestore);

  @override
  Future<void> setChatMessage(
    String userId,
    String msgId,
    Map<String, dynamic> data,
  ) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'forced',
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  late FakeFirebaseFirestore firestore;
  late InMemoryInsightLocalDatasource local;
  late MockAiService ai;
  late MockHolisticContextBuilder builder;
  const ConflictDetector detector = ConflictDetector();

  setUp(() {
    firestore = FakeFirebaseFirestore();
    local = InMemoryInsightLocalDatasource();
    ai = MockAiService();
    builder = MockHolisticContextBuilder();
    registerFallbackValue(const HolisticContext());
    registerFallbackValue(<CorrelationAlert>[]);
    registerFallbackValue(<ChatMessage>[]);
    registerFallbackValue(
      WeeklyReportContent(
        executiveSummary: 'e',
        activityInsight: 'a',
        dietInsight: 'd',
        workoutInsight: 'w',
        healthInsight: 'h',
        mentalInsight: 'm',
        wins: const <String>[],
        focusAreas: const <String>[],
        goalProgress: 'g',
      ),
    );
  });

  test('getDailyBriefing returns cached local result within same day', () async {
    final DateTime now = DateTime.now();
    final String dkToday = _dateKey(now);
    await local.upsertDailyBriefing(
      id: 'brief-u1-$dkToday',
      userId: 'u1',
      dateKey: dkToday,
      morningText: 'cached morning',
      todaysGoalsJson: jsonEncode(<String>['Walk']),
      alertsJson: encodeCorrelationAlerts(const <CorrelationAlert>[]),
      contextJson: encodeHolisticContext(const HolisticContext()),
      generatedAt: now,
      synced: true,
    );

    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      InsightRemoteDatasource(firestore),
      ai,
      builder,
      detector,
    );

    final Either<Failure, DailyBriefing> r = await repo.getDailyBriefing('u1');
    expect(r.isRight(), isTrue);
    r.fold(
      (Failure _) => fail('expected Right'),
      (DailyBriefing b) => expect(b.morningText, 'cached morning'),
    );

    verifyNever(() => ai.getDailyBriefing(any()));
    verifyNever(() => builder.buildFor(any()));
  });

  test('generateDailyBriefing calls detectConflictsWithAI before getDailyBriefing',
      () async {
    when(() => builder.buildFor(any())).thenAnswer(
      (_) async => const HolisticContext(),
    );
    final List<String> order = <String>[];
    when(() => ai.detectConflictsWithAI(any(), any())).thenAnswer((_) async {
      order.add('detect');
      return const Right<Failure, List<String>>(<String>[]);
    });
    when(() => ai.getDailyBriefing(any())).thenAnswer((_) async {
      order.add('brief');
      return const Right<Failure, String>('Hello');
    });

    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      InsightRemoteDatasource(firestore),
      ai,
      builder,
      detector,
    );

    final Either<Failure, DailyBriefing> res =
        await repo.generateDailyBriefing('u1');
    expect(res.isRight(), isTrue);
    expect(order, <String>['detect', 'brief']);
  });

  test('sendChatMessage passes sanitized message to AiService', () async {
    when(() => builder.buildFor(any())).thenAnswer(
      (_) async => const HolisticContext(),
    );
    when(() => ai.chatWithAI(any(), any(), any(), moduleFocus: any(named: 'moduleFocus')))
        .thenAnswer((_) async => const Right<Failure, String>('ok'));

    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      InsightRemoteDatasource(firestore),
      ai,
      builder,
      detector,
    );

    final String long = List<String>.filled(1200, 'x').join();
    await repo.sendChatMessage('u1', long, null);

    final String passed = verify(
      () => ai.chatWithAI(
        captureAny(),
        any(),
        any(),
        moduleFocus: any(named: 'moduleFocus'),
      ),
    ).captured.first as String;
    expect(passed.length, 1000);
  });

  test(
    'sendChatMessage returns Right with assistant when Firestore throws after AI',
    () async {
    when(() => builder.buildFor(any())).thenAnswer(
      (_) async => const HolisticContext(),
    );
    when(() => ai.chatWithAI(any(), any(), any(), moduleFocus: any(named: 'moduleFocus')))
        .thenAnswer((_) async => const Right<Failure, String>('reply'));

    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      ChatThrowingRemote(firestore),
      ai,
      builder,
      detector,
    );

    final Either<Failure, ChatMessage> r =
        await repo.sendChatMessage('u1', 'hi', null);
    expect(r.isRight(), isTrue);
    r.fold(
      (Failure _) => fail('expected Right'),
      (ChatMessage m) {
        expect(m.content, 'reply');
        expect(m.cloudSyncPending, isTrue);
      },
    );
  });

  test(
    'getWeeklyReport does not call AiService.generateWeeklyReport when '
    'cache empty and allowProIfStale false',
    () async {
    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      InsightRemoteDatasource(firestore),
      ai,
      builder,
      detector,
    );

    final Either<Failure, WeeklyReport> r =
        await repo.getWeeklyReport('u1', DateTime.now());
    expect(r.isRight(), isTrue);
    r.fold(
      (Failure _) => fail('expected Right'),
      (WeeklyReport w) {
        expect(w.isPlaceholder, isTrue);
      },
    );
    verifyNever(() => ai.generateWeeklyReport(any()));
    verifyNever(() => builder.buildFor(any()));
  });

  test(
    'getWeeklyReport triggers AiService.generateWeeklyReport when allowProIfStale',
    () async {
    when(() => builder.buildFor(any())).thenAnswer(
      (_) async => const HolisticContext(),
    );
    when(() => ai.generateWeeklyReport(any())).thenAnswer(
      (_) async => Right<Failure, WeeklyReportContent>(
        WeeklyReportContent(
          executiveSummary: 'ex',
          activityInsight: 'a',
          dietInsight: 'd',
          workoutInsight: 'w',
          healthInsight: 'h',
          mentalInsight: 'm',
          wins: const <String>['win'],
          focusAreas: const <String>['focus'],
          goalProgress: 'gp',
        ),
      ),
    );

    final FirebaseInsightRepository repo = FirebaseInsightRepository(
      local,
      InsightRemoteDatasource(firestore),
      ai,
      builder,
      detector,
    );

    await repo.getWeeklyReport(
      'u1',
      DateTime.now(),
      allowProIfStale: true,
    );
    verify(() => ai.generateWeeklyReport(any())).called(1);
  });
}
