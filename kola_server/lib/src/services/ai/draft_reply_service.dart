// draft_reply_service.dart — Phase 14e. The "kola suggests a reply,
// edit before you send" seam operations_page.dart's own header has
// named as deliberately unfilled since Phase 13c: "SUGGESTED REPLY —
// the export offers an editable AI draft. There is still no endpoint
// that produces one."
//
// ── WHY A REAL MODEL CALL, NOT JUST A TEMPLATE ────────────────────────
//
// The owner's explicit instruction for this pass (2026-09-01): build
// real AI generation now, with a template fallback rather than the
// other way around. This service is that — [draft] tries a real model
// completion first and only falls back to [_template] if every
// configured provider fails (no key configured, every provider erroring,
// or the completion coming back empty).
//
// ── REUSES AiOrchestrator — NOT A NEW GEMINI CLIENT ───────────────────
//
// 14i found a real problem: EmbeddingOrchestrator has exactly one
// provider (Gemini) with no fallback, so a single 429 permanently fails
// that call. AiOrchestrator (the TEXT-completion path this service
// calls, not the embeddings one) does not have that problem — it
// already cascades Groq → Gemini → OpenRouter, trying the next provider
// on ANY failure including a 429, and only throwing once every
// configured provider has failed. So this service inherits real
// multi-provider resilience for free, rather than needing its own
// retry/backoff logic — the [_template] fallback below only fires in
// the genuinely rare case that every configured provider is down or
// none is configured at all.
//
// ── WHAT THE TEMPLATE FALLBACK IS, HONESTLY ───────────────────────────
//
// Not a second AI call and not a canned "Thanks for reaching out" —
// it quotes back what the customer actually last said and asks them to
// hold, which is truthful regardless of why the model path failed. See
// [_template]. [DraftReply.isTemplate] tells the caller which path
// produced the text, so the dashboard can label a template-sourced
// draft honestly rather than presenting it as if a model wrote it.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/generated/protocol.dart' hide Message;
import 'package:kola_server/src/generated/protocol.dart' as protocol show Message;
import 'ai_orchestrator.dart';

class DraftReply {
  const DraftReply({required this.text, required this.isTemplate});

  final String text;

  /// True when [text] came from [DraftReplyService._template] rather
  /// than a real model completion — every configured AiOrchestrator
  /// provider failed or none was configured. The dashboard uses this to
  /// label the draft honestly rather than implying a model wrote it.
  final bool isTemplate;
}

class DraftReplyService {
  DraftReplyService({required AiOrchestrator aiOrchestrator})
      : _ai = aiOrchestrator;

  final AiOrchestrator _ai;

  /// Drafts a reply to the customer's most recent inbound message in
  /// [thread], given the conversation so far. [thread] is expected
  /// oldest-first, same order ConversationEndpoint.getMessages already
  /// returns — this method does not re-sort it.
  Future<DraftReply> draft({
    required List<protocol.Message> thread,
    required String? customerDisplayName,
  }) async {
    final lastCustomerMessage = thread.lastWhere(
      (m) => m.senderType == 'customer',
      orElse: () => thread.isNotEmpty
          ? thread.last
          : protocol.Message(
              conversationId: 0,
              direction: 'inbound',
              senderType: 'customer',
              body: '',
              createdAt: DateTime.now(),
            ),
    );

    try {
      final transcript = _renderTranscript(thread);
      final result = await _ai.complete(
        systemPrompt:
            'You are drafting a reply for a small business owner to send '
            'to one of their customers, on their behalf, in a WhatsApp/'
            'Telegram-style conversation. Write ONLY the reply text — no '
            'preamble, no quotation marks, no "Here is a draft:", no '
            'signature. Keep it short (1-4 sentences), warm, and '
            'specific to what the customer actually asked. The owner '
            'will read and edit this before sending, so it is a starting '
            'point, not a final answer — do not invent facts about '
            'orders, prices, or policies you were not given.',
        userMessage: 'Conversation so far (oldest first):\n$transcript\n\n'
            'Draft the business\'s next reply.',
        maxTokens: 220,
      );
      final text = result.text.trim();
      if (text.isEmpty) {
        throw StateError('Model returned an empty draft.');
      }
      return DraftReply(text: text, isTemplate: false);
    } catch (e) {
      Log.warning(
        'DraftReplyService: every provider failed, falling back to template: $e',
      );
      return DraftReply(
        text: _template(lastCustomerMessage, customerDisplayName),
        isTemplate: true,
      );
    }
  }

  String _renderTranscript(List<protocol.Message> thread) {
    // Last 12 messages — enough for real context on a normal support
    // exchange without unbounded prompt growth on a very long thread.
    final recent = thread.length > 12
        ? thread.sublist(thread.length - 12)
        : thread;
    return recent
        .map((m) {
          final who = switch (m.senderType) {
            'customer' => 'Customer',
            'bot' => 'Kola (auto-reply)',
            'human' => 'Business',
            'api' => 'Business (API)',
            _ => m.senderType,
          };
          return '$who: ${m.body}';
        })
        .join('\n');
  }

  /// Honest, non-AI fallback: quotes the customer's own last message
  /// back to them and buys the owner time, rather than guessing at an
  /// answer. Never invents an order status, a price, or a policy —
  /// exactly the failure mode a plausible-sounding template risks.
  String _template(protocol.Message lastCustomerMessage, String? name) {
    final greeting = (name == null || name.trim().isEmpty)
        ? 'Hi there'
        : 'Hi ${name.trim()}';
    final quoted = lastCustomerMessage.body.trim();
    if (quoted.isEmpty) {
      return '$greeting, thanks for reaching out — let me look into this '
          'and get back to you shortly.';
    }
    return '$greeting, thanks for your message. Let me look into '
        '"${quoted.length > 120 ? '${quoted.substring(0, 120)}…' : quoted}" '
        'and get back to you shortly.';
  }
}
