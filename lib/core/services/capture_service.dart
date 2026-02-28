import '../models/capture_entry.dart';
import 'ambient_scan_service.dart';
import 'calendar_service.dart';
import 'gps_metrics_service.dart';
import 'health_service.dart';
import 'local_db_service.dart';
import 'location_service.dart';

/// Service for creating and managing comprehensive data captures.
///
/// This service orchestrates data collection from multiple sources:
/// - Health data (steps, heart rate, calories, sleep, workouts)
/// - Environmental data (temperature, weather, AQI, UV)
/// - Location data (GPS, city, region, country)
/// - Calendar events
/// - User input (notes, mood)
///
/// All captures are stored in the local database with an `isProcessed` flag
/// that indicates whether the AI has analyzed this data.
class CaptureService {
  final HealthService _healthService;
  final AmbientScanService _ambientService;
  final LocationService _locationService;
  final GpsMetricsService _gpsMetricsService;
  final CalendarService _calendarService;
  final LocalDbService _dbService;

  CaptureService({
    HealthService? healthService,
    AmbientScanService? ambientService,
    LocationService? locationService,
    GpsMetricsService? gpsMetricsService,
    CalendarService? calendarService,
    LocalDbService? dbService,
  }) : _healthService = healthService ?? HealthService(),
       _ambientService = ambientService ?? AmbientScanService(),
       _locationService = locationService ?? LocationService(),
       _gpsMetricsService = gpsMetricsService ?? GpsMetricsService(),
       _calendarService = calendarService ?? CalendarService(),
       _dbService = dbService ?? LocalDbService();

  /// Create a comprehensive capture of the current state.
  ///
  /// Parameters:
  /// - [includeHealth]: Include health metrics (default: true)
  /// - [includeEnvironment]: Include environmental data (default: true)
  /// - [includeLocation]: Include location data (default: true)
  /// - [includeCalendar]: Include calendar events (default: true)
  /// - [userNote]: Optional user note or reflection
  /// - [userMood]: Optional user mood emoji
  /// - [tags]: Optional tags for categorization
  /// - [source]: Whether this is a manual or background capture
  /// - [trigger]: What triggered this capture
  Future<CaptureEntry> createCapture({
    bool includeHealth = true,
    bool includeEnvironment = true,
    bool includeLocation = true,
    bool includeCalendar = true,
    String? userNote,
    String? userMood,
    List<String> tags = const [],
    CaptureSource source = CaptureSource.manual,
    CaptureTrigger? trigger,
  }) async {
    final stopwatch = Stopwatch()..start();
    final timestamp = DateTime.now();
    final id = _generateId(timestamp);
    final errors = <String>[];

    // Collect data from various sources in parallel
    final futures = <Future<dynamic>>[];

    if (includeHealth) {
      futures.add(_collectHealthData());
    } else {
      futures.add(Future.value(null));
    }

    if (includeEnvironment) {
      futures.add(_collectEnvironmentData());
    } else {
      futures.add(Future.value(null));
    }

    if (includeLocation) {
      futures.add(_collectLocationData());
    } else {
      futures.add(Future.value(null));
    }

    if (includeCalendar) {
      futures.add(_collectCalendarEvents());
    } else {
      futures.add(Future.value(<String>[]));
    }

    final results = await Future.wait(futures);

    stopwatch.stop();

    final capture = CaptureEntry(
      id: id,
      timestamp: timestamp,
      isProcessed: false,
      userNote: userNote,
      userMood: userMood,
      tags: tags,
      healthData: results[0] as CaptureHealthData?,
      environmentData: results[1] as CaptureEnvironmentData?,
      locationData: results[2] as CaptureLocationData?,
      calendarEvents: results[3] as List<String>,
      source: source,
      trigger:
          trigger ??
          (source == CaptureSource.manual
              ? CaptureTrigger.manual
              : CaptureTrigger.time),
      executionDuration: stopwatch.elapsed,
      errors: errors,
    );

    // Save to database
    await _dbService.saveCapture(capture);

    return capture;
  }

  /// Collect health metrics for the current moment.
  Future<CaptureHealthData?> _collectHealthData() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Get today's steps
      final steps = await _healthService.getTodaySteps();

      // Get today's calories
      final calories = await _healthService.getTodayCalories();

      // Get today's distance
      final distance = await _healthService.getTodayDistance();

