import '../../domain/entities/breathing_session.dart';
import '../../domain/entities/meditation_session.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/survey_result.dart';

abstract class MentalWellbeingLocalDatasource {
  Future<void> upsertMood(MoodEntry entry, {required bool synced});

  Future<List<MoodEntry>> queryMoods(String userId, {int days = 30});

  Future<void> upsertSurvey(SurveyResult r, {required bool synced});

  Future<void> upsertBreathing(BreathingSession s, {required bool synced});

  Future<void> upsertMeditation(MeditationSession s, {required bool synced});

  Future<void> upsertStressJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime calculatedAt,
    required bool synced,
  });
}
