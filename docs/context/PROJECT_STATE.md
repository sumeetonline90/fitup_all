# PROJECT STATE
# ⚠️ AGENTS: Read this before starting ANY task. Update it when you finish ANY task.
#
# **Canonical file:** `docs/context/PROJECT_STATE.md` (repo root). This copy may lag; prefer root for Phase 9+.

Last Updated: Phase 9.2 — Home workout calories ring + no-double-count steps (H10/H11)
Updated By: Bugfix agent — 2026-04-03

---

## App Status: PHASE 9.2 COMPLETE — ACTIVITY & HEALTH SYNC GAP FIXES (BG-1 deferred)

**Phase 4 (backend slice):** Workout entities/repos/use cases, Firestore + Drift v3 caches (`exercise_library`, `personal_records`, `workout_plan` 7-day AI cache, `workout_log` queue), `FirebaseWorkoutRepository` / `ExerciseRepositoryImpl`, `AiService` workout helpers (`generateWorkoutPlan`, `getWorkoutInsight`, `suggestProgressiveOverload`), Riverpod `workout_providers.dart`. Tests: `firebase_workout_repository_test` (including `Left(ServerFailure)` on remote throw), `generate_workout_plan_usecase_test`, `log_workout_usecase_test`, `complete_session_usecase_test`.

**Phase 4.1:** Gemini prompts use `workoutProfilePromptSegment` (no Firebase UID). `FitcoinUpdateFailure` when log saves but FTC increment fails. `ActiveSessionNotifier` sets `finished` only after successful save; `saveError` / `sessionEnded`; `ActiveSessionScreen` SnackBars + retry/discard; auth `ref.listen` so session starts when sign-in resolves. New tests: `workout_ai_prompt_test`, `active_session_notifier_test`, `active_session_screen_test`, Fitcoin repo test.

**Phase 5 / 5.1:** Health + Mental Wellbeing UI/repos (vitals, labs, medications, menstrual, surveys, meditation). **5.1:** Menstrual data via `HealthRepository` + `menstrualHistoryProvider` / `menstrualCycleLogProvider`; lab scan preview via `LabScanNotifier.extractLabReportRows`; meditation timer no double-dispose on `_pulse`. Tests: `saveMenstrualCycle` repo test, `menstrual_cycle_log_notifier_test`, `lab_scan_screen_no_ai_direct_test`, `meditation_timer_screen_test`.

**Phase 6 / 6.1:** AI Insights (`insights/`) — daily briefing, rule + AI alerts, weekly holistic report (Pro), coach chat. **6.1:** Pro gated (`getWeeklyReport` placeholder unless Sunday / Remote Config / user **Generate**); `ConflictDetector` hedged copy (ADR-017); chat returns `Right` + `cloudSyncPending` when Firestore fails after local+model (ADR-020). Tests: `firebase_insight_repository_test`, `conflict_detector_test`, `weekly_report_pro_gate_test`.

**Phase 7 / 7.1:** Community + Fitcoins — `FirebaseCommunityRepository` + `FirebaseFitcoinRepository`; tab badge via `watchUnreadNotificationCount` (no Firestore in presentation); social feed + leaderboard + events wired through Riverpod; report/block stubs; `InsufficientBalanceFailure` on redeem; Firestore rules + index stubs under `firebase/` (deploy before prod — see `KNOWN_ISSUES` C7). Tests: `community_repository_test`, `fitcoin_award_service_test` (redeem).

**Phase 8 / 8.1:** Profile + Settings + Onboarding — optimistic profile sync (`user_profile_cache.synced`, `SyncStatusEmitter`, `SyncService` + connectivity); `AccountDeletionService` + `clearAllUserData`; onboarding Drift draft + restore; `firebase/storage.rules` + `firebase.json` storage entry. Tests: `profile_sync_test`, `onboarding_draft_test`.

---

## What's Built

