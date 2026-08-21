// bot_mother_service.dart
//
// TASK #139 — a real (if deliberately minimal) first slice of
// DEVELOPMENT_PLAN.md §8c's "Bot Mother" ("Not started. Needs product
// scoping first"). Full Bot Mother — per that plan section's own
// framing — means a whole WhatsApp/Telegram-native onboarding
// conversation, which genuinely does need a product decision this file
// doesn't make. What THIS closes is a narrower, concretely-scoped gap
// the owner pointed at directly: kola_dashboard's home-page composer
// ("What do you want kola to help with today?") sat next to a
// "Create a new bot" quick action with zero AI wiring behind it —
// see composer.dart's own header, "Static shell... no kola_client wiring
// yet". This service is that wiring's other half: turn one plain-
// language description into the same {name, archetype, knowledgeSeed}
// shape BotEndpoint.createBot's caller would otherwise fill in by hand
// on the CreateBotPage form.
//
// NOT A NEW CREATION PATH: BotEndpoint.createBotFromDescription (the
// caller of this service) still runs through createBot's exact
// validation and starts the bot in the same 'draft' status — this is a
// drafting step layered on top of the existing contract, not a second
// set of rules for AI-originated bots.
//
// FAILURE MODE: same "never bluff" posture as bot_knowledge_service.dart
// — if no AI provider is configured, or the model's response can't be
// parsed as the expected JSON shape, this falls back to a safe,
// honest draft (a generic name derived from the description, the
// 'customerCare' default archetype, and NO knowledge seed — inventing
// business facts the description didn't actually state would be worse
// than leaving the seed empty for the owner to fill in on the Knowledge
// page afterward).

import 'dart:convert';

import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/agents/agent_archetypes.dart';

/// Phase A of the agent architecture correction: this used to be its own
/// literal set, duplicated from bot_endpoint.dart's (also-private, also
/// now retired) copy specifically so a change to one was a visible
/// two-file diff rather than silent drift. Now both read from
/// [AgentArchetypes.allKeys] instead — the registry itself is the single
/// source of truth, so there is nothing left to drift. The prompt text
/// below still needs its own hand-written prose (an LLM needs sentences,
/// not just keys) and MUST list the same roles this set contains.
final _validArchetypes = AgentArchetypes.allKeys;

class DraftedBot {
  const DraftedBot({
    required this.name,
    required this.archetype,
    this.knowledgeSeed,
  });

  final String name;
  final String archetype;

  /// Null means "nothing concrete enough to seed" — never a guessed
  /// placeholder. BotEndpoint.createBotFromDescription only calls
  /// setKnowledgeSeed's underlying update when this is non-null.
  final String? knowledgeSeed;
}

class BotMotherService {
  BotMotherService({required AiOrchestrator aiOrchestrator})
    : _ai = aiOrchestrator;

  final AiOrchestrator _ai;

  // Archetype guide below MUST list the same roles AgentArchetypes.all
  // declares (see this file's header) — kept as hand-written prose
  // rather than generated from that list because an LLM needs a
  // sentence of guidance per role, not a bare key.
  static const _systemPrompt = '''
You help set up a new agent for a small business from one short description they type. An agent is defined by its ROLE — what job it does — not by which channel (WhatsApp, Telegram) it happens to talk on; do not let a mention of a specific channel change which role you pick. Respond with ONLY a JSON object, no other text before or after it, matching exactly this shape:
{"name": "<short, friendly agent name, 2-4 words>", "archetype": "<one of: customerCare, catalog, payment, support, finance, inventory, marketing, sales, custom>", "knowledgeSeed": "<a short starter knowledge paragraph based ONLY on what the description actually states, or an empty string if it gives no concrete facts to seed>"}

Archetype guide:
- "customerCare": general Q&A, support, escalation to a human when stuck — the right default for most businesses when nothing more specific fits.
- "catalog": the business is primarily about browsing or negotiating over a product catalog (prices, stock, variants).
- "payment": collecting or confirming payments from customers, on any channel, settling through any connected provider.
- "support": resolving tickets and routing issues to the right person or department.
- "finance": chasing overdue invoices, confirming payments, answering finance questions.
- "inventory": watching stock levels and flagging what needs restocking.
- "marketing": sending promotions, announcements, or follow-ups.
- "sales": answering product questions and taking orders.
- "custom": anything that clearly doesn't fit any of the above.

If a business or product name is mentioned, use it in "name". Otherwise use something generic and friendly like "Store Assistant". Never invent prices, policies, hours, or any other fact "knowledgeSeed" doesn't actually come from — an empty string is the honest answer when the description doesn't give you enough to seed.''';

  /// Turns [description] (the raw text a business owner typed into the
  /// dashboard composer) into a [DraftedBot]. Never throws — every
  /// failure mode (no provider configured, malformed model output)
  /// resolves to [_fallback] instead, since a drafting step failing
  /// shouldn't block bot creation outright when the plain form
  /// (CreateBotPage) is right there as a fallback path anyway.
  Future<DraftedBot> draftFromDescription(String description) async {
    try {
      final result = await _ai.complete(
        systemPrompt: _systemPrompt,
        userMessage: description,
        maxTokens: 300,
      );
      return _parse(result.text, description);
    } catch (_) {
      return _fallback(description);
    }
  }

  DraftedBot _parse(String raw, String description) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return _fallback(description);
      }

      final decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! Map) return _fallback(description);

      final name = (decoded['name'] as String?)?.trim();
      final archetype = (decoded['archetype'] as String?)?.trim();
      final knowledgeSeed = (decoded['knowledgeSeed'] as String?)?.trim();

      return DraftedBot(
        name: (name != null && name.isNotEmpty)
            ? name
            : _fallbackName(description),
        archetype: _validArchetypes.contains(archetype)
            ? archetype!
            : 'customerCare',
        knowledgeSeed: (knowledgeSeed != null && knowledgeSeed.isNotEmpty)
            ? knowledgeSeed
            : null,
      );
    } catch (_) {
      return _fallback(description);
    }
  }

  DraftedBot _fallback(String description) => DraftedBot(
    name: _fallbackName(description),
    archetype: 'customerCare',
    knowledgeSeed: null,
  );

  /// A plain, deterministic name when the model is unavailable or its
  /// output can't be parsed — the first few words of the description,
  /// title-cased, so it's at least recognizable to the owner rather than
  /// a bare "New Bot" every time.
  String _fallbackName(String description) {
    final words = description.trim().split(RegExp(r'\s+')).take(4).join(' ');
    if (words.isEmpty) return 'New Bot';
    return words[0].toUpperCase() + words.substring(1);
  }
}
