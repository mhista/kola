// bot_knowledge_service.dart
//
// Satisfies half of Phase 3's overall "done when" bar
// (DEVELOPMENT_PLAN.md Phase 3): "a bot can answer a question grounded
// in a manually-seeded piece of knowledge... through the multi-provider
// AI orchestrator." The other half (executing a built-in Errand) is
// builtin_errand_executor.dart.
//
// PHASE 9 — §8 HAS NOW SHIPPED, AND THIS FILE CHANGED EXACTLY THE WAY
// THE PARAGRAPH BELOW SAID IT WOULD. That original note read: "Once §8
// ships, real retrieval replaces reading that field directly here; this
// file's job (turn 'seeded knowledge' into a grounded system prompt,
// then call AiOrchestrator) stays the same shape, just fed by a smarter
// source." That is precisely what happened — [answerGrounded] and
// [decide] have the same signatures and the same contract; only the
// SOURCE of the "--- BUSINESS INFORMATION ---" block changed, from one
// plain-text field to semantically-retrieved passages with citations.
//
// THE FALLBACK IS DELIBERATE AND NOT TEMPORARY-UNTIL-WE-GET-AROUND-TO-IT.
// _resolveKnowledge below prefers retrieved memory, but falls back to
// Bot.knowledgeSeed when a workspace has no indexed documents, when
// retrieval finds nothing above the similarity floor, or when no
// embedding provider is configured at all. Three real reasons:
//   • Every existing workspace has content in knowledgeSeed today and
//     none in knowledge_documents. Cutting over without a fallback would
//     make every live bot instantly stop knowing anything.
//   • A self-hosted or key-less deployment has no embeddings available.
//     Degrading to the old behaviour is strictly better than refusing to
//     answer.
//   • Retrieval legitimately returns nothing for an off-topic question.
//     A small seed ("we're a fashion store in Lagos, open 9–6") is
//     genuinely useful context that no retrieval hit would surface.
// bot.spy.yaml's knowledgeSeed field is therefore NOT dropped by
// migration 017, and shouldn't be until every workspace has migrated.
//
// ORIGINAL PHASE 3 NOTE, kept for the reasoning trail:
// DELIBERATELY NOT SRS.md §8's Document Parsing Engine: that's PDF/DOCX/
// CSV/XLSX upload, chunking, and retrieval — separate, larger, later
// work with its own KnowledgeDocument model. This service reads exactly
// one plain-text field (Bot.knowledgeSeed, see bot.spy.yaml's header)
// and injects it into the system prompt whole — no chunking, no
// retrieval ranking, because there's nothing to rank yet.
//
// COST-SAVING CHANNEL HANDOFF (added after Meta's Jul 2026 announcement
// that free WhatsApp service-window replies end Oct 1, 2026): both
// answerGrounded and decide append _costSavingNote(bot) to whichever
// prompt they build — see that method's own doc comment.

import 'dart:convert';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/ai/ai_provider.dart';
import 'package:kola_server/src/services/errand/errand_tool_registry.dart';
import 'package:kola_server/src/services/memory/memory_retrieval_service.dart';

/// A grounded answer, plus whether the model itself decided this needs
/// a human — see [BotKnowledgeService.answerGrounded]'s header for the
/// sentinel-token mechanism that sets [needsEscalation]. [text] never
/// contains the raw sentinel — it's always already stripped out.
class GroundedAnswer {
  const GroundedAnswer({
    required this.text,
    required this.needsEscalation,
    required this.providerName,
    this.citations = const [],
  });

  final String text;
  final bool needsEscalation;
  final String providerName;

  /// PHASE 9 — which stored passages this answer was grounded in.
  ///
  /// Empty when the answer came from the legacy knowledgeSeed fallback
  /// (there is nothing to cite: one undifferentiated blob of text isn't
  /// a source), or when no knowledge applied at all. Non-empty means the
  /// answer is traceable to specific documents and sections — the point
  /// of Layer 2, and the thing that makes "cite where information came
  /// from" checkable rather than a promise.
  ///
  /// Defaulted rather than required so every existing construction of
  /// this class — including the const fallbacks in the catch blocks
  /// below — keeps compiling unchanged.
  final List<MemoryCitation> citations;
}

class BotKnowledgeService {
  BotKnowledgeService({
    required AiOrchestrator aiOrchestrator,
    MemoryRetrievalService? retrieval,
  })  : _ai = aiOrchestrator,
        _retrieval = retrieval;

  final AiOrchestrator _ai;

