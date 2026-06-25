import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/sync/sync_status_emitter.dart';
import 'core/router/app_router.dart';
import 'features/profile/domain/entities/app_settings.dart';
import 'features/profile/domain/entities/profile_enums.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'l10n/app_localizations.dart';
import 'services/analytics_service.dart';
import 'services/health_connect_service.dart';
import 'services/notification_service.dart';
import 'services/revenue_cat_subscription_service.dart';
import 'services/subscription_service.dart';
import 'core/theme/app_theme.dart';
import 'features/workout/domain/repositories/exercise_repository.dart';
import 'features/activity/data/datasources/activity_local_datasource.dart';
import 'features/activity/domain/repositories/activity_repository.dart';
import 'core/database/health_sync_metadata_dao.dart';
import 'firebase_options.dart';
import 'services/logger_service.dart';
import 'services/trace_log_service.dart';
import 'features/fitcoins/domain/services/fitcoin_award_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  configureDependencies();

  if (!kIsWeb) {
    await TraceLogService.init();
  }

  if (!kIsWeb) {
    try {
      await RevenueCatSubscriptionService.configureSdk();
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await getIt<SubscriptionService>().identifyUser(uid);
        await getIt<AnalyticsService>().setUserId(uid);
      }
    } catch (e, st) {
      LoggerService.e('RevenueCat startup', e, st);
    }
  } else {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await getIt<AnalyticsService>().setUserId(uid);
      } catch (e, st) {
        LoggerService.e('Analytics setUserId on startup', e, st);
      }
    }
  }

  if (!kIsWeb) {
    try {
      await getIt<NotificationService>().initialize();
    } catch (e, st) {
      LoggerService.e('NotificationService.initialize', e, st);
    }
    try {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final AppSettings prefsSettings = await loadAppSettingsFromPrefs();
        if (prefsSettings.pushNotificationsEnabled) {
          await getIt<NotificationService>().rescheduleAll(
            userId: uid,
            settings: prefsSettings,
          );
        }

        // Passive backfill: if the user was away for multiple days, pull
        // Health Connect steps per day, upsert local passive rows, then
        // award daily step-goal Fitcoins idempotently.
        unawaited(
          getIt<HealthConnectService>().syncHistoricalSteps(
            userId: uid,
            localDs: getIt<ActivityLocalDataSource>(),
            fitcoinService: getIt<FitcoinAwardService>(),
            metadataDao: getIt<HealthSyncMetadataDao>(),
            activityRepository: getIt<ActivityRepository>(),
          ),
        );
      }
    } catch (e, st) {
      LoggerService.e('Notification reschedule on startup', e, st);
    }
  }

  try {
    await getIt<ExerciseRepository>().seedExercises();
  } catch (e, st) {
    LoggerService.e('Exercise seed', e, st);
  }

  LoggerService.i('Fitup starting');

  if (!kIsWeb) {
    FlutterForegroundTask.initCommunicationPort();
  }
  runApp(const ProviderScope(child: FitupApp()));
}

/// SnackBars for sync status (e.g. profile saved offline).
final GlobalKey<ScaffoldMessengerState> fitupScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Root: [MaterialApp.router] + go_router.
class FitupApp extends ConsumerStatefulWidget {
  const FitupApp({super.key});

  @override
  ConsumerState<FitupApp> createState() => _FitupAppState();
}

class _FitupAppState extends ConsumerState<FitupApp>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _syncMessages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Widget tests may pump [FitupApp] without [configureDependencies].
    if (!kIsWeb && getIt.isRegistered<SyncStatusEmitter>()) {
      _syncMessages = getIt<SyncStatusEmitter>().messages.listen((String msg) {
        fitupScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(msg)),
        );
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final StreamSubscription<String>? s = _syncMessages;
    if (s != null) {
      unawaited(s.cancel());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(TraceLogService.flush());
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);
    final AsyncValue<AppSettings> settingsAsync =
        ref.watch(settingsNotifierProvider);
    final Locale locale = settingsAsync.maybeWhen(
      data: (AppSettings s) => Locale(s.languageCode ?? 'en'),
      orElse: () => const Locale('en'),
    );
    final ThemeMode userThemeMode = settingsAsync.maybeWhen(
      data: (AppSettings s) => switch (s.themePreference) {
        FitupThemePreference.light => ThemeMode.light,
        FitupThemePreference.dark => ThemeMode.dark,
        FitupThemePreference.system => ThemeMode.system,
      },
      orElse: () => ThemeMode.dark,
    );
    return MaterialApp.router(
      title: 'Fitup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: kIsWeb ? ThemeMode.dark : userThemeMode,
      scaffoldMessengerKey: fitupScaffoldMessengerKey,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
