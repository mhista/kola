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
