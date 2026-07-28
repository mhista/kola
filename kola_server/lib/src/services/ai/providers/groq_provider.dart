// groq_provider.dart
//
// Groq's OpenAI-compatible chat completions API — ported from
// copycat/kopicat_server's lib/ai.dart, same model list and same
// "try the strong model, fall back to the fast one on failure" shape.
// Kola's default/first-tried provider (see ai_orchestrator.dart) purely
// for cost: Groq's free tier is fast and generous, so it's the right
// default while cost efficiency matters more than model choice — see
// AiOrchestrator's header for why this is trivially swappable later.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

class GroqProvider implements AiProvider {
  GroqProvider({required this.apiKey});

  final String apiKey;

  /// llama-3.3-70b-versatile — best quality, tried first.
  /// llama-3.1-8b-instant    — faster fallback within Groq alone, tried
  /// only if the first model's call fails for any reason.
  static const _models = ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'];

  @override
  String get name => 'groq';

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        return await _call(
          model: model,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          maxTokens: maxTokens,
        );
      } catch (e) {
        lastError = e;
        // Try the next model in this provider's own list before giving
        // up on Groq entirely.
      }
    }
    throw Exception('Groq: all models failed. Last error: $lastError');
  }

  Future<String> _call({
    required String model,
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': maxTokens,
      }),
    );

    if (res.statusCode == 429) throw const AiQuotaExceededException('groq');
    if (res.statusCode != 200) {
      throw Exception('Groq error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['choices'] as List).first['message']['content'] as String;
  }

  // TASK #134 — same OpenAI-compatible endpoint, with a `tools` array
  // added to the request body and `tool_calls` parsed out of the
  // response. Reuses [_models]' own strong→fast fallback exactly like
  // [complete] does — a tool-calling request degrading to the faster
  // model on failure is the same "degrade before going silent" instinct
  // as ai_orchestrator.dart's own provider cascade, just one level down.
  @override
  Future<AiToolCompletionResult> completeWithTools({
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    int maxTokens = 1024,
  }) async {
    Object? lastError;
    for (final model in _models) {
      try {
        return await _callWithTools(
          model: model,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          tools: tools,
          maxTokens: maxTokens,
        );
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Groq: all models failed (tool-calling). Last error: $lastError');
  }

  Future<AiToolCompletionResult> _callWithTools({
    required String model,
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    required int maxTokens,
  }) async {
    final res = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': maxTokens,
        'tools': tools
            .map((t) => {
                  'type': 'function',
                  'function': {
                    'name': t.name,
                    'description': t.description,
                    'parameters': t.parametersSchema,
                  },
                })
            .toList(),
      }),
    );

    if (res.statusCode == 429) throw const AiQuotaExceededException('groq');
    if (res.statusCode != 200) {
      throw Exception('Groq error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final message = (data['choices'] as List).first['message'] as Map<String, dynamic>;
    final toolCalls = message['tool_calls'] as List?;
    if (toolCalls != null && toolCalls.isNotEmpty) {
      final call = (toolCalls.first as Map<String, dynamic>)['function'] as Map<String, dynamic>;
      final rawArgs = call['arguments'] as String? ?? '{}';
      Map<String, dynamic> arguments;
      try {
        arguments = jsonDecode(rawArgs) as Map<String, dynamic>;
      } catch (_) {
        arguments = <String, dynamic>{};
      }
      return AiToolCompletionResult(
        toolCall: AiToolCall(toolName: call['name'] as String, arguments: arguments),
      );
    }
    return AiToolCompletionResult(text: message['content'] as String? ?? '');
  }
}
