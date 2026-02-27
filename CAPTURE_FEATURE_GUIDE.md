# Capture Feature Guide

## Overview

The Capture feature is a comprehensive data collection system that serves as the foundation for AI-driven closed-loop feedback in BodyPress. It captures multi-dimensional snapshots of the user's state, including health metrics, environmental conditions, location data, calendar context, and user reflections.

## The Closed-Loop Vision

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOSED-LOOP SYSTEM                        │
│                                                              │
│  1. CAPTURE                                                  │
│     ↓ User captures moment with all available data          │
│     ↓ Health + Environment + Location + Calendar + Notes    │
│                                                              │
│  2. STORE                                                    │
│     ↓ Data stored with isProcessed = false flag             │
│     ↓ Comprehensive snapshot preserved for analysis         │
│                                                              │
│  3. ANALYZE (AI Processing)                                  │
│     ↓ AI analyzes unprocessed captures                      │
│     ↓ Identifies patterns, correlations, insights           │
│     ↓ Generates personalized recommendations                │
│                                                              │
│  4. FEEDBACK                                                 │
│     ↓ User receives contextual insights                     │
│     ↓ Actionable recommendations delivered                  │
│                                                              │
│  5. ACTION                                                   │
│     ↓ User acts on recommendations                          │
│     ↓ New captures reflect behavior changes                 │
│                                                              │
│  6. LOOP CONTINUES                                           │
│     → System learns and adapts over time                    │
└─────────────────────────────────────────────────────────────┘
```

## Architecture

### Data Model: CaptureEntry

Located in: `lib/core/models/capture_entry.dart`

The `CaptureEntry` model is the centerpiece of the capture system:

```dart
class CaptureEntry {
  final String id;                      // Unique identifier
  final DateTime timestamp;             // When captured
  final bool isProcessed;               // AI processing status
  final String? userNote;               // User's reflection
  final String? userMood;               // Mood emoji
  final List<String> tags;              // Categorization

  // Comprehensive data collection:
  final CaptureHealthData? healthData;          // Health metrics
  final CaptureEnvironmentData? environmentData; // Environmental conditions
  final CaptureLocationData? locationData;       // GPS & location info
  final List<String> calendarEvents;            // Calendar context

  // AI processing results:
  final DateTime? processedAt;          // When processed
  final String? aiInsights;             // AI-generated insights
}
```

### Service Layer: CaptureService

Located in: `lib/core/services/capture_service.dart`

The `CaptureService` orchestrates data collection from multiple sources:

**Data Sources Integration:**

- **HealthService**: Steps, heart rate, calories, sleep, workouts
- **AmbientScanService**: Temperature, weather, AQI, UV index
- **LocationService**: GPS coordinates, altitude, accuracy
- **GpsMetricsService**: City, region, country
- **CalendarService**: Today's events and appointments

**Key Methods:**

```dart
// Create a comprehensive capture
Future<CaptureEntry> createCapture({
  bool includeHealth = true,
  bool includeEnvironment = true,
  bool includeLocation = true,
  bool includeCalendar = true,
  String? userNote,
  String? userMood,
  List<String> tags = const [],
});

// Get captures with optional filtering
Future<List<CaptureEntry>> getCaptures({
  bool? isProcessed,
  int? limit,
});

// Mark capture as processed by AI
Future<void> markAsProcessed(
  String id, {
  String? aiInsights,
});

// Get count of unprocessed captures
Future<int> getUnprocessedCount();
```

### Database Layer: LocalDbService

Located in: `lib/core/services/local_db_service.dart`

Database schema version updated to **v4** with new `captures` table:

```sql
CREATE TABLE captures (
  id               TEXT    PRIMARY KEY,
  timestamp        TEXT    NOT NULL,
  is_processed     INTEGER NOT NULL DEFAULT 0,
  user_note        TEXT,
  user_mood        TEXT,
  tags             TEXT    NOT NULL DEFAULT '[]',
  health_data      TEXT,
  environment_data TEXT,
  location_data    TEXT,
  calendar_events  TEXT    NOT NULL DEFAULT '[]',
  processed_at     TEXT,
  ai_insights      TEXT
);

