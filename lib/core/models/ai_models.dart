/// Models for AI/LLM API interactions.
///
/// These models conform to the OpenAI-compatible chat completions format
/// used by the llm-api gateway at https://ai.governor-hq.com
library;

/// A message in a chat conversation.
class ChatMessage {
  final String role; // "system", "user", "assistant"
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(role: 'system', content: content);
  }

  factory ChatMessage.user(String content) {
    return ChatMessage(role: 'user', content: content);
  }

  factory ChatMessage.assistant(String content) {
    return ChatMessage(role: 'assistant', content: content);
  }
}

/// Request payload for chat completions endpoint.
class ChatCompletionRequest {
  final List<ChatMessage> messages;
  final String? model; // Optional - gateway has default
  final double? temperature;
  final int? maxTokens;
  final bool stream;

  const ChatCompletionRequest({
    required this.messages,
    this.model,
    this.temperature,
    this.maxTokens,
    this.stream = false,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
      'stream': stream,
    };
    if (model != null) json['model'] = model;
    if (temperature != null) json['temperature'] = temperature;
    if (maxTokens != null) json['max_tokens'] = maxTokens;
    return json;
  }
}

/// Response from chat completions endpoint.
class ChatCompletionResponse {
  final String id;
  final String object;
  final int created;
  final String model;
  final List<ChatChoice> choices;
  final ChatUsage? usage;

  const ChatCompletionResponse({
    required this.id,
    required this.object,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    return ChatCompletionResponse(
      id: json['id'] as String,
      object: json['object'] as String,
      created: json['created'] as int,
      model: json['model'] as String,
      choices: (json['choices'] as List)
          .map((c) => ChatChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? ChatUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Get the first assistant message content, or empty string if none.
  String get content {
    if (choices.isEmpty) return '';
    return choices[0].message.content;
  }
}

/// A single choice in the response.
class ChatChoice {
  final int index;
  final ChatMessage message;
  final String? finishReason;

  const ChatChoice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory ChatChoice.fromJson(Map<String, dynamic> json) {
    return ChatChoice(
      index: json['index'] as int,
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

/// Token usage statistics.
class ChatUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const ChatUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory ChatUsage.fromJson(Map<String, dynamic> json) {
    return ChatUsage(
      promptTokens: json['prompt_tokens'] as int,
      completionTokens: json['completion_tokens'] as int,
      totalTokens: json['total_tokens'] as int,
    );
  }
}

/// Exception thrown when AI service fails.
class AiServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const AiServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() {
    if (statusCode != null) {
      return 'AiServiceException: $message (HTTP $statusCode)';
    }
    return 'AiServiceException: $message';
  }
}
