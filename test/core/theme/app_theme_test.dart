import 'package:bodypress_flutter/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    // Prevent GoogleFonts from making network requests during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme', () {
    // ── Color constants ──

    // ── Midnight Ocean palette ──
    test('primary and accent colors are defined', () {
      // Primary = moonlit teal glow
      expect(AppTheme.primaryColor, const Color(0xFF4DD4C8));
      // Accent = pale sky starlight
      expect(AppTheme.accentColor, const Color(0xFFB0CCEF));
      expect(AppTheme.successColor, const Color(0xFF38C87E));
      expect(AppTheme.warningColor, const Color(0xFFFFBD5A));
      expect(AppTheme.errorColor, const Color(0xFFFF5A7A));
    });

    test('background and surface colors are defined', () {
      expect(AppTheme.backgroundColor, const Color(0xFF0A0E1A));
      expect(AppTheme.surfaceColor, const Color(0xFF101625));
      expect(AppTheme.cardColor, const Color(0xFF172036));
    });

    test('secondary color is defined', () {
      // Secondary = amethyst aurora
      expect(AppTheme.secondaryColor, const Color(0xFF8B78F5));
    });
  });
}
