import 'package:drift/drift.dart';

import 'connection.dart';

part 'fitup_database.g.dart';

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  RealColumn get distanceMeters => real()();
  IntColumn get durationSeconds => integer()();
  RealColumn get caloriesBurnt => real()();
  TextColumn get routePointsJson => text().withDefault(const Constant('[]'))();
  IntColumn get steps => integer().nullable()();
  RealColumn get avgPace => real().nullable()();
  RealColumn get avgSpeed => real().nullable()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get gpsDropSeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get gpsDropInterruptions =>
      integer().withDefault(const Constant(0))();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('SleepLogRow')
class SleepLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get bedtime => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  IntColumn get durationMinutes => integer()();
  RealColumn get quality => real().nullable()();
  TextColumn get source => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get resourceType => text()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('DietMealCacheRow')
class DietMealCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WaterLogCacheRow')
class WaterLogCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  RealColumn get amountMl => real()();
  DateTimeColumn get loggedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('FoodSearchCacheRow')
class FoodSearchCache extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get userId => text()();
  TextColumn get resultsJson => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{cacheKey};
}

@DataClassName('FoodCatalogCacheRow')
class FoodCatalogCache extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('DietPlanCacheRow')
class DietPlanCache extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('ExerciseLibraryCacheRow')
class ExerciseLibraryCache extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('PersonalRecordCacheRow')
class PersonalRecordCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get exerciseId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WorkoutPlanCacheRow')
class WorkoutPlanCache extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('WorkoutLogCacheRow')
class WorkoutLogCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthVitalRow')
class HealthVitals extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get source => text()();
  TextColumn get notes => text().nullable()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WellbeingMoodRow')
class WellbeingMoods extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get moodLevel => integer()();
  TextColumn get journal => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WellbeingSurveyRow')
class WellbeingSurveyResults extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get surveyType => text()();
  TextColumn get answersJson => text()();
  IntColumn get totalScore => integer()();
  TextColumn get severity => text()();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get aiGuidance => text().nullable()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WellbeingBreathingRow')
class WellbeingBreathingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get breathingType => text()();
  IntColumn get durationSeconds => integer()();
  IntColumn get cyclesCompleted => integer()();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('WellbeingMeditationRow')
class WellbeingMeditationSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  IntColumn get durationSeconds => integer()();
  TextColumn get ambientSound => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
  BoolColumn get completed =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthLabReportRow')
class HealthLabReports extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get scannedAt => dateTime()();
  TextColumn get status => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthMedicationRow')
class HealthMedications extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthMenstrualRow')
class HealthMenstrualCycles extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthStressScoreRow')
class HealthStressScores extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get calculatedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('HealthInsightCacheRow')
class HealthInsightCache extends Table {
  TextColumn get userId => text()();
  TextColumn get summaryText => text()();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('InsightDailyBriefingRow')
class InsightDailyBriefings extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get dateKey => text()();
  TextColumn get morningText => text()();
  TextColumn get todaysGoalsJson => text()();
  TextColumn get alertsJson => text()();
  TextColumn get contextJson => text()();
  DateTimeColumn get generatedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('InsightWeeklyReportRow')
class InsightWeeklyReports extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get weekStartKey => text()();
  TextColumn get reportJson => text()();
  DateTimeColumn get generatedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('InsightChatMessageRow')
class InsightChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get moduleContext => text().nullable()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('FitcoinWalletCacheRow')
class FitcoinWalletCache extends Table {
  TextColumn get userId => text()();
  IntColumn get balance => integer()();
  IntColumn get totalEarned => integer()();
  IntColumn get totalSpent => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('FitcoinTransactionCacheRow')
class FitcoinTransactionsCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()();
  TextColumn get source => text().nullable()();
  IntColumn get amount => integer()();
  TextColumn get description => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get idempotencyKey => text().nullable()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('FitcoinIdempotencyCacheRow')
class FitcoinIdempotencyCache extends Table {
  TextColumn get keyId => text()();
  TextColumn get userId => text()();
  TextColumn get transactionId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{keyId};
}

@DataClassName('HolisticPlanRow')
class HolisticPlans extends Table {
  /// Stored as `plan_{micros}` to keep ids unique and URL/path safe.
  TextColumn get id => text()();
  TextColumn get userId => text()();

