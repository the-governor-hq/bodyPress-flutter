import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Data model for the ambient-scan API response.
class AmbientScanData {
  final AmbientMeta meta;
  final AmbientTemperature temperature;
  final AmbientAirQuality airQuality;
  final AmbientUvIndex uvIndex;
  final AmbientHumidity humidity;
  final AmbientWind wind;
  final AmbientAtmosphere atmosphere;
  final AmbientPrecipitation precipitation;
  final AmbientConditions conditions;
  final AmbientSun sun;

  AmbientScanData({
    required this.meta,
    required this.temperature,
    required this.airQuality,
    required this.uvIndex,
    required this.humidity,
    required this.wind,
    required this.atmosphere,
    required this.precipitation,
    required this.conditions,
    required this.sun,
  });

  factory AmbientScanData.fromJson(Map<String, dynamic> json) {
    return AmbientScanData(
      meta: AmbientMeta.fromJson(json['meta'] ?? {}),
      temperature: AmbientTemperature.fromJson(json['temperature'] ?? {}),
      airQuality: AmbientAirQuality.fromJson(json['air_quality'] ?? {}),
      uvIndex: AmbientUvIndex.fromJson(json['uv_index'] ?? {}),
      humidity: AmbientHumidity.fromJson(json['humidity'] ?? {}),
      wind: AmbientWind.fromJson(json['wind'] ?? {}),
      atmosphere: AmbientAtmosphere.fromJson(json['atmosphere'] ?? {}),
      precipitation: AmbientPrecipitation.fromJson(json['precipitation'] ?? {}),
      conditions: AmbientConditions.fromJson(json['conditions'] ?? {}),
      sun: AmbientSun.fromJson(json['sun'] ?? {}),
    );
  }
}

class AmbientMeta {
  final String city;
  final String region;
  final String country;
  final String countryCode;
  final double lat;
  final double lon;
  final String timezone;
  final double elevationM;
  final int responseTimeMs;

  AmbientMeta({
    required this.city,
    required this.region,
    required this.country,
    required this.countryCode,
    required this.lat,
    required this.lon,
    required this.timezone,
    required this.elevationM,
    required this.responseTimeMs,
  });

  factory AmbientMeta.fromJson(Map<String, dynamic> json) {
    final location = json['location'] ?? {};
    final coords = location['coordinates'] ?? {};
    return AmbientMeta(
      city: location['city'] ?? '',
      region: location['region'] ?? '',
      country: location['country'] ?? '',
      countryCode: location['countryCode'] ?? '',
      lat: (coords['lat'] ?? 0).toDouble(),
      lon: (coords['lon'] ?? 0).toDouble(),
      timezone: json['timezone'] ?? '',
      elevationM: (json['elevation_m'] ?? 0).toDouble(),
      responseTimeMs: json['_responseTime_ms'] ?? 0,
    );
  }
}

class AmbientTemperature {
  final double currentC;
  final double feelsLikeC;
  final double dailyHighC;
  final double dailyLowC;

  AmbientTemperature({
    required this.currentC,
    required this.feelsLikeC,
    required this.dailyHighC,
    required this.dailyLowC,
  });

  factory AmbientTemperature.fromJson(Map<String, dynamic> json) {
    return AmbientTemperature(
      currentC: (json['current_c'] ?? 0).toDouble(),
      feelsLikeC: (json['feels_like_c'] ?? 0).toDouble(),
      dailyHighC: (json['daily_high_c'] ?? 0).toDouble(),
      dailyLowC: (json['daily_low_c'] ?? 0).toDouble(),
    );
  }
}

class AmbientAirQuality {
  final int usAqi;
  final String level;
  final String concern;
  final double pm25;
  final double pm10;

  AmbientAirQuality({
    required this.usAqi,
    required this.level,
    required this.concern,
    required this.pm25,
    required this.pm10,
  });

  factory AmbientAirQuality.fromJson(Map<String, dynamic> json) {
    final pollutants = json['pollutants'] ?? {};
    final pm25Data = pollutants['pm2_5'] ?? {};
    final pm10Data = pollutants['pm10'] ?? {};
    return AmbientAirQuality(
      usAqi: json['us_aqi'] ?? 0,
      level: json['level'] ?? '',
      concern: json['concern'] ?? '',
      pm25: (pm25Data['value'] ?? 0).toDouble(),
      pm10: (pm10Data['value'] ?? 0).toDouble(),
    );
  }
}

class AmbientUvIndex {
  final double current;
  final double clearSky;
  final double dailyMax;
  final String level;
  final String concern;

  AmbientUvIndex({
    required this.current,
    required this.clearSky,
    required this.dailyMax,
    required this.level,
    required this.concern,
  });

  factory AmbientUvIndex.fromJson(Map<String, dynamic> json) {
    return AmbientUvIndex(
      current: (json['current'] ?? 0).toDouble(),
      clearSky: (json['clear_sky'] ?? 0).toDouble(),
      dailyMax: (json['daily_max'] ?? 0).toDouble(),
      level: json['level'] ?? '',
      concern: json['concern'] ?? '',
    );
  }
}

