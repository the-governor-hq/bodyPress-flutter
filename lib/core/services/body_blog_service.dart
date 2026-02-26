import 'package:device_calendar/device_calendar.dart';

import '../models/body_blog_entry.dart';
import 'ambient_scan_service.dart';
import 'calendar_service.dart';
import 'health_service.dart';
import 'location_service.dart';

/// Service that collects real device data and generates a daily body-blog
/// narrative.
///
/// In v1 the narrative is composed locally from templates. In a future
/// version this will call an LLM endpoint (OpenAI / Gemini / local model)
/// with the [BodySnapshot] as structured context.
class BodyBlogService {
  final HealthService _health = HealthService();
  final LocationService _location = LocationService();
  final CalendarService _calendar = CalendarService();
  final AmbientScanService _ambient = AmbientScanService();

  // ── public API ──────────────────────────────────────────────────

  /// Build today's blog entry from live device data.
  Future<BodyBlogEntry> getTodayEntry() async {
    final snapshot = await _collectSnapshot();
    return _compose(DateTime.now(), snapshot);
  }

  /// Build entries for the last [days] days.
  /// Only today has real data; past days get skeleton entries.
  Future<List<BodyBlogEntry>> getRecentEntries({int days = 7}) async {
    final today = DateTime.now();
    final entries = <BodyBlogEntry>[];

    // Today – live data
    final todaySnap = await _collectSnapshot();
    entries.add(_compose(today, todaySnap));

    // Previous days – placeholder structure (real persistence comes later)
    for (var i = 1; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      entries.add(_composeEmpty(date));
    }

    return entries;
  }

  // ── data collection ─────────────────────────────────────────────

  Future<BodySnapshot> _collectSnapshot() async {
    int steps = 0;
    double cals = 0;
    double dist = 0;
    double sleep = 0;
    int hr = 0;
    int workouts = 0;

    try {
      steps = await _health.getTodaySteps().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}
    try {
      cals = await _health.getTodayCalories().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}
    try {
      dist = await _health.getTodayDistance().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}
    try {
      sleep = await _health.getLastNightSleep().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}
    try {
      hr = await _health.getTodayAverageHeartRate().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}
    try {
      workouts = await _health.getTodayWorkoutCount().timeout(
        const Duration(seconds: 5),
        onTimeout: () => 0,
      );
    } catch (_) {}

    // Location + environment
    double? tempC;
    int? aqi;
    double? uv;
    String? weatherDesc;
    String? city;
    try {
      final pos = await _location.getCurrentLocation().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      if (pos != null) {
        final env = await _ambient
            .scanByCoordinates(pos.latitude, pos.longitude)
            .timeout(const Duration(seconds: 8), onTimeout: () => null);
        if (env != null) {
          tempC = env.temperature.currentC;
          aqi = env.airQuality.usAqi;
          uv = env.uvIndex.current;
          weatherDesc = env.conditions.description;
          city = env.meta.city;
        }
      }
    } catch (_) {}

    // Calendar
    final calEvents = <String>[];
    try {
      final hasPerm = await _calendar.hasPermissions().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (hasPerm) {
        final events = await _calendar.getTodayEvents().timeout(
          const Duration(seconds: 5),
          onTimeout: () => <Event>[],
        );
        for (final e in events) {
          if (e.title != null && e.title!.isNotEmpty) {
            calEvents.add(e.title!);
          }
        }
      }
    } catch (_) {}

    return BodySnapshot(
      steps: steps,
      caloriesBurned: cals,
      distanceKm: dist / 1000,
      sleepHours: sleep,
      avgHeartRate: hr,
      workouts: workouts,
      temperatureC: tempC,
      aqiUs: aqi,
      uvIndex: uv,
      weatherDesc: weatherDesc,
      city: city,
      calendarEvents: calEvents,
    );
  }

  // ── narrative composition (local v1 — LLM-ready) ───────────────

  BodyBlogEntry _compose(DateTime date, BodySnapshot s) {
    final mood = _inferMood(s);
    final moodEmoji = _moodEmoji(mood);
    final tags = _buildTags(s);

    final headline = _buildHeadline(s, mood);
    final summary = _buildSummary(s, mood);
    final body = _buildBody(s, mood);

    return BodyBlogEntry(
      date: date,
      headline: headline,
      summary: summary,
      fullBody: body,
      mood: mood,
      moodEmoji: moodEmoji,
      tags: tags,
      snapshot: s,
    );
  }

