import 'dart:convert';

/// AI-generated metadata extracted from a [CaptureEntry].
///
/// The AI analyses every newly saved capture in the background and
/// derives structured insights that are then aggregated on the
/// Patterns screen to surface trends over time.
class CaptureAiMetadata {
  /// One-sentence plain-language summary of what the capture represents.
  final String summary;

  /// High-level recurring themes identified in this capture.
  /// Examples: "recovery", "productive-morning", "stress", "outdoor-activity".
  final List<String> themes;

  /// Perceived energy level based on health + context signals.
  /// One of: "high", "medium", "low".
  final String energyLevel;

  /// Brief AI-assessed mood description (e.g. "calm and focused").
  final String moodAssessment;

  /// Concise keyword tags for search / grouping.
  final List<String> tags;

  /// Notable data signals worth calling out.
  /// Examples: "elevated heart rate", "poor sleep", "high UV".
  final List<String> notableSignals;

  /// When this metadata was generated.
  final DateTime generatedAt;

  const CaptureAiMetadata({
    required this.summary,
    required this.themes,
    required this.energyLevel,
    required this.moodAssessment,
    required this.tags,
    required this.notableSignals,
    required this.generatedAt,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'themes': themes,
    'energy_level': energyLevel,
    'mood_assessment': moodAssessment,
    'tags': tags,
    'notable_signals': notableSignals,
    'generated_at': generatedAt.toIso8601String(),
  };

  factory CaptureAiMetadata.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic raw) =>
        raw is List ? raw.cast<String>() : const [];

    return CaptureAiMetadata(
      summary: json['summary'] as String? ?? '',
      themes: list(json['themes']),
      energyLevel: json['energy_level'] as String? ?? 'unknown',
      moodAssessment: json['mood_assessment'] as String? ?? '',
      tags: list(json['tags']),
      notableSignals: list(json['notable_signals']),
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Encode to a JSON string for SQLite storage.
  String encode() => jsonEncode(toJson());

  /// Decode from a JSON string stored in SQLite.
  static CaptureAiMetadata? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return CaptureAiMetadata.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
