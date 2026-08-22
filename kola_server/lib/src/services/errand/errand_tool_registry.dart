// errand_tool_registry.dart
//
// TASK #134 — turns a workspace's active Errands into the [AiTool] list
// completeWithTools() actually offers the model. This is the concrete
// piece errand_repository.dart's listActiveByWorkspace doc comment
// already promised ("what the AI orchestrator will eventually load as
// the available-tools list per conversation... once tool-calling
// exists").
//
// TOOL NAMES ARE `errand_<id>`, NOT THE ERRAND'S OWN DISPLAY NAME: a
// stable, always-valid-as-an-identifier, always-unique name sidesteps
// sanitizing arbitrary business-chosen Errand names (spaces, emoji,
// duplicates across a workspace) entirely. The Errand's real name and
// descriptionForAi still reach the model — as the tool's `description`
// — which is what actually drives the model's choice of which tool to
// call and how; the `name` field is just a stable handle callers use to
// look the Errand back up after the model responds (see
// [ErrandToolRegistry.findErrandForToolName]).
//
// CONTEXT-INJECTED ARGUMENTS ARE DELIBERATELY EXCLUDED FROM THE MODEL'S
// SCHEMA: 'createSupportTicket' and 'recordCustomerProfile' both take a
// `conversationId` in their raw handler input (see
// builtin_errand_executor.dart), but the model has no business inventing
// one — InboundMessageHandler already knows which Conversation this is.
// [_contextInjectedKeys] is the per-handler-key set of arguments the
// model is never asked to supply; errand_dispatch_service.dart's caller
// (InboundMessageHandler) merges the real value in right before
// dispatching. Getting this list out of sync with
// builtin_errand_executor.dart's actual handlers is the one real risk
// here — each handler's own doc comment lists its required input keys,
// so cross-check there first if a handler's signature ever changes.
//
// TASK #154 — 'channelId' JOINS 'conversationId' AS A CONTEXT-INJECTED
// KIND, NOT JUST A KEY: 'createProductListTemplate' needs to know which
// of a business's channels to submit a Meta template against, and the
// model has no legitimate way to know a channel's numeric id. See
// InboundMessageHandler's merge loop, which now branches on both.
//
// A RESERVED, ALWAYS-AVAILABLE ESCALATION TOOL: 'escalate_to_human' is
// NOT built from any Errand — it's added to every tool list regardless
// of whether a workspace has ever registered a real 'escalateToHuman'
// builtin Errand (most haven't; nothing auto-provisions one — see
// bot.spy.yaml/errand_endpoint.dart, no workspace-creation flow creates
// this automatically). Escalation is a PLATFORM guarantee (PRD.md §6's
// customer-care requirement to "escalate what it can't answer"), not a
// business-configured feature that could silently be missing — this is
// what replaces bot_knowledge_service.dart's old sentinel-token hack for
// the new tool-calling path (that path is unchanged, for the old
// `answerGrounded` callers that still use it).
//
// CONNECTOR-NATIVE CAPABILITIES EXTEND THIS SAME PATTERN (2026-08-22):
// 'escalate_to_human' was the first tool with no backing Errand row;
// collectPayment and bookCalendarEvent now work the same way, EXCEPT
// they're conditional on connection state instead of unconditional —
// see connector_capability_registry.dart. That file builds real (but
// never-persisted) Errand objects for whatever capabilities a
// workspace's connected connectors currently grant, and
// InboundMessageHandler merges them into the same list this class
// already knows how to turn into tools and dispatch. This registry
// itself needed only one change for that: `bookCalendarEvent`'s entry
// in [_builtinParameterSchemas], since collectPayment's schema already
// existed for the (now removed) Errand-registration path. Errands
// proper — the DB-backed kind — stay reserved for genuinely custom,
// business-authored actions; see errand.spy.yaml's header.

import 'dart:convert';

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/ai/ai_provider.dart';

/// Reserved tool name for the platform's always-available escalation
/// path — never collides with an Errand-derived `errand_<id>` name.
const kEscalateToHumanToolName = 'escalate_to_human';

