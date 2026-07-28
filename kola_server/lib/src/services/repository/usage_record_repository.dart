// usage_record_repository.dart
//
// All database read/write operations for UsageRecord — the daily
// per-workspace, per-usage-class rollup rows (see usage_record.spy.yaml's
// header for why this is a rollup, not one row per event).
//
// PATTERN: same as every other repository — speaks only in Serverpod
// model types, UsageRecordDto handles the Supabase JSON translation.
//
// CONCURRENCY NOTE (read honestly, not glossed over): [incrementUsage]
// is a read-then-write, not a single atomic SQL increment — Supabase's
// REST layer has no built-in "upsert with increment" operation short of
// a custom Postgres function, and this project hasn't introduced one
// anywhere yet. Under genuinely concurrent calls for the same
// (workspaceId, usageClass, day) — e.g. two messages arriving in the
// same instant — this can undercount by one increment in the rare case
// both reads happen before either write lands. Acceptable for a
// metering system whose current job is "show usage trends and feed
// future plan-limit checks," not "bill to the exact unit" — worth
// revisiting with a Postgres RPC function if/when precise billing
// depends on this number being exact.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/usage_record_dto.dart';
import 'supabase_client.dart';

final _log = Logger('UsageRecordRepository');

const _dto = UsageRecordDto();

class UsageRecordRepository {
  const UsageRecordRepository();

  /// Adds [amount] to today's (or [on]'s) running total for
  /// (workspaceId, usageClass) — creating the row if today's doesn't
  /// exist yet. This is the one method every metering call site should
  /// use; nothing should insert into usage_records directly.
  Future<UsageRecord> incrementUsage({
    required int workspaceId,
    required String usageClass,
    double amount = 1,
    DateTime? on,
  }) async {
    final day = _dateOnly(on ?? DateTime.now().toUtc());
    _log.fine('incrementUsage workspaceId=$workspaceId usageClass=$usageClass amount=$amount day=$day');

    final existingRow = await supabase
        .from('usage_records')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('usage_class', usageClass)
        .eq('period_date', day)
        .maybeSingle();

    final now = DateTime.now().toUtc();
    if (existingRow == null) {
      final created = UsageRecord(
        workspaceId: workspaceId,
        usageClass: usageClass,
        periodDate: DateTime.parse(day),
        quantity: amount,
        createdAt: now,
        updatedAt: now,
      );
      final row = _dto.toRow(created, includeId: false);
      row['created_at'] = now.toIso8601String();
      final response = await supabase.from('usage_records').insert(row).select().single();
      return _dto.fromRow(response);
    }

    final existing = _dto.fromRow(existingRow);
    final response = await supabase
        .from('usage_records')
        .update({'quantity': existing.quantity + amount, 'updated_at': now.toIso8601String()})
        .eq('id', existing.id!)
        .select()
        .single();
    return _dto.fromRow(response);
  }

  /// Total usage for one workspace/usageClass across an inclusive date
  /// range — e.g. "how many messages has this workspace used this
  /// billing period." [from]/[to] are compared as plain calendar dates.
  Future<double> sumUsageInRange({
    required int workspaceId,
    required String usageClass,
    required DateTime from,
    required DateTime to,
  }) async {
    _log.fine('sumUsageInRange workspaceId=$workspaceId usageClass=$usageClass from=$from to=$to');
    final response = await supabase
        .from('usage_records')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('usage_class', usageClass)
        .gte('period_date', _dateOnly(from))
        .lte('period_date', _dateOnly(to));

    final rows = (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>));
    var total = 0.0;
    for (final r in rows) {
      total += r.quantity;
    }
    return total;
  }

  static String _dateOnly(DateTime dt) {
    final d = dt.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
