import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../../activity/domain/entities/activity_stats.dart';
import '../../../activity/presentation/providers/activity_providers.dart';
import '../../../auth/domain/entities/fitup_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../diet/domain/entities/diet_summary.dart';
import '../../../diet/presentation/providers/diet_providers.dart';
import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/muscle_group.dart';
import '../../domain/entities/workout.dart';
import '../../domain/entities/workout_user_profile.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../../domain/repositories/workout_repository.dart';
import '../../domain/usecases/complete_session_usecase.dart';
import '../../domain/usecases/generate_workout_plan_usecase.dart';
import '../../domain/usecases/get_personal_records_usecase.dart';
import '../../domain/usecases/get_workout_summary_usecase.dart';
import '../../domain/usecases/log_workout_usecase.dart';

part 'workout_providers.g.dart';

/// Filter params for [exerciseLibraryProvider] (family equality).
@immutable
class ExerciseLibraryParams {
  const ExerciseLibraryParams({
    this.muscleGroup,
    this.equipment,
    this.difficulty,
    this.limit = 50,
  });

  final MuscleGroup? muscleGroup;
  final Equipment? equipment;
  final DifficultyLevel? difficulty;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is ExerciseLibraryParams &&
        other.muscleGroup == muscleGroup &&
        other.equipment == equipment &&
        other.difficulty == difficulty &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(muscleGroup, equipment, difficulty, limit);
}

@immutable
class WorkoutLogRange {
  const WorkoutLogRange({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) {
    return other is WorkoutLogRange && other.from == from && other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}

@riverpod
WorkoutRepository workoutRepository(Ref ref) => getIt<WorkoutRepository>();

@riverpod
ExerciseRepository exerciseRepository(Ref ref) =>
    getIt<ExerciseRepository>();

@riverpod
GenerateWorkoutPlanUseCase generateWorkoutPlanUseCase(Ref ref) =>
    getIt<GenerateWorkoutPlanUseCase>();

/// Pulls latest exercise data (including video URLs) from Firestore.
/// Invalidates [exerciseLibraryProvider] on success so the UI picks up changes.
@riverpod
Future<int> refreshExerciseLibrary(Ref ref) async {
  final Either<Failure, int> r =
      await ref.read(exerciseRepositoryProvider).refreshExercisesFromRemote();
  return r.fold(
    (Failure f) => 0,
    (int count) => count,
  );
}

@riverpod
Future<List<Exercise>> exerciseLibrary(
  Ref ref,
  ExerciseLibraryParams params,
) async {
  final Either<Failure, List<Exercise>> r =
      await ref.read(exerciseRepositoryProvider).getExercises(
            muscleGroup: params.muscleGroup,
            equipment: params.equipment,
            difficulty: params.difficulty,
            limit: params.limit,
          );
  return r.fold(
    (Failure f) => throw f,
    (List<Exercise> list) => list,
  );
}

@riverpod
Future<Exercise?> exerciseById(
  Ref ref,
  String id,
) async {
  final Either<Failure, Exercise?> r =
      await ref.read(exerciseRepositoryProvider).getExerciseById(id);
  return r.fold(
    (Failure f) => throw f,
    (Exercise? e) => e,
  );
}

@riverpod
Future<List<Exercise>> exerciseSearch(
  Ref ref,
  String query,
) async {
  final String q = query.trim();
  if (q.isEmpty) {
    return <Exercise>[];
  }
  final Either<Failure, List<Exercise>> r =
      await ref.read(exerciseRepositoryProvider).searchExercises(q);
  return r.fold(
    (Failure f) => throw f,
    (List<Exercise> list) => list,
  );
}

@riverpod
Future<WorkoutPlan?> activeWorkoutPlan(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return null;
  }
  final Either<Failure, WorkoutPlan?> r =
      await ref.read(workoutRepositoryProvider).getActiveWorkoutPlan(user.id);
  return r.fold(
    (Failure f) => throw f,
    (WorkoutPlan? p) => p,
  );
}

@riverpod
Future<List<WorkoutLog>> workoutLogs(
  Ref ref,
  WorkoutLogRange range,
) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <WorkoutLog>[];
  }
  final Either<Failure, List<WorkoutLog>> r =
      await ref.read(workoutRepositoryProvider).getWorkoutLogs(
            user.id,
            dateFrom: range.from,
            dateTo: range.to,
          );
  return r.fold(
    (Failure f) => throw f,
    (List<WorkoutLog> list) => list,
  );
}

