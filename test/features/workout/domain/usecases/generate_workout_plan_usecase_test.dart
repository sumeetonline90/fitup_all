import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/workout/domain/entities/difficulty_level.dart';
import 'package:fitup/features/workout/domain/entities/equipment.dart';
import 'package:fitup/features/workout/domain/entities/exercise.dart';
import 'package:fitup/features/workout/domain/entities/exercise_type.dart';
import 'package:fitup/features/workout/domain/entities/muscle_group.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/entities/workout_user_profile.dart';
import 'package:fitup/features/workout/domain/repositories/exercise_repository.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/features/workout/domain/usecases/generate_workout_plan_usecase.dart';
import 'package:fitup/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAi extends Mock implements AiService {}

class _MockWorkouts extends Mock implements WorkoutRepository {}

class _MockExercises extends Mock implements ExerciseRepository {}

void main() {
  late _MockAi ai;
  late _MockWorkouts workouts;
  late _MockExercises exercises;
  late GenerateWorkoutPlanUseCase useCase;

  const WorkoutUserProfile profile =
      WorkoutUserProfile(userId: 'u1', age: 30);

  setUpAll(() {
    registerFallbackValue(const WorkoutUserProfile(userId: 'fb'));
    registerFallbackValue(<String>[]);
    registerFallbackValue(<Equipment>[]);
    registerFallbackValue(0);
    registerFallbackValue('');
  });

  final List<Exercise> library = <Exercise>[
    const Exercise(
      id: 'e1',
      name: 'Squat',
      description: 'd',
      muscleGroups: <MuscleGroup>[MuscleGroup.quadriceps],
      equipment: <Equipment>[Equipment.none],
      difficulty: DifficultyLevel.beginner,
      type: WorkoutExerciseType.strength,
      instructions: <String>['a'],
      caloriesPerMinute: 5,
    ),
  ];

  final WorkoutPlan generatedPlan = WorkoutPlan(
    id: 'plan1',
    userId: 'u1',
    name: 'AI Plan',
    description: 'd',
    goals: const <String>['strength'],
    fitnessLevel: 'beginner',
    equipment: const <Equipment>[Equipment.none],
    daysPerWeek: 3,
    sessions: const <WorkoutSession>[],
    isAIGenerated: true,
    createdAt: DateTime(2025, 3, 1),
  );

  setUp(() {
    ai = _MockAi();
    workouts = _MockWorkouts();
    exercises = _MockExercises();
    useCase = GenerateWorkoutPlanUseCase(ai, workouts, exercises);
    registerFallbackValue(generatedPlan);
  });

  test('loads library, generates plan, saves and returns Right', () async {
    when(
      () => exercises.getExercises(limit: any(named: 'limit')),
    ).thenAnswer((_) async => Right<Failure, List<Exercise>>(library));
    when(
      () => ai.generateWorkoutPlan(
        profile: any(named: 'profile'),
        goals: any(named: 'goals'),
        equipment: any(named: 'equipment'),
        fitnessLevel: any(named: 'fitnessLevel'),
        daysPerWeek: any(named: 'daysPerWeek'),
        approvedExerciseNames: any(named: 'approvedExerciseNames'),
      ),
    ).thenAnswer((_) async => Right<Failure, WorkoutPlan>(generatedPlan));
    when(() => workouts.saveWorkoutPlan(any()))
        .thenAnswer((_) async => Right<Failure, WorkoutPlan>(generatedPlan));

    final Either<Failure, WorkoutPlan> result = await useCase(
      profile: profile,
      goals: const <String>['strength'],
      equipment: const <Equipment>[Equipment.none],
      fitnessLevel: 'beginner',
      daysPerWeek: 3,
    );

    expect(result.isRight(), isTrue);
    verify(() => workouts.saveWorkoutPlan(generatedPlan)).called(1);
  });

  test('returns Left when exercise library fails', () async {
    when(
      () => exercises.getExercises(limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => const Left<Failure, List<Exercise>>(CacheFailure('offline')),
    );

    final Either<Failure, WorkoutPlan> result = await useCase(
      profile: profile,
      goals: const <String>[],
      equipment: const <Equipment>[Equipment.none],
      fitnessLevel: 'beginner',
      daysPerWeek: 2,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => ai.generateWorkoutPlan(
          profile: any(named: 'profile'),
          goals: any(named: 'goals'),
          equipment: any(named: 'equipment'),
          fitnessLevel: any(named: 'fitnessLevel'),
          daysPerWeek: any(named: 'daysPerWeek'),
          approvedExerciseNames: any(named: 'approvedExerciseNames'),
        ));
  });

  test('returns Left when AI fails', () async {
    when(
      () => exercises.getExercises(limit: any(named: 'limit')),
    ).thenAnswer((_) async => Right<Failure, List<Exercise>>(library));
    when(
      () => ai.generateWorkoutPlan(
        profile: any(named: 'profile'),
        goals: any(named: 'goals'),
        equipment: any(named: 'equipment'),
        fitnessLevel: any(named: 'fitnessLevel'),
        daysPerWeek: any(named: 'daysPerWeek'),
        approvedExerciseNames: any(named: 'approvedExerciseNames'),
      ),
    ).thenAnswer(
      (_) async => const Left<Failure, WorkoutPlan>(AiFailure('bad')),
    );

    final Either<Failure, WorkoutPlan> result = await useCase(
      profile: profile,
      goals: const <String>[],
      equipment: const <Equipment>[Equipment.none],
      fitnessLevel: 'beginner',
      daysPerWeek: 2,
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => workouts.saveWorkoutPlan(any()));
  });

  test('returns Left when save fails', () async {
    when(
      () => exercises.getExercises(limit: any(named: 'limit')),
    ).thenAnswer((_) async => Right<Failure, List<Exercise>>(library));
    when(
      () => ai.generateWorkoutPlan(
        profile: any(named: 'profile'),
        goals: any(named: 'goals'),
        equipment: any(named: 'equipment'),
        fitnessLevel: any(named: 'fitnessLevel'),
        daysPerWeek: any(named: 'daysPerWeek'),
        approvedExerciseNames: any(named: 'approvedExerciseNames'),
      ),
    ).thenAnswer((_) async => Right<Failure, WorkoutPlan>(generatedPlan));
    when(() => workouts.saveWorkoutPlan(any())).thenAnswer(
      (_) async => const Left<Failure, WorkoutPlan>(ServerFailure('x')),
    );

    final Either<Failure, WorkoutPlan> result = await useCase(
      profile: profile,
      goals: const <String>[],
      equipment: const <Equipment>[Equipment.none],
      fitnessLevel: 'beginner',
      daysPerWeek: 2,
    );

    expect(result.isLeft(), isTrue);
  });
}