const _escalateToHumanTool = AiTool(
  name: kEscalateToHumanToolName,
  description:
      'Hand this conversation off to a human on the business\'s team. Call '
      'this whenever you don\'t have enough information to help, the '
      'customer is upset or explicitly asks for a person, or nothing else '
      'available can fulfill what they\'re asking for. Do not guess or '
      'invent an answer instead of calling this.',
  parametersSchema: {
    'type': 'object',
    'properties': {
      'reason': {
        'type': 'string',
        'description': 'Briefly, why this needs a human — what the customer asked for that nothing else could resolve.',
      },
    },
    'required': ['reason'],
  },
);

/// Per-builtinHandlerKey JSON Schema for the AI-visible arguments of each
/// registered handler in builtin_errand_executor.dart — see that file's
/// per-handler doc comments for the authoritative "input required/
/// optional" list this must stay in sync with. Deliberately excludes any
/// key listed in [_contextInjectedKeys] for the same handler.
const Map<String, Map<String, dynamic>> _builtinParameterSchemas = {
  'escalateToHuman': {
    'type': 'object',
    'properties': {
      'reason': {
        'type': 'string',
        'description': 'Why this needs a human.',
      },
    },
    'required': ['reason'],
  },
  'collectPayment': {
    'type': 'object',
    'properties': {
      'gateway': {
        'type': 'string',
        'enum': ['paystack', 'flutterwave'],
        'description': 'Which payment gateway this business has connected.',
      },
      'amountKobo': {
        'type': 'integer',
        'description': 'Amount to charge, in kobo (smallest currency unit) — e.g. 500000 for ₦5,000.',
      },
      'customerEmail': {
        'type': 'string',
        'description': "The customer's email address.",
      },
      'customerPhone': {
        'type': 'string',
        'description': "The customer's phone number, if known.",
      },
      'holdInEscrow': {
        'type': 'boolean',
        'description': 'Whether to hold this payment until the business releases it, rather than settling immediately.',
      },
    },
    'required': ['gateway', 'amountKobo', 'customerEmail'],
  },
  'createSupportTicket': {
    'type': 'object',
    'properties': {
      'subject': {
        'type': 'string',
        'description': 'A short summary of the complaint or request.',
      },
      'description': {
        'type': 'string',
        'description': "The complaint, in the customer's own words as closely as possible.",
      },
      'priority': {
        'type': 'string',
        'enum': ['low', 'medium', 'high', 'urgent'],
        'description': 'How urgent this is. Default to medium if unclear.',
      },
    },
    'required': ['subject', 'description'],
  },
  'recordCustomerProfile': {
    'type': 'object',
    'properties': {
      'birthday': {
        'type': 'string',
        'description': "Customer's birthday as an ISO-8601 date (YYYY-MM-DD).",
      },
      'anniversary': {
        'type': 'string',
        'description': "Customer's anniversary as an ISO-8601 date (YYYY-MM-DD).",
      },
    },
    'required': [],
  },
  'sendOtp': {
    'type': 'object',
    'properties': {
      'recipientEmail': {
        'type': 'string',
        'description': 'The email address to send the verification code to — must be an address the customer actually gave in this conversation.',
      },
    },
    'required': ['recipientEmail'],
  },
  'verifyOtp': {
    'type': 'object',
    'properties': {
      'code': {
        'type': 'string',
        'description': 'The verification code the customer just typed, exactly as they gave it.',
      },
    },
    'required': ['code'],
  },
  // Task #154 — see builtin_errand_executor.dart's _createProductListTemplate
  // doc comment. 'channelId' is deliberately absent here: it's the first
  // context-injected key that ISN'T 'conversationId' (see
  // _contextInjectedKeys below) — the model has no business picking which
  // of a business's channels to submit a Meta template against, and
  // InboundMessageHandler already knows.
  // 'bookCalendarEvent' — Connect Gate, subphase 4b. Schema for
  // builtin_errand_executor.dart's _bookCalendarEvent handler.
  // 'conversationId' is context-injected (see below), never asked of
  // the model. workspaceId isn't in this schema at all — the handler
  // reads it off the Errand itself (errand.workspaceId), real or
  // synthetic — see connector_capability_registry.dart.
  'bookCalendarEvent': {
    'type': 'object',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'A short title for the appointment/booking, e.g. "Consultation with Jane".',
      },
      'description': {
        'type': 'string',
        'description': 'Optional extra detail about what this booking is for.',
      },
      'startsAt': {
        'type': 'string',
        'description': 'Start time as an ISO-8601 datetime, e.g. 2026-08-25T14:00:00Z.',
      },
      'endsAt': {
        'type': 'string',
        'description': 'End time as an ISO-8601 datetime — must be after startsAt.',
      },
      'attendeeName': {
        'type': 'string',
        'description': "The customer's name, if known.",
      },
      'attendeeEmail': {
        'type': 'string',
        'description': "The customer's email address, if known — used to invite them on the calendar event.",
      },
      'attendeePhone': {
        'type': 'string',
        'description': "The customer's phone number, if known.",
      },
    },
    'required': ['title', 'startsAt', 'endsAt'],
  },
  'createProductListTemplate': {
    'type': 'object',
    'properties': {
      'productList': {
        'type': 'string',
        'description': 'The product list to send, formatted as plain text — compose this yourself from what you know about the business\'s catalog/knowledge base.',
      },
      'customerName': {
        'type': 'string',
        'description': "The customer's name, if known. Defaults to \"Customer\" if omitted.",
      },
    },
    'required': ['productList'],
  },
};