@riverpod
Future<WorkoutSummary> workoutSummary(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    throw const AuthFailure('Not signed in');
  }
  final Either<Failure, WorkoutSummary> r =
      await GetWorkoutSummaryUseCase(ref.read(workoutRepositoryProvider))
          .call(user.id);
  return r.fold(
    (Failure f) => throw f,
    (WorkoutSummary s) => s,
  );
}

@riverpod
Future<List<PersonalRecord>> personalRecords(Ref ref) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return <PersonalRecord>[];
  }
  final Either<Failure, List<PersonalRecord>> r =
      await GetPersonalRecordsUseCase(ref.read(workoutRepositoryProvider))
          .call(user.id);
  return r.fold(
    (Failure f) => throw f,
    (List<PersonalRecord> list) => list,
  );
}

@riverpod
Future<List<WorkoutLog>> recentWorkouts(Ref ref) async {
  final List<WorkoutLog> all = await ref.watch(
    workoutLogsProvider(const WorkoutLogRange()).future,
  );
  return all.take(10).toList();
}

/// Today's total calories burnt from all workout logs.
@riverpod
Future<double> todayCaloriesBurnt(Ref ref) async {
  final DateTime now = DateTime.now();
  final DateTime todayStart = DateTime(now.year, now.month, now.day);
  final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));
  final List<WorkoutLog> logs = await ref.watch(
    workoutLogsProvider(const WorkoutLogRange()).future,
  );
  double total = 0;
  for (final WorkoutLog l in logs) {
    if (!l.startTime.isBefore(todayStart) && l.startTime.isBefore(tomorrowStart)) {
      total += l.totalCaloriesBurnt;
    }
  }
  return total;
}

@riverpod
Future<Map<MuscleGroup, int>> muscleGroupFrequency(
  Ref ref,
) async {
  final WorkoutSummary s = await ref.watch(workoutSummaryProvider.future);
  return s.muscleGroupFrequency;
}

@riverpod
Future<String> workoutInsight(
  Ref ref,
  List<String> recentLogIds,
) async {
  final AsyncValue<FitupUser?> auth = ref.watch(authStateProvider);
  final FitupUser? user = auth.maybeWhen(
    data: (FitupUser? u) => u,
    orElse: () => null,
  );
  if (user == null) {
    return 'Sign in for workout insights.';
  }
  final List<WorkoutLog> logs = await ref.watch(
    workoutLogsProvider(const WorkoutLogRange()).future,
  );
  final List<WorkoutLog> recent = logs
      .where((WorkoutLog l) => recentLogIds.contains(l.id))
      .toList();
  final WorkoutSummary summary = await ref.watch(workoutSummaryProvider.future);
  final Either<Failure, ActivityStats> act = await ref
      .read(activityRepositoryProvider)
      .getStats(
        user.id,
        DateTime.now().subtract(const Duration(days: 7)),
        DateTime.now(),
      );
  final ActivityStats? stats = act.fold((_) => null, (ActivityStats s) => s);
  DietSummary? diet;
  try {
    diet = await ref.watch(dailySummaryProvider.future);
  } catch (_) {
    diet = null;
  }
  Map<String, DietSummary>? weeklyNutrition;
  try {
    weeklyNutrition = await ref.watch(weeklyNutritionProvider.future);
  } catch (_) {
    weeklyNutrition = null;
  }
  final WorkoutPlan? plan = await ref.watch(activeWorkoutPlanProvider.future);
  return ref.read(aiServiceProvider).getWorkoutInsight(
        recentLogs: recent.isEmpty ? logs.take(8).toList() : recent,
        summary: summary,
        activityData: stats,
        dietData: diet,
        weeklyNutrition: weeklyNutrition,
        activePlanGoals: plan?.goals,
      );
}

