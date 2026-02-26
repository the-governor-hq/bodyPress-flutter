/// Data model for a single body-blog entry.
///
/// Each entry represents one day's AI-generated narrative, written from
/// the perspective of the user's body based on real health, environment,
/// and calendar data.
class BodyBlogEntry {
  final DateTime date;
  final String headline;
  final String summary;
  final String fullBody;
  final String mood; // e.g. "calm", "energised", "tired", "restless"
  final String moodEmoji;
  final List<String> tags;
  final BodySnapshot snapshot;

  const BodyBlogEntry({
    required this.date,
    required this.headline,
    required this.summary,
    required this.fullBody,
    required this.mood,
    required this.moodEmoji,
    required this.tags,
    required this.snapshot,
  });
}

/// Raw data snapshot collected for a given day.
class BodySnapshot {
  final int steps;
  final double caloriesBurned;
  final double distanceKm;
  final double sleepHours;
  final int avgHeartRate;
  final int workouts;
  final double? temperatureC;
  final int? aqiUs;
  final double? uvIndex;
  final String? weatherDesc;
  final String? city;
  final List<String> calendarEvents;

  const BodySnapshot({
    this.steps = 0,
    this.caloriesBurned = 0,
    this.distanceKm = 0,
    this.sleepHours = 0,
    this.avgHeartRate = 0,
    this.workouts = 0,
    this.temperatureC,
    this.aqiUs,
    this.uvIndex,
    this.weatherDesc,
    this.city,
    this.calendarEvents = const [],
  });
}