  /// PHASE 9. Nullable on purpose: the standalone verification scripts in
  /// tool/ (test_grounded_qa.dart, test_escalation_loop.dart) construct
  /// this service with an orchestrator alone and no database at all.
  /// Null simply means "no long-term memory available here" and takes the
  /// same knowledgeSeed path a workspace with no indexed documents takes
  /// — so those scripts keep working without a Supabase connection.
  final MemoryRetrievalService? _retrieval;

  /// Resolves the knowledge block for one question: retrieved memory if
  /// there is any, else the legacy seed, else nothing. This is the ONE
  /// place that decision is made — [answerGrounded] and [decide] both
  /// call it rather than each re-deriving the precedence and drifting
  /// apart.
  Future<_ResolvedKnowledge> _resolveKnowledge(Bot bot, String question) async {
    final retrieval = _retrieval;
    if (retrieval != null) {
      final context = await retrieval.retrieve(
        workspaceId: bot.workspaceId,
        query: question,
      );
      if (!context.isEmpty) {
        return _ResolvedKnowledge(
          block: context.promptBlock,
          citations: context.citations,
          isRetrieved: true,
        );
      }
    }

    final seed = bot.knowledgeSeed?.trim();
    if (seed != null && seed.isNotEmpty) {
      return _ResolvedKnowledge(block: seed, citations: const [], isRetrieved: false);
    }

    return const _ResolvedKnowledge(block: '', citations: [], isRetrieved: false);
  }

  /// Instruction appended when the knowledge block came from real
  /// retrieval. Only added in that case: the numbered `[1]`/`[2]` markers
  /// it refers to exist only in MemoryRetrievalService's formatted block,
  /// so telling the model to cite them when it's looking at an
  /// unstructured knowledgeSeed blob would invite it to invent citations
  /// — the exact opposite of what this feature is for.
  static const _citationInstruction =
      ' The information below is drawn from the business\'s own saved '
      'documents, each numbered and labelled with its source. Base your '
      'answer only on those passages. Do not mention the numbers, the '
      'sources, or the fact that you are reading documents in your reply '
      'to the customer — write naturally, as the business would.';

  // A plain, unambiguous marker the model is instructed to append — NOT
  // real AI tool-calling (that's Phase 3d's Errand/AI security-filter
  // pass, still pending). This is a deliberately simple, honest stand-in
  // that makes the escalation feature's automatic trigger buildable
  // today without waiting on that larger piece: the model just says so
  // in plain text, and this file parses that out. Any future real
  // tool-calling implementation replaces this token check, not the
  // GroundedAnswer contract callers already depend on.
  static const _escalateToken = '[[ESCALATE_TO_HUMAN]]';

  /// COST-SAVING CHANNEL HANDOFF — added after Meta announced (Jul 2026)
  /// that free-text replies inside WhatsApp's 24-hour service window
  /// stop being free on Oct 1, 2026. See bot.spy.yaml's header on the
  /// two fields this reads and docs/AVOIDING_EXCESSIVE_WHATSAPP_BILLING.md
  /// for the full explanation given to business owners. Returns an
  /// empty string (appends nothing) if the owner hasn't configured
  /// either field — a bot NEVER invents a Telegram link or alternate
  /// number, and never redirects a customer away from WhatsApp just
  /// because it's technically possible; only when it's actually
  /// warranted (a long, back-and-forth conversation) AND the owner has
  /// actually provided somewhere to send them.
  String _costSavingNote(Bot bot) {
    final telegram = bot.costSavingTelegramLink?.trim();
    final altWhatsapp = bot.costSavingAlternateWhatsapp?.trim();
    final hasTelegram = telegram != null && telegram.isNotEmpty;
    final hasAlt = altWhatsapp != null && altWhatsapp.isNotEmpty;
    if (!hasTelegram && !hasAlt) return '';

    final options = [
      if (hasTelegram) 'Telegram ($telegram)',
      if (hasAlt) altWhatsapp,
    ].join(' or ');

    return '\n\nIf this conversation runs long or becomes back-and-forth-heavy, '
        'and only then, you may suggest continuing on $options instead — '
        'mention it briefly, once, without being pushy, and only if the '
        'customer seems fine with it. Do not suggest this for a short or '
        'already-resolved conversation.';
  }

