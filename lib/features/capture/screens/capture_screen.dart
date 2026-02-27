import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/capture_entry.dart';
import '../../../core/services/capture_service.dart';

/// Capture tab — comprehensive data capture for AI analysis.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final CaptureService _captureService = CaptureService();

  bool _includeHealth = true;
  bool _includeEnvironment = true;
  bool _includeLocation = true;
  bool _includeCalendar = true;

  bool _isCapturing = false;
  String? _userNote;
  String? _userMood;

  List<CaptureEntry>? _recentCaptures;
  int _unprocessedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecentCaptures();
  }

  Future<void> _loadRecentCaptures() async {
    try {
      final captures = await _captureService.getCaptures(limit: 10);
      final unprocessed = await _captureService.getUnprocessedCount();
      if (mounted) {
        setState(() {
          _recentCaptures = captures;
          _unprocessedCount = unprocessed;
        });
      }
    } catch (e) {
      print('Error loading recent captures: $e');
    }
  }

  Future<void> _createCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final capture = await _captureService.createCapture(
        includeHealth: _includeHealth,
        includeEnvironment: _includeEnvironment,
        includeLocation: _includeLocation,
        includeCalendar: _includeCalendar,
        userNote: _userNote,
        userMood: _userMood,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture created: ${capture.id}'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset user inputs
        _userNote = null;
        _userMood = null;

        // Reload recent captures
        await _loadRecentCaptures();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating capture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Capture',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.secondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stats card
                  if (_recentCaptures != null) ...[
                    _buildStatsCard(theme),
                    const SizedBox(height: 24),
                  ],

                  // Data selection card
                  _buildDataSelectionCard(theme),
                  const SizedBox(height: 16),

                  // User input card
                  _buildUserInputCard(theme),
                  const SizedBox(height: 24),

                  // Capture button
                  ElevatedButton(
                    onPressed: _isCapturing ? null : _createCapture,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCapturing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt_rounded),
                              const SizedBox(width: 8),
                              Text(
                                'Capture Now',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Recent captures
                  if (_recentCaptures != null &&
                      _recentCaptures!.isNotEmpty) ...[
                    Text(
                      'Recent Captures',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // Recent captures list
          if (_recentCaptures != null && _recentCaptures!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final capture = _recentCaptures![index];
                return _buildCaptureCard(theme, capture);
              }, childCount: _recentCaptures!.length),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              theme,
              'Total',
              _recentCaptures!.length.toString(),
              Icons.library_books_rounded,
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildStatItem(
              theme,
              'Unprocessed',
              _unprocessedCount.toString(),
              Icons.hourglass_empty_rounded,
              color: _unprocessedCount > 0 ? Colors.orange : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDataSelectionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Data to Capture',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildDataToggle(
              theme,
              'Health Metrics',
              'Steps, heart rate, calories, sleep, workouts',
              Icons.favorite_rounded,
              _includeHealth,
              (value) => setState(() => _includeHealth = value),
            ),
            _buildDataToggle(
              theme,
              'Environment',
              'Temperature, weather, air quality, UV',
              Icons.wb_sunny_rounded,
              _includeEnvironment,
              (value) => setState(() => _includeEnvironment = value),
            ),
            _buildDataToggle(
              theme,
              'Location',
              'GPS coordinates, city, region, country',
              Icons.location_on_rounded,
              _includeLocation,
              (value) => setState(() => _includeLocation = value),
            ),
            _buildDataToggle(
              theme,
              'Calendar',
              'Today\'s events and appointments',
              Icons.event_rounded,
              _includeCalendar,
              (value) => setState(() => _includeCalendar = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataToggle(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInputCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optional: Add Context',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Note or reflection',
                hintText: 'How are you feeling? What\'s on your mind?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.note_rounded),
              ),
              maxLines: 3,
              onChanged: (value) => _userNote = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Mood (emoji)',
                hintText: '😊 😔 😴 😤 😌',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.emoji_emotions_rounded),
              ),
              onChanged: (value) => _userMood = value.isEmpty ? null : value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard(ThemeData theme, CaptureEntry capture) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showCaptureDetails(capture),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: capture.isProcessed ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateFormat.format(capture.timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (capture.userMood != null)
                    Text(
                      capture.userMood!,
                      style: const TextStyle(fontSize: 20),
                    ),
                ],
              ),
              if (capture.userNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  capture.userNote!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (capture.healthData != null)
                    _buildDataChip(theme, Icons.favorite_rounded, 'Health'),
                  if (capture.environmentData != null)
                    _buildDataChip(
                      theme,
                      Icons.wb_sunny_rounded,
                      'Environment',
                    ),
                  if (capture.locationData != null)
                    _buildDataChip(
                      theme,
                      Icons.location_on_rounded,
                      'Location',
                    ),
                  if (capture.calendarEvents.isNotEmpty)
                    _buildDataChip(theme, Icons.event_rounded, 'Calendar'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCaptureDetails(CaptureEntry capture) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final dateFormat = DateFormat('MMMM d, y • h:mm:ss a');

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Capture Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailSection(
                  theme,
                  'Timestamp',
                  dateFormat.format(capture.timestamp),
                  Icons.access_time_rounded,
                ),
                _buildDetailSection(
                  theme,
                  'Status',
                  capture.isProcessed
                      ? 'Processed by AI'
                      : 'Awaiting processing',
                  capture.isProcessed
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_empty_rounded,
                  valueColor: capture.isProcessed
                      ? Colors.green
                      : Colors.orange,
                ),
                if (capture.userNote != null)
                  _buildDetailSection(
                    theme,
                    'Note',
                    capture.userNote!,
                    Icons.note_rounded,
                  ),
                if (capture.healthData != null) ...[
                  const Divider(),
                  _buildHealthData(theme, capture.healthData!),
                ],
                if (capture.environmentData != null) ...[
                  const Divider(),
                  _buildEnvironmentData(theme, capture.environmentData!),
                ],
                if (capture.locationData != null) ...[
                  const Divider(),
                  _buildLocationData(theme, capture.locationData!),
                ],
                if (capture.calendarEvents.isNotEmpty) ...[
                  const Divider(),
                  _buildCalendarData(theme, capture.calendarEvents),
                ],
                if (capture.aiInsights != null) ...[
                  const Divider(),
                  _buildDetailSection(
                    theme,
                    'AI Insights',
                    capture.aiInsights!,
                    Icons.psychology_rounded,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthData(ThemeData theme, CaptureHealthData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Health Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.steps != null) _buildMetric('Steps', '${data.steps}'),
        if (data.calories != null)
          _buildMetric('Calories', '${data.calories?.toStringAsFixed(0)} kcal'),
        if (data.distance != null)
          _buildMetric('Distance', '${data.distance?.toStringAsFixed(2)} km'),
        if (data.heartRate != null)
          _buildMetric('Heart Rate', '${data.heartRate} bpm'),
        if (data.sleepHours != null)
          _buildMetric('Sleep', '${data.sleepHours?.toStringAsFixed(1)} hours'),
        if (data.workouts != null) _buildMetric('Workouts', '${data.workouts}'),
      ],
    );
  }

  Widget _buildEnvironmentData(ThemeData theme, CaptureEnvironmentData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.wb_sunny_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Environment Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.temperature != null)
          _buildMetric(
            'Temperature',
            '${data.temperature?.toStringAsFixed(1)}°C',
          ),
        if (data.aqi != null) _buildMetric('Air Quality Index', '${data.aqi}'),
        if (data.uvIndex != null)
          _buildMetric('UV Index', '${data.uvIndex?.toStringAsFixed(1)}'),
        if (data.weatherDescription != null)
          _buildMetric('Weather', data.weatherDescription!),
        if (data.humidity != null)
          _buildMetric('Humidity', '${data.humidity}%'),
        if (data.windSpeed != null)
          _buildMetric(
            'Wind Speed',
            '${data.windSpeed?.toStringAsFixed(1)} km/h',
          ),
      ],
    );
  }

  Widget _buildLocationData(ThemeData theme, CaptureLocationData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Location Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMetric(
          'Coordinates',
          '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}',
        ),
        if (data.altitude != null)
          _buildMetric('Altitude', '${data.altitude?.toStringAsFixed(0)} m'),
        if (data.city != null) _buildMetric('City', data.city!),
        if (data.region != null) _buildMetric('Region', data.region!),
        if (data.country != null) _buildMetric('Country', data.country!),
      ],
    );
  }

  Widget _buildCalendarData(ThemeData theme, List<String> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Calendar Events',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...events.map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $event', style: GoogleFonts.inter(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: GoogleFonts.inter(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
