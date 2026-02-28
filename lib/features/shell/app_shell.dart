import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Root scaffold with a reader-inspired editorial chapter navigation.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body bleeds under the floating nav bar so the blur has content to blur.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _ChapterNav(
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
    required this.numeral,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Roman numeral shown as a subtle chapter marker on active tab.
  final String numeral;
}

const List<_NavItem> _navItems = [
  _NavItem(
    icon: Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories,
    label: 'Journal',
    numeral: 'I',
  ),
  _NavItem(
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
    label: 'Patterns',
    numeral: 'II',
  ),
  _NavItem(
    icon: Icons.edit_note_rounded,
    activeIcon: Icons.edit_note_rounded,
    label: 'Capture',
    numeral: 'III',
  ),
];

// ─── Chapter navigation bar ────────────────────────────────────────────────────

class _ChapterNav extends StatefulWidget {
  const _ChapterNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_ChapterNav> createState() => _ChapterNavState();
}

class _ChapterNavState extends State<_ChapterNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final CurvedAnimation _slideAnim;

  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentIndex;

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideCtrl,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _slideCtrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_ChapterNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prevIndex = old.currentIndex;
      _slideCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 10),
      child: SizedBox(
        height: 72,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.deepSea.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.shimmer.withValues(alpha: 0.30),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _slideAnim,
                builder: (context, _) => _ChapterNavContent(
                  items: _navItems,
                  currentIndex: widget.currentIndex,
                  prevIndex: _prevIndex,
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

class _ChapterNavContent extends StatelessWidget {
  const _ChapterNavContent({
    required this.items,
    required this.currentIndex,
    required this.prevIndex,
    required this.slideAnim,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final int prevIndex;
  final Animation<double> slideAnim;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final total = items.length;
        final itemW = constraints.maxWidth / total;

        // Interpolated x-position of the sliding top rule.
        final fromX = prevIndex * itemW;
        final toX = currentIndex * itemW;
        final lineX = Tween<double>(
          begin: fromX,
          end: toX,
        ).animate(slideAnim).value;

        // The rule inset from each tab edge — gives a refined, editorial gap.
        const lineInset = 22.0;
        const lineH = 1.5;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Glowing top-rule chapter indicator ────────────────────────
            Positioned(
              left: lineX + lineInset,
              top: 0,
              width: itemW - lineInset * 2,
              height: lineH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.glow,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glow.withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),

            // ── Subtle dividers between tabs ──────────────────────────────
            ...List.generate(total - 1, (i) {
              return Positioned(
                left: itemW * (i + 1),
                top: 20,
                bottom: 20,
                width: 0.5,
                child: ColoredBox(
                  color: AppTheme.shimmer.withValues(alpha: 0.40),
                ),
              );
            }),

            // ── Chapter tabs ──────────────────────────────────────────────
            Row(
              children: List.generate(total, (i) {
                final isActive = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: _ChapterTab(item: items[i], isActive: isActive),
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

// ─── Single chapter tab ──────────────────────────────────────────────────────

class _ChapterTab extends StatelessWidget {
  const _ChapterTab({required this.item, required this.isActive});

  final _NavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final iconColor = isActive ? AppTheme.glow : AppTheme.fog;
    final labelColor = isActive ? AppTheme.moonbeam : AppTheme.fog;
    final numeralColor = isActive
        ? AppTheme.glow.withValues(alpha: 0.70)
        : Colors.transparent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 4), // breathing room below the top rule
        // ── Chapter numeral ──────────────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: numeralColor,
            letterSpacing: 1.5,
            fontFamily: 'DM Sans',
          ),
          child: Text(item.numeral),
        ),
        const SizedBox(height: 2),
        // ── Icon ─────────────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            key: ValueKey(isActive),
            size: 20,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 4),
        // ── Label (all-caps editorial) ────────────────────────────────────
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: labelColor,
            letterSpacing: 2.2,
            fontFamily: 'DM Sans',
          ),
          child: Text(item.label.toUpperCase()),
        ),
      ],
    );
  }
}
