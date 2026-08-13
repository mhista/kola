// gemini_provider.dart
//
// Google's Gemini generateContent API — ported from
// copycat/kopicat_server's lib/ai.dart. Second in AiOrchestrator's
// priority order: Google's free tier is generous but has a lower
// requests-per-minute ceiling than Groq's, so it's the fallback, not
// the default.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../ai_provider.dart';

class GeminiProvider implements AiProvider {
  GeminiProvider({required this.apiKey});

  final String apiKey;

  /// ── BOTH PREVIOUS MODELS WERE SHUT DOWN ───────────────────────────
  ///
  /// This listed gemini-2.0-flash-lite and gemini-2.0-flash. Google has
  /// retired both, so EVERY call through this provider returned 404:
  ///
  ///   "This model models/gemini-2.0-flash-lite is no longer available."
  ///
  /// The per-model loop below made that invisible for longer than it
  /// should have been — it exists to survive one model failing, and
  /// instead it walked a list where every entry was dead, then reported
  /// one aggregate failure. Nothing distinguishes "temporarily rate
  /// limited" from "this endpoint no longer exists" in that message.
  ///
  /// A hardcoded model id is a dependency on someone else's release
  /// schedule, and the only real defence is that a 404 here now fails
  /// LOUDLY: WorkspaceAnswerService falls back to a text-only completion
  /// and marks the answer `generated: false`, so an owner is told the
  /// reasoning could not be reached rather than being handed a canned
  /// line dressed as an answer.
  ///
  /// gemini-3.5-flash-lite — cheapest current stable, tried first.
  /// gemini-3.6-flash      — smarter fallback within Gemini alone.
  ///
  /// Deliberately NOT `gemini-flash-latest`. That alias hot-swaps
  /// underneath us, and this provider is used for TOOL CALLING, where a
  /// silent model change is a silent change in how reliably the schema
  /// is honoured.
  static const _models = ['gemini-3.5-flash-lite', 'gemini-3.6-flash'];

  @override
  String get name => 'gemini';

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
      } on AiQuotaExceededException catch (e) {
        lastError = e;
        continue; // try the next Gemini model before giving up on Gemini
      }
    }
    throw Exception('Gemini: all models exhausted quota. Last error: $lastError');
  }

  Future<String> _call({
    required String model,
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final res = await http.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': maxTokens},
      }),
    );

    if (res.statusCode == 429) throw const AiQuotaExceededException('gemini');
    if (res.statusCode != 200) {
      throw Exception('Gemini error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List;
    final parts = (candidates.first as Map)['content']['parts'] as List;
    return (parts.first as Map)['text'] as String;
  }

  // TASK #134 — Gemini's OWN tool-calling shape, genuinely different from
  // the other two providers' OpenAI-compatible `tools`/`tool_calls`: the
  // request nests tool definitions under `tools[].functionDeclarations`
  // (not `tools[].function`), and a chosen call comes back as a
  // `functionCall` part inside `candidates[0].content.parts`, sitting
  // alongside (never combined with, in practice) plain `text` parts —
  // this is exactly the "near-equivalent request shape" ai_provider.dart's
  // header already flagged Gemini as having, not a surprise.
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
      } on AiQuotaExceededException catch (e) {
        lastError = e;
        continue;
      }
    }
    throw Exception('Gemini: all models exhausted quota (tool-calling). Last error: $lastError');
  }

  Future<AiToolCompletionResult> _callWithTools({
    required String model,
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    required int maxTokens,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final res = await http.post(
      url,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': maxTokens},
        'tools': [
          {
            'functionDeclarations': tools
                .map((t) => {
                      'name': t.name,
                      'description': t.description,
                      'parameters': t.parametersSchema,
                    })
                .toList(),
          },
        ],
      }),
    );

    if (res.statusCode == 429) throw const AiQuotaExceededException('gemini');
    if (res.statusCode != 200) {
      throw Exception('Gemini error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List;
    final parts = (candidates.first as Map)['content']['parts'] as List;

    for (final part in parts) {
      final functionCall = (part as Map)['functionCall'] as Map<String, dynamic>?;
      if (functionCall != null) {
        final args = functionCall['args'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return AiToolCompletionResult(
          toolCall: AiToolCall(toolName: functionCall['name'] as String, arguments: args),
        );
      }
    }

    final textPart = parts.firstWhere(
      (p) => (p as Map).containsKey('text'),
      orElse: () => {'text': ''},
    );
    return AiToolCompletionResult(text: (textPart as Map)['text'] as String? ?? '');
  }
}
