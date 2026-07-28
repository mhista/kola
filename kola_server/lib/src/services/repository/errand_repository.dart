// errand_repository.dart
//
// All database read/write operations for Errand records.
//
// MULTI-TENANCY: every method here takes or filters by workspaceId — an
// Errand is never fetched by its bare id alone in a context where the
// caller hasn't already established which workspace they're allowed to
// touch. Same convention as BotRepository/ChannelRepository.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/errand_dto.dart';
import 'supabase_client.dart';

final _log = Logger('ErrandRepository');

const _dto = ErrandDto();

class ErrandRepository {
  const ErrandRepository();

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Internal-only lookup by bare id — endpoint-facing code should prefer
  /// [findByIdScoped] instead, same reasoning as BotRepository.findById.
  Future<Errand?> findById(int id) async {
    _log.fine('findById($id)');
    final response = await supabase
        .from('errands')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Workspace-scoped lookup — returns null both when the errand doesn't
  /// exist AND when it exists but belongs to a different workspace, same
  /// "don't leak which case it is" reasoning as
  /// BotRepository.findByIdScoped.
  Future<Errand?> findByIdScoped(int id, int workspaceId) async {
    _log.fine('findByIdScoped($id, workspaceId=$workspaceId)');
    final response = await supabase
        .from('errands')
        .select()
        .eq('id', id)
        .eq('workspace_id', workspaceId)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  /// Every errand belonging to a workspace, regardless of status.
  Future<List<Errand>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('errands')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Every 'active' errand for a workspace — what the AI orchestrator will
  /// eventually load as the available-tools list per conversation
  /// (SRS.md §7.2), once tool-calling exists (see ai_provider.dart's
  /// header). Excludes 'disabled' errands without deleting their history.
  Future<List<Errand>> listActiveByWorkspace(int workspaceId) async {
    _log.fine('listActiveByWorkspace($workspaceId)');
    final response = await supabase
        .from('errands')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('status', 'active');

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  // ── WRITE ─────────────────────────────────────────────────────────────────

  /// Register a new Errand. [inputSchemaJson]/[sensitiveInputKeysJson]
  /// default to an empty object/array — callers building either from a
  /// real Dart Map/List should jsonEncode before calling this, same
  /// "flexible shape lives in a text column" pattern as
  /// WhatsAppCredential.encode().
  Future<Errand> create({
    required int workspaceId,
    required String name,
    required String descriptionForAi,
    required String source,
    required String createdVia,
    String? builtinHandlerKey,
    String permissionScope = 'readOnly',
    String inputSchemaJson = '{}',
    String sensitiveInputKeysJson = '[]',
    String? queryTemplateSql,
  }) async {
    final now = DateTime.now().toUtc();
    _log.info('Creating errand workspaceId=$workspaceId name=$name source=$source');

    final errand = Errand(
      workspaceId: workspaceId,
      name: name,
      descriptionForAi: descriptionForAi,
      source: source,
      builtinHandlerKey: builtinHandlerKey,
      createdVia: createdVia,
      permissionScope: permissionScope,
      inputSchemaJson: inputSchemaJson,
      sensitiveInputKeysJson: sensitiveInputKeysJson,
      status: 'active',
      queryTemplateSql: queryTemplateSql,
      createdAt: now,
      updatedAt: now,
    );

    final row = _dto.toRow(errand, includeId: false);
    row['created_at'] = now.toIso8601String();

    final response = await supabase.from('errands').insert(row).select().single();
    return _dto.fromRow(response);
  }

  /// Update mutable fields. Matches on id — callers must have already
  /// confirmed workspace ownership via findByIdScoped before calling this.
  Future<Errand> update(Errand errand) async {
    _log.info('Updating errand id=${errand.id}');
    final row = _dto.toRow(errand, includeId: false);
    row['updated_at'] = DateTime.now().toUtc().toIso8601String();

    final response = await supabase
        .from('errands')
        .update(row)
        .eq('id', errand.id!)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Toggle an errand active/disabled without deleting its history/logs.
  Future<Errand> setStatus(int errandId, String status) async {
    _log.info('setStatus errandId=$errandId status=$status');
    final response = await supabase
        .from('errands')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', errandId)
        .select()
        .single();

    return _dto.fromRow(response);
  }

  /// Permanently deletes the errand row. Callers (ErrandEndpoint.deleteErrand)
  /// must have already: confirmed workspace ownership, confirmed
  /// status == 'disabled', and deleted the errand's credential row (if
  /// any) first — this method itself does none of those checks, same
  /// "repository doesn't re-derive policy the endpoint already enforced"
  /// convention as every other repository in this codebase.
  Future<void> delete(int errandId) async {
    _log.info('delete errandId=$errandId');
    await supabase.from('errands').delete().eq('id', errandId);
  }
}
