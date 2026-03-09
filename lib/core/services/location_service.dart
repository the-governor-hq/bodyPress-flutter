import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

/// Lightweight container for IP-based geolocation data.
class GeoIpLocation {
  final double latitude;
  final double longitude;
  final String? city;
  final String? region;
  final String? regionCode;
  final String? country;
  final String? countryCode;
  final String? zip;
  final String? timezone;
  final String? isp;

  const GeoIpLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.region,
    this.regionCode,
    this.country,
    this.countryCode,
    this.zip,
    this.timezone,
    this.isp,
  });

  factory GeoIpLocation.fromJson(Map<String, dynamic> json) {
    return GeoIpLocation(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      city: json['city'] as String?,
      region: json['region'] as String?,
      regionCode: json['regionCode'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      zip: json['zip'] as String?,
      timezone: json['timezone'] as String?,
      isp: json['isp'] as String?,
    );
  }

  /// Convert to a geolocator [Position] so callers that expect GPS Position
  /// work transparently.  Accuracy is set to a large value (~5 km) to signal
  /// that this is an IP-derived estimate, not a real GPS fix.
  Position toPosition() => Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: 5000.0, // ~5 km — typical GeoIP accuracy
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

class LocationService {
  static const _geoIpUrl = 'https://ambiant-scan.fly.dev/geoip';

  /// Most recent GeoIP result, cached so we don't re-fetch every call.
  GeoIpLocation? _cachedGeoIp;

  /// Public read-only access to the cached GeoIP data (city, region, etc.).
  GeoIpLocation? get cachedGeoIp => _cachedGeoIp;

  /// Whether the user has granted location permission (without requesting).
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // Get current location — tries GPS first, falls back to GeoIP
  // ONLY when location permission is not granted.
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await _checkPermission();

    if (hasPermission) {
      // Permission granted — use GPS only, never GeoIP.
      try {
        final gpsPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).timeout(const Duration(seconds: 8));
        return gpsPosition;
      } catch (e) {
        debugPrint(
          'GPS location unavailable ($e) — no GeoIP fallback '
          'because permission is granted',
        );
        return null;
      }
    }

    // Permission NOT granted — fall back to GeoIP.
    try {
      final geoIp = await getGeoIpLocation();
      if (geoIp != null) {
        debugPrint(
          'Using GeoIP fallback (no location permission): '
          '${geoIp.city}, ${geoIp.region} '
          '(${geoIp.latitude}, ${geoIp.longitude})',
        );
        return geoIp.toPosition();
      }
    } catch (e) {
      debugPrint('GeoIP fallback also failed: $e');
    }

    return null;
  }

  /// Fetch location from IP address via the ambient-scan GeoIP endpoint.
  /// Returns cached result if already fetched during this session.
  Future<GeoIpLocation?> getGeoIpLocation() async {
    if (_cachedGeoIp != null) return _cachedGeoIp;

    try {
      final response = await http
          .get(Uri.parse(_geoIpUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['lat'] != null && json['lon'] != null) {
          _cachedGeoIp = GeoIpLocation.fromJson(json);
          return _cachedGeoIp;
        }
      }
    } catch (e) {
      debugPrint('GeoIP request failed: $e');
    }
    return null;
  }

  /// Whether the last position came from GeoIP (accuracy >= 5000 m).
  bool isGeoIpPosition(Position position) => position.accuracy >= 5000.0;

  // Stream location updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission
  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Calculate distance between two positions
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
