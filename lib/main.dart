import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/router/app_router.dart';
import 'core/services/service_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone data is needed for scheduled notifications.
  tz.initializeTimeZones();

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

  // Schedule daily reminder — default to 9:00 AM if never configured.
  final dailyReminderTime = await db.getSetting('daily_reminder_time');
  final int reminderHour;
  final int reminderMinute;
  if (dailyReminderTime != null && dailyReminderTime.isNotEmpty) {
    final parts = dailyReminderTime.split(':');
    reminderHour = (parts.length == 2 ? int.tryParse(parts[0]) : null) ?? 9;
    reminderMinute = (parts.length == 2 ? int.tryParse(parts[1]) : null) ?? 0;
  } else {
    reminderHour = 9;
    reminderMinute = 0;
    await db.setSetting('daily_reminder_time', '9:0');
  }
  final notifService = container.read(notificationServiceProvider);
  await notifService.initialize();
  await notifService.scheduleDailyReminder(
    hour: reminderHour,
    minute: reminderMinute,
  );

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
