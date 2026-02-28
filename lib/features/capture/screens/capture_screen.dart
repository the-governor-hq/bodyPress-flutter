import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/capture_entry.dart';
import '../../../core/services/capture_service.dart';

/// Capture tab — comprehensive data capture for AI analysis.
/// Zen, minimalist design inspired by BodyBlog.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final CaptureService _captureService = CaptureService();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();

  bool _includeHealth = true;
  bool _includeEnvironment = true;
  bool _includeLocation = true;
  bool _includeCalendar = true;

  bool _isCapturing = false;
  String? _userNote;
  String? _userMood;

  List<CaptureEntry>? _recentCaptures;
  int _unprocessedCount = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadRecentCaptures();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _moodController.dispose();
    _animController.dispose();
    super.dispose();
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
            content: Text('Capture created successfully'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Reset user inputs
        _noteController.clear();
        _moodController.clear();
        _userNote = null;
        _userMood = null;

        // Reload recent captures
        await _loadRecentCaptures();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    final dark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _loadRecentCaptures,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Zen top bar
                  SliverToBoxAdapter(child: _buildTopBar(dark)),

                  // Main content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Stats section
                          if (_recentCaptures != null)
                            _buildStatsSection(theme, dark),

                          const SizedBox(height: 32),

                          // Data selection section
                          _buildDataSelectionSection(theme, dark),

                          const SizedBox(height: 32),

                          // Context input section
                          _buildContextSection(theme, dark),

                          const SizedBox(height: 40),

                          // Capture button
                          _buildCaptureButton(theme, dark),

                          const SizedBox(height: 48),

                          // Recent captures header
                          if (_recentCaptures != null &&
                              _recentCaptures!.isNotEmpty)
                            _buildRecentHeader(theme, dark),
                        ],
                      ),
                    ),
                  ),

                  // Recent captures list
                  if (_recentCaptures != null && _recentCaptures!.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final capture = _recentCaptures![index];
                        return _buildCaptureCard(theme, dark, capture);
                      }, childCount: _recentCaptures!.length),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TOP BAR — zen, minimal, like BodyBlog
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        children: [
          Text(
            'Capture',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loadRecentCaptures,
            icon: Icon(
              Icons.refresh_rounded,
              color: dark ? Colors.white38 : Colors.black26,
              size: 22,
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STATS SECTION — elegant, minimalist
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatsSection(ThemeData theme, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            dark,
            '${_recentCaptures!.length}',
            'Total Captures',
            Icons.camera_alt_outlined,
          ),
          Container(
            width: 1,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (dark ? Colors.white : Colors.black).withValues(alpha: 0),
                  (dark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                  (dark ? Colors.white : Colors.black).withValues(alpha: 0),
                ],
              ),
            ),
          ),
          _buildStatItem(
            theme,
            dark,
            '$_unprocessedCount',
            'Unprocessed',
            Icons.hourglass_empty_rounded,
            highlight: _unprocessedCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool dark,
    String value,
    String label,
    IconData icon, {
    bool highlight = false,
  }) {
    final color = highlight ? Colors.amber.shade600 : theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 28),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: dark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: dark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DATA SELECTION — elegant checkboxes
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDataSelectionSection(ThemeData theme, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATA SOURCES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 2,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 24),
        _buildDataOption(
          theme,
          dark,
          'Health & Fitness',
          'Steps, heart rate, calories, sleep, workouts',
          Icons.favorite_outline,
          _includeHealth,
          (v) => setState(() => _includeHealth = v),
        ),
        const SizedBox(height: 20),
        _buildDataOption(
          theme,
          dark,
          'Environment',
          'Temperature, weather, air quality, UV index',
          Icons.wb_sunny_outlined,
          _includeEnvironment,
          (v) => setState(() => _includeEnvironment = v),
        ),
        const SizedBox(height: 20),
        _buildDataOption(
          theme,
          dark,
          'Location',
          'GPS coordinates, altitude, city, region',
          Icons.location_on_outlined,
          _includeLocation,
          (v) => setState(() => _includeLocation = v),
        ),
        const SizedBox(height: 20),
        _buildDataOption(
          theme,
          dark,
          'Calendar',
          'Today\'s events and appointments',
          Icons.event_outlined,
          _includeCalendar,
          (v) => setState(() => _includeCalendar = v),
        ),
      ],
    );
  }

  Widget _buildDataOption(
    ThemeData theme,
    bool dark,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : (dark
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? theme.colorScheme.primary.withValues(alpha: 0.3)
                : (dark ? Colors.white : Colors.black).withValues(alpha: 0.06),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: value
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : (dark ? Colors.white : Colors.black).withValues(
                        alpha: 0.04,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: value
                    ? theme.colorScheme.primary
                    : (dark ? Colors.white38 : Colors.black38),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: value
                          ? (dark ? Colors.white : Colors.black87)
                          : (dark ? Colors.white60 : Colors.black54),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: dark ? Colors.white38 : Colors.black38,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: value
                      ? theme.colorScheme.primary
                      : (dark ? Colors.white38 : Colors.black26),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CONTEXT SECTION — note and mood input
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildContextSection(ThemeData theme, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADD CONTEXT',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 2,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'How are you feeling? What\'s on your mind?',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: dark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: dark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
          onChanged: (value) => _userNote = value.isEmpty ? null : value,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _moodController,
          decoration: InputDecoration(
            hintText: 'Mood (emoji): 😊 😔 😴 😤 😌',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: dark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: dark ? Colors.white.withValues(alpha: 0.87) : Colors.black87,
            fontWeight: FontWeight.w400,
          ),
          onChanged: (value) => _userMood = value.isEmpty ? null : value,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CAPTURE BUTTON — elegant, zen
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCaptureButton(ThemeData theme, bool dark) {
    return Center(
      child: TextButton(
        onPressed: _isCapturing ? null : _createCapture,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          backgroundColor: _isCapturing
              ? (dark ? Colors.white12 : Colors.black12)
              : theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isCapturing
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    dark ? Colors.white38 : Colors.black38,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Capture Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // RECENT CAPTURES HEADER
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildRecentHeader(ThemeData theme, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT CAPTURES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 2,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CAPTURE CARD — zen list item
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildCaptureCard(ThemeData theme, bool dark, CaptureEntry capture) {
    final dateFormat = DateFormat('MMM d · h:mm a');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCaptureDetails(capture),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (dark ? Colors.white : Colors.black).withValues(
                  alpha: 0.06,
                ),
              ),
            ),
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
                        color: capture.isProcessed
                            ? Colors.green.shade400
                            : Colors.amber.shade600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateFormat.format(capture.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: dark ? Colors.white60 : Colors.black54,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (capture.userMood != null)
                      Text(
                        capture.userMood!,
                        style: const TextStyle(fontSize: 22),
                      ),
                  ],
                ),
                if (capture.userNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    capture.userNote!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: dark ? Colors.white70 : Colors.black87,
                      height: 1.6,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (capture.healthData != null)
                      _buildDataBadge(theme, dark, Icons.favorite, 'Health'),
                    if (capture.environmentData != null)
                      _buildDataBadge(
                        theme,
                        dark,
                        Icons.wb_sunny,
                        'Environment',
                      ),
                    if (capture.locationData != null)
                      _buildDataBadge(
                        theme,
                        dark,
                        Icons.location_on,
                        'Location',
                      ),
                    if (capture.calendarEvents.isNotEmpty)
                      _buildDataBadge(theme, dark, Icons.event, 'Calendar'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataBadge(
    ThemeData theme,
    bool dark,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DETAIL MODAL — zen bottom sheet
  // ─────────────────────────────────────────────────────────────────────

  void _showCaptureDetails(CaptureEntry capture) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          final dateFormat = DateFormat('EEEE, MMMM d · h:mm a');

          return Container(
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: (dark ? Colors.white : Colors.black).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Capture Details',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: dark ? Colors.white38 : Colors.black26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        theme,
                        dark,
                        'Timestamp',
                        dateFormat.format(capture.timestamp),
                        Icons.access_time_rounded,
                      ),
                      _buildDetailSection(
                        theme,
                        dark,
                        'Status',
                        capture.isProcessed
                            ? 'Processed by AI'
                            : 'Awaiting processing',
                        capture.isProcessed
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_empty_rounded,
                        valueColor: capture.isProcessed
                            ? Colors.green.shade400
                            : Colors.amber.shade600,
                      ),
                      if (capture.userMood != null)
                        _buildDetailSection(
                          theme,
                          dark,
                          'Mood',
                          capture.userMood!,
                          Icons.emoji_emotions_rounded,
                        ),
                      if (capture.userNote != null)
                        _buildDetailSection(
                          theme,
                          dark,
                          'Note',
                          capture.userNote!,
                          Icons.note_rounded,
                        ),
                      if (capture.healthData != null) ...[
                        const SizedBox(height: 24),
                        _buildHealthData(theme, dark, capture.healthData!),
                      ],
                      if (capture.environmentData != null) ...[
                        const SizedBox(height: 24),
                        _buildEnvironmentData(
                          theme,
                          dark,
                          capture.environmentData!,
                        ),
                      ],
                      if (capture.locationData != null) ...[
                        const SizedBox(height: 24),
                        _buildLocationData(theme, dark, capture.locationData!),
                      ],
                      if (capture.calendarEvents.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildCalendarData(theme, dark, capture.calendarEvents),
                      ],
                      if (capture.aiInsights != null) ...[
                        const SizedBox(height: 24),
                        _buildDetailSection(
                          theme,
                          dark,
                          'AI Insights',
                          capture.aiInsights!,
                          Icons.psychology_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(
    ThemeData theme,
    bool dark,
    String title,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: dark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color:
                  valueColor ??
                  (dark
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87),
              height: 1.6,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthData(ThemeData theme, bool dark, CaptureHealthData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'HEALTH DATA',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: dark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (data.steps != null)
                _buildMetric(dark, 'Steps', '${data.steps}'),
              if (data.calories != null)
                _buildMetric(
                  dark,
                  'Calories',
                  '${data.calories?.toStringAsFixed(0)} kcal',
                ),
              if (data.distance != null)
                _buildMetric(
                  dark,
                  'Distance',
                  '${data.distance?.toStringAsFixed(2)} km',
                ),
              if (data.heartRate != null)
                _buildMetric(dark, 'Heart Rate', '${data.heartRate} bpm'),
              if (data.sleepHours != null)
                _buildMetric(
                  dark,
                  'Sleep',
                  '${data.sleepHours?.toStringAsFixed(1)} hours',
                ),
              if (data.workouts != null)
                _buildMetric(dark, 'Workouts', '${data.workouts}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentData(
    ThemeData theme,
    bool dark,
    CaptureEnvironmentData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.wb_sunny,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'ENVIRONMENT DATA',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: dark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (data.temperature != null)
                _buildMetric(
                  dark,
                  'Temperature',
                  '${data.temperature?.toStringAsFixed(1)}°C',
                ),
              if (data.aqi != null)
                _buildMetric(dark, 'Air Quality Index', '${data.aqi}'),
              if (data.uvIndex != null)
                _buildMetric(
                  dark,
                  'UV Index',
                  '${data.uvIndex?.toStringAsFixed(1)}',
                ),
              if (data.weatherDescription != null)
                _buildMetric(dark, 'Weather', data.weatherDescription!),
              if (data.humidity != null)
                _buildMetric(dark, 'Humidity', '${data.humidity}%'),
              if (data.windSpeed != null)
                _buildMetric(
                  dark,
                  'Wind Speed',
                  '${data.windSpeed?.toStringAsFixed(1)} km/h',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationData(
    ThemeData theme,
    bool dark,
    CaptureLocationData data,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'LOCATION DATA',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: dark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildMetric(
                dark,
                'Coordinates',
                '${data.latitude.toStringAsFixed(4)}, ${data.longitude.toStringAsFixed(4)}',
              ),
              if (data.altitude != null)
                _buildMetric(
                  dark,
                  'Altitude',
                  '${data.altitude?.toStringAsFixed(0)} m',
                ),
              if (data.city != null) _buildMetric(dark, 'City', data.city!),
              if (data.region != null)
                _buildMetric(dark, 'Region', data.region!),
              if (data.country != null)
                _buildMetric(dark, 'Country', data.country!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarData(ThemeData theme, bool dark, List<String> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event,
              size: 18,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              'CALENDAR EVENTS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: dark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: events.map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•  ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: dark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        event,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: dark
                              ? Colors.white.withValues(alpha: 0.87)
                              : Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(bool dark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: dark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dark
                    ? Colors.white.withValues(alpha: 0.87)
                    : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
