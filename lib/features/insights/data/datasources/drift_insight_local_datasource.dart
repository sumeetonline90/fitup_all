import 'package:drift/drift.dart';
import 'package:fitup/core/database/fitup_database.dart';

import 'insight_local_datasource.dart';

class DriftInsightLocalDatasource implements InsightLocalDatasource {
  DriftInsightLocalDatasource(this._db);

  final FitupDatabase _db;

  @override
  Future<InsightDailyBriefingRow?> getDailyBriefing(
    String userId,
    String dateKey,
  ) {
    return (_db.select(_db.insightDailyBriefings)..where(
          ($InsightDailyBriefingsTable t) =>
              t.userId.equals(userId) & t.dateKey.equals(dateKey),
        ))
        .getSingleOrNull();
  }

  @override
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
  }) async {
    await _db
        .into(_db.insightDailyBriefings)
        .insertOnConflictUpdate(
          InsightDailyBriefingsCompanion.insert(
            id: id,
            userId: userId,
            dateKey: dateKey,
            morningText: morningText,
            todaysGoalsJson: todaysGoalsJson,
            alertsJson: alertsJson,
            contextJson: contextJson,
            generatedAt: generatedAt,
            synced: Value(synced),
          ),
        );
  }

  @override
  Future<InsightWeeklyReportRow?> getWeeklyReport(
    String userId,
    String weekStartKey,
  ) {
    return (_db.select(_db.insightWeeklyReports)..where(
          ($InsightWeeklyReportsTable t) =>
              t.userId.equals(userId) & t.weekStartKey.equals(weekStartKey),
        ))
        .getSingleOrNull();
  }

  @override
  Future<void> upsertWeeklyReport({
    required String id,
    required String userId,
    required String weekStartKey,
    required String reportJson,
    required DateTime generatedAt,
    required bool synced,
  }) async {
    await _db
        .into(_db.insightWeeklyReports)
        .insertOnConflictUpdate(
          InsightWeeklyReportsCompanion.insert(
            id: id,
            userId: userId,
            weekStartKey: weekStartKey,
            reportJson: reportJson,
            generatedAt: generatedAt,
            synced: Value(synced),
          ),
        );
  }

  @override
  Future<List<InsightChatMessageRow>> getChatMessages(
    String userId, {
    int limit = 50,
  }) {
    return (_db.select(_db.insightChatMessages)
          ..where(($InsightChatMessagesTable t) => t.userId.equals(userId))
          ..orderBy(<OrderClauseGenerator<$InsightChatMessagesTable>>[
            ($InsightChatMessagesTable t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
  }

  @override
  Future<void> insertChatMessage({
    required String id,
    required String userId,
    required String role,
    required String content,
    required DateTime timestamp,
    String? moduleContext,
    required bool synced,
  }) async {
    await _db
        .into(_db.insightChatMessages)
        .insertOnConflictUpdate(
          InsightChatMessagesCompanion.insert(
            id: id,
            userId: userId,
            role: role,
            content: content,
            timestamp: timestamp,
            moduleContext: Value(moduleContext),
            synced: Value(synced),
          ),
        );
  }
}
