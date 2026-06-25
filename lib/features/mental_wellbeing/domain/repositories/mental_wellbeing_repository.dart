import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/breathing_session.dart';
import '../entities/meditation_session.dart';
import '../entities/mental_wellbeing_summary.dart';
import '../entities/mood_entry.dart';
import '../entities/stress_score.dart';
import '../entities/survey_result.dart';
import '../entities/survey_type.dart';

abstract class MentalWellbeingRepository {
  Future<Either<Failure, MoodEntry>> saveMoodEntry(MoodEntry entry);

  Future<Either<Failure, List<MoodEntry>>> getMoodHistory(
    String userId, {
    int days = 30,
  });

  Stream<Either<Failure, MoodEntry?>> watchTodayMood(String userId);

  Future<Either<Failure, SurveyResult>> saveSurveyResult(SurveyResult result);

  Future<Either<Failure, List<SurveyResult>>> getSurveyHistory(
    String userId,
    SurveyType type, {
    int limit = 5,
  });

  Future<Either<Failure, SurveyResult?>> getLatestSurvey(
    String userId,
    SurveyType type,
  );

  Future<Either<Failure, BreathingSession>> saveBreathingSession(
    BreathingSession session,
  );

  Future<Either<Failure, MeditationSession>> saveMeditationSession(
    MeditationSession session,
  );

  Future<Either<Failure, MentalWellbeingSummary>> getMentalWellbeingSummary(
    String userId,
  );

  Future<Either<Failure, StressScore>> calculateAndSaveStressScore(
    String userId,
  );
}
