import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/body_blog_entry.dart';
import '../../../core/services/body_blog_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Body Blog — Medium-inspired, Zen home screen
// ─────────────────────────────────────────────────────────────────────────────

class BodyBlogScreen extends StatefulWidget {
  const BodyBlogScreen({super.key});

  @override
  State<BodyBlogScreen> createState() => _BodyBlogScreenState();
}

class _BodyBlogScreenState extends State<BodyBlogScreen> {
  final BodyBlogService _blogService = BodyBlogService();
  final PageController _pageCtrl = PageController();

  List<BodyBlogEntry> _entries = [];
  int _currentPage = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await _blogService.getRecentEntries(days: 7);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goPage(int page) {
    if (page < 0 || page >= _entries.length) return;
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: _loading
              ? const Center(child: _ZenLoader())
              : _entries.isEmpty
              ? _emptyState(dark)
              : Column(
                  children: [
                    _TopBar(
                      onDebug: () => context.push('/debug'),
                      onRefresh: _load,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageCtrl,
                        itemCount: _entries.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (ctx, i) => _BlogPage(
                          entry: _entries[i],
                          onReadMore: () => _openDetail(context, _entries[i]),
                        ),
                      ),
                    ),
                    _BottomNav(
                      current: _currentPage,
                      total: _entries.length,
                      onPrev: () => _goPage(_currentPage - 1),
                      onNext: () => _goPage(_currentPage + 1),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _emptyState(bool dark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Your body journal is preparing…\nPull down to refresh.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: dark ? Colors.white54 : Colors.black38,
            height: 1.8,
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, BodyBlogEntry entry) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _BlogDetailPage(entry: entry),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TOP BAR
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onDebug, required this.onRefresh});

  final VoidCallback onDebug;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
      child: Row(
        children: [
          Text(
            'BodyPress',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: Icon(
              Icons.refresh_rounded,
              color: dark ? Colors.white38 : Colors.black26,
              size: 22,
            ),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: onDebug,
            icon: Icon(
              Icons.settings_outlined,
              color: dark ? Colors.white38 : Colors.black26,
              size: 22,
            ),
            tooltip: 'Debug panel',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  BLOG PAGE (single entry card — scrollable)
// ═════════════════════════════════════════════════════════════════════════════

class _BlogPage extends StatelessWidget {
  const _BlogPage({required this.entry, required this.onReadMore});

  final BodyBlogEntry entry;
  final VoidCallback onReadMore;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dateLabel = _formatDate(entry.date);
    final primary = Theme.of(context).colorScheme.primary;

    return RefreshIndicator(
      onRefresh: () async {}, // handled at parent level
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── date & mood ──
            Row(
              children: [
                Text(
                  dateLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                    color: primary.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(entry.moodEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text(
                  entry.mood.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: dark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── headline ──
            Text(
              entry.headline,
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // ── horizontal rule ──
            Container(
              width: 48,
              height: 2,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
            ),

            const SizedBox(height: 20),

            // ── summary ──
            Text(
              entry.summary,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.8,
                fontWeight: FontWeight.w300,
                color: dark ? Colors.white70 : Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // ── tags ──
            if (entry.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.tags.map((t) => _Tag(label: t)).toList(),
              ),

            if (entry.tags.isNotEmpty) const SizedBox(height: 28),

            // ── snapshot glance ──
            _SnapshotGlance(snapshot: entry.snapshot),

            const SizedBox(height: 28),

            // ── read more CTA ──
            if (entry.fullBody.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: onReadMore,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: primary.withValues(alpha: 0.25)),
                    ),
                  ),
                  child: Text(
                    'Read full journal entry',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'TODAY  ·  ${DateFormat('MMMM d').format(d)}';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'YESTERDAY  ·  ${DateFormat('MMMM d').format(d)}';
    }
    return DateFormat('EEEE  ·  MMMM d').format(d).toUpperCase();
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SNAPSHOT GLANCE — small stat row
// ═════════════════════════════════════════════════════════════════════════════

class _SnapshotGlance extends StatelessWidget {
  const _SnapshotGlance({required this.snapshot});
  final BodySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = <_GlanceItem>[];

    if (snapshot.steps > 0) {
      items.add(_GlanceItem('🚶', '${snapshot.steps}', 'steps'));
    }
    if (snapshot.sleepHours > 0) {
      items.add(
        _GlanceItem('😴', snapshot.sleepHours.toStringAsFixed(1), 'h sleep'),
      );
    }
    if (snapshot.avgHeartRate > 0) {
      items.add(_GlanceItem('❤️', '${snapshot.avgHeartRate}', 'bpm'));
    }
    if (snapshot.caloriesBurned > 0) {
      items.add(
        _GlanceItem('🔥', snapshot.caloriesBurned.toStringAsFixed(0), 'kcal'),
      );
    }
    if (snapshot.temperatureC != null) {
      items.add(
        _GlanceItem(
          '🌡️',
          '${snapshot.temperatureC!.toStringAsFixed(0)}°',
          'C',
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((item) => _GlanceCell(item: item, dark: dark))
            .toList(),
      ),
    );
  }
}

class _GlanceItem {
  final String emoji;
  final String value;
  final String unit;
  const _GlanceItem(this.emoji, this.value, this.unit);
}

class _GlanceCell extends StatelessWidget {
  const _GlanceCell({required this.item, required this.dark});
  final _GlanceItem item;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          item.unit,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: dark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAG CHIP
// ═════════════════════════════════════════════════════════════════════════════

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: dark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  BOTTOM NAVIGATION — prev / page dots / next
// ═════════════════════════════════════════════════════════════════════════════

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  final int current;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // prev
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            enabled: current > 0,
            onTap: onPrev,
            label: 'Newer',
          ),

          // dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(total > 7 ? 7 : total, (i) {
              // Show max 7 dots; highlight the one matching current
              final dotIdx = total > 7
                  ? (current - 3).clamp(0, total - 7) + i
                  : i;
              final active = dotIdx == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? primary
                      : (dark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),

          // next
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            enabled: current < total - 1,
            onTap: onNext,
            label: 'Older',
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = enabled
        ? (dark ? Colors.white70 : Colors.black54)
        : (dark ? Colors.white12 : Colors.black12);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == Icons.chevron_left_rounded)
            Icon(icon, color: color, size: 22),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          if (icon == Icons.chevron_right_rounded)
            Icon(icon, color: color, size: 22),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ZEN LOADER
// ═════════════════════════════════════════════════════════════════════════════

class _ZenLoader extends StatefulWidget {
  const _ZenLoader();

  @override
  State<_ZenLoader> createState() => _ZenLoaderState();
}

class _ZenLoaderState extends State<_ZenLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.95 + _ctrl.value * 0.05,
              child: Opacity(
                opacity: 0.4 + _ctrl.value * 0.3,
                child: Icon(Icons.spa_outlined, size: 36, color: primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Listening to your body…',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: dark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FULL JOURNAL DETAIL PAGE
// ═════════════════════════════════════════════════════════════════════════════

class _BlogDetailPage extends StatelessWidget {
  const _BlogDetailPage({required this.entry});
  final BodyBlogEntry entry;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: dark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMMM d, y').format(entry.date),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: dark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // headline
                    Text(
                      entry.headline,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          entry.moodEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.mood,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 24),

                    // full body
                    Text(
                      entry.fullBody,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.85,
                        fontWeight: FontWeight.w300,
                        color: dark ? Colors.white70 : Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // tags
                    if (entry.tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags
                            .map((t) => _Tag(label: t))
                            .toList(),
                      ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
