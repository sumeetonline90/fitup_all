import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../profile/domain/entities/app_settings.dart';
import '../../profile/domain/entities/profile_enums.dart';

abstract final class AppSettingsCodec {
  static AppSettings fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> m = doc.data() ?? <String, dynamic>{};
    final int ti = (m['themeIndex'] as num?)?.toInt() ?? 2;
    return AppSettings(
      masterPushEnabled: m['masterPushEnabled'] as bool? ?? true,
      mealReminders: m['mealReminders'] as bool? ?? true,
      hydrationReminders: m['hydrationReminders'] as bool? ?? true,
      workoutReminders: m['workoutReminders'] as bool? ?? true,
      sleepReminders: m['sleepReminders'] as bool? ?? true,
      medicationReminders: m['medicationReminders'] as bool? ?? true,
      aiNudges: m['aiNudges'] as bool? ?? true,
      themePreference: FitupThemePreference
          .values[ti.clamp(0, FitupThemePreference.values.length - 1)],
      useMetricUnits: m['useMetricUnits'] as bool? ?? true,
      languageCode: m['languageCode'] as String? ?? 'en',
    );
  }

  static Map<String, dynamic> toFirestore(AppSettings s) {
    return <String, dynamic>{
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
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String toJsonString(AppSettings s) => jsonEncode(_plain(s));

  static AppSettings fromJsonString(String raw) {
    final Map<String, dynamic> m =
        jsonDecode(raw) as Map<String, dynamic>;
    final int ti = (m['themeIndex'] as num?)?.toInt() ?? 2;
    return AppSettings(
      masterPushEnabled: m['masterPushEnabled'] as bool? ?? true,
      mealReminders: m['mealReminders'] as bool? ?? true,
      hydrationReminders: m['hydrationReminders'] as bool? ?? true,
      workoutReminders: m['workoutReminders'] as bool? ?? true,
      sleepReminders: m['sleepReminders'] as bool? ?? true,
      medicationReminders: m['medicationReminders'] as bool? ?? true,
      aiNudges: m['aiNudges'] as bool? ?? true,
      themePreference:
          FitupThemePreference.values[ti.clamp(0, FitupThemePreference.values.length - 1)],
      useMetricUnits: m['useMetricUnits'] as bool? ?? true,
      languageCode: m['languageCode'] as String? ?? 'en',
    );
  }

  static Map<String, dynamic> _plain(AppSettings s) {
    return <String, dynamic>{
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
    };
  }
}
