import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Root scaffold with a floating, frosted-glass zen navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body bleeds under the floating nav bar so the blur has content to blur.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _ZenNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ─── Nav item metadata ────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<_NavItem> _navItems = [
  _NavItem(
    icon: Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories,
    label: 'journal',
  ),
  _NavItem(
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
    label: 'patterns',
  ),
  _NavItem(
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
    label: 'capture',
  ),
];

// ─── Animated zen nav bar ────────────────────────────────────────────────────

class _ZenNavBar extends StatefulWidget {
  const _ZenNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_ZenNavBar> createState() => _ZenNavBarState();
}

class _ZenNavBarState extends State<_ZenNavBar> with TickerProviderStateMixin {
  /// Drives the water-drop shape morph: narrow drop → settled puddle.
  late final AnimationController _dropCtrl;

  /// Drives the horizontal slide of the indicator to the new tab.
  late final AnimationController _slideCtrl;

  late final Animation<double> _dropAnim;
  late final CurvedAnimation _slideAnim;

  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;

    _dropCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Elastic out → mimics a water drop tensioning and settling.
    _dropAnim = CurvedAnimation(parent: _dropCtrl, curve: Curves.elasticOut);

    // Smooth deceleration slide.
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOutCubicEmphasized,
    );

    // Start in "settled" state for the initial tab.
    _dropCtrl.value = 1.0;
    _slideCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_ZenNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _dropCtrl
        ..reset()
        ..forward();
      _slideCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _dropCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 12),
      child: SizedBox(
        height: 68,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.deepSea.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: AppTheme.shimmer.withValues(alpha: 0.45),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  // Faint bioluminescent underglow.
                  BoxShadow(
                    color: AppTheme.glow.withValues(alpha: 0.05),
                    blurRadius: 48,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: Listenable.merge([_dropCtrl, _slideCtrl]),
                builder: (context, _) => _NavBarContent(
                  items: _navItems,
                  currentIndex: widget.currentIndex,
                  prevIndex: _prevIndex,
                  dropAnim: _dropAnim,
                  slideAnim: _slideAnim,
                  onTap: widget.onTap,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Inner content (rebuilt on animation tick) ───────────────────────────────

class _NavBarContent extends StatelessWidget {
  const _NavBarContent({
    required this.items,
    required this.currentIndex,
    required this.prevIndex,
    required this.dropAnim,
    required this.slideAnim,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final int prevIndex;
  final Animation<double> dropAnim;
  final Animation<double> slideAnim;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final total = items.length;
        final itemW = constraints.maxWidth / total;

        // Interpolated x-position of the indicator centre.
        final fromCX = prevIndex * itemW + itemW / 2;
        final toCX = currentIndex * itemW + itemW / 2;
        final cx = Tween<double>(
          begin: fromCX,
          end: toCX,
        ).animate(slideAnim).value;

        // Water-drop shape: starts slightly taller/narrower, then settles.
        final t = dropAnim.value.clamp(0.0, 1.0);
        final dropScaleX = 0.65 + 0.35 * t; // narrows on drop, widens on settle
        final dropScaleY = 1.3 - 0.3 * t; // squishes down as it settles

        const pillW = 52.0;
        const pillH = 28.0;
        const glowR = 52.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Soft radial glow around the active indicator ──────────────
            Positioned(
              left: cx - glowR,
              top: (68 - glowR * 2) / 2,
              width: glowR * 2,
              height: glowR * 2,
              child: Opacity(
                opacity: (0.3 + 0.7 * t).clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.glow.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Pill indicator ────────────────────────────────────────────
            Positioned(
              left: cx - pillW / 2,
              top: (68 - pillH) / 2,
              width: pillW,
              height: pillH,
              child: Transform.scale(
                scaleX: dropScaleX,
                scaleY: dropScaleY,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppTheme.glow.withValues(alpha: 0.13),
                    border: Border.all(
                      color: AppTheme.glow.withValues(alpha: 0.35),
                      width: 0.75,
                    ),
                  ),
                ),
              ),
            ),

            // ── Nav items ─────────────────────────────────────────────────
            Row(
              children: List.generate(total, (i) {
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTap(i);
                    },
                    child: _NavItemTile(
                      item: items[i],
                      isActive: isActive,
                      dropT: isActive ? t : 1.0,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ─── Single nav tile ─────────────────────────────────────────────────────────

class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.dropT,
  });

  final _NavItem item;
  final bool isActive;

  /// 0→1 animation progress for the active drop settle (1 = fully settled).
  final double dropT;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive
        ? Color.lerp(AppTheme.fog, AppTheme.glow, dropT)!
        : AppTheme.fog;

    final textColor = isActive
        ? Color.lerp(AppTheme.fog, AppTheme.glow, dropT)!
        : AppTheme.fog;

    // Icon dips slightly as the "drop" falls in, then rises.
    final dy = isActive ? -3.0 * (1.0 - dropT).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, dy),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            size: 22,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
            letterSpacing: isActive ? 0.2 : 0.6,
            fontFamily: 'DM Sans',
          ),
        ),
      ],
    );
  }
}
