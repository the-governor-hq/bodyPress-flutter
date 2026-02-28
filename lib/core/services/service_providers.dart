// ignore_for_file: directives_ordering
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service_provider.dart';
import 'ambient_scan_service.dart';
import 'background_capture_service.dart';
import 'body_blog_service.dart';
import 'calendar_service.dart';
import 'capture_service.dart';
import 'context_window_service.dart';
import 'gps_metrics_service.dart';
import 'health_service.dart';
import 'journal_ai_service.dart';
import 'local_db_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'permission_service.dart';

// Re-export so callers only need to import this one file.
export 'ai_service_provider.dart' show aiServiceProvider;

// ── Infrastructure ──────────────────────────────────────────────────────────

/// Single SQLite connection shared across the whole app.
///
/// Using [keepAlive] ensures the database is never closed while the app
/// lives inside a [ProviderScope], eliminating multiple-connection bugs.
final localDbServiceProvider = Provider<LocalDbService>((ref) {
  final service = LocalDbService();
  // No explicit dispose needed — sqflite manages the connection lifecycle.
  return service;
}, dependencies: []);

// ── Leaf services (no inter-service dependencies) ───────────────────────────

final healthServiceProvider = Provider<HealthService>((_) => HealthService());

final locationServiceProvider = Provider<LocationService>(
  (_) => LocationService(),
);

final calendarServiceProvider = Provider<CalendarService>(
  (_) => CalendarService(),
);

final ambientScanServiceProvider = Provider<AmbientScanService>(
  (_) => AmbientScanService(),
);

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
);

/// [NotificationService] ships its own internal singleton; the provider just
/// surfaces it so it can be injected / overridden in tests.
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

final gpsMetricsServiceProvider = Provider<GpsMetricsService>((ref) {
  final service = GpsMetricsService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Composite services ──────────────────────────────────────────────────────

final journalAiServiceProvider = Provider<JournalAiService>((ref) {
  return JournalAiService(ai: ref.read(aiServiceProvider));
});

final contextWindowServiceProvider = Provider<ContextWindowService>((ref) {
  return ContextWindowService(db: ref.read(localDbServiceProvider));
});

final captureServiceProvider = Provider<CaptureService>((ref) {
  return CaptureService(
    healthService: ref.read(healthServiceProvider),
    ambientService: ref.read(ambientScanServiceProvider),
    locationService: ref.read(locationServiceProvider),
    calendarService: ref.read(calendarServiceProvider),
    dbService: ref.read(localDbServiceProvider),
  );
});

final backgroundCaptureServiceProvider = Provider<BackgroundCaptureService>((
  ref,
) {
  return BackgroundCaptureService(dbService: ref.read(localDbServiceProvider));
});

final bodyBlogServiceProvider = Provider<BodyBlogService>((ref) {
  return BodyBlogService(
    health: ref.read(healthServiceProvider),
    location: ref.read(locationServiceProvider),
    calendar: ref.read(calendarServiceProvider),
    ambient: ref.read(ambientScanServiceProvider),
    db: ref.read(localDbServiceProvider),
    ai: ref.read(journalAiServiceProvider),
  );
});

// ── Health permission reactive status ───────────────────────────────────────

/// A [FutureProvider] that resolves to whether health permissions are granted.
/// Invalidate this provider after a permission change to force a refresh:
///   ref.invalidate(healthPermissionStatusProvider);
final healthPermissionStatusProvider = FutureProvider<bool>((ref) async {
  return ref.read(healthServiceProvider).hasPermissions();
});

/// A [FutureProvider] that resolves to whether the health platform is available
/// on this device (HealthKit on iOS, Health Connect installed on Android).
final healthAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(healthServiceProvider).isHealthAvailable();
});
