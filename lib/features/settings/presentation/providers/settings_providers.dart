import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/notification_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/entities/app_settings.dart';
import '../../../profile/domain/entities/profile_enums.dart';
import '../../domain/repositories/app_settings_repository.dart';

const String _kMaster = 'fitup_settings_master_push';
const String _kMeal = 'fitup_settings_meal';
const String _kHydration = 'fitup_settings_hydration';
const String _kWorkout = 'fitup_settings_workout';
const String _kSleep = 'fitup_settings_sleep';
const String _kMed = 'fitup_settings_med';
const String _kAi = 'fitup_settings_ai';
const String _kTheme = 'fitup_settings_theme';
const String _kUnits = 'fitup_settings_units_metric';
const String _kLang = 'fitup_settings_lang';

/// Reads the same keys as [AppSettingsNotifier] (for startup / bootstrap).
AppSettings appSettingsFromSharedPreferences(SharedPreferences prefs) {
  final int ti = (prefs.getInt(_kTheme) ?? 2)
      .clamp(0, FitupThemePreference.values.length - 1)
      .toInt();
  return AppSettings(
    masterPushEnabled: prefs.getBool(_kMaster) ?? true,
    mealReminders: prefs.getBool(_kMeal) ?? true,
    hydrationReminders: prefs.getBool(_kHydration) ?? true,
    workoutReminders: prefs.getBool(_kWorkout) ?? true,
    sleepReminders: prefs.getBool(_kSleep) ?? true,
    medicationReminders: prefs.getBool(_kMed) ?? true,
    aiNudges: prefs.getBool(_kAi) ?? true,
    themePreference: FitupThemePreference.values[ti],
    useMetricUnits: prefs.getBool(_kUnits) ?? true,
    languageCode: prefs.getString(_kLang) ?? 'en',
  );
}

/// Async helper for [main] after DI.
Future<AppSettings> loadAppSettingsFromPrefs() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return appSettingsFromSharedPreferences(prefs);
}

/// App-wide toggles + preferences (SharedPreferences; optimistic UI).
final AsyncNotifierProvider<AppSettingsNotifier, AppSettings>
    settingsNotifierProvider =
    AsyncNotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

/// Alias (spec).
final AsyncNotifierProvider<AppSettingsNotifier, AppSettings>
    appSettingsProvider = settingsNotifierProvider;

class AppSettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return appSettingsFromSharedPreferences(prefs);
  }

  Future<void> saveSettings(AppSettings next) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMaster, next.masterPushEnabled);
    await prefs.setBool(_kMeal, next.mealReminders);
    await prefs.setBool(_kHydration, next.hydrationReminders);
    await prefs.setBool(_kWorkout, next.workoutReminders);
    await prefs.setBool(_kSleep, next.sleepReminders);
    await prefs.setBool(_kMed, next.medicationReminders);
    await prefs.setBool(_kAi, next.aiNudges);
    await prefs.setInt(_kTheme, next.themePreference.index);
    await prefs.setBool(_kUnits, next.useMetricUnits);
    if (next.languageCode != null) {
      await prefs.setString(_kLang, next.languageCode!);
    }
    state = AsyncData<AppSettings>(next);
    final String? uid = ref.read(authStateProvider).maybeWhen(
          data: (u) => u?.id,
          orElse: () => null,
        );
    if (uid == null) {
      return;
    }
    final Either<Failure, Unit> saved =
        await getIt<AppSettingsRepository>().saveSettings(uid, next);
    saved.fold(
      (Failure f) => LoggerService.e(
        'AppSettingsRepository.saveSettings',
        f,
        StackTrace.current,
      ),
      (_) {},
    );
    try {
      await getIt<NotificationService>().rescheduleAll(
        userId: uid,
        settings: next,
      );
    } catch (e, st) {
      LoggerService.e('NotificationService.rescheduleAll', e, st);
    }
  }
}

/// Opens [SubscriptionScreen] (native billing; web shows availability copy).
Future<void> launchSubscriptionFlow(BuildContext context) async {
  await context.push('/subscription');
}
