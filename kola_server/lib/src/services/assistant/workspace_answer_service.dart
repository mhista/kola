// workspace_answer_service.dart — kola answering the OWNER.
//
// ── WHAT THIS REPLACES ───────────────────────────────────────────────
//
// The Overview's "Ask kola" box called KnowledgeEndpoint.searchMemory and
// printed the retrieved chunks verbatim. There was no model in the path
// at all. What an owner saw was raw document text — markdown asterisks,
// half-sentences from a chunk boundary, the same passage twice when a
// document had been saved twice.
//
// It was honestly labelled in its own source ("deliberately NOT dressed
// up as conversational AI") and still read, on screen, as a broken AI.
//
// ── THE SHAPE, AND WHY IT IS NOT JUST "ASK THE MODEL" ────────────────
//
//   question
//     ├─ memory retrieval        the owner's own documents
//     ├─ catalog digest          what they actually sell
//     └─ model ──▶ tool call ──▶ { answer, product ids, intents }
//                                          │
//                                          └─ server resolves routes
//
// Two rules make this safe to put in front of an owner:
//
//   1. The model may POINT at products, never DESCRIBE them. It returns
//      ids; the dashboard loads those rows and renders real prices,
//      photos and stock. A hallucinated price cannot reach the screen,
//      because prose about a product is never the source of a number.
//
//   2. The model may CHOOSE an intent, never a URL. See
//      workspace_answer_action.spy.yaml — this codebase has already
//      shipped two links to routes that did not exist, by hand, and a
//      model cannot read the router.
//
// ── STRUCTURED OUTPUT VIA A TOOL CALL, NOT "RETURN JSON" ─────────────
//
// AiOrchestrator.completeWithTools already exists for Errands and every
// provider translates AiTool into its own function-calling format. Asking
// for JSON in the prompt instead would mean parsing whatever came back —
// including the ```json fences models love — and having no recourse when
// it is malformed.
//
// A single tool the model is told to always call is the standard way to
// get schema-shaped output from a chat model. The fallback still matters:
// completeWithTools returns text OR a tool call, so a model that ignores
// the instruction produces a plain answer with no products and no
// actions, which is degraded but correct.

import 'package:logging/logging.dart';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/ai/ai_orchestrator.dart';
import 'package:kola_server/src/services/ai/ai_provider.dart';
import 'package:kola_server/src/services/memory/memory_retrieval_service.dart';
import 'package:kola_server/src/services/repository/product_repository.dart';

// package:logging, like every other service here. `Log` (kola_logger.dart)
// is the ENDPOINT-layer helper — it takes a Session so an entry is
// attached to the request that caused it, and a service has no Session.
final _log = Logger('WorkspaceAnswerService');

class WorkspaceAnswerService {
  WorkspaceAnswerService({
    required AiOrchestrator aiOrchestrator,
    required MemoryRetrievalService memory,
    required ProductRepository products,
  })  : _ai = aiOrchestrator,
        _memory = memory,
        _products = products;

  final AiOrchestrator _ai;
  final MemoryRetrievalService _memory;
  final ProductRepository _products;

  /// The tool the model is asked to call. One tool, always called —
  /// which is how a chat model is made to emit a fixed schema.
  static const _toolName = 'reply_to_owner';

  // ── THE CLOSED INTENT VOCABULARY ───────────────────────────────────
  //
  // Every route here is one this app actually registers. When a screen is
  // added, it is added here; when one is renamed, this map is the single
  // place that changes and every previously-generated action keeps
  // resolving.
  //
  // Deliberately NOT including anything gated or unbuilt. An action
  // pointing at a locked feature is a dead end wearing a helpful face,
  // which is the specific failure this vocabulary exists to prevent.
  static const kIntents = <String, String>{
    'open_catalog': '/catalog',
    'add_product': '/catalog',
    'import_products': '/catalog/import',
    'view_product': '/catalog', // + /<id>, appended below
    'open_knowledge': '/knowledge',
    'add_knowledge': '/knowledge',
    'open_operations': '/operations',
    'open_agents': '/bots',
    'open_integrations': '/integrations',
    'open_settings': '/settings',
  };

