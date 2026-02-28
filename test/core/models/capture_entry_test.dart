import 'package:bodypress_flutter/core/models/capture_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── CaptureHealthData ────────────────────────────────────────────────────

  group('CaptureHealthData', () {
    test('toJson / fromJson round-trip', () {
      const original = CaptureHealthData(
        steps: 5000,
        calories: 210.5,
        distance: 3200,
        heartRate: 72,
        sleepHours: 6.5,
        workouts: 1,
      );
      final json = original.toJson();
      final decoded = CaptureHealthData.fromJson(json);

      expect(decoded.steps, original.steps);
      expect(decoded.calories, original.calories);
      expect(decoded.distance, original.distance);
      expect(decoded.heartRate, original.heartRate);
      expect(decoded.sleepHours, original.sleepHours);
      expect(decoded.workouts, original.workouts);
    });

    test('fromJson handles null fields', () {
      final decoded = CaptureHealthData.fromJson({});
      expect(decoded.steps, isNull);
      expect(decoded.calories, isNull);
      expect(decoded.distance, isNull);
      expect(decoded.heartRate, isNull);
      expect(decoded.sleepHours, isNull);
      expect(decoded.workouts, isNull);
    });
  });

  // ─── CaptureEnvironmentData ───────────────────────────────────────────────

  group('CaptureEnvironmentData', () {
    test('toJson / fromJson round-trip', () {
      const original = CaptureEnvironmentData(
        temperature: 22.5,
        aqi: 45,
        uvIndex: 5.0,
        weatherDescription: 'Sunny',
        humidity: 60,
        windSpeed: 15.3,
        pressure: 1013.2,
        conditions: 'Clear sky',
      );
      final json = original.toJson();
      final decoded = CaptureEnvironmentData.fromJson(json);

      expect(decoded.temperature, original.temperature);
      expect(decoded.aqi, original.aqi);
      expect(decoded.uvIndex, original.uvIndex);
      expect(decoded.weatherDescription, original.weatherDescription);
      expect(decoded.humidity, original.humidity);
      expect(decoded.windSpeed, original.windSpeed);
      expect(decoded.pressure, original.pressure);
      expect(decoded.conditions, original.conditions);
    });

    test('fromJson handles null fields', () {
      final decoded = CaptureEnvironmentData.fromJson({});
      expect(decoded.temperature, isNull);
      expect(decoded.aqi, isNull);
      expect(decoded.conditions, isNull);
    });
  });

  // ─── CaptureLocationData ──────────────────────────────────────────────────

  group('CaptureLocationData', () {
    test('toJson / fromJson round-trip', () {
      const original = CaptureLocationData(
        latitude: 45.5017,
        longitude: -73.5673,
        altitude: 30.0,
        accuracy: 5.0,
        city: 'Montreal',
        region: 'Quebec',
        country: 'Canada',
      );
      final json = original.toJson();
      final decoded = CaptureLocationData.fromJson(json);

      expect(decoded.latitude, original.latitude);
      expect(decoded.longitude, original.longitude);
      expect(decoded.altitude, original.altitude);
      expect(decoded.accuracy, original.accuracy);
      expect(decoded.city, original.city);
      expect(decoded.region, original.region);
      expect(decoded.country, original.country);
    });

    test('fromJson handles null optional fields', () {
      final decoded = CaptureLocationData.fromJson({
        'latitude': 45.0,
        'longitude': -73.0,
      });
      expect(decoded.latitude, 45.0);
      expect(decoded.longitude, -73.0);
      expect(decoded.altitude, isNull);
      expect(decoded.city, isNull);
    });
  });

  // ─── CaptureSource & CaptureTrigger enums ─────────────────────────────────

  group('CaptureSource enum', () {
    test('has expected values', () {
      expect(CaptureSource.values, hasLength(3));
      expect(CaptureSource.manual.name, 'manual');
      expect(CaptureSource.backgroundScheduled.name, 'backgroundScheduled');
      expect(CaptureSource.backgroundTriggered.name, 'backgroundTriggered');
    });
  });

  group('CaptureTrigger enum', () {
    test('has expected values', () {
      expect(CaptureTrigger.values, hasLength(4));
      expect(CaptureTrigger.time.name, 'time');
      expect(CaptureTrigger.location.name, 'location');
      expect(CaptureTrigger.activity.name, 'activity');
      expect(CaptureTrigger.manual.name, 'manual');
    });
  });

  // ─── CaptureEntry ────────────────────────────────────────────────────────

  group('CaptureEntry', () {
    CaptureEntry sampleEntry({
      bool isProcessed = false,
      CaptureSource source = CaptureSource.manual,
      CaptureTrigger? trigger,
    }) {
      return CaptureEntry(
        id: 'capture_1234567890',
        timestamp: DateTime(2025, 6, 15, 10, 30),
        isProcessed: isProcessed,
        userNote: 'Feeling good',
        userMood: '😊',
        tags: ['morning', 'walk'],
        healthData: const CaptureHealthData(steps: 3000, heartRate: 68),
        environmentData: const CaptureEnvironmentData(
          temperature: 20.0,
          aqi: 35,
        ),
        locationData: const CaptureLocationData(
          latitude: 45.5,
          longitude: -73.5,
          city: 'Montreal',
        ),
        calendarEvents: ['Standup', 'Lunch meeting'],
        source: source,
        trigger: trigger ?? CaptureTrigger.manual,
        executionDuration: const Duration(milliseconds: 1500),
        errors: ['GPS timeout'],
        batteryLevel: 85,
      );
    }

    test('toJson / fromJson round-trip with all fields', () {
      final original = sampleEntry();
      final json = original.toJson();
      final decoded = CaptureEntry.fromJson(json);

      expect(decoded.id, original.id);
      expect(decoded.timestamp, original.timestamp);
      expect(decoded.isProcessed, original.isProcessed);
      expect(decoded.userNote, original.userNote);
      expect(decoded.userMood, original.userMood);
      expect(decoded.tags, original.tags);
      expect(decoded.healthData!.steps, 3000);
      expect(decoded.healthData!.heartRate, 68);
      expect(decoded.environmentData!.temperature, 20.0);
      expect(decoded.environmentData!.aqi, 35);
      expect(decoded.locationData!.latitude, 45.5);
      expect(decoded.locationData!.city, 'Montreal');
      expect(decoded.calendarEvents, ['Standup', 'Lunch meeting']);
      expect(decoded.source, CaptureSource.manual);
      expect(decoded.trigger, CaptureTrigger.manual);
      expect(decoded.executionDuration!.inMilliseconds, 1500);
      expect(decoded.errors, ['GPS timeout']);
      expect(decoded.batteryLevel, 85);
    });

    test('toJson stores nested objects as JSON strings', () {
      final json = sampleEntry().toJson();
      expect(json['health_data'], isA<String>());
      expect(json['environment_data'], isA<String>());
      expect(json['location_data'], isA<String>());
      expect(json['tags'], isA<String>());
      expect(json['calendar_events'], isA<String>());
      expect(json['errors'], isA<String>());
    });

    test('toJson stores isProcessed as 1/0', () {
      expect(sampleEntry(isProcessed: true).toJson()['is_processed'], 1);
      expect(sampleEntry(isProcessed: false).toJson()['is_processed'], 0);
    });

    test('fromJson handles null nested objects', () {
      final json = {'id': 'capture_1', 'timestamp': '2025-06-15T10:30:00.000'};
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.healthData, isNull);
      expect(decoded.environmentData, isNull);
      expect(decoded.locationData, isNull);
      expect(decoded.calendarEvents, isEmpty);
      expect(decoded.tags, isEmpty);
      expect(decoded.errors, isEmpty);
    });

    test('fromJson defaults source to manual for missing key', () {
      final json = {'id': 'capture_1', 'timestamp': '2025-06-15T10:30:00.000'};
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.source, CaptureSource.manual);
      expect(decoded.trigger, isNull);
    });

    test('fromJson parses source enum correctly', () {
      final json = {
        'id': 'capture_1',
        'timestamp': '2025-06-15T10:30:00.000',
        'source': 'backgroundScheduled',
        'trigger': 'time',
      };
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.source, CaptureSource.backgroundScheduled);
      expect(decoded.trigger, CaptureTrigger.time);
    });

    test('fromJson falls back to manual for unknown source', () {
      final json = {
        'id': 'capture_1',
        'timestamp': '2025-06-15T10:30:00.000',
        'source': 'unknownSource',
      };
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.source, CaptureSource.manual);
    });

    test('fromJson falls back to manual for unknown trigger', () {
      final json = {
        'id': 'capture_1',
        'timestamp': '2025-06-15T10:30:00.000',
        'trigger': 'unknownTrigger',
      };
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.trigger, CaptureTrigger.manual);
    });

    test('fromJson parses processedAt', () {
      final json = {
        'id': 'capture_1',
        'timestamp': '2025-06-15T10:30:00.000',
        'processed_at': '2025-06-15T12:00:00.000',
        'is_processed': 1,
        'ai_insights': 'Some insights',
      };
      final decoded = CaptureEntry.fromJson(json);
      expect(decoded.isProcessed, true);
      expect(decoded.processedAt, DateTime(2025, 6, 15, 12, 0));
      expect(decoded.aiInsights, 'Some insights');
    });

    // ── copyWith ──

    test('copyWith preserves all values when no args', () {
      final original = sampleEntry();
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.timestamp, original.timestamp);
      expect(copy.userNote, original.userNote);
      expect(copy.healthData!.steps, 3000);
      expect(copy.source, original.source);
    });

    test('copyWith overrides specified fields', () {
      final original = sampleEntry();
      final copy = original.copyWith(
        isProcessed: true,
        userNote: 'Updated note',
        tags: ['updated'],
      );
      expect(copy.isProcessed, true);
      expect(copy.userNote, 'Updated note');
      expect(copy.tags, ['updated']);
      // unchanged
      expect(copy.id, original.id);
    });

    test('copyWith clear flags set fields to null', () {
      final original = sampleEntry();
      final copy = original.copyWith(
        clearUserNote: true,
        clearUserMood: true,
        clearHealthData: true,
        clearEnvironmentData: true,
        clearLocationData: true,
        clearTrigger: true,
        clearExecutionDuration: true,
        clearBatteryLevel: true,
      );
      expect(copy.userNote, isNull);
      expect(copy.userMood, isNull);
      expect(copy.healthData, isNull);
      expect(copy.environmentData, isNull);
      expect(copy.locationData, isNull);
      expect(copy.trigger, isNull);
      expect(copy.executionDuration, isNull);
      expect(copy.batteryLevel, isNull);
    });

    test('copyWith clearProcessedAt / clearAiInsights', () {
      final original = sampleEntry(
        isProcessed: true,
      ).copyWith(processedAt: DateTime(2025, 1, 1), aiInsights: 'insight');
      final copy = original.copyWith(
        clearProcessedAt: true,
        clearAiInsights: true,
      );
      expect(copy.processedAt, isNull);
      expect(copy.aiInsights, isNull);
    });
  });
}
