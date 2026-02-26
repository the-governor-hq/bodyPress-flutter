import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/health_service.dart';
import '../../../core/services/permission_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding — Zen-inspired, step-by-step permission flow
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // 5 pages: welcome · location · health · calendar · complete
  static const _totalPages = 5;
  static const _permSteps = 3;

  final _pageCtrl = PageController();
  final _permissionService = PermissionService();
  final _healthService = HealthService();

  int _page = 0;
  bool _busy = false;

  late final AnimationController _breathe;

  // ── lifecycle ──────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _breathe.dispose();
    super.dispose();
  }

  // ── navigation ────────────────────────────────────────────────

  void _next() {
    if (_page < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _finish() => context.go('/');

  // ── permission helpers ────────────────────────────────────────

  Future<void> _requestLocation() async {
    setState(() => _busy = true);
    try {
      await _permissionService.requestLocationPermission().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
    _next();
  }

  Future<void> _requestHealth() async {
    setState(() => _busy = true);
    try {
      await _permissionService.requestActivityRecognitionPermission().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      await _permissionService.requestSensorsPermission().timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      await _healthService.requestAuthorization().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
    _next();
  }

  Future<void> _requestCalendar() async {
    setState(() => _busy = true);
    try {
      await _permissionService.requestCalendarPermission().timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (_) {}
    if (mounted) setState(() => _busy = false);
    _next();
  }

  // ── build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── progress bar (only on perm steps) ──
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: (_page >= 1 && _page <= _permSteps)
                    ? _StepBar(
                        key: const ValueKey('bar'),
                        step: _page,
                        total: _permSteps,
                        accent: Theme.of(context).colorScheme.primary,
                        onSkip: _busy ? null : _next,
                      )
                    : const SizedBox.shrink(key: ValueKey('nobar')),
              ),

              // ── pages ──
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _WelcomePage(onBegin: _next, breathe: _breathe),
                    _PermissionStep(
                      icon: Icons.explore_outlined,
                      accent: const Color(0xFF6B8E6B),
                      title: 'Environmental\nAwareness',
                      subtitle: 'LOCATION ACCESS',
                      body:
                          'BodyPress uses your GPS coordinates to fetch local '
                          'environmental data — weather conditions, air quality, '
                          'UV index, and altitude.\n\n'
                          'This helps you understand how your surroundings '
                          'influence your body and overall wellness.',
                      privacy:
                          'Your location is never tracked, stored, or shared. '
                          'We only read it in the moment to pull environmental data.',
                      ctaLabel: 'Allow Location',
                      onAllow: _requestLocation,
                      onSkip: _next,
                      busy: _busy,
                      breathe: _breathe,
                    ),
                    _PermissionStep(
                      icon: Icons.monitor_heart_outlined,
                      accent: const Color(0xFFD4738A),
                      title: 'Body\nIntelligence',
                      subtitle: 'HEALTH DATA ACCESS',
                      body:
                          'Access to Apple Health or Google Health Connect lets '
                          'BodyPress read your steps, heart rate, sleep patterns, '
                          'calories burned, and workouts.\n\n'
                          'This paints a holistic picture of your daily vitality '
                          'so you can make informed choices.',
                      privacy:
                          'Health data stays on your device. '
                          'We only read — never write or upload.',
                      ctaLabel: 'Allow Health Data',
                      onAllow: _requestHealth,
                      onSkip: _next,
                      busy: _busy,
                      breathe: _breathe,
                    ),
                    _PermissionStep(
                      icon: Icons.event_outlined,
                      accent: const Color(0xFF7B8EC4),
                      title: 'Mindful\nScheduling',
                      subtitle: 'CALENDAR ACCESS',
                      body:
                          'Calendar integration helps you plan wellness '
                          'routines, set mindful reminders, and maintain a '
                          'consistent rhythm in your health journey.\n\n'
                          'See how your daily agenda aligns with your '
                          'body\'s needs.',
                      privacy:
                          'We only read your calendar for context — '
                          'nothing is modified, copied, or shared.',
                      ctaLabel: 'Allow Calendar',
                      onAllow: _requestCalendar,
                      onSkip: _next,
                      busy: _busy,
                      breathe: _breathe,
                    ),
                    _CompletePage(onEnter: _finish, breathe: _breathe),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PROGRESS BAR
// ═════════════════════════════════════════════════════════════════════════════

class _StepBar extends StatelessWidget {
  const _StepBar({
    super.key,
    required this.step,
    required this.total,
    required this.accent,
    this.onSkip,
  });

  final int step;
  final int total;
  final Color accent;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $step of $total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 1.0,
                ),
              ),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: accent.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (step / total).clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.grey.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  WELCOME PAGE
// ═════════════════════════════════════════════════════════════════════════════

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onBegin, required this.breathe});

  final VoidCallback onBegin;
  final AnimationController breathe;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),

          // ── zen orb ──
          _ZenOrb(
            size: 180,
            color: primary,
            breathe: breathe,
            child: Icon(Icons.spa_outlined, size: 48, color: primary),
          ),

          const Spacer(flex: 2),

          // ── branding ──
          Text(
            'BodyPress',
            style: GoogleFonts.playfairDisplay(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your mindful body companion',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 28),
          Container(
            width: 48,
            height: 1,
            color: Colors.grey.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 28),

          // ── philosophy ──
          Text(
            'Tune into your body\'s signals.\n'
            'Understand your environment.\n'
            'Live with intention.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.85,
              fontWeight: FontWeight.w300,
              color: dark ? Colors.white60 : Colors.black45,
            ),
          ),

          const Spacer(flex: 3),

          // ── CTA ──
          _PillButton(label: 'Begin', color: primary, onPressed: onBegin),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  PERMISSION STEP (reusable for each permission)
// ═════════════════════════════════════════════════════════════════════════════

class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.privacy,
    required this.ctaLabel,
    required this.onAllow,
    required this.onSkip,
    required this.busy,
    required this.breathe,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String body;
  final String privacy;
  final String ctaLabel;
  final VoidCallback onAllow;
  final VoidCallback onSkip;
  final bool busy;
  final AnimationController breathe;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // ── scrollable content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 36),

                // orb
                _ZenOrb(
                  size: 140,
                  color: accent,
                  breathe: breathe,
                  child: Icon(icon, size: 42, color: accent),
                ),

                const SizedBox(height: 36),

                // title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                // subtitle label
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 28),

                // body
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.75,
                    fontWeight: FontWeight.w300,
                    color: dark ? Colors.white60 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 24),

                // privacy note
                _PrivacyNote(text: privacy, accent: accent),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── pinned buttons ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              _PillButton(
                label: ctaLabel,
                color: accent,
                onPressed: busy ? null : onAllow,
                busy: busy,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: busy ? null : onSkip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Not now',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  COMPLETE PAGE
// ═════════════════════════════════════════════════════════════════════════════

class _CompletePage extends StatelessWidget {
  const _CompletePage({required this.onEnter, required this.breathe});

  final VoidCallback onEnter;
  final AnimationController breathe;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    const successGreen = Color(0xFF6B8E6B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),

          _ZenOrb(
            size: 160,
            color: successGreen,
            breathe: breathe,
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: successGreen,
            ),
          ),

          const Spacer(flex: 2),

          Text(
            'You\'re ready',
            style: GoogleFonts.playfairDisplay(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 16),
          Container(
            width: 48,
            height: 1,
            color: Colors.grey.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),

          Text(
            'BodyPress is set up to help you\n'
            'tune into your body and environment.\n'
            'Start your mindful journey.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.75,
              fontWeight: FontWeight.w300,
              color: dark ? Colors.white60 : Colors.black45,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'You can adjust permissions anytime in Settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),

          const Spacer(flex: 3),

          _PillButton(
            label: 'Enter BodyPress',
            color: primary,
            onPressed: onEnter,
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

/// Pulsing concentric-circle decoration — the Zen orb.
class _ZenOrb extends StatelessWidget {
  const _ZenOrb({
    required this.size,
    required this.color,
    required this.breathe,
    required this.child,
  });

  final double size;
  final Color color;
  final AnimationController breathe;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: breathe,
      builder: (context, child) {
        final t = breathe.value; // 0 → 1 → 0

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // outer ring
              Transform.scale(
                scale: 1.0 + t * 0.06,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.08 + t * 0.04),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // middle ring
              Transform.scale(
                scale: 1.0 + t * 0.03,
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.12 + t * 0.06),
                      width: 1,
                    ),
                  ),
                ),
              ),
              // inner filled circle
              Container(
                width: size * 0.48,
                height: size * 0.48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
                child: Center(child: this.child),
              ),
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Pill-shaped primary action button.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              )
            : Text(label),
      ),
    );
  }
}

/// Block-quote-style privacy reassurance.
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent.withValues(alpha: 0.4), width: 2),
        ),
        color: accent.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: accent.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: dark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
