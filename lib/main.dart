import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/service_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (keys available via dotenv.env['KEY']).
  // Silently ignored when the file is absent (e.g. CI builds that use --dart-define).
  await dotenv.load(fileName: '.env', mergeWith: {}).catchError((_) {});

  // Build a single ProviderContainer that lives for the app's lifetime.
  // All provider reads here share the same instances as the widget tree.
  final container = ProviderContainer();

  // Initialise background capture scheduler (re-registers periodic task
  // if the user previously enabled it).
  final bgService = container.read(backgroundCaptureServiceProvider);
  await bgService.initialize();

  // Check whether the user opted out of seeing the intro.
  final db = container.read(localDbServiceProvider);
  final skipOnboarding = (await db.getSetting('skip_onboarding')) == 'true';

  AppRouter.init(skipOnboarding: skipOnboarding);

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'BodyPress',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
