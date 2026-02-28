import 'package:bodypress_flutter/core/models/ai_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── ChatMessage ──────────────────────────────────────────────────────────

  group('ChatMessage', () {
    test('toJson produces correct map', () {
      const msg = ChatMessage(role: 'user', content: 'Hello');
      expect(msg.toJson(), {'role': 'user', 'content': 'Hello'});
    });

    test('fromJson round-trip', () {
      const original = ChatMessage(role: 'assistant', content: 'Hi there');
      final json = original.toJson();
      final decoded = ChatMessage.fromJson(json);
      expect(decoded.role, original.role);
      expect(decoded.content, original.content);
    });

    test('system factory sets role to system', () {
      final msg = ChatMessage.system('Be helpful');
      expect(msg.role, 'system');
      expect(msg.content, 'Be helpful');
    });

    test('user factory sets role to user', () {
      final msg = ChatMessage.user('What is the weather?');
      expect(msg.role, 'user');
      expect(msg.content, 'What is the weather?');
    });

    test('assistant factory sets role to assistant', () {
      final msg = ChatMessage.assistant('It is sunny');
      expect(msg.role, 'assistant');
      expect(msg.content, 'It is sunny');
    });
  });

  // ─── ChatCompletionRequest ────────────────────────────────────────────────

  group('ChatCompletionRequest', () {
    test('toJson includes messages and stream', () {
      const request = ChatCompletionRequest(
        messages: [ChatMessage(role: 'user', content: 'hi')],
      );
      final json = request.toJson();
      expect(json['stream'], false);
      expect(json['messages'], isA<List>());
      expect((json['messages'] as List).length, 1);
    });

    test('toJson omits optional fields when null', () {
      const request = ChatCompletionRequest(
        messages: [ChatMessage(role: 'user', content: 'hi')],
      );
      final json = request.toJson();
      expect(json.containsKey('model'), false);
      expect(json.containsKey('temperature'), false);
      expect(json.containsKey('max_tokens'), false);
    });

    test('toJson includes optional fields when set', () {
      const request = ChatCompletionRequest(
        messages: [ChatMessage(role: 'user', content: 'hi')],
        model: 'gpt-4',
        temperature: 0.7,
        maxTokens: 100,
        stream: true,
      );
      final json = request.toJson();
      expect(json['model'], 'gpt-4');
      expect(json['temperature'], 0.7);
      expect(json['max_tokens'], 100);
      expect(json['stream'], true);
    });
  });

  // ─── ChatCompletionResponse ───────────────────────────────────────────────

  group('ChatCompletionResponse', () {
    Map<String, dynamic> sampleResponseJson({
      String content = 'Hello!',
      bool includeUsage = true,
    }) {
      return {
        'id': 'chatcmpl-abc123',
        'object': 'chat.completion',
        'created': 1700000000,
        'model': 'gpt-4',
        'choices': [
          {
            'index': 0,
            'message': {'role': 'assistant', 'content': content},
            'finish_reason': 'stop',
          },
        ],
        if (includeUsage)
          'usage': {
            'prompt_tokens': 10,
            'completion_tokens': 5,
            'total_tokens': 15,
          },
      };
    }

    test('fromJson parses all fields', () {
      final response = ChatCompletionResponse.fromJson(sampleResponseJson());
      expect(response.id, 'chatcmpl-abc123');
      expect(response.object, 'chat.completion');
      expect(response.created, 1700000000);
      expect(response.model, 'gpt-4');
      expect(response.choices.length, 1);
      expect(response.usage, isNotNull);
      expect(response.usage!.totalTokens, 15);
    });

    test('content getter returns first choice content', () {
      final response = ChatCompletionResponse.fromJson(
        sampleResponseJson(content: 'World'),
      );
      expect(response.content, 'World');
    });

    test('content getter returns empty string when choices empty', () {
      final json = sampleResponseJson();
      json['choices'] = [];
      final response = ChatCompletionResponse.fromJson(json);
      expect(response.content, '');
    });

    test('fromJson handles null usage', () {
      final response = ChatCompletionResponse.fromJson(
        sampleResponseJson(includeUsage: false),
      );
      expect(response.usage, isNull);
    });
  });

  // ─── ChatChoice ───────────────────────────────────────────────────────────

  group('ChatChoice', () {
    test('fromJson parses all fields', () {
      final choice = ChatChoice.fromJson({
        'index': 0,
        'message': {'role': 'assistant', 'content': 'Reply'},
        'finish_reason': 'stop',
      });
      expect(choice.index, 0);
      expect(choice.message.role, 'assistant');
      expect(choice.message.content, 'Reply');
      expect(choice.finishReason, 'stop');
    });

    test('fromJson handles null finish_reason', () {
      final choice = ChatChoice.fromJson({
        'index': 1,
        'message': {'role': 'assistant', 'content': 'x'},
      });
      expect(choice.finishReason, isNull);
    });
  });

  // ─── ChatUsage ────────────────────────────────────────────────────────────

  group('ChatUsage', () {
    test('fromJson parses token counts', () {
      final usage = ChatUsage.fromJson({
        'prompt_tokens': 42,
        'completion_tokens': 13,
        'total_tokens': 55,
      });
      expect(usage.promptTokens, 42);
      expect(usage.completionTokens, 13);
      expect(usage.totalTokens, 55);
    });
  });

  // ─── AiServiceException ───────────────────────────────────────────────────

  group('AiServiceException', () {
    test('toString includes message only when no statusCode', () {
      const e = AiServiceException('Something went wrong');
      expect(e.toString(), 'AiServiceException: Something went wrong');
    });

    test('toString includes HTTP status when provided', () {
      const e = AiServiceException('Unauthorized', statusCode: 401);
      expect(e.toString(), 'AiServiceException: Unauthorized (HTTP 401)');
    });

    test('originalError is stored', () {
      final original = FormatException('bad format');
      final e = AiServiceException('parse error', originalError: original);
      expect(e.originalError, original);
    });
  });
}
