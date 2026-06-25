import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/models/weekly_report_content.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/correlation_alert.dart';
import '../../domain/entities/daily_briefing.dart';
import '../../domain/entities/goal_adjustment.dart';
import '../../domain/entities/holistic_context.dart';
import '../../domain/entities/weekly_report.dart';
import '../../domain/repositories/insight_repository.dart';
import '../../domain/services/conflict_detector.dart';
import '../../domain/services/holistic_context_builder.dart';

/// Local-first insights: Gemini via [AiService], chat + dismissals in memory.
class LocalInsightRepository implements InsightRepository {
  LocalInsightRepository({
    required HolisticContextBuilder contextBuilder,
    required AiService aiService,
    ConflictDetector conflictDetector = const ConflictDetector(),
  }) : _contextBuilder = contextBuilder,
       _aiService = aiService,
       _conflictDetector = conflictDetector;

  final HolisticContextBuilder _contextBuilder;
  final AiService _aiService;
  final ConflictDetector _conflictDetector;

  DailyBriefing? _briefingCache;
  DateTime? _briefingDay;

  final Map<String, List<ChatMessage>> _chats = <String, List<ChatMessage>>{};
  final Map<String, Set<String>> _dismissed = <String, Set<String>>{};
  final Map<String, WeeklyReport> _weeklyByKey = <String, WeeklyReport>{};

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime mondayOfWeek(DateTime date) {
    final DateTime d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  String _weekKey(String userId, DateTime weekStart) =>
      '$userId-${weekStart.millisecondsSinceEpoch}';

  @override
  Future<Either<Failure, DailyBriefing>> getDailyBriefing(String userId) async {
    final DateTime today = _dateOnly(DateTime.now());
    if (_briefingCache != null &&
        _briefingCache!.userId == userId &&
        _briefingDay == today) {
      return Right<Failure, DailyBriefing>(_briefingCache!);
    }
    return generateDailyBriefing(userId);
  }

  @override
  Future<Either<Failure, DailyBriefing>> generateDailyBriefing(
    String userId,
  ) async {
    try {
      final HolisticContext ctx = await _contextBuilder.buildFor(userId);
      final List<CorrelationAlert> alerts = _conflictDetector.detectFrom(ctx);
      final Either<Failure, String> textEither = await _aiService
          .getDailyBriefing(ctx);
      return textEither.fold(Left<Failure, DailyBriefing>.new, (String text) {
        final DailyBriefing b = DailyBriefing(
          id: 'briefing-$userId-${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          generatedAt: DateTime.now(),
          morningText: text,
          todaysGoals: const <String>[],
          alerts: alerts,
          contextSnapshot: ctx,
        );
        _briefingCache = b;
        _briefingDay = _dateOnly(DateTime.now());
        return Right<Failure, DailyBriefing>(b);
      });
    } on Object catch (e) {
      return Left<Failure, DailyBriefing>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyReport>> getWeeklyReport(
    String userId,
    DateTime weekStart, {
    bool allowProIfStale = false,
  }) async {
    final DateTime start = mondayOfWeek(weekStart);
    final String key = _weekKey(userId, start);
    final WeeklyReport? cached = _weeklyByKey[key];
    if (cached != null && !cached.isPlaceholder) {
      return Right<Failure, WeeklyReport>(cached);
    }
    if (!allowProIfStale) {
      return Right<Failure, WeeklyReport>(
        WeeklyReport.placeholder(userId, start),
      );
    }
    try {
      final HolisticContext ctx = await _contextBuilder.buildFor(userId);
      final Either<Failure, WeeklyReportContent> gen = await _aiService
          .generateWeeklyReport(ctx);
      return gen.fold(Left<Failure, WeeklyReport>.new, (WeeklyReportContent c) {
        final List<CorrelationAlert> cross = _conflictDetector.detectFrom(ctx);
        final WeeklyReport report = WeeklyReport(
          id: 'wr-$key',
          userId: userId,
          weekStarting: start,
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
          crossModuleInsights: cross,
          goalProgressText: c.goalProgress,
          isPlaceholder: false,
        );
        _weeklyByKey[key] = report;
        return Right<Failure, WeeklyReport>(report);
      });
    } on Object catch (e) {
      return Left<Failure, WeeklyReport>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WeeklyReport>> generateWeeklyReport(
    String userId,
  ) async {
    final DateTime start = mondayOfWeek(DateTime.now());
    _weeklyByKey.remove(_weekKey(userId, start));
    return getWeeklyReport(userId, start, allowProIfStale: true);
  }

  @override
  Future<Either<Failure, List<CorrelationAlert>>> getActiveAlerts(
    String userId,
  ) async {
    try {
      final HolisticContext ctx = await _contextBuilder.buildFor(userId);
      final List<CorrelationAlert> detected = _conflictDetector.detectFrom(ctx);
      final Set<String> dismissed = _dismissed[userId] ?? <String>{};
      final List<CorrelationAlert> active = detected
          .where((CorrelationAlert a) => !dismissed.contains(a.id))
          .toList();
      return Right<Failure, List<CorrelationAlert>>(active);
    } on Object catch (e) {
      return Left<Failure, List<CorrelationAlert>>(
        UnexpectedFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> dismissAlert(
    String userId,
    String alertId,
  ) async {
    _dismissed.putIfAbsent(userId, () => <String>{});
    _dismissed[userId]!.add(alertId);
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatHistory(
    String userId, {
    int limit = 50,
  }) async {
    final List<ChatMessage> all = List<ChatMessage>.from(
      _chats[userId] ?? const <ChatMessage>[],
    );
    if (all.length <= limit) {
      return Right<Failure, List<ChatMessage>>(all);
    }
    return Right<Failure, List<ChatMessage>>(all.sublist(all.length - limit));
  }

  @override
  Future<Either<Failure, ChatMessage>> sendChatMessage(
    String userId,
    String message,
    String? moduleContext,
  ) async {
    try {
      final HolisticContext ctx = await _contextBuilder.buildFor(userId);
      final List<ChatMessage> history = List<ChatMessage>.from(
        _chats[userId] ?? const <ChatMessage>[],
      );
      final Either<Failure, String> reply = await _aiService.chatWithAI(
        message,
        ctx,
        history,
        moduleFocus: moduleContext,
      );
      return reply.fold(Left<Failure, ChatMessage>.new, (String text) {
        final ChatMessage userMsg = ChatMessage(
          id: 'u-${DateTime.now().microsecondsSinceEpoch}',
          role: ChatRole.user,
          content: message.trim(),
          timestamp: DateTime.now(),
          moduleContext: moduleContext,
        );
        final ChatMessage assistantMsg = ChatMessage(
          id: 'a-${DateTime.now().microsecondsSinceEpoch}',
          role: ChatRole.assistant,
          content: text,
          timestamp: DateTime.now(),
        );
        _chats[userId] = <ChatMessage>[...history, userMsg, assistantMsg];
        return Right<Failure, ChatMessage>(assistantMsg);
      });
    } on Object catch (e) {
      return Left<Failure, ChatMessage>(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GoalAdjustment?>> getLatestGoalAdjustment(
    String userId,
  ) async {
    try {
      final HolisticContext ctx = await _contextBuilder.buildFor(userId);
      final Either<Failure, ({String suggestion, String rationale})?> r =
          await _aiService.suggestGoalAdjustment(ctx);
      return r.fold(Left<Failure, GoalAdjustment?>.new, (
        ({String suggestion, String rationale})? tuple,
      ) {
        if (tuple == null) {
          return const Right<Failure, GoalAdjustment?>(null);
        }
        return Right<Failure, GoalAdjustment?>(
          GoalAdjustment(
            id: 'ga-${DateTime.now().millisecondsSinceEpoch}',
            userId: userId,
            currentGoal: ctx.primaryGoal ?? 'General wellbeing',
            suggestion: tuple.suggestion,
            rationale: tuple.rationale,
            generatedAt: DateTime.now(),
          ),
        );
      });
    } on Object catch (e) {
      return Left<Failure, GoalAdjustment?>(UnexpectedFailure(e.toString()));
    }
  }
}
