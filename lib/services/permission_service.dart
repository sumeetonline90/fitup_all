import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/health_connect_service.dart';
import './logger_service.dart';
import 'location_service.dart';

/// Aggregate state for critical permissions required for core features.
class AppPermissionState {
  const AppPermissionState({
    required this.locationGranted,
    required this.healthGranted,
    required this.notificationGranted,
  });

  final bool locationGranted;
  final bool healthGranted;
  final bool notificationGranted;
}

/// Centralized permission orchestration used for first-launch onboarding.
class PermissionService {
  PermissionService(
    this._healthService,
    this._locationService, {
    NotificationPermissionAdapter? notificationPermission,
  }) : _notificationPermission =
            notificationPermission ?? NotificationPermissionAdapter();

  final HealthConnectService _healthService;
  final LocationService _locationService;
  final NotificationPermissionAdapter _notificationPermission;

  Future<LocationPermission> checkLocationPermission() async {
    return Geolocator.checkPermission();
  }

  Future<bool> checkHealthPermissions() async {
    if (kIsWeb) {
      return false;
    }
    return await _healthService.hasPermissions();
  }

  Future<bool> requestLocation() async {
    LoggerService.i('PermissionService.requestLocation');
    final bool ok = await _locationService.requestPermission();
    LoggerService.i('PermissionService.requestLocation ok=$ok');
    return ok;
  }

  Future<bool> requestHealthPermissions() async {
    if (kIsWeb) {
      return false;
    }
    LoggerService.i('PermissionService.requestHealthPermissions');
    final bool ok = await _healthService.requestPermissions();
    LoggerService.i('PermissionService.requestHealthPermissions ok=$ok');
    return ok;
  }

  Future<bool> requestNotifications() async {
    if (kIsWeb) {
      return false;
    }
    LoggerService.i('PermissionService.requestNotifications');
    await _notificationPermission.request();
    final bool ok = await _checkNotificationPermission();
    LoggerService.i('PermissionService.requestNotifications ok=$ok');
    return ok;
  }

  Future<bool> _checkNotificationPermission() async {
    if (kIsWeb) {
      return false;
    }
    final PermissionStatus status = await _notificationPermission.status();
    return status.isGranted;
  }

  /// Check if all critical permissions are granted.
  Future<AppPermissionState> getPermissionState() async {
    final LocationPermission location = await checkLocationPermission();
    final bool healthGranted = await checkHealthPermissions();
    LoggerService.i(
      'PermissionService.getPermissionState location=$location healthGranted=$healthGranted',
    );
    return AppPermissionState(
      locationGranted: location == LocationPermission.always ||
          location == LocationPermission.whileInUse,
      healthGranted: healthGranted,
      notificationGranted: await _checkNotificationPermission(),
    );
  }

  /// Requests all permissions used by Fitup (location + Health data +
  /// notifications).
  Future<void> requestAll() async {
    if (kIsWeb) {
      return;
    }
    await requestLocation();
    await requestHealthPermissions();
    await _notificationPermission.request();
  }
}

/// Adapter around `permission_handler` so we can override in tests.
class NotificationPermissionAdapter {
  Future<PermissionStatus> status() => Permission.notification.status;
  Future<PermissionStatus> request() => Permission.notification.request();
}

