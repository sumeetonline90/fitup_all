import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fitup/core/database/fitup_database.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/insights/data/datasources/insight_local_datasource.dart';
import 'package:fitup/features/insights/data/datasources/insight_remote_datasource.dart';
import 'package:fitup/features/insights/data/insight_alert_codec.dart';
import 'package:fitup/features/insights/data/insight_context_codec.dart';
import 'package:fitup/features/insights/domain/entities/chat_message.dart';
import 'package:fitup/features/insights/domain/entities/correlation_alert.dart';
import 'package:fitup/features/insights/domain/entities/daily_briefing.dart';
import 'package:fitup/features/insights/domain/entities/goal_adjustment.dart';
import 'package:fitup/features/insights/domain/entities/holistic_context.dart';
import 'package:fitup/features/insights/domain/entities/weekly_report.dart';
import 'package:fitup/features/insights/domain/repositories/insight_repository.dart';
import 'package:fitup/features/insights/domain/services/conflict_detector.dart';
import 'package:fitup/features/insights/domain/services/holistic_context_builder.dart';
import 'package:fitup/services/ai_input_sanitizer.dart';
import 'package:fitup/services/ai_service.dart';
import 'package:fitup/services/logger_service.dart';
import 'package:fitup/services/models/weekly_report_content.dart';

