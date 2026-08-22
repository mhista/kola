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
import 'package:kola_server/kola_logger.dart';
import '../ai_provider.dart';

class GroqProvider implements AiProvider {
  GroqProvider({required this.apiKey, String? secondaryApiKey})
      : _keys = [
          if (apiKey.isNotEmpty) apiKey,
          if (secondaryApiKey != null && secondaryApiKey.isNotEmpty) secondaryApiKey,
        ];

  final String apiKey;

  /// GROQ_API_KEY, then (if set) GROQ_API_KEY_2 — a second Groq account's
  /// key, tried ONLY after every model has failed on the first key. This
  /// exists because Groq's free-tier quota is shared across every model
  /// under one account: a 429 on gpt-oss-120b almost always means
  /// gpt-oss-20b will 429 too, since they're the same account hitting the
  /// same cap. A second, separate account's key is real headroom in a way
  /// a second model on the SAME key is not. If GROQ_API_KEY_2 is unset,
  /// [_keys] just holds one entry and this behaves exactly as before this
  /// field existed.
  final List<String> _keys;

  /// ── BOTH PREVIOUS MODELS WERE RETIRED FROM GROQ'S CATALOG ─────────
  ///
  /// This listed llama-3.3-70b-versatile and llama-3.1-8b-instant.
  /// Neither appears in Groq's Production, Production Systems, or
  /// Preview tables anymore (checked https://console.groq.com/docs/models
  /// directly, 2026-08-22) — Groq has moved its hosted Llama 3.x lineup
  /// out entirely. Every call through this provider was failing with
  /// 404 model_not_found, and because the per-model loop below only
  /// surfaces the LAST model's error, the log read as "llama-3.1-8b-
  /// instant doesn't exist" when the real story was "neither model in
  /// this list exists anymore" — the exact same invisible-failure shape
  /// already documented (and partly fixed) in gemini_provider.dart's
  /// header. [_call]/[_callWithTools] below now log every attempt, not
  /// just the survivor, so this doesn't hide again.
  ///
  /// openai/gpt-oss-120b — best quality, tried first. Built for
  ///                       tool-use/agentic tasks per Groq's own model
  ///                       page, which matters here since this provider
  ///                       is used for tool calling.
  /// openai/gpt-oss-20b  — faster/cheaper fallback within Groq alone.
  ///
  /// Deliberately NOT groq/compound or groq/compound-mini — those are
  /// Groq's own agentic SYSTEMS with their own built-in tools (web
  /// search, code execution), not a plain chat model this codebase can
  /// hand its OWN tool schema to.
  static const _models = ['openai/gpt-oss-120b', 'openai/gpt-oss-20b'];

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
    // Keys OUTER, models INNER: a 429 on key 1 almost always means every
    // model on key 1 is also quota-exceeded (same account, same cap), so
    // exhaust key 1's models first, THEN move to key 2 — not the other
    // way round, which would burn key 2's quota on a model that's simply
    // retired rather than actually rate-limited.
    for (final key in _keys) {
      for (final model in _models) {
        try {
          return await _call(
            apiKey: key,
            model: model,
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            maxTokens: maxTokens,
          );
        } catch (e) {
          lastError = e;
          // Logged HERE, not just thrown at the end — a model that's been
          // retired reports 404 on every single call, and swallowing that
          // until the final "last error" message hid exactly which
          // model(s) were dead for longer than it should have (see this
          // file's header). Every attempt is now visible in its own line.
          Log.warning('GroqProvider: $model on ${_keyLabel(key)} failed, trying next: $e');
        }
      }
    }
    throw Exception('Groq: all keys/models failed. Last error: $lastError');
  }

  /// Never logs the real key — just which slot it is, so key rotation
  /// failures are traceable in logs without a secret ever appearing in
  /// them.
  String _keyLabel(String key) => key == apiKey ? 'primary key' : 'secondary key';

  Future<String> _call({
    required String apiKey,
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
    // Same keys-outer, models-inner order as [complete] — see that
    // method's comment.
    for (final key in _keys) {
      for (final model in _models) {
        try {
          return await _callWithTools(
            apiKey: key,
            model: model,
            systemPrompt: systemPrompt,
            userMessage: userMessage,
            tools: tools,
            maxTokens: maxTokens,
          );
        } catch (e) {
          lastError = e;
          // See the plain-completion loop above for why this is logged
          // per-attempt now instead of only at the end.
          Log.warning('GroqProvider: $model on ${_keyLabel(key)} failed (tool-calling), trying next: $e');
        }
      }
    }
    throw Exception('Groq: all keys/models failed (tool-calling). Last error: $lastError');
  }

  Future<AiToolCompletionResult> _callWithTools({
    required String apiKey,
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
