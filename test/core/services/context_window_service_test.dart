import 'package:bodypress_flutter/core/models/body_blog_entry.dart';
import 'package:bodypress_flutter/core/services/context_window_service.dart';
import 'package:bodypress_flutter/core/services/local_db_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal fake [LocalDbService] that returns pre-set entries.
///
/// We only override [loadRecentEntries] since that's the only method
/// used by [ContextWindowService].
class _FakeLocalDbService extends LocalDbService {
  final List<BodyBlogEntry> entries;

  _FakeLocalDbService(this.entries);

  @override
  Future<List<BodyBlogEntry>> loadRecentEntries(int days) async => entries;
}

void main() {
  group('ContextWindowService', () {
    test('build returns empty-window text when DB has no entries', () async {
      final service = ContextWindowService(db: _FakeLocalDbService([]));
      final result = await service.build();

      expect(result.entries, isEmpty);
      expect(result.text, contains('7-DAY CONTEXT WINDOW'));
      expect(result.text, contains('No entries stored yet'));
      expect(result.text, contains('END CONTEXT WINDOW'));
    });

    test('build renders entries with all snapshot fields', () async {
      final entries = [
        BodyBlogEntry(
          date: DateTime(2025, 6, 15),
          headline: 'Strong morning momentum',
          summary: 'Legs felt powerful and steady.',
          fullBody: 'Body content here…',
          mood: 'energised',
          moodEmoji: '⚡',
          tags: ['12k steps', 'sunny'],
          snapshot: const BodySnapshot(
            steps: 12000,
            caloriesBurned: 450,
            distanceKm: 8.5,
            sleepHours: 7.5,
            avgHeartRate: 68,
            workouts: 1,
            temperatureC: 22.0,
            aqiUs: 30,
            uvIndex: 5.0,
            weatherDesc: 'Clear sky',
            city: 'Montreal',
            calendarEvents: ['Team standup', 'Lunch'],
          ),
          userNote: 'Had a great run!',
          userMood: '😊',
        ),
      ];

      final service = ContextWindowService(db: _FakeLocalDbService(entries));
      final result = await service.build(days: 7);

      expect(result.entries, hasLength(1));
      final text = result.text;

      // Window header
      expect(text, contains('7-DAY CONTEXT WINDOW'));
      expect(text, contains('1 entry'));

      // Date line
      expect(text, contains('2025-06-15'));

      // Mood
      expect(text, contains('Mood: energised ⚡'));

      // Sleep
      expect(text, contains('Sleep: 7.5 h'));

      // Movement
      expect(text, contains('12000 steps'));
      expect(text, contains('8.5 km'));
      expect(text, contains('450 kcal'));

      // Workouts
      expect(text, contains('Workouts: 1 session'));

      // Heart rate
      expect(text, contains('Heart rate: 68 bpm'));

      // Environment
      expect(text, contains('22°C'));
      expect(text, contains('Clear sky'));
      expect(text, contains('AQI 30'));
      expect(text, contains('UV 5.0'));
      expect(text, contains('(Montreal)'));

      // Calendar
      expect(text, contains('2 events'));
      expect(text, contains('Team standup'));

      // Narrative
      expect(text, contains('Headline: Strong morning momentum'));
      expect(text, contains('Summary: Legs felt powerful'));

      // User annotation
      expect(text, contains('User mood: 😊'));
      expect(text, contains('User note: "Had a great run!"'));

      // Footer
      expect(text, contains('END CONTEXT WINDOW'));
    });

    test('build renders "no data" for empty snapshots', () async {
      final entries = [
        BodyBlogEntry(
          date: DateTime(2025, 6, 15),
          headline: 'Waiting for data…',
          summary: "This day's journal is still being written.",
          fullBody: '',
          mood: 'calm',
          moodEmoji: '🌿',
          tags: [],
          snapshot: const BodySnapshot(), // all zeros
        ),
      ];

      final service = ContextWindowService(db: _FakeLocalDbService(entries));
      final result = await service.build();
      final text = result.text;

      expect(text, contains('Sleep: no data'));
      expect(text, contains('Movement: no data'));
      // Headline "Waiting for data…" should be skipped
      expect(text, isNot(contains('Headline:')));
    });

    test('build shows plural entries count', () async {
      final entries = [
        BodyBlogEntry(
          date: DateTime(2025, 6, 15),
          headline: 'Day 1',
          summary: 's',
          fullBody: 'b',
          mood: 'calm',
          moodEmoji: '🌿',
          tags: [],
          snapshot: const BodySnapshot(),
        ),
        BodyBlogEntry(
          date: DateTime(2025, 6, 14),
          headline: 'Day 2',
          summary: 's',
          fullBody: 'b',
          mood: 'calm',
          moodEmoji: '🌿',
          tags: [],
          snapshot: const BodySnapshot(),
        ),
      ];

      final service = ContextWindowService(db: _FakeLocalDbService(entries));
      final result = await service.build();
      expect(result.text, contains('2 entries'));
    });

    test('custom days parameter is used in header', () async {
      final service = ContextWindowService(db: _FakeLocalDbService([]));
      final result = await service.build(days: 14);
      expect(result.text, contains('14-DAY CONTEXT WINDOW'));
    });
  });
}