  /// What each intent is FOR, in the model's words rather than ours.
  ///
  /// This text goes into the prompt. It is the only thing standing
  /// between "suggest something relevant" and a model that offers
  /// "Open Settings" after every question.
  static const _intentHelp = <String, String>{
    'open_catalog': 'show the full product list',
    'add_product': 'create a new product',
    'import_products': 'bring in many products from a spreadsheet',
    'view_product': 'open ONE specific product — requires product_id',
    'open_knowledge': 'see what kola has been taught',
    'add_knowledge': 'teach kola something new, such as a policy or FAQ',
    'open_operations': 'read customer conversations',
    'open_agents': 'configure the agents that reply to customers',
    'open_integrations': 'connect WhatsApp, Telegram or other channels',
    'open_settings': 'change business details',
  };

  /// How many products go into the prompt.
  ///
  /// A digest, not the catalog. Fifty products is a few thousand tokens;
  /// five hundred would blow the context window and cost real money on
  /// every question. Above this the honest answer is to retrieve the
  /// relevant subset rather than send everything, and this cap is where
  /// that work starts.
  static const _catalogDigestLimit = 60;

  Future<WorkspaceAnswer> ask({
    required int workspaceId,
    required String question,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return _fallback(
        'Ask me something about your business — what you sell, what you '
        'have taught me, or what a customer has asked.',
        const [],
      );
    }

    // Both reads before the model call, because the prompt needs them
    // and neither depends on the other.
    final retrieved = await _memory.retrieve(
      workspaceId: workspaceId,
      query: trimmed,
    );
    final catalog = await _catalogDigest(workspaceId);

    final citations = <KnowledgeSearchHit>[
      for (final m in retrieved.matches)
        KnowledgeSearchHit(
          chunkId: m.chunkId,
          documentId: m.documentId,
          documentTitle: m.documentTitle,
          chunkIndex: m.chunkIndex,
          content: m.content,
          similarity: m.similarity,
        ),
    ];

    // Nothing to answer FROM. Said plainly rather than sent to a model
    // that would then have to invent a way to say it.
    if (retrieved.matches.isEmpty && catalog.isEmpty) {
      return _fallback(
        "I have not been taught anything yet, so I cannot answer that from "
        "your own words.\n\n"
        "Add your products, or a document such as your delivery terms or "
        "returns policy, and ask me again.",
        const [
          ('add_knowledge', 'Teach kola something'),
          ('import_products', 'Import your products'),
        ],
      );
    }

    try {
      final result = await _ai.completeWithTools(
        systemPrompt: _systemPrompt(
          memoryBlock: retrieved.promptBlock,
          catalog: catalog,
        ),
        userMessage: trimmed,
        tools: [_replyTool()],
      );

      final call = result.toolCall;
      if (call == null || call.toolName != _toolName) {
        // The model answered in prose instead of calling the tool. Not a
        // failure — the prose is the part that matters — so it is shown
        // with no products and no actions rather than discarded.
        final text = (result.text ?? '').trim();
        if (text.isEmpty) {
          return _fallback(_couldNotAnswer, _defaultActions(catalog));
        }
        return WorkspaceAnswer(
          answer: text,
          productIds: const [],
          actions: _resolve(const [], workspaceId, catalog),
          citations: citations,
          generated: true,
          providerName: result.providerName,
        );
      }

      return _fromToolCall(
        call: call,
        workspaceId: workspaceId,
        catalog: catalog,
        citations: citations,
        providerName: result.providerName,
      );
    } catch (e) {
      // Degrade, do not break. An owner asking a question during a
      // provider outage should get a usable screen and an honest note,
      // not a red error — and `generated: false` is how the dashboard
      // knows to say so.
      _log.warning('ask failed for workspace $workspaceId: $e');
      return _fallback(_couldNotAnswer, _defaultActions(catalog));
    }
  }

  static const _couldNotAnswer =
      "I could not put an answer together just now. Your information is "
      "safe — this is a problem on my side, not with anything you have "
      "saved. Try again in a moment.";

  // ── Prompt ──────────────────────────────────────────────────────────

