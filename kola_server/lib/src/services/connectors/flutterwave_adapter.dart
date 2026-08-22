// flutterwave_adapter.dart — Gate 4. Same shape as paystack_adapter.dart,
// deliberately — both are ConnectorAdapter implementations for the
// paymentGateway store, and the differences between them are exactly the
// differences between the two providers' real APIs, not stylistic
// drift. See flutterwave_service.dart's header for the two documented
// differences this adapter has to account for that Paystack didn't:
//
//   1. Pagination is a known total page count (meta.page_info), not a
//      "fewer than perPage" signal.
//   2. There is no documented "list customers" endpoint — customer
//      identity comes only from each transaction's own customer fields,
//      so there is no second pull pass the way PaystackAdapter has one.
//
// WHY THIS DOES NOT DUPLICATE PaymentWebhookHandler'S LOGIC: same
// reasoning as PaystackAdapter's header — both converge on
// PaymentTransactionRepository.upsertFromSync and
// CustomerIdentityResolver.resolve, and both emit the same
// 'payment_confirmed:$transactionId' fingerprint, so whichever path sees
// a transaction first does the work and the other is a deduplicated
// no-op at the EventBus layer.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/billing/flutterwave_service.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';

class FlutterwaveAdapter implements ConnectorAdapter {
  FlutterwaveAdapter({required this.workspaceId, required FlutterwaveService service})
      : _service = service;

  final int workspaceId;
  final FlutterwaveService _service;

  PaymentTransactionRepository get _transactions =>
      getIt<PaymentTransactionRepository>();
  CustomerIdentityResolver get _customerIdentity =>
      getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  static const _maxPages = 500; // same bounded-loop discipline as PaystackAdapter

  @override
  String get connectorKey => 'flutterwave';

  @override
  ConnectorCapabilities get capabilities => const ConnectorCapabilities(
        supportsIncrementalSync: true,
        supportsPagination: true,
        isPushDriven: false,
      );

  @override
  String get retentionPolicy => RetentionPolicy.retainOnDisconnect;

  @override
  Future<SyncResult> sync({SyncCursor cursor = SyncCursor.none}) async {
    final since = cursor.isEmpty ? null : DateTime.tryParse(cursor.value as String? ?? '');

    var seen = 0;
    var changed = 0;
    final errors = <String>[];
    DateTime? newestSeen = since;

    var page = 1;
    while (page <= _maxPages) {
      final result = await _service.listTransactions(from: since, to: DateTime.now(), page: page);
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
          errors.add('transaction ${row['tx_ref']}: $e');
          Log.warning('FlutterwaveAdapter: failed to process transaction row: $e');
        }
      }

      // Flutterwave's list response gives an actual page count, unlike
      // Paystack's — walk to it exactly rather than inferring from a
      // short page.
      final pageInfo = (result['meta'] as Map<String, dynamic>?)?['page_info']
          as Map<String, dynamic>?;
      final totalPages = pageInfo?['total_pages'] as int?;
      if (totalPages == null || page >= totalPages) break;
      page++;
    }

    return SyncResult(
      recordsSeen: seen,
      recordsChanged: changed,
      nextCursor: SyncCursor(newestSeen?.toIso8601String()),
      errors: errors,
    );
  }

  Future<bool> _upsertTransaction(Map<String, dynamic> row) async {
    final status = row['status'] as String?;
    if (status != 'successful') return false;

    final reference = row['tx_ref'] as String?;
    if (reference == null) return false;

    // Flutterwave's list response carries flat customer_email/
    // customer_name — no nested `customer` object the way verify's
    // single-transaction response and Paystack's list both do. Read the
    // nested shape first (in case a future response includes it) and
    // fall back to the flat fields, rather than assuming one shape.
    final nestedCustomer = row['customer'] as Map<String, dynamic>?;
    final email = (nestedCustomer?['email'] as String?) ?? (row['customer_email'] as String?) ?? '';
    final phone = (nestedCustomer?['phone_number'] as String?) ?? (row['phone_number'] as String?);
    final normalizedPhone = (phone == null || phone.isEmpty || phone == 'N/A') ? null : phone;

    final before = await _transactions.findByReference(reference);
    final alreadyCompleted = before?.status == 'completed';

    final txn = await _transactions.upsertFromSync(
      workspaceId: workspaceId,
      gateway: 'flutterwave',
      reference: reference,
      // Flutterwave's amount is major-unit (e.g. 5000.00 NGN), unlike
      // Paystack/this table's own amountKobo convention (minor unit) —
      // same conversion payment_checkout_service.dart does in reverse
      // when INITIATING a Flutterwave checkout. Missing this would make
      // every synced Flutterwave transaction land 100x too small.
      amountKobo: (((row['amount'] as num?) ?? 0) * 100).round(),
      currency: row['currency'] as String? ?? 'NGN',
      customerEmail: email,
      customerPhone: normalizedPhone,
      status: 'completed',
      gatewayTransactionId: row['id']?.toString(),
      paidAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
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
        source: 'flutterwave',
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
        'gateway': 'flutterwave',
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

  @override
  Future<ConnectorHealth> health() async {
    try {
      await _service.probe();
      return const ConnectorHealth.healthy();
    } catch (e) {
      return ConnectorHealth.unhealthy(
        'Could not reach Flutterwave with the stored key — it may have been rotated or revoked on their end. ($e)',
      );
    }
  }
}
