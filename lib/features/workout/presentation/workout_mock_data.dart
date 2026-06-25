// Mock workout domain for Phase 4 UI until repositories are wired.

class MockExercise {
  const MockExercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.difficulty,
    required this.equipment,
    required this.sets,
    required this.targetReps,
    this.suggestedWeightKg = 20,
    this.videoUrl,
    this.caloriesPerMin = 8,
    this.description,
    this.instructions,
  });

  final String id;
  final String name;
  final List<String> muscleGroups;
  final String difficulty;
  final String equipment;
  final int sets;
  final int targetReps;
  final double suggestedWeightKg;
  final String? videoUrl;
  final int caloriesPerMin;
  final String? description;
  final List<String>? instructions;
}

/// Logged set for session / complete screen.
class MockLoggedSet {
  const MockLoggedSet({
    required this.reps,
    required this.weightKg,
  });

  final int reps;
  final double weightKg;
}

class MockSessionExerciseProgress {
  MockSessionExerciseProgress({
    required this.exercise,
    required this.loggedSets,
    this.skipped = false,
  });

  final MockExercise exercise;
  final List<MockLoggedSet> loggedSets;
  final bool skipped;
}

/// Template for an active workout session.
class MockWorkoutSessionTemplate {
  const MockWorkoutSessionTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    this.restBetweenSetsSec = 45,
  });

  final String id;
  final String name;
  final List<MockExercise> exercises;
  final int restBetweenSetsSec;
}

class MockWorkoutLog {
  const MockWorkoutLog({
    required this.id,
    required this.sessionName,
    required this.date,
    required this.duration,
    required this.calories,
    required this.exerciseLines,
  });

  final String id;
  final String sessionName;
  final DateTime date;
  final Duration duration;
  final int calories;
  final List<String> exerciseLines;
}

class MockActivePlan {
  const MockActivePlan({
    required this.id,
    required this.name,
    required this.isAiGenerated,
    required this.weekCompleted,
    required this.todayDayIndex,
    required this.sessionTemplateId,
  });

  final String id;
  final String name;
  final bool isAiGenerated;
  /// Mon–Sun, true = had a workout that day.
  final List<bool> weekCompleted;
  /// 0 = Mon … 6 = Sun
  final int todayDayIndex;
  final String sessionTemplateId;
}

class MockWeeklyStats {
  const MockWeeklyStats({
    required this.sessionsDone,
    required this.sessionsTarget,
    required this.totalMinutes,
    required this.caloriesBurned,
  });

  final int sessionsDone;
  final int sessionsTarget;
  final int totalMinutes;
  final int caloriesBurned;
}

/// Muscle id → sessions count this week (for heatmap).
typedef MuscleFrequencyMap = Map<String, int>;

final List<MockExercise> kMockExerciseLibrary = <MockExercise>[
  const MockExercise(
    id: 'ex1',
    name: 'Barbell Bench Press',
    muscleGroups: <String>['Chest', 'Arms'],
    difficulty: 'intermediate',
    equipment: 'Barbell',
    sets: 4,
    targetReps: 8,
    suggestedWeightKg: 40,
    videoUrl: 'https://www.youtube.com/watch?v=rT7DgCr-3pg',
    caloriesPerMin: 10,
    description: 'Compound pressing movement for chest and triceps.',
    instructions: <String>[
      'Lie on bench, feet flat, retract shoulder blades.',
      'Lower bar to mid-chest with control.',
      'Press up along a slight arc, lock out without losing tension.',
    ],
  ),
  const MockExercise(
    id: 'ex2',
    name: 'Pull-ups',
    muscleGroups: <String>['Back', 'Arms'],
    difficulty: 'intermediate',
    equipment: 'Pull-up Bar',
    sets: 3,
    targetReps: 8,
    suggestedWeightKg: 0,
    videoUrl: 'https://www.youtube.com/watch?v=eGo4IYlbE5g',
    caloriesPerMin: 9,
    description: 'Vertical pull for lats and biceps.',
    instructions: <String>[
      'Hang with full grip, engage lats.',
      'Pull chest toward bar, chin over if possible.',
      'Lower with control.',
    ],
  ),
  const MockExercise(
    id: 'ex3',
    name: 'Goblet Squat',
    muscleGroups: <String>['Legs', 'Core'],
    difficulty: 'beginner',
    equipment: 'Dumbbells',
    sets: 3,
    targetReps: 12,
    suggestedWeightKg: 16,
    caloriesPerMin: 8,
    description: 'Front-loaded squat pattern.',
    instructions: <String>[
      'Hold dumbbell at chest, stand tall.',
      'Sit hips back and down, knees track toes.',
      'Drive up through mid-foot.',
    ],
  ),
  const MockExercise(
    id: 'ex4',
    name: 'Plank',
    muscleGroups: <String>['Core'],
    difficulty: 'beginner',
    equipment: 'No Equipment',
    sets: 3,
    targetReps: 45,
    suggestedWeightKg: 0,
    caloriesPerMin: 5,
    description: 'Isometric core brace.',
    instructions: <String>[
      'Forearms under shoulders, body straight.',
      'Brace abs, breathe shallow.',
      'Hold without sagging hips.',
    ],
  ),
  const MockExercise(
    id: 'ex5',
    name: 'Overhead Press',
    muscleGroups: <String>['Shoulders', 'Arms'],
    difficulty: 'intermediate',
    equipment: 'Dumbbells',
    sets: 3,
    targetReps: 10,
    suggestedWeightKg: 14,
    caloriesPerMin: 7,
    description: 'Vertical press for shoulders.',
    instructions: <String>[
      'Stand tall, dumbbells at shoulders.',
      'Press up and slightly forward.',
      'Lower with control.',
    ],
  ),
];

