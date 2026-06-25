import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;

import 'logger_service.dart';

/// Wraps [FlutterForegroundTask] for GPS polling while the app is backgrounded.
class ForegroundTaskService {
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fitup_activity_tracking',
        channelName: 'Activity Tracking',
        channelDescription: 'Tracks your activity via GPS in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<bool> start() async {
    init();
    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
      notificationTitle: 'Fitup — Tracking Activity',
      notificationText: 'GPS tracking is active',
      callback: _startCallback,
    );
    LoggerService.i('ForegroundTaskService.start result=$result');
    return result is ServiceRequestSuccess;
  }

  Future<bool> stop() async {
    final ServiceRequestResult result =
        await FlutterForegroundTask.stopService();
    LoggerService.i('ForegroundTaskService.stop result=$result');
    return result is ServiceRequestSuccess;
  }

  Future<void> updateNotification({String? text}) async {
    if (text != null) {
      await FlutterForegroundTask.updateService(
        notificationText: text,
      );
    }
  }

  Future<bool> requestIgnoreBatteryOptimization() async {
    return FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_GpsTaskHandler());
}

class _GpsTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    LoggerService.i('_GpsTaskHandler.onStart');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _fetchAndSend();
  }

  Future<void> _fetchAndSend() async {
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      FlutterForegroundTask.sendDataToMain(<String, double>{
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'accuracy': pos.accuracy,
      });
    } catch (e) {
      LoggerService.e('_GpsTaskHandler._fetchAndSend', e, StackTrace.current);
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    LoggerService.i('_GpsTaskHandler.onDestroy isTimeout=$isTimeout');
  }
}