CREATE INDEX idx_captures_timestamp ON captures(timestamp DESC);
CREATE INDEX idx_captures_processed ON captures(is_processed);
```

**CRUD Operations:**

- `saveCapture()` - Insert or update a capture
- `loadCapture(id)` - Load specific capture
- `loadCaptures({isProcessed, limit})` - Query captures with filters
- `deleteCapture(id)` - Delete a capture
- `countCaptures({isProcessed})` - Count captures with filter

### UI Layer: CaptureScreen

Located in: `lib/features/capture/screens/capture_screen.dart`

A modern, intuitive interface for capturing data:

**Features:**

- **Data Selection**: Toggle what data to capture (Health, Environment, Location, Calendar)
- **User Input**: Add optional notes and mood
- **Stats Dashboard**: View total captures and unprocessed count
- **Capture History**: Browse recent captures
- **Detailed View**: Drill down into captured data

**User Flow:**

1. Select data sources to include
2. Optionally add context (note, mood)
3. Tap "Capture Now" button
4. View confirmation and updated stats
5. Browse recent captures
6. Tap any capture to view full details

## Implementation Examples

### Basic Capture

```dart
final captureService = CaptureService();

// Capture everything with default settings
final capture = await captureService.createCapture();
```

### Selective Capture

```dart
// Only capture health and environment data
final capture = await captureService.createCapture(
  includeHealth: true,
  includeEnvironment: true,
  includeLocation: false,
  includeCalendar: false,
  userNote: "Felt great after morning run!",
  userMood: "😊",
  tags: ["workout", "morning"],
);
```

### Query Unprocessed Captures

```dart
// Get all captures that haven't been processed by AI
final unprocessed = await captureService.getCaptures(
  isProcessed: false,
);

print('Pending analysis: ${unprocessed.length} captures');
```

### AI Processing Pipeline

```dart
// Example: Batch process unprocessed captures
final captureService = CaptureService();
final aiService = AiService();

Future<void> processCaptures() async {
  final unprocessed = await captureService.getCaptures(isProcessed: false);

  for (final capture in unprocessed) {
    // Build AI prompt from capture data
    final prompt = buildPromptFromCapture(capture);

    // Get AI insights
    final insights = await aiService.ask(
      prompt,
      systemPrompt: 'You are a health and wellness analyst...',
    );

    // Mark as processed with insights
    await captureService.markAsProcessed(
      capture.id,
      aiInsights: insights,
    );
  }
}

String buildPromptFromCapture(CaptureEntry capture) {
  final buffer = StringBuffer();
  buffer.writeln('Analyze this health snapshot:');
  buffer.writeln('Timestamp: ${capture.timestamp}');

  if (capture.healthData != null) {
    final h = capture.healthData!;
    buffer.writeln('Health:');
    if (h.steps != null) buffer.writeln('  Steps: ${h.steps}');
    if (h.heartRate != null) buffer.writeln('  Heart Rate: ${h.heartRate} bpm');
    if (h.calories != null) buffer.writeln('  Calories: ${h.calories} kcal');
  }

  if (capture.environmentData != null) {
    final e = capture.environmentData!;
    buffer.writeln('Environment:');
    if (e.temperature != null) buffer.writeln('  Temp: ${e.temperature}°C');
    if (e.aqi != null) buffer.writeln('  AQI: ${e.aqi}');
  }

  if (capture.userNote != null) {
    buffer.writeln('User Note: ${capture.userNote}');
  }

  buffer.writeln('\nProvide insights and recommendations.');
  return buffer.toString();
}
```

## Integration with AI Service

The capture system is designed to feed data into the AI service for analysis. Here's how they work together:

### 1. Scheduled Analysis

```dart
// Background job that runs periodically
Future<void> scheduledAnalysis() async {
  final captureService = CaptureService();
  final aiService = AiService();

  // Check if there are enough unprocessed captures
  final count = await captureService.getUnprocessedCount();
  if (count >= 3) {  // Process in batches of 3+
    await processCaptures(); // From example above
  }
}
```

### 2. On-Demand Analysis

```dart
// User requests analysis of specific capture
Future<String> analyzeCapture(String captureId) async {
  final captureService = CaptureService();
  final aiService = AiService();

  final capture = await captureService.getCapture(captureId);
  if (capture == null) throw Exception('Capture not found');

  final prompt = buildPromptFromCapture(capture);
  final insights = await aiService.ask(prompt);

  await captureService.markAsProcessed(captureId, aiInsights: insights);

  return insights;
}
```

### 3. Pattern Analysis

```dart
// Analyze multiple captures to find patterns
Future<String> findPatterns() async {
  final captureService = CaptureService();
  final aiService = AiService();

  // Get last 7 days of captures
  final captures = await captureService.getCaptures(limit: 7);

  final prompt = '''
Analyze these health snapshots over the past week:

${captures.map((c) => buildPromptFromCapture(c)).join('\n---\n')}

Identify patterns, correlations, and provide recommendations for improvement.
''';

  return await aiService.ask(
    prompt,
    systemPrompt: 'You are a data analyst specializing in health patterns.',
  );
}
```

## Closed-Loop Workflow Example

### Complete Implementation

```dart
import 'package:bodypress_flutter/core/services/capture_service.dart';
import 'package:bodypress_flutter/core/services/ai_service.dart';

