import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/features/activity/data/repositories/firebase_activity_repository.dart';
import 'package:fitup/features/activity/domain/entities/activity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_activity_local_datasource.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockActivityLocalDataSource local;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    local = MockActivityLocalDataSource();
    registerFallbackValue(
      Activity(
        id: 'a1',
        userId: 'u1',
        type: ActivityType.walk,
        startTime: DateTime(2025, 1, 1),
        distanceMeters: 1,
        durationSeconds: 1,
        caloriesBurnt: 1,
        routePoints: const <LatLng>[],
      ),
    );
  });

  test('saveActivity writes to Firestore and local', () async {
    when(() => local.saveActivityLocal(any(), synced: any(named: 'synced')))
        .thenAnswer((_) async {});
    when(
      () => local.enqueueSync(
        id: any(named: 'id'),
        userId: any(named: 'userId'),
        resourceType: any(named: 'resourceType'),
        payloadJson: any(named: 'payloadJson'),
      ),
    ).thenAnswer((_) async {});
    when(() => local.markActivitySynced(any())).thenAnswer((_) async {});
    when(() => local.dequeueSync(any())).thenAnswer((_) async {});

    final FirebaseActivityRepository repo =
        FirebaseActivityRepository(firestore, local);
    final Activity activity = Activity(
      id: 'act1',
      userId: 'user1',
      type: ActivityType.run,
      startTime: DateTime(2025, 6, 1, 8),
      endTime: DateTime(2025, 6, 1, 8, 30),
      distanceMeters: 5000,
      durationSeconds: 1800,
      caloriesBurnt: 300,
      routePoints: const <LatLng>[],
    );

    final result = await repo.saveActivity(activity);
    expect(result.isRight(), isTrue);

    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('user1')
        .collection('activities')
        .doc('act1')
        .get();
    expect(doc.exists, isTrue);
    expect(doc.data()?['distanceMeters'], 5000);

    verify(() => local.saveActivityLocal(activity, synced: false)).called(1);
  });

  test('getActivities reads documents from Firestore', () async {
    await firestore
        .collection('users')
        .doc('user1')
        .collection('activities')
        .doc('x1')
        .set(<String, dynamic>{
      'userId': 'user1',
      'type': 'walk',
      'startTime': Timestamp.fromDate(DateTime(2025, 1, 3)),
      'distanceMeters': 200.0,
      'durationSeconds': 120,
      'caloriesBurnt': 10.0,
      'routePoints': <Map<String, double>>[],
    });

    final FirebaseActivityRepository repo =
        FirebaseActivityRepository(firestore, local);

    final result = await repo.getActivities(
      'user1',
      from: DateTime(2025, 1, 1),
      to: DateTime(2025, 1, 31),
    );

    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (List<Activity> list) => expect(list.length, 1),
    );
  });
}
