import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/ai_mode_config.dart';
import '../models/ai_models.dart';

/// On-device LLM inference service.
///
/// Mirrors the public API surface of [AiService] so callers can swap
/// transparently. Under the hood it talks to a platform channel that
/// delegates to OS-native ML or a bundled runtime (hybrid strategy).
///
/// All calls are **strictly offline** — no HTTP traffic is generated.
class LocalAiService {
  static const _channel = MethodChannel('com.bodypress/local_llm');

  LocalModelStatus _status = LocalModelStatus.notDownloaded;
  LocalModelBackend _backend = LocalModelBackend.none;
  String? _modelName;
  double _downloadProgress = 0.0;
  String? _lastError;

  // ── Getters ────────────────────────────────────────────────────────────────

  LocalModelStatus get status => _status;
  LocalModelBackend get backend => _backend;
  String? get modelName => _modelName;
  double get downloadProgress => _downloadProgress;
  String? get lastError => _lastError;

  // ── Model lifecycle ────────────────────────────────────────────────────────

  /// Probe the platform for which backend is available.
  ///
  /// Returns the resolved [LocalModelBackend] and caches it.
  Future<LocalModelBackend> resolveBackend() async {
    try {
      final result = await _channel.invokeMethod<String>('resolveBackend');
      switch (result) {
        case 'osNative':
          _backend = LocalModelBackend.osNative;
        case 'bundledRuntime':
          _backend = LocalModelBackend.bundledRuntime;
        default:
          _backend = LocalModelBackend.none;
      }
    } on MissingPluginException {
      // Platform channel not yet implemented — expected during scaffolding.
      _backend = LocalModelBackend.none;
      debugPrint('[LocalAiService] Platform channel not available yet');
    } catch (e) {
      _backend = LocalModelBackend.none;
      _lastError = e.toString();
      debugPrint('[LocalAiService] resolveBackend error: $e');
    }
    return _backend;
  }

  /// Download (or verify) a local model suitable for this device.
  ///
  /// [onProgress] fires with 0.0–1.0 while bytes are transferred.
  /// Completes with the final [LocalModelStatus].
  Future<LocalModelStatus> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    _status = LocalModelStatus.downloading;
    _downloadProgress = 0.0;
    _lastError = null;

    try {
      // Set up progress listener
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'downloadProgress') {
          _downloadProgress = (call.arguments as num).toDouble();
          onProgress?.call(_downloadProgress);
        }
      });

      final result = await _channel.invokeMethod<Map>('downloadModel');
      _modelName = result?['modelName'] as String?;
      _status = LocalModelStatus.downloaded;
      _downloadProgress = 1.0;
      onProgress?.call(1.0);
      debugPrint('[LocalAiService] Model downloaded: $_modelName');
    } on MissingPluginException {
      // Stub: simulate a successful download for development.
      _modelName = 'stub-model-q4';
      _status = LocalModelStatus.downloaded;
      _downloadProgress = 1.0;
      onProgress?.call(1.0);
      debugPrint('[LocalAiService] Stub download (channel not wired)');
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
      _lastError = 'Cannot activate — model not downloaded';
      return _status;
    }

    try {
      await _channel.invokeMethod<void>('activateModel');
      _status = LocalModelStatus.ready;
      debugPrint('[LocalAiService] Model activated');
    } on MissingPluginException {
      // Stub: mark as ready for development.
      _status = LocalModelStatus.ready;
      debugPrint('[LocalAiService] Stub activate (channel not wired)');
    } catch (e) {
      _status = LocalModelStatus.error;
      _lastError = e.toString();
      debugPrint('[LocalAiService] Activation failed: $e');
    }
    return _status;
  }

  /// Unload the model from memory (keeps files on disk).
  Future<void> deactivateModel() async {
    try {
      await _channel.invokeMethod<void>('deactivateModel');
    } on MissingPluginException {
      // Ignored for stub.
    }
    _status = _modelName != null
        ? LocalModelStatus.downloaded
        : LocalModelStatus.notDownloaded;
    debugPrint('[LocalAiService] Model deactivated');
  }

  /// Delete model files and reset state.
  Future<void> deleteModel() async {
    try {
      await _channel.invokeMethod<void>('deleteModel');
    } on MissingPluginException {
      // Ignored for stub.
    }
    _status = LocalModelStatus.notDownloaded;
    _modelName = null;
    _downloadProgress = 0.0;
    debugPrint('[LocalAiService] Model deleted');
  }

  // ── Inference (mirrors AiService public API) ──────────────────────────────

  /// Run a chat completion locally.
  ///
  /// Throws [AiServiceException] if the model isn't ready or inference fails.
  Future<ChatCompletionResponse> chatCompletion(
    List<ChatMessage> messages, {
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    _assertReady();

    try {
      final result = await _channel.invokeMethod<Map>('chatCompletion', {
        'messages': messages.map((m) => m.toJson()).toList(),
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
      });

      if (result == null) {
        throw const AiServiceException('Local model returned null');
      }

      return ChatCompletionResponse(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        object: 'chat.completion',
        created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        model: _modelName ?? 'local',
        choices: [
          ChatChoice(
            index: 0,
            message: ChatMessage.assistant(result['content'] as String? ?? ''),
            finishReason: 'stop',
          ),
        ],
      );
    } on MissingPluginException {
      // Stub: return a placeholder response for development.
      return ChatCompletionResponse(
        id: 'local-stub-${DateTime.now().millisecondsSinceEpoch}',
        object: 'chat.completion',
        created: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        model: 'stub-model',
        choices: [
          ChatChoice(
            index: 0,
            message: ChatMessage.assistant(_stubResponse(messages)),
            finishReason: 'stop',
          ),
        ],
      );
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Local inference failed: $e', originalError: e);
    }
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

  /// Local service is "healthy" when the model is loaded and ready.
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
    // Nothing to close for channel-based service.
  }

  // ── private ───────────────────────────────────────────────────────────────

  void _assertReady() {
    if (_status != LocalModelStatus.ready) {
      throw AiServiceException(
        'Local model not ready (status: ${_status.name})',
      );
    }
  }

  /// Produce a deterministic stub response when the platform channel
  /// isn't connected yet. Helps test the full flow end-to-end.
  String _stubResponse(List<ChatMessage> messages) {
    final userMsg = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => const ChatMessage(role: 'user', content: ''),
    );

    // If the prompt asks for JSON, return valid stub JSON.
    if (userMsg.content.contains('"headline"') ||
        userMsg.content.contains('"summary"')) {
      return '''
{
  "headline": "A quiet day of local reflection",
  "summary": "Running on-device with no network calls. This is a stub response from the local LLM placeholder.",
  "full_body": "— Local Mode —\\nYour body journal is being generated entirely on this device. No data left the phone today.\\n\\n— Placeholder —\\nOnce a real local model is downloaded and activated, this section will contain a rich, data-driven narrative just like the remote version.",
  "mood": "calm",
  "mood_emoji": "🌿",
  "tags": ["local mode", "on-device", "no network"]
}''';
    }

    // If it's a metadata-style prompt, return stub metadata JSON.
    if (userMsg.content.contains('"themes"') ||
        userMsg.content.contains('"energy_level"')) {
      return '''
{
  "summary": "Local stub analysis of this capture moment.",
  "themes": ["on-device", "placeholder"],
  "energy_level": "medium",
  "mood_assessment": "Steady and calm",
  "tags": ["local", "stub"],
  "notable_signals": ["Running in local LLM stub mode"]
}''';
    }

    return 'This is a local LLM stub response. '
        'Download and activate a model in the debug panel to get real on-device inference.';
  }
}
