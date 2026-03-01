import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_models.dart';
import 'local_inference_engine.dart';

/// Deterministic fake inference engine for testing and development.
///
/// Returns structurally valid responses that match expected JSON schemas
/// so the full pipeline (journal generation, capture metadata, etc.) can be
/// exercised end-to-end without a real model.
///
/// ## Usage
///
/// ```dart
/// // In tests
/// final service = LocalAiService.stub();
///
/// // Or directly
/// final engine = StubInferenceEngine();
/// await engine.loadModel('any-id');
/// final result = await engine.infer([ChatMessage.user('Hello')]);
/// ```
///
/// **Never used in release builds** — guarded by explicit constructor
/// injection in [LocalAiService.stub].
@visibleForTesting
class StubInferenceEngine implements LocalInferenceEngine {
  bool _loaded = false;

  /// Simulated latency added to each [infer] call.
  final Duration simulatedLatency;

  StubInferenceEngine({
    this.simulatedLatency = const Duration(milliseconds: 50),
  });

  @override
  String get engineName => 'stub';

  @override
  bool get isModelLoaded => _loaded;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> loadModel(String modelPath) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    _loaded = true;
    debugPrint('[StubInferenceEngine] Model "loaded" (stub): $modelPath');
  }

  @override
  Future<void> unloadModel() async {
    _loaded = false;
  }

  @override
  Future<InferenceResult> infer(
    List<ChatMessage> messages, {
    double? temperature,
    int? maxTokens,
  }) async {
    if (!_loaded) {
      throw const AiServiceException('Stub model not loaded');
    }

    final stopwatch = Stopwatch()..start();
    await Future<void>.delayed(simulatedLatency);
    final text = _generateResponse(messages);
    stopwatch.stop();

    // Rough token estimate: ~4 chars per token (matches GPT-family averages).
    final promptChars = messages.fold<int>(0, (s, m) => s + m.content.length);

    return InferenceResult(
      text: text,
      latency: stopwatch.elapsed,
      promptTokens: (promptChars / 4).ceil(),
      completionTokens: (text.length / 4).ceil(),
      engineName: engineName,
    );
  }

  @override
  void dispose() {
    _loaded = false;
  }

  // ── Stub response logic ──────────────────────────────────────────────────

  String _generateResponse(List<ChatMessage> messages) {
    final userMsg = messages.lastWhere(
      (m) => m.role == 'user',
      orElse: () => const ChatMessage(role: 'user', content: ''),
    );

    if (_isJournalPrompt(userMsg.content)) return _journalStub;
    if (_isMetadataPrompt(userMsg.content)) return _metadataStub;
    return _defaultStub;
  }

  bool _isJournalPrompt(String content) =>
      content.contains('"headline"') || content.contains('"summary"');

  bool _isMetadataPrompt(String content) =>
      content.contains('"themes"') || content.contains('"energy_level"');

  static const _journalStub =
      '{'
      '"headline": "A quiet day of local reflection", '
      '"summary": "Running on-device — stub response from the local LLM placeholder.", '
      '"full_body": "— Local Mode —\\nYour body journal is generated entirely on this device.\\n\\n'
      '— Placeholder —\\nOnce a real local model is activated, this will contain a rich data-driven narrative.", '
      '"mood": "calm", '
      '"mood_emoji": "🌿", '
      '"tags": ["local mode", "on-device", "stub"]'
      '}';

  static const _metadataStub =
      '{'
      '"summary": "Local stub analysis of this capture moment.", '
      '"themes": ["on-device", "placeholder"], '
      '"energy_level": "medium", '
      '"mood_assessment": "Steady and calm", '
      '"tags": ["local", "stub"], '
      '"notable_signals": ["Running in local LLM stub mode"]'
      '}';

  static const _defaultStub =
      '[Stub] Local LLM placeholder — download and activate a model '
      'for real on-device inference.';
}
