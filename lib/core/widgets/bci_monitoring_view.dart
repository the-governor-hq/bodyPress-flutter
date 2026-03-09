import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ble_source_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BCI Monitoring View — real-time signal quality dashboard (demo).
//
// Shows what a clinical / research BCI monitoring console looks like:
//   • Per-channel signal quality indicators (SNR, impedance estimate)
//   • Artifact detection ribbon (blinks, muscle, movement)
//   • Overall "data readiness" score
//   • Channel-level RMS amplitude meter
//
// DEMO visualisation — quality metrics are derived from signal statistics,
// not real impedance measurements.
// ─────────────────────────────────────────────────────────────────────────────

/// Artifact types detected (simulated).
enum _ArtifactType {
  clean('CLEAN', Icons.check_circle_outline_rounded, AppTheme.seaGreen),
  eyeBlink('BLINK', Icons.visibility_off_rounded, Color(0xFFFFBD5A)),
  muscle('MUSCLE', Icons.flash_on_rounded, Color(0xFFFF9800)),
  movement('MOVE', Icons.open_with_rounded, Color(0xFFFF5252));

  final String label;
  final IconData icon;
  final Color color;

  const _ArtifactType(this.label, this.icon, this.color);
}

/// Per-channel quality snapshot.
class _ChannelQuality {
  final String label;
  final double snrDb;
  final double rmsUv;
  final double impedanceKOhm; // simulated
  final _ArtifactType artifact;

  const _ChannelQuality({
    required this.label,
    required this.snrDb,
    required this.rmsUv,
    required this.impedanceKOhm,
    required this.artifact,
  });

  /// Simple quality score 0…1.
  double get quality {
    // Good SNR (>10 dB) + low impedance (<20 kΩ) + clean = high quality.
    final snrScore = (snrDb / 20.0).clamp(0.0, 1.0);
    final impScore = (1.0 - impedanceKOhm / 50.0).clamp(0.0, 1.0);
    final artScore = artifact == _ArtifactType.clean ? 1.0 : 0.3;
    return (snrScore * 0.4 + impScore * 0.3 + artScore * 0.3);
  }

  Color get qualityColor {
    final q = quality;
    if (q >= 0.7) return AppTheme.seaGreen;
    if (q >= 0.4) return AppTheme.amber;
    return AppTheme.crimson;
  }
}

/// Demo BCI monitoring console — signal quality & artifact dashboard.
class BciMonitoringView extends StatefulWidget {
  final Stream<SignalSample> signalStream;
  final List<ChannelDescriptor> channelDescriptors;
  final String? sourceName;

  const BciMonitoringView({
    super.key,
    required this.signalStream,
    required this.channelDescriptors,
    this.sourceName,
  });

  @override
  State<BciMonitoringView> createState() => _BciMonitoringViewState();
}

