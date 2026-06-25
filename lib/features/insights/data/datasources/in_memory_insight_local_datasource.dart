import 'package:fitup/core/database/fitup_database.dart';

import 'insight_local_datasource.dart';

/// Web / tests — mirrors Drift row shapes as plain maps converted to rows.
class InMemoryInsightLocalDatasource implements InsightLocalDatasource {
  final Map<String, InsightDailyBriefingRow> _daily =
      <String, InsightDailyBriefingRow>{};
  final Map<String, InsightWeeklyReportRow> _weekly =
      <String, InsightWeeklyReportRow>{};
  final List<InsightChatMessageRow> _chat = <InsightChatMessageRow>[];

  String _dk(String userId, String dateKey) => '$userId|$dateKey';
  String _wk(String userId, String weekKey) => '$userId|$weekKey';

  @override
  Future<InsightDailyBriefingRow?> getDailyBriefing(
    String userId,
    String dateKey,
  ) async => _daily[_dk(userId, dateKey)];

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
    _daily[_dk(userId, dateKey)] = InsightDailyBriefingRow(
      id: id,
      userId: userId,
      dateKey: dateKey,
      morningText: morningText,
      todaysGoalsJson: todaysGoalsJson,
      alertsJson: alertsJson,
      contextJson: contextJson,
      generatedAt: generatedAt,
      synced: synced,
    );
  }

  @override
  Future<InsightWeeklyReportRow?> getWeeklyReport(
    String userId,
    String weekStartKey,
  ) async => _weekly[_wk(userId, weekStartKey)];

  @override
  Future<void> upsertWeeklyReport({
    required String id,
    required String userId,
    required String weekStartKey,
    required String reportJson,
    required DateTime generatedAt,
    required bool synced,
  }) async {
    _weekly[_wk(userId, weekStartKey)] = InsightWeeklyReportRow(
      id: id,
      userId: userId,
      weekStartKey: weekStartKey,
      reportJson: reportJson,
      generatedAt: generatedAt,
      synced: synced,
    );
  }

  @override
  Future<List<InsightChatMessageRow>> getChatMessages(
    String userId, {
    int limit = 50,
  }) async {
    final List<InsightChatMessageRow> list =
        _chat.where((InsightChatMessageRow r) => r.userId == userId).toList()
          ..sort(
            (InsightChatMessageRow a, InsightChatMessageRow b) =>
                b.timestamp.compareTo(a.timestamp),
          );
    if (list.length <= limit) {
      return list;
    }
    return list.sublist(0, limit);
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
    _chat.removeWhere((InsightChatMessageRow r) => r.id == id);
    _chat.add(
      InsightChatMessageRow(
        id: id,
        userId: userId,
        role: role,
        content: content,
        timestamp: timestamp,
        moduleContext: moduleContext,
        synced: synced,
      ),
    );
  }
}
