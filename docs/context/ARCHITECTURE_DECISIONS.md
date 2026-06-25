# ARCHITECTURE DECISIONS
# ⚠️ AGENTS: Read this before making any structural or technical decision.
# Add a new entry here whenever a significant decision is made.

---

## ADR-001: Flutter for cross-platform
- **Decision**: Use Flutter 3.x for Android, iOS, and Web from a single codebase
- **Reason**: Single codebase reduces solo developer overhead. Web app needed for vitals/diet logging without GPS
- **Consequence**: Some platform-specific code needed (Health Connect for Android, HealthKit for iOS) via method channels

## ADR-002: Firebase as initial backend
- **Decision**: Firebase (Firestore, Auth, Storage, Functions) for MVP
- **Reason**: Zero server management, generous free tier, fast to ship
- **Migration path**: Repository pattern (abstract interfaces in domain/) ensures we can swap to Supabase/custom backend without touching UI or domain code
- **Consequence**: All Firestore calls MUST go through repository implementations. Never call Firebase directly from UI or domain layers.

## ADR-003: Riverpod 2.x for state management
- **Decision**: Riverpod with code generation (`@riverpod` annotation)
- **Reason**: Type-safe, less boilerplate than BLoC, compile-time error checking, great for solo dev
- **Consequence**: Always use `@riverpod` annotation + `build_runner`. Never use raw `Provider()` constructors.

## ADR-004: Offline-first architecture
- **Decision**: All writes go to local Drift (SQLite) first, then sync to Firebase
- **Reason**: App must work outdoors with poor connectivity (activity tracking, food logging)
- **Consequence**: Every feature needs a local datasource AND a remote datasource. SyncService handles the queue.

## ADR-005: Clean Architecture with strict layer separation
- **Decision**: data / domain / presentation layers with enforced boundaries
- **Reason**: Maintainability, testability, and future backend migration
- **Rules**:
  - presentation → imports domain only
  - domain → pure Dart, zero external dependencies
  - data → implements domain interfaces, owns all external calls
  - NEVER: UI importing Firebase, UI importing data layer directly

## ADR-006: get_it + injectable for dependency injection
- **Decision**: Use get_it service locator with injectable code generation
- **Reason**: Simpler than manual DI, works well with Riverpod, easy to swap implementations (e.g., Firebase repo → Supabase repo)
- **Consequence**: All repositories and services registered in `lib/core/di/injection.dart`

## ADR-007: Gemini AI model selection
- **Decision**: Gemini 2.0 Flash for real-time (meal questions, quick insights), Gemini Pro for holistic cross-module analysis
- **Reason**: Cost optimisation — Flash is cheaper and fast enough for chat; Pro for the weekly reports
- **Consequence**: AiService has two model instances. Never use Pro for real-time queries.

## ADR-008: Repository pattern for future migration
- **Decision**: Every module has an abstract repository interface in domain/ and a Firebase implementation in data/
- **Future**: A SupabaseXxxRepository can be created implementing the same interface and swapped in DI config
- **Example**:
  - `domain/repositories/activity_repository.dart` — abstract interface
  - `data/repositories/firebase_activity_repository.dart` — current implementation
  - `data/repositories/supabase_activity_repository.dart` — future, same interface

## ADR-009: Error handling with Either
- **Decision**: Use `Either<Failure, T>` from dartz package for all repository return types
- **Reason**: Forces explicit error handling, no unexpected exceptions bubbling to UI
- **Consequence**: All repository methods return `Future<Either<Failure, T>>`. UI handles both Left (error) and Right (success) cases.

## ADR-010: No hardcoded values
- **Decision**: All colors from AppColors, all text styles from AppTextStyles, all API keys from env config
- **Reason**: Consistency, theming, and security
- **Consequence**: If you need a color or style not in AppColors/AppTextStyles, ADD it there first, then use it.

## ADR-016: Gemini Pro only for explicit weekly report generation
- **Decision**: `getWeeklyReport(..., allowProIfStale: false)` returns a local placeholder without calling Pro. Pro runs when the user taps **Generate this week**, on **Sunday** (auto), or when **Remote Config** sets `WeeklyReportProGate.remoteConfigAllowsAutoPro`.
- **Reason**: Avoid surprise Pro spend on passive `ref.watch` (e.g. opening Insights hub).
- **Consequence**: `WeeklyHolisticReportNotifier` passes `allowProIfStale` from `WeeklyReportProGate`; `generateThisWeekReport()` / `generateWeeklyReport` always allow Pro.

## ADR-017: Rule engine vs AI for insights copy
- **Decision**: `ConflictDetector` and similar rule outputs use screening-style hedging only (“may warrant discussion with your clinician”, “typical reference band”). No diagnoses, “deficiency detected”, or “prediabetes” labels in user-facing insight strings.
- **Reason**: Medical copy policy; rules are deterministic and must stay non-clinical.
- **Consequence**: Gemini may add soft recommendations separately; rule titles/messages stay hedged. Vitals reference-range labels in Health module may still use clinical band names where product requires — keep Insights/correlation copy aligned with this ADR.

## ADR-020: Coach chat — local truth on remote failure
- **Decision**: After Drift persist + successful `chatWithAI`, if Firestore `setChatMessage` fails, return `Right(ChatMessage)` with `cloudSyncPending: true` and leave rows `synced: false` for a future sync/retry path.
- **Reason**: User should see the assistant reply that already exists locally; remote failure must not look like total failure.
- **Consequence**: UI may show a SnackBar; full `SyncService` retry for chat outbox is future work (see `KNOWN_ISSUES.md`).

---

## HOW AGENTS MUST USE THIS FILE

### Before making a structural decision:
Check if there's an ADR that covers it. If yes, follow it.

### When making a new significant decision:
Add a new ADR entry at the bottom in the same format:
```
## ADR-XXX: Short title
- **Decision**: What was decided
- **Reason**: Why
- **Consequence**: What this means for other code
```

Examples of decisions that need an ADR:
- Choosing a new package for a feature
- Changing a naming convention
- Deciding how a cross-module data flow works
- Changing the sync strategy for a module