/// Arguments injected by InboundMessageHandler at dispatch time, per
/// builtinHandlerKey — never exposed to the model. See this file's
/// header.
const Map<String, Set<String>> _contextInjectedKeys = {
  'createSupportTicket': {'conversationId'},
  'recordCustomerProfile': {'conversationId'},
  'sendOtp': {'conversationId'},
  'verifyOtp': {'conversationId'},
  'createProductListTemplate': {'channelId'},
  'bookCalendarEvent': {'conversationId'},
};

/// Arguments a webhook/dbCredential Errand's flat `inputSchemaJson`
/// (`{"paramName": "typeName"}`, see errand.spy.yaml) declares, converted
/// into that same context-injection set — none today (a webhook/db
/// Errand's URL/query template already fully determine what it does;
/// there's no equivalent of "conversationId" those executors need
/// injected). Kept as an explicit empty set, not omitted, so a future
/// contextual argument for these types has an obvious place to go.
const Set<String> _nonBuiltinContextInjectedKeys = {};

class ErrandToolRegistry {
  const ErrandToolRegistry._();

  /// Builds the full tool list for one conversation turn: the reserved
  /// escalation tool, always, followed by one [AiTool] per Errand in
  /// [activeErrands] this registry knows how to describe. An Errand this
  /// registry can't build a schema for (unknown builtinHandlerKey, or a
  /// genuinely unsupported source) is skipped, not thrown on — a single
  /// mis-registered Errand must never take down every other tool a
  /// business has set up.
  static List<AiTool> buildTools(List<Errand> activeErrands) {
    final tools = <AiTool>[_escalateToHumanTool];
    for (final errand in activeErrands) {
      final tool = _toolFor(errand);
      if (tool != null) tools.add(tool);
    }
    return tools;
  }

  /// The context-injected argument keys InboundMessageHandler must merge
  /// into the model's supplied arguments before dispatching [errand] —
  /// see this file's header. Empty set if [errand] needs none.
  static Set<String> contextInjectedKeysFor(Errand errand) {
    if (errand.source == 'builtin') {
      return _contextInjectedKeys[errand.builtinHandlerKey] ?? const {};
    }
    return _nonBuiltinContextInjectedKeys;
  }

