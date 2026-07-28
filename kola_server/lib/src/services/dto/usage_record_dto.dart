// usage_record_dto.dart
//
// Translates between:
//   Serverpod model  → UsageRecord  (kola_server/lib/src/generated/usage_record.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: usage_records
// Schema: docs/migrations/008_subscriptions_and_usage_records.sql
//
// NOTE: periodDate is a plain calendar date, not a timestamp — stored
// as a Postgres `date` column (see the migration), so it round-trips as
// a bare 'YYYY-MM-DD' string, not full ISO-8601 with a time component.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class UsageRecordDto extends BaseDto<UsageRecord> {
  const UsageRecordDto();

  @override
  UsageRecord fromRow(Map<String, dynamic> row) {
    return UsageRecord(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      usageClass: row['usage_class'] as String,
      periodDate: DateTime.parse(row['period_date'] as String),
      quantity: (row['quantity'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(UsageRecord model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'usage_class': model.usageClass,
      'period_date': _dateOnly(model.periodDate),
      'quantity': model.quantity,
      'updated_at': model.updatedAt.toIso8601String(),
      // created_at is set by Supabase default — we never write it on updates
    };
  }

  static String _dateOnly(DateTime dt) {
    final d = dt.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
