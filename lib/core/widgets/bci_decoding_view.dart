import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/ble_source_provider.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BCI Decoding View — simulated neural state classifier (demo).
//
// Visualises what a real-time BCI decoder would look like:
//   • Dominant brain state classification with confidence ring
//   • Per-state probability bars (Focus, Relax, Motor L/R, Meditation)
//   • Scrolling classification timeline ribbon
//   • All driven from the live signal stream (synthetic classification)
//
// This is a DEMO visualisation — the classifications are derived from
// signal statistics, not a real ML model.
// ─────────────────────────────────────────────────────────────────────────────

/// Simulated mental states for BCI decoding demo.
enum _BrainState {
  focus('FOCUS', Icons.center_focus_strong_rounded, Color(0xFF4DD4C8)),
  relax('RELAX', Icons.self_improvement_rounded, Color(0xFF8B78F5)),
  motorLeft('MOTOR L', Icons.pan_tool_rounded, Color(0xFF40C4FF)),
  motorRight('MOTOR R', Icons.back_hand_rounded, Color(0xFFFF5252)),
  meditation('MEDITATE', Icons.spa_rounded, Color(0xFF69F0AE));

  final String label;
  final IconData icon;
  final Color color;

  const _BrainState(this.label, this.icon, this.color);
}

/// Demo BCI decoding overlay — shows simulated neural state classification.
class BciDecodingView extends StatefulWidget {
  final Stream<SignalSample> signalStream;
  final List<ChannelDescriptor> channelDescriptors;
  final String? sourceName;

  const BciDecodingView({
    super.key,
    required this.signalStream,
    required this.channelDescriptors,
    this.sourceName,
  });

  @override
  State<BciDecodingView> createState() => _BciDecodingViewState();
}

