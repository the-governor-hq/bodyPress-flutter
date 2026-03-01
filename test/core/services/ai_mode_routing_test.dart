import 'package:bodypress_flutter/core/models/ai_mode_config.dart';
import 'package:bodypress_flutter/core/models/ai_models.dart';
import 'package:bodypress_flutter/core/models/local_model_spec.dart';
import 'package:bodypress_flutter/core/services/ai_router.dart';
import 'package:bodypress_flutter/core/services/ai_service.dart';
import 'package:bodypress_flutter/core/services/local_ai_service.dart';
import 'package:bodypress_flutter/core/services/local_inference_engine.dart';
import 'package:bodypress_flutter/core/services/stub_inference_engine.dart';
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

  group('LocalInferenceEngine contract (StubInferenceEngine)', () {
    late StubInferenceEngine engine;

    setUp(() {
      engine = StubInferenceEngine(simulatedLatency: Duration.zero);
    });

    test('engine name is "stub"', () {
      expect(engine.engineName, 'stub');
    });

    test('is always "available"', () async {
      expect(await engine.isAvailable(), isTrue);
    });

    test('model not loaded initially', () {
      expect(engine.isModelLoaded, isFalse);
    });

    test('loadModel transitions to loaded', () async {
      await engine.loadModel('test-model');
      expect(engine.isModelLoaded, isTrue);
    });

    test('unloadModel transitions to not loaded', () async {
      await engine.loadModel('test-model');
      await engine.unloadModel();
      expect(engine.isModelLoaded, isFalse);
    });

    test('infer throws when model not loaded', () {
      expect(
        () => engine.infer([ChatMessage.user('Hello')]),
        throwsA(isA<AiServiceException>()),
      );
    });

    test('infer returns InferenceResult with metadata', () async {
      await engine.loadModel('test-model');
      final result = await engine.infer([ChatMessage.user('Hello')]);
      expect(result.text, isNotEmpty);
      expect(result.engineName, 'stub');
      expect(result.latency, greaterThanOrEqualTo(Duration.zero));
      expect(result.promptTokens, greaterThan(0));
      expect(result.completionTokens, greaterThan(0));
    });

    test('infer returns valid journal JSON for journal prompt', () async {
      await engine.loadModel('test-model');
      final result = await engine.infer([
        ChatMessage.user('Generate journal.\n"headline": "..."'),
      ]);
      expect(result.text, contains('"headline"'));
    });

    test('infer returns valid metadata JSON for metadata prompt', () async {
      await engine.loadModel('test-model');
      final result = await engine.infer([
        ChatMessage.user(
          'Analyse capture.\n"themes": ["..."]\n"energy_level": "..."',
        ),
      ]);
      expect(result.text, contains('"themes"'));
    });
  });

  group('InferenceResult', () {
    test('tokensPerSecond computation', () {
      const result = InferenceResult(
        text: 'hello world',
        latency: Duration(seconds: 1),
        promptTokens: 10,
        completionTokens: 100,
        engineName: 'test',
      );
      expect(result.tokensPerSecond, closeTo(100.0, 0.1));
    });

    test('tokensPerSecond is 0 for zero latency', () {
      const result = InferenceResult(
        text: 'hello',
        latency: Duration.zero,
        promptTokens: 0,
        completionTokens: 0,
        engineName: 'test',
      );
      expect(result.tokensPerSecond, 0.0);
    });
  });

  group('LocalModelSpec / Registry', () {
    test('registry contains at least one model', () {
      expect(LocalModelRegistry.all, isNotEmpty);
    });

    test('default model is in the registry', () {
      expect(
        LocalModelRegistry.all.contains(LocalModelRegistry.defaultModel),
        isTrue,
      );
    });

    test('byId finds known model', () {
      final model = LocalModelRegistry.byId('gemma-2b-it-q4_0');
      expect(model, isNotNull);
      expect(model!.family, 'gemma');
    });

    test('byId returns null for unknown model', () {
      expect(LocalModelRegistry.byId('nonexistent'), isNull);
    });

    test('fileSizeDisplay formats correctly', () {
      expect(LocalModelRegistry.gemma2b_q4.fileSizeDisplay, contains('GB'));
      expect(LocalModelRegistry.smolLM2_360m.fileSizeDisplay, contains('MB'));
    });

    test('models ordered smallest first', () {
      for (int i = 1; i < LocalModelRegistry.all.length; i++) {
        expect(
          LocalModelRegistry.all[i].fileSizeBytes,
          greaterThanOrEqualTo(LocalModelRegistry.all[i - 1].fileSizeBytes),
        );
      }
    });
  });

  group('LocalAiService (with stub engine)', () {
    late LocalAiService local;

    setUp(() {
      local = LocalAiService.stub();
    });

    test('initial status is notDownloaded', () {
      expect(local.status, LocalModelStatus.notDownloaded);
      expect(local.modelName, isNull);
      expect(local.engineName, 'stub');
    });

    test('resolveBackend detects stub as available', () async {
      final backend = await local.resolveBackend();
      expect(backend, LocalModelBackend.bundledRuntime);
    });

    test('download transitions to downloaded with progress', () async {
      final progressValues = <double>[];
      final status = await local.downloadModel(onProgress: progressValues.add);
      expect(status, LocalModelStatus.downloaded);
      expect(local.modelName, isNotNull);
      expect(progressValues, contains(1.0));
      expect(progressValues.first, lessThanOrEqualTo(progressValues.last));
    });

    test('download uses specified model spec', () async {
      await local.downloadModel(spec: LocalModelRegistry.gemma2b_q4);
      expect(local.modelName, 'gemma-2b-it-q4_0');
      expect(local.modelSpec, isNotNull);
      expect(local.modelSpec!.family, 'gemma');
    });

    test('download defaults to registry default model', () async {
      await local.downloadModel();
      expect(local.modelName, LocalModelRegistry.defaultModel.id);
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

    test('ask works when model is ready', () async {
      await local.downloadModel();
      await local.activateModel();
      final response = await local.ask('Hello fitness!');
      expect(response, isNotEmpty);
    });

    test('ask throws when model not ready', () {
      expect(() => local.ask('Hello'), throwsA(isA<AiServiceException>()));
    });

    test('chatCompletion returns usage stats', () async {
      await local.downloadModel();
      await local.activateModel();
      final response = await local.chatCompletion([ChatMessage.user('Hello!')]);
      expect(response.usage, isNotNull);
      expect(response.usage!.totalTokens, greaterThan(0));
      expect(response.model, contains(local.modelName!));
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
      expect(local.modelSpec, isNull);
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

    test('stub returns valid JSON for journal prompt', () async {
      await local.downloadModel();
      await local.activateModel();
      final response = await local.ask(
        'Generate journal for today.\n"headline": "..."',
        systemPrompt: 'You are a journal writer.',
      );
      expect(response, contains('headline'));
    });

    test('stub returns valid JSON for metadata prompt', () async {
      await local.downloadModel();
      await local.activateModel();
      final response = await local.ask(
        'Analyse this capture.\n"themes": ["..."]\n"energy_level": "..."',
      );
      expect(response, contains('themes'));
    });
  });

  group('AiRouter', () {
    late _FakeRemote fakeRemote;
    late LocalAiService localService;
    late AiRouter router;

    setUp(() {
      fakeRemote = _FakeRemote();
      localService = LocalAiService.stub();
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

    test('routes ask() to local in local mode', () async {
      await localService.downloadModel();
      await localService.activateModel();
      router.mode = AiMode.local;

      final result = await router.ask('Hello');
      expect(result, isNotEmpty);
      expect(fakeRemote.askCount, 0, reason: 'remote must NOT be called');
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

      // Switch to local.
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
}
