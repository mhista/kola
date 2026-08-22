// paystack_adapter.dart — Gate 4. The first real implementation of
// ConnectorAdapter (contract/connector_adapter.dart), proving the
// pull-based half of the connector contract Gate 1 only scaffolded.
// See migration 040's header for why payment_gateway_credentials needed
// its own sync_cursor column before this could exist at all.
//
// WHAT THIS ADDS THAT THE WEBHOOK PATH DOESN'T HAVE: PaymentWebhookHandler
// is reactive-only — it learns about a payment the instant Paystack
// pushes charge.success, and nothing else. Two real gaps that leaves:
// (1) a business connecting Paystack for the first time has months of
// existing transaction history the webhook never saw, and (2) a webhook
// delivery that Paystack's retry policy eventually gives up on is a
// payment kola never learns about at all. [sync] closes both — it walks
// the account's own transaction/customer history directly, so a missed
// or late webhook is simply re-confirmed on the next sweep rather than
// permanently lost.
//
// WHY THIS DOES NOT DUPLICATE PaymentWebhookHandler'S LOGIC: both paths
// converge on the exact same two operations —
// PaymentTransactionRepository (upsertFromSync here, markCompleted
// there) and CustomerIdentityResolver.resolve — and both emit the SAME
// 'payment_confirmed:$transactionId' event fingerprint, so whichever
// path sees a given transaction first does the real work and the second
// is a deduplicated no-op at the EventBus layer (migration 037's unique
// index on (workspace_id, fingerprint)). Neither path needs to know the
// other ran.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/billing/paystack_service.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';

class PaystackAdapter implements ConnectorAdapter {
  PaystackAdapter({required this.workspaceId, required PaystackService service})
      : _service = service;

  final int workspaceId;
  final PaystackService _service;

  PaymentTransactionRepository get _transactions =>
      getIt<PaymentTransactionRepository>();
  CustomerIdentityResolver get _customerIdentity =>
      getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  static const _pageSize = 100;
  // A hard ceiling on pages per run, not a real expectation of hitting
  // it — a workspace with genuinely more than 500 pages of NEW
  // transactions since its last sync (50,000+ at this page size) will
  // finish the rest on the next sweep rather than this call running
  // forever. Bounded loops over an external API are non-negotiable.
  static const _maxPages = 500;

