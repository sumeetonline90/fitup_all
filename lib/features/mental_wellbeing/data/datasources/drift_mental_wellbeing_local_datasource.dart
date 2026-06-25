import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/fitup_database.dart';
import '../../domain/entities/breathing_session.dart';
import '../../domain/entities/meditation_session.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_level.dart';
import '../../domain/entities/survey_result.dart';
import 'mental_wellbeing_local_datasource.dart';

class DriftMentalWellbeingLocalDatasource
    implements MentalWellbeingLocalDatasource {
  DriftMentalWellbeingLocalDatasource(this._db);

  final FitupDatabase _db;

  @override
  Future<void> upsertMood(MoodEntry entry, {required bool synced}) async {
    await _db
        .into(_db.wellbeingMoods)
        .insertOnConflictUpdate(
          WellbeingMoodsCompanion.insert(
            id: entry.id,
            userId: entry.userId,
            moodLevel: entry.mood.storageValue,
            journal: Value<String?>(entry.journal),
            recordedAt: entry.recordedAt,
            tagsJson: Value<String>(jsonEncode(entry.tags)),
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<List<MoodEntry>> queryMoods(String userId, {int days = 30}) async {
    final DateTime from = DateTime.now().subtract(Duration(days: days));
    final List<WellbeingMoodRow> rows =
        await (_db.select(_db.wellbeingMoods)
              ..where(
                ($WellbeingMoodsTable t) =>
                    t.userId.equals(userId) &
                    t.recordedAt.isBiggerOrEqualValue(from),
              )
              ..orderBy([
                ($WellbeingMoodsTable t) => OrderingTerm(
                  expression: t.recordedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();
    return rows.map(_moodFromRow).toList();
  }

  MoodEntry _moodFromRow(WellbeingMoodRow r) {
    return MoodEntry(
      id: r.id,
      userId: r.userId,
      mood: moodLevelFromStorageValue(r.moodLevel),
      journal: r.journal,
      recordedAt: r.recordedAt,
      tags: (jsonDecode(r.tagsJson) as List<dynamic>)
          .map((dynamic e) => e.toString())
          .toList(),
    );
  }

  @override
  Future<void> upsertSurvey(SurveyResult r, {required bool synced}) async {
    await _db
        .into(_db.wellbeingSurveyResults)
        .insertOnConflictUpdate(
          WellbeingSurveyResultsCompanion.insert(
            id: r.id,
            userId: r.userId,
            surveyType: r.type.name,
            answersJson: jsonEncode(r.answers),
            totalScore: r.totalScore,
            severity: r.severity.name,
            completedAt: r.completedAt,
            aiGuidance: Value<String?>(r.aiGuidance),
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> upsertBreathing(
    BreathingSession s, {
    required bool synced,
  }) async {
    await _db
        .into(_db.wellbeingBreathingSessions)
        .insertOnConflictUpdate(
          WellbeingBreathingSessionsCompanion.insert(
            id: s.id,
            userId: s.userId,
            breathingType: s.type.name,
            durationSeconds: s.durationSeconds,
            cyclesCompleted: s.cyclesCompleted,
            completedAt: s.completedAt,
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> upsertMeditation(
    MeditationSession s, {
    required bool synced,
  }) async {
    await _db
        .into(_db.wellbeingMeditationSessions)
        .insertOnConflictUpdate(
          WellbeingMeditationSessionsCompanion.insert(
            id: s.id,
            userId: s.userId,
            durationSeconds: s.durationSeconds,
            ambientSound: Value<String?>(s.ambientSound),
            completedAt: s.completedAt,
            completed: Value<bool>(s.completed),
            synced: Value<bool>(synced),
          ),
        );
  }

  @override
  Future<void> upsertStressJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime calculatedAt,
    required bool synced,
  }) async {
    await _db
        .into(_db.healthStressScores)
        .insertOnConflictUpdate(
          HealthStressScoresCompanion.insert(
            id: id,
            userId: userId,
            payloadJson: payloadJson,
            calculatedAt: calculatedAt,
            synced: Value<bool>(synced),
          ),
        );
  }
}
