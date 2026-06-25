import 'package:fitup/core/database/fitup_database.dart';

/// Local cache for insights (Drift or in-memory on web).
abstract class InsightLocalDatasource {
  Future<InsightDailyBriefingRow?> getDailyBriefing(
    String userId,
    String dateKey,
  );

  Future<void> upsertDailyBriefing({
    required String id,
    required String userId,
    required String dateKey,
    required String morningText,
    required String todaysGoalsJson,
    required String alertsJson,
    required String contextJson,
    required DateTime generatedAt,
    required bool synced,
  });

  Future<InsightWeeklyReportRow?> getWeeklyReport(
    String userId,
    String weekStartKey,
  );

  Future<void> upsertWeeklyReport({
    required String id,
    required String userId,
    required String weekStartKey,
    required String reportJson,
    required DateTime generatedAt,
    required bool synced,
  });

  Future<List<InsightChatMessageRow>> getChatMessages(
    String userId, {
    int limit = 50,
  });

  Future<void> insertChatMessage({
    required String id,
    required String userId,
    required String role,
    required String content,
    required DateTime timestamp,
    String? moduleContext,
    required bool synced,
  });
}
