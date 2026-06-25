import 'package:fitup/features/activity/domain/entities/activity_type.dart';
import 'package:fitup/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('LocationService static helpers', () {
    test('calculateDistance returns non-negative for two points', () {
      const LatLng a = LatLng(0, 0);
      const LatLng b = LatLng(0, 0.01);
      final double m = LocationService.calculateDistance(a, b);
      expect(m, greaterThan(0));
    });

    test('calculatePace returns minutes per km', () {
      final double pace = LocationService.calculatePace(1000, 360);
      expect(pace, closeTo(6.0, 0.01));
    });

    test('calculateCalories scales with distance and weight', () {
      final double c1 = LocationService.calculateCalories(
        ActivityType.walk,
        1000,
        70,
      );
      final double c2 = LocationService.calculateCalories(
        ActivityType.walk,
        2000,
        70,
      );
      expect(c2, greaterThan(c1));
    });
  });
}
