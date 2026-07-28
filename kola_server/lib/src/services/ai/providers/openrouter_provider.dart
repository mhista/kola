// openrouter_provider.dart
//
// OpenRouter's OpenAI-compatible chat completions API, pinned to a free
// model — ported from copycat/kopicat_server's lib/ai.dart. Last resort
// in AiOrchestrator's priority order: OpenRouter's free-model tier is
// the least capable of the three, but it's a real safety net if both
// Groq and Gemini are unavailable or out of quota at the same moment.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

class OpenRouterProvider implements AiProvider {
  OpenRouterProvider({required this.apiKey});

  final String apiKey;

  static const _model = 'mistralai/mistral-7b-instruct:free';

  @override
  String get name => 'openrouter';

  @override
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    final res = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
        // Required by OpenRouter's free tier to identify the calling
        // app — kept as the same value copycat/kopicat already used.
        'http-referer': 'https://kopicat.app',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': maxTokens,
      }),
    );

    if (res.statusCode == 429) throw const AiQuotaExceededException('openrouter');
    if (res.statusCode != 200) {
      throw Exception('OpenRouter error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['choices'] as List).first['message']['content'] as String;
  }

  // TASK #134 — same OpenAI-compatible `tools`/`tool_calls` shape as
  // GroqProvider's own addition; see that file for the full reasoning.
  // OpenRouter's free-model tier is the least capable of the three (see
  // this file's header), so tool-calling here is the last resort, not
  // the primary path — AiOrchestrator's cascade already reflects that.
  @override
  Future<AiToolCompletionResult> completeWithTools({
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    int maxTokens = 1024,
  }) async {
    final res = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $apiKey',
        'http-referer': 'https://kopicat.app',
      },
      body: jsonEncode({
        'model': _model,
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

    if (res.statusCode == 429) throw const AiQuotaExceededException('openrouter');
    if (res.statusCode != 200) {
      throw Exception('OpenRouter error ${res.statusCode}: ${res.body}');
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
