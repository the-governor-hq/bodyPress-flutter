# BodyPress

[![CI — Download Build APK](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/the-governor-hq/bodyPress-flutter/actions/workflows/ci.yml)

Your body writes a journal every day — BodyPress reads it. A cross-platform Flutter app that collects physiological, environmental, and behavioural signals from device sensors, then synthesises them into a daily first-person narrative: a blog written _by_ your body, _for_ you.

<p>
  <img width="300" alt="Journal" src="https://github.com/user-attachments/assets/83c0a31e-1cfe-48e3-9478-9fcbf6c12dcc" />
  <img width="300" alt="Capture" src="https://github.com/user-attachments/assets/4a6de629-54b0-40f4-af2a-b8650b305fd2" />
  <img width="300" alt="Patterns" src="https://github.com/user-attachments/assets/7b58bd67-4dc1-4cd4-88a7-6a177d931bb1" />
  <img width="300" alt="Detail" src="https://github.com/user-attachments/assets/1c07cc5f-6dfd-4f66-9294-19f1bf20e8d8" />
</p>

<details>
<summary>More screenshots</summary>
<p>
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/ecee3855-2836-4e5b-a559-c9edac9166a7" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/4b7bb0b1-2f92-40b1-a170-49a67ac802c8" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/8834a150-3d16-4fcc-bb7f-a184a9b91c48" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/b76caba3-f7ee-449f-ab20-9795bbcff717" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/ce5c09cf-0021-4f67-bb28-31bc0b6fcdfe" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/4f7cb624-64e7-4728-a1d4-ea87a914cf15" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/3218e319-f647-4b30-8785-f6bf38256e6e" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/57cd41ac-3d52-43cf-9cac-da500b8caa3e" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/f44194ea-0f20-4805-8744-a85c1f80f844" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/14dd1b37-20f3-412b-aa8a-8521633e7488" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/d009636a-4713-48a2-b62a-81ec479cc320" />
  <img width="300" alt="image" src="https://github.com/user-attachments/assets/86b6c9a9-30af-4715-a62d-9a62e11e7d16" />
</p>
</details>

---

## Why BodyPress?

Most health apps show dashboards of numbers. BodyPress takes a different approach: it presents your biometrics as a _narrative_. The hypothesis is that story-framing surfaces correlations you'd otherwise miss — poor sleep preceding an elevated resting heart rate, high AQI days correlating with fewer steps — and that reading about yourself is more engaging than staring at charts.

Under the hood the app treats the human body as an observable system: collect objective signals throughout the day, feed them to an LLM, and get back a warm, first-person journal entry that reads as though your body is writing to you.

---

## Features

| Feature                 | Description                                                                                                                                       |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **AI Journal**          | Daily narrative generated from real sensor data — headline, mood, summary, full body text. Written in first-person ("your body speaking to you"). |
| **Smart Refresh**       | Persisted entries return instantly. AI runs only when new unprocessed captures exist. No redundant sensor reads or API calls.                     |
| **Background Captures** | WorkManager-based periodic data collection with quiet-hour and battery-awareness support.                                                         |
| **Manual Capture**      | On-demand snapshot with toggleable data sources (health, environment, location, calendar).                                                        |
| **Patterns & Trends**   | AI-derived insights aggregated from capture history — energy distribution, recurring themes, notable signals, recent moments timeline.            |
| **User Annotations**    | Free-text notes and mood emojis per day, persisted in SQLite alongside the AI-generated content.                                                  |
| **Onboarding**          | Step-by-step permission flow with per-permission explanations and privacy notes. Every step is skippable.                                         |
| **Dark & Light Themes** | Material 3 theming with system-mode detection.                                                                                                    |

---

## Data Sources

| Domain             | Sensor / API               | What's read                                                |
| ------------------ | -------------------------- | ---------------------------------------------------------- |
| **Movement**       | Health Connect / HealthKit | Steps, distance, calories, workouts                        |
| **Cardiovascular** | Optical HR sensor          | Resting & average heart rate                               |
| **Sleep**          | Device sleep tracking      | Duration, phases                                           |
| **Environment**    | GPS → ambient-scan API     | Temperature, humidity, AQI, UV, pressure, wind, conditions |
| **Schedule**       | Device calendar (CalDAV)   | Today's events                                             |
| **Location**       | GPS (Geolocator)           | Coordinates — ephemeral, never stored                      |

> **Privacy:** GPS is read once to fetch environmental data, then discarded. No location history is recorded or transmitted. Health data is read-only — the app never writes to HealthKit or Health Connect.

---

## Tech Stack

| Concern          | Library                       | Role                                                     |
| ---------------- | ----------------------------- | -------------------------------------------------------- |
| State management | `flutter_riverpod`            | DI + reactive state                                      |
| Routing          | `go_router`                   | Declarative navigation (3-tab shell + standalone routes) |
| Health           | `health`                      | Cross-platform HealthKit / Health Connect                |
| Location         | `geolocator`                  | GPS coordinates                                          |
| Calendar         | `device_calendar`             | CalDAV read                                              |
| HTTP             | `http`                        | Ambient-scan & AI API calls                              |
| Persistence      | `sqflite` + `path`            | Local SQLite (entries, captures, settings)               |
| Background       | `workmanager`                 | Periodic background captures                             |
| Notifications    | `flutter_local_notifications` | Daily reminders                                          |
| Typography       | `google_fonts`                | Inter (body) / Playfair Display (headlines)              |
| Formatting       | `intl`                        | Date/number formatting                                   |
| Config           | `flutter_dotenv`              | `.env` file support                                      |

---

## Getting Started

### Prerequisites

- Flutter SDK **≥ 3.9.2**
- **iOS:** Xcode 14+, deployment target iOS 14+
- **Android:** SDK 21+ (Android 5.0), Health Connect app for health data on Android 13+

### Install & run

```bash
flutter pub get
flutter run

# Or use the helper scripts
.\dev.ps1           # Windows (PowerShell)
./dev.sh            # macOS / Linux
```

### Platform configuration

<details>
<summary><strong>iOS</strong></summary>

Info.plist keys are pre-configured:

- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`
- `NSCalendarsUsageDescription`
- `NSMotionUsageDescription`

Enable HealthKit capability in Xcode: **Runner** target → **Signing & Capabilities** → **+ HealthKit**.

</details>

<details>
<summary><strong>Android</strong></summary>

`AndroidManifest.xml` includes permissions for location, Health Connect, activity recognition, and calendar. Health Connect app is required on Android 13+.

</details>

---

## Architecture

```
lib/
├── core/
│   ├── background/           # WorkManager callback (capture_executor.dart)
│   ├── models/               # Immutable domain objects
│   │   ├── body_blog_entry   #   BodyBlogEntry + BodySnapshot
│   │   ├── capture_entry     #   CaptureEntry + health/env/location sub-models
│   │   ├── capture_ai_metadata  # AI-derived tags, themes, energy level per capture
│   │   ├── ai_models         #   ChatMessage, request/response DTOs
│   │   └── background_capture_config
│   ├── router/               # GoRouter (3-tab shell + standalone routes)
│   ├── services/             # All business logic
│   │   ├── service_providers #   ★ Central Riverpod provider registry
│   │   ├── body_blog_service #   Smart-refresh orchestrator
│   │   ├── journal_ai_service  # Prompt → AI → JournalAiResult
│   │   ├── capture_metadata_service  # Per-capture background AI metadata
│   │   ├── ai_service        #   HTTP client for ai.governor-hq.com
│   │   ├── local_db_service  #   SQLite CRUD (schema v7)
│   │   ├── capture_service   #   Multi-source data → CaptureEntry
│   │   ├── background_capture_service  # WorkManager scheduler
│   │   ├── context_window_service  # 7-day rolling context builder
│   │   ├── health_service    #   HealthKit / Health Connect abstraction
│   │   ├── location_service  #   Geolocator wrapper
│   │   ├── ambient_scan_service  # Environment API
│   │   ├── gps_metrics_service   # Real-time GPS metrics
│   │   ├── calendar_service  #   Device calendar read
│   │   ├── notification_service  # Local notification scheduling
│   │   └── permission_service    # Permission orchestration
│   └── theme/                # Material 3 (light + dark)
├── features/
│   ├── onboarding/           # Step-by-step permission flow
│   ├── journal/              # Journal tab — paginated daily narrative
│   ├── body_blog/            # Underlying blog screen & widgets
│   ├── patterns/             # AI-derived trends & insights
│   ├── capture/              # Manual capture with data-source toggles
│   ├── shell/                # AppShell (3-tab nav) + DebugScreen
│   ├── environment/          # Detailed environment view
│   ├── shared/               # Reusable widgets
│   └── …                     # health, location, calendar, ai_test, home
└── main.dart                 # App entry point
```

### Key Abstractions

| Type                | Purpose                                                                                                                                                         |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BodyBlogEntry`     | Immutable day record: headline, summary, full text, mood, tags, user note, `aiGenerated` flag, raw `BodySnapshot`.                                              |
| `BodySnapshot`      | Flat struct of every collected metric for one day. Serialisation-ready for persistence and prompts.                                                             |
| `CaptureEntry`      | Point-in-time snapshot (health + env + location + calendar). Carries `isProcessed` / `processedAt` for the refresh pipeline, plus optional `CaptureAiMetadata`. |
| `CaptureAiMetadata` | AI-derived per-capture metadata: summary, themes, energy level, mood assessment, tags, notable signals. Stored as JSON in the `captures` table (schema v7).     |
| `JournalAiResult`   | Parsed AI output: headline, summary, full body, mood, mood emoji, tags.                                                                                         |

### Provider Architecture

All services are exposed as `Provider<T>` singletons via `service_providers.dart`. Screens consume them with `ref.read(someServiceProvider)`, which guarantees a single SQLite connection, makes every service replaceable in tests, and eliminates scattered state.

---

## How the AI Journal Works

### Smart Refresh Pipeline

```
getTodayEntry()                       ← called on every Journal visit
  │
  ├─ INSTANT  — persisted entry exists, 0 unprocessed captures
  │              → return immediately (no sensors, no AI, no network)
  │
  ├─ INCREMENTAL — persisted entry exists, N unprocessed captures
  │              → AI runs on new captures only → persist → mark processed
  │
  └─ COLD START — no entry for today
                 → collect sensors → local template → AI enrich → persist
```

### Capture → Journal Flow

1. Captures are created by `CaptureService` (manual) or `BackgroundCaptureService` (WorkManager).
2. Each starts with `is_processed = 0`.
3. `getTodayEntry()` checks for unprocessed captures → runs AI only when needed.
4. On success, `markCapturesProcessed()` flips the flag.
5. Next visit → zero unprocessed → instant return.

### AI Details

- **Endpoint:** `POST ai.governor-hq.com`
- **System prompt:** First-person voice — "the body speaking to its person." Warm, poetic, data-grounded. Never clinical, never medical advice.
- **Fallback:** On timeout (45 s) or parse error, the local template entry is returned unchanged.
- **`aiGenerated` flag:** Persisted in SQLite (schema v6) so the ✦ badge survives restarts.
- **`regenerateWithAi(date)`:** Force a fresh AI pass for any date from the journal detail screen.

### Mood Inference (v1 — Heuristic)

```
sleep ≥ 7 h  AND  steps ≥ 5 000  AND  HR > 0   →  energised
sleep < 5 h                                       →  tired
steps ≥ 8 000                                     →  active
AQI > 100                                         →  cautious
sleep ≥ 7 h                                       →  rested
steps = 0  AND  calories = 0                      →  quiet
default                                           →  calm
```

Will be replaced by a classifier or LLM prompt once sufficient labelled data exists.

---

## Screens

| #   | Screen             | Route               | Description                                                                                       |
| --- | ------------------ | ------------------- | ------------------------------------------------------------------------------------------------- |
| 1   | **Onboarding**     | `/onboarding`       | Permission flow — location, health, calendar. Every step skippable.                               |
| 2   | **Journal**        | `/journal` (Tab 0)  | Paginated daily blog. Swipe between days. Pull-to-refresh + "Refresh day" button on today's card. |
| 3   | **Journal Detail** | —                   | Full narrative: Sleep, Movement, Heart, Environment, Agenda. AI regeneration & mood/note editor.  |
| 4   | **Patterns**       | `/patterns` (Tab 1) | Energy distribution, top themes, keyword tags, notable signals, recent moments timeline.          |
| 5   | **Capture**        | `/capture` (Tab 2)  | Manual capture with toggleable data sources.                                                      |
| 6   | **Debug**          | `/debug`            | Raw sensor readouts — health metrics, GPS, ambient data, calendar events.                         |
| 7   | **Environment**    | `/environment`      | Expanded environmental data view.                                                                 |

---

## Development

### Day-to-day

```bash
flutter analyze          # static analysis — must pass with zero errors
flutter test             # run the test suite
dart format lib/         # format everything
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

### Working with the Journal Pipeline

The journal has three layers — understanding them prevents accidental slowdowns:

| Layer         | File                      | Responsibility                                  |
| ------------- | ------------------------- | ----------------------------------------------- |
| Persistence   | `local_db_service.dart`   | SQLite CRUD for entries, captures, settings     |
| Orchestration | `body_blog_service.dart`  | Smart refresh, sensor collection, AI enrichment |
| AI            | `journal_ai_service.dart` | Prompt building, API call, JSON parsing         |

**Key rule:** `getTodayEntry()` is called on every Journal visit. The fast path (persisted entry + zero unprocessed captures) must return with no I/O beyond two DB queries.

### Adding a New Service

1. Create `lib/core/services/your_service.dart`.
2. Add a Riverpod provider in a `_provider.dart` file alongside.
3. Wire into `BodyBlogService` or the relevant feature screen.

### Adding a New Feature Screen

1. Create `lib/features/your_feature/screens/your_screen.dart`.
2. Add a route in `lib/core/router/app_router.dart`.
3. For a top-level tab, add to the `StatefulShellRoute`.

### Database Migrations

Schema version lives in `local_db_service.dart` (`_schemaVersion`, currently **7**).

1. Bump `_schemaVersion`.
2. Add `if (oldVersion < N)` block in `_onUpgrade()`.
3. Wrap `ALTER TABLE` in try/catch for duplicate-column safety (hot-restart resilience).

### Testing on Emulators

| Data source      | Emulator setup                                                |
| ---------------- | ------------------------------------------------------------- |
| Health (Android) | Install Health Connect, add test data manually                |
| Health (iOS)     | Physical device required — HealthKit unavailable in simulator |
| Location         | Set coordinates via emulator extended controls                |
| Calendar         | Add events in the device calendar app                         |
| Environment      | Requires valid GPS to query ambient-scan API                  |

All data fetches have 5–15 s timeouts. The app shows zero/empty states for unavailable sensors — never fake data (see `CODING_PRINCIPLES.md`).

### Pre-commit Checklist

- [ ] `flutter pub get` — no unresolved deps
- [ ] `dart format lib/` — formatter applied
- [ ] `flutter analyze` — 0 errors, 0 warnings
- [ ] `flutter test` — all green
- [ ] New screens wired in `app_router.dart`
- [ ] README architecture tree & screen list updated
- [ ] Roadmap checkbox ticked if feature was planned
- [ ] No fake data

---

## Principles

- **No fake data.** Sensor unavailable → zero or null, never a plausible placeholder.
- **No location tracking.** GPS read once, used for environment fetch, then discarded.
- **Read-only health access.** Never writes to HealthKit or Health Connect.
- **Graceful degradation.** Every data fetch has a timeout. The app never freezes waiting for a sensor.

---

## Roadmap

### Done

- [x] LLM-backed narrative generation (captures-first, snapshot fallback, local template on failure)
- [x] SQLite persistence for entries, captures, and settings
- [x] 7-day rolling context window for AI prompts
- [x] User annotations (free-text note + mood emoji per day)
- [x] Smart refresh — instant cache, incremental AI, capture-processed tracking
- [x] Background captures via WorkManager (quiet hours, battery awareness)
- [x] Manual capture with configurable data-source toggles
- [x] "Refresh day" button for user-triggered full sensor + AI refresh
- [x] Per-capture AI metadata extraction (`CaptureMetadataService`)
- [x] Patterns screen — progressive AI-derived insights from capture history

### Next — BLE Peripherals

- [ ] Bluetooth Low Energy scanning & pairing
- [ ] Real-time data from BLE heart rate straps, pulse oximeters, smart scales
- [ ] Continuous background BLE data collection

### Next — Home Automation

- [ ] Smart-home integration (Matter, HomeKit, MQTT)
- [ ] Physiological-state-driven rules (sleep → dim lights, wake → start coffee)
- [ ] User-defined trigger engine based on body + environment state

### Future

- [ ] On-device ML for mood/state classification
- [ ] Multi-user household awareness (BLE presence + individual profiles)
- [ ] Wearable companion (Wear OS / watchOS)
- [ ] Export to structured health records (FHIR-compatible)

---

## License

MIT
