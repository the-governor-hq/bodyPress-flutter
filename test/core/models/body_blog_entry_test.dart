import 'dart:convert';

import 'package:bodypress_flutter/core/models/body_blog_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── BodySnapshot ─────────────────────────────────────────────────────────

  group('BodySnapshot', () {
    test('default constructor uses zeros / nulls', () {
      const s = BodySnapshot();
      expect(s.steps, 0);
      expect(s.caloriesBurned, 0);
      expect(s.distanceKm, 0);
      expect(s.sleepHours, 0);
      expect(s.avgHeartRate, 0);
      expect(s.workouts, 0);
      expect(s.temperatureC, isNull);
      expect(s.aqiUs, isNull);
      expect(s.uvIndex, isNull);
      expect(s.weatherDesc, isNull);
      expect(s.city, isNull);
      expect(s.calendarEvents, isEmpty);
    });

    test('toJson / fromJson round-trip', () {
      const original = BodySnapshot(
        steps: 8500,
        caloriesBurned: 320.5,
        distanceKm: 6.2,
        sleepHours: 7.5,
        avgHeartRate: 72,
        workouts: 1,
        temperatureC: 18.3,
        aqiUs: 42,
        uvIndex: 3.5,
        weatherDesc: 'Partly cloudy',
        city: 'Montreal',
        calendarEvents: ['Standup', 'Lunch'],
      );

      final json = original.toJson();
      final decoded = BodySnapshot.fromJson(json);

      expect(decoded.steps, original.steps);
      expect(decoded.caloriesBurned, original.caloriesBurned);
      expect(decoded.distanceKm, original.distanceKm);
      expect(decoded.sleepHours, original.sleepHours);
      expect(decoded.avgHeartRate, original.avgHeartRate);
      expect(decoded.workouts, original.workouts);
      expect(decoded.temperatureC, original.temperatureC);
      expect(decoded.aqiUs, original.aqiUs);
      expect(decoded.uvIndex, original.uvIndex);
      expect(decoded.weatherDesc, original.weatherDesc);
      expect(decoded.city, original.city);
      // calendarEvents are stored as jsonEncoded string
      expect(decoded.calendarEvents, original.calendarEvents);
    });

    test('fromJson handles null calendar_events', () {
      final s = BodySnapshot.fromJson({});
      expect(s.calendarEvents, isEmpty);
      expect(s.steps, 0);
    });

    test('fromJson handles missing fields with defaults', () {
      final s = BodySnapshot.fromJson({'steps': 100});
      expect(s.steps, 100);
      expect(s.caloriesBurned, 0);
      expect(s.temperatureC, isNull);
    });
  });

  // ─── BodyBlogEntry ────────────────────────────────────────────────────────

  group('BodyBlogEntry', () {
    BodyBlogEntry sampleEntry({
      String? userNote,
      String? userMood,
      bool aiGenerated = true,
    }) {
      return BodyBlogEntry(
        date: DateTime(2025, 3, 15),
        headline: 'A balanced day',
        summary: 'Good rest, moderate activity.',
        fullBody: 'Today your body moved gently...',
        mood: 'calm',
        moodEmoji: '🌿',
        tags: ['8k steps', '7h sleep'],
        snapshot: const BodySnapshot(steps: 8000, sleepHours: 7),
        userNote: userNote,
        userMood: userMood,
        aiGenerated: aiGenerated,
      );
    }

    test('toJson / fromJson round-trip', () {
      final original = sampleEntry(userNote: 'Felt great', userMood: '😊');
      final json = original.toJson();
      final decoded = BodyBlogEntry.fromJson(json);

      expect(decoded.date, original.date);
      expect(decoded.headline, original.headline);
      expect(decoded.summary, original.summary);
      expect(decoded.fullBody, original.fullBody);
      expect(decoded.mood, original.mood);
      expect(decoded.moodEmoji, original.moodEmoji);
      expect(decoded.tags, original.tags);
      expect(decoded.userNote, original.userNote);
      expect(decoded.userMood, original.userMood);
      expect(decoded.aiGenerated, true);
      expect(decoded.snapshot.steps, 8000);
      expect(decoded.snapshot.sleepHours, 7);
    });

    test('fromJson handles null tags / snapshot', () {
      final json = <String, dynamic>{
        'date': '2025-03-15T00:00:00.000',
        'headline': 'h',
        'summary': 's',
        'full_body': 'b',
        'mood': 'm',
        'mood_emoji': '🌿',
        'tags': null,
        'snapshot': null,
        'ai_generated': 0,
      };
      final entry = BodyBlogEntry.fromJson(json);
      expect(entry.tags, isEmpty);
      expect(entry.snapshot.steps, 0); // default BodySnapshot
      expect(entry.aiGenerated, false);
    });

    test('aiGenerated defaults to false', () {
      final json = <String, dynamic>{
        'date': '2025-03-15T00:00:00.000',
        'headline': 'h',
        'summary': 's',
        'full_body': 'b',
        'mood': 'm',
        'mood_emoji': '🌿',
      };
      final entry = BodyBlogEntry.fromJson(json);
      expect(entry.aiGenerated, false);
    });

    // ── copyWith ──

    test('copyWith preserves values when no args', () {
      final original = sampleEntry(userNote: 'note', userMood: '😊');
      final copy = original.copyWith();
      expect(copy.headline, original.headline);
      expect(copy.userNote, original.userNote);
      expect(copy.userMood, original.userMood);
    });

    test('copyWith overrides specified fields', () {
      final original = sampleEntry();
      final copy = original.copyWith(
        headline: 'New headline',
        mood: 'energised',
        aiGenerated: true,
      );
      expect(copy.headline, 'New headline');
      expect(copy.mood, 'energised');
      expect(copy.aiGenerated, true);
      // unchanged
      expect(copy.summary, original.summary);
    });

    test('copyWith clearUserNote sets userNote to null', () {
      final original = sampleEntry(userNote: 'some note');
      final copy = original.copyWith(clearUserNote: true);
      expect(copy.userNote, isNull);
    });

    test('copyWith clearUserMood sets userMood to null', () {
      final original = sampleEntry(userMood: '😊');
      final copy = original.copyWith(clearUserMood: true);
      expect(copy.userMood, isNull);
    });

    test('toJson stores tags and snapshot as encoded strings', () {
      final entry = sampleEntry();
      final json = entry.toJson();
      // tags should be a JSON string, not a List
      expect(json['tags'], isA<String>());
      expect(jsonDecode(json['tags'] as String), ['8k steps', '7h sleep']);
      // snapshot should be a JSON string, not a Map
      expect(json['snapshot'], isA<String>());
    });

    test('toJson stores aiGenerated as 1/0', () {
      expect(sampleEntry(aiGenerated: true).toJson()['ai_generated'], 1);
      expect(sampleEntry(aiGenerated: false).toJson()['ai_generated'], 0);
    });
  });
}