  BodyBlogEntry _composeEmpty(DateTime date) {
    return BodyBlogEntry(
      date: date,
      headline: 'Waiting for data…',
      summary: 'This day\'s journal will appear once data is synced.',
      fullBody: '',
      mood: 'neutral',
      moodEmoji: '🌿',
      tags: const [],
      snapshot: const BodySnapshot(),
    );
  }

  // ── mood inference ──────────────────────────────────────────────

  String _inferMood(BodySnapshot s) {
    // Simple heuristic; replace with ML / LLM later
    if (s.sleepHours >= 7 && s.steps >= 5000 && s.avgHeartRate > 0) {
      return 'energised';
    }
    if (s.sleepHours < 5 && s.sleepHours > 0) return 'tired';
    if (s.steps >= 8000) return 'active';
    if (s.aqiUs != null && s.aqiUs! > 100) return 'cautious';
    if (s.sleepHours >= 7) return 'rested';
    if (s.steps == 0 && s.caloriesBurned == 0) return 'quiet';
    return 'calm';
  }

  String _moodEmoji(String mood) {
    switch (mood) {
      case 'energised':
        return '⚡';
      case 'tired':
        return '😴';
      case 'active':
        return '🏃';
      case 'cautious':
        return '🌫️';
      case 'rested':
        return '🧘';
      case 'quiet':
        return '🌙';
      default:
        return '🌿';
    }
  }

  List<String> _buildTags(BodySnapshot s) {
    final tags = <String>[];
    if (s.steps > 0) tags.add('${s.steps} steps');
    if (s.sleepHours > 0) tags.add('${s.sleepHours.toStringAsFixed(1)}h sleep');
    if (s.avgHeartRate > 0) tags.add('${s.avgHeartRate} bpm');
    if (s.temperatureC != null) {
      tags.add('${s.temperatureC!.toStringAsFixed(0)}°C');
    }
    if (s.weatherDesc != null && s.weatherDesc!.isNotEmpty) {
      tags.add(s.weatherDesc!);
    }
    if (s.calendarEvents.isNotEmpty) {
      tags.add('${s.calendarEvents.length} events');
    }
    return tags;
  }

  // ── headline ────────────────────────────────────────────────────

  String _buildHeadline(BodySnapshot s, String mood) {
    switch (mood) {
      case 'energised':
        return 'Your body is buzzing with energy today';
      case 'tired':
        return 'A gentle start — your body is asking for rest';
      case 'active':
        return 'On the move — your body is loving the motion';
      case 'cautious':
        return 'The air outside needs your attention';
      case 'rested':
        return 'Well-rested — a calm canvas for the day';
      case 'quiet':
        return 'A still morning — your body is listening';
      default:
        return 'Your body speaks — a moment of awareness';
    }
  }

  // ── summary (2-3 sentences) ─────────────────────────────────────

  String _buildSummary(BodySnapshot s, String mood) {
    final parts = <String>[];

    // Sleep
    if (s.sleepHours > 0) {
      if (s.sleepHours >= 7) {
        parts.add(
          'You got ${s.sleepHours.toStringAsFixed(1)} hours of sleep — your body feels recharged.',
        );
      } else if (s.sleepHours >= 5) {
        parts.add(
          '${s.sleepHours.toStringAsFixed(1)} hours of sleep. Decent, but your body wouldn\'t mind a bit more.',
        );
      } else {
        parts.add(
          'Only ${s.sleepHours.toStringAsFixed(1)} hours of sleep. Your body is flagging this — consider resting early tonight.',
        );
      }
    }

    // Activity
    if (s.steps > 0) {
      if (s.steps >= 8000) {
        parts.add(
          '${s.steps} steps so far — your muscles are grateful for the movement.',
        );
      } else if (s.steps >= 3000) {
        parts.add(
          '${s.steps} steps and counting. A steady rhythm your body appreciates.',
        );
      } else {
        parts.add(
          '${s.steps} steps today. Even small movements matter — your joints agree.',
        );
      }
    }

    // Environment
    if (s.weatherDesc != null && s.city != null) {
      parts.add(
        'Outside in ${s.city}: ${s.weatherDesc}, ${s.temperatureC?.toStringAsFixed(0) ?? '-'}°C.',
      );
    }

    if (parts.isEmpty) {
      parts.add('Your body is present. Data will fill in as the day unfolds.');
    }

    return parts.join(' ');
  }

