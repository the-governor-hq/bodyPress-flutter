import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/capture_ai_metadata.dart';
import '../models/capture_entry.dart';
import 'ai_service.dart';
import 'local_db_service.dart';

/// Background service that generates [CaptureAiMetadata] for every new capture.
///
/// After each capture is saved, `processCapture` is called fire-and-forget
/// style. The AI examines the capture data and returns structured metadata
/// (themes, energy level, notable signals, …) that is streamed into the
/// Patterns screen as it accumulates.
///
/// Processing is idempotent: captures that already have metadata are skipped.
class CaptureMetadataService {
  final AiService _ai;
  final LocalDbService _db;

  CaptureMetadataService({required AiService ai, required LocalDbService db})
    : _ai = ai,
      _db = db;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Generate and persist AI metadata for a single capture.
  ///
  /// If the capture already has metadata or cannot be found, this is a no-op.
  /// Errors are caught and logged — a metadata failure should never surface
  /// to the user.
  Future<void> processCapture(String captureId) async {
    try {
      final capture = await _db.loadCapture(captureId);
      if (capture == null || capture.aiMetadata != null) return;

      final metadata = await _generateMetadata(capture);
      if (metadata == null) return;

      await _db.updateCaptureAiMetadata(captureId, metadata.encode());
      debugPrint('[CaptureMetadata] ✓ ${captureId.substring(0, 20)}…');
    } catch (e) {
      debugPrint('[CaptureMetadata] ✗ error for $captureId: $e');
    }
  }

  /// Process all captures that have no AI metadata yet.
  ///
  /// [onProgress] is called after each capture attempt with
  /// `(done, total)` counts — use it to drive a progress UI.
  ///
  /// Useful on app start to catch up on any captures that failed or were
  /// created before this feature existed. Returns the number processed.
  Future<int> processAllPendingMetadata({
    void Function(int done, int total)? onProgress,
  }) async {
    final allCaptures = await _db.loadCaptures();
    final pending = allCaptures.where((c) => c.aiMetadata == null).toList();

    debugPrint(
      '[CaptureMetadata] Processing ${pending.length} pending captures…',
    );

    // Report the initial total immediately so the UI can show the denominator.
    onProgress?.call(0, pending.length);

    int processed = 0;
    for (final capture in pending) {
      try {
        final metadata = await _generateMetadata(capture);
        if (metadata != null) {
          await _db.updateCaptureAiMetadata(capture.id, metadata.encode());
          processed++;
        }
      } catch (e) {
        debugPrint('[CaptureMetadata] ✗ error for ${capture.id}: $e');
      }
      // Always tick progress, even on failure, so the bar keeps moving.
      onProgress?.call(processed, pending.length);
    }

    debugPrint(
      '[CaptureMetadata] Done — $processed/${pending.length} processed.',
    );
    return processed;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Call the AI and parse the response into a [CaptureAiMetadata].
  Future<CaptureAiMetadata?> _generateMetadata(CaptureEntry capture) async {
    final prompt = _buildPrompt(capture);

    final raw = await _ai.ask(
      prompt,
      systemPrompt:
          'You are a holistic body-data analyst. '
          'You receive biometric and contextual snapshots and return concise structured JSON. '
          'Always respond with ONLY the JSON object, no markdown fences, no commentary.',
      temperature: 0.3,
      maxTokens: 400,
    );

    return _parseResponse(raw);
  }

  /// Build the text prompt sent to the AI.
  String _buildPrompt(CaptureEntry c) {
    final buf = StringBuffer();
    buf.writeln(
      'Analyse this body/context capture and return structured JSON metadata.',
    );
    buf.writeln();
    buf.writeln('CAPTURE DATA:');
    buf.writeln('• Timestamp : ${c.timestamp.toIso8601String()}');

    if (c.userMood != null) buf.writeln('• Mood emoji : ${c.userMood}');
    if (c.userNote != null && c.userNote!.isNotEmpty) {
      buf.writeln('• User note  : ${c.userNote}');
    }

    final h = c.healthData;
    if (h != null) {
      buf.writeln('HEALTH:');
      if (h.steps != null) buf.writeln('  steps=${h.steps}');
      if (h.heartRate != null) buf.writeln('  heart_rate=${h.heartRate} bpm');
      if (h.sleepHours != null) {
        buf.writeln('  sleep=${h.sleepHours!.toStringAsFixed(1)} h');
      }
      if (h.calories != null) {
        buf.writeln('  calories=${h.calories!.toStringAsFixed(0)} kcal');
      }
      if (h.workouts != null) buf.writeln('  workouts=${h.workouts}');
      if (h.distance != null) {
        buf.writeln('  distance=${h.distance!.toStringAsFixed(0)} m');
      }
    }

    final e = c.environmentData;
    if (e != null) {
      buf.writeln('ENVIRONMENT:');
      if (e.temperature != null) buf.writeln('  temp=${e.temperature}°C');
      if (e.conditions != null) buf.writeln('  conditions=${e.conditions}');
      if (e.aqi != null) buf.writeln('  aqi=${e.aqi}');
      if (e.uvIndex != null) buf.writeln('  uv=${e.uvIndex}');
      if (e.humidity != null) buf.writeln('  humidity=${e.humidity}%');
    }

    final l = c.locationData;
    if (l != null) {
      buf.writeln('LOCATION:');
      if (l.city != null) buf.writeln('  city=${l.city}');
      if (l.region != null) buf.writeln('  region=${l.region}');
      if (l.country != null) buf.writeln('  country=${l.country}');
    }

    if (c.calendarEvents.isNotEmpty) {
      buf.writeln('CALENDAR: ${c.calendarEvents.join(', ')}');
    }

    buf.writeln();
    buf.writeln('Return ONLY valid JSON with this exact structure:');
    buf.writeln('''{
  "summary": "<one sentence describing this moment>",
  "themes": ["<theme1>", "<theme2>"],
  "energy_level": "<high|medium|low>",
  "mood_assessment": "<brief mood description>",
  "tags": ["<tag1>", "<tag2>"],
  "notable_signals": ["<signal1>"]
}''');

    return buf.toString();
  }

  /// Parse the raw AI text into a [CaptureAiMetadata], stripping any accidental
  /// markdown fences.
  CaptureAiMetadata? _parseResponse(String raw) {
    try {
      // Strip potential markdown fences
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```[a-z]*\n?', multiLine: false), '')
            .replaceAll(RegExp(r'```$', multiLine: false), '')
            .trim();
      }

      final jsonStart = cleaned.indexOf('{');
      final jsonEnd = cleaned.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;

      final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CaptureAiMetadata.fromJson({
        ...decoded,
        'generated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint(
        '[CaptureMetadata] Failed to parse AI response: $e\nRaw: $raw',
      );
      return null;
    }
  }
}
