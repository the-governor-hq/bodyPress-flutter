# Coding Principles - BodyPress Flutter

## Critical Rule: NO FAKE DATA IN PRODUCTION

### The Problem
AI assistants sometimes introduce mock/placeholder data in production code that gets displayed to users as if it's real. This is:
- **Misleading** - Users think they're seeing real health data, location, etc.
- **Unprofessional** - Violates user trust
- **Dangerous** - Could lead to incorrect decisions based on fake information

### The Solution: Real Data Only

#### ✅ CORRECT Approach
```dart
// Production code - always try real data sources
Future<int> getTodaySteps() async {
  try {
    final healthData = await _health.getHealthDataFromTypes(...);
    int totalSteps = 0;
    for (var data in healthData) {
      if (data.value is NumericHealthValue) {
        totalSteps += (data.value as NumericHealthValue).numericValue.toInt();
      }
    }
    return totalSteps;  // Real data or zero if unavailable
  } catch (e) {
    print('Error getting steps: $e');
    return 0;  // Return zero on error, not fake data
  }
}

// UI displays real data or indicates unavailable
Text('Steps: ${_todaySteps}')  // Shows 0 if no data, not fake numbers
```

#### ❌ WRONG Approach - NEVER DO THIS
```dart
// WRONG - Don't return fake data in production
Future<int> getTodaySteps() async {
  return 8547;  // FAKE DATA - NEVER!
}

// WRONG - Don't simulate data
final mockSteps = Random().nextInt(10000);  // FAKE - NEVER!

// WRONG - Don't use placeholder data that looks real
_todaySteps = 12000;  // FAKE - NEVER!
```

## When Mock Data IS Acceptable

### 1. Unit Tests ONLY
```dart
// test/services/health_service_test.dart
test('calculates total steps correctly', () {
  // This is a TEST - mock data is appropriate here
  final mockData = [
    HealthDataPoint(value: NumericHealthValue(1000)),
    HealthDataPoint(value: NumericHealthValue(1500)),
  ];
  expect(calculateTotal(mockData), 2500);
});
```

### 2. Development Mode with Clear Labels
```dart
// ONLY in debug mode, CLEARLY LABELED
class HealthService {
  static const bool _debugMode = kDebugMode;
  
  Future<int> getTodaySteps() async {
    if (_debugMode) {
      debugPrint('⚠️ DEBUG MODE: Using test data');
      // Test data clearly marked
    }
    // Real implementation...
  }
}
```

### 3. UI Examples in Documentation
```markdown
# Example Output
```
Steps: 8,500 (example value for demonstration)
```
```

## Handling Unavailable Data

### Show Empty States, Not Fake Data
```dart
// CORRECT: Show when data isn't available
if (_todaySteps == 0) {
  return Text('No step data available');
}

// CORRECT: Show loading state
if (_isLoading) {
  return CircularProgressIndicator();
}

// CORRECT: Show error state
if (_error != null) {
  return Text('Unable to load data: $_error');
}

// CORRECT: Show zero/null for unavailable data
Text('Steps: ${_todaySteps}')  // Shows 0, not fake number
```

## Timeouts and Error Handling

### Always use timeouts to prevent hanging
```dart
// CORRECT: Timeout returns null/zero, not fake data
final location = await _locationService
    .getCurrentLocation()
    .timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,  // Return null, not fake coordinates
    );

// Display appropriately
if (location == null) {
  Text('Location unavailable');
} else {
  Text('Lat: ${location.latitude}');
}
```

## Health Data Testing Without Physical Device

### Problem
Emulators/simulators don't generate real health data (steps, heart rate, etc.)

### Solutions WITHOUT Fake Data

#### Option 1: Real Device Testing
- **Android**: Use Health Connect app on real device
- **iOS**: Use actual iPhone with HealthKit data

#### Option 2: Manual Data Entry
- **Android**: Install Health Connect, manually enter test data
- **iOS**: Use Health app to manually add test data
- App reads REAL data from these sources

#### Option 3: Test with Zero Values
- Run on simulator/emulator
- App correctly shows 0 steps, 0 calories
- Verify UI handles zero values gracefully
- Verify error handling works

#### ❌ WRONG: Creating fake health data generator
```dart
// NEVER DO THIS
int _generateFakeSteps() {
  return Random().nextInt(15000);  // FAKE - NEVER!
}
```

## Calendar Data Testing

### CORRECT: Use Real Calendar Events
```dart
// Read from device calendar (even if empty)
Future<List<Event>> getTodayEvents() async {
  final calendars = await getCalendars();
  final allEvents = [];
  for (var calendar in calendars) {
    final events = await getEvents(...);  // Real API call
    allEvents.addAll(events);
  }
  return allEvents;  // Real events or empty list
}
```

### Testing: Add Real Events
1. Add events to device calendar
2. App reads these REAL events
3. Test with empty calendar (shows empty state)

## Location Data Testing

### CORRECT: Use Emulator Location Features
```dart
// Request real location from emulator
Future<Position?> getCurrentLocation() async {
  try {
    return await Geolocator.getCurrentPosition(...);
  } catch (e) {
    return null;  // Unavailable, not fake coordinates
  }
}
```

### Testing with Emulator
- **Android Emulator**: Use Extended Controls → Location to set GPS
- **iOS Simulator**: Debug → Location → Custom Location
- App reads these "real" coordinates from system

## Summary

### Golden Rules
1. **NEVER return fake/mock data in production code**
2. **ALWAYS attempt to fetch real data from real sources**
3. **Handle errors by returning null/zero/empty, not fake values**
4. **Use timeouts to prevent hanging**
5. **Display unavailable states clearly**
6. **Mock data ONLY in tests, clearly labeled**
7. **For testing, use real tools (Health Connect, manual entry, emulator GPS)**

### When Unsure
Ask: "If this data is shown to the user, would they think it's real?"
- If YES → It must be real or clearly marked as unavailable
- You should NEVER generate or simulate data in production

### The Right Mindset
- Empty/zero is honest ✅
- "Unavailable" is honest ✅
- Fake data pretending to be real is dishonest ❌
