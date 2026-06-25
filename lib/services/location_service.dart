import 'dart:async';

import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/activity/domain/entities/activity_type.dart';
import './logger_service.dart';

/// GPS helpers and periodic sampling (every 3 seconds).
class LocationService {
  /// Request foreground location permission when needed.
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    LoggerService.i('LocationService.requestPermission status=$permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      LoggerService.i(
        'LocationService.requestPermission after requestPermission=$permission',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      LoggerService.i(
        'LocationService.requestPermission deniedForever opening app settings',
      );
      await Geolocator.openAppSettings();
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Emits a position roughly every 3 seconds while active.
  Stream<Position> trackLocation() async* {
    final bool ok = await requestPermission();
    if (!ok) {
      return;
    }
    await for (final Object? _ in Stream<Object?>.periodic(
      const Duration(seconds: 3),
    )) {
      final Position? p = await _getCurrentPositionNoPermissionCheck();
      if (p != null) {
        yield p;
      }
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final bool ok = await requestPermission();
      if (!ok) {
        return null;
      }
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Position?> _getCurrentPositionNoPermissionCheck() async {
    try {
      return Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  /// Great-circle distance in meters.
  static double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Minutes per kilometre (run / walk / swim).
  static double calculatePace(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0 || durationSeconds < 0) {
      return 0;
    }
    final double km = distanceMeters / 1000.0;
    final double minutes = durationSeconds / 60.0;
    return minutes / km;
  }

  /// Rough kcal estimate from distance and body weight (not clinical).
  static double calculateCalories(
    ActivityType type,
    double distanceMeters,
    double weightKg,
  ) {
    final double km = distanceMeters / 1000.0;
    final double factor = switch (type) {
      ActivityType.run => 1.0,
      ActivityType.walk => 0.6,
      ActivityType.cycle => 0.45,
      ActivityType.swim => 0.85,
    };
    return weightKg * km * factor;
  }
}
