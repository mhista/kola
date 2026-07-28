// bot_dto.dart
//
// Translates between:
//   Serverpod model  → Bot  (generated/bot.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: bots
// Schema: docs/migrations/001_initial_schema.sql (source of truth — not
// duplicated here to avoid the two drifting apart over time), plus
// knowledge_seed added in docs/migrations/005_errands_and_knowledge_seed.sql.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class BotDto extends BaseDto<Bot> {
  const BotDto();

  @override
  Bot fromRow(Map<String, dynamic> row) {
    return Bot(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      name: row['name'] as String,
      archetype: row['archetype'] as String,
      status: row['status'] as String,
      knowledgeSeed: row['knowledge_seed'] as String?,
      costSavingTelegramLink: row['cost_saving_telegram_link'] as String?,
      costSavingAlternateWhatsapp: row['cost_saving_alternate_whatsapp'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(Bot model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'name': model.name,
      'archetype': model.archetype,
      'status': model.status,
      'knowledge_seed': model.knowledgeSeed,
      'cost_saving_telegram_link': model.costSavingTelegramLink,
      'cost_saving_alternate_whatsapp': model.costSavingAlternateWhatsapp,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
