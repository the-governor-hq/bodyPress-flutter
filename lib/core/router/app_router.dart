import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/body_blog/screens/body_blog_screen.dart';
import '../../features/environment/screens/environment_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
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
      GoRoute(
        path: '/',
        name: 'blog',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BodyBlogScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/debug',
        name: 'debug',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: '/environment',
        name: 'environment',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const EnvironmentScreen()),
      ),
    ],
  );
}
