# Fitup - Step by Step Start Guide
## For someone who knows coding but is new to Flutter

---

# PHASE 0 — WEEK 1
## YOUR TASK FOR TODAY: Verify setup + Create the project

---

## ✅ STEP 1: Verify Flutter works (5 minutes)

Open your Terminal (Mac) or Command Prompt (Windows) and run:

```bash
flutter --version
```

You should see something like:
```
Flutter 3.x.x • channel stable
Dart 3.x.x
```

Then run:
```bash
flutter doctor
```

This checks your environment. You need to see green checkmarks for:
- ✅ Flutter
- ✅ Android toolchain (Android Studio or SDK)
- ✅ Xcode (Mac only, for iOS)

**If you see red X or warnings:** Share the output with me and I'll fix it for you.

---

## ✅ STEP 2: Create the Flutter Project (3 minutes)

In Terminal, navigate to where you want your project to live, then run:

```bash
flutter create fitup --org com.ivl.fitup --platforms android,ios,web
```

> **What this does:** Creates a new Flutter project called "fitup" with your company identifier.
> Think of it like `npm init` or `git init` but for Flutter. It creates the boilerplate project structure.

Then open it in Cursor:
```bash
cd fitup
cursor .
```

---

## ✅ STEP 3: Copy Your Agent Files Into The Project (5 minutes)

Your agent files are already created in the Fitup folder. Now you need to copy them into the new Flutter project:

**Files to copy FROM** `Fitup/` folder **INTO** your new `fitup/` Flutter project:

| From | To |
|------|----|
| `Fitup/.cursorrules` | `fitup/.cursorrules` |
| `Fitup/.cursor/agents/agent_orchestrator.md` | `fitup/.cursor/agents/agent_orchestrator.md` |
| `Fitup/.cursor/agents/agent_frontend.md` | `fitup/.cursor/agents/agent_frontend.md` |
| `Fitup/.cursor/agents/agent_backend.md` | `fitup/.cursor/agents/agent_backend.md` |
| `Fitup/docs/` (whole folder) | `fitup/docs/` |

> **Why:** Cursor auto-detects `.cursorrules` in your project root. The agent files in `.cursor/agents/` become referenceable with `@` in Cursor chat.

---

## ✅ STEP 4: Set Up Firebase (20 minutes)

This is the backend for your app. Do this BEFORE any coding.

### 4a. Create Firebase Project
1. Go to → https://console.firebase.google.com
2. Click **"Add project"**
3. Name it: `fitup-app`
4. Enable Google Analytics: **Yes**
5. Click through and wait for project to be created

### 4b. Enable Authentication
1. Left sidebar → **Build → Authentication**
2. Click **"Get started"**
3. Click **"Google"** → Enable it → Set your support email → Save
4. Click **"Email/Password"** → Enable it → Save

