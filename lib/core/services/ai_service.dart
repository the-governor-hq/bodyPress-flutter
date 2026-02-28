import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ai_models.dart';

/// Service for interacting with the LLM gateway at ai.governor-hq.com
///
/// This service provides access to OpenAI-compatible chat completions
/// through a self-hosted gateway that abstracts the underlying LLM provider.
///
/// Example usage:
/// ```dart
/// final service = AiService();
/// final response = await service.chatCompletion([
///   ChatMessage.user('Summarize this health data...'),
/// ]);
/// print(response.content);
/// ```
class AiService {
  static const String _baseUrl = 'https://ai.governor-hq.com';

  /// API key injected at build time via `--dart-define=AI_API_KEY=...`
  static const String _apiKey = String.fromEnvironment('AI_API_KEY');

  final http.Client _client;

  AiService({http.Client? client}) : _client = client ?? http.Client();

  /// Send a chat completion request with the given messages.
  ///
  /// Returns the full [ChatCompletionResponse] from the API.
  /// Throws [AiServiceException] on failure.
  Future<ChatCompletionResponse> chatCompletion(
    List<ChatMessage> messages, {
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    final request = ChatCompletionRequest(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      stream: false,
    );

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatCompletionResponse.fromJson(data);
      } else {
        // Try to extract error message from response body
        String errorMsg = 'Request failed';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          errorMsg = errorData['error']?['message'] ?? errorMsg;
        } catch (_) {
          errorMsg = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}';
        }

        throw AiServiceException(errorMsg, statusCode: response.statusCode);
      }
    } on TimeoutException {
      throw const AiServiceException('Request timed out');
    } on http.ClientException catch (e) {
      throw AiServiceException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Unexpected error: $e', originalError: e);
    }
  }

  /// Simplified method to get a quick AI response from a single user prompt.
  ///
  /// Optionally include a system prompt to set behavior/context.
  ///
  /// Example:
  /// ```dart
  /// final answer = await service.ask(
  ///   'What are the health benefits of walking 10k steps?',
  ///   systemPrompt: 'You are a fitness expert.',
  /// );
  /// print(answer);
  /// ```
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

  /// Check if the AI service is available.
  ///
  /// Makes a lightweight request to the /health endpoint.
  /// Returns `true` if the service is reachable, `false` otherwise.
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Clean up resources.
  void dispose() {
    _client.close();
  }
}