class HealthFeedbackLoop {
  final CaptureService _captureService = CaptureService();
  final AiService _aiService = AiService();

  /// Step 1: User captures a moment
  Future<String> captureAndAnalyze({
    String? userNote,
    String? userMood,
  }) async {
    // Create comprehensive capture
    final capture = await _captureService.createCapture(
      userNote: userNote,
      userMood: userMood,
    );

    print('✅ Captured: ${capture.id}');

    // Immediately analyze if user wants instant feedback
    final insights = await _analyzeCapture(capture.id);

    return insights;
  }

  /// Step 2: AI analyzes the capture
  Future<String> _analyzeCapture(String captureId) async {
    final capture = await _captureService.getCapture(captureId);
    if (capture == null) throw Exception('Capture not found');

    // Build context-rich prompt
    final prompt = _buildAnalysisPrompt(capture);

    // Get AI insights
    final insights = await _aiService.ask(
      prompt,
      systemPrompt: '''You are a holistic health analyst.
Analyze the captured data and provide:
1. Key observations
2. Potential correlations (e.g., weather vs mood, activity vs sleep)
3. One actionable recommendation

Be encouraging and specific.''',
      temperature: 0.7,
    );

    // Mark as processed
    await _captureService.markAsProcessed(captureId, aiInsights: insights);

    print('🤖 Analysis complete for: $captureId');

    return insights;
  }

  /// Step 3: Compare with historical data for patterns
  Future<String> findLongTermPatterns() async {
    final allCaptures = await _captureService.getCaptures(
      isProcessed: true,
      limit: 30,  // Last 30 captures
    );

    if (allCaptures.length < 5) {
      return 'Not enough data yet. Keep capturing!';
    }

    final prompt = _buildPatternPrompt(allCaptures);

    return await _aiService.ask(
      prompt,
      systemPrompt: '''You are a longitudinal health data analyst.
Identify meaningful patterns, trends, and correlations over time.
Provide evidence-based recommendations.''',
      temperature: 0.6,
    );
  }

  String _buildAnalysisPrompt(CaptureEntry capture) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Health Snapshot Analysis');
    buffer.writeln('Timestamp: ${capture.timestamp}');
    buffer.writeln();

    if (capture.healthData != null) {
      final h = capture.healthData!;
      buffer.writeln('💪 Health Metrics:');
      if (h.steps != null) buffer.writeln('  Steps: ${h.steps}');
      if (h.calories != null) buffer.writeln('  Calories: ${h.calories?.toStringAsFixed(0)} kcal');
      if (h.heartRate != null) buffer.writeln('  Heart Rate: ${h.heartRate} bpm');
      if (h.sleepHours != null) buffer.writeln('  Sleep: ${h.sleepHours?.toStringAsFixed(1)} hours');
      buffer.writeln();
    }

    if (capture.environmentData != null) {
      final e = capture.environmentData!;
      buffer.writeln('🌤️ Environment:');
      if (e.temperature != null) buffer.writeln('  Temperature: ${e.temperature?.toStringAsFixed(1)}°C');
      if (e.weatherDescription != null) buffer.writeln('  Weather: ${e.weatherDescription}');
      if (e.aqi != null) buffer.writeln('  Air Quality: ${e.aqi}');
      if (e.uvIndex != null) buffer.writeln('  UV Index: ${e.uvIndex?.toStringAsFixed(1)}');
      buffer.writeln();
    }

    if (capture.locationData != null) {
      final l = capture.locationData!;
      if (l.city != null) {
        buffer.writeln('📍 Location: ${l.city}${l.region != null ? ", ${l.region}" : ""}');
        buffer.writeln();
      }
    }

