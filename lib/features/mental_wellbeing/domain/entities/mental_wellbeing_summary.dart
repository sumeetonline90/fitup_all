import 'mood_entry.dart';
import 'stress_score.dart';
import 'survey_result.dart';

class MentalWellbeingSummary {
  const MentalWellbeingSummary({
    this.latestMood,
    this.weeklyMoods = const <MoodEntry>[],
    this.latestPhq9,
    this.latestGad7,
    this.latestPss10,
    this.currentStressScore,
    this.breathingSessionsThisWeek = 0,
    this.meditationMinutesThisWeek = 0,
  });

  final MoodEntry? latestMood;
  final List<MoodEntry> weeklyMoods;
  final SurveyResult? latestPhq9;
  final SurveyResult? latestGad7;
  final SurveyResult? latestPss10;
  final StressScore? currentStressScore;
  final int breathingSessionsThisWeek;
  final int meditationMinutesThisWeek;
}
