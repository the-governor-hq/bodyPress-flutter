import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/background_capture_service.dart';
import 'core/services/local_db_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise background capture scheduler (re-registers periodic task
  // if the user previously enabled it).
  final bgService = BackgroundCaptureService();
  await bgService.initialize();

  // Check whether the user opted out of seeing the intro.
  final db = LocalDbService();
  final skipOnboarding = (await db.getSetting('skip_onboarding')) == 'true';

  AppRouter.init(skipOnboarding: skipOnboarding);

  runApp(const ProviderScope(child: MyApp()));
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
