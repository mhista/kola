// invoice_endpoint.dart — the A4 invoice tab on Documents.
// docs/TILL_DOCUMENTS_STATUS.md's suggested-next-steps item 4 asked for
// this: "an Invoice/Order entity" so the A4 tab can stop being a labeled
// empty state. See migration 047 / invoice.spy.yaml headers for the
// schema reasoning (JSON lines column, derived-not-stored 'overdue').
//
// Gated on the same commerce.core + commerce.pos flags SaleEndpoint
// already uses — an invoice is the till's own output in another form,
// not a new capability a workspace opts into separately.
//
// "PAY NOW" IS A REAL CHECKOUT, NOT A MOCKUP — the dashboard calls the
// EXISTING PaymentEndpoint.initializeCheckout directly (this endpoint
// does not wrap or duplicate it), against whichever gateway the
// workspace has already connected. What this endpoint does NOT do:
// automatically credit paidMinor when that checkout completes — no
// webhook -> invoice link is wired (that is Gate 13, Reconciliation,
// fully unbuilt per the roadmap doc). recordPayment below is a manual
// "mark as paid" the owner triggers themselves, same posture
// payment_transaction.spy.yaml's own manual-payment fields already
// document for the till.

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
import 'package:kola_server/src/services/repository/invoice_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class InvoiceEndpoint extends Endpoint {
  InvoiceRepository get _invoices => getIt<InvoiceRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// Creates a new invoice. [linesJson] is a JSON array of
  /// `{"name": String, "quantity": int, "unitPriceMinor": int}` objects —
  /// a String parameter, deliberately, not `List<InvoiceLineInput>` or
  /// even a parallel `List<int>`/`List<String>` split. See
  /// sale_endpoint.dart's ringUpSale header for the full trace of why
  /// this app's Serverpod install cannot deserialize ANY `List<...>` as a
  /// direct endpoint parameter — that finding governs this endpoint's
  /// shape too, not just the till's.
  ///
  /// Totals are recomputed from [linesJson] here, server-side — never
  /// trusted from the caller, same discipline ringUpSale already applies
  /// to a sale's subtotal/tax/total.
  Future<Invoice> createInvoice(
    Session session,
    String accessToken,
    int workspaceId,
    String billToName,
    String linesJson, {
    int? customerId,
    int? saleId,
    String? billToAddress,
    String? billToPhone,
    int taxRateBps = 0,
    String currency = 'NGN',
    String? paymentInstructions,
    DateTime? dueAt,
  }) async {
    await _require(accessToken, workspaceId);

    final trimmedName = billToName.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Bill-to name is required.');
    }

    final decoded = jsonDecode(linesJson);
    if (decoded is! List || decoded.isEmpty) {
      throw KolaException(message: 'An invoice needs at least one line.');
    }
    final lines = [
      for (final raw in decoded)
        if (raw is Map)
          (
            name: raw['name'] as String,
            quantity: raw['quantity'] as int,
            unitPriceMinor: raw['unitPriceMinor'] as int,
          ),
    ];

    final subtotalMinor = lines.fold<int>(
      0,
      (sum, l) => sum + (l.unitPriceMinor * l.quantity),
    );
    final taxMinor = (subtotalMinor * taxRateBps / 10000).round();
    final totalMinor = subtotalMinor + taxMinor;

    final now = DateTime.now().toUtc();
    final invoice = Invoice(
      workspaceId: workspaceId,
      customerId: customerId,
      saleId: saleId,
      reference: InvoiceRepository.generateReference(now),
      status: 'draft',
      billToName: trimmedName,
      billToAddress: (billToAddress?.trim().isEmpty ?? true) ? null : billToAddress!.trim(),
      billToPhone: (billToPhone?.trim().isEmpty ?? true) ? null : billToPhone!.trim(),
      linesJson: jsonEncode([
        for (final l in lines)
          {'name': l.name, 'quantity': l.quantity, 'unitPriceMinor': l.unitPriceMinor},
      ]),
      subtotalMinor: subtotalMinor,
      taxRateBps: taxRateBps,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      paidMinor: 0,
      currency: currency,
      paymentInstructions: (paymentInstructions?.trim().isEmpty ?? true)
          ? null
          : paymentInstructions!.trim(),
      issuedAt: now,
      dueAt: dueAt,
      createdAt: now,
      updatedAt: now,
    );

    final created = await _invoices.create(invoice);
    Log.success('Invoice created', data: {'invoiceId': created.id, 'workspaceId': workspaceId});
    return created;
  }

  Future<List<Invoice>> listInvoices(
    Session session,
    String accessToken,
    int workspaceId, {
    int limit = 50,
    int offset = 0,
  }) async {
    await _require(accessToken, workspaceId);
    return _invoices.listByWorkspace(workspaceId: workspaceId, limit: limit, offset: offset);
  }

  Future<Invoice?> getInvoice(
    Session session,
    String accessToken,
    int workspaceId,
    int invoiceId,
  ) async {
    await _require(accessToken, workspaceId);
    return _invoices.findById(workspaceId, invoiceId);
  }

  /// The most recently issued invoice for a given sale, or null. Lets
  /// Documents' A4 tab reuse an existing invoice instead of creating a
  /// new one every time an owner opens the tab for the same sale.
  Future<Invoice?> getInvoiceForSale(
    Session session,
    String accessToken,
    int workspaceId,
    int saleId,
  ) async {
    await _require(accessToken, workspaceId);
    return _invoices.findLatestForSale(workspaceId, saleId);
  }

  /// Owner-driven status transitions (draft -> sent -> viewed), and the
  /// only way to move backward too (e.g. correcting a mistaken "sent").
  /// No validation on the transition graph — same trust level Sale's own
  /// status already gets, and simpler than encoding a state machine for
  /// four values an owner is the sole judge of.
  Future<Invoice> updateInvoiceStatus(
    Session session,
    String accessToken,
    int workspaceId,
    int invoiceId,
    String status,
  ) async {
    await _require(accessToken, workspaceId);
    const valid = {'draft', 'sent', 'viewed', 'partly_paid', 'paid'};
    if (!valid.contains(status)) {
      throw KolaException(message: 'status must be one of: ${valid.join(", ")}');
    }
    return _invoices.updateStatus(workspaceId, invoiceId, status);
  }

  /// Manual "mark as paid" — see this file's header on why this is not
  /// an automatic webhook credit yet.
  Future<Invoice> recordPayment(
    Session session,
    String accessToken,
    int workspaceId,
    int invoiceId,
    int amountMinor,
  ) async {
    await _require(accessToken, workspaceId);
    if (amountMinor <= 0) {
      throw KolaException(message: 'Payment amount must be greater than zero.');
    }
    final invoice = await _invoices.findById(workspaceId, invoiceId);
    if (invoice == null) {
      throw KolaException(message: 'Invoice $invoiceId not found in workspace $workspaceId.');
    }
    return _invoices.recordPayment(
      workspaceId: workspaceId,
      invoiceId: invoiceId,
      amountMinor: amountMinor,
      totalMinor: invoice.totalMinor,
      currentPaidMinor: invoice.paidMinor,
    );
  }

  Future<void> _require(String accessToken, int workspaceId) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
    }
    if (!await _features.isEnabled(FeatureKeys.commerceCore, workspace) ||
        !await _features.isEnabled(FeatureKeys.commercePos, workspace)) {
      throw KolaException(message: 'Invoicing is not available on this workspace yet.');
    }
  }
}
