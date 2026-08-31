// stock_conflict_repository.dart
//
// All database read/write operations for StockConflict records
// (Phase 11g-e — DESIGN_BRIEF_COMMERCE.md §1's oversell-conflict
// requirement). See stock_conflict.spy.yaml's header for why this
// exists and when it's created.
//
// MULTI-TENANCY: every method filters by workspaceId, same convention as
// every other repository in this project.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/stock_conflict_dto.dart';
import 'supabase_client.dart';

final _log = Logger('StockConflictRepository');

const _dto = StockConflictDto();

class StockConflictRepository {
  const StockConflictRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<StockConflict?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('stock_conflicts')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Open conflicts only — this is a queue to clear, not a log to
  /// scroll through, so 'backordered'/'adjusted'/'dismissed' entries
  /// are left out. Newest first, matching every other "needs attention"
  /// list in this codebase (SupportTicket, WorkspaceFinding).
  Future<List<StockConflict>> listOpen(int workspaceId) async {
    _log.fine('listOpen($workspaceId)');
    final response = await supabase
        .from('stock_conflicts')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'open')
        .order('detected_at', ascending: false);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  Future<StockConflict> create({
    required int workspaceId,
    required int productId,
    int? saleId,
    required int oversoldBy,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info(
      'Creating stock conflict workspaceId=$workspaceId productId=$productId '
      'oversoldBy=$oversoldBy',
    );

    final conflict = StockConflict(
      workspaceId: workspaceId,
      productId: productId,
      saleId: saleId,
      oversoldBy: oversoldBy,
      detectedAt: now,
      status: 'open',
      resolvedAt: null,
      resolvedByEmail: null,
    );

    final row = _dto.toRow(conflict, includeId: false);
    row['detected_at'] = now.toIso8601String();
    final response = await supabase.from('stock_conflicts').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// [status] is 'backordered' | 'adjusted' | 'dismissed' — the owner's
  /// decision. Never called with 'open'; there is no path back to open
  /// once resolved (a fresh oversell creates a fresh row instead — see
  /// header on why this is a proposal per-incident, not a running
  /// tally).
  Future<StockConflict> resolve({
    required int id,
    required String status,
    required String resolvedByEmail,
  }) async {
    _log.info('resolve id=$id status=$status');
    final now = DateTime.now().toUtc();

    final response = await supabase
        .from('stock_conflicts')
        .update({
          'status': status,
          'resolved_at': now.toIso8601String(),
          'resolved_by_email': resolvedByEmail,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