  // ── full body (long-form narrative) ─────────────────────────────

  String _buildBody(BodySnapshot s, String mood) {
    final buf = StringBuffer();

    // Opening
    buf.writeln(
      'You slept 6h 12m — about 58 minutes shorter than your 14-day average.\n',
    );

    // Sleep section
    if (s.sleepHours > 0) {
      buf.writeln('— Sleep —');
      if (s.sleepHours >= 7) {
        buf.writeln(
          'Last night you gave me ${s.sleepHours.toStringAsFixed(1)} hours of rest. '
          'My cells are humming with recovery. Muscles rebuilt, memories '
          'consolidated, immune defences topped up. Thank you.',
        );
      } else {
        buf.writeln(
          'I only got ${s.sleepHours.toStringAsFixed(1)} hours last night. '
          'I can feel the deficit — cortisol is a touch higher, focus may '
          'wander. If you can, a 20-minute nap today would be a gift.',
        );
      }
      buf.writeln();
    }

    // Movement section
    if (s.steps > 0 || s.caloriesBurned > 0) {
      buf.writeln('— Movement —');
      if (s.steps > 0) {
        buf.writeln(
          'So far: ${s.steps} steps, ${s.distanceKm.toStringAsFixed(1)} km. ',
        );
      }
      if (s.caloriesBurned > 0) {
        buf.writeln(
          'Energy spent: ${s.caloriesBurned.toStringAsFixed(0)} kcal. ',
        );
      }
      if (s.workouts > 0) {
        buf.writeln(
          'I registered ${s.workouts} workout${s.workouts > 1 ? 's' : ''} today — well done.',
        );
      }
      buf.writeln(
        'Every step sends oxygen through me, feeds the brain, nudges '
        'the lymphatic system awake. Keep it up.',
      );
      buf.writeln();
    }

    // Heart
    if (s.avgHeartRate > 0) {
      buf.writeln('— Heart —');
      buf.writeln('Average heart rate today: ${s.avgHeartRate} bpm. ');
      if (s.avgHeartRate < 70) {
        buf.writeln('Calm and steady — a sign of good cardiovascular fitness.');
      } else if (s.avgHeartRate < 90) {
        buf.writeln('Normal range. Your ticker is doing just fine.');
      } else {
        buf.writeln(
          'A bit elevated. Could be exertion, stress, or caffeine — '
          'I\'ll keep monitoring.',
        );
      }
      buf.writeln();
    }

    // Environment
    if (s.weatherDesc != null) {
      buf.writeln('— Environment —');
      buf.write(
        '${s.city != null ? 'In ${s.city}' : 'Your area'}: '
        '${s.weatherDesc}, ${s.temperatureC?.toStringAsFixed(0) ?? '-'}°C.',
      );
      if (s.aqiUs != null) {
        buf.write(' Air quality index: ${s.aqiUs}.');
        if (s.aqiUs! > 100) {
          buf.write(
            ' That\'s moderate-to-poor — consider limiting outdoor exertion.',
          );
        }
      }
      if (s.uvIndex != null && s.uvIndex! > 5) {
        buf.write(
          ' UV is ${s.uvIndex!.toStringAsFixed(1)} — sunscreen advised.',
        );
      }
      buf.writeln();
      buf.writeln();
    }

    // Calendar
    if (s.calendarEvents.isNotEmpty) {
      buf.writeln('— Your Agenda —');
      buf.writeln(
        'You have ${s.calendarEvents.length} event${s.calendarEvents.length > 1 ? 's' : ''} today:',
      );
      for (final ev in s.calendarEvents) {
        buf.writeln('  • $ev');
      }
      buf.writeln(
        '\nRemember to breathe between commitments. I do better when '
        'you take micro-breaks.',
      );
      buf.writeln();
    }

    // Closing
    buf.writeln('—');
    buf.writeln('Stay present. I\'m always here, listening.');
    buf.writeln('\nYour Body');

    return buf.toString();
  }
}
