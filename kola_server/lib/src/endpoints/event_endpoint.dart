// event_endpoint.dart — Phase 14/174. Backs `/timeline`: nav_model.dart
// has pointed 'Timeline' at this route since it was written, but no
// EventEndpoint existed anywhere (confirmed via glob:
// `endpoints/event*.dart` — zero matches) and no page backed it
// (confirmed via grep: zero matches for '/timeline' in app.dart).
// EventRepository already existed (Gate 2, migration 037) and
// event_bus.dart has been writing real rows to it ever since — this
// endpoint is the first thing that reads them back out for a human to
// look at, rather than for replay or webhook fan-out.
//
// ── CATEGORY MAPPING: WHAT HAS REAL EMIT-CALL EVIDENCE, WHAT DOESN'T ────
//
// grep for `_events.emit(` across the whole of kola_server found NINE
// real eventType strings actually fired from production code paths —
// more than event.spy.yaml's own doc comment lists (it names only six;
// left uncorrected there, out of scope for this pass, but worth
// knowing it under-counts). Every one below has a real call site:
//
//   sale_completed                   → Payments      (sale_endpoint
//                                       .dart, bumpa_adapter.dart)
//   payment_confirmed                → Payments      (manual_payment_
//                                       service.dart, payment_webhook_
//                                       handler.dart, + 4 gateway
//                                       adapters: fincra/flutterwave/
//                                       monnify/paystack)
//   new_conversation                 → Conversations (inbound_message_
//                                       handler.dart)
//   message_sent                     → Conversations (outbound_message_
//                                       service.dart)
//   agent_drafted / agent_published /
//   agent_paused                     → Integrations  (agent_lifecycle_
//                                       events.dart — "agent" is the
//                                       product-facing rename of "bot",
//                                       see that file's own header)
//   errand_executed                  → Operations    (errand_dispatch_
//                                       service.dart)
//   errand_rows_mapped_to_customers  → Customers     (errand_row_
//                                       customer_mapper.dart)
//
// NOT ONE real event exists yet for Inventory or Knowledge — no emit
// call anywhere in this codebase fires when stock changes or a document
// is taught. Both chips are still offered client-side (the design names
// them) but will honestly return an empty list until a future gate adds
// those emit calls. Named here rather than inventing a plausible-looking
// inventory event to make the chip feel populated.
//
// ── WHY THIS RETURNS THE RAW Event MODEL, NOT A NEW WIRE TYPE ───────────
//
// A dedicated TimelineEntry output type (title/category/dot color/
// formatted amount, precomputed server-side) would mean a brand-new
// generated model class on both sides of the wire — in a codebase with
// no working `serverpod generate` in this environment (hand-edited
// generated/ output is this project's own precedent for that — see
// endpoints.dart/client.dart's own edits alongside this file), that is
// real risk for no real benefit: every one of those fields is either
// already on Event or trivially derived from eventType + payloadJson.
// timeline_page.dart does that one small switch client-side instead.
// Category FILTERING still happens here, server-side, over the
// workspace's full set — so the type→category table has exactly one
// source of truth (this file), not two copies quietly able to drift.

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/event_repository.dart';

/// The category a given real eventType belongs to, per this file's own
/// header. NOTE: intelligence_endpoint.dart's own "Correlation spotted"
/// check does NOT read this table or the event bus at all — it uses
/// Conversation.status == 'escalated' directly (this codebase's one
/// real complaint/escalation signal; see that file's own header for
/// why). Named here only to avoid the wrong assumption that every
/// cross-feature signal in this codebase routes through events.
const categoryByEventType = <String, String>{
  'sale_completed': 'Payments',
  'payment_confirmed': 'Payments',
  'new_conversation': 'Conversations',
  'message_sent': 'Conversations',
  'agent_drafted': 'Integrations',
  'agent_published': 'Integrations',
  'agent_paused': 'Integrations',
  'errand_executed': 'Operations',
  'errand_rows_mapped_to_customers': 'Customers',
};

class EventEndpoint extends Endpoint {
  EventRepository get _events => getIt<EventRepository>();

  /// [category] is one of the design's chip labels — 'Payments',
  /// 'Inventory', 'Operations', 'Conversations', 'Knowledge',
  /// 'Integrations', 'Customers' — or null/omitted/'All' for
  /// everything. An unrecognized category, or one with zero real event
  /// types mapped to it (Inventory, Knowledge — see this file's
  /// header), returns an empty list rather than throwing: a filter
  /// that legitimately matches nothing is the honest state for a
  /// two-week-old workspace, not an error.
  ///
  /// Newest first — a human reading a timeline wants what just
  /// happened at the top; EventRepository's default ordering
  /// (`ascending: true`) exists for the replay use case, not this one.
  Future<List<Event>> listTimeline(
    Session session,
    String accessToken,
    int workspaceId, {
    String? category,
    int limit = 100,
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    if (category == null || category.isEmpty || category == 'All') {
      return _events.listByWorkspace(
        workspaceId: workspaceId,
        limit: limit,
        ascending: false,
      );
    }

    // Filtering by category (as opposed to a single eventType) means
    // fetching the wider set and narrowing in memory — the repository
    // only ever filters by one exact eventType at a time (see its own
    // `eventType` param), and a category can map to several. `limit`
    // still bounds the read itself; a workspace old enough to have more
    // than [limit] events of ONE category in its most recent [limit]
    // rows overall is a real future scaling question, not one this
    // pass needs to solve.
    final all = await _events.listByWorkspace(
      workspaceId: workspaceId,
      limit: limit,
      ascending: false,
    );
    return all.where((e) => categoryByEventType[e.eventType] == category).toList();
  }
}
