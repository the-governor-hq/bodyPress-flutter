import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_router.dart';
import '../services/ai_service.dart';
import '../services/local_ai_service.dart';

/// Global AI router provider.
///
/// Replaces the old `aiServiceProvider` — callers get an [AiRouter] that
/// routes to remote or local depending on the active [AiMode].
///
/// ```dart
/// final ai = ref.read(aiRouterProvider);
/// final response = await ai.ask('Your question here');
/// ```
final aiRouterProvider = Provider<AiRouter>((ref) {
  final router = AiRouter(remote: AiService(), local: LocalAiService());
  ref.onDispose(() => router.dispose());
  return router;
});

/// Legacy alias — kept for backward-compatibility in existing code that
/// only needs the remote [AiService] directly (e.g. debug health check).
final aiServiceProvider = Provider<AiService>((ref) {
  return ref.read(aiRouterProvider).remote;
});
