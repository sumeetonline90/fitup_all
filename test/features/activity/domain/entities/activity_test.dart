import 'package:fitup/features/activity/domain/entities/activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('Activity', () {
    test('copyWith preserves identity fields', () {
      const LatLng p = LatLng(12.34, 56.78);
      final Activity a = Activity(
        id: '1',
        userId: 'u',
        type: ActivityType.run,
        startTime: DateTime(2025, 1, 1),
        distanceMeters: 1000,
        durationSeconds: 600,
        caloriesBurnt: 80,
        routePoints: <LatLng>[p],
      );
      final Activity b = a.copyWith(distanceMeters: 2000);
      expect(b.distanceMeters, 2000);
      expect(b.id, '1');
      expect(b.routePoints, <LatLng>[p]);
    });
  });
}