Failure _mapErr(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

class FirebaseInsightRepository implements InsightRepository {
  FirebaseInsightRepository(
    this._local,
    this._remote,
    this._ai,
    this._builder,
    this._detector,
  );

  final InsightLocalDatasource _local;
  final InsightRemoteDatasource _remote;
  final AiService _ai;
  final HolisticContextBuilder _builder;
  final ConflictDetector _detector;

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _mondayOf(DateTime d) {
    final int fromMon = d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: fromMon));
  }

  static List<String> _inferTodaysGoals(HolisticContext c) {
    final List<String> g = <String>[];
    if (c.mealsLoggedToday == false) {
      g.add('Log your meals today');
    }
    if ((c.stepsYesterday ?? 100000) < 6000) {
      g.add('Aim for a 30-minute walk');
    }
    if ((c.sleepMinutesLastNight ?? 500) < 360) {
      g.add('Prioritize sleep and wind down earlier');
    }
    if (g.isEmpty) {
      g.add('Check in on how you feel this evening');
    }
    return g.take(4).toList();
  }

  DailyBriefing _briefingFromRow(InsightDailyBriefingRow r) {
    final List<String> goals = (jsonDecode(r.todaysGoalsJson) as List<dynamic>)
        .map((dynamic e) => e.toString())
        .toList();
    return DailyBriefing(
      id: r.id,
      userId: r.userId,
      generatedAt: r.generatedAt,
      morningText: r.morningText,
      todaysGoals: goals,
      alerts: decodeCorrelationAlerts(r.alertsJson),
      contextSnapshot: decodeHolisticContext(r.contextJson),
    );
  }

  ChatMessage _rowToMessage(InsightChatMessageRow r) {
    return ChatMessage(
      id: r.id,
      role: ChatRole.values.firstWhere(
        (ChatRole e) => e.name == r.role,
        orElse: () => ChatRole.user,
      ),
      content: r.content,
      timestamp: r.timestamp,
      moduleContext: r.moduleContext,
    );
  }

  @override
  Future<Either<Failure, DailyBriefing>> getDailyBriefing(String userId) async {
    try {
      final String dk = _dateKey(DateTime.now());
      final InsightDailyBriefingRow? row = await _local.getDailyBriefing(
        userId,
        dk,
      );
      if (row != null && _dateKey(row.generatedAt) == dk) {
        return Right<Failure, DailyBriefing>(_briefingFromRow(row));
      }
      return generateDailyBriefing(userId);
    } catch (e, st) {
      LoggerService.e('getDailyBriefing', e, st);
      return Left<Failure, DailyBriefing>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, DailyBriefing>> generateDailyBriefing(
    String userId,
  ) async {
    try {
      final HolisticContext ctx = await _builder.buildFor(userId);
      final List<CorrelationAlert> ruleAlerts = _detector.detectFrom(ctx);

      final Either<Failure, List<String>> aiExtra = await _ai
          .detectConflictsWithAI(ctx, ruleAlerts);
      final List<String> extraLines = aiExtra.fold(
        (_) => <String>[],
        (List<String> l) => l,
      );

      final List<CorrelationAlert> allAlerts = List<CorrelationAlert>.from(
        ruleAlerts,
      );
      int k = 0;
      for (final String line in extraLines) {
        final String t = line.length > 72 ? '${line.substring(0, 69)}…' : line;
        allAlerts.add(
          CorrelationAlert(
            id: 'ai-$userId-${DateTime.now().microsecondsSinceEpoch}-$k',
            type: AlertType.recommendation,
            severity: AlertSeverity.info,
            title: t,
            message: line,
            modules: const <String>['General'],
            generatedAt: DateTime.now(),
          ),
        );
        k++;
      }

      for (final CorrelationAlert a in allAlerts) {
        try {
          await _remote.setAlert(userId, a.id, _alertToFirestore(a));
        } catch (e, st) {
          LoggerService.e('setAlert', e, st);
        }
      }

      final Either<Failure, String> textRes = await _ai.getDailyBriefing(ctx);
      return textRes.fold(Left<Failure, DailyBriefing>.new, (String morning) {
        final List<String> goals = _inferTodaysGoals(ctx);
        final String dk = _dateKey(DateTime.now());
        final String id = 'brief-$userId-$dk';
        final DailyBriefing briefing = DailyBriefing(
          id: id,
          userId: userId,
          generatedAt: DateTime.now(),
          morningText: morning,
          todaysGoals: goals,
          alerts: allAlerts,
          contextSnapshot: ctx,
        );

        return _persistDailyBriefing(briefing, dk);
      });
    } catch (e, st) {
      LoggerService.e('generateDailyBriefing', e, st);
      return Left<Failure, DailyBriefing>(_mapErr(e));
    }
  }

  Future<Either<Failure, DailyBriefing>> _persistDailyBriefing(
    DailyBriefing briefing,
    String dateKey,
  ) async {
    try {
      final String goalsJson = jsonEncode(briefing.todaysGoals);
      final String alertsJson = encodeCorrelationAlerts(briefing.alerts);
      final String ctxJson = encodeHolisticContext(briefing.contextSnapshot);
      await _local.upsertDailyBriefing(
        id: briefing.id,
        userId: briefing.userId,
        dateKey: dateKey,
        morningText: briefing.morningText,
        todaysGoalsJson: goalsJson,
        alertsJson: alertsJson,
        contextJson: ctxJson,
        generatedAt: briefing.generatedAt,
        synced: false,
      );
      await _remote
          .setDailyBriefing(briefing.userId, dateKey, <String, dynamic>{
            'id': briefing.id,
            'userId': briefing.userId,
            'dateKey': dateKey,
            'morningText': briefing.morningText,
            'todaysGoals': briefing.todaysGoals,
            'alertsJson': alertsJson,
            'contextJson': ctxJson,
            'generatedAt': Timestamp.fromDate(briefing.generatedAt),
          });
      await _local.upsertDailyBriefing(
        id: briefing.id,
        userId: briefing.userId,
        dateKey: dateKey,
        morningText: briefing.morningText,
        todaysGoalsJson: goalsJson,
        alertsJson: alertsJson,
        contextJson: ctxJson,
        generatedAt: briefing.generatedAt,
        synced: true,
      );
      return Right<Failure, DailyBriefing>(briefing);
    } catch (e, st) {
      LoggerService.e('_persistDailyBriefing', e, st);
      return Left<Failure, DailyBriefing>(_mapErr(e));
    }
  }

  Map<String, dynamic> _alertToFirestore(CorrelationAlert a) {
    return <String, dynamic>{
      'id': a.id,
      'type': a.type.name,
      'severity': a.severity.name,
      'title': a.title,
      'message': a.message,
      'modules': a.modules,
      'generatedAt': Timestamp.fromDate(a.generatedAt),
      'isDismissed': a.isDismissed,
    };
  }

  @override
  Future<Either<Failure, WeeklyReport>> getWeeklyReport(
    String userId,
    DateTime weekStart, {
    bool allowProIfStale = false,
  }) async {
    try {
      final String wk = _dateKey(_mondayOf(weekStart));
      final InsightWeeklyReportRow? row = await _local.getWeeklyReport(
        userId,
        wk,
      );
      if (row != null &&
          DateTime.now().difference(row.generatedAt) <
              const Duration(days: 8)) {
        return Right<Failure, WeeklyReport>(
          _weeklyFromJson(row.reportJson, userId, _mondayOf(weekStart)),
        );
      }
      if (allowProIfStale) {
        return generateWeeklyReport(userId);
      }
      return Right<Failure, WeeklyReport>(
        WeeklyReport.placeholder(userId, _mondayOf(weekStart)),
      );
    } catch (e, st) {
      LoggerService.e('getWeeklyReport', e, st);
      return Left<Failure, WeeklyReport>(_mapErr(e));
    }
  }

  WeeklyReport _weeklyFromJson(String raw, String userId, DateTime weekStart) {
    final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
    return WeeklyReport(
      id: m['id'] as String? ?? 'wk-$userId',
      userId: userId,
      weekStarting: weekStart,
      generatedAt:
          DateTime.tryParse(m['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      executiveSummary: m['executiveSummary'] as String? ?? '',
      moduleInsights: Map<String, String>.from(
        (m['moduleInsights'] as Map?)?.cast<String, String>() ??
            const <String, String>{},
      ),
      wins:
          (m['wins'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      focusAreas:
          (m['focusAreas'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      crossModuleInsights: decodeCorrelationAlerts(
        m['crossModuleInsightsJson'] as String? ?? '[]',
      ),
      goalProgressText: m['goalProgressText'] as String? ?? '',
    );
  }

  @override
  Future<Either<Failure, WeeklyReport>> generateWeeklyReport(
    String userId,
  ) async {
    try {
      final HolisticContext ctx = await _builder.buildFor(userId);
      final Either<Failure, WeeklyReportContent> res = await _ai
          .generateWeeklyReport(ctx);
      return res.fold(Left<Failure, WeeklyReport>.new, (WeeklyReportContent c) {
        final DateTime mon = _mondayOf(DateTime.now());
        final String wk = _dateKey(mon);
        final String id = 'wk-$userId-$wk';
        final WeeklyReport report = WeeklyReport(
          id: id,
          userId: userId,
          weekStarting: mon,
          generatedAt: DateTime.now(),
          executiveSummary: c.executiveSummary,
          moduleInsights: <String, String>{
            'Activity': c.activityInsight,
            'Diet': c.dietInsight,
            'Workout': c.workoutInsight,
            'Health': c.healthInsight,
            'Mental': c.mentalInsight,
          },
          wins: c.wins,
          focusAreas: c.focusAreas,
          crossModuleInsights: const <CorrelationAlert>[],
          goalProgressText: c.goalProgress,
          isPlaceholder: false,
        );
        return _persistWeeklyReport(report, wk);
      });
    } catch (e, st) {
      LoggerService.e('generateWeeklyReport', e, st);
      return Left<Failure, WeeklyReport>(_mapErr(e));
    }
  }

  Future<Either<Failure, WeeklyReport>> _persistWeeklyReport(
    WeeklyReport report,
    String weekKey,
  ) async {
    try {
      final String crossJson = encodeCorrelationAlerts(
        report.crossModuleInsights,
      );
      final Map<String, dynamic> payload = <String, dynamic>{
        'id': report.id,
        'userId': report.userId,
        'weekStartKey': weekKey,
        'generatedAt': report.generatedAt.toIso8601String(),
        'executiveSummary': report.executiveSummary,
        'moduleInsights': report.moduleInsights,
        'wins': report.wins,
        'focusAreas': report.focusAreas,
        'crossModuleInsightsJson': crossJson,
        'goalProgressText': report.goalProgressText,
      };
      final String reportJson = jsonEncode(payload);
      await _local.upsertWeeklyReport(
        id: report.id,
        userId: report.userId,
        weekStartKey: weekKey,
        reportJson: reportJson,
        generatedAt: report.generatedAt,
        synced: false,
      );
      await _remote.setWeeklyReport(report.userId, weekKey, {
        ...payload,
        'generatedAt': Timestamp.fromDate(report.generatedAt),
      });
      await _local.upsertWeeklyReport(
        id: report.id,
        userId: report.userId,
        weekStartKey: weekKey,
        reportJson: reportJson,
        generatedAt: report.generatedAt,
        synced: true,
      );
      return Right<Failure, WeeklyReport>(report);
    } catch (e, st) {
      LoggerService.e('_persistWeeklyReport', e, st);
      return Left<Failure, WeeklyReport>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, List<CorrelationAlert>>> getActiveAlerts(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryActiveAlerts(userId);
      final List<CorrelationAlert> out = <CorrelationAlert>[];
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
        out.add(
          CorrelationAlert(
            id: d.id,
            type: AlertType.values.firstWhere(
              (AlertType t) => t.name == (d['type'] as String? ?? ''),
              orElse: () => AlertType.recommendation,
            ),
            severity: AlertSeverity.values.firstWhere(
              (AlertSeverity s) => s.name == (d['severity'] as String? ?? ''),
              orElse: () => AlertSeverity.info,
            ),
            title: d['title'] as String? ?? '',
            message: d['message'] as String? ?? '',
            modules:
                (d['modules'] as List<dynamic>?)
                    ?.map((dynamic e) => e.toString())
                    .toList() ??
                const <String>[],
            generatedAt:
                (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isDismissed: d['isDismissed'] as bool? ?? false,
          ),
        );
      }
      return Right<Failure, List<CorrelationAlert>>(out);
    } catch (e, st) {
      LoggerService.e('getActiveAlerts', e, st);
      return Left<Failure, List<CorrelationAlert>>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> dismissAlert(
    String userId,
    String alertId,
  ) async {
    try {
      await _remote.dismissAlert(userId, alertId);
      return const Right<Failure, Unit>(unit);
    } catch (e, st) {
      LoggerService.e('dismissAlert', e, st);
      return Left<Failure, Unit>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final List<InsightChatMessageRow> rows = await _local.getChatMessages(
        userId,
        limit: limit,
      );
      final List<ChatMessage> msgs = rows.map(_rowToMessage).toList();
      msgs.sort(
        (ChatMessage a, ChatMessage b) => a.timestamp.compareTo(b.timestamp),
      );
      return Right<Failure, List<ChatMessage>>(msgs);
    } catch (e, st) {
      LoggerService.e('getChatHistory', e, st);
      return Left<Failure, List<ChatMessage>>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendChatMessage(
    String userId,
    String message,
    String? moduleContext,
  ) async {
    try {
      final String safe = AiInputSanitizer.sanitizeProfileText(
        message,
        maxLength: 1000,
      );
      final List<InsightChatMessageRow> rows = await _local.getChatMessages(
        userId,
        limit: 10,
      );
      final List<ChatMessage> chronological = rows.reversed
          .map(_rowToMessage)
          .toList();

      final String userMsgId =
          'chat-$userId-${DateTime.now().microsecondsSinceEpoch}-u';
      final DateTime ts = DateTime.now();
      await _local.insertChatMessage(
        id: userMsgId,
        userId: userId,
        role: ChatRole.user.name,
        content: safe,
        timestamp: ts,
        moduleContext: moduleContext,
        synced: false,
      );

      final HolisticContext ctx = await _builder.buildFor(userId);
      final List<ChatMessage> forAi = <ChatMessage>[
        ...chronological,
        ChatMessage(
          id: userMsgId,
          role: ChatRole.user,
          content: safe,
          timestamp: ts,
          moduleContext: moduleContext,
        ),
      ];

      final Either<Failure, String> reply = await _ai.chatWithAI(
        safe,
        ctx,
        forAi,
        moduleFocus: moduleContext,
      );
      return await reply.fold(
        (Failure f) async => Left<Failure, ChatMessage>(f),
        (String text) async {
          final String assistantId =
              'chat-$userId-${DateTime.now().microsecondsSinceEpoch}-a';
          final DateTime assistantTs = DateTime.now();
          await _local.insertChatMessage(
            id: assistantId,
            userId: userId,
            role: ChatRole.assistant.name,
            content: text,
            timestamp: assistantTs,
            moduleContext: null,
            synced: false,
          );
          try {
            await _remote.setChatMessage(userId, userMsgId, <String, dynamic>{
              'role': ChatRole.user.name,
              'content': safe,
              'timestamp': Timestamp.fromDate(ts),
              'moduleContext': moduleContext,
            });
            await _remote.setChatMessage(userId, assistantId, <String, dynamic>{
              'role': ChatRole.assistant.name,
              'content': text,
              'timestamp': Timestamp.fromDate(assistantTs),
            });
          } catch (e, st) {
            LoggerService.e('sendChatMessage remote', e, st);
            // Local + model succeeded; return success so UI shows the reply (ADR-020 / sync queue).
            return Right<Failure, ChatMessage>(
              ChatMessage(
                id: assistantId,
                role: ChatRole.assistant,
                content: text,
                timestamp: assistantTs,
                cloudSyncPending: true,
              ),
            );
          }
          await _local.insertChatMessage(
            id: userMsgId,
            userId: userId,
            role: ChatRole.user.name,
            content: safe,
            timestamp: ts,
            moduleContext: moduleContext,
            synced: true,
          );
          await _local.insertChatMessage(
            id: assistantId,
            userId: userId,
            role: ChatRole.assistant.name,
            content: text,
            timestamp: assistantTs,
            moduleContext: null,
            synced: true,
          );
          return Right<Failure, ChatMessage>(
            ChatMessage(
              id: assistantId,
              role: ChatRole.assistant,
              content: text,
              timestamp: assistantTs,
              cloudSyncPending: false,
            ),
          );
        },
      );
    } catch (e, st) {
      LoggerService.e('sendChatMessage', e, st);
      return Left<Failure, ChatMessage>(_mapErr(e));
    }
  }

  @override
  Future<Either<Failure, GoalAdjustment?>> getLatestGoalAdjustment(
    String userId,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryLatestGoalAdjustment(userId);
      if (snap.docs.isEmpty) {
        return const Right<Failure, GoalAdjustment?>(null);
      }
      final Map<String, dynamic> d = snap.docs.first.data();
      return Right<Failure, GoalAdjustment?>(
        GoalAdjustment(
          id: snap.docs.first.id,
          userId: userId,
          currentGoal: d['currentGoal'] as String? ?? '',
          suggestion: d['suggestion'] as String? ?? '',
          rationale: d['rationale'] as String? ?? '',
          generatedAt:
              (d['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isAccepted: d['isAccepted'] as bool? ?? false,
        ),
      );
    } catch (e, st) {
      LoggerService.e('getLatestGoalAdjustment', e, st);
      return Left<Failure, GoalAdjustment?>(_mapErr(e));
    }
  }
}
