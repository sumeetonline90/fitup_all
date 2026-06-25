import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../sync/sync_service.dart';
import '../sync/sync_status_emitter.dart';

import '../../features/activity/data/datasources/activity_local_datasource.dart';
import '../../features/activity/data/datasources/drift_activity_local_datasource.dart';
import '../../features/activity/data/datasources/in_memory_activity_local_datasource.dart';
import '../../features/activity/data/repositories/firebase_activity_repository.dart';
import '../../features/activity/domain/repositories/activity_repository.dart';
import '../../features/auth/data/repositories/firebase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/profile/data/repositories/firebase_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/community/data/repositories/firebase_community_repository.dart';
import '../../features/community/domain/repositories/community_repository.dart';
import '../../features/fitcoins/data/repositories/firebase_fitcoin_repository.dart';
import '../../features/fitcoins/domain/repositories/fitcoin_repository.dart';
import '../../features/fitcoins/domain/services/fitcoin_award_service.dart';
import '../../features/diet/data/datasources/diet_local_datasource.dart';
import '../../features/diet/data/datasources/drift_diet_local_datasource.dart';
import '../../features/diet/data/datasources/diet_remote_datasource.dart';
import '../../features/diet/data/datasources/in_memory_diet_local_datasource.dart';
import '../../features/diet/data/repositories/firebase_diet_repository.dart';
import '../../features/diet/data/repositories/food_repository_impl.dart';
import '../../features/diet/domain/repositories/diet_repository.dart';
import '../../features/diet/domain/repositories/food_repository.dart';
import '../../features/workout/data/datasources/drift_workout_local_datasource.dart';
import '../../features/workout/data/datasources/in_memory_workout_local_datasource.dart';
import '../../features/workout/data/datasources/workout_local_datasource.dart';
import '../../features/workout/data/datasources/workout_remote_datasource.dart';
import '../../features/workout/data/repositories/exercise_repository_impl.dart';
import '../../features/workout/data/repositories/firebase_workout_repository.dart';
import '../../features/workout/domain/repositories/exercise_repository.dart';
import '../../features/workout/domain/repositories/workout_repository.dart';
import '../../features/workout/domain/usecases/complete_session_usecase.dart';
import '../../features/workout/domain/usecases/generate_workout_plan_usecase.dart';
import '../../features/workout/domain/usecases/get_personal_records_usecase.dart';
import '../../features/workout/domain/usecases/get_workout_summary_usecase.dart';
import '../../features/workout/domain/usecases/log_workout_usecase.dart';
import '../../features/workout/domain/usecases/search_exercises_usecase.dart';
import '../../features/health/data/datasources/drift_health_local_datasource.dart';
import '../../features/health/data/datasources/health_local_datasource.dart';
import '../../features/health/data/datasources/health_remote_datasource.dart';
import '../../features/health/data/datasources/in_memory_health_local_datasource.dart';
import '../../features/health/data/repositories/firebase_health_repository.dart';
import '../../features/health/domain/repositories/health_repository.dart';
import '../../features/mental_wellbeing/data/datasources/drift_mental_wellbeing_local_datasource.dart';
import '../../features/mental_wellbeing/data/datasources/in_memory_mental_wellbeing_local_datasource.dart';
import '../../features/mental_wellbeing/data/datasources/mental_wellbeing_local_datasource.dart';
import '../../features/mental_wellbeing/data/datasources/mental_wellbeing_remote_datasource.dart';
import '../../features/mental_wellbeing/data/repositories/firebase_mental_wellbeing_repository.dart';
import '../../features/mental_wellbeing/domain/repositories/mental_wellbeing_repository.dart';
import '../../features/insights/data/datasources/drift_insight_local_datasource.dart';
import '../../features/insights/data/datasources/in_memory_insight_local_datasource.dart';
import '../../features/insights/data/datasources/insight_local_datasource.dart';
import '../../features/insights/data/datasources/insight_remote_datasource.dart';
import '../../features/insights/data/repositories/firebase_holistic_plan_repository.dart';
import '../../features/insights/data/repositories/firebase_insight_repository.dart';
import '../../features/insights/domain/repositories/insight_repository.dart';
import '../../features/insights/domain/repositories/holistic_plan_repository.dart';
import '../../features/insights/domain/services/conflict_detector.dart';
import '../../features/insights/domain/services/holistic_context_builder.dart';
import '../database/health_sync_metadata_dao.dart';
import '../../features/settings/data/repositories/firebase_app_settings_repository.dart';
import '../../features/settings/domain/repositories/app_settings_repository.dart';
import '../../services/account_deletion_service.dart';
import '../../services/ai_service.dart';
import '../../services/ai_usage_service.dart';
import '../../services/analytics_service.dart';
import '../../services/sos_service.dart';
import '../../services/barcode_scanner_service.dart';
import '../../services/food_database_service.dart';
import '../../services/health_connect_service.dart';
import '../../services/data_export_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/revenue_cat_subscription_service.dart';
import '../../services/permission_service.dart';
import '../../services/subscription_service.dart';
import '../database/fitup_database.dart';

