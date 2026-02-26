import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// Computed GPS metrics derived from position stream data.
class GpsMetrics {
  final double currentSpeedKmh;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final double totalDistanceKm;
  final double altitudeM;
  final double heading;
  final String cardinalDirection;
  final double accuracyM;
  final Duration trackingDuration;
  final int positionCount;

  GpsMetrics({
    required this.currentSpeedKmh,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.totalDistanceKm,
    required this.altitudeM,
    required this.heading,
    required this.cardinalDirection,
    required this.accuracyM,
    required this.trackingDuration,
    required this.positionCount,
  });

  static GpsMetrics empty() => GpsMetrics(
    currentSpeedKmh: 0,
    maxSpeedKmh: 0,
    averageSpeedKmh: 0,
    totalDistanceKm: 0,
    altitudeM: 0,
    heading: 0,
    cardinalDirection: '-',
    accuracyM: 0,
    trackingDuration: Duration.zero,
    positionCount: 0,
  );
}

/// Service that computes real-time GPS metrics from device position stream.
///
/// Tracks speed, distance, altitude, heading, and more via continuous
/// position updates from the Geolocator plugin.
class GpsMetricsService {
  StreamSubscription<Position>? _positionSubscription;
  final List<_TimedPosition> _positions = [];
  double _totalDistanceM = 0;
  double _maxSpeedKmh = 0;
  DateTime? _trackingStart;

  bool get isTracking => _positionSubscription != null;

  /// Start tracking GPS metrics. Returns a stream of updated metrics.
  Stream<GpsMetrics> startTracking() {
    final controller = StreamController<GpsMetrics>.broadcast();

    _trackingStart = DateTime.now();
    _positions.clear();
    _totalDistanceM = 0;
    _maxSpeedKmh = 0;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen(
          (position) {
            final timedPos = _TimedPosition(position, DateTime.now());

            // Calculate distance from previous position
            if (_positions.isNotEmpty) {
              final prev = _positions.last;
              final distM = Geolocator.distanceBetween(
                prev.position.latitude,
                prev.position.longitude,
                position.latitude,
                position.longitude,
              );
              // Only count plausible movements (filter GPS jitter)
              if (distM > 2 && distM < 10000) {
                _totalDistanceM += distM;
              }
            }

            _positions.add(timedPos);

            // Current speed from GPS (m/s → km/h)
            final currentSpeedKmh = max(0.0, position.speed * 3.6).toDouble();
            if (currentSpeedKmh > _maxSpeedKmh) {
              _maxSpeedKmh = currentSpeedKmh;
            }

            // Average speed
            final duration = DateTime.now().difference(_trackingStart!);
            final avgSpeedKmh = duration.inSeconds > 0
                ? (_totalDistanceM / 1000) / (duration.inSeconds / 3600)
                : 0.0;

            // Heading → cardinal direction
            final cardinal = _headingToCardinal(position.heading);

            controller.add(
              GpsMetrics(
                currentSpeedKmh: currentSpeedKmh,
                maxSpeedKmh: _maxSpeedKmh,
                averageSpeedKmh: avgSpeedKmh,
                totalDistanceKm: _totalDistanceM / 1000,
                altitudeM: position.altitude,
                heading: position.heading,
                cardinalDirection: cardinal,
                accuracyM: position.accuracy,
                trackingDuration: duration,
                positionCount: _positions.length,
              ),
            );
          },
          onError: (e) {
            print('GPS metrics stream error: $e');
          },
        );

    return controller.stream;
  }

  /// Get a single snapshot of GPS metrics from current position.
  Future<GpsMetrics> getSnapshot() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );

      final speedKmh = max(0.0, position.speed * 3.6).toDouble();

      return GpsMetrics(
        currentSpeedKmh: speedKmh,
        maxSpeedKmh: speedKmh,
        averageSpeedKmh: 0,
        totalDistanceKm: 0,
        altitudeM: position.altitude,
        heading: position.heading,
        cardinalDirection: _headingToCardinal(position.heading),
        accuracyM: position.accuracy,
        trackingDuration: Duration.zero,
        positionCount: 1,
      );
    } catch (e) {
      print('Error getting GPS snapshot: $e');
      return GpsMetrics.empty();
    }
  }

  /// Stop tracking and clean up.
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
  }

  static String _headingToCardinal(double heading) {
    if (heading < 0) return '-';
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }
}

class _TimedPosition {
  final Position position;
  final DateTime timestamp;
  _TimedPosition(this.position, this.timestamp);
}
