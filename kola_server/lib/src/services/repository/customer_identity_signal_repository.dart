// customer_identity_signal_repository.dart — Gate 3. The deterministic
// matcher's storage layer. Migration 039's unique index on (workspaceId,
// signalType, normalizedValue) is what makes [findMatch] authoritative —
// a lookup either finds the one customer who already owns this value or
// it finds nothing.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/customer_identity_signal_dto.dart';
import 'supabase_client.dart';

final _log = Logger('CustomerIdentitySignalRepository');

const _dto = CustomerIdentitySignalDto();

class CustomerIdentitySignalRepository {
  const CustomerIdentitySignalRepository();

  /// The matcher lookup itself: does a customer already own this exact
  /// (signalType, normalizedValue) in this workspace?
  Future<CustomerIdentitySignal?> findMatch({
    required int workspaceId,
    required String signalType,
    required String normalizedValue,
  }) async {
    final row = await supabase
        .from('customer_identity_signals')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('signal_type', signalType)
        .eq('normalized_value', normalizedValue)
        .maybeSingle();
    return row == null ? null : _dto.fromRow(row);
  }

  /// Attaches a new signal to a customer. Idempotent on the same
  /// (workspaceId, signalType, normalizedValue) — a retried call sees
  /// the unique-index conflict and this just skips the insert rather
  /// than throwing, since the resolver already checked [findMatch]
  /// first in the normal path; this is the safety net for a race
  /// between two concurrent calls resolving the same brand-new signal.
  Future<void> attach({
    required int workspaceId,
    required int customerId,
    required String signalType,
    required String normalizedValue,
    required String source,
    String? sourceRef,
  }) async {
    try {
      await supabase.from('customer_identity_signals').insert({
        'workspace_id': workspaceId,
        'customer_id': customerId,
        'signal_type': signalType,
        'normalized_value': normalizedValue,
        'source': source,
        'source_ref': sourceRef,
        'first_seen_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      _log.info(
        'attach($workspaceId, $signalType, $normalizedValue): '
        'already exists (expected under a race) — $e',
      );
    }
  }

  Future<List<CustomerIdentitySignal>> listForCustomer(int customerId) async {
    final response = await supabase
        .from('customer_identity_signals')
        .select()
        .eq('customer_id', customerId)
        .order('first_seen_at', ascending: true);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Every signal of one type across a whole workspace — Phase 14/186,
  /// backs the Customers page's "Search by name or phone…" (the
  /// export's own placeholder copy, `Kola Customers.dc.html` line 64).
  /// Scoped to [signalType] rather than every signal in the workspace:
  /// the one caller today wants phone numbers only, and there is no
  /// reason to also pull every WhatsApp/Telegram external-id signal
  /// along with it. The (workspaceId, signalType, normalizedValue)
  /// unique index (migration 039) covers this query's leading columns.
  Future<List<CustomerIdentitySignal>> listByWorkspaceAndType({
    required int workspaceId,
    required String signalType,
  }) async {
    final response = await supabase
        .from('customer_identity_signals')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('signal_type', signalType);
    return (response as List).map((r) => _dto.fromRow(r as Map<String, dynamic>)).toList();
  }
}
