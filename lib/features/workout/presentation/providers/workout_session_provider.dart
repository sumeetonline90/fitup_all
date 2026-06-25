import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../workout_mock_data.dart';

part 'workout_session_provider.g.dart';

/// Running workout: elapsed time, exercise index, rest countdown, logs.
class ActiveWorkoutState {
  const ActiveWorkoutState({
    required this.template,
    required this.elapsedSeconds,
    required this.exerciseIndex,
    required this.isResting,
    required this.restSecondsLeft,
    required this.progress,
    required this.lastSetWasPr,
    this.prExerciseId,
    this.finished = false,
  });

  final MockWorkoutSessionTemplate template;
  final int elapsedSeconds;
  final int exerciseIndex;
  final bool isResting;
  final int restSecondsLeft;
  final List<MockSessionExerciseProgress> progress;
  final bool lastSetWasPr;
  final String? prExerciseId;
  final bool finished;

  MockExercise get currentExercise => template.exercises[exerciseIndex];

  /// 1-based current set number for this exercise.
  int get currentSetNumber {
    final int logged = progress[exerciseIndex].loggedSets.length;
    return logged + 1;
  }

  int get totalSetsLogged {
    int n = 0;
    for (final MockSessionExerciseProgress p in progress) {
      n += p.loggedSets.length;
    }
    return n;
  }

  ActiveWorkoutState copyWith({
    int? elapsedSeconds,
    int? exerciseIndex,
    bool? isResting,
    int? restSecondsLeft,
    List<MockSessionExerciseProgress>? progress,
    bool? lastSetWasPr,
    String? prExerciseId,
    bool? finished,
  }) {
    return ActiveWorkoutState(
      template: template,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      isResting: isResting ?? this.isResting,
      restSecondsLeft: restSecondsLeft ?? this.restSecondsLeft,
      progress: progress ?? this.progress,
      lastSetWasPr: lastSetWasPr ?? this.lastSetWasPr,
      prExerciseId: prExerciseId ?? this.prExerciseId,
      finished: finished ?? this.finished,
    );
  }
}

@riverpod
class ActiveWorkout extends _$ActiveWorkout {
  Timer? _elapsedTimer;
  Timer? _restTimer;

  @override
  ActiveWorkoutState? build() {
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _restTimer?.cancel();
    });
    return null;
  }

  void startSession(MockWorkoutSessionTemplate template) {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = ActiveWorkoutState(
      template: template,
      elapsedSeconds: 0,
      exerciseIndex: 0,
      isResting: false,
      restSecondsLeft: 0,
      progress: template.exercises
          .map(
            (MockExercise e) => MockSessionExerciseProgress(
              exercise: e,
              loggedSets: <MockLoggedSet>[],
            ),
          )
          .toList(),
      lastSetWasPr: false,
      prExerciseId: null,
      finished: false,
    );
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final ActiveWorkoutState? s = state;
      if (s == null || s.isResting || s.finished) {
        return;
      }
      state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
    });
  }

  void disposeSession() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _elapsedTimer = null;
    _restTimer = null;
    state = null;
  }

  void skipRest() {
    final ActiveWorkoutState? s = state;
    if (s == null || !s.isResting) {
      return;
    }
    _restTimer?.cancel();
    state = s.copyWith(isResting: false, restSecondsLeft: 0);
  }

  void _startRestTimer(ActiveWorkoutState s) {
    _restTimer?.cancel();
    state = s.copyWith(isResting: true, restSecondsLeft: s.template.restBetweenSetsSec);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final ActiveWorkoutState? st = state;
      if (st == null || !st.isResting) {
        _restTimer?.cancel();
        return;
      }
      if (st.restSecondsLeft <= 1) {
        _restTimer?.cancel();
        state = st.copyWith(isResting: false, restSecondsLeft: 0);
        return;
      }
      state = st.copyWith(restSecondsLeft: st.restSecondsLeft - 1);
    });
  }

  void completeSet({
    required int reps,
    required double weightKg,
  }) {
    final ActiveWorkoutState? s = state;
    if (s == null || s.isResting || s.finished) {
      return;
    }
    final MockExercise ex = s.currentExercise;
    final List<MockSessionExerciseProgress> nextProgress =
        List<MockSessionExerciseProgress>.from(s.progress);
    final MockSessionExerciseProgress cur = nextProgress[s.exerciseIndex];
    nextProgress[s.exerciseIndex] = MockSessionExerciseProgress(
      exercise: cur.exercise,
      loggedSets: <MockLoggedSet>[
        ...cur.loggedSets,
        MockLoggedSet(reps: reps, weightKg: weightKg),
      ],
    );

    final double? prev = kMockPreviousPrKg[ex.id];
    final bool isPr = weightKg > (prev ?? 0);

    final int setsDone = nextProgress[s.exerciseIndex].loggedSets.length;
    final bool exerciseComplete = setsDone >= ex.sets;
    final bool lastExercise =
        s.exerciseIndex >= s.template.exercises.length - 1;

    if (exerciseComplete && lastExercise) {
      _elapsedTimer?.cancel();
      _restTimer?.cancel();
      state = s.copyWith(
        progress: nextProgress,
        lastSetWasPr: isPr,
        prExerciseId: isPr ? ex.id : null,
        finished: true,
        isResting: false,
        restSecondsLeft: 0,
      );
      return;
    }

    if (exerciseComplete) {
      final int nextEx = s.exerciseIndex + 1;
      state = s.copyWith(
        progress: nextProgress,
        exerciseIndex: nextEx,
        lastSetWasPr: isPr,
        prExerciseId: isPr ? ex.id : null,
        isResting: false,
        restSecondsLeft: 0,
      );
      _startRestTimer(state!);
      return;
    }

    state = s.copyWith(
      progress: nextProgress,
      lastSetWasPr: isPr,
      prExerciseId: isPr ? ex.id : null,
      isResting: false,
      restSecondsLeft: 0,
    );
    _startRestTimer(state!);
  }

  void goToExercise(int index) {
    final ActiveWorkoutState? s = state;
    if (s == null || s.finished) {
      return;
    }
    if (index < 0 || index >= s.template.exercises.length) {
      return;
    }
    _restTimer?.cancel();
    state = s.copyWith(
      exerciseIndex: index,
      isResting: false,
      restSecondsLeft: 0,
    );
  }

  void skipExercise() {
    final ActiveWorkoutState? s = state;
    if (s == null || s.finished) {
      return;
    }
    final int next = s.exerciseIndex + 1;
    if (next >= s.template.exercises.length) {
      _elapsedTimer?.cancel();
      state = s.copyWith(finished: true, isResting: false);
      return;
    }
    _restTimer?.cancel();
    state = s.copyWith(
      exerciseIndex: next,
      isResting: false,
      restSecondsLeft: 0,
    );
  }

  void clearPrFlag() {
    final ActiveWorkoutState? s = state;
    if (s == null) {
      return;
    }
    state = s.copyWith(lastSetWasPr: false, prExerciseId: null);
  }

  /// Ends session early (user confirmed) and marks [finished].
  void finishEarly() {
    final ActiveWorkoutState? s = state;
    if (s == null || s.finished) {
      return;
    }
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    state = s.copyWith(finished: true, isResting: false, restSecondsLeft: 0);
  }
}
