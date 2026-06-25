# KNOWN ISSUES & DECISIONS LOG
# ⚠️ AGENTS: Log every bug, blocker, and resolved decision here.
# This is the project memory — if something broke and was fixed, write it here so it doesn't happen again.

---

## Doc updater — Phase 9 Tab 4 (2026-03-22)
- Phase 9 launch-hardening review: **P9-1–P9-9** in **root** `docs/context/KNOWN_ISSUES.md`.

## Doc updater — Phase 8 Tab 4 (2026-03-22)
- Phase 8 Flutter Review: **P8-1–P8-9** logged in **`docs/context/KNOWN_ISSUES.md`** (canonical). **`docs/PHASE_8_1_PROFILE_FIXES.md`** tracks P1 (**P8-1–P8-4**).

## Open Issues

| ID | Issue | Module | Severity | Logged By | Date |
|----|-------|--------|----------|-----------|------|
| P8-5–P8-9 | Image pick quality, `FitupToggle`/`FitupChip` semantics, edit profile labels, URL scheme guard — **Phase 9 polish** — see root `KNOWN_ISSUES` | Profile / Settings | P2 | Flutter Reviewer | 2026-03-22 |
| P9-1–P9-9 | Phase 9 launch hardening — Android/iOS manifests, CSP, web bundle size, RevenueCat obfuscation, SOS E.164, HTTPS URLs, rules deploy, release signing — **see root** `docs/context/KNOWN_ISSUES.md` | Launch | P1 | Flutter Reviewer | 2026-03-22 |
| C7 | Firestore rules + indexes live in `firebase/` (`firestore.rules`, `firestore.indexes.json`). **Deploy** with `firebase deploy --only firestore:rules,firestore:indexes` before production. Rules deny client writes to `fitcoin_wallet` — current app still uses client transactions for dev; migrate balance updates to Cloud Functions for prod alignment. | Infra | P1 | — | 2026-03-22 |
| D1 | `frequentFoodsProvider` reads `freq_{userId}` in Drift catalog cache; nothing writes that key yet — list stays empty until frequency aggregation is implemented | Diet | P2 | Backend Agent | 2026-03-22 |
| D2 | `dietInsightProvider` uses placeholder user goals and static health string until Profile + Health modules expose real fields | Diet | P2 | Backend Agent | 2026-03-22 |
| D6–D12 | Remaining Phase 3 Flutter review items (P2/P3) — deferred per Phase 4 gate; track in review doc | Various | P2/P3 | — | 2026-03-22 |
| I4 | Insight chat: messages with failed Firestore `setChatMessage` stay `synced: false` locally — no automated retry until `SyncService` / outbox | Insights | P2 | Backend Agent | 2026-03-22 |
| BG-1 | Background activity tracking deferred to v1.1 (GPS kept alive when app is backgrounded/killed requires WorkManager/foreground service) | Activity Tracking | P2 | Backend Agent | 2026-03-23 |
| W2 | Phase 4 workout review — P2 (see Phase 4 review doc) | Workout | P2 | — | 2026-03-22 |
| W4–W9 | Phase 4 workout review — P2/P3 backlog (acceptable for now) | Workout | P2/P3 | — | 2026-03-22 |
| W12 | Phase 4 workout review — P3 (acceptable for now) | Workout | P3 | — | 2026-03-22 |

---

## Resolved Issues

