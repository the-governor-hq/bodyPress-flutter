import 'package:workmanager/workmanager.dart';

import '../background/capture_executor.dart';
import '../models/background_capture_config.dart';
import 'local_db_service.dart';

/// Unique task name registered with WorkManager.
const _periodicTaskName = 'com.bodypress.backgroundCapture';

/// Unique task identifier tag.
const _periodicTaskTag = 'capture_periodic';

/// Central orchestrator for scheduling and managing background captures.
///
/// Wraps the `workmanager` plugin and persists user preferences through
/// [LocalDbService].  Call [initialize] once at app startup (in `main()`),
/// then use [enable] / [disable] / [updateConfig] to control behaviour.
class BackgroundCaptureService {
  final LocalDbService _dbService;

  BackgroundCaptureService({LocalDbService? dbService})
    : _dbService = dbService ?? LocalDbService();

  // ── Initialization ──────────────────────────────────────────────────────

  /// Must be called once at app startup (after `WidgetsFlutterBinding`
  /// has been initialised).
  ///
  /// Registers the background callback with WorkManager and, if the user
  /// previously enabled background captures, re-registers the periodic task
  /// so it survives app updates and reboots.
  Future<void> initialize() async {
    await Workmanager().initialize(
      _workmanagerCallbackDispatcher,
      isInDebugMode: false,
    );

    // Re-register if previously enabled
    final config = await loadConfig();
    if (config.enabled) {
      await _registerPeriodicTask(config);
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Enable background captures with the given (or current) configuration.
  Future<void> enable([BackgroundCaptureConfig? config]) async {
    final cfg = config ?? await loadConfig();
    final enabled = cfg.copyWith(enabled: true);
    await saveConfig(enabled);
    await _registerPeriodicTask(enabled);
  }

  /// Disable background captures and cancel any scheduled tasks.
  Future<void> disable() async {
    final config = await loadConfig();
    await saveConfig(config.copyWith(enabled: false));
    await Workmanager().cancelByTag(_periodicTaskTag);
  }

  /// Update the configuration and re-schedule if enabled.
  Future<void> updateConfig(BackgroundCaptureConfig config) async {
    await saveConfig(config);
    if (config.enabled) {
      // Cancel the old schedule and register with new interval.
      await Workmanager().cancelByTag(_periodicTaskTag);
      await _registerPeriodicTask(config);
    } else {
      await Workmanager().cancelByTag(_periodicTaskTag);
    }
  }

  /// Trigger a one-off background capture immediately (useful for debugging).
  Future<void> triggerNow() async {
    await Workmanager().registerOneOffTask(
      'capture_immediate_${DateTime.now().millisecondsSinceEpoch}',
      _periodicTaskName,
      tag: _periodicTaskTag,
      existingWorkPolicy: ExistingWorkPolicy.append,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  // ── Config persistence ────────────────────────────────────────────────

  static const _configKey = 'background_capture_config';

  /// Load the persisted configuration (returns defaults if never saved).
  Future<BackgroundCaptureConfig> loadConfig() async {
    final raw = await _dbService.getSetting(_configKey);
    if (raw == null) return BackgroundCaptureConfig.defaultConfig;
    return BackgroundCaptureConfig.decode(raw);
  }

  /// Save the configuration to the database.
  Future<void> saveConfig(BackgroundCaptureConfig config) async {
    await _dbService.setSetting(_configKey, config.encode());
  }

  // ── Statistics ────────────────────────────────────────────────────────

  /// Human-readable stats map for the debug panel / settings screen.
  Future<Map<String, String>> getStats() async {
    final lastCapture = await _dbService.getSetting('last_background_capture');
    final successes = await _dbService.getSetting('bg_capture_success_count');
    final failures = await _dbService.getSetting('bg_capture_failure_count');
    return {
      'last_capture': lastCapture ?? 'never',
      'successes': successes ?? '0',
      'failures': failures ?? '0',
    };
  }

  /// Reset all background capture statistics.
  Future<void> resetStats() async {
    await _dbService.setSetting('last_background_capture', '');
    await _dbService.setSetting('bg_capture_success_count', '0');
    await _dbService.setSetting('bg_capture_failure_count', '0');
  }

  // ── Internals ─────────────────────────────────────────────────────────

  Future<void> _registerPeriodicTask(BackgroundCaptureConfig config) async {
    // Android WorkManager enforces a 15-minute minimum.
    final frequency = config.interval.inMinutes < 15
        ? const Duration(minutes: 15)
        : config.interval;

    await Workmanager().registerPeriodicTask(
      _periodicTaskTag,
      _periodicTaskName,
      frequency: frequency,
      tag: _periodicTaskTag,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: config.batteryOptimization,
      ),
    );
  }
}

// ── WorkManager callback ──────────────────────────────────────────────────

/// Top-level function called by the native WorkManager / BGTaskScheduler.
///
/// Must be a **top-level** or `static` function to be callable from the
/// platform side.
@pragma('vm:entry-point')
void _workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == _periodicTaskName ||
        taskName == Workmanager.iOSBackgroundTask) {
      return captureExecutorCallback();
    }
    return true;
  });
}
