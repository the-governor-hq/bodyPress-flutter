import 'dart:convert';

import 'package:bodypress_flutter/core/services/ambient_scan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A minimal but complete ambient-scan API response.
Map<String, dynamic> _sampleApiResponse() => {
  'meta': {
    'location': {
      'city': 'Montreal',
      'region': 'Quebec',
      'country': 'Canada',
      'countryCode': 'CA',
      'coordinates': {'lat': 45.5, 'lon': -73.56},
    },
    'timezone': 'America/Montreal',
    'elevation_m': 30,
    '_responseTime_ms': 42,
  },
  'temperature': {
    'current_c': 18.2,
    'feels_like_c': 16.0,
    'daily_high_c': 22.0,
    'daily_low_c': 12.0,
  },
  'air_quality': {
    'us_aqi': 35,
    'level': 'Good',
    'concern': 'Minimal',
    'pollutants': {
      'pm2_5': {'value': 8.2},
      'pm10': {'value': 12.0},
    },
  },
  'uv_index': {
    'current': 3.5,
    'clear_sky': 5.0,
    'daily_max': 6.2,
    'level': 'Moderate',
    'concern': 'Low',
  },
  'humidity': {'relative_percent': 65},
  'wind': {
    'speed_kmh': 15.5,
    'gusts_kmh': 22.0,
    'direction_degrees': 180,
    'direction_label': 'S',
    'description': 'Moderate breeze',
  },
  'atmosphere': {
    'pressure_msl_hpa': 1013.5,
    'surface_pressure_hpa': 1013.0,
    'cloud_cover_percent': 40,
  },
  'precipitation': {
    'current_mm': 0.0,
    'rain_mm': 0.0,
    'daily_sum_mm': 1.2,
    'daily_probability_percent': 20,
  },
  'conditions': {
    'weather_code': 1,
    'description': 'Partly cloudy',
    'is_day': true,
  },
  'sun': {'sunrise': '06:30', 'sunset': '19:45'},
};