### 4c. Enable Firestore Database
1. Left sidebar → **Build → Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (we'll add security rules later)
4. Choose a location (pick `asia-south1` for India, or closest region to your users)
5. Click Done

### 4d. Add Android App to Firebase
1. In Firebase console, click the **Android icon** ( </> or Android robot icon)
2. Android package name: `com.ivl.fitup`
3. App nickname: `Fitup Android`
4. Click **"Register app"**
5. Download `google-services.json`
6. Place it here: `fitup/android/app/google-services.json`

### 4e. Add iOS App to Firebase
1. Back in Firebase console, click **"Add app"** → iOS icon
2. iOS bundle ID: `com.ivl.fitup`
3. App nickname: `Fitup iOS`
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. In Cursor, find `fitup/ios/Runner/` folder
7. Drag `GoogleService-Info.plist` into that folder

### 4f. Add Web App to Firebase
1. Back in Firebase console, click **"Add app"** → Web icon `</>`
2. App nickname: `Fitup Web`
3. Check **"Also set up Firebase Hosting"** → Next
4. You'll see a `firebaseConfig` object with keys like apiKey, authDomain, etc.
5. **COPY THIS** — you'll need it in a later step

---

## ✅ STEP 5: First Cursor Session — Set Up pubspec.yaml (10 minutes)

> **What is pubspec.yaml?** In Flutter, this is like `package.json` in Node.js. It lists all your dependencies (packages/libraries). Every package you want to use goes here.

1. Open Cursor, make sure you're in the `fitup` project
2. Press `Cmd+L` (Mac) or `Ctrl+L` (Windows) to open Chat
3. Copy and paste this EXACT message:

---
**PASTE THIS INTO CURSOR CHAT:**
```
@.cursorrules

I need you to replace the contents of pubspec.yaml with the complete dependency list for the Fitup project. Use exactly the packages specified in the .cursorrules file under "KEY PACKAGES".

Also update:
- name: fitup
- description: Fitup - Holistic Health AI
- version: 1.0.0+1

Make sure flutter sdk constraints are set to >=3.0.0 <4.0.0
```
---

4. Cursor will show you the changes to make. Review them and accept.

5. Once pubspec.yaml is updated, go to Terminal and run:
```bash
flutter pub get
```

> **What this does:** Downloads all the packages. Like `npm install`. You'll see a lot of packages being fetched. This is normal.

---

## ✅ STEP 6: First Cursor Session — Create Folder Structure (15 minutes)

> **What is this?** Flutter puts all app code in `lib/`. Right now it just has `main.dart`. We need to create the clean architecture folder structure before any agent writes code.

In Cursor Chat, paste this:

---
**PASTE THIS INTO CURSOR CHAT:**
```
@.cursorrules

Create the complete clean architecture folder structure inside the lib/ folder as specified in the .cursorrules file.

Create these folders (with a .gitkeep file in each empty folder):
- lib/core/constants/
- lib/core/theme/
- lib/core/utils/
- lib/core/error/
- lib/core/di/
- lib/core/router/
- lib/core/widgets/
- lib/features/auth/data/models/
- lib/features/auth/data/datasources/
- lib/features/auth/data/repositories/
- lib/features/auth/domain/entities/
- lib/features/auth/domain/repositories/
- lib/features/auth/domain/usecases/
- lib/features/auth/presentation/screens/
- lib/features/auth/presentation/widgets/
- lib/features/auth/presentation/providers/
- lib/features/activity/ (same sub-structure as auth)
- lib/features/diet/ (same sub-structure)
- lib/features/workout/ (same sub-structure)
- lib/features/health/ (same sub-structure)
- lib/features/mental_wellbeing/ (same sub-structure)
- lib/features/community/ (same sub-structure)
- lib/features/profile/ (same sub-structure)
- lib/features/home/ (same sub-structure)
- lib/features/fitcoins/ (same sub-structure)
- lib/services/
- lib/shared/widgets/
- lib/shared/models/
- lib/shared/extensions/

Also update main.dart to be a minimal placeholder that just shows a blank dark screen (#0A0E21) with the text "Fitup" in white. We'll build the real app incrementally.
```
---

7. Accept the changes Cursor suggests.

---

## ✅ STEP 7: Verify the App Runs (5 minutes)

Start an Android emulator or connect your phone, then run:

```bash
flutter run
```

> **What you should see:** A black/dark screen with "Fitup" text. That's it. That means everything is wired up correctly.

If it runs: 🎉 **Phase 0, Week 1 is done.**

If it errors: Copy the error and share it with me — I'll fix it.

---

# WHAT COMES NEXT (Phase 0 — Week 2)

Once you confirm the app runs, tell me and I'll give you the exact Cursor prompts for:

1. Setting up the design system (colors, fonts, theme) — Frontend Agent
2. Setting up Firebase initialization — Backend Agent
3. Creating the GlassCard and NeonButton shared widgets — Frontend Agent

**But first: Start designing in Google Stitch NOW (in parallel)**

While Cursor is doing the above, open Google Stitch and start designing your screens. The more screens you complete, the faster the Frontend Agent can build them.

**Stitch prompt template to use:**
```
Design a mobile app screen for a holistic health app called "Fitup".
Design language: dark background (#0A0E21), glassmorphism cards with blur effect,
neon cyan (#00E5FF) and electric blue (#3D5AFE) accents, neon gradient buttons,
modern clean fitness aesthetic similar to a premium health tracking app.

Screen: [describe the specific screen, e.g., "Home dashboard showing glass cards
for Activity, Diet, Workout, Health, and Mental Wellbeing modules with daily stats"]
```

---

# CHEAT SHEET: Flutter Terms You'll See

| Flutter Term | Equivalent You Know |
|-------------|---------------------|
| `pubspec.yaml` | `package.json` |
| `flutter pub get` | `npm install` |
| `flutter run` | `npm start` / `node app.js` |
| `Widget` | UI Component / React Component |
| `StatelessWidget` | Functional Component (no state) |
| `StatefulWidget` | Class Component (with state) |
| `lib/` | `src/` folder |
| `Dart` | The programming language (like TypeScript) |
| `Provider/Riverpod` | Redux / Zustand / Context |
| `go_router` | React Router |
| `BuildContext` | Component's rendering context |
| `Scaffold` | Page layout with AppBar + Body |
| `Column/Row` | Flexbox column/row |
| `Expanded` | `flex: 1` in CSS |
| `SizedBox` | Spacing div |

---

# KEY RULE TO REMEMBER

When using Cursor agents:
- **Always start your message with** `@.cursorrules` — this gives the agent the full project context
- **Then add** `@.cursor/agents/agent_frontend.md` OR `@agent_backend.md` for specialist work
- **One tab per agent** — keep them separate to maintain context