### Infrastructure
| Item | Status | Notes |
|------|--------|-------|
| Flutter project created | ✅ | `fitup/` |
| pubspec.yaml configured | ✅ | Firebase, Riverpod, go_router, google_fonts, etc. |
| Folder structure created | ✅ | feature-first layout |
| Firebase connected | ✅ | `firebase_options.dart`, init in `main.dart` |
| Riverpod configured | ✅ | `ProviderScope`, feature providers |
| get_it DI configured | ✅ | `lib/core/di/injection.dart` — Auth, Activity, Diet, Food, AiService, FoodDatabase, BarcodeScanner, Location, Health |
| go_router configured | ✅ | `lib/core/router/app_router.dart` + auth redirects |
| Drift (local DB) configured | ✅ | `lib/core/database/fitup_database.dart` — activities, sleep, sync queue, diet meal/water/food search/catalog, diet plan cache, workout exercise/PR/plan/log caches — schema v3 (mobile/desktop; web uses in-memory local DS) |
| ConnectivityService | ❌ | Planned |
| Logger service | ✅ | `logger` package + app logging |
| Error handling (Failure classes) | ✅ | `lib/core/error/failures.dart` |
| analysis_options.yaml | ✅ | `flutter_lints` |

### Design System (lib/core/theme/)
| Item | Status | Notes |
|------|--------|-------|
| AppColors | ✅ | Stitch tokens — `app_colors.dart` |
| AppTextStyles | ✅ | Space Grotesk + Manrope — `app_text_styles.dart` |
| AppTheme (dark) | ✅ | `app_theme.dart` |
| AppGradients | ❌ | Use inline gradients in screens/widgets for now |

### Shared Widgets (lib/shared/widgets/)
| Item | Status | Notes |
|------|--------|-------|
| GlassCard | ✅ | Stitch glassmorphism — `glass_card.dart` |
| NeonButton | ✅ | `neon_button.dart` |
| GradientAppBar | ❌ | Not required for Phase 1 |
| ChartWrapper | ❌ | Planned with charts module |
| ShimmerLoading | ✅ | `shimmer_loading.dart` |
| ModuleSummaryCard | ❌ | Use `ModuleCard` on home for now |
| EmptyState | ✅ | `empty_state.dart` |
| ErrorState | ✅ | `error_state.dart` |

### Features
| Module | Domain Layer | Data Layer | UI Layer | AI Integration | Status |
|--------|-------------|------------|----------|----------------|--------|
| Auth | ✅ | ✅ | ✅ | — | Phase 1 |
| Profile | ✅ | ✅ | `ProfileScreen` / `EditProfileScreen` | — | Phase 8 + 8.1 sync semantics |
| Home | — | — | ✅ | — | Activity + Diet + Workout cards (`weeklyStatsProvider`, `dailySummaryProvider`, `workoutSummaryProvider` / plan / recent — see root `docs/context/PROJECT_STATE.md`) |
| Activity | ✅ | ✅ | ✅ | ✅ | Routes, live GPS, dashboards, AI sheet — see `API_CONTRACTS.md`; AI Plan module controls (generate dynamic-duration + amend daily step targets) |
| Diet | ✅ | ✅ | ✅ | ✅ | `DietScreen`, meal log, barcode, photo, water, AI sheet — all wired to providers + routes; AI Plan module controls (generate dynamic-duration + amend calories/water targets) |
| Workout | ✅ | ✅ | ✅ screens + providers | ✅ | Phase 4 — wired to repos + AI; exercise seed + offline cache; AI Plan module controls (generate dynamic-duration + amend daily workout minutes target) |
| Health | ✅ | ✅ | ✅ screens + providers | Partial | Vitals, labs, meds, menstrual (persisted), summaries — see `health/` |
| Mental Wellbeing | ✅ | ✅ | ✅ screens + providers | Partial | Mood, surveys, breathing, meditation — see `mental_wellbeing/`; AI Plan module controls (generate dynamic-duration + amend daily sleep target) |
| Insights | ✅ | ✅ | ✅ screens + providers | Flash + gated Pro | Briefing, alerts, weekly report, coach chat — see `insights/`; ADR-016–020 |
| Community | ✅ | ✅ | ✅ providers + screens | — | Phase 7 — feed, events, leaderboard, report/block; ADR-021–024 alignment; Events: organizer `delete/extend` actions + “Create duel challenge” routing + AI Plan Guide manual |
| Fitcoins | ✅ | ✅ | ✅ wallet + ledger | — | Phase 7 — `InsufficientBalanceFailure`; rules deny client wallet writes (see C7) |

