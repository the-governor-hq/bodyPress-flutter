import 'dart:convert';

/// A comprehensive capture of the user's state at a moment in time.
///
/// This includes health metrics, environmental data, location, calendar,
/// user input, and timestamps. Captured data is stored for AI analysis.
class CaptureEntry {
  /// Unique identifier for this capture (timestamp-based).
  final String id;

  /// When this capture was created.
  final DateTime timestamp;

  /// Whether this entry has been processed by AI.
  final bool isProcessed;

  /// Optional user note or reflection.
  final String? userNote;

  /// Optional user-reported mood emoji.
  final String? userMood;

  /// Optional tags for categorization.
  final List<String> tags;

  /// Health metrics at the time of capture.
  final CaptureHealthData? healthData;

  /// Environmental conditions at the time of capture.
  final CaptureEnvironmentData? environmentData;

  /// Location data at the time of capture.
  final CaptureLocationData? locationData;

  /// Calendar events for context.
  final List<String> calendarEvents;

  /// When this entry was processed by AI (if applicable).
  final DateTime? processedAt;

  /// AI-generated insights (if processed).
  final String? aiInsights;

  const CaptureEntry({
    required this.id,
    required this.timestamp,
    this.isProcessed = false,
    this.userNote,
    this.userMood,
    this.tags = const [],
    this.healthData,
    this.environmentData,
    this.locationData,
    this.calendarEvents = const [],
    this.processedAt,
    this.aiInsights,
  });

  CaptureEntry copyWith({
    String? id,
    DateTime? timestamp,
    bool? isProcessed,
    String? userNote,
    bool clearUserNote = false,
    String? userMood,
    bool clearUserMood = false,
    List<String>? tags,
    CaptureHealthData? healthData,
    bool clearHealthData = false,
    CaptureEnvironmentData? environmentData,
    bool clearEnvironmentData = false,
    CaptureLocationData? locationData,
    bool clearLocationData = false,
    List<String>? calendarEvents,
    DateTime? processedAt,
    bool clearProcessedAt = false,
    String? aiInsights,
    bool clearAiInsights = false,
  }) {
    return CaptureEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      isProcessed: isProcessed ?? this.isProcessed,
      userNote: clearUserNote ? null : (userNote ?? this.userNote),
      userMood: clearUserMood ? null : (userMood ?? this.userMood),
      tags: tags ?? this.tags,
      healthData: clearHealthData ? null : (healthData ?? this.healthData),
      environmentData: clearEnvironmentData
          ? null
          : (environmentData ?? this.environmentData),
      locationData: clearLocationData
          ? null
          : (locationData ?? this.locationData),
      calendarEvents: calendarEvents ?? this.calendarEvents,
      processedAt: clearProcessedAt ? null : (processedAt ?? this.processedAt),
      aiInsights: clearAiInsights ? null : (aiInsights ?? this.aiInsights),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'is_processed': isProcessed ? 1 : 0,
    'user_note': userNote,
    'user_mood': userMood,
    'tags': jsonEncode(tags),
    'health_data': healthData != null ? jsonEncode(healthData!.toJson()) : null,
    'environment_data': environmentData != null
        ? jsonEncode(environmentData!.toJson())
        : null,
    'location_data': locationData != null
        ? jsonEncode(locationData!.toJson())
        : null,
    'calendar_events': jsonEncode(calendarEvents),
    'processed_at': processedAt?.toIso8601String(),
    'ai_insights': aiInsights,
  };

  factory CaptureEntry.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'] as String?;
    final healthDataRaw = json['health_data'] as String?;
    final environmentDataRaw = json['environment_data'] as String?;
    final locationDataRaw = json['location_data'] as String?;
    final calendarEventsRaw = json['calendar_events'] as String?;

    return CaptureEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isProcessed: (json['is_processed'] as int?) == 1,
      userNote: json['user_note'] as String?,
      userMood: json['user_mood'] as String?,
      tags: tagsRaw != null
          ? (jsonDecode(tagsRaw) as List).cast<String>()
          : const [],
      healthData: healthDataRaw != null
          ? CaptureHealthData.fromJson(
              jsonDecode(healthDataRaw) as Map<String, dynamic>,
            )
          : null,
      environmentData: environmentDataRaw != null
          ? CaptureEnvironmentData.fromJson(
              jsonDecode(environmentDataRaw) as Map<String, dynamic>,
            )
          : null,
      locationData: locationDataRaw != null
          ? CaptureLocationData.fromJson(
              jsonDecode(locationDataRaw) as Map<String, dynamic>,
            )
          : null,
      calendarEvents: calendarEventsRaw != null
          ? (jsonDecode(calendarEventsRaw) as List).cast<String>()
          : const [],
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      aiInsights: json['ai_insights'] as String?,
    );
  }
}

/// Health metrics captured at a moment in time.
class CaptureHealthData {
  final int? steps;
  final double? calories;
  final double? distance;
  final int? heartRate;
  final double? sleepHours;
  final int? workouts;

  const CaptureHealthData({
    this.steps,
    this.calories,
    this.distance,
    this.heartRate,
    this.sleepHours,
    this.workouts,
  });

  Map<String, dynamic> toJson() => {
    'steps': steps,
    'calories': calories,
    'distance': distance,
    'heart_rate': heartRate,
    'sleep_hours': sleepHours,
    'workouts': workouts,
  };

  factory CaptureHealthData.fromJson(Map<String, dynamic> json) {
    return CaptureHealthData(
      steps: json['steps'] as int?,
      calories: (json['calories'] as num?)?.toDouble(),
      distance: (json['distance'] as num?)?.toDouble(),
      heartRate: json['heart_rate'] as int?,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      workouts: json['workouts'] as int?,
    );
  }
}

/// Environmental conditions captured at a moment in time.
class CaptureEnvironmentData {
  final double? temperature;
  final int? aqi;
  final double? uvIndex;
  final String? weatherDescription;
  final int? humidity;
  final double? windSpeed;
  final double? pressure;
  final String? conditions;

  const CaptureEnvironmentData({
    this.temperature,
    this.aqi,
    this.uvIndex,
    this.weatherDescription,
    this.humidity,
    this.windSpeed,
    this.pressure,
    this.conditions,
  });

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'aqi': aqi,
    'uv_index': uvIndex,
    'weather_description': weatherDescription,
    'humidity': humidity,
    'wind_speed': windSpeed,
    'pressure': pressure,
    'conditions': conditions,
  };

  factory CaptureEnvironmentData.fromJson(Map<String, dynamic> json) {
    return CaptureEnvironmentData(
      temperature: (json['temperature'] as num?)?.toDouble(),
      aqi: json['aqi'] as int?,
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
      weatherDescription: json['weather_description'] as String?,
      humidity: json['humidity'] as int?,
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      pressure: (json['pressure'] as num?)?.toDouble(),
      conditions: json['conditions'] as String?,
    );
  }
}

/// Location data captured at a moment in time.
class CaptureLocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final String? city;
  final String? region;
  final String? country;

  const CaptureLocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.city,
    this.region,
    this.country,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'city': city,
    'region': region,
    'country': country,
  };

  factory CaptureLocationData.fromJson(Map<String, dynamic> json) {
    return CaptureLocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      city: json['city'] as String?,
      region: json['region'] as String?,
      country: json['country'] as String?,
    );
  }
}