  /// Answers [question] using [bot]'s knowledgeSeed as the ONLY source
  /// of truth — the system prompt explicitly instructs the model not to
  /// invent an answer beyond it, so a gap in what's seeded surfaces as
  /// an honest "I don't know, let me get someone" rather than a
  /// hallucinated guess. Mirrors the escalateToHuman built-in Errand's
  /// tone deliberately — both are the same underlying promise to the end
  /// customer: never bluff.
  Future<GroundedAnswer> answerGrounded({
    required Bot bot,
    required String question,
  }) async {
    final knowledge = await _resolveKnowledge(bot, question);
    final systemPrompt = (knowledge.hasContent
        ? 'You are a helpful assistant for this business. Answer the '
            'customer\'s question using ONLY the information below. If '
            'the answer isn\'t in it, say plainly that you don\'t have '
            'that information and that you\'re connecting them with a '
            'person on the team — never invent an answer that isn\'t '
            'supported by this information. Whenever you give that '
            '"connecting you with a person" reply for ANY reason (missing '
            'info, an angry or urgent customer, an explicit request for a '
            'human), end your message with exactly this token on its own '
            'line, verbatim: $_escalateToken'
            '${knowledge.isRetrieved ? _citationInstruction : ''}\n\n'
            '--- BUSINESS INFORMATION ---\n${knowledge.block}'
        : 'You are a helpful assistant for this business, but no '
            'business-specific information has been set up yet. Be '
            'honest that you don\'t have specific details to answer from, '
            'and say you\'re connecting the customer with a person on the '
            'team. End that message with exactly this token on its own '
            'line, verbatim: $_escalateToken') +
        _costSavingNote(bot);

    try {
      final result = await _ai.complete(systemPrompt: systemPrompt, userMessage: question);
      final needsEscalation = result.text.contains(_escalateToken);
      final cleanText = result.text.replaceAll(_escalateToken, '').trimRight();
      return GroundedAnswer(
        text: cleanText,
        needsEscalation: needsEscalation,
        providerName: result.providerName,
        citations: knowledge.citations,
      );
    } catch (_) {
      // No AI provider configured/reachable at all — fail honest, not
      // silent: same "never bluff" promise, just triggered by an
      // infrastructure gap instead of a knowledge gap.
      return const GroundedAnswer(
        text: "I'm having trouble answering that right now — I'm "
            "connecting you with a person on the team.",
        needsEscalation: true,
        providerName: 'none',
      );
    }
  }

  /// TASK #134 — the tool-calling sibling of [answerGrounded]. Same
  /// grounding-in-knowledgeSeed promise, but the model may additionally
  /// choose to call one of [tools] (built by errand_tool_registry.dart
  /// from a workspace's active Errands, plus the reserved
  /// [kEscalateToHumanToolName] tool that's always present) instead of
  /// answering in plain text. This REPLACES [answerGrounded]'s sentinel-
  /// token escalation mechanism for callers that use it — escalation is
  /// now just the model calling a tool like any other — but
  /// [answerGrounded] itself is untouched, so anything still calling it
  /// (test scripts, any future caller that genuinely doesn't need
  /// Errand-calling) keeps working exactly as before.
  Future<KnowledgeDecision> decide({
    required Bot bot,
    required List<AiTool> tools,
    required String question,
  }) async {
    final knowledge = await _resolveKnowledge(bot, question);
    final systemPrompt = (knowledge.hasContent
        ? 'You are a helpful assistant for this business. Answer the '
            'customer\'s question using ONLY the information below when '
            'it\'s relevant. If one of your available tools can directly '
            'help fulfill what the customer is asking for (for example: '
            'taking a payment, logging a complaint, saving a follow-up '
            'date, or anything else a tool below describes), call it with '
            'the best values you can infer from the conversation — don\'t '
            'just describe what you would do. If the answer isn\'t '
            'supported by the information below and no tool applies, or '
            'the customer is upset, urgent, or explicitly asking for a '
            'person, call the $kEscalateToHumanToolName tool rather than '
            'guessing. Never invent an answer that isn\'t supported by '
            'this information.'
            '${knowledge.isRetrieved ? _citationInstruction : ''}\n\n'
            '--- BUSINESS INFORMATION ---\n${knowledge.block}'
        : 'You are a helpful assistant for this business, but no '
            'business-specific information has been set up yet. If one of '
            'your available tools can directly help the customer, call it '
            'with the best values you can infer. Otherwise, if you don\'t '
            'have enough information to help, call the '
            '$kEscalateToHumanToolName tool rather than guessing.') +
        _costSavingNote(bot);

    try {
      final result = await _ai.completeWithTools(
        systemPrompt: systemPrompt,
        userMessage: question,
        tools: tools,
      );
      return KnowledgeDecision(
        directAnswer: result.text,
        toolCall: result.toolCall,
        providerName: result.providerName,
        citations: knowledge.citations,
      );
    } catch (_) {
      // Same "fail honest" posture as answerGrounded's catch block —
      // triggered by an infrastructure gap, so it forces the same
      // escalation path a knowledge gap would have gone through, just
      // via a real tool call now instead of a sentinel token.
      return const KnowledgeDecision(
        toolCall: AiToolCall(
          toolName: kEscalateToHumanToolName,
          arguments: {'reason': 'No AI provider was reachable to answer this question.'},
        ),
        providerName: 'none',
      );
    }
  }