### Services (lib/services/)
| Service | Status | Notes |
|---------|--------|-------|
| AiService (Gemini) | ✅ | `lib/services/ai_service.dart` — Flash + Pro; meal photo/text diet helpers; diet plan cache (Drift); workout plan generation + insight + progressive overload (sanitized inputs); holistic insight uses DietRepository |
| FoodDatabaseService | ✅ | Open Food Facts + Gemini fallback + Drift catalog cache |
| BarcodeScannerService | ✅ | Wraps `MobileScannerController` (`captures` stream for UI) |
| LocationService (GPS) | ✅ | `lib/services/location_service.dart` |
| HealthConnectService | ✅ | `health_connect_service.dart` (mobile + web stub) |
| HealthKitService | ❌ | |
| NotificationService | ❌ | `flutter_local_notifications` dep |
| SyncService | ✅ | `SyncService` + `SyncStatusEmitter` (profile + fitcoin + activity/sleep outbox flush on connectivity/startup) |
| AnalyticsService | ❌ | Firebase Analytics dep |

### Diet module — presentation (`lib/features/diet/`)
| Area | Notes |
|------|--------|
| Screens | `diet_screen`, `meal_log_screen`, `barcode_scanner_screen`, `photo_meal_screen` |
| Widgets | `water_tracker_card`, `weekly_nutrition_chart`, `macro_bar_chart`, `calorie_ring_chart`, `meal_type_selector`, `ai_diet_insight_sheet` |
| Use cases | `log_meal`, `log_water`, `search_food`, `scan_barcode`, `get_daily_summary`, `get_weekly_nutrition` |

### Workout module (`lib/features/workout/`)
| Area | Notes |
|------|--------|
| Domain / data | Repos, use cases, `exercise_seed.dart`, Firestore + Drift v3 |
| Presentation | `workout_providers.dart`, screens (`workout_screen`, plan generator, active session, complete, library, detail, logger), widgets |
| Tests | `firebase_workout_repository_test`, `generate_workout_plan_usecase_test`, `log_workout_usecase_test`, `complete_session_usecase_test` |

---

## Current Phase
**Phase 9.2 — Activity & Health Sync Gap Fixes:** GAP1 (step backfill + last-sync tracking), GAP2 (offline Fitcoin award queue), GAP3 (GPS loss handling + persisted metrics), GAP4 (centralized permission onboarding flow) — see `KNOWN_ISSUES.md` Resolved. BG-1 (background activity tracking) remains open for v1.1.

**Next:** Phone testing + remaining Phase 9 polish items (P9-7–P9-9).

Ongoing: I4 chat Firestore retry (partial — profile uses `SyncService`; chat P2); D1/D2 diet data quality (P2); C7 deploy Firestore rules; workout P2/P3 backlog in `KNOWN_ISSUES.md`.

---

## Known Issues / Blockers
- **Google Sign-In on device:** May show `DEVELOPER_ERROR` until OAuth client / SHA-1 is configured in Firebase Console for this app.
- **Plugins:** `health` upgraded to ^13.3.1; `speech_to_text` to ^7.3.0 (V1 embedding fixes). Android `minSdk` uses `maxOf(flutter.minSdkVersion, 26)` for Health Connect.

---

## HOW AGENTS MUST USE THIS FILE

### Before starting a task:
1. Read this file to understand what exists
2. Check the relevant module row — if a dependency shows ❌, build that first or coordinate with the other agent

### After completing a task:
Update the relevant row from ❌ to ✅ and add a note. Example:
```
| AppColors | ✅ | Created at lib/core/theme/app_colors.dart |
```

### When you discover a bug or blocker:
Add it to the "Known Issues / Blockers" section immediately.
