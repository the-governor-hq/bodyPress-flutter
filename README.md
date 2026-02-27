# BodyPress

A cross-platform Flutter application that aggregates physiological, environmental, and behavioural data from device sensors, then synthesises a daily first-person narrative — a journal written by the user's body.

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
│   ├── models/
│   │   └── body_blog_entry.dart      # BodyBlogEntry, BodySnapshot
│   ├── router/
│   │   └── app_router.dart           # GoRouter config
│   ├── services/
│   │   ├── body_blog_service.dart    # Data collection + narrative composition + DB integration
│   │   ├── local_db_service.dart     # SQLite persistence (sqflite) — CRUD for BodyBlogEntry
│   │   ├── health_service.dart       # HealthKit / Health Connect abstraction
│   │   ├── location_service.dart     # Geolocator wrapper
│   │   ├── ambient_scan_service.dart # Environment API client
│   │   ├── gps_metrics_service.dart  # Real-time GPS metrics (speed, altitude)
│   │   ├── calendar_service.dart     # Device calendar read
│   │   └── permission_service.dart   # Permission orchestration
│   └── theme/
│       └── app_theme.dart            # Material 3 theming (light + dark)
├── features/
│   ├── onboarding/                   # Step-by-step permission flow
│   ├── body_blog/                    # Main screen — paginated journal
│   ├── home/                         # Debug panel (raw sensor readouts)
│   ├── environment/                  # Detailed environment view
│   ├── health/
│   ├── location/
│   ├── calendar/
│   └── permissions/                  # Legacy (superseded by onboarding)
└── main.dart
```

### Key abstractions

- **`BodyBlogService`** — Orchestrates data collection from all services, infers a mood label via heuristic rules, and composes the narrative. Designed to be swapped for an LLM endpoint (OpenAI, Gemini, local model) when the narrative quality ceiling is hit.
- **`BodyBlogEntry`** — Immutable value object containing date, headline, summary, full body text, mood, tags, and the raw `BodySnapshot` used to generate it.
- **`BodySnapshot`** — Flat struct of all collected metrics for a given day. Serialisation-ready for future persistence and API payloads.

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
2. **Body Blog** (`/`) — Paginated journal. Swipe between days. Each page shows date, inferred mood, headline, summary, data tags, a stat glance bar, and a "Read full entry" link.
3. **Journal Detail** — Full narrative view. Sections: Sleep, Movement, Heart, Environment, Agenda.
4. **Debug Panel** (`/debug`) — Raw sensor readout: all health metrics, GPS coordinates, ambient data, calendar events. Accessible via the settings icon on the blog screen.
5. **Environment Detail** (`/environment`) — Expanded environmental data.

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

- [ ] LLM-backed narrative generation (structured prompt with BodySnapshot as context)
- [x] Local persistence of daily entries (SQLite via sqflite)
- [ ] 7-day rolling context window — AI reads the past week to detect trends
- [x] User annotations — free-text note per day, stored in SQLite, shown in journal detail

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

```bash
# PowerShell
.\dev.ps1

# Bash
./dev.sh
```

Hot reload: `r` · Hot restart: `R` · Quit: `q`

```bash
flutter analyze
flutter test
```

## Testing notes

The app displays only real sensor data. On emulators without Health Connect or HealthKit, health values will be zero. This is correct behaviour — see `CODING_PRINCIPLES.md`.

- **Android health**: Install Health Connect, add test data manually.
- **iOS health**: Requires a physical device; HealthKit is unavailable in the simulator.
- **Location**: Set coordinates via emulator extended controls.
- **Calendar**: Add events in the device calendar app.

All data fetches have 5–15 s timeouts to prevent UI freezes.

## License

Private — all rights reserved.
