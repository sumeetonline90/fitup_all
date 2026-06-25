# Fitup - Holistic Health AI
## Project Conventions for AI Agents

### Project Overview
Flutter app (Android + iOS + Web) — holistic health tracking with AI insights via Gemini.
Solo developer: Sumeet Gupta | IVL

### Current status (roadmap)
- **Phase 7.1** — ✅ Complete (Community & Fitcoins P1: C1–C4, Firestore rules in `firebase/`).
- **Phase 8** — ✅ Complete (Profile, Onboarding, Settings — ADR-025–029).
- **Phase 8.1** — ✅ Complete (P8-1–P8-4: profile sync semantics, account deletion cascade, onboarding draft, Storage rules).
- **Phase 9.1** — ✅ Complete (P9-1–P9-6 launch hardening).
- **Phase 9.2** — ✅ Complete (Activity & Health Sync Gap Fixes: GAP1–4). Ready for phone testing.
- **Pre-launch manual checklist** — NEXT: phone testing for P9-2, then P9-7 (web bundle size), P9-8 (firebase deploy rules), P9-9 (release signing).

### Tech Stack
- Flutter 3.x + Dart, Riverpod 2.x state management
- Firebase (Firestore, Auth, Functions, Storage) — repository pattern for future Supabase migration
- Gemini 2.0 Flash/Pro for AI, Google Maps for GPS, Health Connect + HealthKit
- Drift (SQLite) for offline-first local storage, go_router for navigation
- get_it + injectable for dependency injection, dartz for Either error handling

### Architecture — Clean Architecture (strict layer separation)
```
lib/
  core/          → theme, constants, DI, router, error handling, utils
  features/      → one folder per module, each with data/domain/presentation
  services/      → AI (Gemini), GPS, Health Connect/HealthKit, notifications, sync
  shared/        → reusable widgets, shared models, extensions
```

### Module List
activity | diet | workout | health | mental_wellbeing | community | profile | home | fitcoins | auth

### Layer Rules (never violate)
- presentation → domain only (never imports data layer or Firebase directly)
- domain → no external dependencies (pure Dart entities, abstract repos, use cases)
- data → implements domain interfaces (Firebase/Supabase/local DB live here)
- services → cross-cutting, imported by domain or presentation via DI

### Key Patterns
- Repository pattern: abstract interface in domain/, Firebase implementation in data/
- All errors use `Either<Failure, T>` from dartz
- All providers use `@riverpod` annotation (code generation)
- Offline-first: write to local Drift DB first, sync queue handles remote writes
- Feature flags via Firebase Remote Config (never ship broken features without a flag)

### Naming Conventions
- Files: snake_case → `meal_repository.dart`
- Classes: PascalCase → `MealRepository`
- Providers: end with `Provider` → `mealsProvider`
- Screens: end with `Screen` → `DietScreen`
- Widgets: descriptive PascalCase → `MacroRingChart`
- Models (Firestore DTOs): end with `Model` → `MealModel`
- Entities (pure Dart): no suffix → `Meal`

### Design System
- Dark theme default, background #0A0E21, cards #1A1F38
- Neon accents: cyan #00E5FF, magenta #FF006E, blue #3D5AFE, green #00E676
- Glassmorphism cards: BackdropFilter blur + semi-transparent background
- All colors/styles from `core/theme/` — never hardcode hex values
- Fonts: Poppins (headings) + Inter (body)

### Testing
- Unit tests for all repositories and providers
- Widget tests for critical flows (onboarding, activity tracking, meal logging)
- Use mocktail for mocks, fake_cloud_firestore for Firestore
- Test files mirror source: test/features/activity/ mirrors lib/features/activity/

### Important Constraints
- No `print()` — use logger service
- No hardcoded API keys — use environment config
- No medical diagnoses — AI uses hedging language only ("consider", "you may want to")
- No Firebase direct calls from UI — always go through repository
- GPS tracking must work offline
- All health data encrypted at rest