  String _systemPrompt({
    required String memoryBlock,
    required List<_CatalogEntry> catalog,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        'You are kola, answering the OWNER of a small business inside '
        'their own dashboard. You are not talking to a customer.',
      )
      ..writeln()
      ..writeln(
        'Answer from the information below and nothing else. If it does '
        'not contain the answer, say so plainly and suggest where the '
        'owner could record it. Never invent a price, a stock number or a '
        'policy. Do not offer to "connect them with someone" — the owner '
        'IS that someone.',
      )
      ..writeln()
      ..writeln(
        'Write in plain sentences. You may use "- " bullets and **bold**. '
        'Do NOT use headings, tables, links, code blocks or any other '
        'markdown — they are not rendered and reach the owner as literal '
        'punctuation.',
      )
      ..writeln()
      ..writeln(
        'Do not list product details in your prose. When you refer to '
        'products, name them briefly and put their ids in product_ids — '
        'the dashboard shows each one as a card with its real photo, '
        'price and stock underneath your answer. Repeating those numbers '
        'in text only risks contradicting them.',
      );

    if (catalog.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('--- PRODUCTS (id | name | category | price | stock) ---');
      for (final e in catalog) {
        buffer.writeln(e.promptLine);
      }
      if (catalog.length >= _catalogDigestLimit) {
        // Said in the prompt so the model can qualify its own answer
        // rather than confidently describing a partial list as complete.
        buffer.writeln(
          '(This is the first $_catalogDigestLimit products only, not the '
          'whole catalog. Say so if the question is about totals.)',
        );
      }
    }

    if (memoryBlock.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('--- WHAT THE OWNER HAS TAUGHT YOU ---')
        ..writeln(memoryBlock);
    }

    return buffer.toString();
  }

