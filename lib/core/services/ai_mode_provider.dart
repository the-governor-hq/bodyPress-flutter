import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_mode_config.dart';
import 'ai_router.dart';
import 'ai_service_provider.dart' show aiRouterProvider;
import 'local_ai_service.dart';
import 'local_db_service.dart';

/// Dedicated DB provider for AI mode persistence.
///
/// Points to the same [LocalDbService] singleton as `localDbServiceProvider`
/// but is defined here to avoid a circular import with service_providers.dart.
final _aiModeDb = Provider<LocalDbService>((_) => LocalDbService());

/// Notifier that manages the [AiModeConfig] lifecycle: mode switching,
/// model download / activate / delete, and persistence.
///
/// The actual inference routing lives in [AiRouter]; this notifier just
/// keeps [AiRouter.mode] in sync with the persisted user choice.
class AiModeNotifier extends AsyncNotifier<AiModeConfig> {
  late final AiRouter _router;
  late final LocalDbService _db;

  LocalAiService get _local => _router.local;

  // ── Initialisation ─────────────────────────────────────────────────────────

  @override
  Future<AiModeConfig> build() async {
    _router = ref.read(aiRouterProvider);
    _db = ref.read(_aiModeDb);

    // Restore persisted mode.
    final savedMode = await _db.getSetting(AiModeConfig.kModeKey);
    final mode = savedMode == 'local' ? AiMode.local : AiMode.remote;
    _router.mode = mode;

    // Probe local backend if in local mode.
    if (mode == AiMode.local) {
      await _local.resolveBackend();
    }

    return _local.toConfig(mode);
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  /// Switch between remote and local mode. Persists the choice.
  Future<void> setMode(AiMode mode) async {
    await _db.setSetting(AiModeConfig.kModeKey, mode.name);
    _router.mode = mode;
    if (mode == AiMode.local) {
      await _local.resolveBackend();
    }
    state = AsyncData(_local.toConfig(mode));
  }

  /// Download (or verify) a local model.
  Future<void> downloadModel() async {
    final current = state.valueOrNull ?? const AiModeConfig();
    state = AsyncData(
      current.copyWith(modelStatus: LocalModelStatus.downloading),
    );

    await _local.downloadModel(
      onProgress: (p) {
        final c = state.valueOrNull ?? const AiModeConfig();
        state = AsyncData(c.copyWith(downloadProgress: p));
      },
    );

    state = AsyncData(_local.toConfig(current.mode));
  }

  /// Load the downloaded model into the runtime.
  Future<void> activateModel() async {
    await _local.activateModel();
    final current = state.valueOrNull ?? const AiModeConfig();
    state = AsyncData(_local.toConfig(current.mode));
  }

  /// Unload model from memory (keeps files on disk).
  Future<void> deactivateModel() async {
    await _local.deactivateModel();
    final current = state.valueOrNull ?? const AiModeConfig();
    state = AsyncData(_local.toConfig(current.mode));
  }

  /// Delete model files and reset.
  Future<void> deleteModel() async {
    await _local.deleteModel();
    final current = state.valueOrNull ?? const AiModeConfig();
    state = AsyncData(_local.toConfig(current.mode));
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

/// The main AI mode state provider (config + actions).
final aiModeProvider = AsyncNotifierProvider<AiModeNotifier, AiModeConfig>(
  AiModeNotifier.new,
);
