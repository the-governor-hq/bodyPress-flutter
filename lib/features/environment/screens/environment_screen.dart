import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/ambient_scan_service.dart';
import '../../../core/services/location_service.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final AmbientScanService _ambientService = AmbientScanService();
  final LocationService _locationService = LocationService();

  AmbientScanData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try GPS coordinates first
      final Position? position = await _locationService
          .getCurrentLocation()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);

      AmbientScanData? data;
      if (position != null) {
        data = await _ambientService.scanByCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      // Fallback to GeoIP
      data ??= await _ambientService.scanByGeoIp();

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          if (data == null) {
            _errorMessage =
                'Could not fetch environmental data.\nMake sure the ambient-scan server is running.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              displacement: 80,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLocationHeader(),
                    const SizedBox(height: 20),
                    _buildWeatherSection(),
                    const SizedBox(height: 16),
                    _buildAirQualitySection(),
                    const SizedBox(height: 16),
                    _buildUvSection(),
                    const SizedBox(height: 16),
                    _buildAtmosphereSection(),
                    const SizedBox(height: 16),
                    _buildWindSection(),
                    const SizedBox(height: 16),
                    _buildPrecipitationSection(),
                    const SizedBox(height: 16),
                    _buildSunSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    final meta = _data!.meta;
    final cond = _data!.conditions;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              cond.isDay ? Icons.wb_sunny : Icons.nightlight_round,
              size: 48,
              color: cond.isDay ? Colors.orange : Colors.indigo,
            ),
            const SizedBox(height: 12),
            Text(
              '${meta.city}${meta.region.isNotEmpty ? ', ${meta.region}' : ''}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (meta.country.isNotEmpty)
              Text(meta.country, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              cond.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Elevation: ${meta.elevationM.toStringAsFixed(0)}m',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSection() {
    final temp = _data!.temperature;
    final humidity = _data!.humidity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Temperature'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.thermostat,
                title: 'Current',
                value: '${temp.currentC.toStringAsFixed(1)}°',
                color: _tempColor(temp.currentC),
                unit: 'C',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.thermostat_outlined,
                title: 'Feels Like',
                value: '${temp.feelsLikeC.toStringAsFixed(1)}°',
                color: _tempColor(temp.feelsLikeC),
                unit: 'C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.arrow_upward,
                title: 'High',
                value: '${temp.dailyHighC.toStringAsFixed(1)}°',
                color: Colors.red[400]!,
                unit: 'C',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.arrow_downward,
                title: 'Low',
                value: '${temp.dailyLowC.toStringAsFixed(1)}°',
                color: Colors.blue[400]!,
                unit: 'C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricCard(
          icon: Icons.water_drop,
          title: 'Humidity',
          value: '${humidity.relativePercent}',
          color: Colors.cyan,
          unit: '%',
        ),
      ],
    );
  }

  Widget _buildAirQualitySection() {
    final aq = _data!.airQuality;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Air Quality'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _aqiColor(aq.usAqi).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.air, color: _aqiColor(aq.usAqi)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'US AQI: ${aq.usAqi}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          aq.level.toUpperCase(),
                          style: TextStyle(
                            color: _aqiColor(aq.usAqi),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(aq.concern, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _smallChip('PM2.5', '${aq.pm25.toStringAsFixed(1)} μg/m³'),
                    const SizedBox(width: 8),
                    _smallChip('PM10', '${aq.pm10.toStringAsFixed(1)} μg/m³'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUvSection() {
    final uv = _data!.uvIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('UV Index'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _uvColor(uv.current).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: _uvColor(uv.current),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uv.current.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          uv.level.toUpperCase(),
                          style: TextStyle(
                            color: _uvColor(uv.current),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(uv.concern, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _smallChip('Clear Sky', uv.clearSky.toStringAsFixed(1)),
                    const SizedBox(width: 8),
                    _smallChip('Daily Max', uv.dailyMax.toStringAsFixed(1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtmosphereSection() {
    final atm = _data!.atmosphere;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Atmosphere'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.compress,
                title: 'Pressure',
                value: atm.pressureMslHpa.toStringAsFixed(0),
                color: Colors.deepPurple,
                unit: 'hPa',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.cloud,
                title: 'Cloud Cover',
                value: '${atm.cloudCoverPercent}',
                color: Colors.blueGrey,
                unit: '%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWindSection() {
    final wind = _data!.wind;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Wind'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.air, color: Colors.teal),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${wind.speedKmh.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          wind.description,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _smallChip(
                      'Gusts',
                      '${wind.gustsKmh.toStringAsFixed(1)} km/h',
                    ),
                    const SizedBox(width: 8),
                    _smallChip(
                      'Direction',
                      '${wind.directionLabel} (${wind.directionDegrees}°)',
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

  Widget _buildPrecipitationSection() {
    final precip = _data!.precipitation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Precipitation'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.umbrella,
                title: 'Probability',
                value: '${precip.dailyProbabilityPercent}',
                color: Colors.blue,
                unit: '%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.water,
                title: 'Daily Total',
                value: precip.dailySumMm.toStringAsFixed(1),
                color: Colors.indigo,
                unit: 'mm',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSunSection() {
    final sun = _data!.sun;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sun'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.wb_twilight,
                title: 'Sunrise',
                value: _formatTime(sun.sunrise),
                color: Colors.amber,
                unit: '',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                icon: Icons.nights_stay,
                title: 'Sunset',
                value: _formatTime(sun.sunset),
                color: Colors.deepOrange,
                unit: '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _metricCard({
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
            if (unit.isNotEmpty)
              Text(
                unit,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Color _tempColor(double c) {
    if (c < 0) return Colors.blue[700]!;
    if (c < 10) return Colors.blue[400]!;
    if (c < 20) return Colors.green;
    if (c < 30) return Colors.orange;
    return Colors.red;
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }

  Color _uvColor(double uv) {
    if (uv < 3) return Colors.green;
    if (uv < 6) return Colors.yellow[700]!;
    if (uv < 8) return Colors.orange;
    if (uv < 11) return Colors.red;
    return Colors.purple;
  }

  String _formatTime(String iso) {
    try {
      // Handles "2026-02-18T07:02" format
      final parts = iso.split('T');
      if (parts.length == 2) return parts[1];
      return iso;
    } catch (_) {
      return iso;
    }
  }
}
