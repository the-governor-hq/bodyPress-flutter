# BodyPress Flutter

A stylish cross-platform Flutter app for GPS tracking, health monitoring, and calendar integration.

## Features

### 🎯 Core Functionality
- **GPS Tracking**: Real-time location tracking with background support
- **Health Data Monitoring**: Cross-platform health data access (iOS HealthKit & Android Health Connect)
  - Daily step count
  - Calories burned
  - Heart rate monitoring
  - Sleep tracking
  - Workout tracking
- **Calendar Integration**: View and manage your workout schedule
  - Today's events display
  - Create workout sessions
  - Integration with device calendars

### 🎨 Design
- Modern, stylish dark theme with vibrant accent colors
- Clean Material 3 design
- Responsive layouts for all screen sizes
- Smooth animations and transitions
- Google Fonts integration (Inter)

### 🏗️ Architecture
Following Flutter best practices:
- **Feature-first structure**: Organized by features (home, permissions, health, location, calendar)
- **Riverpod**: State management using flutter_riverpod
- **GoRouter**: Declarative routing
- **Service layer**: Clean separation of business logic
- **Material 3**: Modern UI components

## Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── router/            # Navigation configuration
│   ├── services/          # Business logic services
│   │   ├── permission_service.dart
│   │   ├── location_service.dart
│   │   ├── health_service.dart
│   │   └── calendar_service.dart
│   └── theme/             # App theming
│       └── app_theme.dart
├── features/
│   ├── home/              # Home screen
│   │   └── screens/
│   ├── permissions/       # Permission request flow
│   │   └── screens/
│   ├── health/            # Health tracking features
│   ├── location/          # Location tracking features
│   └── calendar/          # Calendar features
├── shared/
│   └── widgets/           # Reusable widgets
└── main.dart              # App entry point
```

## Dependencies

### Core
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `google_fonts` - Typography

### Permissions & Data
- `permission_handler` - Permission management
- `geolocator` - GPS tracking
- `health` - Health data (cross-platform)
- `device_calendar` - Calendar integration

## Setup Instructions

### Prerequisites
- Flutter SDK 3.9.2 or higher
- iOS: Xcode 14+ with iOS 14+ deployment target
- Android: Android Studio with minimum SDK 21 (Android 5.0)

### Installation

1. **Clone and navigate to the project:**
   ```bash
   cd bodypress_flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### iOS Configuration
All required Info.plist entries are already configured:
- NSLocationWhenInUseUsageDescription
- NSLocationAlwaysAndWhenInUseUsageDescription
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription
- NSCalendarsUsageDescription
- NSMotionUsageDescription

**Note**: You may need to enable HealthKit capability in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Click "+ Capability" → Add "HealthKit"

#### Android Configuration
All required permissions are already configured in AndroidManifest.xml:
- Location permissions (fine, coarse, background)
- Health permissions (Android 13+ Health Connect)
- Activity recognition
- Calendar permissions

**Note**: For Android 13+ health features, users must have Health Connect app installed.

## Usage

### First Launch
On first launch, the app will request necessary permissions:
1. Location access (for GPS tracking)
2. Health data access (for fitness metrics)
3. Calendar access (for scheduling)

Grant the permissions to enable full functionality.

### Main Screen
The home screen displays:
- Time-based greeting
- Today's activity metrics (steps, calories)
- Current location coordinates
- Today's calendar events
- Pull-to-refresh to update data

## Development

### Quick Start Development

**Easiest way (PowerShell):**
```powershell
.\dev.ps1
```

**Linux/Mac (Bash):**
```bash
chmod +x dev.sh
./dev.sh
```

This will:
- Check device connection
- Start the app with hot reload enabled
- Display keyboard shortcuts

### Hot Reload Commands

While the app is running:
- **`r`** - Hot reload (fast, preserves state) - Use this for UI changes
- **`R`** - Hot restart (full restart, resets state) - Use when adding new files/dependencies
- **`h`** - Show all available commands
- **`c`** - Clear the console
- **`q`** - Quit and stop the app

### Development Workflow

1. **Make UI/logic changes** in your editor
2. **Save the file** (Ctrl+S / Cmd+S)
3. **Press `r`** in the Flutter terminal for instant hot reload
4. **See changes immediately** on the emulator (usually <1 second)

### When to Use Hot Restart (R) vs Hot Reload (r)

**Use Hot Reload (`r`) for:**
- UI changes (widgets, layouts, colors)
- Logic changes in existing methods
- Text/string changes
- Style changes
- Fast iteration (preserves app state)

**Use Hot Restart (`R`) for:**
- Adding new files
- Changing dependencies
- Modifying `main()` or global variables
- Changing app initialization
- When hot reload doesn't reflect changes

### VS Code Integration

For the best DX, use VS Code with Flutter extension:
1. Open project in VS Code
2. Press `F5` or Run → Start Debugging
3. Edit files and save - auto-hot-reload enabled
4. See changes instantly without manual commands

### Running in Debug Mode
```bash
flutter run -d emulator-5554
```

### Running with Verbose Output


**iOS:**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

### Code Analysis
```bash
flutter analyze
```

### Testing
```bash
flutter test
```

## Testing on Emulator/Simulator

### Overview
**IMPORTANT**: This app uses REAL data sources only. No fake/mock data is presented to users. When testing on emulator/simulator, you'll see zero values if real data isn't available - this is correct behavior.

