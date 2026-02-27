# AI Service Usage Guide

The AI service is now ready to use! Here's how to integrate it into your Flutter app.

## Quick Start

### 1. Using with Riverpod (Recommended)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bodypress_flutter/core/services/ai_service_provider.dart';
import 'package:bodypress_flutter/core/models/ai_models.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final ai = ref.read(aiServiceProvider);

        // Simple question
        final answer = await ai.ask('What are the benefits of daily exercise?');
        print(answer);
      },
      child: Text('Ask AI'),
    );
  }
}
```

### 2. Direct Service Usage

```dart
import 'package:bodypress_flutter/core/services/ai_service.dart';
import 'package:bodypress_flutter/core/models/ai_models.dart';

Future<void> example() async {
  final ai = AiService();

  // Simple question-answer
  final answer = await ai.ask(
    'Summarize the health benefits of 10,000 steps per day',
    systemPrompt: 'You are a fitness expert. Be concise.',
  );
  print(answer);

  // Advanced: Multi-turn conversation
  final messages = [
    ChatMessage.system('You are a health coach.'),
    ChatMessage.user('I walked 8,500 steps today.'),
    ChatMessage.assistant('Great job! You\'re close to the 10k goal.'),
    ChatMessage.user('What should I aim for tomorrow?'),
  ];

  final response = await ai.chatCompletion(messages);
  print(response.content);

  // Don't forget to dispose when done (if not using provider)
  ai.dispose();
}
```

## Real-World Examples

### Example 1: Summarize Daily Health Data

```dart
Future<String> summarizeHealthData(
  WidgetRef ref,
  int steps,
  double calories,
  double sleepHours,
) async {
  final ai = ref.read(aiServiceProvider);

  final prompt = '''
Today's health metrics:
- Steps: $steps
- Calories burned: ${calories.toStringAsFixed(0)} kcal
- Sleep: ${sleepHours.toStringAsFixed(1)} hours

Provide a brief, encouraging summary in 2-3 sentences.
''';

  try {
    return await ai.ask(
      prompt,
      systemPrompt: 'You are a supportive health coach.',
      temperature: 0.7,
    );
  } catch (e) {
    return 'Unable to generate summary at this time.';
  }
}
```

### Example 2: Generate Workout Suggestions

```dart
Future<String> suggestWorkout(
  WidgetRef ref, {
  required String fitnessLevel,
  required int availableMinutes,
}) async {
  final ai = ref.read(aiServiceProvider);

  final prompt = '''
User profile:
- Fitness level: $fitnessLevel
- Available time: $availableMinutes minutes

Suggest a specific workout routine they can do today.
''';

  return await ai.ask(
    prompt,
    systemPrompt: 'You are a certified personal trainer.',
    maxTokens: 300,
  );
}
```

### Example 3: Health Check

```dart
Future<bool> checkAiAvailability(WidgetRef ref) async {
  final ai = ref.read(aiServiceProvider);
  return await ai.checkHealth();
}
```

## Error Handling

Always wrap AI calls in try-catch blocks:

```dart
try {
  final response = await ai.ask('Your question');
  print(response);
} on AiServiceException catch (e) {
  if (e.statusCode == 401) {
    print('Authentication failed - check API key');
  } else if (e.statusCode == 429) {
    print('Rate limit exceeded - try again later');
  } else {
    print('AI service error: ${e.message}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## Configuration

The service is pre-configured for your setup:

- **Endpoint**: https://ai.governor-hq.com
- **API Key**: Already embedded (can be moved to env vars later)
- **Timeout**: 60 seconds for standard requests

## Testing

To test if the service works, you can add this to any screen:

```dart
ElevatedButton(
  onPressed: () async {
    final ai = ref.read(aiServiceProvider);

    print('Testing AI connection...');
    final isHealthy = await ai.checkHealth();
    print('Health check: ${isHealthy ? "✓" : "✗"}');

    if (isHealthy) {
      final response = await ai.ask('Say hello in one sentence.');
      print('Response: $response');
    }
  },
  child: Text('Test AI'),
)
```

## Next Steps

1. **Integrate into BodyBlogService**: Use AI to generate narrative blog entries from health data
2. **Pattern Recognition**: Ask AI to analyze trends in past health metrics
3. **Personalized Insights**: Generate custom health recommendations based on user data
4. **Natural Language Queries**: Let users ask questions about their health data

## Security Note

The API key is currently hardcoded in the service. For production, consider:

- Moving it to environment variables or secure storage
- Using Flutter's `flutter_dotenv` package
- Never committing keys to version control

## API Reference

See the inline documentation in:

- `lib/core/models/ai_models.dart` - Data models
- `lib/core/services/ai_service.dart` - Service implementation
- `lib/core/services/ai_service_provider.dart` - Riverpod provider
