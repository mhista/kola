// payment_gateway_credential_repository.dart
//
// All database read/write operations for PaymentGatewayCredential
// records — one row per (workspaceId, gateway) pair, a workspace's OWN
// Paystack/Flutterwave secret key. See
// payment_gateway_credential.spy.yaml's header for why this exists
// separately from the global Env.paystackSecretKey/flutterwaveSecretKey.
//
// CREDENTIAL HANDLING: this repository stores and returns whatever
// ciphertext it's given in encryptedSecretKey — it never encrypts or
// decrypts itself, same separation of concerns as ChannelRepository.

import 'package:logging/logging.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/dto/payment_gateway_credential_dto.dart';
import 'supabase_client.dart';

final _log = Logger('PaymentGatewayCredentialRepository');

const _dto = PaymentGatewayCredentialDto();

class PaymentGatewayCredentialRepository {
  const PaymentGatewayCredentialRepository();

  Future<PaymentGatewayCredential?> findByWorkspaceAndGateway(
    int workspaceId,
    String gateway,
  ) async {
    _log.fine('findByWorkspaceAndGateway($workspaceId, $gateway)');
    final response = await supabase
        .from('payment_gateway_credentials')
        .select()
        .eq('workspace_id', workspaceId)
        .eq('gateway', gateway)
        .maybeSingle();

    if (response == null) return null;
    return _dto.fromRow(response);
  }

  Future<List<PaymentGatewayCredential>> listByWorkspace(int workspaceId) async {
    _log.fine('listByWorkspace($workspaceId)');
    final response = await supabase
        .from('payment_gateway_credentials')
        .select()
        .eq('workspace_id', workspaceId);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Gate 4 — every workspace's credential for one [gateway], across the
  /// whole platform. ConnectorSyncSweepService's only query: it needs
  /// "everyone connected to Paystack," not one workspace at a time, same
  /// precedent as ChannelRepository.listConnected() feeding
  /// ChannelHealthCheckService's own sweep.
  Future<List<PaymentGatewayCredential>> listAllByGateway(String gateway) async {
    _log.fine('listAllByGateway($gateway)');
    final response = await supabase
        .from('payment_gateway_credentials')
        .select()
        .eq('gateway', gateway);

    return (response as List)
        .map((row) => _dto.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Gate 4 — persists what a sync run learned: the next watermark to
  /// resume from, and that an attempt happened at all (even if
  /// [cursor] is unchanged, e.g. a run that found nothing new).
  /// Never touches encrypted_secret_key/encrypted_webhook_secret — a
  /// sync run has no reason to know about either.
  Future<void> updateSyncState({
    required int workspaceId,
    required String gateway,
    required String? cursor,
    required DateTime syncedAt,
  }) async {
    _log.fine('updateSyncState($workspaceId, $gateway)');
    await supabase
        .from('payment_gateway_credentials')
        .update({
          'sync_cursor': cursor,
          'last_synced_at': syncedAt.toUtc().toIso8601String(),
        })
        .eq('workspace_id', workspaceId)
        .eq('gateway', gateway);
  }

  /// Create-or-replace, keyed by the (workspaceId, gateway) unique index —
  /// the right call for both "connect this gateway for the first time" and
  /// "rotate a leaked/rotated secret key," since a caller should never need
  /// to know which case applies.
  Future<PaymentGatewayCredential> upsert({
    required int workspaceId,
    required String gateway,
    required String encryptedSecretKey,
    String? encryptedWebhookSecret,
  }) async {
    _log.info('Upserting payment gateway credential workspaceId=$workspaceId gateway=$gateway');
    final now = DateTime.now().toUtc();

    final row = {
      'workspace_id': workspaceId,
      'gateway': gateway,
      'encrypted_secret_key': encryptedSecretKey,
      'updated_at': now.toIso8601String(),
    };
    // Only touch this column when a value was actually supplied — an
    // omitted webhookSecret on a re-connect/rotate call should leave a
    // previously-set one alone, not silently null it out.
    if (encryptedWebhookSecret != null) {
      row['encrypted_webhook_secret'] = encryptedWebhookSecret;
    }

    final response = await supabase
        .from('payment_gateway_credentials')
        .upsert(row, onConflict: 'workspace_id,gateway')
        .select()
        .single();

    return _dto.fromRow(response);
  }
}
