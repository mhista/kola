// fincra_adapter.dart — Gate 11 (breadth). Fourth ConnectorAdapter for
// the paymentGateway store, same shape as paystack_adapter.dart/
// flutterwave_adapter.dart/monnify_adapter.dart — differences are
// exactly the differences between Fincra's real API and theirs, not
// stylistic drift. See fincra_service.dart's header for what was
// verified and what wasn't.
//
// NO CHECKOUT-INITIATION SIDE, SAME CUT AS MONNIFY: see
// payment_checkout_service.dart's explicit refusal for gateways outside
// checkoutSupportedGateways.
//
// DEFENSIVE PARSING, MORE SO THAN MONNIFY: fincra_service.dart's header
// documents that GET /wallets/topups's response schema is completely
// undocumented (Fincra's own reference shows an empty example body).
// [_rowsFrom] and [_upsertTopup] below try a small set of plausible
// shapes and field names, and skip+log a row they can't make sense of,
// rather than asserting a schema never actually seen.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/billing/fincra_service.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';

class FincraAdapter implements ConnectorAdapter {
  FincraAdapter({required this.workspaceId, required FincraService service}) : _service = service;

  final int workspaceId;
  final FincraService _service;

  PaymentTransactionRepository get _transactions => getIt<PaymentTransactionRepository>();
  CustomerIdentityResolver get _customerIdentity => getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  static const _maxPages = 500; // same bounded-loop discipline as the other gateway adapters
  static const _pageSize = 50;

  @override
  String get connectorKey => 'fincra';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        supportsIncrementalSync: false, // no confirmed date-range filter on /wallets/topups — see header
        supportsPagination: true,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    var seen = 0;
    var changed = 0;
    final errors = <String>[];

    // No confirmed date-range parameter on this endpoint (see
    // fincra_service.dart's header) — unlike Paystack/Flutterwave/
    // Monnify, this adapter cannot ask only for what changed since
    // [cursor]. It walks every page every run instead, relying on
    // PaymentTransactionRepository.upsertFromSync's own idempotency
    // (same safety net Bumpa's full-catalog-each-run sweep leans on) to
    // keep repeated runs cheap on the write side even though the read
    // side re-fetches everything. Worth tightening if Fincra's real
    // account data reveals a date filter this pass's docs research
    // missed.
    var page = 1;
    while (page <= _maxPages) {
      final result = await _service.listTopups(page: page, perPage: _pageSize);
      final rows = _rowsFrom(result);
      if (rows.isEmpty) break;

      for (final row in rows) {
        seen++;
        try {
          final wasNewOrChanged = await _upsertTopup(row);
          if (wasNewOrChanged) changed++;
        } catch (e) {
          errors.add('topup ${row['reference'] ?? row['id']}: $e');
          Log.warning('FincraAdapter: failed to process topup row (keys: ${row.keys}): $e');
        }
      }

      if (rows.length < _pageSize) break;
      page++;
    }

    return SyncResult(
      recordsSeen: seen,
      recordsChanged: changed,
      // No cursor to advance — see the loop comment above.
      nextCursor: cursor,
      errors: errors,
    );
  }

  /// Defensively locates the row list inside Fincra's response envelope
  /// — see this file's header. The one confirmed sibling endpoint
  /// (Get Balance History) nests its list under `data.results`, so
  /// that's tried first; a few plausible fallbacks follow before giving
  /// up and returning nothing rather than throwing.
  static List<Map<String, dynamic>> _rowsFrom(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) return results.whereType<Map<String, dynamic>>().toList();
      final topups = data['topups'];
      if (topups is List) return topups.whereType<Map<String, dynamic>>().toList();
    }
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    final topLevel = result['results'] ?? result['topups'];
    if (topLevel is List) return topLevel.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<bool> _upsertTopup(Map<String, dynamic> row) async {
    // No confirmed status field on this endpoint (see this file's
    // header — the Balance History sibling's own rows have no status
    // field either, only an `action` credit/debit flag). Skip anything
    // explicitly marked failed/pending/reversed under any plausible key
    // name; treat everything else — including rows with no status field
    // at all — as a completed pay-in, same "absence of a failure signal
    // is not itself a failure signal" stance PaystackAdapter takes for
    // rows missing an expected field it can still otherwise use.
    final status = (row['status'] ?? row['transactionStatus'] ?? row['action']) as String?;
    const failureStatuses = {'failed', 'pending', 'reversed', 'cancelled', 'debit'};
    if (status != null && failureStatuses.contains(status.toLowerCase())) return false;

    final reference = (row['reference'] ?? row['id']?.toString()) as String?;
    if (reference == null) return false;

    final customer = row['customer'] as Map<String, dynamic>?;
    final email = (customer?['email'] as String?) ?? (row['customerEmail'] as String?) ?? '';
    final phoneRaw = (customer?['phoneNumber'] as String?) ?? (row['customerPhoneNumber'] as String?);
    final normalizedPhone = (phoneRaw == null || phoneRaw.isEmpty) ? null : phoneRaw;

    // amount is in the currency's smallest unit per the one confirmed
    // sibling endpoint (Balance History's example shows 140000 for a
    // sum described only as "collection successful," consistent with
    // Fincra treating amounts as minor-unit integers rather than major-
    // unit decimals) — NOT independently confirmed for /wallets/topups
    // specifically, but this is the more likely convention of the two
    // and is applied here (unlike Monnify/Flutterwave's confirmed
    // major-unit convention, which gets ×100'd instead). Worth
    // rechecking against a real sandbox topup.
    final amountMinor = (row['amount'] as num?) ?? 0;

    final before = await _transactions.findByReference(reference);
    final alreadyCompleted = before?.status == 'completed';

    final txn = await _transactions.upsertFromSync(
      workspaceId: workspaceId,
      gateway: 'fincra',
      reference: reference,
      amountKobo: amountMinor.round(),
      currency: (row['currency'] as String?) ?? 'NGN',
      customerEmail: email,
      customerPhone: normalizedPhone,
      status: 'completed',
      gatewayTransactionId: row['id']?.toString(),
      paidAt: _parseDate(row['createdAt'] ?? row['date']),
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
        source: 'fincra',
      );
      if (customerId != null) {
        await _transactions.setCustomer(txnId, customerId);
      }
    }

    await _events.emit(
      workspaceId: workspaceId,
      eventType: 'payment_confirmed',
      fingerprint: 'payment_confirmed:$txnId',
      payload: {
        'transactionId': txnId,
        'workspaceId': workspaceId,
        'gateway': 'fincra',
        'reference': reference,
        'amountKobo': txn.amountKobo,
        'currency': txn.currency,
        'conversationId': txn.conversationId,
        'source': 'sync',
      },
      occurredAt: txn.paidAt ?? DateTime.now(),
    );

    return !alreadyCompleted;
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Future<ConnectorHealth> health() async {
    try {
      await _service.probe();
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not authenticate with Fincra using the stored secret key — it may have been rotated or revoked. ($e)',
      );
    }
  }
}
