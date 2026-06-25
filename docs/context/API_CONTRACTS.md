# API CONTRACTS
# ⚠️ AGENTS: This is the source of truth for interfaces between layers.
# Frontend Agent reads this to know what providers/data to expect.
# Backend Agent reads this to know what it must implement.
# Orchestrator updates this when interfaces are agreed upon.

---

## HOW THIS WORKS
- Backend Agent creates the interface (repository + provider)
- Orchestrator documents it here
- Frontend Agent reads here to know what data shape to expect
- If Frontend needs something different, flag it — Orchestrator resolves it

---

## AUTH MODULE

### User Entity
```dart
// lib/features/auth/domain/entities/fitup_user.dart
class FitupUser {
  final String id;            // Firebase UID
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isOnboarded;     // Has completed onboarding wizard
  final DateTime createdAt;
}
```
**Status:** ✅ Implemented

### Auth Providers (available to Frontend)
**Implemented in** `lib/features/auth/presentation/providers/auth_providers.dart`

```dart
// Repository (get_it)
final Provider<AuthRepository> authRepositoryProvider

// Auth state stream — watch as AsyncValue
final StreamProvider<FitupUser?> authStateProvider

// Auth actions — AsyncNotifier<void>
final AsyncNotifierProvider<AuthNotifier, void> authNotifierProvider

class AuthNotifier extends AsyncNotifier<void> {
  Future<void> signInWithGoogle()
  Future<void> signInWithEmail(String email, String password)
  Future<void> registerWithEmail(String email, String password, { String? displayName })
  Future<void> signOut()
}
```

**Repository** (`lib/features/auth/domain/repositories/auth_repository.dart`):
```dart
abstract class AuthRepository {
  Future<Either<Failure, FitupUser>> signInWithGoogle()
  Future<Either<Failure, FitupUser>> signInWithEmail(String email, String password)
  Future<Either<Failure, FitupUser>> registerWithEmail(String email, String password, { String? displayName })
  Future<Either<Failure, void>> signOut()
  Stream<FitupUser?> get authStateChanges
  FitupUser? get currentUser
}
```

**Status:** ✅ Implemented with the signatures above

---

## PROFILE MODULE

### UserProfile Entity
```dart
class UserProfile {
  final String userId;
  final String? name;
  final DateTime? dateOfBirth;
  final String? gender;        // 'male', 'female', 'other'
  final double? weightKg;
  final double? heightCm;
  final String? dietPreference; // 'veg', 'non-veg', 'vegan', 'keto'
  final String fitnessLevel;   // 'beginner', 'intermediate', 'expert'
  final List<String> healthGoals; // ['weight_loss', 'muscle_gain', 'holistic']
  final List<String> healthConditions;
  final String units;          // 'metric', 'imperial'
}
```
**Status:** ❌ Not implemented yet

---

## ACTIVITY MODULE

### Activity Entity
**Implemented in** `lib/features/activity/domain/entities/activity.dart` (Freezed) + `activity_type.dart`

```dart
class Activity {
  final String id;
  final String userId;
  final ActivityType type;     // run, walk, jog, cycle
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceMeters;
  final int durationSeconds;
  final double caloriesBurnt;
  final List<LatLng> routePoints;
  final int? steps;
  final double? avgPace;       // min/km for run/walk/jog
  final double? avgSpeed;      // km/h for cycle
  final int? avgHeartRate;
}
```

### ActivityRepository
**Implemented in** `lib/features/activity/domain/repositories/activity_repository.dart` — `FirebaseActivityRepository` in `lib/features/activity/data/repositories/firebase_activity_repository.dart`

