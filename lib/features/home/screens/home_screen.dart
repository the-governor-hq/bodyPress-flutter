import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/ambient_scan_service.dart';
import '../../../core/services/gps_metrics_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/service_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final _healthService = ref.read(healthServiceProvider);
  late final _locationService = ref.read(locationServiceProvider);
  late final _calendarService = ref.read(calendarServiceProvider);
  late final _ambientService = ref.read(ambientScanServiceProvider);
  late final _gpsMetricsService = ref.read(gpsMetricsServiceProvider);
  late final _dbService = ref.read(localDbServiceProvider);
  late final _contextWindowService = ref.read(contextWindowServiceProvider);

  int _todaySteps = 0;
  double _todayCalories = 0;
  double _todayDistance = 0;
  double _lastNightSleep = 0;
  int _averageHeartRate = 0;
  int _workoutCount = 0;
  Position? _currentLocation;
  List<Event> _todayEvents = [];
  AmbientScanData? _ambientData;
  GpsMetrics? _gpsMetrics;
  bool _isLoading = true;
  bool _isInitialLoad = true;

  // DB + context state
  DbInfo? _dbInfo;
  List<Map<String, Object?>> _dbRows = [];
  String _contextWindowText = '';
  bool _dbSectionExpanded = true;
  bool _contextSectionExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Only show full-screen spinner on first load, not on pull-to-refresh
    if (_isInitialLoad) {
      setState(() => _isLoading = true);
    }

    try {
      // Load health data with timeout
      int steps = 0;
      double calories = 0;
      double distance = 0;
      double sleep = 0;
      int heartRate = 0;
      int workouts = 0;
      try {
        steps = await _healthService.getTodaySteps().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health steps request timed out');
            return 0;
          },
        );
        calories = await _healthService.getTodayCalories().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health calories request timed out');
            return 0;
          },
        );
        distance = await _healthService.getTodayDistance().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health distance request timed out');
            return 0;
          },
        );
        sleep = await _healthService.getLastNightSleep().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health sleep request timed out');
            return 0;
          },
        );
        heartRate = await _healthService.getTodayAverageHeartRate().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health heart rate request timed out');
            return 0;
          },
        );
        workouts = await _healthService.getTodayWorkoutCount().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Health workouts request timed out');
            return 0;
          },
        );
      } catch (e) {
        debugPrint('Error loading health data: $e');
      }

      // Load location with timeout
      Position? location;
      try {
        location = await _locationService.getCurrentLocation().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Location request timed out');
            return null;
          },
        );
      } catch (e) {
        debugPrint('Error loading location: $e');
      }

      // Load calendar events with timeout
      List<Event> events = [];
      try {
        final hasCalendarPermission = await _calendarService
            .hasPermissions()
            .timeout(const Duration(seconds: 3), onTimeout: () => false);
        if (hasCalendarPermission) {
          events = await _calendarService.getTodayEvents().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Calendar events request timed out');
              return <Event>[];
            },
          );
        }
      } catch (e) {
        debugPrint('Error loading calendar events: $e');
      }

      // Load ambient environmental data
      AmbientScanData? ambientData;
      try {
        if (location != null) {
          ambientData = await _ambientService
              .scanByCoordinates(location.latitude, location.longitude)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('Ambient scan request timed out');
                  return null;
                },
              );
        }
      } catch (e) {
        debugPrint('Error loading ambient data: $e');
      }

      // Load GPS metrics snapshot
      GpsMetrics? gpsMetrics;
      try {
        gpsMetrics = await _gpsMetricsService.getSnapshot().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('GPS metrics request timed out');
            return GpsMetrics.empty();
          },
        );
      } catch (e) {
        debugPrint('Error loading GPS metrics: $e');
      }

      // Load DB info + context window
      DbInfo? dbInfo;
      List<Map<String, Object?>> dbRows = [];
      String contextWindowText = '';
      try {
        dbInfo = await _dbService.getDbInfo();
        dbRows = await _dbService.getDebugRows();
        final cwResult = await _contextWindowService.build(days: 7);
        contextWindowText = cwResult.text;
      } catch (e) {
        debugPrint('Error loading DB / context window: $e');
      }

      if (mounted) {
        setState(() {
          _todaySteps = steps;
          _todayCalories = calories;
          _todayDistance = distance;
          _lastNightSleep = sleep;
          _averageHeartRate = heartRate;
          _workoutCount = workouts;
          _currentLocation = location;
          _todayEvents = events;
          _ambientData = ambientData;
          _gpsMetrics = gpsMetrics;
          _dbInfo = dbInfo;
          _dbRows = dbRows;
          _contextWindowText = contextWindowText;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/journal'),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: (_isLoading && _isInitialLoad)
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              displacement: 80,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(),
                    const SizedBox(height: 24),
                    _buildHealthSection(),
                    const SizedBox(height: 16),
                    _buildAdditionalMetricsSection(),
                    const SizedBox(height: 24),
                    _buildGpsMetricsSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildEnvironmentSummarySection(),
                    const SizedBox(height: 24),
                    _buildCalendarSection(),
                    const SizedBox(height: 24),
                    _buildDatabaseSection(),
                    const SizedBox(height: 24),
                    _buildContextWindowSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGreetingSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w300),
        ),
        Text(
          "Let's track your progress",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Activity',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.directions_walk,
                title: 'Steps',
                value: _todaySteps.toString(),
                color: Colors.blue,
                unit: 'steps',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.local_fire_department,
                title: 'Calories',
                value: _todayCalories.toStringAsFixed(0),
                color: Colors.orange,
                unit: 'kcal',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.straighten,
                title: 'Distance',
                value: (_todayDistance / 1000).toStringAsFixed(2),
                color: Colors.green,
                unit: 'km',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bedtime,
                title: 'Sleep',
                value: _lastNightSleep.toStringAsFixed(1),
                color: Colors.purple,
                unit: 'hours',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.favorite,
                title: 'Heart Rate',
                value: _averageHeartRate > 0
                    ? _averageHeartRate.toString()
                    : '-',
                color: Colors.red,
                unit: 'bpm',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.fitness_center,
                title: 'Workouts',
                value: _workoutCount.toString(),
                color: Colors.teal,
                unit: 'sessions',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentLocation != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accuracy: ${_currentLocation!.accuracy.toStringAsFixed(1)}m',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              )
            else
              Text(
                'Location not available',
                style: TextStyle(color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsMetricsSection() {
    if (_gpsMetrics == null) return const SizedBox.shrink();
    final gps = _gpsMetrics!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GPS Metrics',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.speed,
                title: 'Speed',
                value: gps.currentSpeedKmh.toStringAsFixed(1),
                color: Colors.indigo,
                unit: 'km/h',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.terrain,
                title: 'Altitude',
                value: gps.altitudeM.toStringAsFixed(0),
                color: Colors.brown,
                unit: 'm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.explore,
                title: 'Heading',
                value: gps.cardinalDirection,
                color: Colors.deepPurple,
                unit: '${gps.heading.toStringAsFixed(0)}°',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.gps_fixed,
                title: 'Accuracy',
                value: gps.accuracyM.toStringAsFixed(0),
                color: Colors.cyan,
                unit: 'm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvironmentSummarySection() {
    if (_ambientData == null) return const SizedBox.shrink();
    final data = _ambientData!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Environment',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.push('/environment'),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Details'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.meta.city.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          data.conditions.isDay
                              ? Icons.wb_sunny
                              : Icons.nightlight_round,
                          color: data.conditions.isDay
                              ? Colors.orange
                              : Colors.indigo,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${data.conditions.description} · ${data.meta.city}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _envChip(
                        Icons.thermostat,
                        '${data.temperature.currentC.toStringAsFixed(0)}°C',
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _envChip(
                        Icons.air,
                        'AQI ${data.airQuality.usAqi}',
                        _aqiChipColor(data.airQuality.usAqi),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _envChip(
                        Icons.wb_sunny_outlined,
                        'UV ${data.uvIndex.current.toStringAsFixed(1)}',
                        Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _envChip(
                        Icons.water_drop,
                        '${data.humidity.relativePercent}%',
                        Colors.cyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _envChip(
                        Icons.air,
                        '${data.wind.speedKmh.toStringAsFixed(0)} km/h',
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _envChip(
                        Icons.compress,
                        '${data.atmosphere.pressureMslHpa.toStringAsFixed(0)} hPa',
                        Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _envChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _aqiChipColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Schedule',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_todayEvents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No events scheduled for today',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayEvents.length,
            itemBuilder: (context, index) {
              final event = _todayEvents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    event.title ?? 'Untitled Event',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: event.start != null
                      ? Text(
                          '${event.start!.hour.toString().padLeft(2, '0')}:${event.start!.minute.toString().padLeft(2, '0')}',
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }

  // ── Database inspector ──────────────────────────────────────────────────

  Widget _buildDatabaseSection() {
    final info = _dbInfo;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _dbSectionExpanded = !_dbSectionExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Icon(Icons.storage_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Database Inspector',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Icon(
                _dbSectionExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        if (_dbSectionExpanded) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata rows
                  _dbKv(
                    'Schema version',
                    info != null ? '${info.schemaVersion}' : '—',
                  ),
                  _dbKv(
                    'Entries stored',
                    info != null ? '${info.entryCount}' : '—',
                  ),
                  _dbKv('Oldest entry', info?.oldestDate ?? '—'),
                  _dbKv('Newest entry', info?.newestDate ?? '—'),
                  _dbKv('Path', info?.path ?? '—', mono: true, small: true),
                  if (_dbRows.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text(
                      'Stored entries (newest first)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_dbRows.map((row) {
                      final date = row['date'] as String? ?? '?';
                      final mood = row['mood'] as String? ?? '';
                      final emoji = row['mood_emoji'] as String? ?? '';
                      final note = row['user_note'] as String?;
                      final userMood = row['user_mood'] as String?;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '$emoji $mood',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (userMood != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                userMood,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (note != null && note.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '✏️ "$note"',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    })),
                  ],
                  if (_dbRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No entries yet — open the journal to generate today\'s entry.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dbKv(
    String key,
    String value, {
    bool mono = false,
    bool small = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              key,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 11 : 13,
                fontFamily: mono ? 'monospace' : null,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 7-day context window ─────────────────────────────────────────────────

  Widget _buildContextWindowSection() {
    final primary = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(
            () => _contextSectionExpanded = !_contextSectionExpanded,
          ),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '7-Day Context Window',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (_contextWindowText.isNotEmpty)
                IconButton(
                  tooltip: 'Copy to clipboard',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _contextWindowText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Context window copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              Icon(
                _contextSectionExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        if (_contextSectionExpanded) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 420),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  _contextWindowText.isEmpty
                      ? 'No data yet — entries appear after the first journal load.'
                      : _contextWindowText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    height: 1.65,
                    color: dark ? Colors.green[300] : Colors.blueGrey[800],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required String unit,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(unit, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
