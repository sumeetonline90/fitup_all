import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/health_connect_service.dart';
import '../../../../services/logger_service.dart';
import '../../../activity/domain/entities/sleep_log.dart';
import '../../../activity/domain/repositories/activity_repository.dart';
import '../../domain/entities/breathing_session.dart';
import '../../domain/entities/mental_wellbeing_summary.dart';
import '../../domain/entities/meditation_session.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/mood_level.dart';
import '../../domain/entities/stress_level.dart';
import '../../domain/entities/stress_score.dart';
import '../../domain/entities/survey_result.dart';
import '../../domain/entities/survey_severity.dart';
import '../../domain/entities/survey_type.dart';
import '../../domain/repositories/mental_wellbeing_repository.dart';
import '../../domain/stress_calculator.dart';
import '../datasources/mental_wellbeing_local_datasource.dart';
import '../datasources/mental_wellbeing_remote_datasource.dart';

Failure _mapFirebase(Object e) {
  if (e is FirebaseException) {
    return ServerFailure(e.message ?? e.code);
  }
  return ServerFailure(e.toString());
}

Map<String, dynamic> _moodToMap(MoodEntry m) {
  return <String, dynamic>{
    'id': m.id,
    'userId': m.userId,
    'mood': m.mood.storageValue,
    'journal': m.journal,
    'recordedAt': Timestamp.fromDate(m.recordedAt),
    'tags': m.tags,
  };
}

MoodEntry _moodFromMap(Map<String, dynamic> j) {
  return MoodEntry(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
    mood: moodLevelFromStorageValue((j['mood'] as num?)?.toInt() ?? 3),
    journal: j['journal'] as String?,
    recordedAt: _readTs(j['recordedAt']) ?? DateTime.now(),
    tags:
        (j['tags'] as List<dynamic>?)
            ?.map((dynamic e) => e.toString())
            .toList() ??
        const <String>[],
  );
}

Map<String, dynamic> _surveyToMap(SurveyResult r) {
  return <String, dynamic>{
    'id': r.id,
    'userId': r.userId,
    'type': r.type.name,
    'answers': r.answers,
    'totalScore': r.totalScore,
    'severity': r.severity.name,
    'completedAt': Timestamp.fromDate(r.completedAt),
    'aiGuidance': r.aiGuidance,
  };
}

SurveyResult _surveyFromMap(Map<String, dynamic> j) {
  return SurveyResult(
    id: j['id'] as String? ?? '',
    userId: j['userId'] as String? ?? '',
    type: SurveyType.values.firstWhere(
      (SurveyType t) => t.name == (j['type'] as String? ?? 'phq9'),
      orElse: () => SurveyType.phq9,
    ),
    answers:
        (j['answers'] as List<dynamic>?)
            ?.map((dynamic e) => (e as num).toInt())
            .toList() ??
        const <int>[],
    totalScore: (j['totalScore'] as num?)?.toInt() ?? 0,
    severity: SurveySeverity.values.firstWhere(
      (SurveySeverity s) => s.name == (j['severity'] as String? ?? 'minimal'),
      orElse: () => SurveySeverity.minimal,
    ),
    completedAt: _readTs(j['completedAt']) ?? DateTime.now(),
    aiGuidance: j['aiGuidance'] as String?,
  );
}

