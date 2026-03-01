import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/ai_mode_config.dart';
import '../models/ai_models.dart';
import '../models/local_model_spec.dart';
import 'local_inference_engine.dart';
import 'platform_channel_engine.dart';
import 'stub_inference_engine.dart';

/// On-device LLM inference orchestrator.
///
/// Manages the full model lifecycle — **resolve → download → activate →
/// infer → deactivate → delete** — and delegates actual token generation
/// to a pluggable [LocalInferenceEngine].
///
/// ## Engine selection
///
/// | Constructor                          | Engine                  | Use case           |
/// |--------------------------------------|-------------------------|--------------------|
/// | `LocalAiService()`                   | [PlatformChannelEngine] | Production         |
/// | `LocalAiService.stub()`              | [StubInferenceEngine]   | Unit tests / dev   |
/// | `LocalAiService(engine: custom)`     | any implementation      | Integration tests  |
///
/// All inference is **strictly offline** — no HTTP traffic is generated.
class LocalAiService {
  final LocalInferenceEngine _engine;

  LocalModelStatus _status = LocalModelStatus.notDownloaded;
  LocalModelBackend _backend = LocalModelBackend.none;
  LocalModelSpec? _modelSpec;
  String? _modelName;
  double _downloadProgress = 0.0;
  String? _lastError;

  /// Production constructor — uses [PlatformChannelEngine] by default.
  LocalAiService({LocalInferenceEngine? engine})
    : _engine = engine ?? PlatformChannelEngine();

  /// Explicit test / development constructor with [StubInferenceEngine].
  ///
  /// Responses are deterministic and structurally valid so the full
  /// pipeline (journal, metadata) can be exercised without native code.
  @visibleForTesting
  factory LocalAiService.stub({Duration? simulatedLatency}) {
    return LocalAiService(
      engine: StubInferenceEngine(
        simulatedLatency: simulatedLatency ?? const Duration(milliseconds: 10),
      ),
    );
  }

  // ── Getters ──────────────────────────────────────────────────────────────

  LocalModelStatus get status => _status;
  LocalModelBackend get backend => _backend;
  String? get modelName => _modelName;
  LocalModelSpec? get modelSpec => _modelSpec;
  double get downloadProgress => _downloadProgress;
  String? get lastError => _lastError;

  /// Human-readable engine identifier (e.g. `"platform-channel"`, `"stub"`).
  String get engineName => _engine.engineName;

  // ── Model lifecycle ──────────────────────────────────────────────────────

  /// Probe the platform for which inference backend is available.
  ///
  /// Returns the resolved [LocalModelBackend] and caches it internally.
  Future<LocalModelBackend> resolveBackend() async {
    final available = await _engine.isAvailable();
    _backend = available
        ? LocalModelBackend.bundledRuntime
        : LocalModelBackend.none;
    debugPrint(
      '[LocalAiService] Backend resolved: ${_backend.name} '
      '(engine: ${_engine.engineName})',
    );
    return _backend;
  }

