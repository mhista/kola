// sale_repository.dart — the till. Storage for Sale + SaleLine
// (migrations 035, 039). See sale.spy.yaml's header for why this
// finishes what PART II's gap table called outstanding, and why
// customerId is nullable.
//
// NO TRANSACTION WRAPPING — this codebase has no established multi-
// statement-transaction pattern (checked: only one unrelated .rpc()
// call exists anywhere in lib/src). Sale then SaleLines is two
// sequential inserts, same posture as every other multi-row write here.
// client_reference's uniqueness (migration 035) is what makes a retried
// offline sync safe even if a prior attempt got partway through: the
// sale insert itself is the idempotency gate — see [findByClientReference].

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/sale_dto.dart';
import 'package:kola_server/src/services/dto/sale_line_dto.dart';
import 'supabase_client.dart';

final _log = Logger('SaleRepository');

const _saleDto = SaleDto();
const _lineDto = SaleLineDto();

class SaleRepository {
  const SaleRepository();

  Future<Sale?> findByClientReference({
    required int workspaceId,
    required String clientReference,
  }) async {
    final row = await supabase
        .from('sales')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('client_reference', clientReference)
        .maybeSingle();
    return row == null ? null : _saleDto.fromRow(row);
  }

  Future<Sale> create({
    required int workspaceId,
    int? customerId,
    required String reference,
    String? clientReference,
    required int subtotalMinor,
    required int taxRateBps,
    required int taxMinor,
    required int totalMinor,
    required String currency,
    required String paymentMethod,
    int? cashReceivedMinor,
    int? changeMinor,
    DateTime? soldAt,
  }) async {
    final now = DateTime.now().toUtc();
    final inserted = await supabase
        .from('sales')
        .insert({
          'workspace_id': workspaceId,
          'customer_id': customerId,
          'reference': reference,
          'client_reference': clientReference,
          'subtotal_minor': subtotalMinor,
          'tax_rate_bps': taxRateBps,
          'tax_minor': taxMinor,
          'total_minor': totalMinor,
          'currency': currency,
          'payment_method': paymentMethod,
          'cash_received_minor': cashReceivedMinor,
          'change_minor': changeMinor,
          'status': 'completed',
          'sold_at': (soldAt ?? now).toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select()
        .single();
    return _saleDto.fromRow(inserted);
  }

  Future<void> setCustomer(int saleId, int customerId) async {
    await supabase
        .from('sales')
        .update({
          'customer_id': customerId,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', saleId);
  }

  Future<List<SaleLine>> addLines({
    required int saleId,
    required List<({int? productId, String name, int unitPriceMinor, int quantity, int lineTotalMinor})> lines,
  }) async {
    if (lines.isEmpty) return const [];
    final rows = await supabase
        .from('sale_lines')
        .insert([
          for (final l in lines)
            {
              'sale_id': saleId,
              'product_id': l.productId,
              'name': l.name,
              'unit_price_minor': l.unitPriceMinor,
              'quantity': l.quantity,
              'line_total_minor': l.lineTotalMinor,
            },
        ])
        .select();
    return (rows as List).map((r) => _lineDto.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<List<SaleLine>> listLines(int saleId) async {
    final response = await supabase.from('sale_lines').select().eq('sale_id', saleId);
    return (response as List).map((r) => _lineDto.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<List<Sale>> listByWorkspace({
    required int workspaceId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await supabase
        .from('sales')
        .select()
        .eq('workspace_id', workspaceId)
        .order('sold_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((r) => _saleDto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// The read Gate 3b exists to make possible: every order on a
  /// customer's timeline.
  Future<List<Sale>> listByCustomer(int customerId) async {
    _log.fine('listByCustomer($customerId)');
    final response = await supabase
        .from('sales')
        .select()
        .eq('customer_id', customerId)
        .order('sold_at', ascending: false);
    return (response as List).map((r) => _saleDto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// All sales (any status) with `sold_at` in `[from, to)`, for the
  /// End-of-day report. Half-open on purpose so a caller can chain
  /// consecutive days (today's `to` is tomorrow's `from`) without a
  /// sale landing in neither or both buckets.
  Future<List<Sale>> listByWorkspaceAndRange({
    required int workspaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await supabase
        .from('sales')
        .select()
        .eq('workspace_id', workspaceId)
        .gte('sold_at', from.toIso8601String())
        .lt('sold_at', to.toIso8601String())
        .order('sold_at', ascending: true);
    return (response as List).map((r) => _saleDto.fromRow(r as Map<String, dynamic>)).toList();
  }

  static String generateReference(DateTime at) =>
      'SALE-${at.microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
}