@riverpod
class GeneratePlanNotifier extends _$GeneratePlanNotifier {
  @override
  FutureOr<void> build() async {}

  Future<Either<Failure, WorkoutPlan>> generate({
    required WorkoutUserProfile profile,
    required List<String> goals,
    required List<Equipment> equipment,
    required String fitnessLevel,
    required int daysPerWeek,
  }) async {
    return ref.read(generateWorkoutPlanUseCaseProvider).call(
          profile: profile,
          goals: goals,
          equipment: equipment,
          fitnessLevel: fitnessLevel,
          daysPerWeek: daysPerWeek,
        );
  }
}

/// Live session: elapsed timer pauses during rest; [ref.onDispose] cancels timers.
@riverpod
class ActiveSessionNotifier extends _$ActiveSessionNotifier {
  Timer? _elapsedTimer;
  Timer? _restTimer;

  @override
  ActiveSessionState build() {
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _restTimer?.cancel();
    });
    return const ActiveSessionState();
  }

  void beginSession(WorkoutSession session, String userId) {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = ActiveSessionState(
      session: session,
      userId: userId,
      exerciseIndex: 0,
      currentSet: 1,
      elapsedSeconds: 0,
      restSecondsRemaining: 0,
      isResting: false,
      completedSets: const <CompletedSet>[],
      sessionStartTime: DateTime.now(),
      finished: false,
      sessionEnded: false,
      saveError: null,
    );
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final ActiveSessionState s = state;
      if (s.session == null ||
          s.isResting ||
          s.finished ||
          s.sessionEnded) {
        return;
      }
      state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
    });
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    state = state.copyWith(isResting: true, restSecondsRemaining: seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final int next = state.restSecondsRemaining - 1;
      if (next <= 0) {
        _restTimer?.cancel();
        state = state.copyWith(isResting: false, restSecondsRemaining: 0);
      } else {
        state = state.copyWith(restSecondsRemaining: next);
      }
    });
  }

  void skipRest() {
    _restTimer?.cancel();
    state = state.copyWith(isResting: false, restSecondsRemaining: 0);
  }

  /// Logs one set for the current exercise; detects PR vs [personalRecordsProvider].
  /// Returns a [WorkoutLog] when the session was auto-finished (last set of last exercise).
  Future<WorkoutLog?> completeSet({
    required int reps,
    required double weightKg,
  }) async {
    final WorkoutSession? session = state.session;
    if (session == null ||
        state.finished ||
        state.sessionEnded ||
        state.isResting) {
      return null;
    }
    final SessionExercise ex = session.exercises[state.exerciseIndex];
    final List<CompletedSet> forEx = state.completedSets
        .where((CompletedSet c) => c.exerciseId == ex.exerciseId)
        .toList();
    final int setNumber = forEx.length + 1;
    final List<PersonalRecord> prs =
        await ref.read(personalRecordsProvider.future);
    double? prevBest;
    for (final PersonalRecord p in prs) {
      if (p.exerciseId == ex.exerciseId && p.maxWeightKg != null) {
        prevBest = p.maxWeightKg;
        break;
      }
    }
    final bool isPr =
        weightKg > 0 && (prevBest == null || weightKg > prevBest);
    final CompletedSet done = CompletedSet(
      exerciseId: ex.exerciseId,
      exerciseName: ex.exerciseName,
      setNumber: setNumber,
      reps: reps,
      weightKg: weightKg,
      isPersonalRecord: isPr,
    );
    final List<CompletedSet> nextSets = <CompletedSet>[
      ...state.completedSets,
      done,
    ];
    final bool exerciseDone = setNumber >= ex.sets;
    final bool lastExercise =
        state.exerciseIndex >= session.exercises.length - 1;

    if (exerciseDone && lastExercise) {
      _elapsedTimer?.cancel();
      _restTimer?.cancel();
      state = state.copyWith(
        completedSets: nextSets,
        isResting: false,
        restSecondsRemaining: 0,
        saveError: null,
      );
      final Either<Failure, WorkoutLog> result = await finishSession();
      return result.fold(
        (Failure f) {
          if (f is FitcoinUpdateFailure) {
            state = state.copyWith(saveError: f, sessionEnded: true);
            final String? userId = state.userId;
            final DateTime? startTime = state.sessionStartTime;
            if (userId == null || startTime == null) {
              return null;
            }
            final String id = f.savedWorkoutLogId;
            final List<String> parts = id.split('_w_');
            final int? endMillis = parts.isNotEmpty
                ? int.tryParse(parts.last)
                : int.tryParse(id);
            final DateTime endTime = endMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(endMillis)
                : DateTime.now();
            final double cal = (state.elapsedSeconds / 60 * 8)
                .clamp(40, 9999)
                .toDouble();
            return WorkoutLog(
              id: id,
              userId: userId,
              sessionId: session.id,
              sessionName: session.name,
              startTime: startTime,
              endTime: endTime,
              completedSets: state.completedSets,
              totalCaloriesBurnt: cal,
            );
          }
          state = state.copyWith(saveError: f, sessionEnded: true);
          return null;
        },
        (WorkoutLog l) {
          state = state.copyWith(
            finished: true,
            saveError: null,
            sessionEnded: false,
          );
          return l;
        },
      );
    }

    if (exerciseDone) {
      state = state.copyWith(
        completedSets: nextSets,
        exerciseIndex: state.exerciseIndex + 1,
        currentSet: 1,
        isResting: false,
        restSecondsRemaining: 0,
      );
      _startRest(ex.restSeconds);
      return null;
    }

    state = state.copyWith(
      completedSets: nextSets,
      currentSet: setNumber + 1,
      isResting: false,
      restSecondsRemaining: 0,
    );
    _startRest(ex.restSeconds);
    return null;
  }

  void goToExercise(int index) {
    final WorkoutSession? session = state.session;
    if (session == null ||
        state.finished ||
        state.sessionEnded ||
        index < 0 ||
        index >= session.exercises.length) {
      return;
    }
    _restTimer?.cancel();
    state = state.copyWith(
      exerciseIndex: index,
      currentSet: 1,
      isResting: false,
      restSecondsRemaining: 0,
    );
  }

  void skipCurrentExercise() {
    final WorkoutSession? session = state.session;
    if (session == null || state.finished || state.sessionEnded) {
      return;
    }
    final int nextIdx = state.exerciseIndex + 1;
    if (nextIdx >= session.exercises.length) {
      finishEarly();
      return;
    }
    _restTimer?.cancel();
    state = state.copyWith(
      exerciseIndex: nextIdx,
      currentSet: 1,
      isResting: false,
      restSecondsRemaining: 0,
    );
  }

  void finishEarly() {
    if (state.session == null || state.finished || state.sessionEnded) {
      return;
    }
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = state.copyWith(
      sessionEnded: true,
      isResting: false,
      restSecondsRemaining: 0,
    );
  }

  void reset() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = const ActiveSessionState();
  }

  /// Builds a [WorkoutLog] and persists via [CompleteSessionUseCase].
  Future<Either<Failure, WorkoutLog>> finishSession() async {
    final WorkoutSession? session = state.session;
    final String? userId = state.userId;
    final DateTime? start = state.sessionStartTime;
    if (session == null || userId == null || start == null) {
      return const Left<Failure, WorkoutLog>(
        UnexpectedFailure('No active session'),
      );
    }
    if (state.completedSets.isEmpty) {
      return const Left<Failure, WorkoutLog>(
        UnexpectedFailure('Log at least one set'),
      );
    }
    final DateTime end = DateTime.now();
    final double cal =
        (state.elapsedSeconds / 60 * 8).clamp(40, 9999).toDouble();
    final WorkoutLog draft = WorkoutLog(
      id: '${userId}_w_${end.millisecondsSinceEpoch}',
      userId: userId,
      sessionId: session.id,
      sessionName: session.name,
      startTime: start,
      endTime: end,
      completedSets: state.completedSets,
      totalCaloriesBurnt: cal,
    );
    final Either<Failure, WorkoutLog> r =
        await ref.read(workoutLoggerProvider.notifier).completeSession(
              draft,
            );
    return r;
  }

  /// Clears [saveError] and retries persisting the current session.
  Future<Either<Failure, WorkoutLog>> retrySave() async {
    state = state.copyWith(clearSaveError: true);
    return finishSession();
  }
}