```dart
abstract class ActivityRepository {
  Future<Either<Failure, Activity>> saveActivity(Activity activity);
  Future<Either<Failure, List<Activity>>> getActivities(
    String userId, { DateTime? from, DateTime? to, ActivityType? type });
  Stream<List<Activity>> watchTodayActivities(String userId);
  Future<Either<Failure, ActivityStats>> getStats(String userId, DateTime from, DateTime to);
  Future<Either<Failure, void>> deleteActivity(String activityId);
  Future<Either<Failure, SleepLog>> saveSleepLog(SleepLog log);
  Future<Either<Failure, List<SleepLog>>> getSleepLogs(String userId, { DateTime? from, DateTime? to });
}
```

### Activity Providers (available to Frontend)
**Implemented in** `lib/features/activity/presentation/providers/activity_providers.dart` (Riverpod codegen)

```dart
// get_it-backed repository
final Provider<ActivityRepository> activityRepositoryProvider

// GPS service (singleton)
final Provider<LocationService> locationServiceProvider

// Today — watch as AsyncValue (StreamProvider)
final StreamProvider<List<Activity>> todayActivitiesProvider

// Last 7 days rolling window
final FutureProvider<ActivityStats> weeklyStatsProvider

// AI — family: pass optional follow-up question (Flash model)
final FutureProviderFamily<AiInsight, String?> activityInsightProvider
// Usage: ref.watch(activityInsightProvider(null)) or activityInsightProvider('Why is my pace slow?')

// Live GPS tracking (Notifier)
final NotifierProvider<ActivityTracker, ActivityTrackingState> activityTrackerProvider

class ActivityTracker extends Notifier<ActivityTrackingState> {
  Future<void> startTracking(ActivityType type)
  void pauseTracking()
  void resumeTracking()
  Future<Activity?> stopAndSave()
  void cancelTracking() // discard session (no save)
}

// Tracking HUD — status: idle | active | paused | saving
class ActivityTrackingState { ... }
```

**go_router (activity)**  
`/activity` (tab) · `/activity/start` (type sheet) · `/activity/live/:type` · `/activity/complete` (`extra`: `Activity`) · `/activity/sleep` (sleep sheet)

**Status:** ✅ Implemented with the signatures above

### Health Dashboard UI Filters (Presentation Contract)
**Implemented in** `lib/features/health/presentation/screens/health_screen.dart`

- Category filter: `All` + `VitalCategory` chips (existing)
- Status filter: `Status: All`, `Needs attention`, `Moderate`, `Good` (new)
- Status mapping:
  - `Needs attention` → `VitalStatus.elevated`
  - `Moderate` → `VitalStatus.borderline`
  - `Good` → `VitalStatus.normal`
- Filters are composable (category + status both apply to the vitals grid)

---

## DIET MODULE

**Implementation:** `lib/features/diet/` — providers: `presentation/providers/diet_providers.dart` (codegen `*.g.dart`).  
**AI:** `mealPhotoAnalysisProvider` and `dietInsightForProvider` use `aiServiceProvider` from `activity_providers.dart`.

### Domain entities (Freezed)
See `lib/features/diet/domain/entities/`: `Meal`, `FoodItem`, `WaterLog`, `DietSummary`, `Food` + `FoodSource`, `MealType`.

### DietRepository
`FirebaseDietRepository` — Firestore meals/water + local datasource. Abstract:

```dart
abstract class DietRepository {
  Future<Either<Failure, Meal>> saveMeal(Meal meal);
  Future<Either<Failure, List<Meal>>> getMeals(String userId, DateTime date);
  Future<Either<Failure, List<Meal>>> getMealsByDateRange(String userId, DateTime start, DateTime end);
  Future<Either<Failure, void>> deleteMeal(String mealId);
  Future<Either<Failure, DietSummary>> getDailySummary(String userId, DateTime date);
  Future<Either<Failure, WaterLog>> saveWaterLog(WaterLog log);
  Future<Either<Failure, List<WaterLog>>> getWaterLogs(String userId, DateTime date);
  Future<Either<Failure, Map<String, DietSummary>>> getWeeklyNutrition(String userId);
  Stream<List<Meal>> watchMeals(String userId, DateTime date);
}
```

