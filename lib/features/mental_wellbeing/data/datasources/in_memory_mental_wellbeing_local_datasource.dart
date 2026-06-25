import '../../domain/entities/breathing_session.dart';
import '../../domain/entities/meditation_session.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/survey_result.dart';
import 'mental_wellbeing_local_datasource.dart';

class InMemoryMentalWellbeingLocalDatasource
    implements MentalWellbeingLocalDatasource {
  final Map<String, MoodEntry> _moods = <String, MoodEntry>{};
  final Map<String, SurveyResult> _surveys = <String, SurveyResult>{};

  @override
  Future<void> upsertMood(MoodEntry entry, {required bool synced}) async {
    _moods[entry.id] = entry;
  }

  @override
  Future<List<MoodEntry>> queryMoods(String userId, {int days = 30}) async {
    final DateTime from = DateTime.now().subtract(Duration(days: days));
    return _moods.values
        .where(
          (MoodEntry m) => m.userId == userId && !m.recordedAt.isBefore(from),
        )
        .toList()
      ..sort(
        (MoodEntry a, MoodEntry b) => b.recordedAt.compareTo(a.recordedAt),
      );
  }

  @override
  Future<void> upsertSurvey(SurveyResult r, {required bool synced}) async {
    _surveys[r.id] = r;
  }

  @override
  Future<void> upsertBreathing(
    BreathingSession s, {
    required bool synced,
  }) async {}

  @override
  Future<void> upsertMeditation(
    MeditationSession s, {
    required bool synced,
  }) async {}

  @override
  Future<void> upsertStressJson({
    required String id,
    required String userId,
    required String payloadJson,
    required DateTime calculatedAt,
    required bool synced,
  }) async {}
}
