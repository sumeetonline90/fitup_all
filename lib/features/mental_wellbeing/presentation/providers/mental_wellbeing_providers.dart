import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../../../activity/domain/entities/activity.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/mental_wellbeing_summary.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_level.dart';
import '../../domain/entities/stress_score.dart';
import '../../domain/entities/survey_result.dart';
import '../../domain/entities/survey_type.dart';
import '../../domain/repositories/mental_wellbeing_repository.dart';
import '../../domain/usecases/complete_survey.dart';
import '../../domain/usecases/get_stress_score.dart';
import '../../domain/usecases/get_wellbeing_summary.dart';
import '../../domain/usecases/log_mood.dart';

part 'mental_wellbeing_providers.g.dart';

FitupUser? _currentUser(Ref ref) {
  return ref
      .watch(authStateProvider)
      .maybeWhen(data: (FitupUser? u) => u, orElse: () => null);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// UI model for today's mood card (mirrors persisted [MoodEntry]).
class MoodLogUi {
  const MoodLogUi({
    required this.level,
    required this.loggedAt,
    this.journal,
    this.tags = const <String>[],
  });

  final MoodLevel level;
  final DateTime loggedAt;
  final String? journal;
  final List<String> tags;
}

class SurveyResultUi {
  const SurveyResultUi({
    required this.type,
    required this.score,
    required this.takenAt,
  });

  final SurveyType type;
  final int score;
  final DateTime takenAt;
}

@riverpod
MentalWellbeingRepository mentalWellbeingRepository(Ref ref) =>
    getIt<MentalWellbeingRepository>();

@riverpod
AiService mentalAiService(Ref ref) => getIt<AiService>();

@riverpod
Stream<MoodEntry?> todayMood(Ref ref) {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    return Stream<MoodEntry?>.value(null);
  }
  return ref
      .read(mentalWellbeingRepositoryProvider)
      .watchTodayMood(u.id)
      .map(
        (Either<Failure, MoodEntry?> e) =>
            e.fold((Failure _) => null, (MoodEntry? m) => m),
      );
}

@riverpod
MoodLogUi? dailyMood(Ref ref) {
  final AsyncValue<MoodEntry?> async = ref.watch(todayMoodProvider);
  return async.maybeWhen(
    data: (MoodEntry? m) {
      if (m == null) {
        return null;
      }
      return MoodLogUi(
        level: m.mood,
        loggedAt: m.recordedAt,
        journal: m.journal,
        tags: m.tags,
      );
    },
    orElse: () => null,
  );
}

@riverpod
Future<List<MoodEntry>> moodHistory(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final Either<Failure, List<MoodEntry>> r = await ref
      .read(mentalWellbeingRepositoryProvider)
      .getMoodHistory(u.id, days: 7);
  return r.fold((Failure f) => throw f, (List<MoodEntry> list) => list);
}

@riverpod
List<int> moodWeekLevels(Ref ref) {
  final AsyncValue<List<MoodEntry>> hist = ref.watch(moodHistoryProvider);
  final MoodEntry? todayStream = ref
      .watch(todayMoodProvider)
      .maybeWhen(data: (MoodEntry? m) => m, orElse: () => null);
  final DateTime today = DateTime.now();
  final DateTime todayDate = DateTime(today.year, today.month, today.day);
  return hist.maybeWhen(
    data: (List<MoodEntry> entries) {
      final List<int> out = List<int>.filled(7, 1);
      for (int i = 0; i < 7; i++) {
        final DateTime day = todayDate.subtract(Duration(days: 6 - i));
        MoodEntry? pick;
        if (todayStream != null && _sameDay(todayStream.recordedAt, day)) {
          pick = todayStream;
        } else {
          for (final MoodEntry e in entries) {
            if (_sameDay(e.recordedAt, day)) {
              pick = e;
              break;
            }
          }
        }
        if (pick != null) {
          out[i] = pick.mood.index.clamp(0, 4);
        }
      }
      return out;
    },
    orElse: () => List<int>.filled(7, 1),
  );
}

@riverpod
class MoodLoggerNotifier extends _$MoodLoggerNotifier {
  @override
  void build() {}

  Future<void> logMood({
    required MoodLevel level,
    String? journal,
    List<String> tags = const <String>[],
  }) async {
    final FitupUser? u = ref
        .read(authStateProvider)
        .maybeWhen(data: (FitupUser? x) => x, orElse: () => null);
    if (u == null) {
      return;
    }
    final LogMoodUseCase uc = LogMoodUseCase(
      ref.read(mentalWellbeingRepositoryProvider),
    );
    final MoodEntry entry = MoodEntry(
      id: 'mood-${DateTime.now().microsecondsSinceEpoch}',
      userId: u.id,
      mood: level,
      journal: journal,
      recordedAt: DateTime.now(),
      tags: tags,
    );
    await uc(entry);
    ref.invalidate(todayMoodProvider);
    ref.invalidate(moodHistoryProvider);
    ref.invalidate(moodWeekLevelsProvider);
    ref.invalidate(mentalWellbeingSummaryProvider);
  }
}

@riverpod
Future<SurveyResult?> latestSurvey(Ref ref, SurveyType type) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final Either<Failure, SurveyResult?> r = await ref
      .read(mentalWellbeingRepositoryProvider)
      .getLatestSurvey(u.id, type);
  return r.fold((Failure f) => throw f, (SurveyResult? s) => s);
}

