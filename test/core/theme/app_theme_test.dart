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

    test('primary and accent colors are defined', () {
      expect(AppTheme.primaryColor, const Color(0xFF6C63FF));
      expect(AppTheme.accentColor, const Color(0xFFFF6584));
      expect(AppTheme.successColor, const Color(0xFF4CAF50));
      expect(AppTheme.warningColor, const Color(0xFFFFC107));
      expect(AppTheme.errorColor, const Color(0xFFFF5252));
    });

    test('background and surface colors are defined', () {
      expect(AppTheme.backgroundColor, const Color(0xFF0F0F1E));
      expect(AppTheme.surfaceColor, const Color(0xFF1A1A2E));
      expect(AppTheme.cardColor, const Color(0xFF16213E));
    });

    test('secondary color is defined', () {
      expect(AppTheme.secondaryColor, const Color(0xFF5C54FF));
    });
  });
}