class _BciDecodingViewState extends State<BciDecodingView>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  StreamSubscription<SignalSample>? _sub;

  // Running signal stats for pseudo-classification.
  final _recentValues = ListQueue<double>();
  static const _windowSize = 128;

  // Classification state.
  _BrainState _currentState = _BrainState.relax;
  final Map<_BrainState, double> _probabilities = {
    for (final s in _BrainState.values) s: 0.2,
  };
  double _confidence = 0.0;

  // Timeline history.
  final _timeline = ListQueue<_TimelineEntry>();
  static const _maxTimeline = 40;
  int _sampleCount = 0;
  int _classifyCounter = 0;

  @override
  void initState() {
    super.initState();
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
    // Accumulate RMS-like statistic from first channel.
    if (sample.channels.isNotEmpty) {
      _recentValues.addLast(sample.channels[0]);
      while (_recentValues.length > _windowSize) {
        _recentValues.removeFirst();
      }
    }

    // Re-classify every ~30 samples (~0.5 s at 60 Hz demo rate).
    _classifyCounter++;
    if (_classifyCounter >= 30 && _recentValues.length >= _windowSize ~/ 2) {
      _classifyCounter = 0;
      _classify();
    }
  }

  void _classify() {
    // Pseudo-classification from signal statistics.
    // NOT a real ML model — just plausible-looking demo output.
    final values = _recentValues.toList();
    final n = values.length;
    if (n < 2) return;

    double sum = 0, sumSq = 0;
    for (final v in values) {
      sum += v;
      sumSq += v * v;
    }
    final mean = sum / n;
    final variance = (sumSq / n) - (mean * mean);
    final rms = math.sqrt(variance.abs());

    // Derive pseudo-probabilities from signal characteristics.
    // High variance → focus/motor; low variance → relax/meditation.
    final rng = math.Random(_sampleCount);
    double jitter() => (rng.nextDouble() - 0.5) * 0.08;

    final normalizedRms = (rms / 30.0).clamp(0.0, 1.0);
    final energyBias = normalizedRms;

    _probabilities[_BrainState.focus] = (0.15 + energyBias * 0.35 + jitter())
        .clamp(0.02, 0.95);
    _probabilities[_BrainState.relax] = (0.30 - energyBias * 0.20 + jitter())
        .clamp(0.02, 0.95);
    _probabilities[_BrainState.motorLeft] =
        (0.10 + (mean > 0 ? 0.15 : 0.0) + jitter()).clamp(0.02, 0.95);
    _probabilities[_BrainState.motorRight] =
        (0.10 + (mean < 0 ? 0.15 : 0.0) + jitter()).clamp(0.02, 0.95);
    _probabilities[_BrainState.meditation] =
        (0.20 - energyBias * 0.15 + jitter()).clamp(0.02, 0.95);

    // Normalise to sum = 1.
    final total = _probabilities.values.fold<double>(0, (a, b) => a + b);
    for (final key in _probabilities.keys) {
      _probabilities[key] = _probabilities[key]! / total;
    }

    // Pick winner.
    _BrainState winner = _BrainState.relax;
    double best = 0;
    for (final entry in _probabilities.entries) {
      if (entry.value > best) {
        best = entry.value;
        winner = entry.key;
      }
    }
    _currentState = winner;
    _confidence = best;

    // Push to timeline.
    _timeline.addFirst(_TimelineEntry(state: winner, confidence: best));
    while (_timeline.length > _maxTimeline) {
      _timeline.removeLast();
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
          color: _currentState.color.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 4),
          Expanded(flex: 3, child: _buildClassificationRing()),
          Expanded(flex: 2, child: _buildProbabilityBars()),
          _buildTimeline(),
          _buildFooter(),
        ],
      ),
    );
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
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.psychology_rounded,
              size: 16,
              color: const Color(0xFFFF9800).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEURAL DECODING',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF9800).withValues(alpha: 0.9),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'DEMO — simulated classifier',
                  style: GoogleFonts.robotoMono(
                    fontSize: 8,
                    color: AppTheme.fog.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Confidence badge.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _currentState.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentState.color.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '${(_confidence * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.robotoMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _currentState.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Central classification ring ───────────────────────────────────────

  Widget _buildClassificationRing() {
    return Center(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final size =
              math.min(constraints.maxWidth, constraints.maxHeight) * 0.7;
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring.
                CustomPaint(
                  size: Size(size, size),
                  painter: _ConfidenceRingPainter(
                    confidence: _confidence,
                    color: _currentState.color,
                    probabilities: Map.fromEntries(
                      _BrainState.values.map(
                        (s) => MapEntry(s.color, _probabilities[s] ?? 0),
                      ),
                    ),
                  ),
                ),
                // Inner content.
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _currentState.icon,
                        key: ValueKey(_currentState),
                        size: size * 0.22,
                        color: _currentState.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _currentState.label,
                        key: ValueKey(_currentState.label),
                        style: GoogleFonts.robotoMono(
                          fontSize: size * 0.09,
                          fontWeight: FontWeight.w700,
                          color: _currentState.color,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(_confidence * 100).toStringAsFixed(1)}% confidence',
                      style: GoogleFonts.robotoMono(
                        fontSize: size * 0.055,
                        color: AppTheme.fog.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Probability bars ──────────────────────────────────────────────────

  Widget _buildProbabilityBars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _BrainState.values.map((state) {
          final prob = _probabilities[state] ?? 0;
          final isWinner = state == _currentState;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Row(
                      children: [
                        Icon(
                          state.icon,
                          size: 13,
                          color: isWinner
                              ? state.color
                              : state.color.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          state.label,
                          style: GoogleFonts.robotoMono(
                            fontSize: 8,
                            fontWeight: isWinner
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isWinner
                                ? state.color
                                : AppTheme.fog.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: state.color.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: prob.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: [
                                    state.color.withValues(alpha: 0.2),
                                    state.color.withValues(
                                      alpha: isWinner ? 0.5 : 0.3,
                                    ),
                                  ],
                                ),
                                boxShadow: isWinner
                                    ? [
                                        BoxShadow(
                                          color: state.color.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(prob * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: isWinner
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isWinner
                            ? state.color
                            : AppTheme.fog.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Classification timeline ribbon ────────────────────────────────────

  Widget _buildTimeline() {
    return Container(
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _TimelinePainter(
            entries: _timeline.toList(),
            maxEntries: _maxTimeline,
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
            'Classify every ~0.5 s · $_sampleCount samples',
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Text(
            '${_timeline.length} classifications',
            style: GoogleFonts.robotoMono(
              fontSize: 8,
              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confidence ring painter ─────────────────────────────────────────────────

class _ConfidenceRingPainter extends CustomPainter {
  final double confidence;
  final Color color;
  final Map<Color, double> probabilities;

  const _ConfidenceRingPainter({
    required this.confidence,
    required this.color,
    required this.probabilities,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Multi-segment arc showing probability distribution.
    double startAngle = -math.pi / 2;
    for (final entry in probabilities.entries) {
      final sweep = entry.value * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = entry.key.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }

    // Outer glow for the dominant state.
    canvas.drawCircle(
      center,
      radius + 2,
      Paint()
        ..color = color.withValues(alpha: confidence * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Confidence arc (bright overlay).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      confidence * 2 * math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ConfidenceRingPainter old) => true;
}

// ── Timeline painter ────────────────────────────────────────────────────────

class _TimelineEntry {
  final _BrainState state;
  final double confidence;

  const _TimelineEntry({required this.state, required this.confidence});
}

class _TimelinePainter extends CustomPainter {
  final List<_TimelineEntry> entries;
  final int maxEntries;

  const _TimelinePainter({required this.entries, required this.maxEntries});

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // Dark background.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF080E16),
    );

    final slotWidth = size.width / maxEntries;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final x = size.width - (i + 1) * slotWidth;
      final alpha = (1.0 - i / maxEntries).clamp(0.1, 1.0);

      canvas.drawRect(
        Rect.fromLTWH(x, 0, slotWidth + 0.5, size.height),
        Paint()
          ..color = e.state.color.withValues(alpha: e.confidence * alpha * 0.6),
      );
    }

    // "now" label.
    final tp = TextPainter(
      text: TextSpan(
        text: 'now →',
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 7,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 4, size.height - tp.height - 2),
    );
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => true;
}
