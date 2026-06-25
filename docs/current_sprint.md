# Current Sprint: Phase 0 - Foundation & Design
**Dates**: Week 1-3
**Goal**: Set up Flutter project scaffold, design system, Firebase config, and CI/CD

---

## Pre-Sprint Checklist
| # | Task | Status | Owner |
|---|------|--------|-------|
| P0 | Design all screens in Google Stitch | Not Started | Sumeet |
| P1 | Save all Stitch screenshots to docs/ui_screenshots/ | Not Started | Sumeet |
| P2 | Create Firebase project (fitup-app) | Not Started | Sumeet |
| P3 | Enable Firebase Auth (Google + Email/Password) | Not Started | Sumeet |
| P4 | Create Firestore database (production mode) | Not Started | Sumeet |
| P5 | Get google-services.json (Android) & GoogleService-Info.plist (iOS) | Not Started | Sumeet |
| P6 | Set up GitHub repository | Not Started | Sumeet |

---

## Sprint Tasks

### Week 1: Project Scaffold

| ID | Task | Agent | Status | Priority | Notes |
|----|------|-------|--------|----------|-------|
| T01 | Initialize Flutter project: `flutter create fitup --org com.innoval.fitup` | Orchestrator | Not Started | P0 | |
| T02 | Set up folder structure (clean architecture) | Orchestrator | Not Started | P0 | See .cursorrules |
| T03 | Configure pubspec.yaml with all dependencies | Orchestrator | Not Started | P0 | Package list in .cursorrules |
| T04 | Set up Firebase initialization (core, auth, firestore) | Backend | Not Started | P0 | Needs P5 done first |
| T05 | Configure Riverpod (add ProviderScope, set up code gen) | Backend | Not Started | P0 | |
| T06 | Set up get_it dependency injection container | Backend | Not Started | P0 | |
| T07 | Configure go_router with bottom navigation shell | Orchestrator | Not Started | P0 | 5 tabs: Home, Activity, Diet, Workout, Profile |
| T08 | Create AppColors, AppTextStyles, AppTheme | Frontend | Not Started | P0 | Use neon fluidic specs from agent file |
| T09 | Create GlassCard shared widget | Frontend | Not Started | P0 | |
| T10 | Create NeonButton shared widget | Frontend | Not Started | P0 | |
| T11 | Create GradientAppBar shared widget | Frontend | Not Started | P1 | |
| T12 | Create ChartWrapper shared widget | Frontend | Not Started | P1 | Uses fl_chart |
| T13 | Create ShimmerLoading shared widget | Frontend | Not Started | P1 | For loading states |
| T14 | Create ModuleSummaryCard shared widget | Frontend | Not Started | P1 | Home dashboard cards |

### Week 2: Core Infrastructure

| ID | Task | Agent | Status | Priority | Notes |
|----|------|-------|--------|----------|-------|
| T15 | Create base Failure classes and error handling | Backend | Not Started | P0 | |
| T16 | Create base repository pattern (abstract + helpers) | Backend | Not Started | P0 | |
| T17 | Create User entity (freezed) | Backend | Not Started | P0 | |
| T18 | Create UserModel (Firestore DTO) | Backend | Not Started | P0 | |
| T19 | Set up Drift (SQLite) local database | Backend | Not Started | P0 | Offline-first |
| T20 | Create ConnectivityService | Backend | Not Started | P0 | |
| T21 | Create SyncService base class | Backend | Not Started | P1 | |
| T22 | Set up Firebase Analytics + Crashlytics | Backend | Not Started | P1 | |
| T23 | Create logger service (replaces print) | Backend | Not Started | P1 | |
| T24 | Build splash screen with Fitup logo + animation | Frontend | Not Started | P0 | Lottie animation |
| T25 | Build placeholder screens for all 5 bottom nav tabs | Frontend | Not Started | P0 | Basic scaffold |
| T26 | Build shared bottom navigation bar with animations | Frontend | Not Started | P0 | Neon active indicator |

### Week 3: Design System Polish & Review

| ID | Task | Agent | Status | Priority | Notes |
|----|------|-------|--------|----------|-------|
| T27 | Write Firestore security rules (initial) | Backend | Not Started | P0 | |
| T28 | Set up GitHub Actions CI (flutter analyze + test) | Orchestrator | Not Started | P1 | |
| T29 | Create .env configuration for API keys | Orchestrator | Not Started | P0 | |
| T30 | Design system review - ensure all widgets match Stitch designs | Frontend | Not Started | P0 | Compare with screenshots |
| T31 | Run flutter analyze - fix all warnings | Orchestrator | Not Started | P0 | |
| T32 | Run flutter test - all tests pass | Orchestrator | Not Started | P0 | |
| T33 | Build APK and test on Android device/emulator | Orchestrator | Not Started | P1 | |
| T34 | Build iOS and test on simulator | Orchestrator | Not Started | P1 | |

---

## Blockers
- None yet (update as they arise)

## Definition of Done for Phase 0
- [ ] Flutter project builds for Android, iOS, and Web without errors
- [ ] Clean architecture folder structure in place
- [ ] All shared widgets built and match design system
- [ ] Firebase connected (Auth + Firestore)
- [ ] Riverpod + get_it configured
- [ ] go_router with bottom nav working
- [ ] Offline database (Drift) initialized
- [ ] CI pipeline running on push
- [ ] All Stitch UI screenshots saved in docs/ui_screenshots/

---

## Next Phase Preview: Phase 1 - Auth, Profile & Home (Weeks 4-6)
- Google Sign-In and Email/Password authentication
- Guided onboarding wizard (5-step)
- Profile page with user preferences
- Home dashboard with module summary cards
- Fitcoins balance display