  AiTool _replyTool() => AiTool(
        name: _toolName,
        description:
            'Give your answer to the owner. Always call this exactly once.',
        parametersSchema: {
          'type': 'object',
          'properties': {
            'answer': {
              'type': 'string',
              'description':
                  'The reply, in plain sentences. Bullets with "- " and '
                      '**bold** are allowed; no other markdown.',
            },
            'product_ids': {
              'type': 'array',
              'items': {'type': 'integer'},
              'description':
                  'Ids of products this answer is about, most relevant '
                      'first. Only ids from the PRODUCTS list. Leave empty '
                      'if the question is not about specific products.',
            },
            'actions': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'intent': {
                    'type': 'string',
                    'enum': kIntents.keys.toList(),
                    'description': _intentHelp.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('; '),
                  },
                  'label': {
                    'type': 'string',
                    'description':
                        'Short button text, at most 5 words, phrased for '
                            'THIS answer. Prefer "See the 6 low on stock" '
                            'over "Open catalog".',
                  },
                  'product_id': {
                    'type': 'integer',
                    'description': 'Required for view_product only.',
                  },
                },
                'required': ['intent', 'label'],
              },
              'description':
                  'Up to 3 things the owner might do next, following from '
                      'what you just told them. Omit rather than pad — an '
                      'irrelevant button is worse than none.',
            },
          },
          'required': ['answer'],
        },
      );

  // ── Reading the model's answer back ────────────────────────────────

  WorkspaceAnswer _fromToolCall({
    required AiToolCall call,
    required int workspaceId,
    required List<_CatalogEntry> catalog,
    required List<KnowledgeSearchHit> citations,
    required String providerName,
  }) {
    final args = call.arguments;

    final answer = _asString(args['answer']).trim();

    // Every id checked against the digest we ourselves built. A model
    // inventing id 9999, or echoing one from another workspace's
    // conversation, gets it dropped here rather than turned into a card
    // the owner cannot open.
    //
    // `seen` is a LOCAL, not a field. This service is a lazy singleton,
    // so an instance-level dedupe set would persist between requests and
    // silently swallow a product the previous question had mentioned —
    // an answer missing a card for no visible reason, and only for the
    // second person to ask.
    final known = {for (final e in catalog) e.id};
    final seen = <int>{};
    final productIds = <int>[
      for (final raw in _asList(args['product_ids']))
        if (_asInt(raw) case final id?)
          if (known.contains(id) && seen.add(id)) id,
    ];

    final actions = <({String intent, String label, int? productId})>[
      for (final raw in _asList(args['actions']))
        if (raw is Map)
          (
            intent: _asString(raw['intent']),
            label: _asString(raw['label']),
            productId: _asInt(raw['product_id']),
          ),
    ];

    return WorkspaceAnswer(
      answer: answer.isEmpty ? _couldNotAnswer : answer,
      productIds: productIds,
      actions: _resolve(actions, workspaceId, catalog),
      citations: citations,
      generated: true,
      providerName: providerName,
    );
  }

  /// Turns model intents into real routes, dropping anything unknown.
  List<WorkspaceAnswerAction> _resolve(
    List<({String intent, String label, int? productId})> raw,
    int workspaceId,
    List<_CatalogEntry> catalog,
  ) {
    final known = {for (final e in catalog) e.id};
    final out = <WorkspaceAnswerAction>[];

    for (final a in raw) {
      final base = kIntents[a.intent];
      // An intent we do not recognise is DROPPED, not guessed at. The
      // cost is a missing button; the cost of guessing is a dead link.
      if (base == null) continue;

      var route = base;
      int? productId;

      if (a.intent == 'view_product') {
        final id = a.productId;
        // A product action with no valid product is not a weaker action,
        // it is a broken one.
        if (id == null || !known.contains(id)) continue;
        route = '/catalog/$id';
        productId = id;
      }

      if (out.any((e) => e.route == route)) continue;

      final label = a.label.trim();
      out.add(WorkspaceAnswerAction(
        intent: a.intent,
        // A model asked for a button label occasionally writes a
        // sentence. Truncated rather than rejected — the intent is still
        // good, and a button is not where you find out.
        label: label.isEmpty
            ? _fallbackLabel(a.intent)
            : (label.length > 42 ? '${label.substring(0, 41)}…' : label),
        route: route,
        productId: productId,
      ));

      if (out.length == 3) break;
    }
    return out;
  }

  static String _fallbackLabel(String intent) => switch (intent) {
        'open_catalog' || 'add_product' => 'Open your catalog',
        'import_products' => 'Import products',
        'view_product' => 'Open this product',
        'open_knowledge' || 'add_knowledge' => 'Open Knowledge',
        'open_operations' => 'Open Operations',
        'open_agents' => 'Open Agents',
        'open_integrations' => 'Open Integrations',
        _ => 'Open Settings',
      };

  WorkspaceAnswer _fallback(
    String text,
    List<(String, String)> intents,
  ) =>
      WorkspaceAnswer(
        answer: text,
        productIds: const [],
        actions: [
          for (final (intent, label) in intents)
            if (kIntents[intent] case final route?)
              WorkspaceAnswerAction(
                intent: intent,
                label: label,
                route: route,
              ),
        ],
        citations: const [],
        // FALSE, and this matters. It is how the dashboard can tell the
        // owner "this one is not from the model" during an outage
        // instead of letting a canned line pass as an answer.
        generated: false,
        providerName: 'none',
      );

  List<(String, String)> _defaultActions(List<_CatalogEntry> catalog) => [
        if (catalog.isEmpty)
          ('import_products', 'Import your products')
        else
          ('open_catalog', 'Open your catalog'),
        ('open_knowledge', 'See what kola knows'),
      ];

  // ── Catalog digest ──────────────────────────────────────────────────

  Future<List<_CatalogEntry>> _catalogDigest(int workspaceId) async {
    try {
      final products =
          await _products.listByWorkspace(workspaceId, includeArchived: false);
      return [
        for (final p in products.take(_catalogDigestLimit))
          if (p.id != null)
            _CatalogEntry(
              id: p.id!,
              name: p.name,
              category: p.category,
              priceMinor: p.priceMinor,
              currency: p.priceCurrency,
              stock: p.stock,
            ),
      ];
    } catch (e) {
      // A question about policies should still be answerable when the
      // catalog read fails.
      _log.warning('catalog digest failed for $workspaceId: $e');
      return const [];
    }
  }

  // ── Coercion ────────────────────────────────────────────────────────
  //
  // Tool arguments are UNVALIDATED — ai_provider.dart says so explicitly.
  // Providers differ on whether an integer arrives as int, double or a
  // string, so every read goes through these rather than a cast that
  // works against one provider and throws against another.

  static String _asString(Object? v) => v is String ? v : (v?.toString() ?? '');

  static List<Object?> _asList(Object? v) => v is List ? v : const [];

  static int? _asInt(Object? v) => switch (v) {
        int i => i,
        double d => d.toInt(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };
}

class _CatalogEntry {
  const _CatalogEntry({
    required this.id,
    required this.name,
    this.category,
    this.priceMinor,
    required this.currency,
    this.stock,
  });

  final int id;
  final String name;
  final String? category;
  final int? priceMinor;
  final String currency;
  final int? stock;

  /// One line per product, pipe-separated.
  ///
  /// Minor units are converted here because a model shown "450000" will
  /// repeat "450000" to the owner. Null price is written "by quote" and
  /// null stock "not stocked" — the words the rest of the product means
  /// by them, so the model does not read a blank as zero and tell an
  /// owner their tailoring service is out of stock.
  String get promptLine {
    final price = priceMinor == null
        ? 'by quote'
        : '$currency ${(priceMinor! / 100).toStringAsFixed(2)}';
    final stockText = stock == null ? 'not stocked' : '$stock';
    return '$id | $name | ${category ?? 'uncategorised'} | $price | $stockText';
  }
}