### FoodRepository
`FoodRepositoryImpl` — custom foods + `FoodDatabaseService` + caches.

```dart
abstract class FoodRepository {
  Future<Either<Failure, List<Food>>> searchFood(String query, { int limit, bool isIndian });
  Future<Either<Failure, Food?>> getFoodByBarcode(String barcode);
  Future<Either<Failure, Food>> saveCustomFood(Food food);
  Future<Either<Failure, List<Food>>> getRecentFoods(String userId);
  Future<Either<Failure, List<Food>>> getFrequentFoods(String userId);
}
```

### FoodDatabaseService (`lib/services/food_database_service.dart`)
OFF `searchProducts` / `fetchProductByBarcode`, Drift catalog cache, Gemini fallback.

### BarcodeScannerService (`lib/services/barcode_scanner_service.dart`)
Wraps `MobileScannerController`; see repo `KNOWN_ISSUES.md` D10.

### AiService — diet (`lib/services/ai_service.dart`)
`analyzeMealPhoto`, `parseMealFromText`, `getDietInsight`, `suggestDietPlan` (24h cache). `MealAnalysisResult` in `lib/services/models/meal_analysis_result.dart`.

### Providers
| Provider | Notes |
|----------|--------|
| `mealsForDayProvider(dateKey)` / `todayMealsProvider` | streams |
| `dailySummaryForDateProvider` / `dailySummaryProvider` | |
| `weeklyNutritionProvider` | |
| `waterLogsForDateProvider` / `waterLogsProvider` | |
| `foodSearchProvider(query)` | 400ms debounce in provider |
| `mealLoggerProvider` / `waterLoggerProvider` | `logMeal` / `logWater` → `Either` |
| `barcodeScanProvider` | `Food?` |
| `mealPhotoAnalysisProvider` | `MealAnalysisResult` |
| `dietInsightForProvider` / `dietInsightProvider` | `String` |
| `recentFoodsProvider` / `frequentFoodsProvider` | |

`dietDateKey(DateTime)` → `yyyy-MM-dd`.

### Routes
`/diet`, `/diet/log/:mealType`, `/diet/scan?mealType=`, `/diet/photo/:mealType`

**Status:** ✅ — full contract in repo root `docs/context/API_CONTRACTS.md`; Phase 3 review D1–D12 in `KNOWN_ISSUES.md`.

---

## WORKOUT MODULE
**Status:** ✅ Implemented — entities, repositories, use cases, Firestore paths, Drift caches, providers

### Entities
**Implemented in** `lib/features/workout/domain/entities/` — `exercise.dart`, `workout.dart` (Freezed), `muscle_group.dart`, `equipment.dart`, `exercise_type.dart`, `difficulty_level.dart`, `workout_user_profile.dart`

Key types: `Exercise`, `WorkoutPlan`, `WorkoutSession`, `SessionExercise`, `WorkoutLog`, `CompletedSet`, `PersonalRecord`, `WorkoutSummary`.

### Firestore
- `users/{userId}/workout_plans/{planId}`
- `users/{userId}/workout_logs/{logId}`
- `users/{userId}/personal_records/{exerciseId}`
- `exercises/{exerciseId}` (global catalog)

### Repositories
- `WorkoutRepository` — `lib/features/workout/domain/repositories/workout_repository.dart` — `FirebaseWorkoutRepository`
- `ExerciseRepository` — `lib/features/workout/domain/repositories/exercise_repository.dart` — `ExerciseRepositoryImpl` (local cache + Firestore + bundled seed)

### AiService — workout (`lib/services/ai_service.dart`)
- `generateWorkoutPlan(...)` → `Either<Failure, WorkoutPlan>` (Gemini Flash, 7-day Drift cache, approved exercise names only, sanitized strings)
- `getWorkoutInsight(...)` — optional `ActivityStats` + `DietSummary` cross-module context
- `suggestProgressiveOverload(...)` — short Flash reply, `maxOutputTokens: 200`

