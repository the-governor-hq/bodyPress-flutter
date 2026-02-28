/// Configuration for AI execution mode (remote vs local).
///
/// Persisted in the settings table so the chosen mode survives app restarts.
/// The debug screen is the only place users can change this in phase 1.
library;

/// Which AI backend the app should route inference requests through.
enum AiMode {
  /// Default — calls the remote gateway at ai.governor-hq.com.
  remote,

  /// All inference runs on-device. **No** network calls are made.
  /// If the local model is unavailable the request hard-fails.
  local,
}

/// Lifecycle state of the downloaded local model.
enum LocalModelStatus {
  /// No model has been downloaded yet.
  notDownloaded,

  /// A model download is in progress.
  downloading,

  /// Model files are on disk and ready to load.
  downloaded,

  /// The runtime has loaded the model into memory — inference is available.
  ready,

  /// Something went wrong (download failed, corrupt file, etc.).
  error,
}

/// Which on-device inference backend is being used.
enum LocalModelBackend {
  /// Platform-native ML APIs (Android ML Kit / Core ML).
  osNative,

  /// Bundled cross-platform runtime (e.g. llama.cpp via ffi, mediapipe, etc.).
  bundledRuntime,

  /// No backend resolved yet.
  none,
}

/// Snapshot of all local-LLM state, used by the debug panel and provider.
class AiModeConfig {
  final AiMode mode;
  final LocalModelStatus modelStatus;
  final LocalModelBackend backend;

  /// Human-readable model identifier (e.g. "gemma-2b-it-q4").
  final String? modelName;

  /// Download progress 0.0 – 1.0 while [modelStatus] == downloading.
  final double downloadProgress;

  /// Last error message, if any.
  final String? error;

  const AiModeConfig({
    this.mode = AiMode.remote,
    this.modelStatus = LocalModelStatus.notDownloaded,
    this.backend = LocalModelBackend.none,
    this.modelName,
    this.downloadProgress = 0.0,
    this.error,
  });

  AiModeConfig copyWith({
    AiMode? mode,
    LocalModelStatus? modelStatus,
    LocalModelBackend? backend,
    String? modelName,
    double? downloadProgress,
    String? error,
  }) {
    return AiModeConfig(
      mode: mode ?? this.mode,
      modelStatus: modelStatus ?? this.modelStatus,
      backend: backend ?? this.backend,
      modelName: modelName ?? this.modelName,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error ?? this.error,
    );
  }

  /// Whether local inference is both selected **and** operational.
  bool get isLocalReady =>
      mode == AiMode.local && modelStatus == LocalModelStatus.ready;

  /// Whether the user has chosen local mode (may or may not be ready).
  bool get isLocalMode => mode == AiMode.local;

  /// Persistence key constants.
  static const kModeKey = 'ai_mode';
  static const kModelNameKey = 'ai_local_model_name';
  static const kBackendKey = 'ai_local_backend';
}
