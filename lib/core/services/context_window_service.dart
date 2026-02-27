import 'package:intl/intl.dart';

import '../models/body_blog_entry.dart';
import 'local_db_service.dart';

/// Composes a plain-text rolling context window from persisted entries.
///
/// Intended for two uses:
///   1. Debug panel — readable at a glance inside the app.
///   2. LLM prompt context — structured enough to paste straight into a
///      system/user message once the AI narrative feature is wired up.
class ContextWindowService {
  final LocalDbService _db;

  ContextWindowService({LocalDbService? db}) : _db = db ?? LocalDbService();

  static const int defaultWindowDays = 7;

  // ── public API ─────────────────────────────────────────────────────────────

  /// Build the rolling context string for the last [days] days.
  /// Returns the text and the entries that were used.
  Future<ContextWindowResult> build({int days = defaultWindowDays}) async {
    final entries = await _db.loadRecentEntries(days);
    final text = _render(entries, days);
    return ContextWindowResult(text: text, entries: entries);
  }

  // ── rendering ──────────────────────────────────────────────────────────────

  String _render(List<BodyBlogEntry> entries, int windowSize) {
    final buf = StringBuffer();
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    final dayFmt = DateFormat('EEEE');

    buf.writeln(
      '=== $windowSize-DAY CONTEXT WINDOW'
      '  (generated: ${DateFormat("yyyy-MM-dd'T'HH:mm").format(now)})',
    );

    if (entries.isEmpty) {
      buf.writeln('No entries stored yet. Run the app for at least one day.');
      buf.writeln('=== END CONTEXT WINDOW ===');
      return buf.toString();
    }

    final oldest = entries.last.date;
    final newest = entries.first.date;
    buf.writeln(
      'Window: ${fmt.format(oldest)} → ${fmt.format(newest)}'
      '  |  ${entries.length} entr${entries.length == 1 ? 'y' : 'ies'}',
    );
    buf.writeln();

    for (final e in entries) {
      final s = e.snapshot;
      buf.writeln('--- ${fmt.format(e.date)} (${dayFmt.format(e.date)}) ---');
      buf.writeln('Mood: ${e.mood} ${e.moodEmoji}');

      // Sleep
      if (s.sleepHours > 0) {
        buf.writeln('Sleep: ${s.sleepHours.toStringAsFixed(1)} h');
      } else {
        buf.writeln('Sleep: no data');
      }

      // Movement
      final moveParts = <String>[];
      if (s.steps > 0) moveParts.add('${s.steps} steps');
      if (s.distanceKm > 0) {
        moveParts.add('${s.distanceKm.toStringAsFixed(1)} km');
      }
      if (s.caloriesBurned > 0) {
        moveParts.add('${s.caloriesBurned.toStringAsFixed(0)} kcal');
      }
      buf.writeln(
        moveParts.isEmpty
            ? 'Movement: no data'
            : 'Movement: ${moveParts.join("  |  ")}',
      );
      if (s.workouts > 0) {
        buf.writeln(
          'Workouts: ${s.workouts} session${s.workouts > 1 ? "s" : ""}',
        );
      }

      // Heart
      if (s.avgHeartRate > 0) {
        buf.writeln('Heart rate: ${s.avgHeartRate} bpm (avg)');
      }

      // Environment
      final envParts = <String>[];
      if (s.temperatureC != null) {
        envParts.add('${s.temperatureC!.toStringAsFixed(0)}°C');
      }
      if (s.weatherDesc != null && s.weatherDesc!.isNotEmpty) {
        envParts.add(s.weatherDesc!);
      }
      if (s.aqiUs != null) envParts.add('AQI ${s.aqiUs}');
      if (s.uvIndex != null) {
        envParts.add('UV ${s.uvIndex!.toStringAsFixed(1)}');
      }
      if (s.city != null && s.city!.isNotEmpty) envParts.add('(${s.city})');
      if (envParts.isNotEmpty) {
        buf.writeln('Environment: ${envParts.join(", ")}');
      }

      // Calendar
      if (s.calendarEvents.isNotEmpty) {
        final evList = s.calendarEvents.join(', ');
        buf.writeln(
          'Calendar: ${s.calendarEvents.length} event${s.calendarEvents.length > 1 ? "s" : ""}'
          ' ($evList)',
        );
      }

      // Narrative headline + summary (compact)
      if (e.headline.isNotEmpty && e.headline != 'Waiting for data…') {
        buf.writeln('Headline: ${e.headline}');
      }
      if (e.summary.isNotEmpty && !e.summary.startsWith("This day's journal")) {
        buf.writeln('Summary: ${e.summary}');
      }

      // User annotation
      if (e.userNote != null && e.userNote!.isNotEmpty) {
        buf.writeln('User note: "${e.userNote}"');
      }

      buf.writeln();
    }

    buf.write('=== END CONTEXT WINDOW ===');
    return buf.toString();
  }
}

/// Return value of [ContextWindowService.build].
class ContextWindowResult {
  final String text;
  final List<BodyBlogEntry> entries;

  const ContextWindowResult({required this.text, required this.entries});
}
