import 'package:bodypress_flutter/core/services/gps_metrics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GpsMetrics', () {
    test('empty() returns all-zero metrics', () {
      final m = GpsMetrics.empty();
      expect(m.currentSpeedKmh, 0);
      expect(m.maxSpeedKmh, 0);
      expect(m.averageSpeedKmh, 0);
      expect(m.totalDistanceKm, 0);
      expect(m.altitudeM, 0);
      expect(m.heading, 0);
      expect(m.cardinalDirection, '-');
      expect(m.accuracyM, 0);
      expect(m.trackingDuration, Duration.zero);
      expect(m.positionCount, 0);
    });

    test('constructor stores all provided values', () {
      final m = GpsMetrics(
        currentSpeedKmh: 5.5,
        maxSpeedKmh: 12.0,
        averageSpeedKmh: 7.2,
        totalDistanceKm: 3.4,
        altitudeM: 50.0,
        heading: 180.0,
        cardinalDirection: 'S',
        accuracyM: 4.5,
        trackingDuration: const Duration(minutes: 30),
        positionCount: 120,
      );
      expect(m.currentSpeedKmh, 5.5);
      expect(m.maxSpeedKmh, 12.0);
      expect(m.averageSpeedKmh, 7.2);
      expect(m.totalDistanceKm, 3.4);
      expect(m.altitudeM, 50.0);
      expect(m.heading, 180.0);
      expect(m.cardinalDirection, 'S');
      expect(m.accuracyM, 4.5);
      expect(m.trackingDuration, const Duration(minutes: 30));
      expect(m.positionCount, 120);
    });
  });
}
