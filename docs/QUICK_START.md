# Fitup - Quick Start Guide
## Your First Day of Development

---

## Before You Write Any Code

### 1. Design First (Google Stitch)
Open Google Stitch and design these screens first. Save screenshots into the corresponding folders:

```
docs/ui_screenshots/
  onboarding/
    01_splash.png
    02_welcome.png
    03_goal_selection.png
    04_body_metrics.png
    05_diet_preferences.png
    06_fitness_level.png
  home/
    01_dashboard.png
    02_dashboard_scrolled.png
  activity/
    01_activity_summary.png
    02_tracking_live.png
    03_activity_complete.png
    04_activity_history.png
  diet/
    01_diet_summary.png
    02_log_meal.png
    03_food_search.png
    04_water_tracker.png
  workout/
    01_workout_library.png
    02_workout_plan.png
    03_active_workout.png
  health_vitals/
    01_vitals_dashboard.png
    02_vital_detail.png
    03_lab_upload.png
  mental_wellbeing/
    01_wellbeing_home.png
    02_mood_checkin.png
    03_breathing_exercise.png
  profile/
    01_profile.png
    02_settings.png
  common/
    01_bottom_nav.png
    02_glass_card.png
    03_neon_buttons.png
```

**Stitch Prompt Tips:**
- Always mention: "dark background #0A0E21, neon cyan accents, glassmorphism cards, modern health/fitness app"
- Be specific about data shown on each screen
- Generate multiple variants and pick the best

### 2. Firebase Setup
1. Go to https://console.firebase.google.com
2. Create project: `fitup-app`
3. Enable Authentication → Google Sign-In + Email/Password
4. Create Firestore Database (start in test mode, we'll add rules later)
5. Download `google-services.json` → place in `android/app/`
6. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 3. Project Setup
```bash
# Create Flutter project
flutter create fitup --org com.ivl.fitup --platforms android,ios,web
cd fitup

# Copy the .cursorrules and .cursor/ folder into the project root
# Copy the docs/ folder into the project root

# Open in Cursor
cursor .
```

---

## Your First Cursor Session

### Step 1: Open Orchestrator Chat
Press `Cmd+L` (Mac) or `Ctrl+L` (Windows) and type:

```
@.cursorrules @.cursor/agents/agent_orchestrator.md

I'm starting Phase 0. Please:
1. Set up the complete folder structure as defined in .cursorrules
2. Configure pubspec.yaml with all the listed dependencies
3. Create the basic main.dart with ProviderScope and MaterialApp
```

### Step 2: Open Backend Agent Chat (new tab)
```
@.cursorrules @.cursor/agents/agent_backend.md

Set up the core infrastructure:
1. Firebase initialization in lib/core/di/
2. Riverpod code generation setup
3. get_it dependency injection container
4. Base Failure classes in lib/core/error/
5. ConnectivityService in lib/services/
```

### Step 3: Open Frontend Agent Chat (new tab)
```
@.cursorrules @.cursor/agents/agent_frontend.md

Build the design system:
1. AppColors class with all neon fluidic colors
2. AppTextStyles with Poppins + Inter fonts
3. AppTheme (dark theme as default)
4. GlassCard widget
5. NeonButton widget
6. GradientAppBar widget
7. Bottom navigation bar with 5 tabs

Reference screenshots in docs/ui_screenshots/common/ if available.
```

### Step 4: Integration
Once both finish, go back to Orchestrator:
```
@.cursor/agents/agent_orchestrator.md

Both agents are done. Please:
1. Wire up go_router with the bottom navigation
2. Set up placeholder screens for each tab
3. Run flutter analyze and fix any issues
4. Verify the app builds and runs
```

---

## Tech Stack Summary

| Layer | Choice | Why |
|-------|--------|-----|
| **Framework** | Flutter 3.x | Single codebase for Android, iOS, Web |
| **State** | Riverpod 2.x | Less boilerplate, compile-safe, great for solo dev |
| **Backend** | Firebase → Supabase (later) | Zero server mgmt now, PostgreSQL flexibility later |
| **AI** | Gemini 2.0 Flash/Pro | Multimodal, fast, good pricing |
| **Maps** | Google Maps SDK | Best route tracking and polylines |
| **Health** | Health Connect + HealthKit | Official platform APIs |
| **Local DB** | Drift (SQLite) | Offline-first, type-safe |
| **Subscriptions** | RevenueCat | Handles iOS/Android billing complexity |
| **CI/CD** | GitHub Actions + Fastlane | Automated builds and store deployment |
| **Design** | Google Stitch | AI-generated UI mockups |
| **IDE** | Cursor (multi-agent) | AI-assisted parallel development |
| **Review** | Claude Code | Complex debugging and architecture |

---

## Key Architectural Decisions

1. **Repository Pattern Everywhere**: Every data operation goes through an abstract interface. This lets us swap Firebase for Supabase without touching UI code.

2. **Offline-First**: All writes go to local SQLite first, then sync to Firebase. Users in areas with poor connectivity (outdoor runs) won't lose data.

3. **Feature Flags**: Firebase Remote Config toggles incomplete features. Ship often behind flags.

4. **No Medical Claims**: AI responses always use hedging language. We inform, never diagnose.

5. **Modular Architecture**: Each health module is a self-contained feature folder. Modules communicate through shared services, never directly.
