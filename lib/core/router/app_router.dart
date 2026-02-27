import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/screens/capture_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/patterns/screens/patterns_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/debug_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/journal',
    routes: [
      // ── Onboarding (no bottom nav) ──────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      // ── Main shell with bottom navigation (3 tabs) ─────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Journal (default)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/journal',
                name: 'journal',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: JournalScreen()),
              ),
            ],
          ),
          // Tab 1 — Patterns
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patterns',
                name: 'patterns',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PatternsScreen()),
              ),
            ],
          ),
          // Tab 2 — Capture
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/capture',
                name: 'capture',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CaptureScreen()),
              ),
            ],
          ),
        ],
      ),

      // ── Standalone routes (no bottom nav) ───────────────────────────
      GoRoute(
        path: '/debug',
        name: 'debug',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DebugScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
        ),
      ),
    ],
  );
}