class _BciMonitoringViewState extends State<BciMonitoringView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  StreamSubscription<SignalSample>? _sub;

  // Per-channel running buffers for statistics.
  late final List<ListQueue<double>> _buffers;
  static const _bufferSize = 256;

  // Computed quality per channel.
  late List<_ChannelQuality> _qualities;

  // Artifact timeline.
  final _artifactTimeline = ListQueue<_ArtifactType>();
  static const _maxArtifactHistory = 60;

  int _sampleCount = 0;
  int _updateCounter = 0;
  double _overallReadiness = 0.0;

  // Simulated impedance (changes slowly).
  late final List<double> _impedances;

  @override
  void initState() {
    super.initState();
    final n = widget.channelDescriptors.length;

    _buffers = List.generate(
      n,
      (_) => ListQueue<double>.from(List<double>.filled(_bufferSize, 0)),
    );
    _qualities = List.generate(
      n,
      (i) => _ChannelQuality(
        label: widget.channelDescriptors[i].label,
        snrDb: 0,
        rmsUv: 0,
        impedanceKOhm: 10,
        artifact: _ArtifactType.clean,
      ),
    );
    _impedances = List.generate(n, (i) => 5.0 + i * 2.0);

    _sub = widget.signalStream.listen(_onSample);
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _onSample(SignalSample sample) {
    _sampleCount++;
    for (
      var ch = 0;
      ch < sample.channels.length && ch < _buffers.length;
      ch++
    ) {
      _buffers[ch].removeFirst();
      _buffers[ch].addLast(sample.channels[ch]);
    }

    _updateCounter++;
    if (_updateCounter >= 20) {
      _updateCounter = 0;
      _computeQuality();
    }
  }

  void _computeQuality() {
    final rng = math.Random(_sampleCount);
    final n = _buffers.length;

    for (var ch = 0; ch < n; ch++) {
      final data = _buffers[ch].toList();
      final len = data.length;

      // RMS.
      double sumSq = 0;
      for (final v in data) {
        sumSq += v * v;
      }
      final rms = math.sqrt(sumSq / len);

      // Pseudo-SNR: ratio of signal power to noise floor estimate.
      // Use difference of consecutive samples as noise proxy.
      double noiseSq = 0;
      for (var i = 1; i < len; i++) {
        final d = data[i] - data[i - 1];
        noiseSq += d * d;
      }
      final noiseRms = math.sqrt(noiseSq / (len - 1));
      final snr = noiseRms > 0
          ? 20 * math.log(rms / noiseRms) / math.ln10
          : 0.0;

      // Slowly drift impedance (simulated — would come from hardware).
      _impedances[ch] += (rng.nextDouble() - 0.5) * 1.5;
      _impedances[ch] = _impedances[ch].clamp(2.0, 40.0);

      // Artifact detection (simulated from signal amplitude).
      _ArtifactType artifact;
      final peak = data.fold<double>(0, (a, v) => math.max(a, v.abs()));
      if (peak > 80) {
        artifact = _ArtifactType.movement;
      } else if (peak > 50) {
        artifact = _ArtifactType.muscle;
      } else if (peak > 35 && ch < 2) {
        // Frontal channels (Fp1, Fp2) more prone to blinks.
        artifact = _ArtifactType.eyeBlink;
      } else {
        artifact = _ArtifactType.clean;
      }

      _qualities[ch] = _ChannelQuality(
        label: widget.channelDescriptors[ch].label,
        snrDb: snr.clamp(-10, 30),
        rmsUv: rms,
        impedanceKOhm: _impedances[ch],
        artifact: artifact,
      );
    }

    // Overall readiness.
    _overallReadiness = _qualities.fold<double>(0, (a, q) => a + q.quality) / n;

    // Artifact timeline (worst artifact across channels).
    _ArtifactType worst = _ArtifactType.clean;
    for (final q in _qualities) {
      if (q.artifact.index > worst.index) worst = q.artifact;
    }
    _artifactTimeline.addFirst(worst);
    while (_artifactTimeline.length > _maxArtifactHistory) {
      _artifactTimeline.removeLast();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060B0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _readinessColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildReadinessMeter(),
          Expanded(child: _buildChannelGrid()),
          _buildArtifactTimeline(),
          _buildFooter(),
        ],
      ),
    );
  }

  Color get _readinessColor {
    if (_overallReadiness >= 0.7) return AppTheme.seaGreen;
    if (_overallReadiness >= 0.4) return AppTheme.amber;
    return AppTheme.crimson;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.starlight.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.starlight.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.monitor_heart_rounded,
              size: 16,
              color: AppTheme.starlight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGNAL MONITORING',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.starlight.withValues(alpha: 0.9),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'DEMO — simulated quality metrics',
                  style: GoogleFonts.robotoMono(
                    fontSize: 8,
                    color: AppTheme.fog.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Readiness meter ───────────────────────────────────────────────────

  Widget _buildReadinessMeter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DATA READINESS',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.fog.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _readinessColor,
                      boxShadow: [
                        BoxShadow(
                          color: _readinessColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(_overallReadiness * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _readinessColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bar.
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 6,
                width: double.infinity,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _overallReadiness.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          _readinessColor.withValues(alpha: 0.3),
                          _readinessColor.withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _readinessColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Channel quality grid ──────────────────────────────────────────────

  Widget _buildChannelGrid() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      itemCount: _qualities.length,
      itemBuilder: (_, i) => _buildChannelRow(_qualities[i], i),
    );
  }

  Widget _buildChannelRow(_ChannelQuality q, int index) {
    const channelColors = [
      Color(0xFF00E676),
      Color(0xFF40C4FF),
      Color(0xFFFF5252),
      Color(0xFFFFD740),
      Color(0xFFE040FB),
      Color(0xFF00E5FF),
      Color(0xFFFF6E40),
      Color(0xFF69F0AE),
    ];
    final chColor = channelColors[index % channelColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: q.qualityColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: q.qualityColor.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Channel label + quality dot.
          SizedBox(
            width: 44,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: q.qualityColor,
                    boxShadow: [
                      BoxShadow(
                        color: q.qualityColor.withValues(alpha: 0.4),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  q.label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: chColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          // SNR.
          _MetricChip(
            label: 'SNR',
            value: '${q.snrDb.toStringAsFixed(0)} dB',
            color: q.snrDb > 10
                ? AppTheme.seaGreen
                : q.snrDb > 5
                ? AppTheme.amber
                : AppTheme.crimson,
          ),
          const SizedBox(width: 4),

          // RMS.
          _MetricChip(
            label: 'RMS',
            value: '${q.rmsUv.toStringAsFixed(0)} µV',
            color: chColor.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),

          // Impedance.
          _MetricChip(
            label: 'Z',
            value: '${q.impedanceKOhm.toStringAsFixed(0)} kΩ',
            color: q.impedanceKOhm < 15
                ? AppTheme.seaGreen
                : q.impedanceKOhm < 25
                ? AppTheme.amber
                : AppTheme.crimson,
          ),
          const SizedBox(width: 6),

          // Artifact indicator.
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: q.artifact.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(q.artifact.icon, size: 10, color: q.artifact.color),
                const SizedBox(width: 2),
                Text(
                  q.artifact.label,
                  style: GoogleFonts.robotoMono(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: q.artifact.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Artifact timeline ─────────────────────────────────────────────────

  Widget _buildArtifactTimeline() {
    return Container(
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(
          painter: _ArtifactTimelinePainter(
            artifacts: _artifactTimeline.toList(),
            maxEntries: _maxArtifactHistory,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.channelDescriptors.length} ch · $_sampleCount samples',
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _legendDot(AppTheme.seaGreen, 'Good'),
              const SizedBox(width: 6),
              _legendDot(AppTheme.amber, 'Fair'),
              const SizedBox(width: 6),
              _legendDot(AppTheme.crimson, 'Poor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 7,
            color: AppTheme.fog.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// ── Small metric chip ───────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 6,
              color: color.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Artifact timeline painter ───────────────────────────────────────────────

class _ArtifactTimelinePainter extends CustomPainter {
  final List<_ArtifactType> artifacts;
  final int maxEntries;

  const _ArtifactTimelinePainter({
    required this.artifacts,
    required this.maxEntries,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF080E16),
    );

    if (artifacts.isEmpty) return;

    final slotWidth = size.width / maxEntries;
    for (var i = 0; i < artifacts.length; i++) {
      final a = artifacts[i];
      final x = size.width - (i + 1) * slotWidth;
      final alpha = (1.0 - i / maxEntries).clamp(0.2, 1.0);

      canvas.drawRect(
        Rect.fromLTWH(x, 0, slotWidth + 0.5, size.height),
        Paint()..color = a.color.withValues(alpha: alpha * 0.4),
      );
    }

    // Label.
    final tp = TextPainter(
      text: TextSpan(
        text: 'ARTIFACTS',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 6,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.2),
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(4, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(_ArtifactTimelinePainter old) => true;
}
