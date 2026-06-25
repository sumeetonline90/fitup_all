import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/database/fitup_database.dart';
import '../core/error/failures.dart';
import '../features/activity/domain/entities/activity.dart';
import '../features/activity/domain/repositories/activity_repository.dart';
import '../features/community/domain/entities/feed_post.dart';
import '../features/community/domain/repositories/community_repository.dart';
import '../features/diet/domain/entities/meal.dart';
import '../features/diet/domain/repositories/diet_repository.dart';
import '../features/health/domain/entities/medication_log.dart';
import '../features/health/domain/entities/vital_entry.dart';
import '../features/health/domain/entities/vital_type.dart';
import '../features/health/domain/repositories/health_repository.dart';
import '../features/mental_wellbeing/domain/entities/mood_entry.dart';
import '../features/mental_wellbeing/domain/repositories/mental_wellbeing_repository.dart';
import '../features/profile/domain/entities/app_settings.dart';
import '../features/profile/domain/entities/user_profile.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/settings/domain/repositories/app_settings_repository.dart';
import '../features/workout/domain/entities/workout.dart';
import '../features/workout/domain/repositories/workout_repository.dart';

/// GDPR / DPDPA-style JSON export (user-owned backup; not medical advice).
class DataExportService {
  DataExportService({
    required FitupDatabase? database,
    required ProfileRepository profileRepository,
    required AppSettingsRepository appSettingsRepository,
    required CommunityRepository communityRepository,
    required ActivityRepository activityRepository,
    required DietRepository dietRepository,
    required WorkoutRepository workoutRepository,
    required HealthRepository healthRepository,
    required MentalWellbeingRepository mentalWellbeingRepository,
  })  : _db = database,
        _profileRepository = profileRepository,
        _appSettingsRepository = appSettingsRepository,
        _communityRepository = communityRepository,
        _activityRepository = activityRepository,
        _dietRepository = dietRepository,
        _workoutRepository = workoutRepository,
        _healthRepository = healthRepository,
        _mentalWellbeingRepository = mentalWellbeingRepository;

  final FitupDatabase? _db;
  final ProfileRepository _profileRepository;
  final AppSettingsRepository _appSettingsRepository;
  final CommunityRepository _communityRepository;
  final ActivityRepository _activityRepository;
  final DietRepository _dietRepository;
  final WorkoutRepository _workoutRepository;
  final HealthRepository _healthRepository;
  final MentalWellbeingRepository _mentalWellbeingRepository;

  /// Writes JSON under app documents `user/{userId}/` and returns the file path.
  Future<Either<Failure, String>> exportUserData(String userId) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime from = now.subtract(const Duration(days: 365));
      final Directory base = await getApplicationDocumentsDirectory();
      final Directory outDir = Directory(
        p.join(base.path, 'user', userId),
      );
      await outDir.create(recursive: true);
      final String name =
          'fitup_export_${DateFormat('yyyyMMdd').format(now)}.json';
      final File file = File(p.join(outDir.path, name));

      final Either<Failure, UserProfile> profileRes =
          await _profileRepository.getProfile(userId);
      final Map<String, dynamic>? profileMap = profileRes.fold(
        (_) => null,
        _profileToMap,
      );

      final Either<Failure, AppSettings> settingsRes =
          await _appSettingsRepository.getSettings(userId);
      final Map<String, dynamic>? settingsMap = settingsRes.fold(
        (_) => null,
        (AppSettings s) => <String, dynamic>{
          'masterPushEnabled': s.masterPushEnabled,
          'mealReminders': s.mealReminders,
          'hydrationReminders': s.hydrationReminders,
          'workoutReminders': s.workoutReminders,
          'sleepReminders': s.sleepReminders,
          'medicationReminders': s.medicationReminders,
          'aiNudges': s.aiNudges,
          'themeIndex': s.themePreference.index,
          'useMetricUnits': s.useMetricUnits,
          'languageCode': s.languageCode,
        },
      );

