import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/error/failures.dart';
import '../features/health/domain/entities/medication_log.dart';
import '../features/health/domain/entities/medication_reminder_time.dart';
import '../features/health/domain/repositories/health_repository.dart';
import '../features/profile/domain/entities/app_settings.dart';
import '../features/profile/domain/entities/profile_enums.dart';
import 'logger_service.dart';

/// Local notification scheduling (mobile only; [kIsWeb] no-op).
class NotificationService {
  NotificationService(this._healthRepository);

  final HealthRepository _healthRepository;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _remindersChannel =
      AndroidNotificationChannel(
    'fitup_reminders',
    'Fitup reminders',
    description: 'Meals, hydration, workouts, sleep, insights',
    importance: Importance.low,
  );

  static const AndroidNotificationChannel _medicationsChannel =
      AndroidNotificationChannel(
    'fitup_medications',
    'Medications',
    description: 'Medication reminders',
    importance: Importance.high,
  );

  bool _initialized = false;

  static const String _kIosPermRequested = 'fitup_ios_notif_perm_requested';

  /// Spec alias for [init].
  Future<void> initialize() => init();

  /// Call once after app start (skipped on web).
  Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    if (_initialized) {
      return;
    }
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: ios,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_remindersChannel);
    await androidImpl?.createNotificationChannel(_medicationsChannel);

    await _requestIOSPermissionsOnFirstLaunch();

    _initialized = true;
  }

  Future<void> _requestIOSPermissionsOnFirstLaunch() async {
    if (kIsWeb) {
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kIosPermRequested) == true) {
      return;
    }
    final IOSFlutterLocalNotificationsPlugin? ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
    await prefs.setBool(_kIosPermRequested, true);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancelAll();
  }

  /// Rebuilds schedules from [settings] and profile context.
  Future<void> rescheduleAll({
    required String userId,
    required AppSettings settings,
    ActivityLevel activityLevel = ActivityLevel.moderatelyActive,
  }) async {
    if (kIsWeb) {
      return;
    }
    await init();
    await cancelAll();
    if (!settings.masterPushEnabled) {
      return;
    }

    if (settings.mealReminders) {
      await _scheduleDaily(
        id: 1001,
        hour: 8,
        minute: 0,
        title: 'Breakfast log',
        body: 'Log your morning meal in Fitup.',
      );
      await _scheduleDaily(
        id: 1002,
        hour: 13,
        minute: 0,
        title: 'Lunch log',
        body: 'Track lunch to stay on top of macros.',
      );
      await _scheduleDaily(
        id: 1003,
        hour: 20,
        minute: 0,
        title: 'Dinner log',
        body: 'Wrap up your day with dinner logging.',
      );
    }

    if (settings.hydrationReminders) {
      int hid = 2000;
      for (int h = 7; h <= 22; h += 2) {
        await _scheduleDaily(
          id: hid++,
          hour: h,
          minute: 0,
          title: 'Hydration',
          body: 'Time for a glass of water.',
        );
      }
    }

    if (settings.workoutReminders) {
      final List<int> weekdays = _workoutWeekdays(activityLevel);
      for (final int wd in weekdays) {
        await _scheduleWeekly(
          id: 3000 + wd,
          weekday: wd,
          hour: 6,
          minute: 30,
          title: 'Workout',
          body: 'Scheduled training reminder.',
          highImportance: false,
        );
      }
    }

    if (settings.sleepReminders) {
      await _scheduleDaily(
        id: 4000,
        hour: 22,
        minute: 0,
        title: 'Wind down',
        body: 'Consider a consistent sleep routine tonight.',
      );
    }

    if (settings.medicationReminders) {
      await _scheduleMedications(userId);
    }

    if (settings.aiNudges) {
      await _scheduleDaily(
        id: 6000,
        hour: 9,
        minute: 0,
        title: 'Daily briefing',
        body: 'Your AI insights may have an update.',
      );
      await _scheduleWeekly(
        id: 6001,
        weekday: DateTime.sunday,
        hour: 18,
        minute: 0,
        title: 'Weekly report',
        body: 'Review your holistic weekly summary.',
        highImportance: false,
      );
    }
  }

  List<int> _workoutWeekdays(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
      case ActivityLevel.lightlyActive:
        return <int>[DateTime.monday, DateTime.wednesday, DateTime.friday];
      case ActivityLevel.moderatelyActive:
      case ActivityLevel.veryActive:
      case ActivityLevel.extraActive:
        return <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.thursday,
          DateTime.saturday,
        ];
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final tz.TZDateTime next = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      next,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _remindersChannel.id,
          _remindersChannel.name,
          channelDescription: _remindersChannel.description,
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required bool highImportance,
  }) async {
    final tz.TZDateTime next = _nextInstanceOfWeekday(weekday, hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      next,
      NotificationDetails(
        android: AndroidNotificationDetails(
          highImportance ? _medicationsChannel.id : _remindersChannel.id,
          highImportance ? _medicationsChannel.name : _remindersChannel.name,
          channelDescription: highImportance
              ? _medicationsChannel.description
              : _remindersChannel.description,
          importance:
              highImportance ? Importance.high : Importance.low,
          priority: highImportance ? Priority.high : Priority.low,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleMedications(String userId) async {
    final result = await _healthRepository.getActiveMedications(userId);
    await result.fold(
      (Failure f) async {
        LoggerService.w('NotificationService meds', f);
      },
      (List<MedicationLog> meds) async {
        int mid = 5000;
        for (final MedicationLog m in meds) {
          final MedicationReminderTime? t = m.reminderTime;
          if (t == null || !m.isActive) {
            continue;
          }
          final tz.TZDateTime next =
              _nextInstanceOfTime(t.hour, t.minute);
          await _plugin.zonedSchedule(
            mid++,
            m.medicationName,
            'Dose: ${m.dose}',
            next,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _medicationsChannel.id,
                _medicationsChannel.name,
                channelDescription: _medicationsChannel.description,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      },
    );
  }

  /// Spec hook — forwards to [rescheduleAll].
  Future<void> scheduleReminder(NotificationReminder reminder) async {
    LoggerService.d('scheduleReminder ${reminder.kind}');
  }
}

/// Typed reminder (extensible).
enum NotificationReminderKind {
  meal,
  hydration,
  workout,
  sleep,
  medication,
  aiInsight,
}

class NotificationReminder {
  const NotificationReminder({required this.kind});

  final NotificationReminderKind kind;
}
