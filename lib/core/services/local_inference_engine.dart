import 'dart:async';

import '../models/ai_models.dart';

/// Result of a single on-device inference call.
///
/// Carries the generated text **plus** performance metadata so callers can
/// monitor model quality without changing their control flow.
class InferenceResult {
  /// The generated text.
  final String text;

  /// Wall-clock time from prompt submission to final token.
  final Duration latency;

  /// Estimated number of prompt tokens processed.
  final int promptTokens;

  /// Number of tokens generated in the response.
  final int completionTokens;

  /// The engine that produced this result (e.g. "platform-channel", "stub").
  final String engineName;

  const InferenceResult({
    required this.text,
    required this.latency,
    this.promptTokens = 0,
    this.completionTokens = 0,
    required this.engineName,
  });

  /// Approximate tokens-per-second for the **completion** phase.
  ///
  /// Returns `0` when latency or token count is zero (avoids division errors).
  double get tokensPerSecond {
    if (latency.inMilliseconds == 0 || completionTokens == 0) return 0;
    return completionTokens / (latency.inMilliseconds / 1000);
  }
}

/// Abstract interface that any on-device LLM inference backend must implement.
///
/// Implementations:
///  - [PlatformChannelEngine]  — delegates to native Kotlin / Swift code.
///  - [StubInferenceEngine]    — deterministic fakes for tests and dev builds.
///
/// [LocalAiService] owns one engine instance and delegates all generation
/// through it, keeping model lifecycle management separate from inference.
abstract class LocalInferenceEngine {
  /// Human-readable backend identifier (e.g. `"platform-channel"`, `"stub"`).
  String get engineName;

  /// `true` after [loadModel] completes successfully.
  bool get isModelLoaded;

  /// Probe the host platform and return `true` if this backend can run
  /// (native libraries present, sufficient hardware, etc.).
  Future<bool> isAvailable();

  /// Load a model by [modelPath] (file-system path or logical identifier)
  /// into the runtime's memory.
  ///
  /// Throws [AiServiceException] if the model cannot be loaded.
  Future<void> loadModel(String modelPath);

  /// Unload the current model from memory. Safe to call even when no model
  /// is loaded.
  Future<void> unloadModel();

  /// Run chat-completion inference on [messages].
  ///
  /// Throws [AiServiceException] if the model is not loaded or inference
  /// fails for any reason.
  Future<InferenceResult> infer(
    List<ChatMessage> messages, {
    double? temperature,
    int? maxTokens,
  });

  /// Release all platform resources held by this engine.
  void dispose();
}