      final Either<Failure, List<Activity>> actRes =
          await _activityRepository.getActivities(userId, from: from, to: now);
      final List<Map<String, dynamic>> activities = actRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<Activity> list) => list.map(_activityToMap).toList(),
      );

      final Either<Failure, List<Meal>> mealsRes =
          await _dietRepository.getMealsByDateRange(userId, from, now);
      final List<Map<String, dynamic>> meals = mealsRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<Meal> list) => list
            .map(
              (Meal m) => <String, dynamic>{
                'id': m.id,
                'dateTime': m.dateTime.toIso8601String(),
                'totalCalories': m.totalCalories,
              },
            )
            .toList(),
      );

      final Either<Failure, List<WorkoutLog>> workoutsRes =
          await _workoutRepository.getWorkoutLogs(
        userId,
        dateFrom: from,
        dateTo: now,
      );
      final List<Map<String, dynamic>> workouts = workoutsRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<WorkoutLog> list) =>
            list.map((WorkoutLog w) => <String, dynamic>{'id': w.id}).toList(),
      );

      final List<Map<String, dynamic>> vitals = <Map<String, dynamic>>[];
      for (final VitalType t in VitalType.values) {
        final Either<Failure, List<VitalEntry>> vRes =
            await _healthRepository.getVitalsForType(userId, t, limit: 50);
        vRes.fold((_) {}, (List<VitalEntry> list) {
          vitals.addAll(
            list.map(
              (VitalEntry v) => <String, dynamic>{
                'id': v.id,
                'type': v.type.name,
                'recordedAt': v.recordedAt.toIso8601String(),
              },
            ),
          );
        });
      }

      final Either<Failure, List<MedicationLog>> medsRes =
          await _healthRepository.getActiveMedications(userId);
      final List<Map<String, dynamic>> medications = medsRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<MedicationLog> list) => list
            .map(
              (MedicationLog m) => <String, dynamic>{
                'id': m.id,
                'name': m.medicationName,
              },
            )
            .toList(),
      );

      final Either<Failure, List<MoodEntry>> moodsRes =
          await _mentalWellbeingRepository.getMoodHistory(
        userId,
        days: 365,
      );
      final List<Map<String, dynamic>> moods = moodsRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<MoodEntry> list) => list
            .map(
              (MoodEntry m) => <String, dynamic>{
                'id': m.id,
                'recordedAt': m.recordedAt.toIso8601String(),
              },
            )
            .toList(),
      );

      final Either<Failure, List<FeedPost>> feedRes =
          await _communityRepository.getFeed(userId, limit: 200);
      final List<Map<String, dynamic>> myPosts = feedRes.fold(
        (_) => <Map<String, dynamic>>[],
        (List<FeedPost> posts) => posts
            .where((FeedPost p) => p.authorId == userId)
            .map(
              (FeedPost p) => <String, dynamic>{
                'id': p.id,
                'createdAt': p.createdAt.toIso8601String(),
              },
            )
            .toList(),
      );

      final Map<String, dynamic> driftMeta = <String, dynamic>{};
      final FitupDatabase? db = _db;
      if (db != null && !kIsWeb) {
        driftMeta['schemaVersion'] = db.schemaVersion;
        driftMeta['note'] =
            'Drift metadata only; row payloads are omitted from this export.';
      }

      final Map<String, Object?> root = <String, Object?>{
        'userId': userId,
        'exportedAt': now.toUtc().toIso8601String(),
        'exportVersion': 1,
        'dataController': 'Fitup (IVL)',
        'purposes': <String>[
          'Providing personalised health and fitness features',
          'Syncing your data across devices',
          'Product improvement and support',
        ],
        'processingBases': <String>[
          'Consent where you opt in (e.g. notifications, AI features)',
          'Performance of a contract (app use)',
        ],
        'disclaimer':
            'This export is for your records only — not medical advice.',
        'profile': profileMap,
        'appSettings': settingsMap,
        'activities': activities,
        'meals': meals,
        'workoutLogs': workouts,
        'vitals': vitals,
        'medications': medications,
        'moodEntries': moods,
        'communityPostsAuthored': myPosts,
        'drift': driftMeta,
      };

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(root),
      );
      return Right<Failure, String>(file.path);
    } catch (e, st) {
      return Left<Failure, String>(ServerFailure('$e\n$st'));
    }
  }

  Map<String, dynamic> _profileToMap(UserProfile p) {
    return <String, dynamic>{
      'userId': p.userId,
      'email': p.email,
      'displayName': p.displayName,
      'phone': p.phone,
    };
  }

  Map<String, dynamic> _activityToMap(Activity a) {
    return <String, dynamic>{
      'id': a.id,
      'type': a.type.name,
      'startTime': a.startTime.toIso8601String(),
      'endTime': a.endTime?.toIso8601String(),
      'distanceMeters': a.distanceMeters,
      'durationSeconds': a.durationSeconds,
      'caloriesBurnt': a.caloriesBurnt,
    };
  }
}
