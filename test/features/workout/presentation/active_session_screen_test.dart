import 'package:dartz/dartz.dart';
import 'package:fitup/core/error/failures.dart';
import 'package:fitup/features/auth/domain/entities/fitup_user.dart';
import 'package:fitup/features/auth/presentation/providers/auth_providers.dart';
import 'package:fitup/features/workout/domain/entities/equipment.dart';
import 'package:fitup/features/workout/domain/entities/muscle_group.dart';
import 'package:fitup/features/workout/domain/entities/workout.dart';
import 'package:fitup/features/workout/domain/repositories/workout_repository.dart';
import 'package:fitup/features/workout/presentation/providers/workout_providers.dart';
import 'package:fitup/features/workout/presentation/screens/active_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockWorkoutRepo extends Mock implements WorkoutRepository {}

void main() {
  late _MockWorkoutRepo repo;
  late FitupUser user;
  late WorkoutPlan plan;

  setUpAll(() {
    registerFallbackValue('');
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

  setUp(() {
    repo = _MockWorkoutRepo();
    user = FitupUser(
      id: 'u1',
      email: 't@test.com',
      createdAt: DateTime(2025),
    );
    plan = WorkoutPlan(
      id: 'plan1',
      userId: 'u1',
      name: 'Plan',
      description: 'd',
      goals: const <String>['strength'],
      fitnessLevel: 'beginner',
      equipment: const <Equipment>[Equipment.none],
      daysPerWeek: 3,
      sessions: <WorkoutSession>[
        const WorkoutSession(
          id: 's1',
          name: 'Test session',
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
        ),
      ],
      isAIGenerated: false,
      createdAt: DateTime(2025, 1, 1),
      isActive: true,
    );
    when(() => repo.getActiveWorkoutPlan(any())).thenAnswer(
      (_) async => Right<Failure, WorkoutPlan?>(plan),
    );
    when(() => repo.saveWorkoutLog(any())).thenAnswer(
      (_) async => const Left<Failure, WorkoutLog>(ServerFailure('fail')),
    );
  });

  testWidgets(
    'ActiveSessionScreen shows retry SnackBar when last set save returns Left',
    (WidgetTester tester) async {
      final GoRouter router = GoRouter(
        initialLocation: '/workout/session/s1',
        routes: <RouteBase>[
          GoRoute(
            path: '/workout/session/:id',
            builder: (BuildContext context, GoRouterState state) =>
                ActiveSessionScreen(
              sessionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/workout/complete',
            builder: (BuildContext context, GoRouterState state) =>
                const Scaffold(body: Text('complete')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (Ref ref) => Stream<FitupUser?>.value(user),
            ),
            workoutRepositoryProvider.overrideWithValue(repo),
            personalRecordsProvider.overrideWith(
              (Ref ref) async => <PersonalRecord>[],
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark set complete'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't save"), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );
}
