import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/workout/domain/entities/muscle_group.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/features/workout/presentation/providers/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late _MockWorkoutRepository repo;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      WorkoutLog(
        id: 'fb',
        userId: 'u',
        sessionId: 's',
        sessionName: 'n',
        startTime: DateTime(2020),
        endTime: DateTime(2020, 1, 2),
        completedSets: const <CompletedSet>[],
        totalCaloriesBurnt: 0,
      ),
    );
  });

  const WorkoutSession session = WorkoutSession(
    id: 's1',
    name: 'S',
    exercises: <SessionExercise>[
      SessionExercise(
        exerciseId: 'e1',
        exerciseName: 'Squat',
        sets: 1,
        reps: 10,
        restSeconds: 60,
      ),
    ],
    estimatedDurationMinutes: 30,
    targetMuscleGroups: <MuscleGroup>[MuscleGroup.quadriceps],
  );

  setUp(() {
    repo = _MockWorkoutRepository();
  });

  test(
      'ActiveSessionNotifier does not set finished=true when finishSession returns Left',
      () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (_) async => const Left<Failure, WorkoutLog>(ServerFailure('fail')),
    );
    container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        personalRecordsProvider.overrideWith(
          (Ref ref) async => <PersonalRecord>[],
        ),
      ],
    );
    addTearDown(container.dispose);
    final ActiveSessionNotifier n =
        container.read(activeSessionProvider.notifier);
    n.beginSession(session, 'user1');
    final WorkoutLog? done = await n.completeSet(reps: 10, weightKg: 50);
    expect(done, isNull);
    final ActiveSessionState st = container.read(activeSessionProvider);
    expect(st.finished, isFalse);
    expect(st.saveError, isA<ServerFailure>());
    expect(st.sessionEnded, isTrue);
  });

  test('ActiveSessionNotifier sets finished=true when finishSession returns Right',
      () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer((Invocation i) async {
      final WorkoutLog l = i.positionalArguments[0] as WorkoutLog;
      return Right<Failure, WorkoutLog>(l);
    });
    container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(repo),
        personalRecordsProvider.overrideWith(
          (Ref ref) async => <PersonalRecord>[],
        ),
      ],
    );
    addTearDown(container.dispose);
    final ActiveSessionNotifier n =
        container.read(activeSessionProvider.notifier);
    n.beginSession(session, 'user1');
    final WorkoutLog? done = await n.completeSet(reps: 10, weightKg: 50);
    expect(done, isNotNull);
    final ActiveSessionState st = container.read(activeSessionProvider);
    expect(st.finished, isTrue);
    expect(st.saveError, isNull);
  });
}