    if (capture.calendarEvents.isNotEmpty) {
      buffer.writeln('📅 Today\'s Events:');
      for (final event in capture.calendarEvents) {
        buffer.writeln('  • $event');
      }
      buffer.writeln();
    }

    if (capture.userNote != null) {
      buffer.writeln('📝 User Note: "${capture.userNote}"');
      buffer.writeln();
    }

    if (capture.userMood != null) {
      buffer.writeln('😊 Mood: ${capture.userMood}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _buildPatternPrompt(List<CaptureEntry> captures) {
    final buffer = StringBuffer();
    buffer.writeln('📈 Pattern Analysis Request');
    buffer.writeln('Dataset: ${captures.length} captures');
    buffer.writeln();

    for (var i = 0; i < captures.length; i++) {
      final c = captures[i];
      buffer.writeln('--- Capture ${i + 1} (${c.timestamp}) ---');

      if (c.healthData != null) {
        final h = c.healthData!;
        buffer.write('Health: ');
        if (h.steps != null) buffer.write('${h.steps} steps, ');
        if (h.heartRate != null) buffer.write('${h.heartRate} bpm, ');
        if (h.sleepHours != null) buffer.write('${h.sleepHours?.toStringAsFixed(1)}h sleep');
        buffer.writeln();
      }

      if (c.environmentData != null) {
        final e = c.environmentData!;
        if (e.temperature != null && e.weatherDescription != null) {
          buffer.writeln('Environment: ${e.temperature?.toStringAsFixed(0)}°C, ${e.weatherDescription}');
        }
      }

      if (c.userNote != null) buffer.writeln('Note: "${c.userNote}"');
      if (c.userMood != null) buffer.writeln('Mood: ${c.userMood}');
      buffer.writeln();
    }

    buffer.writeln('Find patterns in activity, mood, environment, and provide insights.');

    return buffer.toString();
  }
}
```

### Usage in App

```dart
// In your widget or controller
final feedbackLoop = HealthFeedbackLoop();

// When user taps "Capture Now"
final insights = await feedbackLoop.captureAndAnalyze(
  userNote: "Felt energized after morning walk",
  userMood: "😊",
);

// Display insights to user
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('AI Insights'),
    content: Text(insights),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Got it!'),
      ),
    ],
  ),
);
```

## Best Practices

### 1. Privacy & Data Security

- All data is stored locally on device
- No data transmitted to external servers except AI API
- User controls what data to capture
- Can delete captures at any time

### 2. Data Quality

- Always include timestamps
- Validate data before storage
- Handle missing data gracefully (use nullable types)
- Add user context when possible (notes, mood)

### 3. AI Processing

- Process captures in batches for efficiency
- Use appropriate temperature settings (0.6-0.7 for analysis)
- Provide clear system prompts to guide AI
- Store insights for future reference

### 4. User Experience

- Show immediate feedback after capture
- Display unprocessed count to encourage review
- Make capture quick and easy (< 30 seconds)
- Provide detailed view for power users

## Future Enhancements

### Planned Features

1. **Auto-Capture**: Automatically capture at specific times or triggers
2. **Smart Tags**: AI-suggested tags based on context
3. **Trend Visualizations**: Charts showing patterns over time
4. **Export Data**: Share captures and insights
5. **Collaborative Analysis**: Compare anonymized patterns with community
6. **Goals & Tracking**: Set goals and track progress via captures

### Integration Opportunities

- **Journal Integration**: Link captures to journal entries
- **Body Blog**: Use captures as input for daily narratives
- **Health Patterns**: Feed into pattern detection system
- **Recommendations Engine**: Power personalized suggestions

## Troubleshooting

### Common Issues

**Q: Capture returns null for some data**
A: This is normal. Not all data sources may be available (permissions, hardware, network).

**Q: Health data shows zeros**
A: Ensure Health permissions are granted. Check HealthService.hasPermissions().

**Q: Location data missing**
A: Check Location permissions. User may have denied access.

**Q: AI processing takes too long**
A: Consider processing captures in background job rather than real-time.

**Q: Database migration fails**
A: Check schema version. May need to uninstall/reinstall app during development.

## Support & Contribution

- Report issues on GitHub
- Contribute to documentation
- Suggest improvements
- Share usage patterns

---

**Remember**: The capture system is the foundation of the closed-loop feedback system. The more comprehensive the data, the better the AI insights and recommendations!