  /// TASK #134 — turns a raw Errand execution result (a webhook or
  /// dbCredential Errand's JSON response — a builtin handler's own
  /// `replyToCustomer` field is used directly by InboundMessageHandler
  /// instead of calling this, see its header) into a natural-language
  /// reply the customer can actually read. Deliberately uses plain
  /// [AiOrchestrator.complete], not [completeWithTools] — there's
  /// nothing left to call a tool for at this point, just a result to
  /// explain in the context of what the customer originally asked.
  Future<GroundedAnswer> summarizeToolResult({
    required Bot bot,
    required String question,
    required Map<String, dynamic> result,
  }) async {
    final systemPrompt =
        'You are a helpful assistant for this business. The customer just '
        'asked something, and a tool was already run on their behalf. '
        'Below is that tool\'s raw JSON result. Write a short, natural, '
        'friendly reply to the customer summarizing it — never show them '
        'raw JSON or field names, just the useful information in plain '
        'language. If the result looks like an error or clearly didn\'t '
        'work, apologize briefly and say you\'re connecting them with a '
        'person on the team, and end your message with exactly this '
        'token on its own line, verbatim: $_escalateToken\n\n'
        '--- TOOL RESULT (JSON) ---\n${_safeEncode(result)}';

    try {
      final completion = await _ai.complete(systemPrompt: systemPrompt, userMessage: question);
      final needsEscalation = completion.text.contains(_escalateToken);
      final cleanText = completion.text.replaceAll(_escalateToken, '').trimRight();
      return GroundedAnswer(
        text: cleanText,
        needsEscalation: needsEscalation,
        providerName: completion.providerName,
      );
    } catch (_) {
      return const GroundedAnswer(
        text: "That went through, but I'm having trouble summarizing it right now — "
            "I'm connecting you with a person on the team.",
        needsEscalation: true,
        providerName: 'none',
      );
    }
  }
}

String _safeEncode(Map<String, dynamic> result) {
  try {
    return const JsonEncoder.withIndent('  ').convert(result);
  } catch (_) {
    return result.toString();
  }
}

/// What [BotKnowledgeService.decide] returned for one customer message —
/// exactly one of [directAnswer] / [toolCall] is meaningfully set (mirrors
/// [AiToolCompletionResult]'s own "exactly one of text/toolCall" shape).
/// InboundMessageHandler is what actually dispatches [toolCall] (via
/// ErrandDispatchService) and turns the result into a customer-facing
/// reply — this class only carries the model's DECISION, not its effect.
class KnowledgeDecision {
  const KnowledgeDecision({
    this.directAnswer,
    this.toolCall,
    required this.providerName,
    this.citations = const [],
  });

  final String? directAnswer;
  final AiToolCall? toolCall;
  final String providerName;

  /// PHASE 9 — the stored passages that grounded this decision. Same
  /// semantics and same defaulted-not-required reasoning as
  /// [GroundedAnswer.citations].
  final List<MemoryCitation> citations;

  bool get wantsToolCall => toolCall != null;
}

/// PHASE 9 — the knowledge block for one question plus where it came
/// from. Internal to this file: callers get [GroundedAnswer.citations]
/// or [KnowledgeDecision.citations], not this.
class _ResolvedKnowledge {
  const _ResolvedKnowledge({
    required this.block,
    required this.citations,
    required this.isRetrieved,
  });

  /// The text to inject under "--- BUSINESS INFORMATION ---". Empty when
  /// the workspace has neither indexed memory nor a knowledgeSeed.
  final String block;

  final List<MemoryCitation> citations;

  /// True when [block] came from semantic retrieval (and therefore
  /// carries the numbered source labels [_citationInstruction] refers
  /// to), false when it's the legacy knowledgeSeed blob.
  final bool isRetrieved;

  bool get hasContent => block.isNotEmpty;
}