  /// Exactly one `isActive=true` plan per user in normal app flow.
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  /// Reserved for future (active/archived/cancelled), but kept as text so it
  /// can evolve without migrations.
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  /// Holistic-generated daily targets; `null` means "no target set".
  IntColumn get dailyStepGoal => integer().nullable()();
  IntColumn get dailyCalorieGoal => integer().nullable()();
  IntColumn get dailySleepGoalMinutes => integer().nullable()();
  IntColumn get dailyWaterGoalMl => integer().nullable()();
  IntColumn get dailyWorkoutGoalMinutes => integer().nullable()();

  /// JSON array of strings.
  TextColumn get majorGoalsJson =>
      text().withDefault(const Constant('[]'))();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('ModulePlanRow')
class ModulePlans extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get holisticPlanId => text()();

  /// e.g. `activity`, `diet`, `workout`, `mental`, `health`, `community`
  TextColumn get moduleKey => text()();

  /// Module plan snapshot (summary + any module-specific targets).
  TextColumn get payloadJson => text()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('PlanDailyCheckRow')
class PlanDailyChecks extends Table {
  /// Stable id: `check_{planId}_{dateKey}`.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get holisticPlanId => text()();
  TextColumn get dateKey => text()();

  /// Completion flags (derived from logs, persisted to keep UI stable
  /// offline and avoid recomputation).
  BoolColumn get stepsCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get caloriesCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get sleepCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get waterCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get workoutCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Stored AI suggestion text for nudges (may be empty).
  TextColumn get nudgeText => text().withDefault(const Constant(''))();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('CommunityEventsCacheRow')
class CommunityEventsCache extends Table {
  TextColumn get id => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('CommunityChallengesCacheRow')
class CommunityChallengesCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('CommunityFeedCacheRow')
class CommunityFeedCache extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get postId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('UserProfileCacheRow')
class UserProfileCache extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  BoolColumn get synced =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('AppSettingsCacheRow')
class AppSettingsCache extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

@DataClassName('OnboardingDraftCacheRow')
class OnboardingDraftCache extends Table {
  TextColumn get userId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{userId};
}

/// Health Connect / HealthKit sync timestamps for step/backfill logic.
///
/// We intentionally store a single row (id == `singleton`) so we can compute
/// missed days even if the user navigates across modules.
class HealthSyncMetadata extends Table {
  TextColumn get id => text().withDefault(const Constant('singleton'))();
  DateTimeColumn get lastStepSyncAt => dateTime().nullable()();
  DateTimeColumn get lastSleepSyncAt => dateTime().nullable()();
  DateTimeColumn get lastCalorieSyncAt => dateTime().nullable()();
  DateTimeColumn get lastHeartRateSyncAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Pending Fitcoin awards to retry when Firestore writes fail (offline).
class FitcoinAwardQueue extends Table {
  /// Stored as-is for idempotency scope. Primary key ensures "insert once".
  TextColumn get idempotencyKey => text()();
  TextColumn get userId => text()();
  TextColumn get source => text()();
  IntColumn get amount => integer()();
  TextColumn get description => text()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{idempotencyKey};
}

@DriftDatabase(
  tables: <Type>[
    Activities,
    SleepLogs,
    SyncQueue,
    DietMealCache,
    WaterLogCache,
    FoodSearchCache,
    FoodCatalogCache,
    DietPlanCache,
    ExerciseLibraryCache,
    PersonalRecordCache,
    WorkoutPlanCache,
    WorkoutLogCache,
    HealthVitals,
    WellbeingMoods,
    WellbeingSurveyResults,
    WellbeingBreathingSessions,
    WellbeingMeditationSessions,
    HealthLabReports,
    HealthMedications,
    HealthMenstrualCycles,
    HealthStressScores,
    HealthInsightCache,
    InsightDailyBriefings,
    InsightWeeklyReports,
    InsightChatMessages,
    FitcoinWalletCache,
    FitcoinTransactionsCache,
    FitcoinIdempotencyCache,
    FitcoinAwardQueue,
    CommunityEventsCache,
    CommunityChallengesCache,
    CommunityFeedCache,
    UserProfileCache,
    AppSettingsCache,
    OnboardingDraftCache,
    HealthSyncMetadata,
    HolisticPlans,
    ModulePlans,
    PlanDailyChecks,
  ],
)
class FitupDatabase extends _$FitupDatabase {
  FitupDatabase([QueryExecutor? executor]) : super(executor ?? openDriftConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(dietMealCache);
            await m.createTable(waterLogCache);
            await m.createTable(foodSearchCache);
            await m.createTable(foodCatalogCache);
            await m.createTable(dietPlanCache);
          }
          if (from < 3) {
            await m.createTable(exerciseLibraryCache);
            await m.createTable(personalRecordCache);
            await m.createTable(workoutPlanCache);
            await m.createTable(workoutLogCache);
          }
          if (from < 4) {
            await m.createTable(healthVitals);
            await m.createTable(wellbeingMoods);
            await m.createTable(wellbeingSurveyResults);
            await m.createTable(wellbeingBreathingSessions);
            await m.createTable(wellbeingMeditationSessions);
            await m.createTable(healthLabReports);
            await m.createTable(healthMedications);
            await m.createTable(healthMenstrualCycles);
            await m.createTable(healthStressScores);
            await m.createTable(healthInsightCache);
          }
          if (from < 5) {
            await m.createTable(insightDailyBriefings);
            await m.createTable(insightWeeklyReports);
            await m.createTable(insightChatMessages);
          }
          if (from < 6) {
            await m.createTable(fitcoinWalletCache);
            await m.createTable(fitcoinTransactionsCache);
            await m.createTable(fitcoinIdempotencyCache);
            await m.createTable(communityEventsCache);
            await m.createTable(communityChallengesCache);
            await m.createTable(communityFeedCache);
          }
          if (from < 7) {
            await m.createTable(userProfileCache);
            await m.createTable(appSettingsCache);
            await m.createTable(onboardingDraftCache);
          }
          if (from < 8) {
            await m.createTable(healthSyncMetadata);
            await m.createTable(fitcoinAwardQueue);
          }
          if (from < 9) {
            await m.addColumn(activities, activities.gpsDropSeconds);
            await m.addColumn(
              activities,
              activities.gpsDropInterruptions,
            );
          }
          if (from < 10) {
            await m.createTable(holisticPlans);
            await m.createTable(modulePlans);
            await m.createTable(planDailyChecks);
          }
        },
      );

