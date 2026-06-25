import 'package:flutter/foundation.dart';

import 'profile_enums.dart';

/// Local + remote app settings (notifications, theme, units).
@immutable
class AppSettings {
  /// Default notification + display preferences (Firestore seed + first launch).
  static AppSettings defaults() => const AppSettings();

  const AppSettings({
    this.masterPushEnabled = true,
    this.mealReminders = true,
    this.hydrationReminders = true,
    this.workoutReminders = true,
    this.sleepReminders = true,
    this.medicationReminders = true,
    this.aiNudges = true,
    this.themePreference = FitupThemePreference.dark,
    this.useMetricUnits = true,
    this.languageCode = 'en',
  });

  final bool masterPushEnabled;
  final bool mealReminders;
  final bool hydrationReminders;
  final bool workoutReminders;
  final bool sleepReminders;
  final bool medicationReminders;
  final bool aiNudges;
  final FitupThemePreference themePreference;
  final bool useMetricUnits;
  final String? languageCode;

  /// Same as [masterPushEnabled] (spec / API docs name).
  bool get pushNotificationsEnabled => masterPushEnabled;

  AppSettings copyWith({
    bool? masterPushEnabled,
    bool? mealReminders,
    bool? hydrationReminders,
    bool? workoutReminders,
    bool? sleepReminders,
    bool? medicationReminders,
    bool? aiNudges,
    FitupThemePreference? themePreference,
    bool? useMetricUnits,
    String? languageCode,
  }) {
    return AppSettings(
      masterPushEnabled: masterPushEnabled ?? this.masterPushEnabled,
      mealReminders: mealReminders ?? this.mealReminders,
      hydrationReminders: hydrationReminders ?? this.hydrationReminders,
      workoutReminders: workoutReminders ?? this.workoutReminders,
      sleepReminders: sleepReminders ?? this.sleepReminders,
      medicationReminders: medicationReminders ?? this.medicationReminders,
      aiNudges: aiNudges ?? this.aiNudges,
      themePreference: themePreference ?? this.themePreference,
      useMetricUnits: useMetricUnits ?? this.useMetricUnits,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