final GetIt getIt = GetIt.instance;

/// Registers cross-cutting services and repositories (get_it).
void configureDependencies() {
  if (getIt.isRegistered<AuthRepository>()) {
    return;
  }
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );
  getIt.registerLazySingleton<SyncStatusEmitter>(SyncStatusEmitter.new);
  getIt.registerLazySingleton<AccountDeletionService>(
    () => AccountDeletionService(
      firestore,
      FirebaseStorage.instance,
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      auth,
      firestore,
      googleSignIn,
      getIt<AccountDeletionService>(),
    ),
  );
  getIt.registerLazySingleton<AnalyticsService>(AnalyticsService.new);
  getIt.registerLazySingleton<SosService>(SosService.new);
  getIt.registerLazySingleton<AiUsageService>(AiUsageService.new);

  getIt.registerLazySingleton<LocationService>(LocationService.new);
  getIt.registerLazySingleton<HealthConnectService>(HealthConnectService.new);
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService(
      getIt<HealthConnectService>(),
      getIt<LocationService>(),
    ),
  );

  if (kIsWeb) {
    getIt.registerLazySingleton<ActivityLocalDataSource>(
      InMemoryActivityLocalDataSource.new,
    );
  } else {
    getIt.registerLazySingleton<FitupDatabase>(FitupDatabase.new);
    getIt.registerLazySingleton<HealthSyncMetadataDao>(
      () => HealthSyncMetadataDao(getIt<FitupDatabase>()),
    );
    getIt.registerLazySingleton<ActivityLocalDataSource>(
      () => DriftActivityLocalDataSource(getIt<FitupDatabase>()),
    );
  }

  getIt.registerLazySingleton<ProfileRepository>(
    () => FirebaseProfileRepository(
      firestore,
      FirebaseStorage.instance,
      database: kIsWeb ? null : getIt<FitupDatabase>(),
      syncEmitter: kIsWeb ? null : getIt<SyncStatusEmitter>(),
      onProfileRemoteFailed: kIsWeb
          ? null
          : (String uid) => getIt<SyncService>().enqueueProfileSync(uid),
    ),
  );
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(
      getIt<ProfileRepository>(),
      Connectivity(),
      firestore,
      fitcoinAwardService: getIt<FitcoinAwardService>(),
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    )..startListening(),
  );
  getIt.registerLazySingleton<AppSettingsRepository>(
    () => FirebaseAppSettingsRepository(
      firestore,
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );

  getIt.registerLazySingleton<FitcoinRepository>(
    () => FirebaseFitcoinRepository(
      firestore,
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );
  getIt.registerLazySingleton<FitcoinAwardService>(
    () => FitcoinAwardService(
      getIt<FitcoinRepository>(),
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );
  getIt.registerLazySingleton<CommunityRepository>(
    () => FirebaseCommunityRepository(
      firestore,
      database: kIsWeb ? null : getIt<FitupDatabase>(),
      fitcoinAwardService: getIt<FitcoinAwardService>(),
    ),
  );

  getIt.registerLazySingleton<ActivityRepository>(
    () => FirebaseActivityRepository(
      firestore,
      getIt<ActivityLocalDataSource>(),
      fitcoinAwardService: getIt<FitcoinAwardService>(),
    ),
  );

  getIt.registerLazySingleton<DietRemoteDatasource>(
    () => DietRemoteDatasource(firestore),
  );
  if (kIsWeb) {
    getIt.registerLazySingleton<DietLocalDatasource>(
      InMemoryDietLocalDatasource.new,
    );
  } else {
    getIt.registerLazySingleton<DietLocalDatasource>(
      () => DriftDietLocalDatasource(getIt<FitupDatabase>()),
    );
  }
  getIt.registerLazySingleton<DietRepository>(
    () => FirebaseDietRepository(
      firestore,
      getIt<DietRemoteDatasource>(),
      getIt<DietLocalDatasource>(),
      fitcoinAwardService: getIt<FitcoinAwardService>(),
      profileRepository: getIt<ProfileRepository>(),
    ),
  );
  getIt.registerLazySingleton<FoodDatabaseService>(
    () => FoodDatabaseService(database: kIsWeb ? null : getIt<FitupDatabase>()),
  );
  getIt.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(
      firestore,
      getIt<FoodDatabaseService>(),
      kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );
  getIt.registerLazySingleton<BarcodeScannerService>(BarcodeScannerService.new);

  getIt.registerLazySingleton<WorkoutRemoteDatasource>(
    () => WorkoutRemoteDatasource(firestore),
  );
  if (kIsWeb) {
    getIt.registerLazySingleton<WorkoutLocalDatasource>(
      InMemoryWorkoutLocalDatasource.new,
    );
  } else {
    getIt.registerLazySingleton<WorkoutLocalDatasource>(
      () => DriftWorkoutLocalDatasource(getIt<FitupDatabase>()),
    );
  }
  getIt.registerLazySingleton<WorkoutRepository>(
    () => FirebaseWorkoutRepository(
      firestore,
      getIt<WorkoutRemoteDatasource>(),
      getIt<WorkoutLocalDatasource>(),
      fitcoinAwardService: getIt<FitcoinAwardService>(),
    ),
  );
  getIt.registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepositoryImpl(firestore, getIt<WorkoutLocalDatasource>()),
  );

  getIt.registerLazySingleton<LogWorkoutUseCase>(
    () => LogWorkoutUseCase(getIt<WorkoutRepository>()),
  );
  getIt.registerLazySingleton<GetWorkoutSummaryUseCase>(
    () => GetWorkoutSummaryUseCase(getIt<WorkoutRepository>()),
  );
  getIt.registerLazySingleton<SearchExercisesUseCase>(
    () => SearchExercisesUseCase(getIt<ExerciseRepository>()),
  );
  getIt.registerLazySingleton<GetPersonalRecordsUseCase>(
    () => GetPersonalRecordsUseCase(getIt<WorkoutRepository>()),
  );
  getIt.registerLazySingleton<CompleteSessionUseCase>(
    () => CompleteSessionUseCase(getIt<WorkoutRepository>()),
  );

  getIt.registerLazySingleton<AiService>(
    () => AiService(
      activityRepository: getIt<ActivityRepository>(),
      dietRepository: getIt<DietRepository>(),
      usageTracker: getIt<AiUsageService>(),
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );

  getIt.registerLazySingleton<GenerateWorkoutPlanUseCase>(
    () => GenerateWorkoutPlanUseCase(
      getIt<AiService>(),
      getIt<WorkoutRepository>(),
      getIt<ExerciseRepository>(),
    ),
  );

  getIt.registerLazySingleton<HealthRemoteDatasource>(
    () => HealthRemoteDatasource(firestore),
  );
  if (kIsWeb) {
    getIt.registerLazySingleton<HealthLocalDatasource>(
      InMemoryHealthLocalDatasource.new,
    );
  } else {
    getIt.registerLazySingleton<HealthLocalDatasource>(
      () => DriftHealthLocalDatasource(getIt<FitupDatabase>()),
    );
  }
  getIt.registerLazySingleton<HealthRepository>(
    () => FirebaseHealthRepository(
      getIt<HealthRemoteDatasource>(),
      getIt<HealthLocalDatasource>(),
      fitcoinAwardService: getIt<FitcoinAwardService>(),
    ),
  );

  getIt.registerLazySingleton<MentalWellbeingRemoteDatasource>(
    () => MentalWellbeingRemoteDatasource(firestore),
  );
  if (kIsWeb) {
    getIt.registerLazySingleton<MentalWellbeingLocalDatasource>(
      InMemoryMentalWellbeingLocalDatasource.new,
    );
  } else {
    getIt.registerLazySingleton<MentalWellbeingLocalDatasource>(
      () => DriftMentalWellbeingLocalDatasource(getIt<FitupDatabase>()),
    );
  }
  getIt.registerLazySingleton<MentalWellbeingRepository>(
    () => FirebaseMentalWellbeingRepository(
      getIt<MentalWellbeingRemoteDatasource>(),
      getIt<MentalWellbeingLocalDatasource>(),
      getIt<ActivityRepository>(),
      getIt<HealthConnectService>(),
      getIt<AiService>(),
    ),
  );

  getIt.registerLazySingleton<HolisticContextBuilder>(
    () => HolisticContextBuilder(
      activityRepo: getIt<ActivityRepository>(),
      dietRepo: getIt<DietRepository>(),
      workoutRepo: getIt<WorkoutRepository>(),
      healthRepo: getIt<HealthRepository>(),
      mentalRepo: getIt<MentalWellbeingRepository>(),
      communityRepo: getIt<CommunityRepository>(),
      healthConnect: getIt<HealthConnectService>(),
      profileRepo: getIt<ProfileRepository>(),
    ),
  );

  getIt.registerLazySingleton<InsightRemoteDatasource>(
    () => InsightRemoteDatasource(firestore),
  );
  if (kIsWeb) {
    getIt.registerLazySingleton<InsightLocalDatasource>(
      InMemoryInsightLocalDatasource.new,
    );
  } else {
    getIt.registerLazySingleton<InsightLocalDatasource>(
      () => DriftInsightLocalDatasource(getIt<FitupDatabase>()),
    );
  }
  getIt.registerLazySingleton<ConflictDetector>(ConflictDetector.new);
  getIt.registerLazySingleton<InsightRepository>(
    () => FirebaseInsightRepository(
      getIt<InsightLocalDatasource>(),
      getIt<InsightRemoteDatasource>(),
      getIt<AiService>(),
      getIt<HolisticContextBuilder>(),
      getIt<ConflictDetector>(),
    ),
  );

  getIt.registerLazySingleton<HolisticPlanRepository>(
    () => FirebaseHolisticPlanRepository(
      firestore: firestore,
      connectivity: Connectivity(),
      database: kIsWeb ? null : getIt<FitupDatabase>(),
    ),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<HealthRepository>()),
  );
  getIt.registerLazySingleton<SubscriptionService>(() {
    if (kIsWeb) {
      return StubSubscriptionService(getIt<ProfileRepository>());
    }
    return RevenueCatSubscriptionService();
  });
  getIt.registerLazySingleton<DataExportService>(
    () => DataExportService(
      database: kIsWeb ? null : getIt<FitupDatabase>(),
      profileRepository: getIt<ProfileRepository>(),
      appSettingsRepository: getIt<AppSettingsRepository>(),
      communityRepository: getIt<CommunityRepository>(),
      activityRepository: getIt<ActivityRepository>(),
      dietRepository: getIt<DietRepository>(),
      workoutRepository: getIt<WorkoutRepository>(),
      healthRepository: getIt<HealthRepository>(),
      mentalWellbeingRepository: getIt<MentalWellbeingRepository>(),
    ),
  );
}