### Providers (`lib/features/workout/presentation/providers/workout_providers.dart`)
| Provider / notifier | Notes |
|---------------------|--------|
| `exerciseLibraryProvider(ExerciseLibraryParams)` | filter: muscle, equipment, difficulty, limit |
| `exerciseSearchProvider(query)` | 400ms debounce in provider |
| `activeWorkoutPlanProvider` | current user’s active plan |
| `workoutLogsProvider(WorkoutLogRange)` | optional `from` / `to` |
| `workoutSummaryProvider` | streak + totals + muscle frequency map |
| `personalRecordsProvider` | |
| `recentWorkoutsProvider` | last 10 logs |
| `muscleGroupFrequencyProvider` | from summary |
| `workoutInsightProvider(List<String> recentLogIds)` | AI string; uses activity + diet when available |
| `generatePlanNotifierProvider` | `GeneratePlanNotifier.generate(...)` |
| `activeSessionNotifierProvider` | `ActiveSessionNotifier` — timer/rest |
| `workoutLoggerNotifierProvider` | `saveLog` / `completeSession` |

**Routes:** `/workout`, `/workout/plan-generator`, `/workout/session` (extra: session template), `/workout/complete`, `/workout/exercises`, `/workout/exercise/:id`, `/workout/log-custom` (see `app_router.dart`).

---

## HEALTH MODULE
**Status:** ❌ Not designed yet — will be added when Phase 5 begins

---

## MENTAL WELLBEING MODULE
**Status:** ❌ Not designed yet — will be added when Phase 5 begins

---

## FITCOINS MODULE

### FitcoinsBalance Entity
```dart
class FitcoinsBalance {
  final String userId;
  final int balance;
  final DateTime lastUpdated;
}
```
**Status:** ❌ Not implemented yet

---

## AI SERVICE CONTRACT

### AiService (get_it singleton + `aiServiceProvider`)
**Implemented in** `lib/services/ai_service.dart`

```dart
// Activity — last 7 days context, Gemini 2.0 Flash
Future<AiInsight> getActivityInsight(String userId, String? userQuery)

// Weekly holistic — cross-module placeholder + activity data, Gemini 1.5 Pro
Future<AiInsight> getHolisticInsight(String userId)
```

### Planned (not wired yet)
```dart
Future<AiInsight> getModuleInsight({ required String module, required String query })
Future<Map<String, VitalValue>> scanLabReport(File imageFile)
Future<List<FoodItem>> recogniseFoodFromPhoto(File imageFile)
```

### AiInsight shape
**Implemented in** `lib/services/models/ai_insight.dart`

```dart
class AiInsight {
  final String summary;
  final List<String> details;
  final List<String> suggestions;
  final String disclaimer;       // Default: "This is not medical advice..."
}
```
**Status:** ✅ Partial — activity + holistic insight methods implemented; vision / generic module insight planned

---

## HOW AGENTS MUST USE THIS FILE

### Backend Agent — after implementing any provider or entity:
Update the relevant section. Change `❌ Not implemented yet` to `✅ Implemented` and update the code signature if it changed.

### Frontend Agent — before building any screen:
Read the relevant module section here to know exactly what data and actions are available. Never assume — if a provider isn't listed as ✅, coordinate with Backend Agent first.

### Orchestrator — when resolving interface conflicts:
Update this file with the agreed contract. Both agents must follow the updated contract.

---

## 2026-04-03 Delta (Sync Hardening)

- `SyncService` now also flushes queued offline `activity` and `sleep` payloads from Drift `sync_queue` to Firestore on connectivity restore and on startup.
- `HealthConnectService.getStepsForDateRange(from, to)` now uses exact interval boundaries (partial first/last day) instead of whole-day-only windows to support incremental re-login sync semantics.
