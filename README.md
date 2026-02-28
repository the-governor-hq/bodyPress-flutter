# BodyPress

[![CI — Test & Build APK](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml)

A cross-platform Flutter application that aggregates physiological, environmental, and behavioural data from device sensors, then synthesises a daily first-person narrative — a journal written by the user's body.

<img width="300" alt="image" src="https://github.com/user-attachments/assets/83c0a31e-1cfe-48e3-9478-9fcbf6c12dcc" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/4a6de629-54b0-40f4-af2a-b8650b305fd2" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/7b58bd67-4dc1-4cd4-88a7-6a177d931bb1" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/1c07cc5f-6dfd-4f66-9294-19f1bf20e8d8" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/4b7bb0b1-2f92-40b1-a170-49a67ac802c8" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/8834a150-3d16-4fcc-bb7f-a184a9b91c48" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/b76caba3-f7ee-449f-ab20-9795bbcff717" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/ce5c09cf-0021-4f67-bb28-31bc0b6fcdfe" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/4f7cb624-64e7-4728-a1d4-ea87a914cf15" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/3218e319-f647-4b30-8785-f6bf38256e6e" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/f44194ea-0f20-4805-8744-a85c1f80f844" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/14dd1b37-20f3-412b-aa8a-8521633e7488" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/d009636a-4713-48a2-b62a-81ec479cc320" />
<img width="300" alt="image" src="https://github.com/user-attachments/assets/86b6c9a9-30af-4715-a62d-9a62e11e7d16" />

## Concept

BodyPress treats the human body as an observable system. Each day the app collects objective signals (heart rate, step count, sleep duration, ambient temperature, air quality index, UV exposure, calendar load) and produces a structured narrative that surfaces correlations a user might otherwise miss — e.g. poor sleep preceding elevated resting heart rate, or high AQI days correlating with reduced step counts.

The interface is modelled on a paginated blog rather than a dashboard. The hypothesis is that narrative framing increases engagement with personal biometrics compared to raw numbers alone.

## Data sources

| Domain             | Sensors / APIs                                       | Read                                                       | Write |
| ------------------ | ---------------------------------------------------- | ---------------------------------------------------------- | ----- |
| **Movement**       | Accelerometer via Health Connect / HealthKit         | Steps, distance, calories, workouts                        | —     |
| **Cardiovascular** | Optical HR sensor via Health Connect / HealthKit     | Heart rate (resting, average)                              | —     |
| **Sleep**          | Device sleep tracking via Health Connect / HealthKit | Sleep duration, phases                                     | —     |
| **Environment**    | GPS → HTTP ambient-scan API                          | Temperature, humidity, AQI, UV, pressure, wind, conditions | —     |
| **Schedule**       | Device calendar (CalDAV)                             | Today's events                                             | —     |
| **Location**       | GPS (Geolocator)                                     | Coordinates (ephemeral, not stored)                        | —     |

GPS coordinates are used exclusively to query environmental data. No location history is recorded or transmitted.

## Architecture

```
lib/
├── core/
│   ├── background/
│   │   └── capture_executor.dart         # WorkManager callback for background captures
│   ├── models/
│   │   ├── body_blog_entry.dart          # BodyBlogEntry, BodySnapshot
│   │   ├── capture_entry.dart            # CaptureEntry + health/env/location sub-models
│   │   ├── ai_models.dart                # ChatMessage, ChatCompletionRequest/Response
│   │   └── background_capture_config.dart # Background capture scheduling config
│   ├── router/
│   │   └── app_router.dart               # GoRouter config (3-tab shell + standalone routes)
│   ├── services/
│   │   ├── body_blog_service.dart        # Smart refresh orchestrator — instant / incremental / cold-start
│   │   ├── journal_ai_service.dart       # Prompt building + AI call + JSON parsing → JournalAiResult
│   │   ├── ai_service.dart               # HTTP client for ai.governor-hq.com
│   │   ├── ai_service_provider.dart      # Riverpod provider for AiService
│   │   ├── local_db_service.dart         # SQLite (sqflite) — entries, captures, settings
│   │   ├── capture_service.dart          # Multi-source data collection → CaptureEntry
│   │   ├── background_capture_service.dart # WorkManager scheduler (quiet hours, battery-aware)
│   │   ├── context_window_service.dart   # 7-day rolling plain-text context builder
│   │   ├── health_service.dart           # HealthKit / Health Connect abstraction
│   │   ├── location_service.dart         # Geolocator wrapper
│   │   ├── ambient_scan_service.dart     # Environment API client
│   │   ├── gps_metrics_service.dart      # Real-time GPS metrics (speed, altitude)
│   │   ├── calendar_service.dart         # Device calendar read
│   │   ├── notification_service.dart     # Local notification scheduling
│   │   └── permission_service.dart       # Permission orchestration
│   └── theme/
│       └── app_theme.dart                # Material 3 theming (light + dark)
├── features/
│   ├── onboarding/                       # Step-by-step permission flow
│   ├── body_blog/                        # Main screen — paginated journal
│   ├── journal/                          # Journal tab (wraps BodyBlogScreen)
│   ├── capture/                          # Manual capture screen with data source toggles
│   ├── patterns/                         # Patterns & trends view
│   ├── home/                             # Debug panel (raw sensor readouts)
│   ├── shell/                            # AppShell (3-tab StatefulShellRoute) + DebugScreen
│   ├── ai_test/                          # AI playground / testing
│   ├── environment/                      # Detailed environment view
│   ├── health/
│   ├── location/
│   ├── calendar/
│   └── permissions/                      # Legacy (superseded by onboarding)
└── main.dart
```

### Key abstractions

- **`BodyBlogService`** — Orchestrates data collection, AI enrichment, and persistence for daily journal entries. Uses a **smart refresh** strategy: returns persisted entries instantly when no new data exists, runs AI only when unprocessed captures are available, and supports explicit full refresh via user action.
- **`JournalAiService`** — Builds a structured prompt from the day's `CaptureEntry` list (preferred) or a `BodySnapshot` (fallback), calls `AiService`, and parses the model's JSON response into a `JournalAiResult`.
- **`JournalAiResult`** — Parsed AI output: `headline`, `summary`, `fullBody`, `mood`, `moodEmoji`, `tags`.
- **`BodyBlogEntry`** — Immutable value object containing date, headline, summary, full body text, mood, tags, optional user note, optional user mood emoji, `aiGenerated` flag, and the raw `BodySnapshot`.
- **`BodySnapshot`** — Flat struct of all collected metrics for a given day. Serialisation-ready for persistence and AI prompt context.
- **`CaptureEntry`** — A comprehensive snapshot of the user's state at a moment in time (health, environment, location, calendar). Includes an `isProcessed` flag and `processedAt` timestamp to track whether the AI has consumed it.
- **`LocalDbService`** — SQLite CRUD for entries, captures, and settings. Provides `loadUnprocessedCapturesForDate()` and `markCapturesProcessed()` for the smart refresh pipeline.

### Stack

| Layer            | Library            | Purpose                                    |
| ---------------- | ------------------ | ------------------------------------------ |
| State management | `flutter_riverpod` | Dependency injection, reactive state       |
| Routing          | `go_router`        | Declarative navigation                     |
| Health           | `health`           | Cross-platform HealthKit / Health Connect  |
| Location         | `geolocator`       | GPS coordinates                            |
| Calendar         | `device_calendar`  | CalDAV read/write                          |
| HTTP             | `http`             | Ambient-scan API calls                     |
| Typography       | `google_fonts`     | Inter (body), Playfair Display (headlines) |
| Formatting       | `intl`             | Date formatting                            |
| Persistence      | `sqflite` + `path` | SQLite local storage for daily entries     |

## Screens

1. **Onboarding** — Step-by-step permission flow. Each permission (location, health, calendar) is presented on its own page with an explanation of why it is needed and a privacy note. All steps are skippable.
2. **Journal** (Tab 0, `/`) — Paginated journal. Swipe between days. Each page shows date, inferred mood, headline, summary, data tags, a stat glance bar, and a "Read full entry" link. Today's page includes a **"Refresh day"** button that triggers a full sensor + AI refresh. Pull-to-refresh also works on the today card.
3. **Journal Detail** — Full narrative view. Sections: Sleep, Movement, Heart, Environment, Agenda. Includes AI regeneration button and mood/note editor.
4. **Patterns** (Tab 1) — Trends and pattern analysis.
5. **Capture** (Tab 2) — Manual capture screen with toggleable data sources (health, environment, location, calendar).
6. **Debug Panel** (`/debug`) — Raw sensor readout: all health metrics, GPS coordinates, ambient data, calendar events. Accessible via the bug icon on the journal screen.
7. **Environment Detail** (`/environment`) — Expanded environmental data.

## AI journal generation

### Smart refresh strategy

The journal avoids unnecessary sensor reads and AI calls. Each day is created once and updated only when new data arrives:

```
BodyBlogService.getTodayEntry()   ← called on every home page visit
  │
  ├─ 1. INSTANT (fast path)
  │     persisted entry exists + 0 unprocessed captures for today
  │     → return entry immediately  (no sensors, no AI, no network)
  │
  ├─ 2. INCREMENTAL UPDATE
  │     persisted entry exists + N unprocessed captures
  │     → _applyAi(captures=unprocessed only)  → persist
  │     → markCapturesProcessed(ids)
  │     → return updated entry
  │
  └─ 3. COLD START (first visit of the day)
        no persisted entry
        → _collectSnapshot()  (live sensors)
        → _compose()  (local template)
        → _applyAi()  (AI enrichment)
        → persist + markCapturesProcessed(all today)
        → return entry
```

### Explicit refresh

```
BodyBlogService.refreshTodayEntry()   ← user taps "Refresh day" button
  → _collectSnapshot()  (fresh sensors)
  → _compose()  (preserve user note & mood)
  → _applyAi()  (full AI pass with all captures)
  → persist + markCapturesProcessed(all today)
```

### Capture processing lifecycle

```
Capture created (manual or background)
  └─ is_processed = 0, processed_at = null

getTodayEntry() detects unprocessed captures
  └─ sends them to AI
  └─ on success: markCapturesProcessed(ids)
        └─ is_processed = 1, processed_at = now

Next getTodayEntry() call
  └─ 0 unprocessed captures → instant return (no AI)
```

### AI pipeline detail

```
_applyAi(date, entry, snapshotFallback, [captureOverride])
  └─ captureOverride ?? loadCapturesForDate()
  │
  ├─ captures exist? ─── JournalAiService.generate(captures)
  │                           └─ _buildCapturesPrompt()  (chronological)
  │
  └─ no captures? ───── JournalAiService.generate(snapshotFallback)
                              └─ _buildSnapshotPrompt()  (single snapshot)
  │
  └─ AiService.ask(prompt, systemPrompt)
        └─ POST ai.governor-hq.com  →  JSON response
        └─ JournalAiResult.fromJson()
        └─ entry.copyWith(headline, summary, fullBody, mood, …, aiGenerated: true)
  │
  └─ timeout / error  →  original template entry returned unchanged
```

**System prompt** — the model is instructed to write in first-person as "the body speaking to its person": warm, poetic, data-grounded, never clinical, never giving medical advice.

**Timeouts** — `loadCapturesForDate` is capped at 5 s; the AI call at 45 s. Any failure (network, parse error, empty response) falls back to the local template with no visible error.

**`aiGenerated` flag** — set to `true` on the persisted `BodyBlogEntry` when AI enrichment succeeds. Stored in SQLite (schema v6) so the ✦ badge survives app restarts.

**`regenerateWithAi(date)`** — public method on `BodyBlogService` that forces a fresh AI pass for any date. Used by the journal detail screen. Also marks all captures for that date as processed.

## Mood inference (v1 — heuristic)

```
sleep ≥ 7h AND steps ≥ 5000 AND HR > 0  →  energised
sleep < 5h                                →  tired
steps ≥ 8000                              →  active
AQI > 100                                 →  cautious
sleep ≥ 7h                                →  rested
steps = 0 AND calories = 0               →  quiet
default                                   →  calm
```

This will be replaced by a classifier or LLM prompt once sufficient labelled data exists.

## Principles

- **No fake data.** If a sensor is unavailable, the value is zero or null — never a plausible-looking placeholder. See `CODING_PRINCIPLES.md`.
- **No location tracking.** GPS is read once, used to fetch environment data, then discarded.
- **Read-only health access.** The app never writes to HealthKit or Health Connect.
- **Graceful degradation.** Every data fetch has a 5–15 s timeout. The app never freezes waiting for a sensor.

## Roadmap

### Near-term

- [x] LLM-backed narrative generation — `JournalAiService` uses day's `CaptureEntry` list (or `BodySnapshot` fallback) as structured prompt context; falls back to local template on failure
- [x] Local persistence of daily entries (SQLite via sqflite)
- [x] 7-day rolling context window — plain-text summary of last 7 DB entries, shown in debug panel + clipboard-ready for LLM prompts
- [x] User annotations — free-text note per day, stored in SQLite, shown in journal detail
- [x] Smart refresh — instant display of persisted entries; AI runs only when unprocessed captures exist; captures marked as processed after AI consumption
- [x] Background captures via WorkManager with quiet hours and battery awareness
- [x] Manual capture screen with configurable data source toggles
- [x] Explicit "Refresh day" button for user-triggered full sensor + AI refresh

### Mid-term — BLE peripherals

- [ ] Bluetooth Low Energy device scanning and pairing
- [ ] Real-time data from BLE heart rate straps, pulse oximeters, smart scales
- [ ] Continuous background data collection via BLE characteristic subscriptions

### Mid-term — Home automation

- [ ] Integration with smart home protocols (Matter, HomeKit, MQTT)
- [ ] Physiological-state-driven rules:
  - Sleep detected → lower thermostat, dim lights
  - Wake detected → raise thermostat, start coffee machine
  - Elevated heart rate at rest → suggest environment adjustments
- [ ] Rule engine with user-defined triggers based on body + environment state

### Long-term

- [ ] On-device ML for mood/state classification
- [ ] Multi-user household awareness (BLE presence + individual health profiles)
- [ ] Wearable companion (Wear OS / watchOS) for glanceable daily narrative
- [ ] Export to structured health records (FHIR-compatible)

## Setup

### Prerequisites

- Flutter SDK ≥ 3.9.2
- iOS: Xcode 14+, deployment target iOS 14+
- Android: SDK 21+ (Android 5.0), Health Connect app for health data

### Install & run

```bash
flutter pub get
flutter run
```

### Platform configuration

#### iOS

Info.plist keys are pre-configured:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`
- `NSCalendarsUsageDescription`
- `NSMotionUsageDescription`

Enable HealthKit capability in Xcode: Runner target → Signing & Capabilities → + HealthKit.

#### Android

AndroidManifest.xml includes location, Health Connect, activity recognition, and calendar permissions. Health Connect app required on Android 13+.

## Development

## Development

### Quick start

```bash
flutter pub get

# Android emulator
flutter run -d emulator-5554

# iOS simulator
flutter run -d "iPhone 16"

# Or use the helper scripts
.\dev.ps1           # PowerShell (Windows)
./dev.sh             # Bash (macOS / Linux)
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

### Day-to-day workflow

```bash
# Static analysis — must pass with zero errors
flutter analyze

# Run the test suite
flutter test

# Format everything
dart format lib/
```

### Working with the journal pipeline

The journal system has three layers — understanding them prevents accidental slowdowns:

| Layer             | File                      | Responsibility                                        |
| ----------------- | ------------------------- | ----------------------------------------------------- |
| **Persistence**   | `local_db_service.dart`   | SQLite CRUD for entries, captures, settings           |
| **Orchestration** | `body_blog_service.dart`  | Smart refresh logic, sensor collection, AI enrichment |
| **AI**            | `journal_ai_service.dart` | Prompt building, API call, JSON parsing               |

**Key rule:** `getTodayEntry()` is called on every home page visit. It must be fast. If you change it, make sure the fast path (persisted entry + zero unprocessed captures) returns immediately with no I/O beyond two DB queries.

**Capture → Journal flow:**

1. Captures are created by `CaptureService` (manual) or `BackgroundCaptureService` (WorkManager)
2. Each capture starts with `is_processed = 0`
3. `getTodayEntry()` checks for unprocessed captures → runs AI only when needed
4. After AI success, `markCapturesProcessed()` sets `is_processed = 1`
5. Next call → zero unprocessed → instant return

**Testing the smart refresh locally:**

- Cold start: delete the app data or clear the DB via debug panel, then relaunch
- Incremental: create a manual capture via the Capture tab, switch to Journal tab — the entry should auto-update
- Instant: navigate away and back to Journal — no loader, no AI call

### Adding a new service

1. Create `lib/core/services/your_service.dart`
2. If it needs a Riverpod provider, add it in a `_provider.dart` file alongside
3. Wire it into `BodyBlogService` or the relevant feature screen
4. Update the architecture tree in this README

### Adding a new feature screen

1. Create `lib/features/your_feature/screens/your_screen.dart`
2. Add a route in `lib/core/router/app_router.dart`
3. If it's a top-level tab, add it to the `StatefulShellRoute` in the router

### Database migrations

Schema version is tracked in `local_db_service.dart` (`_schemaVersion`). To add a column:

1. Bump `_schemaVersion`
2. Add a new `if (oldVersion < N)` block in `_onUpgrade()`
3. Wrap `ALTER TABLE` in try/catch for duplicate-column safety (hot-restart resilience)

### Pre-commit checklist

- [ ] `flutter pub get` — no unresolved dependencies
- [ ] `dart format lib/` — formatter applied
- [ ] `flutter analyze` — 0 errors, 0 warnings (info-level lint is acceptable)
- [ ] `flutter test` — all tests pass
- [ ] New screens wired in `app_router.dart`
- [ ] Architecture tree and screen list in README updated
- [ ] Roadmap checkbox ticked if feature was planned
- [ ] No fake data — see `CODING_PRINCIPLES.md`

## Testing notes

The app displays only real sensor data. On emulators without Health Connect or HealthKit, health values will be zero. This is correct behaviour — see `CODING_PRINCIPLES.md`.

| Data source          | Emulator setup                                                |
| -------------------- | ------------------------------------------------------------- |
| **Health (Android)** | Install Health Connect app, add test data manually            |
| **Health (iOS)**     | Requires physical device — HealthKit unavailable in simulator |
| **Location**         | Set coordinates via emulator extended controls                |
| **Calendar**         | Add events in the device's calendar app                       |
| **Environment**      | Requires valid GPS coordinates to query the ambient-scan API  |

All data fetches have 5–15 s timeouts to prevent UI freezes.

## License

MIT
