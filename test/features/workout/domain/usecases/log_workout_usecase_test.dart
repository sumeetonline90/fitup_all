import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/features/workout/domain/usecases/log_workout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements WorkoutRepository {}

void main() {
  late _MockRepo repo;
  late LogWorkoutUseCase useCase;

  final WorkoutLog log = WorkoutLog(
    id: 'l1',
    userId: 'u1',
    sessionId: 's1',
    sessionName: 'Push',
    startTime: DateTime(2025, 1, 1, 9),
    endTime: DateTime(2025, 1, 1, 9, 45),
    completedSets: const <CompletedSet>[],
    totalCaloriesBurnt: 200,
  );

  setUp(() {
    repo = _MockRepo();
    useCase = LogWorkoutUseCase(repo);
    registerFallbackValue(log);
  });

  test('delegates to repository.saveWorkoutLog', () async {
    when(() => repo.saveWorkoutLog(any()))
        .thenAnswer((_) async => Right<Failure, WorkoutLog>(log));

    final Either<Failure, WorkoutLog> result = await useCase(log);

    expect(result.isRight(), isTrue);
    verify(() => repo.saveWorkoutLog(log)).called(1);
  });

  test('returns Left when repository fails', () async {
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (_) async => const Left<Failure, WorkoutLog>(ServerFailure('net')),
    );

    final Either<Failure, WorkoutLog> result = await useCase(log);

    expect(result.isLeft(), isTrue);
  });
}