void main() {
  // ─── AmbientScanData.fromJson ─────────────────────────────────────────────

  group('AmbientScanData.fromJson', () {
    test('parses full response correctly', () {
      final data = AmbientScanData.fromJson(_sampleApiResponse());

      // Meta
      expect(data.meta.city, 'Montreal');
      expect(data.meta.region, 'Quebec');
      expect(data.meta.country, 'Canada');
      expect(data.meta.countryCode, 'CA');
      expect(data.meta.lat, 45.5);
      expect(data.meta.lon, -73.56);
      expect(data.meta.timezone, 'America/Montreal');
      expect(data.meta.elevationM, 30.0);
      expect(data.meta.responseTimeMs, 42);

      // Temperature
      expect(data.temperature.currentC, 18.2);
      expect(data.temperature.feelsLikeC, 16.0);
      expect(data.temperature.dailyHighC, 22.0);
      expect(data.temperature.dailyLowC, 12.0);

      // Air Quality
      expect(data.airQuality.usAqi, 35);
      expect(data.airQuality.level, 'Good');
      expect(data.airQuality.pm25, 8.2);
      expect(data.airQuality.pm10, 12.0);

      // UV Index
      expect(data.uvIndex.current, 3.5);
      expect(data.uvIndex.dailyMax, 6.2);
      expect(data.uvIndex.level, 'Moderate');

      // Humidity
      expect(data.humidity.relativePercent, 65);

      // Wind
      expect(data.wind.speedKmh, 15.5);
      expect(data.wind.gustsKmh, 22.0);
      expect(data.wind.directionDegrees, 180);
      expect(data.wind.directionLabel, 'S');

      // Atmosphere
      expect(data.atmosphere.pressureMslHpa, 1013.5);
      expect(data.atmosphere.cloudCoverPercent, 40);

      // Precipitation
      expect(data.precipitation.currentMm, 0.0);
      expect(data.precipitation.dailySumMm, 1.2);
      expect(data.precipitation.dailyProbabilityPercent, 20);

      // Conditions
      expect(data.conditions.weatherCode, 1);
      expect(data.conditions.description, 'Partly cloudy');
      expect(data.conditions.isDay, true);

      // Sun
      expect(data.sun.sunrise, '06:30');
      expect(data.sun.sunset, '19:45');
    });

    test('handles empty/missing sections gracefully', () {
      // fromJson uses ?? {} for every section, so an empty map should not throw.
      final data = AmbientScanData.fromJson({});
      expect(data.meta.city, '');
      expect(data.temperature.currentC, 0.0);
      expect(data.airQuality.usAqi, 0);
      expect(data.humidity.relativePercent, 0);
      expect(data.conditions.description, '');
      expect(data.sun.sunrise, '');
    });
  });

  // ─── AmbientScanService.scanByCoordinates ─────────────────────────────────

  group('AmbientScanService.scanByCoordinates', () {
    test('returns AmbientScanData on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['lat'], '45.5');
        expect(request.url.queryParameters['lon'], '-73.56');
        return http.Response(jsonEncode(_sampleApiResponse()), 200);
      });

      final service = AmbientScanService(client: client);
      final result = await service.scanByCoordinates(45.5, -73.56);
      expect(result, isNotNull);
      expect(result!.meta.city, 'Montreal');
    });

    test('returns null on HTTP error', () async {
      final client = MockClient((_) async => http.Response('err', 500));
      final service = AmbientScanService(client: client);
      final result = await service.scanByCoordinates(45.5, -73.56);
      expect(result, isNull);
    });

    test('returns null on network exception', () async {
      final client = MockClient((_) async {
        throw http.ClientException('timeout');
      });
      final service = AmbientScanService(client: client);
      final result = await service.scanByCoordinates(45.5, -73.56);
      expect(result, isNull);
    });
  });

  // ─── AmbientScanService.scanByCity ────────────────────────────────────────

  group('AmbientScanService.scanByCity', () {
    test('returns AmbientScanData on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['city'], 'Montreal');
        return http.Response(jsonEncode(_sampleApiResponse()), 200);
      });

      final service = AmbientScanService(client: client);
      final result = await service.scanByCity('Montreal');
      expect(result, isNotNull);
      expect(result!.temperature.currentC, 18.2);
    });

    test('returns null on error', () async {
      final client = MockClient((_) async => http.Response('', 404));
      final service = AmbientScanService(client: client);
      expect(await service.scanByCity('Nowhere'), isNull);
    });
  });

  // ─── AmbientScanService.scanByGeoIp ──────────────────────────────────────

  group('AmbientScanService.scanByGeoIp', () {
    test('chains geoip → scanByCoordinates on success', () async {
      int callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (request.url.path == '/geoip') {
          return http.Response(jsonEncode({'lat': 45.5, 'lon': -73.56}), 200);
        }
        // /scan call
        return http.Response(jsonEncode(_sampleApiResponse()), 200);
      });

      final service = AmbientScanService(client: client);
      final result = await service.scanByGeoIp();
      expect(result, isNotNull);
      expect(callCount, 2); // geoip + scan
    });

    test('returns null when geoip fails', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final service = AmbientScanService(client: client);
      expect(await service.scanByGeoIp(), isNull);
    });

    test('returns null when geoip returns no coordinates', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/geoip') {
          return http.Response(jsonEncode({}), 200);
        }
        return http.Response('', 500);
      });

      final service = AmbientScanService(client: client);
      expect(await service.scanByGeoIp(), isNull);
    });
  });

  // ─── AmbientScanService.isAvailable ───────────────────────────────────────

  group('AmbientScanService.isAvailable', () {
    test('returns true on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('OK', 200);
      });
      final service = AmbientScanService(client: client);
      expect(await service.isAvailable(), true);
    });

    test('returns false on non-200', () async {
      final client = MockClient((_) async => http.Response('', 503));
      final service = AmbientScanService(client: client);
      expect(await service.isAvailable(), false);
    });

    test('returns false on exception', () async {
      final client = MockClient((_) async {
        throw http.ClientException('No route');
      });
      final service = AmbientScanService(client: client);
      expect(await service.isAvailable(), false);
    });
  });
}
