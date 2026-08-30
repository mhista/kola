// monnify_adapter.dart — Gate 11 (breadth). Same shape as
// paystack_adapter.dart/flutterwave_adapter.dart, deliberately — a third
// ConnectorAdapter for the paymentGateway store. Differences from those
// two are exactly the differences between Monnify's real API and
// theirs, not stylistic drift — see monnify_service.dart's header for
// what was verified and what wasn't.
//
// NO CHECKOUT-INITIATION SIDE, UNLIKE THE OTHER TWO: PaystackAdapter and
// FlutterwaveAdapter both live alongside a checkout-initiation path in
// payment_checkout_service.dart. Monnify does not — see that file's
// explicit refusal for 'monnify' and monnify_service.dart's header on
// why this is a deliberate v1 scope cut (sync/graph-landing only).
//
// DEFENSIVE PARSING: monnify_service.dart's header documents that the
// search-transactions response envelope was not independently confirmed
// past the endpoint path, auth flow, and the field names Monnify's own
// docs prose names (paymentReference, transactionReference,
// paymentStatus, amountPaid, settlementAmount). [_rowsFrom] and
// [_upsertTransaction] below try a small set of plausible shapes rather
// than asserting one — a single genuinely malformed row is skipped and
// logged (same per-row try/catch every other adapter in this codebase
// already uses), not a reason to fail the whole sync.

import 'package:kola_server/kola_logger.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/billing/monnify_service.dart';
import 'package:kola_server/src/services/repository/payment_transaction_repository.dart';
import 'package:kola_server/src/services/connectors/contract/connector_adapter.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';
import 'package:kola_server/src/services/connectors/contract/event_bus.dart';
import 'package:kola_server/src/services/connectors/contract/sync_types.dart';

class MonnifyAdapter implements ConnectorAdapter {
  MonnifyAdapter({required this.workspaceId, required MonnifyService service}) : _service = service;

  final int workspaceId;
  final MonnifyService _service;

  PaymentTransactionRepository get _transactions => getIt<PaymentTransactionRepository>();
  CustomerIdentityResolver get _customerIdentity => getIt<CustomerIdentityResolver>();
  EventBus get _events => getIt<EventBus>();

  static const _maxPages = 500; // same bounded-loop discipline as the other two gateway adapters
  static const _pageSize = 50;

  @override
  String get connectorKey => 'monnify';

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
    final from = since ?? DateTime.now().toUtc().subtract(const Duration(days: 365));
    final to = DateTime.now().toUtc();

    var seen = 0;
    var changed = 0;
    final errors = <String>[];
    DateTime? newestSeen = since;

    var page = 0;
    while (page < _maxPages) {
      final result = await _service.searchTransactions(from: from, to: to, page: page, size: _pageSize);
      final rows = _rowsFrom(result);
      if (rows.isEmpty) break;

      for (final row in rows) {
        seen++;
        try {
          final wasNewOrChanged = await _upsertTransaction(row);
          if (wasNewOrChanged) changed++;

          final paidOn = _parseDate(row['paidOn'] ?? row['transactionDate'] ?? row['createdOn']);
          if (paidOn != null && (newestSeen == null || paidOn.isAfter(newestSeen))) {
            newestSeen = paidOn;
          }
        } catch (e) {
          errors.add('transaction ${row['paymentReference'] ?? row['transactionReference']}: $e');
          Log.warning('MonnifyAdapter: failed to process transaction row (keys: ${row.keys}): $e');
        }
      }

      // No confirmed total-page-count field to walk to (see this file's
      // header) — a page shorter than the requested size is this
      // adapter's own "last page" signal instead, same fallback
      // PaystackAdapter uses for the same underlying reason (Paystack's
      // own docs don't guarantee a total either).
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

  /// Defensively locates the row list inside Monnify's response envelope
  /// — see this file's header. Tries the standard Monnify wrapper shape
  /// (`responseBody.content`, the Spring-Boot-Pageable convention every
  /// other Monnify list endpoint this codebase's research could confirm
  /// uses) first, then a couple of plausible fallbacks, before giving up
  /// and returning nothing rather than throwing — an unrecognized
  /// envelope shape should surface as "zero rows this run" (visible on
  /// the connector card as no progress) rather than crash the sweep.
  static List<Map<String, dynamic>> _rowsFrom(Map<String, dynamic> result) {
    final body = result['responseBody'];
    if (body is Map<String, dynamic>) {
      final content = body['content'];
      if (content is List) return content.whereType<Map<String, dynamic>>().toList();
      final transactions = body['transactions'];
      if (transactions is List) return transactions.whereType<Map<String, dynamic>>().toList();
    }
    final topLevel = result['content'] ?? result['data'] ?? result['transactions'];
    if (topLevel is List) return topLevel.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Future<bool> _upsertTransaction(Map<String, dynamic> row) async {
    final status = row['paymentStatus'] as String?;
    if (status != 'PAID') return false;

    final reference = (row['paymentReference'] ?? row['transactionReference']) as String?;
    if (reference == null) return false;

    final customer = row['customer'] as Map<String, dynamic>?;
    final email = (customer?['email'] as String?) ?? (row['customerEmail'] as String?) ?? '';
    final phone = (customer?['phoneNumber'] as String?) ?? (row['customerPhoneNumber'] as String?);
    final normalizedPhone = (phone == null || phone.isEmpty) ? null : phone;

    // amountPaid is Monnify's gross major-unit figure (e.g. 5000.00 for
    // ₦5,000) — same major-unit convention Flutterwave uses, and the
    // same ×100 conversion FlutterwaveAdapter applies for the identical
    // reason (this table's own amountKobo column is minor-unit).
    final amountPaidMajor = (row['amountPaid'] as num?) ?? (row['amount'] as num?) ?? 0;

    final before = await _transactions.findByReference(reference);
    final alreadyCompleted = before?.status == 'completed';

    final txn = await _transactions.upsertFromSync(
      workspaceId: workspaceId,
      gateway: 'monnify',
      reference: reference,
      amountKobo: (amountPaidMajor * 100).round(),
      currency: (row['currencyCode'] as String?) ?? 'NGN',
      customerEmail: email,
      customerPhone: normalizedPhone,
      status: 'completed',
      gatewayTransactionId: row['transactionReference']?.toString(),
      paidAt: _parseDate(row['paidOn'] ?? row['transactionDate'] ?? row['createdOn']),
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
        source: 'monnify',
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
        'gateway': 'monnify',
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
        'Could not authenticate with Monnify using the stored API key/secret — they may have been rotated or revoked. ($e)',
      );
    }
  }
}