  /// Reverses [buildTools]'s naming convention — null for the reserved
  /// escalation tool name (callers must check that name first; it has no
  /// backing Errand row) or for a name that doesn't match any Errand in
  /// [activeErrands].
  static Errand? findErrandForToolName(String toolName, List<Errand> activeErrands) {
    if (toolName == kEscalateToHumanToolName) return null;
    // BUG FIXED HERE (2026-08-22): this regex was `^errand_(\d+)$` — \d+
    // cannot match a leading minus sign, so it could never parse the
    // NEGATIVE synthetic IDs connector_capability_registry.dart
    // deliberately uses (SyntheticErrandIds.bookCalendarEvent = -2,
    // .collectPayment = -1) to avoid colliding with real, positive
    // Errand row IDs. The model was offered 'errand_-2', correctly
    // chose to call it, and this method then silently returned null for
    // a tool name that plainly existed — the caller had no way to tell
    // "unknown tool" apart from "known tool, broken lookup," so it fell
    // all the way through to the generic "could not put an answer
    // together" fallback with no error anywhere. Every connector-native
    // capability (calendar booking, payment collection) was affected,
    // not just this one case — `-?` is the entire fix.
    final match = RegExp(r'^errand_(-?\d+)$').firstMatch(toolName);
    if (match == null) return null;
    final id = int.tryParse(match.group(1)!);
    if (id == null) return null;
    for (final errand in activeErrands) {
      if (errand.id == id) return errand;
    }
    return null;
  }

  static AiTool? _toolFor(Errand errand) {
    final id = errand.id;
    if (id == null) return null; // shouldn't happen for a persisted Errand, but never crash on it

    final schema = _schemaFor(errand);
    if (schema == null) return null;

    return AiTool(
      name: 'errand_$id',
      description: '${errand.name}: ${errand.descriptionForAi}',
      parametersSchema: schema,
    );
  }

  static Map<String, dynamic>? _schemaFor(Errand errand) {
    if (errand.source == 'builtin') {
      final key = errand.builtinHandlerKey;
      final base = key == null ? null : _builtinParameterSchemas[key];
      if (base == null) return null;
      return base; // already excludes context-injected keys, per-key above
    }

    if (errand.source == 'webhook' || errand.source == 'dbCredential') {
      return _schemaFromFlatInputSchema(errand.inputSchemaJson);
    }

    // 'mcp' has no create method yet (genuinely unimplemented, see
    // errand_endpoint.dart's header) — nothing to build a schema from.
    return null;
  }

  /// Converts the flat `{"paramName": "typeName"}` shape stored in
  /// Errand.inputSchemaJson (see errand.spy.yaml's header) into a real
  /// JSON Schema object. Every declared key is treated as required — the
  /// business declared exactly the fields this Errand needs, so there's
  /// no "optional-by-default" case to represent. An empty/unparseable
  /// declaration falls back to a permissive schema instead of a schema
  /// with zero usable properties, since a webhook Errand's own endpoint
  /// (not this registry) is what actually validates its payload — see
  /// webhook_errand_executor.dart, which forwards whatever JSON body it's
  /// given as-is.
  static Map<String, dynamic> _schemaFromFlatInputSchema(String inputSchemaJson) {
    Map<String, dynamic> flat;
    try {
      final decoded = jsonDecode(inputSchemaJson);
      flat = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      flat = <String, dynamic>{};
    }

    if (flat.isEmpty) {
      return {'type': 'object', 'properties': <String, dynamic>{}, 'additionalProperties': true};
    }

    final properties = <String, dynamic>{};
    for (final entry in flat.entries) {
      properties[entry.key] = {'type': _jsonSchemaType(entry.value?.toString())};
    }

    return {
      'type': 'object',
      'properties': properties,
      'required': flat.keys.toList(),
    };
  }

  static String _jsonSchemaType(String? declaredType) {
    switch (declaredType) {
      case 'int':
      case 'integer':
        return 'integer';
      case 'double':
      case 'number':
        return 'number';
      case 'bool':
      case 'boolean':
        return 'boolean';
      default:
        return 'string';
    }
  }

}
