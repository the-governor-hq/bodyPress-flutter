import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global theme mode provider. Defaults to system. Toggle via the sun/moon
/// icon in the top bar to force light or dark mode.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
