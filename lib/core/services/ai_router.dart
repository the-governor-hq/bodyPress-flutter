import 'dart:async';

import '../models/ai_mode_config.dart';
import '../models/ai_models.dart';
import 'ai_service.dart';
import 'local_ai_service.dart';

/// Drop-in replacement for [AiService] that routes inference calls to
/// the active backend (remote or local) based on the current [AiMode].
///
/// [JournalAiService] and [CaptureMetadataService] receive this instead of
/// the raw [AiService], so mode-switching is transparent to them.
class AiRouter {
  final AiService remote;
  final LocalAiService local;

  AiMode _mode;

  AiRouter({
    required this.remote,
    required this.local,
    AiMode mode = AiMode.remote,
  }) : _mode = mode;

  AiMode get mode => _mode;
  set mode(AiMode value) => _mode = value;
  bool get isLocalMode => _mode == AiMode.local;

  // ── Inference (same signatures as AiService) ──────────────────────────────

  Future<ChatCompletionResponse> chatCompletion(
    List<ChatMessage> messages, {
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    if (isLocalMode) {
      return local.chatCompletion(
        messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
    return remote.chatCompletion(
      messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    if (isLocalMode) {
      return local.ask(
        userPrompt,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );
    }
    return remote.ask(
      userPrompt,
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
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
