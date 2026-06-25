# Fitup - Multi-Agent Development Workflow Guide
## How to Build Fitup Using Cursor + Claude Code

---

## OVERVIEW

You're using a **3-agent orchestration** model inside Cursor, with Claude Code as the final review layer.

```
                    ┌─────────────────┐
                    │   YOU (Sumeet)   │
                    │  Product Owner   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  ORCHESTRATOR   │ ◄── Cursor Main Chat / Composer
                    │  (Agent Main)   │     @.cursor/agents/agent_orchestrator.md
                    └──┬──────────┬───┘
                       │          │
            ┌──────────▼──┐  ┌───▼──────────┐
            │  FRONTEND   │  │   BACKEND    │
            │  AGENT      │  │   AGENT      │
            │             │  │              │
            │ UI/Screens  │  │ Firebase/API │
            │ Widgets     │  │ Models/Repos │
            │ Animations  │  │ Services     │
            └──────┬──────┘  └──────┬───────┘
                   │                │
                   └───────┬────────┘
                           │
                  ┌────────▼────────┐
                  │  CLAUDE CODE    │ ◄── Terminal (final review, complex debugging)
                  │  Final Review   │
                  └─────────────────┘
```

---

## STEP-BY-STEP: HOW TO USE IN CURSOR

### Step 1: Set Up Your Cursor Project

1. Open the Fitup Flutter project in Cursor
2. The `.cursorrules` file is auto-detected by Cursor and applies globally
3. The agent files in `.cursor/agents/` are used as context when you `@mention` them

### Step 2: Starting a Sprint

1. Open `docs/current_sprint.md` to see current tasks
2. Open Cursor Chat (Cmd+L or Ctrl+L)
3. Start by tagging the orchestrator:

```
@agent_orchestrator.md I'm starting Phase 1 Sprint 1.
Break down the Auth & Onboarding feature into Frontend and Backend tasks.
```

The orchestrator will produce a task breakdown.

### Step 3: Working with the Backend Agent

Open a NEW Cursor Chat tab (or use Composer) and say:

```
@agent_backend.md

## Task: Create Auth Module Data Layer
Create the following for the auth feature:
1. User entity (freezed) in lib/features/auth/domain/entities/user.dart
2. User model (Firestore DTO) in lib/features/auth/data/models/user_model.dart
3. Auth repository interface in lib/features/auth/domain/repositories/auth_repository.dart
4. Firebase auth repository in lib/features/auth/data/repositories/firebase_auth_repository.dart
5. Auth providers in lib/features/auth/presentation/providers/auth_providers.dart
6. Unit tests for the repository

Follow the repository pattern from your agent file.
```

### Step 4: Working with the Frontend Agent (in parallel)

Open ANOTHER Cursor Chat tab and say:

```
@agent_frontend.md

## Task: Build Onboarding Wizard Screens
Create the onboarding flow:
1. Welcome screen with app logo and "Get Started" neon button
2. Goal selection screen (weight loss, muscle gain, holistic wellness)
3. Body metrics input (height, weight, age, gender)
4. Diet preferences (veg, non-veg, vegan, keto)
5. Fitness level assessment (beginner, intermediate, expert)

Use mock data for now - backend will provide real providers.
Reference the neon fluidic design system from your agent file.
The UI screenshots are in: docs/ui_screenshots/onboarding/
```

### Step 5: Integration (Orchestrator)

Once both agents finish, switch back to the orchestrator chat:

```
@agent_orchestrator.md

Both agents completed their Auth tasks. Please:
1. Review the code both agents produced
2. Wire up the frontend onboarding screens to the backend auth providers
3. Add the onboarding routes to go_router
4. Register the auth repository in the DI container
5. Run flutter analyze and check for issues
```

### Step 6: Claude Code Final Review

Open your terminal and run Claude Code:

```bash
claude "Review the auth module I just built in the Fitup project.
Check for: architecture violations, missing error handling,
security issues in Firestore rules, and suggest any improvements.
Files are in lib/features/auth/"
```

---

## PARALLEL WORK PATTERNS

### Pattern 1: Module Development (Most Common)
```
Backend Agent: Creates models, repos, providers    ──►
Frontend Agent: Builds screens with mock data      ──► Both work in PARALLEL
Orchestrator: Integrates when both are done        ──► Sequential after both finish
```

### Pattern 2: Bug Fix
```
Orchestrator: Diagnoses which layer has the bug
Route to appropriate agent (Frontend or Backend)
Agent fixes → Orchestrator verifies
```

