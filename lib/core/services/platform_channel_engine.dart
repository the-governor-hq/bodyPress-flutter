import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/ai_models.dart';
import 'local_inference_engine.dart';

/// On-device inference engine backed by a [MethodChannel].
///
/// The native side (Kotlin / Swift) must register channel
/// `com.bodypress/local_llm` and implement:
///
/// | Method            | Args                                  | Returns                                                    |
/// |-------------------|---------------------------------------|------------------------------------------------------------|
/// | `resolveBackend`  | —                                     | `String` (`"osNative"` \| `"bundledRuntime"` \| `"none"`)  |
/// | `downloadModel`   | `{modelId, downloadUrl, sha256, …}`   | `Map` `{"modelName": "…", "path": "…"}`                   |
/// | `activateModel`   | `{path: "…"}`                         | `void`                                                     |
/// | `deactivateModel` | —                                     | `void`                                                     |
/// | `deleteModel`     | —                                     | `void`                                                     |
/// | `chatCompletion`  | `{messages, temperature?, maxTokens?}`| `Map` `{"content": "…", "promptTokens": int, …}`          |
///
/// **This class does NOT swallow [MissingPluginException]** — it lets
/// them propagate so the caller can decide policy. The old silent-stub
/// pattern is replaced by explicit [StubInferenceEngine] injection.
class PlatformChannelEngine implements LocalInferenceEngine {
  static const _channel = MethodChannel('com.bodypress/local_llm');

  bool _loaded = false;

  @override
  String get engineName => 'platform-channel';

  @override
  bool get isModelLoaded => _loaded;

  @override
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<String>('resolveBackend');
      return result != null && result != 'none';
    } on MissingPluginException {
      return false;
    } catch (e) {
      debugPrint('[PlatformChannelEngine] isAvailable error: $e');
      return false;
    }
  }

  @override
  Future<void> loadModel(String modelPath) async {
    try {
      await _channel.invokeMethod<void>('activateModel', {'path': modelPath});
      _loaded = true;
      debugPrint('[PlatformChannelEngine] Model loaded: $modelPath');
    } on MissingPluginException {
      // Re-throw — caller must handle (no silent stubs).
      rethrow;
    } catch (e) {
      throw AiServiceException(
        'Failed to load model via platform channel: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod<void>('deactivateModel');
    } on MissingPluginException {
      // No plugin → nothing loaded anyway.
    } catch (e) {
      debugPrint('[PlatformChannelEngine] unloadModel error: $e');
    }
    _loaded = false;
  }

  @override
  Future<InferenceResult> infer(
    List<ChatMessage> messages, {
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_loaded) {
      throw const AiServiceException(
        'Model not loaded in platform-channel engine',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _channel.invokeMethod<Map>('chatCompletion', {
        'messages': messages.map((m) => m.toJson()).toList(),
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxTokens': maxTokens,
      });

      stopwatch.stop();

      if (result == null) {
        throw const AiServiceException('Platform chatCompletion returned null');
      }

      return InferenceResult(
        text: result['content'] as String? ?? '',
        latency: stopwatch.elapsed,
        promptTokens: (result['promptTokens'] as int?) ?? 0,
        completionTokens: (result['completionTokens'] as int?) ?? 0,
        engineName: engineName,
      );
    } on MissingPluginException {
      stopwatch.stop();
      rethrow;
    } catch (e) {
      stopwatch.stop();
      if (e is AiServiceException) rethrow;
      throw AiServiceException(
        'Platform inference failed: $e',
        originalError: e,
      );
    }
  }

  @override
  void dispose() {
    _loaded = false;
  }
}