@immutable
class ActiveSessionState {
  const ActiveSessionState({
    this.session,
    this.userId,
    this.exerciseIndex = 0,
    this.currentSet = 1,
    this.elapsedSeconds = 0,
    this.restSecondsRemaining = 0,
    this.isResting = false,
    this.completedSets = const <CompletedSet>[],
    this.sessionStartTime,
    this.finished = false,
    this.sessionEnded = false,
    this.saveError,
  });

  final WorkoutSession? session;
  final String? userId;
  final int exerciseIndex;
  final int currentSet;
  final int elapsedSeconds;
  final int restSecondsRemaining;
  final bool isResting;
  final List<CompletedSet> completedSets;
  final DateTime? sessionStartTime;
  final bool finished;

  /// True after user ends early / last-set save failed (non-FTC); blocks new sets.
  final bool sessionEnded;

  /// Set when [finishSession] returned Left; clear on success or [retrySave].
  final Failure? saveError;

  SessionExercise? get currentExercise {
    final WorkoutSession? s = session;
    if (s == null || exerciseIndex >= s.exercises.length) {
      return null;
    }
    return s.exercises[exerciseIndex];
  }

  ActiveSessionState copyWith({
    WorkoutSession? session,
    String? userId,
    int? exerciseIndex,
    int? currentSet,
    int? elapsedSeconds,
    int? restSecondsRemaining,
    bool? isResting,
    List<CompletedSet>? completedSets,
    DateTime? sessionStartTime,
    bool? finished,
    bool? sessionEnded,
    Failure? saveError,
    bool clearSaveError = false,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      userId: userId ?? this.userId,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      currentSet: currentSet ?? this.currentSet,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      restSecondsRemaining:
          restSecondsRemaining ?? this.restSecondsRemaining,
      isResting: isResting ?? this.isResting,
      completedSets: completedSets ?? this.completedSets,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      finished: finished ?? this.finished,
      sessionEnded: sessionEnded ?? this.sessionEnded,
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

@riverpod
class WorkoutLoggerNotifier extends _$WorkoutLoggerNotifier {
  @override
  FutureOr<void> build() async {}

  Future<Either<Failure, WorkoutLog>> saveLog(WorkoutLog log) async {
    return LogWorkoutUseCase(ref.read(workoutRepositoryProvider)).call(log);
  }

  Future<Either<Failure, WorkoutLog>> completeSession(WorkoutLog draft) async {
    final Either<Failure, WorkoutLog> r =
        await CompleteSessionUseCase(ref.read(workoutRepositoryProvider))(
      draft,
    );
    r.fold(
      (Failure f) {
        if (f is FitcoinUpdateFailure) {
          ref.invalidate(workoutSummaryProvider);
          ref.invalidate(personalRecordsProvider);
          ref.invalidate(workoutLogsProvider(const WorkoutLogRange()));
          ref.invalidate(todayCaloriesBurntProvider);
        }
      },
      (_) {
        ref.invalidate(workoutSummaryProvider);
        ref.invalidate(personalRecordsProvider);
        ref.invalidate(workoutLogsProvider(const WorkoutLogRange()));
        ref.invalidate(todayCaloriesBurntProvider);
      },
    );
    return r;
  }
}
