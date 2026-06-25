import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/chat_message.dart';
import '../entities/correlation_alert.dart';
import '../entities/daily_briefing.dart';
import '../entities/goal_adjustment.dart';
import '../entities/weekly_report.dart';

abstract class InsightRepository {
  Future<Either<Failure, DailyBriefing>> getDailyBriefing(String userId);

  Future<Either<Failure, DailyBriefing>> generateDailyBriefing(String userId);

  /// When [allowProIfStale] is false, missing/stale cache returns a placeholder
  /// without calling Gemini Pro (ADR-016).
  Future<Either<Failure, WeeklyReport>> getWeeklyReport(
    String userId,
    DateTime weekStart, {
    bool allowProIfStale = false,
  });

  Future<Either<Failure, WeeklyReport>> generateWeeklyReport(String userId);

  Future<Either<Failure, List<CorrelationAlert>>> getActiveAlerts(
    String userId,
  );

  Future<Either<Failure, Unit>> dismissAlert(String userId, String alertId);

  Future<Either<Failure, List<ChatMessage>>> getChatHistory(
    String userId, {
    int limit = 50,
  });

  Future<Either<Failure, ChatMessage>> sendChatMessage(
    String userId,
    String message,
    String? moduleContext,
  );

  Future<Either<Failure, GoalAdjustment?>> getLatestGoalAdjustment(
    String userId,
  );
}