  /// Download (or verify) a local model.
  ///
  /// [spec] selects which model to download. Defaults to
  /// [LocalModelRegistry.defaultModel].
  /// [onProgress] fires with 0.0–1.0 during the transfer.
  /// Completes with the final [LocalModelStatus].
  Future<LocalModelStatus> downloadModel({
    LocalModelSpec? spec,
    void Function(double progress)? onProgress,
  }) async {
    _modelSpec = spec ?? LocalModelRegistry.defaultModel;
    _status = LocalModelStatus.downloading;
    _downloadProgress = 0.0;
    _lastError = null;

    try {
      if (_engine is StubInferenceEngine) {
        // Simulate realistic progress ticks for test coverage.
        for (final p in [0.25, 0.5, 0.75, 1.0]) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          _downloadProgress = p;
          onProgress?.call(p);
        }
        _modelName = _modelSpec!.id;
        _status = LocalModelStatus.downloaded;
      } else {
        // Real download via platform channel.
        const channel = MethodChannel('com.bodypress/local_llm');

        channel.setMethodCallHandler((call) async {
          if (call.method == 'downloadProgress') {
            _downloadProgress = (call.arguments as num).toDouble();
            onProgress?.call(_downloadProgress);
          }
        });

        final result = await channel.invokeMethod<Map>('downloadModel', {
          'modelId': _modelSpec!.id,
          'downloadUrl': _modelSpec!.downloadUrl,
          'expectedSha256': _modelSpec!.sha256,
          'fileSizeBytes': _modelSpec!.fileSizeBytes,
        });

        _modelName = result?['modelName'] as String? ?? _modelSpec!.id;
        _status = LocalModelStatus.downloaded;
        _downloadProgress = 1.0;
        onProgress?.call(1.0);
      }
      debugPrint('[LocalAiService] Model downloaded: $_modelName');
    } on MissingPluginException {
      _lastError =
          'Native download handler not implemented — '
          'wire up the ${_modelSpec!.format.toUpperCase()} download '
          'in the platform layer first.';
      _status = LocalModelStatus.error;
      debugPrint('[LocalAiService] ERROR: $_lastError');
    } catch (e) {
      _status = LocalModelStatus.error;
      _lastError = e.toString();
      debugPrint('[LocalAiService] Download failed: $e');
    }
    return _status;
  }

  /// Load the downloaded model into the inference runtime.
  Future<LocalModelStatus> activateModel() async {
    if (_status != LocalModelStatus.downloaded) {
      _lastError =
          'Cannot activate — model not downloaded (status: ${_status.name})';
      return _status;
    }

    try {
      await _engine.loadModel(_modelName ?? _modelSpec?.id ?? 'unknown');
      _status = LocalModelStatus.ready;
      _lastError = null;
      debugPrint('[LocalAiService] Model activated via ${_engine.engineName}');
    } on MissingPluginException {
      _status = LocalModelStatus.error;
      _lastError =
          'Native activation handler not implemented — '
          'register the platform channel before activating.';
      debugPrint('[LocalAiService] ERROR: $_lastError');
    } catch (e) {
      _status = LocalModelStatus.error;
      _lastError = e.toString();
      debugPrint('[LocalAiService] Activation failed: $e');
    }
    return _status;
  }

  /// Unload the model from memory (files remain on disk).
  Future<void> deactivateModel() async {
    await _engine.unloadModel();
    _status = _modelName != null
        ? LocalModelStatus.downloaded
        : LocalModelStatus.notDownloaded;
    _lastError = null;
    debugPrint('[LocalAiService] Model deactivated');
  }

  /// Delete model files and reset all state.
  Future<void> deleteModel() async {
    await _engine.unloadModel();

    // Platform engines may have native file cleanup.
    if (_engine is! StubInferenceEngine) {
      try {
        const channel = MethodChannel('com.bodypress/local_llm');
        await channel.invokeMethod<void>('deleteModel');
      } on MissingPluginException {
        // OK — no native handler registered.
      }
    }

    _status = LocalModelStatus.notDownloaded;
    _modelName = null;
    _modelSpec = null;
    _downloadProgress = 0.0;
    _lastError = null;
    debugPrint('[LocalAiService] Model deleted');
  }

  // ── Inference (mirrors AiService public API) ──────────────────────────────

  /// Run a chat completion locally.
  ///
  /// Returns a full [ChatCompletionResponse] with [ChatUsage] populated
  /// from the engine's [InferenceResult]. Throws [AiServiceException] if the
  /// model is not ready.
  Future<ChatCompletionResponse> chatCompletion(
    List<ChatMessage> messages, {
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    _assertReady();

    final result = await _engine.infer(
      messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    return ChatCompletionResponse(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      object: 'chat.completion',
      created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      model: _modelName ?? 'local-${_engine.engineName}',
      choices: [
        ChatChoice(
          index: 0,
          message: ChatMessage.assistant(result.text),
          finishReason: 'stop',
        ),
      ],
      usage: ChatUsage(
        promptTokens: result.promptTokens,
        completionTokens: result.completionTokens,
        totalTokens: result.promptTokens + result.completionTokens,
      ),
    );
  }

  /// Simplified ask method matching [AiService.ask].
  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    final messages = <ChatMessage>[
      if (systemPrompt != null) ChatMessage.system(systemPrompt),
      ChatMessage.user(userPrompt),
    ];

    final response = await chatCompletion(
      messages,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return response.content;
  }

  /// `true` when the model is loaded and inference is available.
  Future<bool> checkHealth() async {
    return _status == LocalModelStatus.ready;
  }

  /// Build a snapshot of current state for the config model.
  AiModeConfig toConfig(AiMode mode) {
    return AiModeConfig(
      mode: mode,
      modelStatus: _status,
      backend: _backend,
      modelName: _modelName,
      downloadProgress: _downloadProgress,
      error: _lastError,
    );
  }

  void dispose() {
    _engine.dispose();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _assertReady() {
    if (_status != LocalModelStatus.ready) {
      throw AiServiceException(
        'Local model not ready '
        '(status: ${_status.name}, engine: ${_engine.engineName})',
      );
    }
  }
}