### Pattern 3: Cross-Module Feature (e.g., Holistic AI Insights)
```
Backend Agent: Creates AI service, prompt templates, cross-module data aggregation
Frontend Agent: Creates AI chat UI, insight cards, notification UI
Orchestrator: Wires everything together, tests cross-module data flow
Claude Code: Reviews AI prompt quality, optimizes response parsing
```

---

## CURSOR-SPECIFIC TIPS

### Using Composer (Multi-File Editing)
Cursor's Composer mode (Cmd+I) is ideal for:
- Creating an entire feature's file structure at once
- Cross-file refactoring (e.g., renaming a model field across model → repo → provider → UI)
- Tag the relevant agent file for context

### Using .cursorrules Effectively
- The `.cursorrules` file is loaded automatically into every Cursor chat
- It sets the coding standards ALL agents follow
- Update it if you change architectural decisions

### Context Management
- Each Cursor chat tab has its own context window
- Keep one tab per agent to maintain context
- If context gets too long, start a new tab and re-tag the agent file
- Use `@filename` to pull specific files into context when needed

### Keyboard Shortcuts
- `Cmd+L` / `Ctrl+L`: Open chat
- `Cmd+I` / `Ctrl+I`: Open Composer (multi-file)
- `Cmd+K` / `Ctrl+K`: Inline edit (quick fixes)
- `Tab`: Accept AI suggestion

---

## STITCH UI → FLUTTER WORKFLOW

When you design screens in Google Stitch:

1. **Export** the screen as a PNG/screenshot
2. **Save** to `docs/ui_screenshots/<module>/<screen_name>.png`
3. **Tell the Frontend Agent**:
```
@agent_frontend.md

Build this screen. Reference: docs/ui_screenshots/diet/meal_logging.png

Key elements I see:
- Glass card at top showing today's calorie summary
- Meal type selector (Breakfast/Lunch/Dinner/Snack) as horizontal pills
- Food search bar with barcode scanner icon
- List of logged items with swipe-to-delete
- Floating "Add Food" neon button at bottom
- Water intake ring at the bottom of the screen
```

4. The agent will build the screen matching your design
5. Review and iterate

---

## WHEN TO USE CLAUDE CODE vs CURSOR AGENTS

| Task | Use |
|------|-----|
| Building a new screen | Cursor → Frontend Agent |
| Creating data models & repos | Cursor → Backend Agent |
| Scaffolding a full module | Cursor → Orchestrator |
| Complex algorithm (calorie calc, stress score) | Claude Code |
| Debugging platform-specific issues (HealthKit, GPS) | Claude Code |
| Architecture refactoring | Claude Code |
| Writing Firestore security rules | Cursor → Backend Agent |
| Writing Cloud Functions | Claude Code (longer context) |
| Performance profiling & optimization | Claude Code |
| Generating test data & seeds | Cursor → Backend Agent |
| App Store listing copy & marketing | Claude Code or Cowork |

---

## DAILY DEVELOPMENT ROUTINE

```
Morning:
1. Check docs/current_sprint.md for today's tasks
2. Open Cursor with 3 chat tabs (Orchestrator, Frontend, Backend)
3. Ask Orchestrator to break down today's feature

Build Session:
4. Assign tasks to Frontend and Backend agents in parallel
5. Review outputs, iterate, integrate
6. Run flutter analyze + flutter test after each feature

End of Day:
7. Ask Orchestrator to update docs/current_sprint.md
8. Commit with descriptive message: git commit -m "feat(diet): add meal logging with barcode scanner"
9. Optional: Use Claude Code for end-of-day code review

Weekly:
10. Friday: Self-retrospective - what worked, what didn't
11. Update sprint plan for next week
12. Run full build: flutter build apk + flutter build ios
```

---

## TROUBLESHOOTING

### "Agent is producing code that doesn't follow the architecture"
→ Re-tag the agent file: `@agent_backend.md Remember to follow the repository pattern`

### "Frontend and Backend code don't connect"
→ Use Orchestrator to mediate: `@agent_orchestrator.md The frontend expects X but backend provides Y. Fix the interface.`

### "Context window is getting too large"
→ Start a new Cursor chat tab, re-tag the agent file, and reference only the specific files needed

### "Need to change a shared interface"
→ ALWAYS go through Orchestrator. Never let one agent change a shared interface without updating the other.

### "Build fails after agent changes"
→ Run `flutter analyze` first, share errors with Orchestrator to diagnose and fix
