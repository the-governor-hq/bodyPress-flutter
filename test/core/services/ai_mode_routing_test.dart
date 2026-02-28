import 'package:bodypress_flutter/core/models/ai_mode_config.dart';
import 'package:bodypress_flutter/core/models/ai_models.dart';
import 'package:bodypress_flutter/core/services/ai_router.dart';
import 'package:bodypress_flutter/core/services/ai_service.dart';
import 'package:bodypress_flutter/core/services/local_ai_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeRemote extends AiService {
  int askCount = 0;
  String response = 'remote-response';

  _FakeRemote()
    : super(client: MockClient((_) async => http.Response('{}', 200)));

  @override
  Future<String> ask(
    String userPrompt, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) async {
    askCount++;
    return response;
  }

  @override
  Future<bool> checkHealth() async => true;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Register a stub handler so the platform channel falls through to
  // MissingPluginException, which LocalAiService handles gracefully.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.bodypress/local_llm'),
          null, // null → throws MissingPluginException for every method
        );
  });
  group('AiModeConfig', () {
    test('defaults to remote mode', () {
      const cfg = AiModeConfig();
      expect(cfg.mode, AiMode.remote);
      expect(cfg.isLocalMode, isFalse);
      expect(cfg.isLocalReady, isFalse);
    });

    test('isLocalReady requires local mode + ready status', () {
      const cfg = AiModeConfig(
        mode: AiMode.local,
        modelStatus: LocalModelStatus.ready,
      );
      expect(cfg.isLocalReady, isTrue);
    });

    test('isLocalReady false when model not ready', () {
      const cfg = AiModeConfig(
        mode: AiMode.local,
        modelStatus: LocalModelStatus.downloaded,
      );
      expect(cfg.isLocalReady, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const original = AiModeConfig(
        mode: AiMode.local,
        modelStatus: LocalModelStatus.ready,
        modelName: 'test-model',
      );
      final updated = original.copyWith(downloadProgress: 0.5);
      expect(updated.mode, AiMode.local);
      expect(updated.modelStatus, LocalModelStatus.ready);
      expect(updated.modelName, 'test-model');
      expect(updated.downloadProgress, 0.5);
    });
  });

  group('AiRouter', () {
    late _FakeRemote fakeRemote;
    late LocalAiService localService;
    late AiRouter router;

    setUp(() {
      fakeRemote = _FakeRemote();
      localService = LocalAiService();
      router = AiRouter(remote: fakeRemote, local: localService);
    });

    test('defaults to remote mode', () {
      expect(router.mode, AiMode.remote);
      expect(router.isLocalMode, isFalse);
    });

    test('routes ask() to remote in remote mode', () async {
      final result = await router.ask('Hello');
      expect(result, 'remote-response');
      expect(fakeRemote.askCount, 1);
    });

    test('routes ask() to local in local mode (stub)', () async {
      // Activate local stub model first.
      await localService.downloadModel();
      await localService.activateModel();
      router.mode = AiMode.local;

      final result = await router.ask('Hello');
      expect(result, isNotEmpty);
      expect(fakeRemote.askCount, 0, reason: 'remote should NOT be called');
    });

    test('local mode throws when model not ready (hard fail)', () async {
      router.mode = AiMode.local;
      expect(() => router.ask('Hello'), throwsA(isA<AiServiceException>()));
      expect(
        fakeRemote.askCount,
        0,
        reason: 'remote must NOT be called as fallback',
      );
    });

    test('switching mode changes routing', () async {
      // Start remote.
      await router.ask('test1');
      expect(fakeRemote.askCount, 1);

      // Switch to local (with stub model).
      await localService.downloadModel();
      await localService.activateModel();
      router.mode = AiMode.local;

      final localResult = await router.ask('test2');
      expect(localResult, isNotEmpty);
      expect(
        fakeRemote.askCount,
        1,
        reason: 'remote count should not increase',
      );

      // Switch back.
      router.mode = AiMode.remote;
      await router.ask('test3');
      expect(fakeRemote.askCount, 2);
    });

    test('checkHealth routes to correct backend', () async {
      expect(await router.checkHealth(), isTrue); // remote healthy

      router.mode = AiMode.local;
      // Model not ready, so local health is false.
      expect(await router.checkHealth(), isFalse);

      // Make model ready.
      await localService.downloadModel();
      await localService.activateModel();
      expect(await router.checkHealth(), isTrue);
    });
  });

  group('LocalAiService', () {
    late LocalAiService local;

    setUp(() {
      local = LocalAiService();
    });

    test('initial status is notDownloaded', () {
      expect(local.status, LocalModelStatus.notDownloaded);
      expect(local.modelName, isNull);
    });

    test('download transitions to downloaded (stub)', () async {
      final progressValues = <double>[];
      final status = await local.downloadModel(onProgress: progressValues.add);
      expect(status, LocalModelStatus.downloaded);
      expect(local.modelName, isNotNull);
      expect(progressValues, contains(1.0));
    });

    test('activate transitions to ready', () async {
      await local.downloadModel();
      final status = await local.activateModel();
      expect(status, LocalModelStatus.ready);
    });

    test('activate fails when not downloaded', () async {
      final status = await local.activateModel();
      expect(status, LocalModelStatus.notDownloaded);
      expect(local.lastError, isNotNull);
    });

    test('ask works when model is ready (stub)', () async {
      await local.downloadModel();
      await local.activateModel();

      final response = await local.ask('Hello fitness!');
      expect(response, isNotEmpty);
    });

    test('ask throws when model not ready', () async {
      expect(() => local.ask('Hello'), throwsA(isA<AiServiceException>()));
    });

    test('deactivate goes back to downloaded', () async {
      await local.downloadModel();
      await local.activateModel();
      await local.deactivateModel();
      expect(local.status, LocalModelStatus.downloaded);
    });

    test('delete resets everything', () async {
      await local.downloadModel();
      await local.activateModel();
      await local.deleteModel();
      expect(local.status, LocalModelStatus.notDownloaded);
      expect(local.modelName, isNull);
    });

    test('checkHealth reflects model readiness', () async {
      expect(await local.checkHealth(), isFalse);
      await local.downloadModel();
      expect(await local.checkHealth(), isFalse);
      await local.activateModel();
      expect(await local.checkHealth(), isTrue);
    });

    test('toConfig returns correct snapshot', () async {
      await local.downloadModel();
      await local.activateModel();
      final cfg = local.toConfig(AiMode.local);

      expect(cfg.mode, AiMode.local);
      expect(cfg.modelStatus, LocalModelStatus.ready);
      expect(cfg.modelName, isNotNull);
    });

    test('stub response returns valid JSON for journal prompt', () async {
      await local.downloadModel();
      await local.activateModel();

      final response = await local.ask(
        'Generate journal for today.\n"headline": "..."',
        systemPrompt: 'You are a journal writer.',
      );
      // Should contain JSON-like content.
      expect(response, contains('headline'));
    });

    test('stub response returns valid JSON for metadata prompt', () async {
      await local.downloadModel();
      await local.activateModel();

      final response = await local.ask(
        'Analyse this capture.\n"themes": ["..."]\n"energy_level": "..."',
      );
      expect(response, contains('themes'));
    });
  });
}
