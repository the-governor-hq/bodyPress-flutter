import 'dart:convert';

/// AI-generated metadata extracted from a [CaptureEntry].
///
/// The AI analyses every newly saved capture in the background and
/// derives structured insights that are then aggregated on the
/// Patterns screen to surface trends over time.
///
/// ## Correlation-Ready Design
///
/// Fields are designed for multi-day pattern correlation:
/// - **Temporal dimensions**: timeOfDay, dayType enable day-part analysis
/// - **Activity context**: activityCategory normalizes activity states
/// - **Location context**: locationContext identifies place types
/// - **Wellness scores**: sleepQuality, stressLevel enable numeric trends
/// - **Pattern hints**: patternHints are AI-discovered correlations
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

  // ── Correlation-Friendly Fields (v2) ─────────────────────────────────────

  /// Normalized time of day: "early-morning" | "morning" | "midday" |
  /// "afternoon" | "evening" | "night" | "late-night".
  final String? timeOfDay;

  /// Day type: "weekday" | "weekend".
  final String? dayType;

  /// Normalized activity category:
  /// "active" | "light-activity" | "sedentary" | "recovering" | "sleeping".
  final String? activityCategory;

  /// Normalized location context:
  /// "home" | "work" | "gym" | "outdoors" | "transit" | "social" | "other".
  final String? locationContext;

  /// Sleep quality score from recent sleep data (1-10 scale).
  final int? sleepQuality;

  /// Estimated stress level based on signals (1-10 scale).
  final int? stressLevel;

  /// Weather impact assessment: "positive" | "neutral" | "negative".
  final String? weatherImpact;

  /// Social context hint: "alone" | "with-others" | "unknown".
  final String? socialContext;

  /// AI-discovered pattern hints for multi-day correlation.
  /// Examples: "consistent-morning-routine", "weather-affects-mood",
  /// "post-workout-energy-boost", "weekday-stress-pattern".
  final List<String> patternHints;

  /// Primary body signal: the most significant health indicator at this moment.
  /// Examples: "well-rested", "fatigued", "energized", "recovering".
  final String? bodySignal;

  /// Environmental wellness score (1-10) based on AQI, UV, weather.
  final int? environmentScore;

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
    // v2 correlation fields (optional for backwards compat)
    this.timeOfDay,
    this.dayType,
    this.activityCategory,
    this.locationContext,
    this.sleepQuality,
    this.stressLevel,
    this.weatherImpact,
    this.socialContext,
    this.patternHints = const [],
    this.bodySignal,
    this.environmentScore,
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
    // v2 correlation fields
    if (timeOfDay != null) 'time_of_day': timeOfDay,
    if (dayType != null) 'day_type': dayType,
    if (activityCategory != null) 'activity_category': activityCategory,
    if (locationContext != null) 'location_context': locationContext,
    if (sleepQuality != null) 'sleep_quality': sleepQuality,
    if (stressLevel != null) 'stress_level': stressLevel,
    if (weatherImpact != null) 'weather_impact': weatherImpact,
    if (socialContext != null) 'social_context': socialContext,
    if (patternHints.isNotEmpty) 'pattern_hints': patternHints,
    if (bodySignal != null) 'body_signal': bodySignal,
    if (environmentScore != null) 'environment_score': environmentScore,
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
      // v2 correlation fields
      timeOfDay: json['time_of_day'] as String?,
      dayType: json['day_type'] as String?,
      activityCategory: json['activity_category'] as String?,
      locationContext: json['location_context'] as String?,
      sleepQuality: json['sleep_quality'] as int?,
      stressLevel: json['stress_level'] as int?,
      weatherImpact: json['weather_impact'] as String?,
      socialContext: json['social_context'] as String?,
      patternHints: list(json['pattern_hints']),
      bodySignal: json['body_signal'] as String?,
      environmentScore: json['environment_score'] as int?,
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
