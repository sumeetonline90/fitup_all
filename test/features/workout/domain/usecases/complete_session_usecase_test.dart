import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/features/workout/domain/usecases/complete_session_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements WorkoutRepository {}

void main() {
  late _MockRepo repo;
  late CompleteSessionUseCase useCase;

  final WorkoutLog draft = WorkoutLog(
    id: 'l1',
    userId: 'u1',
    sessionId: 's1',
    sessionName: 'Legs',
    startTime: DateTime(2025, 1, 1, 10),
    endTime: DateTime(2025, 1, 1, 10, 30),
    completedSets: const <CompletedSet>[
      CompletedSet(
        exerciseId: 'ex1',
        exerciseName: 'Squat',
        setNumber: 1,
        reps: 8,
        weightKg: 60,
      ),
      CompletedSet(
        exerciseId: 'ex1',
        exerciseName: 'Squat',
        setNumber: 2,
        reps: 8,
        weightKg: 60,
      ),
    ],
    totalCaloriesBurnt: 150,
  );

  setUp(() {
    repo = _MockRepo();
    useCase = CompleteSessionUseCase(repo);
    registerFallbackValue(draft);
  });

  test('saveWorkoutLog receives fitcoins from default formula', () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (Invocation inv) async {
        final WorkoutLog arg = inv.positionalArguments[0] as WorkoutLog;
        expect(arg.fitcoinsEarned, greaterThan(0));
        return Right<Failure, WorkoutLog>(arg);
      },
    );

    final Either<Failure, WorkoutLog> result = await useCase(draft);

    expect(result.isRight(), isTrue);
    verify(() => repo.saveWorkoutLog(any())).called(1);
  });

  test('respects baseFitcoins override', () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (Invocation inv) async {
        final WorkoutLog arg = inv.positionalArguments[0] as WorkoutLog;
        expect(arg.fitcoinsEarned, 99);
        return Right<Failure, WorkoutLog>(arg);
      },
    );

    await useCase(draft, baseFitcoins: 99);

    verify(() => repo.saveWorkoutLog(any())).called(1);
  });

  test('returns Left when save fails', () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (_) async => const Left<Failure, WorkoutLog>(ServerFailure('x')),
    );

    final Either<Failure, WorkoutLog> result = await useCase(draft);

    expect(result.isLeft(), isTrue);
  });
}
