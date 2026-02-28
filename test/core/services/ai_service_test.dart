import 'dart:async';
import 'dart:convert';

import 'package:bodypress_flutter/core/models/ai_models.dart';
import 'package:bodypress_flutter/core/services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    // Initialise dotenv with a test key so AiService._apiKey doesn't throw.
    // flutter_dotenv 6.x uses loadFromString instead of testLoad.
    dotenv.loadFromString(envString: 'AI_API_KEY=test-key');
  });
  // ─── chatCompletion ───────────────────────────────────────────────────────

  group('AiService.chatCompletion', () {
    Map<String, dynamic> successResponseBody() => {
      'id': 'chatcmpl-123',
      'object': 'chat.completion',
      'created': 1700000000,
      'model': 'gpt-4',
      'choices': [
        {
          'index': 0,
          'message': {'role': 'assistant', 'content': 'Hello!'},
          'finish_reason': 'stop',
        },
      ],
      'usage': {'prompt_tokens': 5, 'completion_tokens': 3, 'total_tokens': 8},
    };

    test('returns ChatCompletionResponse on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/chat/completions');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.headers['Authorization'], startsWith('Bearer '));
        return http.Response(jsonEncode(successResponseBody()), 200);
      });

      final service = AiService(client: client);
      final response = await service.chatCompletion([ChatMessage.user('Hi')]);

      expect(response.id, 'chatcmpl-123');
      expect(response.content, 'Hello!');
      expect(response.usage!.totalTokens, 8);
    });

    test('throws AiServiceException on HTTP error with JSON body', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Rate limit exceeded'},
          }),
          429,
        );
      });

      final service = AiService(client: client);
      expect(
        () => service.chatCompletion([ChatMessage.user('Hi')]),
        throwsA(
          isA<AiServiceException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', 'Rate limit exceeded'),
        ),
      );
    });

    test('throws AiServiceException on HTTP error with plain body', () async {
      final client = MockClient((_) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = AiService(client: client);
      expect(
        () => service.chatCompletion([ChatMessage.user('Hi')]),
        throwsA(
          isA<AiServiceException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Internal Server Error'),
        ),
      );
    });

    test('throws AiServiceException on HTTP error with empty body', () async {
      final client = MockClient((_) async {
        return http.Response('', 502);
      });

      final service = AiService(client: client);
      expect(
        () => service.chatCompletion([ChatMessage.user('Hi')]),
        throwsA(
          isA<AiServiceException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.message, 'message', 'HTTP 502'),
        ),
      );
    });

    test('throws AiServiceException on timeout', () async {
      final client = MockClient((_) async {
        throw TimeoutException('Timed out');
      });

      final service = AiService(client: client);
      expect(
        () => service.chatCompletion([ChatMessage.user('Hi')]),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            'Request timed out',
          ),
        ),
      );
    });

    test('throws AiServiceException on network error', () async {
      final client = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });

      final service = AiService(client: client);
      expect(
        () => service.chatCompletion([ChatMessage.user('Hi')]),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            contains('Network error'),
          ),
        ),
      );
    });

    test('includes optional parameters in request body', () async {
      late Map<String, dynamic> sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(successResponseBody()), 200);
      });

      final service = AiService(client: client);
      await service.chatCompletion(
        [ChatMessage.user('Hi')],
        model: 'gpt-4-turbo',
        temperature: 0.5,
        maxTokens: 200,
      );

      expect(sentBody['model'], 'gpt-4-turbo');
      expect(sentBody['temperature'], 0.5);
      expect(sentBody['max_tokens'], 200);
      expect(sentBody['stream'], false);
    });
  });

  // ─── ask ──────────────────────────────────────────────────────────────────

  group('AiService.ask', () {
    test('returns content string from a single prompt', () async {
      late Map<String, dynamic> sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'x',
            'object': 'chat.completion',
            'created': 1,
            'model': 'test',
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': 'Answer'},
                'finish_reason': 'stop',
              },
            ],
          }),
          200,
        );
      });

      final service = AiService(client: client);
      final result = await service.ask('Question?');

      expect(result, 'Answer');
      final messages = sentBody['messages'] as List;
      expect(messages.length, 1);
      expect(messages.first['role'], 'user');
    });

    test('prepends system prompt when provided', () async {
      late Map<String, dynamic> sentBody;
      final client = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'x',
            'object': 'chat.completion',
            'created': 1,
            'model': 'test',
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': 'OK'},
                'finish_reason': 'stop',
              },
            ],
          }),
          200,
        );
      });

      final service = AiService(client: client);
      await service.ask('Q', systemPrompt: 'Be concise');

      final messages = sentBody['messages'] as List;
      expect(messages.length, 2);
      expect(messages[0]['role'], 'system');
      expect(messages[0]['content'], 'Be concise');
      expect(messages[1]['role'], 'user');
    });
  });

  // ─── checkHealth ──────────────────────────────────────────────────────────

  group('AiService.checkHealth', () {
    test('returns true on 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/health');
        return http.Response('OK', 200);
      });

      final service = AiService(client: client);
      expect(await service.checkHealth(), true);
    });

    test('returns false on non-200', () async {
      final client = MockClient((_) async => http.Response('', 500));
      final service = AiService(client: client);
      expect(await service.checkHealth(), false);
    });

    test('returns false on exception', () async {
      final client = MockClient((_) async {
        throw http.ClientException('Network error');
      });
      final service = AiService(client: client);
      expect(await service.checkHealth(), false);
    });
  });
}
