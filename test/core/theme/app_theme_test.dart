import 'dart:io';

import 'package:bodypress_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Override HTTP so Google Fonts font-fetch attempts fail instantly
/// (instead of waiting for a real network timeout).
class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(milliseconds: 1);
  }
}

/// Helper: build a ThemeData and then await (and swallow) any pending
/// GoogleFonts font-loading futures so the test runner doesn't see
/// unhandled async errors after the test completes.
Future<ThemeData> _buildThemeSafely(ThemeData Function() builder) async {
  final theme = builder();
  try {
    await GoogleFonts.pendingFonts();
  } catch (_) {
    // Font loading is expected to fail in tests (no network / no assets).
  }
  return theme;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _NoNetworkHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('AppTheme', () {
    // ── Color constants ──

    test('primary and accent colors are defined', () {
      expect(AppTheme.primaryColor, const Color(0xFF6C63FF));
      expect(AppTheme.accentColor, const Color(0xFFFF6584));
      expect(AppTheme.successColor, const Color(0xFF4CAF50));
      expect(AppTheme.warningColor, const Color(0xFFFFC107));
      expect(AppTheme.errorColor, const Color(0xFFFF5252));
    });

    // ── Light Theme ──

    test('lightTheme is Material3 and light', () async {
      final theme = await _buildThemeSafely(() => AppTheme.lightTheme);
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
    });

    test('lightTheme has correct primary color', () async {
      final theme = await _buildThemeSafely(() => AppTheme.lightTheme);
      expect(theme.colorScheme.primary, AppTheme.primaryColor);
    });

    test('lightTheme has correct error color', () async {
      final theme = await _buildThemeSafely(() => AppTheme.lightTheme);
      expect(theme.colorScheme.error, AppTheme.errorColor);
    });

    test('lightTheme card has rounded rectangle shape', () async {
      final theme = await _buildThemeSafely(() => AppTheme.lightTheme);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
    });

    // ── Dark Theme ──

    test('darkTheme is Material3 and dark', () async {
      final theme = await _buildThemeSafely(() => AppTheme.darkTheme);
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
    });

    test('darkTheme has correct surface and background colors', () async {
      final theme = await _buildThemeSafely(() => AppTheme.darkTheme);
      expect(theme.scaffoldBackgroundColor, AppTheme.backgroundColor);
      expect(theme.colorScheme.surface, AppTheme.surfaceColor);
    });

    test('darkTheme has correct card color', () async {
      final theme = await _buildThemeSafely(() => AppTheme.darkTheme);
      expect(theme.cardTheme.color, AppTheme.cardColor);
    });

    test('both themes use same primary color', () async {
      final light = await _buildThemeSafely(() => AppTheme.lightTheme);
      final dark = await _buildThemeSafely(() => AppTheme.darkTheme);
      expect(light.colorScheme.primary, dark.colorScheme.primary);
    });
  });
}
