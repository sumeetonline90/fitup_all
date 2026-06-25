import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/workout/data/datasources/in_memory_workout_local_datasource.dart';
import 'package:fitup/features/workout/data/datasources/workout_remote_datasource.dart';
import 'package:fitup/features/workout/data/models/workout_model.dart';
import 'package:fitup/features/workout/data/repositories/firebase_workout_repository.dart';
import 'package:fitup/features/workout/domain/entities/equipment.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements WorkoutRemoteDatasource {}

WorkoutPlanModel _dummyPlanModel() {
  return WorkoutPlanModel(
    id: 'f',
    userId: 'u',
    name: 'n',
    description: 'd',
    goals: const <String>[],
    fitnessLevel: 'beginner',
    equipment: const <String>['none'],
    daysPerWeek: 1,
    sessions: const <WorkoutSessionModel>[],
    isAIGenerated: false,
    createdAt: DateTime(2020),
    isActive: false,
  );
}

WorkoutLogModel _dummyLogModel() {
  return WorkoutLogModel(
    id: 'f',
    userId: 'u',
    sessionId: 's',
    sessionName: 'n',
    startTime: DateTime(2020),
    endTime: DateTime(2020, 1, 1, 1),
    completedSets: const <CompletedSetModel>[],
    totalCaloriesBurnt: 0,
    fitcoinsEarned: 0,
  );
}

void main() {
  late FakeFirebaseFirestore firestore;
  late InMemoryWorkoutLocalDatasource local;

  setUpAll(() {
    registerFallbackValue(_dummyPlanModel());
    registerFallbackValue(_dummyLogModel());
  });

  setUp(() {
    firestore = FakeFirebaseFirestore();
    local = InMemoryWorkoutLocalDatasource();
  });

  test('saveWorkoutPlan writes document', () async {
    final WorkoutRemoteDatasource remote = WorkoutRemoteDatasource(firestore);
    final FirebaseWorkoutRepository repo =
        FirebaseWorkoutRepository(firestore, remote, local);
    final WorkoutPlan plan = WorkoutPlan(
      id: 'p1',
      userId: 'u1',
      name: 'Test',
      description: 'd',
      goals: const <String>['strength'],
      fitnessLevel: 'beginner',
      equipment: const <Equipment>[Equipment.none],
      daysPerWeek: 3,
      sessions: const <WorkoutSession>[],
      isAIGenerated: false,
      createdAt: DateTime(2025, 1, 1),
      isActive: false,
    );
    final result = await repo.saveWorkoutPlan(plan);
    expect(result.isRight(), isTrue);
    final DocumentSnapshot<Map<String, dynamic>> doc = await firestore
        .collection('users')
        .doc('u1')
        .collection('workout_plans')
        .doc('p1')
        .get();
    expect(doc.exists, isTrue);
  });

  test('saveWorkoutPlan returns Left(ServerFailure) when remote throws', () async {
    final _MockRemote remote = _MockRemote();
    final FirebaseWorkoutRepository repo =
        FirebaseWorkoutRepository(firestore, remote, local);
    when(() => remote.setWorkoutPlan(any(), any())).thenThrow(
      FirebaseException(plugin: 'test', message: 'forced'),
    );
    final WorkoutPlan plan = WorkoutPlan(
      id: 'p2',
      userId: 'u1',
      name: 'T',
      description: 'd',
      goals: const <String>[],
      fitnessLevel: 'beginner',
      equipment: const <Equipment>[Equipment.none],
      daysPerWeek: 2,
      sessions: const <WorkoutSession>[],
      createdAt: DateTime(2025, 1, 1),
    );
    final result = await repo.saveWorkoutPlan(plan);
    expect(result.isLeft(), isTrue);
    result.fold(
      (Failure f) => expect(f, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });

  test(
      'saveWorkoutLog returns Left(FitcoinUpdateFailure) when Fitcoin increment throws',
      () async {
    final WorkoutRemoteDatasource remote = WorkoutRemoteDatasource(firestore);
    final FirebaseWorkoutRepository repo = FirebaseWorkoutRepository(
      firestore,
      remote,
      local,
      fitcoinIncrement: (_, __) async => throw FirebaseException(
        plugin: 'test',
        message: 'increment failed',
      ),
    );
    final WorkoutLog log = WorkoutLog(
      id: 'l1',
      userId: 'u1',
      sessionId: 's1',
      sessionName: 'Legs',
      startTime: DateTime(2025, 1, 1, 10),
      endTime: DateTime(2025, 1, 1, 11),
      completedSets: const <CompletedSet>[],
      totalCaloriesBurnt: 100,
      fitcoinsEarned: 15,
    );
    final result = await repo.saveWorkoutLog(log);
    expect(result.isLeft(), isTrue);
    result.fold(
      (Failure f) {
        expect(f, isA<FitcoinUpdateFailure>());
        final FitcoinUpdateFailure ft = f as FitcoinUpdateFailure;
        expect(ft.savedWorkoutLogId, log.id);
      },
      (_) => fail('expected Left'),
    );
  });

  test('saveWorkoutLog returns Left when Firestore set fails', () async {
    final _MockRemote remote = _MockRemote();
    final FirebaseWorkoutRepository repo =
        FirebaseWorkoutRepository(firestore, remote, local);
    when(() => remote.setWorkoutLog(any(), any())).thenThrow(
      FirebaseException(plugin: 'test', message: 'fail log'),
    );
    final WorkoutLog log = WorkoutLog(
      id: 'l1',
      userId: 'u1',
      sessionId: 's1',
      sessionName: 'Legs',
      startTime: DateTime(2025, 1, 1, 10),
      endTime: DateTime(2025, 1, 1, 11),
      completedSets: const <CompletedSet>[],
      totalCaloriesBurnt: 100,
    );
    final result = await repo.saveWorkoutLog(log);
    expect(result.isLeft(), isTrue);
  });

  test('getPersonalRecords returns merged list', () async {
    final PersonalRecord pr = PersonalRecord(
      userId: 'u1',
      exerciseId: 'ex1',
      exerciseName: 'Squat',
      maxWeightKg: 80,
      maxReps: 5,
      achievedAt: DateTime(2025, 2, 1),
    );
    await firestore
        .collection('users')
        .doc('u1')
        .collection('personal_records')
        .doc('ex1')
        .set(PersonalRecordModel.fromEntity(pr).toJson());
    final WorkoutRemoteDatasource remote = WorkoutRemoteDatasource(firestore);
    final FirebaseWorkoutRepository repo =
        FirebaseWorkoutRepository(firestore, remote, local);
    final result = await repo.getPersonalRecords('u1');
    expect(result.isRight(), isTrue);
    result.fold(
      (_) => fail('expected Right'),
      (List<PersonalRecord> list) => expect(list.length, 1),
    );
  });
}