See [CODING_PRINCIPLES.md](CODING_PRINCIPLES.md) for why we never use fake data in production.

### Health Data Testing

#### Android Emulator
1. **Install Health Connect**:
   - Open Play Store on emulator
   - Search "Health Connect"
   - Install the app

2. **Add Real Test Data**:
   - Open Health Connect
   - Navigate to Steps/Activity
   - Manually enter test data for today
   - App will read this REAL data

3. **Expected Behavior**:
   - With data: Shows your entered values
   - Without data: Shows 0 (correct - no fake numbers)

#### iOS Simulator
1. **Use Real Device Instead**:
   - iOS Simulator doesn't support HealthKit
   - Connect real iPhone for health testing
   - Or accept zero values in simulator (correct behavior)

2. **On Real iPhone**:
   - Open Health app
   - Add test data (steps, calories, etc.)
   - Run app - it reads REAL data from Health app

### Location Testing

#### Android Emulator
1. **Set GPS Coordinates**:
   - Click "..." (Extended Controls)
   - Navigate to "Location"
   - Enter custom latitude/longitude
   - Click "Send"

2. **Expected Behavior**:
   - App reads these coordinates from system
   - These are "real" to the emulator

#### iOS Simulator
1. **Set Custom Location**:
   - Debug menu → Location → Custom Location
   - Enter latitude/longitude
   - Simulator reports this as system location

2. **Expected Behavior**:
   - App reads from system location API
   - No fake coordinates generated

### Calendar Testing

#### Both Platforms
1. **Add Real Events**:
   - Open device Calendar app
   - Add events for today
   - Include title and time

2. **Run App**:
   - Grant calendar permission
   - App reads REAL events from calendar
   - No fake events are generated

3. **Empty Calendar**:
   - Shows "No events today" - correct!
   - Zero events is honest, not an error

### Testing App Freeze Fix

The app uses timeouts (5 seconds) to prevent hanging:

1. **Normal Case**:
   - Data loads within 5 seconds → displays normally

2. **Timeout Case**:
   - Data takes >5 seconds → returns null/zero
   - App continues, shows unavailable state
   - No infinite loading

3. **Expected in Emulator**:
   - Some services may timeout (especially health on iOS simulator)
   - App should NOT freeze
   - Shows zeros or "unavailable" - this is correct

## Troubleshooting

### App Freezes After Permissions
- **Fixed**: Added 5-second timeouts to all data fetching
- If you experience freezing, check console for timeout messages
- Timeouts return zero/null, not fake data

### iOS Health Data Not Loading
- Ensure HealthKit capability is enabled in Xcode
- Check that permissions were granted in iOS Settings → BodyPress
- **iOS Simulator**: HealthKit not supported - use real device or accept zeros
- Real device: Add data in Health app first

### Android Health Data Shows Zero
- Install Health Connect from Play Store
- Manually add step/activity data in Health Connect
- Grant permissions when app requests
- Zero is shown when no real data exists - this is correct behavior

### Android Location Not Working
- Enable Location Services in device settings
- For background tracking, ensure "Allow all the time" is selected
- **Emulator**: Use Extended Controls → Location to set GPS coordinates

### Calendar Events Not Showing
- Verify calendar permissions are granted
- Check that device has calendars with events
- Add test events in device Calendar app
- Empty list is correct when no events exist

### Understanding Zero Values
- **Zero steps/calories**: No health data available (correct)
- **No location**: GPS unavailable or permission denied (correct)
- **No events**: Calendar empty or no events today (correct)
- App NEVER shows fake data - zeros indicate real absence of data

### Quick Testing Checklist

#### Before Running App
- [ ] Emulator/device is running
- [ ] **For health data**: Health Connect (Android) or real iPhone with Health app
- [ ] **For location**: Use emulator GPS controls (see above)
- [ ] **For calendar**: Add test events in Calendar app

#### Expected Results on Emulator
| Feature | With Data | Without Data | Notes |
|---------|-----------|--------------|-------|
| Steps | Shows count from Health Connect | 0 | Zero is correct - no fake data |
| Calories | Shows value from Health Connect | 0 | Zero is correct - no fake data |
| Location | Shows coordinates from GPS | "Location not available" | Set via emulator controls |
| Calendar | Lists events from Calendar app | "No events scheduled" | Add events in Calendar app |
| App Freeze | Should NOT freeze | Should NOT freeze | Timeouts prevent hanging |

#### Testing the Freeze Fix
1. Run app on emulator without Health Connect installed
2. Grant all permissions
3. **Expected**: App loads within 5 seconds, shows zeros for health data
4. **Previous bug**: App would freeze indefinitely
5. **Fixed**: Timeouts return null/zero after 5 seconds

#### Console Output to Look For
```
Flutter run key commands.
...
Error loading health data: ... (expected on emulator without data)
Health steps request timed out (expected if taking >5s)
Location request timed out (expected if GPS unavailable)
```

These timeout messages are normal and indicate correct behavior - the app is handling unavailable data properly.

## Development


- [ ] Workout tracking with maps
- [ ] History and analytics
- [ ] Custom health goals
- [ ] Social features
- [ ] Wearable device sync
- [ ] Offline mode

## License
Private project - All rights reserved

## Support
For issues or questions, please contact the development team.