@riverpod
Future<List<SurveyResult>> surveyHistoryForType(
  Ref ref,
  SurveyType type,
) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final Either<Failure, List<SurveyResult>> r = await ref
      .read(mentalWellbeingRepositoryProvider)
      .getSurveyHistory(u.id, type);
  return r.fold((Failure f) => throw f, (List<SurveyResult> list) => list);
}

@riverpod
Future<List<SurveyResultUi>> surveyHistory(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final MentalWellbeingRepository repo = ref.read(
    mentalWellbeingRepositoryProvider,
  );
  final List<SurveyResultUi> out = <SurveyResultUi>[];
  for (final SurveyType t in SurveyType.values) {
    final Either<Failure, List<SurveyResult>> r = await repo.getSurveyHistory(
      u.id,
      t,
      limit: 5,
    );
    r.fold((_) {}, (List<SurveyResult> list) {
      for (final SurveyResult s in list) {
        out.add(
          SurveyResultUi(
            type: s.type,
            score: s.totalScore,
            takenAt: s.completedAt,
          ),
        );
      }
    });
  }
  out.sort(
    (SurveyResultUi a, SurveyResultUi b) => b.takenAt.compareTo(a.takenAt),
  );
  return out;
}

@riverpod
class SurveyNotifier extends _$SurveyNotifier {
  @override
  List<int> build() => <int>[];

  void answerQuestion(int index, int value) {
    final List<int> next = List<int>.from(state);
    while (next.length <= index) {
      next.add(0);
    }
    next[index] = value;
    state = next;
  }

  void clearAnswers() => state = <int>[];

  Future<SurveyResult> submitSurvey(SurveyType type) async {
    final FitupUser? u = ref
        .read(authStateProvider)
        .maybeWhen(data: (FitupUser? x) => x, orElse: () => null);
    if (u == null) {
      throw const AuthFailure('Not logged in');
    }
    final CompleteSurveyUseCase uc = CompleteSurveyUseCase(
      ref.read(mentalWellbeingRepositoryProvider),
      ref.read(mentalAiServiceProvider),
    );
    final Either<Failure, SurveyResult> r = await uc(
      userId: u.id,
      type: type,
      answers: state,
    );
    return r.fold((Failure f) => throw f, (SurveyResult res) {
      clearAnswers();
      ref.invalidate(latestSurveyProvider(type));
      ref.invalidate(surveyHistoryForTypeProvider(type));
      ref.invalidate(surveyHistoryProvider);
      ref.invalidate(mentalWellbeingSummaryProvider);
      return res;
    });
  }
}

@riverpod
Future<MentalWellbeingSummary> mentalWellbeingSummary(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final GetWellbeingSummaryUseCase uc = GetWellbeingSummaryUseCase(
    ref.read(mentalWellbeingRepositoryProvider),
  );
  final Either<Failure, MentalWellbeingSummary> r = await uc(u.id);
  return r.fold((Failure f) => throw f, (MentalWellbeingSummary s) => s);
}

@riverpod
Future<int> currentStressScore(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final GetStressScoreUseCase uc = GetStressScoreUseCase(
    ref.read(mentalWellbeingRepositoryProvider),
  );
  final Either<Failure, StressScore> r = await uc(u.id);
  return r.fold(
    (Failure f) => throw f,
    (StressScore s) => s.score.round().clamp(0, 100),
  );
}

@riverpod
Future<String> mentalWellbeingInsight(Ref ref) async {
  final FitupUser? u = _currentUser(ref);
  if (u == null) {
    throw const AuthFailure('Not logged in');
  }
  final MentalWellbeingSummary sum = await ref.watch(
    mentalWellbeingSummaryProvider.future,
  );
  final String moodLine = sum.latestMood != null
      ? 'level ${sum.latestMood!.mood.name}'
      : 'not logged today';
  final String sleepLine = sum.currentStressScore?.sleepScore != null
      ? 'score available'
      : 'unknown';
  final int activityMin = await _weeklyActivityMinutes(ref, u.id);
  final String surveyLine = sum.latestPhq9 != null
      ? 'recent PHQ-9 completed'
      : 'no recent PHQ-9';
  final Either<Failure, String> r = await ref
      .read(mentalAiServiceProvider)
      .getMentalWellbeingInsight(
        moodLabel: moodLine,
        sleepQualityLabel: sleepLine,
        activityMinutesThisWeek: activityMin,
        surveySummaryLabel: surveyLine,
      );
  return r.fold((Failure f) => throw f, (String text) => text);
}

Future<int> _weeklyActivityMinutes(Ref ref, String userId) async {
  final Either<Failure, List<Activity>> res = await ref
      .read(activityRepositoryProvider)
      .getActivities(
        userId,
        from: DateTime.now().subtract(const Duration(days: 7)),
        to: DateTime.now(),
      );
  return res.fold((Failure _) => 0, (List<Activity> list) {
    final int sec = list.fold<int>(
      0,
      (int s, Activity a) => s + a.durationSeconds,
    );
    return sec ~/ 60;
  });
}

@riverpod
class BreathingSessionLog extends _$BreathingSessionLog {
  @override
  List<String> build() => <String>[];

  void record(String summary) {
    state = <String>[summary, ...state];
  }
}

@riverpod
class MeditationSessionLog extends _$MeditationSessionLog {
  @override
  List<String> build() => <String>[];

  void record(String summary) {
    state = <String>[summary, ...state];
  }
}