  /// Deletes all local rows scoped to [userId] (account deletion / sign-out cleanup).
  Future<void> clearAllUserData(String userId) async {
    await (delete(activities)..where((t) => t.userId.equals(userId))).go();
    await (delete(sleepLogs)..where((t) => t.userId.equals(userId))).go();
    await (delete(syncQueue)..where((t) => t.userId.equals(userId))).go();
    await (delete(dietMealCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(waterLogCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(foodSearchCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(dietPlanCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(personalRecordCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(workoutPlanCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(workoutLogCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthVitals)..where((t) => t.userId.equals(userId))).go();
    await (delete(wellbeingMoods)..where((t) => t.userId.equals(userId))).go();
    await (delete(wellbeingSurveyResults)..where((t) => t.userId.equals(userId))).go();
    await (delete(wellbeingBreathingSessions)..where((t) => t.userId.equals(userId))).go();
    await (delete(wellbeingMeditationSessions)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthLabReports)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthMedications)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthMenstrualCycles)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthStressScores)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthInsightCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(insightDailyBriefings)..where((t) => t.userId.equals(userId))).go();
    await (delete(insightWeeklyReports)..where((t) => t.userId.equals(userId))).go();
    await (delete(insightChatMessages)..where((t) => t.userId.equals(userId))).go();
    await (delete(fitcoinWalletCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(fitcoinTransactionsCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(fitcoinIdempotencyCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(fitcoinAwardQueue)..where((t) => t.userId.equals(userId))).go();
    await (delete(communityChallengesCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(communityFeedCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(userProfileCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(appSettingsCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(onboardingDraftCache)..where((t) => t.userId.equals(userId))).go();
    await (delete(holisticPlans)..where((t) => t.userId.equals(userId))).go();
    await (delete(modulePlans)..where((t) => t.userId.equals(userId))).go();
    await (delete(planDailyChecks)..where((t) => t.userId.equals(userId))).go();
    await (delete(healthSyncMetadata)..where((t) => t.id.equals('singleton'))).go();
    await customStatement(
      'DELETE FROM food_catalog_cache WHERE id LIKE ?',
      <Object?>['custom_${userId}_%'],
    );
  }
}
