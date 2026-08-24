// connector_capability_registry.dart — Connect Gate, subphase 4b/4c.
//
// THE CORRECTION THIS FILE IMPLEMENTS: connector-native capabilities
// (collecting a payment, booking a calendar event, and whatever comes
// next) must be available to a workspace's one agent the moment the
// connector is CONNECTED, full stop — never gated behind a business
// having explicitly registered an Errand for it. Before this file,
// 'collectPayment' and 'bookCalendarEvent' only became callable tools if
// a real `Errand` row existed with that builtinHandlerKey, which meant a
// business could connect Paystack and STILL have an agent that can't
// take a payment, because nobody separately created the Errand. That was
// backwards: connecting the tool IS the configuration step, there is no
// second one to skip.
//
// HOW: this mirrors errand_tool_registry.dart's `escalate_to_human`
// precedent — a capability that's added to the tool list without a
// backing Errand row — but per-connector instead of platform-wide.
// Rather than inventing a second code path parallel to
// ErrandToolRegistry/BuiltinErrandExecutor/ErrandDispatchService (all of
// which already know how to turn an `Errand` into a described AiTool and
// dispatch it), this builds SYNTHETIC, never-persisted `Errand` objects
// on the fly, one per connected capability, and hands them to the exact
// same machinery real Errands go through. `id` is negative and drawn
// from a small fixed, per-capability constant — never collides with a
// real Errand's serial primary key (always positive) — so
// ErrandToolRegistry.findErrandForToolName and
// ErrandDispatchService.dispatch work on a synthetic Errand with zero
// changes to either.
//
// WHAT THIS DELIBERATELY DOES NOT TOUCH: the `errands` table and every
// genuinely custom Errand a business registers (webhook, dbCredential,
// mcp, or a custom builtin) keep working exactly as before — this file
// only adds MORE tools to the list InboundMessageHandler already builds,
// it does not replace or gate anything that already worked.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/workspace_connector_repository.dart';
import 'package:kola_server/src/services/repository/payment_gateway_credential_repository.dart';

/// Reserved, negative Errand.id values for synthetic connector-capability
/// tools — see this file's header on why negative. Never persisted, so
/// there's no risk of ever colliding with a real serial id.
class SyntheticErrandIds {
  const SyntheticErrandIds._();
  static const int collectPayment = -1;
  static const int bookCalendarEvent = -2;
  static const int checkRecentTransactions = -3;
}

class ConnectorCapabilityRegistry {
  ConnectorCapabilityRegistry({
    required WorkspaceConnectorRepository connectors,
    required PaymentGatewayCredentialRepository paymentGateways,
  })  : _connectors = connectors,
        _paymentGateways = paymentGateways;

  final WorkspaceConnectorRepository _connectors;
  final PaymentGatewayCredentialRepository _paymentGateways;

  /// The synthetic Errands for whatever connector-native capabilities
  /// [workspaceId] currently has connected — empty if none. Callers
  /// concatenate this with the workspace's real, custom Errands
  /// (ErrandRepository.listActiveByWorkspace) before handing the
  /// combined list to ErrandToolRegistry.buildTools /
  /// findErrandForToolName, so the model sees one unified tool list and
  /// dispatch works unchanged either way.
  Future<List<Errand>> forWorkspace(int workspaceId) async {
    final now = DateTime.now();
    final capabilities = <Errand>[];

    // Paystack/Flutterwave live in the separate paymentGateway store
    // (payment_gateway_credentials), not workspace_connectors — see
    // payment_gateway_credential.spy.yaml's header: presence of a row IS
    // the connected state, there's no separate status column.
    final gateways = await _paymentGateways.listByWorkspace(workspaceId);
    if (gateways.isNotEmpty) {
      capabilities.add(_synthetic(
        id: SyntheticErrandIds.collectPayment,
        workspaceId: workspaceId,
        name: 'Collect payment',
        descriptionForAi:
            'Collect a payment from the customer through the business\'s '
            'connected payment gateway. Use this when the customer has '
            'agreed to pay for something and you know the amount.',
        builtinHandlerKey: 'collectPayment',
        now: now,
      ));

      // Found 2026-08-24: WorkspaceAnswerService (the owner-dashboard
      // assistant) could tell the owner "Paystack: connected" via
      // _connectorDigest, but had no way to actually read a transaction
      // row — collectPayment only INITIATES a new checkout, it cannot
      // look one up. A question like "check my paystack transaction" had
      // no tool that could answer it, so the model correctly reported it
      // had no path to the data, which read as a refusal. This closes
      // that gap the same way every other connector-native capability
      // is closed: gated on the connector actually being connected,
      // read-only, backed by PaymentTransactionRepository directly
      // rather than any gateway API call (payment_transactions is
      // kolaa's own synced+created record, already the source of truth).
      capabilities.add(_synthetic(
        id: SyntheticErrandIds.checkRecentTransactions,
        workspaceId: workspaceId,
        name: 'Check recent transactions',
        descriptionForAi:
            'Look up the business\'s recent payment transactions, or one '
            'specific transaction by its reference, from its connected '
            'payment gateway. Use this whenever the owner asks about a '
            'payment, an order\'s payment status, or wants to see recent '
            'transactions — do not guess or invent transaction details.',
        builtinHandlerKey: 'checkRecentTransactions',
        now: now,
      ));
    }

    final calendar = await _connectors.findByWorkspaceAndKey(workspaceId, 'google_calendar');
    if (calendar != null && calendar.status == 'connected') {
      capabilities.add(_synthetic(
        id: SyntheticErrandIds.bookCalendarEvent,
        workspaceId: workspaceId,
        name: 'Book calendar event',
        descriptionForAi:
            'Book an appointment or delivery slot on the business\'s '
            'connected calendar. Use this when the customer has agreed on '
            'a specific date and time.',
        builtinHandlerKey: 'bookCalendarEvent',
        now: now,
      ));
    }

    return capabilities;
  }

  Errand _synthetic({
    required int id,
    required int workspaceId,
    required String name,
    required String descriptionForAi,
    required String builtinHandlerKey,
    required DateTime now,
  }) {
    return Errand(
      id: id,
      workspaceId: workspaceId,
      name: name,
      descriptionForAi: descriptionForAi,
      source: 'builtin',
      builtinHandlerKey: builtinHandlerKey,
      createdVia: 'api',
      permissionScope: 'readOnly',
      inputSchemaJson: '{}',
      sensitiveInputKeysJson: '[]',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
  }
}