class AmbientHumidity {
  final int relativePercent;

  AmbientHumidity({required this.relativePercent});

  factory AmbientHumidity.fromJson(Map<String, dynamic> json) {
    return AmbientHumidity(relativePercent: json['relative_percent'] ?? 0);
  }
}

class AmbientWind {
  final double speedKmh;
  final double gustsKmh;
  final int directionDegrees;
  final String directionLabel;
  final String description;

  AmbientWind({
    required this.speedKmh,
    required this.gustsKmh,
    required this.directionDegrees,
    required this.directionLabel,
    required this.description,
  });

  factory AmbientWind.fromJson(Map<String, dynamic> json) {
    return AmbientWind(
      speedKmh: (json['speed_kmh'] ?? 0).toDouble(),
      gustsKmh: (json['gusts_kmh'] ?? 0).toDouble(),
      directionDegrees: json['direction_degrees'] ?? 0,
      directionLabel: json['direction_label'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class AmbientAtmosphere {
  final double pressureMslHpa;
  final double surfacePressureHpa;
  final int cloudCoverPercent;

  AmbientAtmosphere({
    required this.pressureMslHpa,
    required this.surfacePressureHpa,
    required this.cloudCoverPercent,
  });

  factory AmbientAtmosphere.fromJson(Map<String, dynamic> json) {
    return AmbientAtmosphere(
      pressureMslHpa: (json['pressure_msl_hpa'] ?? 0).toDouble(),
      surfacePressureHpa: (json['surface_pressure_hpa'] ?? 0).toDouble(),
      cloudCoverPercent: json['cloud_cover_percent'] ?? 0,
    );
  }
}

class AmbientPrecipitation {
  final double currentMm;
  final double rainMm;
  final double dailySumMm;
  final int dailyProbabilityPercent;

  AmbientPrecipitation({
    required this.currentMm,
    required this.rainMm,
    required this.dailySumMm,
    required this.dailyProbabilityPercent,
  });

  factory AmbientPrecipitation.fromJson(Map<String, dynamic> json) {
    return AmbientPrecipitation(
      currentMm: (json['current_mm'] ?? 0).toDouble(),
      rainMm: (json['rain_mm'] ?? 0).toDouble(),
      dailySumMm: (json['daily_sum_mm'] ?? 0).toDouble(),
      dailyProbabilityPercent: json['daily_probability_percent'] ?? 0,
    );
  }
}

class AmbientConditions {
  final int weatherCode;
  final String description;
  final bool isDay;

  AmbientConditions({
    required this.weatherCode,
    required this.description,
    required this.isDay,
  });

  factory AmbientConditions.fromJson(Map<String, dynamic> json) {
    return AmbientConditions(
      weatherCode: json['weather_code'] ?? 0,
      description: json['description'] ?? '',
      isDay: json['is_day'] ?? true,
    );
  }
}

class AmbientSun {
  final String sunrise;
  final String sunset;

  AmbientSun({required this.sunrise, required this.sunset});

  factory AmbientSun.fromJson(Map<String, dynamic> json) {
    return AmbientSun(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
    );
  }
}

/// Service that queries the ambient-scan API for environmental data.
///
/// The ambient-scan server must be running (locally or deployed).
/// Configure [baseUrl] to point to your instance.
class AmbientScanService {
  final String baseUrl;
  final http.Client _client;

  AmbientScanService({
    this.baseUrl = 'https://ambiant-scan.fly.dev',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Scan environmental data by GPS coordinates.
  Future<AmbientScanData?> scanByCoordinates(double lat, double lon) async {
    try {
      final uri = Uri.parse('$baseUrl/scan?lat=$lat&lon=$lon');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AmbientScanData.fromJson(json);
      } else {
        debugPrint('Ambient scan error: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching ambient scan data: $e');
      return null;
    }
  }

  /// Scan environmental data by city name.
  Future<AmbientScanData?> scanByCity(String city) async {
    try {
      final uri = Uri.parse('$baseUrl/scan?city=${Uri.encodeComponent(city)}');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AmbientScanData.fromJson(json);
      } else {
        debugPrint('Ambient scan error: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching ambient scan data: $e');
      return null;
    }
  }

  /// Auto-detect location via GeoIP and return environmental data.
  Future<AmbientScanData?> scanByGeoIp() async {
    try {
      // First get location from GeoIP
      final geoUri = Uri.parse('$baseUrl/geoip');
      final geoResponse = await _client
          .get(geoUri)
          .timeout(const Duration(seconds: 5));

      if (geoResponse.statusCode != 200) return null;

      final geoJson = jsonDecode(geoResponse.body) as Map<String, dynamic>;
      final lat = geoJson['lat'];
      final lon = geoJson['lon'];

      if (lat == null || lon == null) return null;

      return scanByCoordinates(
        (lat as num).toDouble(),
        (lon as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Error fetching ambient scan via GeoIP: $e');
      return null;
    }
  }

  /// Check if the ambient-scan server is reachable.
  Future<bool> isAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
