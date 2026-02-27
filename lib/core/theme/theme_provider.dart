import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_db_service.dart';

const _kThemeModeKey = 'theme_mode';

/// Persisted theme-mode notifier.
///
/// State is synchronous (starts at [ThemeMode.system]) so the UI never
/// blocks; the saved value is loaded asynchronously on first build and
/// written back on every [setThemeMode] call.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadFromDb();
    return ThemeMode.system;
  }

  Future<void> _loadFromDb() async {
    final saved = await LocalDbService().getSetting(_kThemeModeKey);
    if (saved != null) {
      state = _fromString(saved);
    }
  }

  /// Update the theme mode and persist the choice.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await LocalDbService().setSetting(_kThemeModeKey, _toString(mode));
  }

  static ThemeMode _fromString(String s) => switch (s) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };

  static String _toString(ThemeMode m) => switch (m) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    _ => 'system',
  };
}

/// Global theme mode provider — watch to get [ThemeMode], read notifier to
/// call [ThemeModeNotifier.setThemeMode].
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
