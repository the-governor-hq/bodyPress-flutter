import 'dart:convert';

/// A single immutable snapshot of a [BodyBlogEntry]'s AI-generated content,
/// recorded every time the day's narrative is written or updated.
///
/// Each version is identified by [id] (auto-increment PK) and carries a
/// [generatedAt] timestamp so the history shelf can render an exact
/// "HH:mm" timeline for any given [date].
class BodyBlogVersion {
  final int id;
  final DateTime date;
  final DateTime generatedAt;

  /// Short label describing what triggered this version.
  /// One of the [BlogVersionTrigger] constants.
  final String trigger;

  final String headline;
  final String summary;
  final String fullBody;
  final String mood;
  final String moodEmoji;
  final List<String> tags;
  final bool aiGenerated;

  const BodyBlogVersion({
    required this.id,
    required this.date,
    required this.generatedAt,
    required this.trigger,
    required this.headline,
    required this.summary,
    required this.fullBody,
    required this.mood,
    required this.moodEmoji,
    required this.tags,
    required this.aiGenerated,
  });

  factory BodyBlogVersion.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'] as String?;
    return BodyBlogVersion(
      id: json['id'] as int,
      date: DateTime.parse('${json['date']}T00:00:00.000'),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      trigger: json['trigger'] as String,
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      fullBody: json['full_body'] as String,
      mood: json['mood'] as String,
      moodEmoji: json['mood_emoji'] as String,
      tags: tagsRaw != null
          ? (jsonDecode(tagsRaw) as List).cast<String>()
          : const [],
      aiGenerated: (json['ai_generated'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'generated_at': generatedAt.toIso8601String(),
    'trigger': trigger,
    'headline': headline,
    'summary': summary,
    'full_body': fullBody,
    'mood': mood,
    'mood_emoji': moodEmoji,
    'tags': jsonEncode(tags),
    'ai_generated': aiGenerated ? 1 : 0,
  };
}

/// Canonical trigger label constants used when appending a version to the DB.
class BlogVersionTrigger {
  const BlogVersionTrigger._();

  /// First local draft, before any AI call.
  static const draft = 'draft';

  /// Cold-start AI enrichment (first write of the day).
  static const aiEnriched = 'ai_enriched';

  /// User-requested full refresh (sensors + AI).
  static const refresh = 'refresh';

  /// Incremental update triggered by new unprocessed captures.
  static const incremental = 'incremental';

  /// Explicit "regenerate with AI" call.
  static const regen = 'regen';
}