DateTime? _readTs(Object? raw) {
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  return null;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class FirebaseMentalWellbeingRepository implements MentalWellbeingRepository {
  FirebaseMentalWellbeingRepository(
    this._remote,
    this._local,
    this._activity,
    this._health,
    this._ai,
  );

  final MentalWellbeingRemoteDatasource _remote;
  final MentalWellbeingLocalDatasource _local;
  final ActivityRepository _activity;
  final HealthConnectService _health;
  final AiService _ai;

  @override
  Future<Either<Failure, MoodEntry>> saveMoodEntry(MoodEntry entry) async {
    try {
      await _local.upsertMood(entry, synced: false);
      await _remote.setMood(entry.userId, entry.id, _moodToMap(entry));
      await _local.upsertMood(entry, synced: true);
      return Right<Failure, MoodEntry>(entry);
    } catch (e, st) {
      LoggerService.e('saveMoodEntry', e, st);
      return Left<Failure, MoodEntry>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<MoodEntry>>> getMoodHistory(
    String userId, {
    int days = 30,
  }) async {
    try {
      final DateTime from = DateTime.now().subtract(Duration(days: days));
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .queryMoodHistory(userId, from);
      final List<MoodEntry> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                _moodFromMap(<String, dynamic>{'id': d.id, ...d.data()}),
          )
          .toList();
      return Right<Failure, List<MoodEntry>>(list);
    } catch (e, st) {
      LoggerService.e('getMoodHistory', e, st);
      try {
        return Right<Failure, List<MoodEntry>>(
          await _local.queryMoods(userId, days: days),
        );
      } catch (e2, st2) {
        LoggerService.e('getMoodHistory local', e2, st2);
        return Left<Failure, List<MoodEntry>>(_mapFirebase(e));
      }
    }
  }

  @override
  Stream<Either<Failure, MoodEntry?>> watchTodayMood(String userId) {
    final DateTime now = DateTime.now();
    return _remote.watchRecentMoods(userId).map((
      QuerySnapshot<Map<String, dynamic>> snap,
    ) {
      try {
        MoodEntry? today;
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
          final MoodEntry m = _moodFromMap(<String, dynamic>{
            'id': d.id,
            ...d.data(),
          });
          if (_sameDay(m.recordedAt, now)) {
            today = m;
            break;
          }
        }
        return Right<Failure, MoodEntry?>(today);
      } catch (e, st) {
        LoggerService.e('watchTodayMood', e, st);
        return Left<Failure, MoodEntry?>(_mapFirebase(e));
      }
    });
  }

  @override
  Future<Either<Failure, SurveyResult>> saveSurveyResult(
    SurveyResult result,
  ) async {
    try {
      await _local.upsertSurvey(result, synced: false);
      await _remote.setSurvey(result.userId, result.id, _surveyToMap(result));
      await _local.upsertSurvey(result, synced: true);
      return Right<Failure, SurveyResult>(result);
    } catch (e, st) {
      LoggerService.e('saveSurveyResult', e, st);
      return Left<Failure, SurveyResult>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, List<SurveyResult>>> getSurveyHistory(
    String userId,
    SurveyType type, {
    int limit = 5,
  }) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _remote
          .querySurveys(userId, type.name, limit);
      final List<SurveyResult> list = snap.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                _surveyFromMap(<String, dynamic>{'id': d.id, ...d.data()}),
          )
          .toList();
      return Right<Failure, List<SurveyResult>>(list);
    } catch (e, st) {
      LoggerService.e('getSurveyHistory', e, st);
      // No local querySurveys implemented yet, fallback to empty list
      return Right<Failure, List<SurveyResult>>(<SurveyResult>[]);
    }
  }

  @override
  Future<Either<Failure, SurveyResult?>> getLatestSurvey(
    String userId,
    SurveyType type,
  ) async {
    final Either<Failure, List<SurveyResult>> r = await getSurveyHistory(
      userId,
      type,
      limit: 1,
    );
    return r.fold(Left<Failure, SurveyResult?>.new, (List<SurveyResult> list) {
      if (list.isEmpty) {
        return const Right<Failure, SurveyResult?>(null);
      }
      return Right<Failure, SurveyResult?>(list.first);
    });
  }

  @override
  Future<Either<Failure, BreathingSession>> saveBreathingSession(
    BreathingSession session,
  ) async {
    try {
      final Map<String, dynamic> d = <String, dynamic>{
        'id': session.id,
        'userId': session.userId,
        'type': session.type.name,
        'durationSeconds': session.durationSeconds,
        'cyclesCompleted': session.cyclesCompleted,
        'completedAt': Timestamp.fromDate(session.completedAt),
      };
      await _local.upsertBreathing(session, synced: false);
      await _remote.setBreathing(session.userId, session.id, d);
      await _local.upsertBreathing(session, synced: true);
      return Right<Failure, BreathingSession>(session);
    } catch (e, st) {
      LoggerService.e('saveBreathingSession', e, st);
      return Left<Failure, BreathingSession>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, MeditationSession>> saveMeditationSession(
    MeditationSession session,
  ) async {
    try {
      final Map<String, dynamic> d = <String, dynamic>{
        'id': session.id,
        'userId': session.userId,
        'durationSeconds': session.durationSeconds,
        'ambientSound': session.ambientSound,
        'completed': session.completed,
        'completedAt': Timestamp.fromDate(session.completedAt),
      };
      await _local.upsertMeditation(session, synced: false);
      await _remote.setMeditation(session.userId, session.id, d);
      await _local.upsertMeditation(session, synced: true);
      return Right<Failure, MeditationSession>(session);
    } catch (e, st) {
      LoggerService.e('saveMeditationSession', e, st);
      return Left<Failure, MeditationSession>(_mapFirebase(e));
    }
  }

  @override
  Future<Either<Failure, MentalWellbeingSummary>> getMentalWellbeingSummary(
    String userId,
  ) async {
    try {
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final Either<Failure, List<MoodEntry>> moodsRes = await getMoodHistory(
        userId,
        days: 7,
      );
      Failure? moodFail;
      List<MoodEntry>? weekMoods;
      moodsRes.fold(
        (Failure f) => moodFail = f,
        (List<MoodEntry> m) => weekMoods = m,
      );
      if (moodFail != null) {
        return Left<Failure, MentalWellbeingSummary>(moodFail!);
      }
      final List<MoodEntry> moods = weekMoods ?? <MoodEntry>[];
      final MoodEntry? latest = moods.isEmpty ? null : moods.first;
      SurveyResult? phq9;
      SurveyResult? gad7;
      SurveyResult? pss10;

      final Either<Failure, SurveyResult?> phq9Res = await getLatestSurvey(
        userId,
        SurveyType.phq9,
      );
      Failure? phqFail;
      phq9Res.fold((Failure f) => phqFail = f, (SurveyResult? s) => phq9 = s);
      if (phqFail != null) {
        return Left<Failure, MentalWellbeingSummary>(phqFail!);
      }

      final Either<Failure, SurveyResult?> gad7Res = await getLatestSurvey(
        userId,
        SurveyType.gad7,
      );
      Failure? gadFail;
      gad7Res.fold((Failure f) => gadFail = f, (SurveyResult? s) => gad7 = s);
      if (gadFail != null) {
        return Left<Failure, MentalWellbeingSummary>(gadFail!);
      }

      final Either<Failure, SurveyResult?> pss10Res = await getLatestSurvey(
        userId,
        SurveyType.pss10,
      );
      Failure? pssFail;
      pss10Res.fold((Failure f) => pssFail = f, (SurveyResult? s) => pss10 = s);
      if (pssFail != null) {
        return Left<Failure, MentalWellbeingSummary>(pssFail!);
      }
      final QuerySnapshot<Map<String, dynamic>> breathSnap = await _remote
          .queryBreathingSince(userId, weekAgo);
      final QuerySnapshot<Map<String, dynamic>> medSnap = await _remote
          .queryMeditationSince(userId, weekAgo);
      final QuerySnapshot<Map<String, dynamic>> stressSnap = await _remote
          .queryLatestStress(userId);
      StressScore? stress;
      if (stressSnap.docs.isNotEmpty) {
        stress = _stressFromMap(<String, dynamic>{
          'id': stressSnap.docs.first.id,
          ...stressSnap.docs.first.data(),
        });
      }
      int medMin = 0;
      for (final QueryDocumentSnapshot<Map<String, dynamic>> d
          in medSnap.docs) {
        final int sec = (d.data()['durationSeconds'] as num?)?.toInt() ?? 0;
        medMin += sec ~/ 60;
      }
      return Right<Failure, MentalWellbeingSummary>(
        MentalWellbeingSummary(
          latestMood: latest,
          weeklyMoods: moods,
          latestPhq9: phq9,
          latestGad7: gad7,
          latestPss10: pss10,
          currentStressScore: stress,
          breathingSessionsThisWeek: breathSnap.docs.length,
          meditationMinutesThisWeek: medMin,
        ),
      );
    } catch (e, st) {
      LoggerService.e('getMentalWellbeingSummary', e, st);
      return Left<Failure, MentalWellbeingSummary>(_mapFirebase(e));
    }
  }

  StressScore _stressFromMap(Map<String, dynamic> j) {
    return StressScore(
      id: j['id'] as String?,
      userId: j['userId'] as String? ?? '',
      calculatedAt: _readTs(j['calculatedAt']) ?? DateTime.now(),
      score: (j['score'] as num?)?.toDouble() ?? 0,
      level: StressLevel.values.firstWhere(
        (StressLevel l) => l.name == (j['level'] as String? ?? 'low'),
        orElse: () => StressLevel.low,
      ),
      hrvScore: (j['hrvScore'] as num?)?.toDouble(),
      sleepScore: (j['sleepScore'] as num?)?.toDouble(),
      moodScore: (j['moodScore'] as num?)?.toDouble(),
      surveyScore: (j['surveyScore'] as num?)?.toDouble(),
      aiInsight: j['aiInsight'] as String? ?? '',
    );
  }

  @override
  Future<Either<Failure, StressScore>> calculateAndSaveStressScore(
    String userId,
  ) async {
    try {
      final double? hrvMs = await _health.getLatestHrvMs();
      double? hrvNorm;
      if (hrvMs != null) {
        hrvNorm = ((hrvMs - 20) / 80 * 100).clamp(0, 100).toDouble();
      }
      final DateTime now = DateTime.now();
      final Either<Failure, List<SleepLog>> sleepRes = await _activity
          .getSleepLogs(
            userId,
            from: now.subtract(const Duration(days: 7)),
            to: now,
          );
      double? sleepNorm;
      sleepRes.fold((_) {}, (List<SleepLog> logs) {
        if (logs.isEmpty) {
          return;
        }
        double sum = 0;
        int n = 0;
        for (final SleepLog l in logs) {
          if (l.quality != null) {
            sum += (l.quality!.clamp(0, 1)) * 100;
            n++;
          }
        }
        if (n > 0) {
          sleepNorm = sum / n;
        }
      });
      final Either<Failure, List<MoodEntry>> moodRes = await getMoodHistory(
        userId,
        days: 3,
      );
      double? moodNorm;
      moodRes.fold((_) {}, (List<MoodEntry> list) {
        if (list.isNotEmpty) {
          moodNorm = StressCalculator.moodToCalmNorm(
            list.first.mood.storageValue,
          );
        }
      });
      final Either<Failure, SurveyResult?> surv = await getLatestSurvey(
        userId,
        SurveyType.phq9,
      );
      double? surveyNorm = 50;
      surv.fold((_) {}, (SurveyResult? s) {
        if (s != null &&
            now.difference(s.completedAt) <= const Duration(days: 7)) {
          surveyNorm = StressCalculator.phqGadTotalToStressNorm(
            s.totalScore,
            maxScore: 27,
          );
        }
      });
      final double raw = StressCalculator.computeRawStress(
        hrvNorm: hrvNorm,
        sleepNorm: sleepNorm,
        moodNorm: moodNorm,
        surveyNorm: surveyNorm,
      );
      final StressLevel level = StressCalculator.levelFor(raw);
      final double surveyComponent = surveyNorm ?? 50;
      final Either<Failure, String> insight = await _ai
          .getMentalWellbeingInsight(
            moodLabel: moodNorm != null ? 'logged' : 'unknown',
            sleepQualityLabel: sleepNorm != null ? 'available' : 'unknown',
            activityMinutesThisWeek: 0,
            surveySummaryLabel: surveyComponent < 70
                ? 'elevated screening scores'
                : 'minimal',
          );
      final String text = insight.fold(
        (Failure f) => f.message ?? 'Insight unavailable',
        (String s) => s,
      );
      final String id = 'stress-$userId-${now.millisecondsSinceEpoch}';
      final StressScore score = StressScore(
        id: id,
        userId: userId,
        calculatedAt: now,
        score: raw,
        level: level,
        hrvScore: hrvNorm,
        sleepScore: sleepNorm,
        moodScore: moodNorm,
        surveyScore: surveyNorm,
        aiInsight: text,
      );
      final Map<String, dynamic> data = <String, dynamic>{
        'id': id,
        'userId': userId,
        'calculatedAt': Timestamp.fromDate(now),
        'score': raw,
        'level': level.name,
        'hrvScore': hrvNorm,
        'sleepScore': sleepNorm,
        'moodScore': moodNorm,
        'surveyScore': surveyNorm,
        'aiInsight': text,
      };
      final String payload = jsonEncode(
        data,
        toEncodable: (Object? o) {
          if (o is Timestamp) {
            return o.millisecondsSinceEpoch;
          }
          return o;
        },
      );
      await _local.upsertStressJson(
        id: id,
        userId: userId,
        payloadJson: payload,
        calculatedAt: now,
        synced: false,
      );
      await _remote.setStress(userId, id, data);
      await _local.upsertStressJson(
        id: id,
        userId: userId,
        payloadJson: payload,
        calculatedAt: now,
        synced: true,
      );
      return Right<Failure, StressScore>(score);
    } catch (e, st) {
      LoggerService.e('calculateAndSaveStressScore', e, st);
      return Left<Failure, StressScore>(_mapFirebase(e));
    }
  }

  // NOTE: Kept intentionally minimal; unused helpers removed after analyzer fixes.
}
