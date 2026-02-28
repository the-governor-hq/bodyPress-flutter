import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around `flutter_local_notifications` scoped to the channels
/// BodyPress needs.
///
/// Currently only one channel: **Background Captures** — used by the
/// [CaptureExecutor] to surface results to the user.
class NotificationService {
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Channel IDs ─────────────────────────────────────────────────────────

  static const _captureChannelId = 'bodypress_background_capture';
  static const _captureChannelName = 'Background Captures';
  static const _captureChannelDescription =
      'Notifications for automatic background data captures';

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Initialise the notification plugin and create Android channels.
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialised) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Create the Android notification channel (no-op on iOS).
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _captureChannelId,
            _captureChannelName,
            description: _captureChannelDescription,
            importance: Importance.low,
          ),
        );

    _initialised = true;
  }

  // ── Public helpers ────────────────────────────────────────────────────

  /// Show a "capture complete" notification.
  Future<void> showCaptureComplete({
    required String captureId,
    String? dataSources,
  }) async {
    await _ensureInitialised();

    final body = dataSources != null
        ? 'Captured $dataSources automatically.'
        : 'Automatic data capture complete.';

    await _plugin.show(
      captureId.hashCode, // unique int per capture
      'Background Capture',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _captureChannelId,
          _captureChannelName,
          channelDescription: _captureChannelDescription,
          importance: Importance.low,
          priority: Priority.low,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  /// Show a notification for a capture error (only for critical failures).
  Future<void> showCaptureError({required String message}) async {
    await _ensureInitialised();

    await _plugin.show(
      'capture_error'.hashCode,
      'Capture Failed',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _captureChannelId,
          _captureChannelName,
          channelDescription: _captureChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  /// Request notification permission on Android 13+ / iOS.
  Future<bool> requestPermission() async {
    // Android 13+
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    // iOS
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  // ── Internals ─────────────────────────────────────────────────────────

  Future<void> _ensureInitialised() async {
    if (!_initialised) await initialize();
  }
}
