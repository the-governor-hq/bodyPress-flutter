import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_service.dart';

/// Global AI service provider.
///
/// Use this to access the AI service throughout the app:
/// ```dart
/// final ai = ref.read(aiServiceProvider);
/// final response = await ai.ask('Your question here');
/// ```
final aiServiceProvider = Provider<AiService>((ref) {
  final service = AiService();
  ref.onDispose(() => service.dispose());
  return service;
});