| ID | Issue | Root Cause | Fix Applied | Date |
|----|-------|------------|-------------|------|
| C1 | `communityTabBadgeProvider` used `FirebaseFirestore` in presentation | Architecture rule: no Firebase in UI | `CommunityRepository.watchUnreadNotificationCount`; `FirebaseCommunityRepository` implements; `communityTabBadgeProvider` watches repo stream only | 2026-03-22 |
| C2 | No report/block stubs | Phase 8 safety prep | Domain `UserReport`, `BlockedUser`, `ReportReason`; repo `reportUser` / `blockUser` / `getBlockedUserIds`; Firestore `reports/`, `users/{uid}/blocked_users/`; feed filters blocked authors; UI sheet + overflow on feed | 2026-03-22 |
| C3 | Community screens used mock providers / not wired | Providers not calling repository | `upcomingEventsProvider`, `leaderboardEntriesProvider`, `socialFeedProvider`, `eventByIdProvider`, etc.; `CommunityScreen`, events list, `LeaderboardScreen`, `EventDetailScreen`, `SocialFeedScreen` use `AsyncValue` + retry | 2026-03-22 |
| C4 | `redeemCoins` used generic `ValidationFailure` for low balance | Callers could not branch on insufficient balance | `InsufficientBalanceFailure` in `failures.dart`; `FirebaseFitcoinRepository.redeemCoins` returns it; `FitcoinRepository` documented; test updated | 2026-03-22 |
| I1 | Gemini Pro spend on passive `weeklyReportProvider` watch when cache empty | `getWeeklyReport` called `generateWeeklyReport` whenever local row missing/stale | `allowProIfStale` on `getWeeklyReport`; default false → `WeeklyReport.placeholder`; Pro only via `generateWeeklyReport`, Sunday, or `WeeklyReportProGate.remoteConfigAllowsAutoPro` (ADR-016); `generateThisWeekReport()` on notifier; tests in `firebase_insight_repository_test`, `weekly_report_pro_gate_test` | 2026-03-22 |
| I2 | `ConflictDetector` used clinical framing (e.g. prediabetes, deficiency detected) | Rule copy not aligned with screening-only policy | Rewrote titles/messages to hedging + clinician discussion (ADR-017); tests in `conflict_detector_test` (golden-style strings, no “prediabetes” in glucose rule) | 2026-03-22 |
| I3 | `sendChatMessage` returned `Left` after local + AI success when Firestore threw | Remote try/catch returned failure despite usable local reply | Return `Right` with `ChatMessage.cloudSyncPending: true`; rows stay unsynced; SnackBar in `AiChatScreen` (ADR-020); test updated in `firebase_insight_repository_test` | 2026-03-22 |
| H1 | Menstrual cycle UI only in-memory; not persisted via `HealthRepository` | `MenstrualCycleRepository` Riverpod notifier faked saves | `menstrualHistoryProvider` + `MenstrualCycleLogNotifier.saveCycleLog` → `LogMenstrualCycleUseCase` / `FirebaseHealthRepository`; calendar from `getMenstrualHistory`; Drift payload uses ISO JSON (`_menstrualToLocalJsonMap`) | 2026-03-22 |
| H2 | `LabScanScreen` called `AiService.analyzeLabReport` directly | Screen bypassed `LabScanNotifier` / use-case pipeline | `LabScanNotifier.extractLabReportRows`; screen uses `labScanProvider.notifier` only; policy test `lab_scan_screen_no_ai_direct_test.dart` | 2026-03-22 |
| M1 | `MeditationTimerScreen._complete` disposed `AnimationController` then `dispose()` disposed again | Double `dispose()` on `_pulse` | `_complete` uses `_pulse.stop()` only; single dispose in `dispose()`; widget test `meditation_timer_screen_test.dart` | 2026-03-22 |
| W1 | Raw Firebase `userId` in Gemini workout prompt context | `AiService` embedded profile context with UID | `workoutProfilePromptSegment` in `lib/services/workout_ai_prompt.dart` (no identifiers); `generateWorkoutPlan` uses it; test: `workout_ai_prompt_test.dart` | 2026-03-22 |
| W3 | Fitcoin Firestore increment failure still returned `Right(workoutLog)` | Error only logged; UI implied FTC awarded | `saveWorkoutLog` returns `Left(FitcoinUpdateFailure(..., savedWorkoutLog: log))` after log saved; optional `fitcoinIncrement` inject for tests | 2026-03-22 |
| W10 | `finishSession` Left branch in `ActiveSessionScreen` showed nothing | Empty `fold` left branch | SnackBar + Retry/Discard; Fitcoin partial success navigates with message; `ref.listen` auth to start session when ready | 2026-03-22 |
| W11 | `finished=true` before `finishSession` completed; stuck state on failure | `completeSet` set finished before await | `finished` only on `Right`; `saveError` + `sessionEnded` on failures; `retrySave()`; notifier + widget tests | 2026-03-22 |
| R1 | Logo files were 1×1 pixel placeholders (invisible in UI) | Cursor created tiny placeholder files when scaffolding the assets folder | Replaced `fitup/assets/images/logo.png` and `fitcoins.png` with full-size PNGs from `Fitup/assets/images/` (copy on build; parent folder created and populated when it was missing). Regenerated launcher icons via `flutter_launcher_icons` from `logo.png`. Updated `FitupLogo` with a dark rounded plate behind the image for transparent logos. | 2026-03-21 |
| D3 | `saveMeal` / `saveWaterLog` returned `Right` on exception — UI showed “saved” when persistence failed | Catch blocks always returned success value | Catch blocks now return `Left` with `ServerFailure` / mapped failure via `_mapException`; local read fallbacks wrapped so `Left` is returned if both remote and local fail; `food_repository_impl` cache parse errors return `CacheFailure` | 2026-03-22 |
| D4 | Raw meal description sent to Gemini — PII / prompt-injection risk | No sanitization before `generateContent` | Added `lib/services/ai_input_sanitizer.dart` (truncate, email/phone redaction, injection markers); applied in `parseMealFromText`, `getDietInsight`, `suggestDietPlan`, `getActivityInsight` | 2026-03-22 |
| D5 | `dailySummaryForDateProvider` wrapped failures as `Exception` | `fold` used `throw Exception(f.message)` | `throw f` with `Failure implements Exception`; not-logged-in uses `AuthFailure` | 2026-03-22 |
| GAP1 | Historical step backfill + last-sync tracking | No local sync metadata; missed wearable days could not be reconstructed | Added `HealthSyncMetadata` Drift table + `HealthConnectService.getStepsForDateRange` + `syncHistoricalSteps()`; passive step upserts via `upsertPassiveStepsForDate()`; launch-time backfill after auth | 2026-03-23 |
| GAP2 | Offline Fitcoin award queue | Failed remote award offline dropped reward (no retry/outbox) | Added `FitcoinAwardQueue` Drift table + `FitcoinAwardService.awardCoins()` enqueues on failure; `SyncService.syncPendingAwards()` retries on connectivity restore (with retry-count cap) | 2026-03-23 |
| GAP3 | GPS loss handling during active session | GPS signal loss caused distance/pace gaps without user feedback or persisted metrics | Added GPS inference state (`GpsSignalStatus`) + interruption counters; UI chip in live HUD; saved `gpsDropSeconds`/`gpsDropInterruptions` on session save | 2026-03-23 |
| GAP4 | Centralized permission onboarding flow | Permissions requested ad-hoc without pre-check/rationale | Added `PermissionService` + `permissionStateProvider`; first-launch `PermissionRationaleSheet` on `HomeScreen` | 2026-03-23 |
| P8-1 | `updateProfile` returned `Right` when Firestore failed after Drift write | Remote failure not surfaced; cold start could read stale Firestore | Optimistic Drift with `synced`; on Firestore error set `synced: false`, `SyncStatusEmitter` SnackBar (“saved locally…”), `SyncService.enqueueProfileSync` / `flushPendingProfileToRemote`; Drift failure still `Left` | 2026-03-22 |
| P8-2 | `deleteAccount` left Firestore/Storage/Drift data | Only Auth user removed | `AccountDeletionService`: batch known subcollections, Storage `users/{uid}/**`, `clearAllUserData`, then `user.delete()`; re-auth message on `requires-recent-login` | 2026-03-22 |
| P8-3 | Onboarding state memory-only | Crash lost wizard progress | Drift `onboarding_draft_cache` + `OnboardingDraftRepository`; `OnboardingNotifier` saves on change; restore step on launch; clear on complete | 2026-03-22 |
| P8-4 | No Storage rules in repo | Any path policies unverifiable from VCS | `firebase/storage.rules` owner-only avatar + progress (10 MB); `firebase.json` `storage.rules`; deploy `firebase deploy --only storage` | 2026-03-22 |
| C5 | Community “Leaderboard Preview” podium preview overflow | Wide podium layout in `CommunityScreen` | Removed leaderboard preview section from `CommunityScreen` and navigates users directly to full leaderboard | 2026-04-03 |
| S1 | Settings missing AI usage tracker + field diagnostics logs UI | UI cards not present in `SettingsScreen` | Restored AI usage snapshot + trace log controls in `lib/features/settings/presentation/screens/settings_screen.dart` | 2026-04-03 |
| C6 | Events create button loop due to missing router route | `app_router.dart` lacked `/community/events/create` (and `/search`) | Added nested routes for `/community/events/create` (CreateEventScreen) and `/community/events/search` (EventSearchScreen) | 2026-04-03 |
| H3 | Health vitals “Add reading” threw “no routes for location” | `VitalTrendScreen` FAB pushed invalid `/health/log` path | Updated FAB navigation to `/health/vitals/log?type=...` | 2026-04-03 |
| W12-2 | Duplicate workout “Get your plan” compact card caused overflow | Workout screen rendered an extra plan glass card | Removed plan==null compact “Get your plan” block in `workout_screen.dart` | 2026-04-03 |
| H4 | Home holistic plan red screen (`framework.dart` assertion) after wizard input | Step-2 dialog `TextEditingController`s were disposed while `TextField` widgets still rebuilding during route teardown | Replaced step-2 wizard inputs with controller-free `TextFormField(onChanged:)` state in `home_screen.dart` | 2026-04-03 |
| C8 | Deleted event still visible until manual refresh | Event list provider not invalidated after organizer delete action | Invalidate `upcomingEventsProvider` on delete success in `event_detail_screen.dart` before navigating back | 2026-04-03 |
| F2 | Achievement popup shown for non-step rewards | Celebration source whitelist included meals/workout/water/login milestone | Restricted `FitcoinTransaction` celebration sources to `EarnSource.dailyStepGoal` only | 2026-04-03 |
| H5 | Holistic plan generation failed with “No JSON object found” | Gemini sometimes returned non-JSON text around plan output, causing strict parse failure | Added safe fallback in `AiService` to synthesize `HolisticPlanDraft` defaults when JSON parse fails, preserving plan creation flow | 2026-04-03 |
| H6 | Plan created but module screens still showed “Create holistic plan” in some flows | Profile sync failure after successful plan save returned overall `Left`, preventing success-path invalidation/UI refresh | Made profile sync non-blocking in `holistic_plan_ui_actions.dart`; return `Right(plan)` when save succeeds | 2026-04-03 |
| F3 | Daily step celebration popup still repeated across launches | Dedupe previously used transaction id only; repeated daily awards with new ids retriggered popup | Added day-scoped dedupe key (`source + yyyy-mm-dd`) in celebration notifier | 2026-04-03 |
| GAP5 | Offline activity/sleep rows could remain local-only if first remote write failed | Drift `sync_queue` writes were queued but not globally flushed by `SyncService` | Added `SyncService.syncPendingActivityAndSleep()` (startup + connectivity restore) to replay queued rows to Firestore and mark local rows synced | 2026-04-03 |
| GAP6 | Health Connect sync queried whole-day windows again after partial-day sync | Backfill window rounded `from` to day start, re-reading already-synced interval | `HealthConnectService.getStepsForDateRange()` now uses partial-day boundaries and step upsert keeps max(existing, fetched) for idempotent incremental sync | 2026-04-03 |
| H10 | Home workout card showed 100% based on session-count logic that could reach target with one completed workout day | Home card progress used sessions/day metric instead of calories burn target requested by product | Switched home workout card to daily calories (`todayCaloriesBurntProvider`) vs profile `dailyCalorieGoal` ring and primary metric; weekly sessions kept as secondary context | 2026-04-06 |
| H11 | Daily/weekly steps could be double counted when passive Health Connect synthetic records and active tracked sessions existed on the same day | Aggregation summed both passive day-total steps (`passive_steps_*`) and tracked activity steps | Added `stepsByDayNoDoubleCount` aggregator: per day step total = `max(passiveSteps, activeSteps)`; wired into activity repository stats, activity dashboard totals/charts, and home activity summary | 2026-04-06 |
| A-SLEEP-1 | Manual sleep log had only time (no date) and graph often did not update after save | Sleep sheet route opened without a save callback; UI could not persist log and had no explicit date-time range selection | Added sleep start/end **date + time** pickers in `sleep_log_sheet.dart`; wired `/activity/sleep` route to persist via `ActivityRepository.saveSleepLog`; activity screen now awaits route return and invalidates `sleepRangeProvider` to refresh graph immediately | 2026-04-03 |
| W13 | Workout daily burn ring did not update after logging a workout | `todayCaloriesBurntProvider` queried logs with a midnight-only range (`from == to`) and did not invalidate after save | Compute today calories from `workoutLogsProvider(const WorkoutLogRange())` with local date filtering; invalidate `todayCaloriesBurntProvider` in `WorkoutLoggerNotifier.completeSession`; added a Daily Burn card on Home using the same provider | 2026-04-03 |
| H7 | Health dashboard had category filter only; users could not quickly segment by concern severity | No status-level filter for `VitalStatus` buckets in vitals grid | Added status chips on `HealthScreen` (`Needs attention`, `Moderate`, `Good`) mapped to `VitalStatus.elevated`, `VitalStatus.borderline`, `VitalStatus.normal` with combinable category+status filtering | 2026-04-03 |
| H8 | Home showed duplicate AI insights section | Home rendered both top `AI Insights` actions and a second bottom “How are you doing holistically?” orb card | Removed bottom `_AiInsightOrb` section so only the top AI Insights area remains | 2026-04-03 |
| H9 | Home showed separate Diet/Workout wheel tracker cards despite mini wheels on module cards | Standalone `Daily Burn` + `Diet Tracker` section duplicated progress UI and conflicted with module-card wheel design | Removed standalone wheel tracker section; kept mini top-right wheels inside `Activity`, `Diet & Fuel`, and `Workout` cards only | 2026-04-03 |

---

## Decisions Made During Development
_Log ad-hoc decisions here — bigger structural decisions go in ARCHITECTURE_DECISIONS.md_

| Date | Decision | Reason | Agent |
|------|----------|--------|-------|
| — | — | — | — |

---

## HOW AGENTS MUST USE THIS FILE

### When you hit a bug or blocker:
Add a row to Open Issues immediately. Don't just fix it silently.

### When you fix an issue:
Move it from Open Issues to Resolved Issues. Add the root cause and fix.

### When you make a small decision that other agents should know about:
Add a row to "Decisions Made During Development".

**Severity levels:**
- P0 — App crashes or build fails
- P1 — Feature broken but app works
- P2 — Minor issue, workaround exists
- P3 — Cosmetic / nice to have