      // Get recent heart rate (last hour)
      final recentHeartRate = await _healthService.getHeartRateData(
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
      );
      int? heartRate;
      if (recentHeartRate.isNotEmpty) {
        final rates = recentHeartRate
            .map((dp) => (dp.value as dynamic).numericValue as num)
            .toList();
        heartRate = (rates.reduce((a, b) => a + b) / rates.length).round();
      }

      // Get last night's sleep
      final sleepHours = await _healthService.getLastNightSleep();

      // Get today's workouts
      final workouts = await _healthService.getTodayWorkoutCount();

      return CaptureHealthData(
        steps: steps > 0 ? steps : null,
        calories: calories > 0 ? calories : null,
        distance: distance > 0 ? distance : null,
        heartRate: heartRate,
        sleepHours: sleepHours > 0 ? sleepHours : null,
        workouts: workouts > 0 ? workouts : null,
      );
    } catch (e) {
      print('Error collecting health data: $e');
      return null;
    }
  }

  /// Collect environmental data for the current location.
  Future<CaptureEnvironmentData?> _collectEnvironmentData() async {
    try {
      // First get location for ambient scan
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        return null;
      }

      final ambientData = await _ambientService.scanByCoordinates(
        location.latitude,
        location.longitude,
      );

      if (ambientData == null) {
        return null;
      }

      return CaptureEnvironmentData(
        temperature: ambientData.temperature.currentC,
        aqi: ambientData.airQuality.usAqi,
        uvIndex: ambientData.uvIndex.current,
        weatherDescription: ambientData.conditions.description,
        humidity: ambientData.humidity.relativePercent,
        windSpeed: ambientData.wind.speedKmh,
        pressure: ambientData.atmosphere.pressureMslHpa,
        conditions: ambientData.conditions.description,
      );
    } catch (e) {
      print('Error collecting environment data: $e');
      return null;
    }
  }

  /// Collect location data for the current position.
  Future<CaptureLocationData?> _collectLocationData() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        return null;
      }

      // Get city/region/country from ambient scan metadata
      String? city;
      String? region;
      String? country;

      try {
        final ambientData = await _ambientService.scanByCoordinates(
          location.latitude,
          location.longitude,
        );
        if (ambientData != null) {
          city = ambientData.meta.city;
          region = ambientData.meta.region;
          country = ambientData.meta.country;
        }
      } catch (e) {
        print('Error getting location metadata: $e');
      }

      return CaptureLocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        altitude: location.altitude,
        accuracy: location.accuracy,
        city: city,
        region: region,
        country: country,
      );
    } catch (e) {
      print('Error collecting location data: $e');
      return null;
    }
  }

  /// Collect calendar events for today.
  Future<List<String>> _collectCalendarEvents() async {
    try {
      final events = await _calendarService.getTodayEvents();
      return events.map((e) => e.title ?? 'Untitled Event').toList();
    } catch (e) {
      print('Error collecting calendar events: $e');
      return [];
    }
  }

  /// Generate a unique ID for a capture based on timestamp.
  String _generateId(DateTime timestamp) {
    return 'capture_${timestamp.millisecondsSinceEpoch}';
  }

  /// Get all captures, optionally filtered by processed status.
  Future<List<CaptureEntry>> getCaptures({
    bool? isProcessed,
    int? limit,
  }) async {
    return _dbService.loadCaptures(isProcessed: isProcessed, limit: limit);
  }

  /// Get a specific capture by ID.
  Future<CaptureEntry?> getCapture(String id) async {
    return _dbService.loadCapture(id);
  }

  /// Mark a capture as processed by AI.
  Future<void> markAsProcessed(String id, {String? aiInsights}) async {
    final capture = await _dbService.loadCapture(id);
    if (capture == null) {
      throw Exception('Capture not found: $id');
    }

    final updated = capture.copyWith(
      isProcessed: true,
      processedAt: DateTime.now(),
      aiInsights: aiInsights,
    );

    await _dbService.saveCapture(updated);
  }

  /// Delete a capture.
  Future<void> deleteCapture(String id) async {
    await _dbService.deleteCapture(id);
  }

  /// Get count of unprocessed captures.
  Future<int> getUnprocessedCount() async {
    final unprocessed = await _dbService.loadCaptures(isProcessed: false);
    return unprocessed.length;
  }
}
