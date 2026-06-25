# Fitup — Holistic Health AI

Flutter app for Android, iOS, and Web — holistic health tracking with AI insights via Gemini.

**Live web app:** https://fitup-f5f56.web.app

## Features

- **Activity** — GPS tracking, step counts, daily/weekly goals (mobile only)
- **Diet** — meal logging, photo capture, barcode scan, macro tracking
- **Workout** — strength + cardio plans, exercise library
- **Health & Vitals** — lab scans, vitals tracking via Health Connect / HealthKit
- **Mental Wellbeing** — mood tracking, surveys, meditation, breathing exercises
- **Community** — challenges, leaderboards, achievements
- **Fitcoins** — gamified rewards
- **AI Coach** — Gemini-powered holistic plans + insights

## Tech Stack

- Flutter 3.x + Dart
- Riverpod 2.x (state management, code-generated providers)
- Firebase (Auth, Firestore, Functions, Storage, Hosting)
- Gemini 2.0 Flash + 1.5 Pro (AI routing per task)
- Google Maps + Health Connect / HealthKit (mobile)
- Drift (SQLite) — offline-first local storage (mobile only)
- go_router, get_it + injectable, dartz, envied

## Architecture

Clean Architecture with strict layer separation:

```
lib/
  core/          → theme, constants, DI, router, error handling
  features/      → activity | diet | workout | health | mental | community | fitcoins | profile | home | auth
                   each with data/ domain/ presentation/
  services/      → AI (Gemini), GPS, Health Connect/HealthKit, notifications
  shared/        → reusable widgets, utils
```

Layer rules: `presentation → domain only` · `domain` has no external deps · `data` implements domain interfaces.

## Setup (clone and run locally)

Excluded from the repo for security: `.env`, `lib/firebase_options.dart`,
`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, and
all `*.g.dart` / `*.freezed.dart` codegen output.

```bash
# 1. Install Flutter 3.x and Dart 3.x
flutter --version

# 2. Get packages
cd fitup
flutter pub get

# 3. Create .env from the template and add your API keys
cp .env.example .env
# Edit .env — set GEMINI_API_KEY and GOOGLE_MAPS_API_KEY

# 4. Set up Firebase (see https://firebase.google.com/docs/flutter/setup)
#    This generates lib/firebase_options.dart + platform configs:
dart pub global activate flutterfire_cli
flutterfire configure

# 5. Run code generation (riverpod, freezed, injectable, envied, drift)
dart run build_runner build --delete-conflicting-outputs

# 6. Run
flutter run                    # mobile (Android/iOS)
flutter run -d chrome          # web
```

## Build for web + deploy

```bash
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting --project <your-project-id>
```

CSP and hosting headers are configured in `firebase.json` (one level up from `fitup/`).

## Project Status

- Phases 0–9.2 complete (full feature set + launch hardening).
- Pre-launch checklist: web bundle size optimization (P9-7), Firebase rules deploy (P9-8), Android release signing (P9-9).
- See `docs/MASTER_ROADMAP.md` and `docs/context/PROJECT_STATE.md` for detail.

## License

Copyright © 2026 Sumeet Gupta. All rights reserved.
