// message_suppression_repository.dart — Gate 9. All database read/write
// operations for MessageSuppression records — the "entity, not a
// filter" opt-out list broadcast_sweep_service.dart checks at send
// time, per recipient.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/message_suppression_dto.dart';
import 'supabase_client.dart';

final _log = Logger('MessageSuppressionRepository');

const _dto = MessageSuppressionDto();

class MessageSuppressionRepository {
  const MessageSuppressionRepository();

  /// The one check broadcast_sweep_service.dart makes before every
  /// single send — kept this cheap (indexed equality lookup, migration
  /// 049's unique index doubles as this query's index) since it runs
  /// once per recipient per attempt.
  Future<bool> isSuppressed({
    required int workspaceId,
    required String platform,
    required String addressNormalized,
  }) async {
    final response = await supabase
        .from('message_suppressions')
        .select('id')
        .eq('workspace_id', workspaceId)
        .eq('platform', platform)
        .eq('address_normalized', addressNormalized)
        .maybeSingle();
    return response != null;
  }

  Future<List<MessageSuppression>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('message_suppressions')
        .select()
        .eq('workspace_id', workspaceId)
        .order('created_at', ascending: false);
    return (response as List).map((row) => _dto.fromRow(row as Map<String, dynamic>)).toList();
  }

  /// Idempotent add — the same (workspaceId, platform, address) opting
  /// out twice is not an error, it's the same fact stated again.
  Future<MessageSuppression> add({
    required int workspaceId,
    required String platform,
    required String addressNormalized,
    required String reason,
  }) async {
    _log.info('add suppression workspaceId=$workspaceId platform=$platform');
    final now = DateTime.now().toUtc();
    final row = {
      'workspace_id': workspaceId,
      'platform': platform,
      'address_normalized': addressNormalized,
      'reason': reason,
      'created_at': now.toIso8601String(),
    };
    final response = await supabase
        .from('message_suppressions')
        .upsert(row, onConflict: 'workspace_id,platform,address_normalized')
        .select()
        .single();
    return _dto.fromRow(response);
  }

  Future<void> remove({
    required int workspaceId,
    required String platform,
    required String addressNormalized,
  }) async {
    _log.info('remove suppression workspaceId=$workspaceId platform=$platform');
    await supabase
        .from('message_suppressions')
        .delete()
        .eq('workspace_id', workspaceId)
        .eq('platform', platform)
        .eq('address_normalized', addressNormalized);
  }
}
