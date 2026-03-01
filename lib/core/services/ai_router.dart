import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_mode_config.dart';
import '../models/ai_models.dart';
import 'ai_service.dart';
import 'local_ai_service.dart';

/// Drop-in replacement for [AiService] that routes inference calls to
/// the active backend (remote or local) based on the current [AiMode].
///
/// [JournalAiService] and [CaptureMetadataService] receive this instead of
/// the raw [AiService], so mode-switching is transparent to them.
///
/// ## Timeout behaviour
///
/// Both remote and local inference honour [inferenceTimeout]. The default
/// (120 s) is generous enough for large local models on mid-range devices
/// while still preventing infinite hangs.
class AiRouter {
  final AiService remote;
  final LocalAiService local;

  /// Maximum time to wait for a single inference call before timing out.
  final Duration inferenceTimeout;

  AiMode _mode;

  AiRouter({
    required this.remote,
    required this.local,
    AiMode mode = AiMode.remote,
    this.inferenceTimeout = const Duration(seconds: 120),
  }) : _mode = mode;

  AiMode get mode => _mode;
  set mode(AiMode value) {
    if (_mode != value) {
      debugPrint('[AiRouter] Mode switched: ${_mode.name} → ${value.name}');
    }
    _mode = value;
  }

  bool get isLocalMode => _mode == AiMode.local;

  // ── Inference (same signatures as AiService) ──────────────────────────────

  Future<ChatCompletionResponse> chatCompletion(
    List<ChatMessage> messages, {
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    final future = isLocalMode
        ? local.chatCompletion(
            messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
          )
        : remote.chatCompletion(
            messages,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens,
          );

    return future.timeout(
      inferenceTimeout,
      onTimeout: () => throw AiServiceException(
        'Inference timed out after ${inferenceTimeout.inSeconds}s '
        '(mode: ${_mode.name})',
      ),
    );
  }

  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    final future = isLocalMode
        ? local.ask(
            userPrompt,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          )
        : remote.ask(
            userPrompt,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          );

    return future.timeout(
      inferenceTimeout,
      onTimeout: () => throw AiServiceException(
        'Inference timed out after ${inferenceTimeout.inSeconds}s '
        '(mode: ${_mode.name})',
      ),
    );
  }

  Future<bool> checkHealth() {
    if (isLocalMode) return local.checkHealth();
    return remote.checkHealth();
  }

  void dispose() {
    remote.dispose();
    local.dispose();
  }
}
