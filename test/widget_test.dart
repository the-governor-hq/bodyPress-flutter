// Smoke test — verifies BodyPress can build without errors.
//
// Platform plugins (Health, GPS, Calendar, sqflite, etc.) are not available in
// the test environment, so we override the DB-dependent theme provider and
// assert that the widget tree inflates.

import 'package:bodypress_flutter/core/router/app_router.dart';
import 'package:bodypress_flutter/core/theme/theme_provider.dart';
import 'package:bodypress_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A test-only notifier that returns the default theme without touching the DB.
class _TestThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system; // no DB call
}

void main() {
  setUpAll(() {
    // Initialise the router the same way main() does.
    AppRouter.init(skipOnboarding: true);
  });

  testWidgets('MyApp builds and renders a MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [themeModeProvider.overrideWith(_TestThemeModeNotifier.new)],
        child: const MyApp(),
      ),
    );

    // The MaterialApp.router should have mounted successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
