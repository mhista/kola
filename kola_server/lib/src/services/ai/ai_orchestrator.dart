// ai_orchestrator.dart
//
// Phase 3a's "multi-provider AI orchestrator" (DEVELOPMENT_PLAN.md Phase
// 3a, SRS.md §3/§10) — the ONE thing bot logic and Errand execution
// (Phase 3b/3c) ever call to get an AI answer. Nothing else in this
// codebase should import a provider class or call a vendor API directly.
//
// WHY GROQ → GEMINI → OPENROUTER, IN THAT ORDER: this is copycat/
// kopicat_server's exact provider cascade (lib/ai.dart), ported rather
// than reinvented — same "reuse before rebuilding" convention as every
// other service in this project. It was chosen there (and kept here) for
// cost efficiency: all three have usable free tiers, tried in order of
// generosity/speed, so Kola runs on $0 of AI spend until real usage
// numbers justify paying for a stronger model. Switching or reordering
// providers later is a one-line change to [_providers] below — proving
// early that provider choice isn't load-bearing anywhere else is the
// whole point of going through this interface at all (see
// ai_provider.dart's header).
//
// FAILURE MODEL: tries each configured provider in priority order,
// falling through to the next on ANY failure (bad key, quota, network
// error, unexpected response shape) — a business's bot should degrade
// to a slower/weaker provider before it ever goes completely silent.
// Only throws once every configured provider has failed; throws
// immediately (a clear, actionable error) if NO provider has a key
// configured at all, same "fail loud and early" instinct as every
// credential-probing endpoint elsewhere in this project.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/env.dart';
import 'ai_provider.dart';
import 'providers/groq_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/openrouter_provider.dart';

class AiOrchestrator {
  AiOrchestrator({List<AiProvider>? providers})
      : _providers = providers ??
            [
              // GROQ_API_KEY_2 (optional) — a second Groq account's key,
              // tried by GroqProvider itself once every model on the
              // primary key is quota-exceeded, BEFORE this cascade ever
              // has to fall through to Gemini. See groq_provider.dart's
              // header.
              GroqProvider(apiKey: Env.groqApiKey, secondaryApiKey: Env.groqApiKey2),
              GeminiProvider(apiKey: Env.geminiApiKey),
              OpenRouterProvider(apiKey: Env.openRouterApiKey),
            ];

  final List<AiProvider> _providers;

  /// Result of a successful [complete] call — carries which provider
  /// actually answered alongside the text, so callers can log/telemetry
  /// on provider usage without every call site re-deriving it.
  Future<AiCompletionResult> complete({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
  }) async {
    final configured = _providers.where((p) => p.isConfigured).toList();
    if (configured.isEmpty) {
      throw StateError(
        'No AI provider is configured. Set at least one of GROQ_API_KEY '
        '(recommended, free: https://console.groq.com), GEMINI_API_KEY '
        '(free tier: https://aistudio.google.com), or OPENROUTER_API_KEY '
        '(free models: https://openrouter.ai) in .env, then re-run '
        '`dart run build_runner build`.',
      );
    }

    final errors = <String>[];
    for (final provider in configured) {
      try {
        final text = await provider.complete(
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          maxTokens: maxTokens,
        );
        Log.info('AiOrchestrator: ${provider.name} answered — textLength=${text.trim().length}');
        return AiCompletionResult(text: text, providerName: provider.name);
      } catch (e) {
        Log.warning('AiOrchestrator: ${provider.name} failed, trying next provider: $e');
        errors.add('${provider.name}: $e');
      }
    }

    throw Exception(
      'AiOrchestrator: every configured provider failed.\n${errors.join('\n')}',
    );
  }

  /// TASK #134 — the tool-calling sibling of [complete], same
  /// provider-cascade failure model: tries each configured provider in
  /// order, falling through to the next on ANY failure, only throwing
  /// once every configured provider has failed. [tools] is typically
  /// built by errand_tool_registry.dart from a workspace's active
  /// Errands (plus the platform's own always-available escalation tool)
  /// — see bot_knowledge_service.dart's `decide()` for the caller.
  Future<AiToolOrchestratorResult> completeWithTools({
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    int maxTokens = 1024,
  }) async {
    final configured = _providers.where((p) => p.isConfigured).toList();
    if (configured.isEmpty) {
      throw StateError(
        'No AI provider is configured. Set at least one of GROQ_API_KEY '
        '(recommended, free: https://console.groq.com), GEMINI_API_KEY '
        '(free tier: https://aistudio.google.com), or OPENROUTER_API_KEY '
        '(free models: https://openrouter.ai) in .env, then re-run '
        '`dart run build_runner build`.',
      );
    }

    final errors = <String>[];
    for (final provider in configured) {
      try {
        final result = await provider.completeWithTools(
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          tools: tools,
          maxTokens: maxTokens,
        );
        // Visible on EVERY call, not just failures — otherwise there is
        // no way to tell from the logs which provider actually answered
        // a given request, or to notice a pattern like "gemini keeps
        // answering with empty content" before it shows up as a
        // downstream WorkspaceAnswerService warning three calls deep.
        Log.info(
          'AiOrchestrator: ${provider.name} answered (tool-calling) — '
          'toolCall=${result.toolCall?.toolName ?? 'none'}',
        );
        return AiToolOrchestratorResult(
          text: result.text,
          toolCall: result.toolCall,
          providerName: provider.name,
        );
      } catch (e) {
        Log.warning('AiOrchestrator: ${provider.name} failed (tool-calling), trying next provider: $e');
        errors.add('${provider.name}: $e');
      }
    }

    throw Exception(
      'AiOrchestrator: every configured provider failed (tool-calling).\n${errors.join('\n')}',
    );
  }
}

class AiCompletionResult {
  const AiCompletionResult({required this.text, required this.providerName});

  final String text;

  /// Which provider actually produced [text] — e.g. "groq". Never shown
  /// to end users; useful for logs/telemetry on provider reliability and
  /// cost.
  final String providerName;
}

/// Result of a successful [AiOrchestrator.completeWithTools] call — the
/// same [AiToolCompletionResult] shape a single provider returns, plus
/// which provider answered, mirroring [AiCompletionResult]'s own reason
/// for existing.
class AiToolOrchestratorResult {
  const AiToolOrchestratorResult({this.text, this.toolCall, required this.providerName});

  final String? text;
  final AiToolCall? toolCall;
  final String providerName;

  bool get isToolCall => toolCall != null;
}
