import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/environment/screens/environment_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/permissions/screens/permissions_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/permissions',
    routes: [
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: const PermissionsScreen()),
      ),
      GoRoute(
        path: '/',
        name: 'home',
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
