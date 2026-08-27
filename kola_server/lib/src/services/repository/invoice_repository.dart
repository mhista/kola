// invoice_repository.dart — the A4 invoice. Storage for Invoice
// (migration 047). See invoice.spy.yaml's header for why lines live as
// one JSON column, not a child table.

import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/invoice_dto.dart';
import 'supabase_client.dart';

const _dto = InvoiceDto();

class InvoiceRepository {
  const InvoiceRepository();

  Future<Invoice> create(Invoice invoice) async {
    final row = _dto.toRow(invoice, includeId: false)
      ..remove('updated_at'); // let the column default stamp both dates
    final response = await supabase.from('invoices').insert(row).select().single();
    return _dto.fromRow(response);
  }

  Future<Invoice?> findById(int workspaceId, int invoiceId) async {
    final response = await supabase
        .from('invoices')
        .select()
        .eq('id', invoiceId)
        .eq('workspace_id', workspaceId)
        .maybeSingle();
    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<List<Invoice>> listByWorkspace({
    required int workspaceId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await supabase
        .from('invoices')
        .select()
        .eq('workspace_id', workspaceId)
        .order('issued_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// The one open (not fully paid) invoice most recently issued for this
  /// sale, if one already exists — Documents' A4 tab reuses it instead
  /// of creating a duplicate every time the tab is opened.
  Future<Invoice?> findLatestForSale(int workspaceId, int saleId) async {
    final response = await supabase
        .from('invoices')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('sale_id', saleId)
        .order('issued_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<Invoice> updateStatus(int workspaceId, int invoiceId, String status) async {
    final response = await supabase
        .from('invoices')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', invoiceId)
        .eq('workspace_id', workspaceId)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Credits a manual payment against this invoice and moves status to
  /// 'partly_paid' or 'paid' depending on the new running total against
  /// [totalMinor]. See migration 047's header: this is bookkeeping the
  /// owner confirms, not an automatic webhook credit.
  Future<Invoice> recordPayment({
    required int workspaceId,
    required int invoiceId,
    required int amountMinor,
    required int totalMinor,
    required int currentPaidMinor,
  }) async {
    final newPaid = currentPaidMinor + amountMinor;
    final status = newPaid >= totalMinor ? 'paid' : 'partly_paid';
    final response = await supabase
        .from('invoices')
        .update({
          'paid_minor': newPaid,
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', invoiceId)
        .eq('workspace_id', workspaceId)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Same shape as SaleRepository.generateReference — not a "sequential
  /// invoice #889" (the export's own mock number). A real sequential
  /// series needs a per-workspace counter with its own concurrency story
  /// (two invoices created in the same instant must never collide), which
  /// is more machinery than this pass's scope. Time-derived and unique by
  /// construction instead — displayed as-is on the document rather than
  /// implying a sequence this system doesn't actually keep.
  static String generateReference(DateTime at) =>
      'INV-${at.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
