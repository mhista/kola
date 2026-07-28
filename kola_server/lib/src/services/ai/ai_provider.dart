// ai_provider.dart
//
// The one interface every AI provider implements — Phase 3a's "pluggable
// AI provider" requirement from SRS.md §3/§10: bot logic and the
// orchestrator below never import a vendor SDK or call a vendor's HTTP
// API directly, only this interface. Swapping/adding a provider later
// means writing one new class, not touching any calling code.
//
// TASK #134 — REAL TOOL-CALLING LANDED HERE, ADDITIVELY, EXACTLY AS THIS
// FILE'S HEADER PROMISED IT WOULD: [complete]/[AiCompletionResult] (in
// ai_orchestrator.dart) are UNCHANGED — nothing that already calls them
// needed to change. [completeWithTools] is the new sibling method: same
// systemPrompt/userMessage input, but the model may additionally choose
// to call one of [tools] instead of answering in plain text. All three
// providers below already speak an OpenAI-compatible or near-equivalent
// request shape, so this was genuinely additive, not a redesign — see
// each provider file's own header for its specific tools/tool_calls (or
// Gemini's functionDeclarations/functionCall) wire format.
//
// WHO USES [completeWithTools]: bot_knowledge_service.dart's `decide()`
// method (the tool-aware sibling of `answerGrounded()`), called from
// inbound_message_handler.dart. See errand_tool_registry.dart for how a
// workspace's active Errands become the [tools] list passed in.

abstract class AiProvider {
  /// Short identifier for logging/telemetry (e.g. "groq", "gemini",
  /// "openrouter") — never shown to end users.
  String get name;

  /// Returns true if this provider has a usable API key configured.
  /// AiOrchestrator uses this to decide which providers are even worth
  /// trying, in priority order, before making any real HTTP call.
  bool get isConfigured;

  /// Sends [systemPrompt] + [userMessage] to this provider and returns
  /// its plain-text answer. Throws on any failure (bad key, rate limit,
  /// network error, unexpected response shape) — AiOrchestrator is what
  /// decides whether to fall back to the next provider, not this method.
  Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1024,
  });

  /// Same contract as [complete], but the model may instead choose to
  /// call one of [tools]. Returns an [AiToolCompletionResult] whose
  /// [AiToolCompletionResult.toolCall] is set when the model chose a
  /// tool, or whose [AiToolCompletionResult.text] is set when it
  /// answered directly — never both, and (per each provider's own
  /// implementation) never neither. Throws on the same failure classes
  /// as [complete].
  Future<AiToolCompletionResult> completeWithTools({
    required String systemPrompt,
    required String userMessage,
    required List<AiTool> tools,
    int maxTokens = 1024,
  });
}

/// One callable capability offered to the model — built from a workspace's
/// active Errands by errand_tool_registry.dart, NOT constructed by hand
/// elsewhere. [parametersSchema] is a JSON Schema object (`{"type":
/// "object", "properties": {...}, "required": [...]}`) describing the
/// arguments the model should infer and supply — every provider's
/// implementation translates this same shape into its own wire format
/// (OpenAI-style `function.parameters`, or Gemini's
/// `functionDeclarations[].parameters`).
class AiTool {
  const AiTool({
    required this.name,
    required this.description,
    required this.parametersSchema,
  });

  /// Stable identifier the model echoes back in its tool call — NOT
  /// shown to end users, and not necessarily the Errand's own display
  /// name (see errand_tool_registry.dart on why it's `errand_<id>`
  /// instead — avoids any name-collision/sanitization concern entirely).
  final String name;

  final String description;
  final Map<String, dynamic> parametersSchema;
}

/// The model's decision to invoke [toolName] with [arguments] — arguments
/// are exactly what the model inferred, UNVALIDATED. Callers (see
/// bot_knowledge_service.dart / errand_dispatch_service.dart) must run
/// these through SecurityFilter.checkErrandInput before ever executing
/// anything, same "before ANY Errand call" rule that already applied to
/// human/API-triggered Errand calls.
class AiToolCall {
  const AiToolCall({required this.toolName, required this.arguments});

  final String toolName;
  final Map<String, dynamic> arguments;
}

/// What a single [AiProvider.completeWithTools] call returned. Exactly
/// one of [text] / [toolCall] is non-null — enforced by construction
/// convention in each provider's implementation, not by a sealed type,
/// since Dart's exhaustiveness checking on that would add more ceremony
/// than three well-commented provider implementations need.
class AiToolCompletionResult {
  const AiToolCompletionResult({this.text, this.toolCall});

  final String? text;
  final AiToolCall? toolCall;

  bool get isToolCall => toolCall != null;
}

/// Thrown by a provider specifically for rate-limit/quota responses —
/// lets AiOrchestrator distinguish "this key is out of quota, try the
/// next model in this same provider's list" from "this provider is
/// fundamentally broken, skip straight to the next provider entirely."
/// Mirrors copycat/kopicat_server's ai.dart `_QuotaException`, ported
/// rather than reinvented.
class AiQuotaExceededException implements Exception {
  final String providerName;
  const AiQuotaExceededException(this.providerName);

  @override
  String toString() => 'AiQuotaExceededException: $providerName quota exceeded';
}
