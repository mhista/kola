// gemini_provider.dart
//
// Google's Gemini generateContent API — ported from
// copycat/kopicat_server's lib/ai.dart. Second in AiOrchestrator's
// priority order: Google's free tier is generous but has a lower
// requests-per-minute ceiling than Groq's, so it's the fallback, not
// the default.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kola_server/kola_logger.dart';
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

  // ── SECOND BUG FOUND IN THIS SAME FALLBACK LOOP (2026-08-22) ─────────
  //
  // complete()/completeWithTools() used to only catch
  // AiQuotaExceededException when deciding whether to try the second
  // model — any OTHER failure from the first model (bad request, a
  // model rename, an unexpected response shape) threw straight out of
  // the loop, skipping gemini-3.6-flash entirely and propagating all
  // the way up to AiOrchestrator. With OpenRouter unconfigured in
  // production, that meant a single non-quota Gemini error could take
  // down the entire Groq -> Gemini -> OpenRouter chain after Groq's own
  // quota was hit — exactly the failure the owner hit trying to book a
  // calendar event. Both loops now catch everything, matching
  // GroqProvider's per-model loop, and log every attempt.

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
      } catch (e) {
        // BUG FIXED HERE — this used to only catch AiQuotaExceededException,
        // so any OTHER failure (bad request, a renamed/retired model, an
        // unexpected response shape) skipped straight past the second
        // Gemini model and threw all the way up to AiOrchestrator. With
        // OpenRouter unconfigured, that meant one non-quota Gemini error
        // could take down the ENTIRE fallback chain after Groq. Now
        // catches everything, same as GroqProvider's own per-model loop,
        // and logs every attempt instead of hiding all but the last.
        lastError = e;
        Log.warning('GeminiProvider: $model failed, trying next: $e');
      }
    }
    throw Exception('Gemini: all models failed. Last error: $lastError');
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
      } catch (e) {
        // See [complete]'s identical fix above — was quota-only, now
        // catches every failure so one non-quota error from the first
        // model doesn't skip the second Gemini model entirely.
        lastError = e;
        Log.warning('GeminiProvider: $model failed (tool-calling), trying next: $e');
      }
    }
    throw Exception('Gemini: all models failed (tool-calling). Last error: $lastError');
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
