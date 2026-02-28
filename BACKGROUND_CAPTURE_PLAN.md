# Background Capture Implementation Plan

## Executive Summary

This document outlines a comprehensive strategy for implementing reliable, battery-efficient background data captures in BodyPress. Background captures are critical for building a complete dataset for AI-driven health insights, ensuring data is captured automatically without requiring user intervention.

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Architecture Overview](#architecture-overview)
3. [Implementation Strategy](#implementation-strategy)
4. [Technical Specifications](#technical-specifications)
5. [Security & Privacy](#security--privacy)
6. [Testing Strategy](#testing-strategy)
7. [Rollout Plan](#rollout-plan)
8. [Future Enhancements](#future-enhancements)

---

## Current State Analysis

### ✅ What We Have

**Strong Foundation:**

- **CaptureService**: Well-architected service that orchestrates data collection from multiple sources
- **Data Model**: Comprehensive `CaptureEntry` model with health, environment, location, and calendar data
- **Database Layer**: SQLite persistence with proper indexing (`LocalDbService`)
- **UI Layer**: Intuitive capture screen with manual trigger
- **Permissions**: Location, health, and calendar permission handling

**Data Sources Integrated:**

- Health: steps, heart rate, calories, sleep, workouts
- Environment: temperature, weather, AQI, UV index
- Location: GPS coordinates, city, region, country
- Calendar: today's events

### ❌ What We're Missing

**Background Infrastructure:**

- No background task scheduler (e.g., WorkManager, Alarm Manager)
- No background-aware service architecture
- No retry/failure handling for background operations
- No battery optimization considerations
- No background permission handling (Android 10+, iOS background modes)

**Monitoring & Health:**

- No metrics on background capture success/failure rates
- No user visibility into background capture status
- No notification system for capture completion/failures

---

## Architecture Overview

### High-Level Design

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER SPACE                                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                 │
│  │  Capture   │  │   Home     │  │  Settings  │                 │
│  │   Screen   │  │   Screen   │  │   Screen   │                 │
│  └────┬───────┘  └────────────┘  └─────┬──────┘                 │
│       │                                 │                         │
│       │  Manual Trigger          Configure Background            │
└───────┼────────────────────────────────┼─────────────────────────┘
        │                                 │
        ▼                                 ▼
┌──────────────────────────────────────────────────────────────────┐
│                   BACKGROUND CAPTURE SERVICE                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                  BackgroundCaptureService                   │  │
│  │  - Schedule periodic captures                              │  │
│  │  - Handle trigger events                                   │  │
│  │  - Manage capture queue                                    │  │
│  │  - Retry failed captures                                   │  │
│  └────────────────────────┬───────────────────────────────────┘  │
└───────────────────────────┼──────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   WorkManager│   │   Geofencing │   │ Notification │
│   Scheduler  │   │   Trigger    │   │   Manager    │
└──────┬───────┘   └──────┬───────┘   └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          │
                          ▼
              ┌─────────────────────┐
              │   Capture Executor   │
              │  (Dart Entry Point)  │
              └──────────┬───────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   CaptureService    │
              │  (Existing Service) │
              └──────────┬───────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Health     │  │  Environment │  │   Location   │
│   Service    │  │   Service    │  │   Service    │
└──────────────┘  └──────────────┘  └──────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         ▼
              ┌─────────────────────┐
              │   LocalDbService    │
              │   (SQLite Storage)  │
              └─────────────────────┘
```

### Component Breakdown

#### 1. **BackgroundCaptureService** (New)

Central orchestrator for all background capture operations.

**Responsibilities:**

- Schedule periodic captures using WorkManager
- Manage capture settings (frequency, data sources)
- Handle capture triggers (time-based, location-based, event-based)
- Track capture statistics and health metrics
- Provide user-facing API for configuration

#### 2. **CaptureExecutor** (New)

Dart isolate entry point for background execution.

**Responsibilities:**

- Initialize services in background context
- Execute capture logic
- Handle errors gracefully
- Update notification status
- Log execution metrics

#### 3. **CaptureService** (Enhanced)

Existing service with minor enhancements for background execution.

**Enhancements:**

- Background-safe initialization
- Timeout handling for slow operations
- Battery-efficient data collection
- Graceful degradation (skip unavailable data sources)

#### 4. **WorkManager Integration** (New Plugin)

Flutter plugin for scheduling background tasks.

**Configuration:**

- Minimum interval: 15 minutes (Android limit)
- Constraints: battery level, network, charging state
- Retry policy: exponential backoff
- Persistence: survives app restart and device reboot

---

## Implementation Strategy

### Phase 1: Foundation (Week 1)

**Goal:** Set up background task infrastructure and basic periodic captures.

#### Tasks:

1. **Add Dependencies**

   ```yaml
   # pubspec.yaml
   dependencies:
     workmanager: ^0.5.2
     flutter_local_notifications: ^17.0.0
   ```

2. **Create BackgroundCaptureService**
   - Schedule periodic captures
   - Store user preferences (capture frequency, enabled data sources)
   - Provide enable/disable API

3. **Create CaptureExecutor**
   - Dart entry point for WorkManager
   - Initialize services without Flutter UI context
   - Execute single capture
   - Report success/failure

4. **Update Permissions**
   - Android: `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE`
   - iOS: Background modes (location, fetch)

5. **Basic Testing**
   - Verify background task schedules correctly
   - Confirm capture executes in background
   - Test app restart persistence

**Deliverables:**

- `lib/core/services/background_capture_service.dart`
- `lib/core/background/capture_executor.dart`
- Updated `AndroidManifest.xml` and `Info.plist`
- Basic unit tests

---

### Phase 2: Robustness & Reliability (Week 2)

**Goal:** Add error handling, retry logic, and monitoring.

#### Tasks:

1. **Enhanced Error Handling**
   - Graceful degradation when services fail
   - Timeout protection for slow operations
   - Offline mode (cache and retry when online)

2. **Retry Mechanism**
   - Exponential backoff for failed captures
   - Maximum retry count (3 attempts)
   - Skip capture after max retries (log for debugging)

3. **Capture Queue**
   - Queue failed captures for retry
   - Batch process queued captures when conditions improve
   - Limit queue size (prevent memory bloat)

4. **Status Tracking**
   - Last successful capture timestamp
   - Success/failure counters
   - Average capture duration
   - Battery impact estimation

5. **Notification System**
   - Background capture progress indicator
   - Configurable notifications (on/off)
   - Capture completion summary
   - Error alerts (only critical failures)

**Deliverables:**

- Enhanced `BackgroundCaptureService` with retry logic
- `CaptureQueue` class for managing failed captures
- `CaptureStats` model for tracking metrics
- Notification manager integration
- Integration tests

---

### Phase 3: Intelligence & Optimization (Week 3)

**Goal:** Smart capture scheduling and battery optimization.

#### Tasks:

1. **Smart Scheduling**
   - Adaptive capture frequency based on user activity
   - Higher frequency during workouts (detected movement)
   - Lower frequency during sleep (nighttime)
   - Skip captures when user is stationary for long periods

2. **Battery Optimization**
   - Batch data collection (reduce wake-ups)
   - Use geofencing to trigger location-based captures
   - Respect Android Doze mode and App Standby
   - iOS background fetch optimization

3. **Data Source Intelligence**
   - Skip environment API calls if location hasn't changed significantly
   - Cache calendar events (reduce API calls)
   - Debounce rapid health data changes

4. **Context-Aware Triggers**
   - Capture when leaving/arriving at significant locations (home, work, gym)
   - Capture after workout completion (detected by health service)
   - Capture at consistent times (morning, lunch, evening, bedtime)

5. **User Preferences**
   - Configurable capture frequency (15min, 30min, 1hr, 2hr, 4hr)
   - Battery-saving mode (reduce frequency)
   - Data source toggles (enable/disable health, location, etc.)
   - Quiet hours (no captures during sleep)

**Deliverables:**

- Intelligent scheduling logic
- Battery usage monitoring
- Settings screen for background captures
- Geofencing integration (optional)
- Performance tests

---

### Phase 4: User Experience & Polish (Week 4)

**Goal:** Seamless UX and comprehensive monitoring.

#### Tasks:

1. **Settings Screen**
   - Toggle background captures on/off
   - Frequency slider/selector
   - Data source toggles
   - Capture statistics dashboard
   - Last capture timestamp
   - Battery impact indicator

2. **Capture History View**
   - Timeline of all captures (manual + background)
   - Visual indicator for capture source (manual vs background)
   - Capture details view
   - Filter by date range
   - Export captures (JSON, CSV)

3. **Debugging Tools**
   - Background capture log viewer (debug builds only)
   - Force trigger background capture (manual test)
   - Clear capture queue
   - Reset statistics

4. **Onboarding Flow**
   - Explain background captures to new users
   - Highlight privacy and data usage
   - Set initial preferences
   - Request background permissions

5. **Documentation**
   - User-facing: How background captures work
   - Developer: Architecture and maintenance guide
   - Privacy policy updates

**Deliverables:**

- Complete settings UI
- Capture history screen
- Debug panel enhancements
- Updated onboarding
- Documentation

---

## Technical Specifications

### Background Capture Configuration

```dart
class BackgroundCaptureConfig {
  final bool enabled;
  final Duration interval;           // 15min, 30min, 1hr, 2hr, 4hr
  final bool includeHealth;
  final bool includeEnvironment;
  final bool includeLocation;
  final bool includeCalendar;
  final TimeOfDay quietHoursStart;   // e.g., 22:00
  final TimeOfDay quietHoursEnd;     // e.g., 07:00
  final bool batteryOptimization;    // Reduce frequency on low battery
  final bool notificationsEnabled;   // Show capture notifications
}
```

### Capture Metadata Enhancement

```dart
class CaptureEntry {
  // Existing fields...
  final CaptureSource source;        // manual | background_scheduled | background_triggered
  final CaptureTrigger? trigger;     // time | location | activity | manual
  final Duration executionTime;      // How long capture took
  final List<String> errors;         // Any errors during capture
  final int batteryLevel;            // Battery % at capture time
}

enum CaptureSource { manual, backgroundScheduled, backgroundTriggered }
enum CaptureTrigger { time, location, activity, manual }
```

### Background Task Configuration

```dart
// Android WorkManager
await Workmanager().registerPeriodicTask(
  'capture_periodic',
  'captureTask',
  frequency: Duration(minutes: 30),
  constraints: Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
  ),
  backoffPolicy: BackoffPolicy.exponential,
  backoffPolicyDelay: Duration(minutes: 15),
);
```

### iOS Background Modes

```xml
<!-- Info.plist -->
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>location</string>
  <string>processing</string>
</array>
```

### Android Permissions

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_HEALTH" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

---

## Security & Privacy

### Data Privacy Principles

1. **Transparency**
   - Clear explanation of what data is captured in background
   - When and why captures occur
   - How data is stored and used

2. **User Control**
   - Easy toggle to disable background captures
   - Granular control over data sources
   - Ability to delete captured data

3. **Data Minimization**
   - Only capture necessary data
   - Skip redundant captures (e.g., no movement detected)
   - Expire old data (optional auto-delete after 90 days)

4. **Security**
   - All data stored locally in encrypted SQLite database
   - No automatic cloud sync (user-initiated only)
   - Secure handling of location data (no sharing)

### Android Specifics

- **Background Location Disclaimer**: Required by Google Play
- **Foreground Service Notification**: Show persistent notification during capture
- **Battery Optimization Exemption**: Request user to exempt app (optional)

### iOS Specifics

- **Background Location Usage Description**: Clear explanation in Info.plist
- **Always-Allow Location**: Required for background geofencing
- **Privacy Manifest**: Declare all background activities

---

## Testing Strategy

### Unit Tests

- `BackgroundCaptureService` scheduling logic
- `CaptureExecutor` error handling
- Retry mechanism
- Queue management

### Integration Tests

- End-to-end background capture flow
- Database persistence
- Notification delivery
- Permission handling

### Platform-Specific Tests

**Android:**

- Doze mode behavior
- App Standby
- Battery optimization whitelist
- WorkManager constraints

**iOS:**

- Background fetch
- Location updates
- App refresh
- Background time limits

### Performance Tests

- Capture execution time
- Battery drain measurement
- Database write performance
- Memory usage in background

### Real-World Testing

- 24-hour capture cycle
- Low battery behavior
- Network interruptions
- App force-stop recovery

---

## Rollout Plan

### Stage 1: Internal Testing (Week 1-2)

- Deploy to development team
- Monitor live captures for 1 week
- Collect crash reports and performance metrics
- Iterate on bugs and issues

### Stage 2: Beta Testing (Week 3)

- Release to beta testers (10-20 users)
- Collect feedback on UX and reliability
- Monitor battery usage complaints
- A/B test different capture frequencies

### Stage 3: Gradual Rollout (Week 4)

- Release to 20% of users
- Monitor success rate, battery impact, and crash rate
- Address any issues before wider release
- Increase to 50%, then 100%

### Stage 4: Monitoring & Optimization (Ongoing)

- Track background capture success rate (target: >95%)
- Monitor battery impact (target: <5% daily)
- Collect user feedback
- Continuous improvements

---

## Future Enhancements

### Short-Term (1-3 months)

1. **Machine Learning Triggers**
   - Predict when user is active (likely to have interesting data)
   - Capture more frequently during predicted activity periods

2. **Contextual Captures**
   - Detect gym visits (capture pre/post workout)
   - Detect travel (capture at new locations)
   - Detect home/work transitions

3. **Advanced Analytics**
   - Capture pattern visualization
   - Data completeness score
   - Insights on capture timing

### Mid-Term (3-6 months)

1. **Capture Compression**
   - Compress historical captures to save storage
   - Keep uncompressed data for recent captures (last 7 days)

2. **Cloud Backup**
   - Optional encrypted cloud backup of captures
   - Sync across devices
   - Restore from backup

3. **Capture Sharing**
   - Export captures to health apps (Apple Health, Google Fit)
   - Share anonymized data for research (opt-in)

### Long-Term (6-12 months)

1. **Wearable Integration**
   - Direct capture from smartwatches
   - Real-time sync from wearables
   - Richer health metrics

2. **Predictive Captures**
   - AI predicts optimal capture times
   - Reduces unnecessary captures
   - Maximizes data value

3. **Cross-Platform Capture Mesh**
   - Capture from multiple devices (phone, watch, tablet)
   - Intelligent deduplication
   - Unified capture timeline

---

## Success Metrics

### Technical KPIs

- **Capture Success Rate**: >95%
- **Background Capture Latency**: <30 seconds
- **Battery Impact**: <5% per day
- **Crash Rate**: <0.1%
- **Data Completeness**: >90% of scheduled captures

### User Experience KPIs

- **User Opt-In Rate**: >70%
- **Background Capture Disable Rate**: <10%
- **User Satisfaction**: >4.5/5
- **Battery Complaints**: <5%

### Business KPIs

- **Data Availability for AI**: 24x7 capture coverage
- **Capture Density**: Avg 48+ captures per day (30min interval)
- **Data Diversity**: All data sources captured regularly

---

## Risk Mitigation

### Risk 1: Battery Drain

**Impact:** High | **Likelihood:** Medium

- **Mitigation:** Strict capture duration limits, battery-aware scheduling
- **Fallback:** User can reduce frequency or disable

### Risk 2: Permission Denial

**Impact:** High | **Likelihood:** High (especially background location)

- **Mitigation:** Clear permission rationale, graceful degradation
- **Fallback:** Remind user with in-app prompts

### Risk 3: Platform Restrictions

**Impact:** Medium | **Likelihood:** Medium (iOS background limits)

- **Mitigation:** Stay updated on platform changes, use best practices
- **Fallback:** Reduce capture frequency or foreground-only mode

### Risk 4: Data Storage Growth

**Impact:** Medium | **Likelihood:** High

- **Mitigation:** Auto-delete old captures, compress data
- **Fallback:** User-configurable retention period

### Risk 5: API Rate Limits

**Impact:** Low | **Likelihood:** Low (environment API)

- **Mitigation:** Cache responses, skip redundant calls
- **Fallback:** Use stale data or skip environment data

---

## Implementation Checklist

### Phase 1: Foundation

- [ ] Add `workmanager` and `flutter_local_notifications` to pubspec.yaml
- [ ] Create `BackgroundCaptureService` class
- [ ] Create `CaptureExecutor` entry point
- [ ] Update Android permissions in `AndroidManifest.xml`
- [ ] Update iOS background modes in `Info.plist`
- [ ] Implement basic periodic capture scheduling
- [ ] Test background capture on real device
- [ ] Add capture source metadata to `CaptureEntry`

### Phase 2: Robustness

- [ ] Add timeout handling to all data collection methods
- [ ] Implement retry mechanism with exponential backoff
- [ ] Create `CaptureQueue` for failed captures
- [ ] Add `CaptureStats` tracking
- [ ] Implement notification system
- [ ] Add unit tests for error handling
- [ ] Add integration tests for background flow

### Phase 3: Intelligence

- [ ] Implement smart scheduling logic
- [ ] Add battery optimization features
- [ ] Integrate geofencing (optional)
- [ ] Add context-aware triggers
- [ ] Create user preferences storage
- [ ] Add performance monitoring
- [ ] Test battery usage over 24 hours

### Phase 4: UX & Polish

- [ ] Build settings screen UI
- [ ] Build capture history screen
- [ ] Add debug tools to debug panel
- [ ] Update onboarding flow
- [ ] Write user documentation
- [ ] Write developer documentation
- [ ] Conduct user testing
- [ ] Final QA and polish

---

## Code Structure Preview

```
lib/
├── core/
│   ├── background/
│   │   ├── capture_executor.dart          # Background entry point
│   │   ├── capture_queue.dart             # Failed capture queue
│   │   └── capture_stats.dart             # Metrics tracking
│   ├── models/
│   │   ├── capture_entry.dart             # Enhanced with source/trigger
│   │   └── background_capture_config.dart # User preferences
│   ├── services/
│   │   ├── background_capture_service.dart # Main orchestrator
│   │   ├── capture_service.dart           # Enhanced for background
│   │   ├── notification_service.dart      # Capture notifications
│   │   └── ...
│   └── ...
├── features/
│   ├── capture/
│   │   ├── screens/
│   │   │   ├── capture_screen.dart        # Manual capture UI
│   │   │   ├── capture_history_screen.dart # Capture timeline
│   │   │   └── capture_settings_screen.dart # Background preferences
│   │   └── ...
│   └── ...
└── ...
```

---

## Conclusion

Background captures are a critical feature for BodyPress, enabling 24/7 data collection for AI-driven insights. This comprehensive plan balances functionality, reliability, battery efficiency, and user experience.

By following this phased approach, we'll build a robust background capture system that:

- ✅ Captures data reliably even when app is closed
- ✅ Respects user privacy and battery life
- ✅ Provides complete data for AI analysis
- ✅ Delivers excellent user experience

**Estimated Timeline:** 4 weeks for full implementation
**Risk Level:** Medium (platform restrictions, battery concerns)
**Business Impact:** High (critical for AI features)

---

## Next Steps

1. **Review this plan** with team and stakeholders
2. **Prioritize phases** based on business needs
3. **Set up development environment** and dependencies
4. **Begin Phase 1 implementation** (Foundation)
5. **Establish feedback loop** with beta testers

Let's build a world-class background capture system! 🚀