  @override
  String get connectorKey => 'paystack';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        supportsIncrementalSync: true,
        supportsPagination: true,
        // Paystack has no published fixed rate limit for these endpoints
        // at the time this was written — left null so the shared
        // retry/backoff layer falls back to its own conservative
        // default rather than this adapter guessing at a number.
        isPushDriven: false,
      );

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    final since = cursor.isEmpty ? null : DateTime.tryParse(cursor.value as String? ?? '');

    var seen = 0;
    var changed = 0;
    final errors = <String>[];
    DateTime? newestSeen = since;

    // ── Transactions ──────────────────────────────────────────────────
    var page = 1;
    while (page <= _maxPages) {
      final result = await _service.listTransactions(
        from: since,
        page: page,
        perPage: _pageSize,
      );
      final rows = (result['data'] as List?) ?? const [];
      if (rows.isEmpty) break;

      for (final row in rows) {
        seen++;
        try {
          final wasNewOrChanged = await _upsertTransaction(row as Map<String, dynamic>);
          if (wasNewOrChanged) changed++;

          final createdAt = DateTime.tryParse(row['created_at'] as String? ?? '');
          if (createdAt != null && (newestSeen == null || createdAt.isAfter(newestSeen))) {
            newestSeen = createdAt;
          }
        } catch (e) {
          errors.add('transaction ${row['reference']}: $e');
          Log.warning('PaystackAdapter: failed to process transaction row: $e');
        }
      }

      if (rows.length < _pageSize) break; // last page
      page++;
    }

    // ── Customers ─────────────────────────────────────────────────────
    // A separate pass, not derived from the transactions above — a
    // customer Paystack knows about but who has never completed a
    // transaction (an abandoned checkout, a customer record created
    // ahead of a first recurring charge) still belongs in the graph.
    page = 1;
    while (page <= _maxPages) {
      final result = await _service.listCustomers(from: since, page: page, perPage: _pageSize);
      final rows = (result['data'] as List?) ?? const [];
      if (rows.isEmpty) break;

      for (final row in rows) {
        seen++;
        try {
          final wasNew = await _resolveCustomer(row as Map<String, dynamic>);
          if (wasNew) changed++;
        } catch (e) {
          errors.add('customer ${row['customer_code']}: $e');
          Log.warning('PaystackAdapter: failed to process customer row: $e');
        }
      }

      if (rows.length < _pageSize) break;
      page++;
    }

    return SyncResult(
      recordsSeen: seen,
      recordsChanged: changed,
      nextCursor: SyncCursor(newestSeen?.toIso8601String()),
      errors: errors,
    );
  }

  /// Returns true if this transaction was newly written as 'completed'
  /// (i.e. actually moved the needle), false if it was already known —
  /// [SyncResult.recordsChanged] wants the former, not every row touched.
  Future<bool> _upsertTransaction(Map<String, dynamic> row) async {
    final status = row['status'] as String?;
    if (status != 'success') return false; // only real payments belong in the graph

    final reference = row['reference'] as String?;
    if (reference == null) return false;

    final customer = (row['customer'] as Map<String, dynamic>?) ?? const {};
    final email = customer['email'] as String? ?? '';
    final phone = customer['phone'] as String?;

    final before = await _transactions.findByReference(reference);
    final alreadyCompleted = before?.status == 'completed';

    final txn = await _transactions.upsertFromSync(
      workspaceId: workspaceId,
      gateway: 'paystack',
      reference: reference,
      amountKobo: row['amount'] as int? ?? 0,
      currency: row['currency'] as String? ?? 'NGN',
      customerEmail: email,
      customerPhone: (phone == null || phone.isEmpty) ? null : phone,
      status: 'completed',
      gatewayTransactionId: row['id']?.toString(),
      paidAt: DateTime.tryParse(row['paid_at'] as String? ?? ''),
    );

    final txnId = txn.id;
    if (txnId == null) return !alreadyCompleted;

    if (txn.customerId == null) {
      final primary = txn.customerPhone != null
          ? IdentitySignal(
              type: 'phone',
              value: CustomerIdentityResolver.normalizePhone(txn.customerPhone!),
              sourceRef: reference,
            )
          : IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(txn.customerEmail),
              sourceRef: reference,
            );
      final secondary = txn.customerPhone != null
          ? IdentitySignal(
              type: 'email',
              value: CustomerIdentityResolver.normalizeEmail(txn.customerEmail),
              sourceRef: reference,
            )
          : null;

      final customerId = await _customerIdentity.resolve(
        workspaceId: workspaceId,
        primary: primary,
        secondary: secondary,
        source: 'paystack',
      );
      if (customerId != null) {
        await _transactions.setCustomer(txnId, customerId);
      }
    }

    // Same fingerprint PaymentWebhookHandler uses — deduplicated at the
    // EventBus layer if the webhook already emitted this one. See this
    // file's header.
    await _events.emit(
      workspaceId: workspaceId,
      eventType: 'payment_confirmed',
      fingerprint: 'payment_confirmed:$txnId',
      payload: {
        'transactionId': txnId,
        'workspaceId': workspaceId,
        'gateway': 'paystack',
        'reference': reference,
        'amountKobo': txn.amountKobo,
        'currency': txn.currency,
        'conversationId': txn.conversationId,
        'source': 'sync', // distinguishes a backfilled event from a live webhook, for anyone reading the timeline later
      },
      occurredAt: txn.paidAt ?? DateTime.now(),
    );

    return !alreadyCompleted;
  }

  /// Returns true if this customer resolved to a NEW Customer/signal
  /// (see CustomerIdentityResolver.resolve's own return contract) rather
  /// than matching one that already existed.
  Future<bool> _resolveCustomer(Map<String, dynamic> row) async {
    final email = row['email'] as String?;
    final phone = row['phone'] as String?;
    if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      return false; // nothing to resolve identity from
    }

    final customerCode = row['customer_code'] as String?;
    final primary = (phone != null && phone.isNotEmpty)
        ? IdentitySignal(
            type: 'phone',
            value: CustomerIdentityResolver.normalizePhone(phone),
            sourceRef: customerCode,
          )
        : IdentitySignal(
            type: 'email',
            // Safe: the guard above already returned false if BOTH email
            // and phone were null/empty, so reaching this branch (phone
            // null/empty) proves email is non-null/non-empty — Dart's
            // flow analysis just can't see that across the compound `&&`
            // in a separate statement, hence the explicit `!`.
            value: CustomerIdentityResolver.normalizeEmail(email!),
            sourceRef: customerCode,
          );
    final secondary = (phone != null && phone.isNotEmpty && email != null && email.isNotEmpty)
        ? IdentitySignal(
            type: 'email',
            value: CustomerIdentityResolver.normalizeEmail(email),
            sourceRef: customerCode,
          )
        : null;

    final customerId = await _customerIdentity.resolve(
      workspaceId: workspaceId,
      primary: primary,
      secondary: secondary,
      source: 'paystack',
    );
    // resolve() itself does not report new-vs-matched; conservatively
    // count every successful resolution toward recordsChanged rather
    // than adding a second query just to distinguish them for a metric
    // nothing downstream depends on being exact.
    return customerId != null;
  }

  // `implements` (not `extends`) means ConnectorAdapter's own default
  // body for this getter is NOT inherited — only its signature is. Must
  // be declared explicitly even though the value matches the default;
  // omitting it is exactly the compile error this fixes.
  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<ConnectorHealth> health() async {
    try {
      await _service.probe();
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not reach Paystack with the stored key — it may have been rotated or revoked on their end. ($e)',
      );
    }
  }
}