MockWorkoutSessionTemplate kTemplatePushDay() {
  return MockWorkoutSessionTemplate(
    id: 'tpl_push',
    name: 'Push Day A',
    restBetweenSetsSec: 45,
    exercises: <MockExercise>[
      kMockExerciseLibrary[0],
      kMockExerciseLibrary[4],
      kMockExerciseLibrary[3],
    ],
  );
}

/// Previous PR by exercise id (mock).
final Map<String, double> kMockPreviousPrKg = <String, double>{
  'ex1': 38,
  'ex2': 0,
  'ex3': 14,
  'ex4': 0,
  'ex5': 12,
};

MockActivePlan? kMockActivePlan() {
  final DateTime now = DateTime.now();
  final int weekday = now.weekday;
  final int monIndex = weekday - 1;
  return MockActivePlan(
    id: 'plan1',
    name: 'Neon Strength — 4 Day',
    isAiGenerated: true,
    weekCompleted: <bool>[true, true, false, true, false, false, false],
    todayDayIndex: monIndex.clamp(0, 6),
    sessionTemplateId: 'tpl_push',
  );
}

MockWeeklyStats kMockWeeklyStats() => const MockWeeklyStats(
      sessionsDone: 3,
      sessionsTarget: 4,
      totalMinutes: 142,
      caloriesBurned: 980,
    );

MuscleFrequencyMap kMockMuscleFrequency() => <String, int>{
      'chest': 3,
      'back': 2,
      'shoulders': 2,
      'biceps': 2,
      'triceps': 3,
      'core': 4,
      'legs': 1,
      'glutes': 1,
    };

/// Passed via [GoRouterState.extra] to [WorkoutCompleteScreen].
class WorkoutCompleteArgs {
  const WorkoutCompleteArgs({
    required this.sessionName,
    required this.duration,
    required this.calories,
    required this.progress,
    required this.prLines,
    required this.fitcoins,
  });

  final String sessionName;
  final Duration duration;
  final int calories;
  final List<MockSessionExerciseProgress> progress;
  final List<String> prLines;
  final int fitcoins;
}

List<MockWorkoutLog> kMockRecentWorkouts() {
  final DateTime now = DateTime.now();
  return <MockWorkoutLog>[
    MockWorkoutLog(
      id: 'w1',
      sessionName: 'Push Day A',
      date: now.subtract(const Duration(days: 1)),
      duration: const Duration(minutes: 48),
      calories: 320,
      exerciseLines: <String>[
        'Bench Press — 4×8',
        'OHP — 3×10',
        'Plank — 3×45s',
      ],
    ),
    MockWorkoutLog(
      id: 'w2',
      sessionName: 'Pull Day B',
      date: now.subtract(const Duration(days: 3)),
      duration: const Duration(minutes: 52),
      calories: 340,
      exerciseLines: <String>[
        'Pull-ups — 3×8',
        'Rows — 3×12',
      ],
    ),
  ];
}
