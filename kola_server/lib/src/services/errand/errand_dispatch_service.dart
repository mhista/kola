// errand_dispatch_service.dart
//
// TASK #134 — the caller-agnostic core of what ErrandEndpoint.executeErrand
// used to inline directly: given an Errand and an input map, pick the
// right executor by errand.source and run it. Extracted for the exact
// same reason payment_checkout_service.dart was extracted out of
// PaymentEndpoint at task #128 — ErrandEndpoint.executeErrand requires a
// Session (via requireWorkspaceAccess), but the new AI tool-calling engine
// (inbound_message_handler.dart, running inside an already-trusted,
// already-resolved workspace/bot context) has no Session to present and
// shouldn't need one. Two callers, one implementation:
//   - ErrandEndpoint.executeErrand — Session-authenticated, external/
//     dashboard-triggered execution.
//   - InboundMessageHandler (via BotKnowledgeService's tool-call decision)
//     — already-trusted, internal, AI-triggered execution.
//
// WHAT THIS DOES NOT DO: it does not run SecurityFilter.checkErrandInput
// — that stays the caller's responsibility, same as before this
// extraction, since "before ANY Errand call" is a checkpoint that belongs
// right before dispatch is invoked, not buried inside it (both current
// callers already do this at their own call site).

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/errand/builtin_errand_executor.dart';
import 'package:kola_server/src/services/errand/webhook_errand_executor.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_executor.dart';
import 'package:kola_server/src/services/errand/errand_row_customer_mapper.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';

class ErrandDispatchService {
  ErrandDispatchService({
    required BuiltinErrandExecutor builtinExecutor,
    required WebhookErrandExecutor webhookExecutor,
    required DbCredentialErrandExecutor dbCredentialExecutor,
    required EventBus events,
    required ErrandRowCustomerMapper rowCustomerMapper,
  }) : _builtin = builtinExecutor,
       _webhook = webhookExecutor,
       _dbCredential = dbCredentialExecutor,
       _events = events,
       _rowCustomerMapper = rowCustomerMapper;

  final BuiltinErrandExecutor _builtin;
  final WebhookErrandExecutor _webhook;
  final DbCredentialErrandExecutor _dbCredential;
  final EventBus _events;
  final ErrandRowCustomerMapper _rowCustomerMapper;

  /// Runs [errand] with [input], dispatching to the right executor by
  /// errand.source. Does NOT check errand.status or run the security
  /// filter — callers must have already done both (ErrandEndpoint checks
  /// status+security before calling this; InboundMessageHandler only
  /// ever sees Errands from listActiveByWorkspace, so status is already
  /// implied, but still runs the security filter itself before calling
  /// this — see its own header).
  ///
  /// Gate 2 — emits 'errand_executed' on the event bus AFTER a
  /// successful run, never on failure (each executor already throws on
  /// failure, so a caught exception here never reaches the emit call —
  /// see the switch below). Fingerprint includes a microsecond
  /// timestamp, deliberately NOT just errand.id — two distinct
  /// executions of the same Errand are two distinct events, not a
  /// duplicate of each other, unlike agent_drafted/new_conversation
  /// where the fingerprint is meant to collapse repeats.
  Future<Map<String, dynamic>> dispatch({
    required Errand errand,
    required Map<String, dynamic> input,
  }) async {
    final result = switch (errand.source) {
      'builtin' => await _builtin.execute(errand: errand, input: input),
      'webhook' => await _webhook.execute(errand: errand, input: input),
      'dbCredential' => await _dbCredential.execute(errand: errand, input: input),
      _ => throw KolaException(
            message: 'This errand is set up in a way kola cannot run yet.'),
    };

    final errandId = errand.id;
    if (errandId != null) {
      final now = DateTime.now().toUtc();
      await _events.emit(
        workspaceId: errand.workspaceId,
        eventType: 'errand_executed',
        fingerprint: 'errand_executed:$errandId:${now.microsecondsSinceEpoch}',
        payload: {
          'errandId': errandId,
          'workspaceId': errand.workspaceId,
          'source': errand.source,
        },
        occurredAt: now,
      );
    }

    // Gate 5's second half — best-effort, AFTER the real result above is
    // already computed, and never allowed to change or delay what this
    // method returns to its caller (a conversation, or the dashboard's
    // "Test this Errand" button) beyond the mapping work itself. No-ops
    // instantly for the overwhelming majority of Errands, which have no
    // saved mapping — see ErrandRowCustomerMapper's header.
    await _rowCustomerMapper.applyIfMapped(
      workspaceId: errand.workspaceId,
      errand: errand,
      executionResult: result,
    );

    return result;
  }
}
