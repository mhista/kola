// whatsapp_signature_verifier.dart
//
// Verifies the X-Hub-Signature-256 header Meta attaches to every
// WhatsApp webhook POST — an HMAC-SHA256 of the raw request body, keyed
// by the App Secret of whichever Meta App is delivering the webhook.
//
// TAKES A LIST OF CANDIDATE SECRETS, NOT JUST ONE — TRANSITIONAL:
//   New WhatsApp channels each get their own callback path
//   (/webhooks/whatsapp/<channelId> — see whatsapp_bot_registry.dart's
//   file header), so for those the channel — and therefore exactly which
//   App Secret applies — is already known from the URL, and the caller
//   passes a single-item list. The FIRST channel connected before this
//   change is still verified via the original shared /webhooks/whatsapp
//   route (kept alive deliberately — re-verifying that callback URL/
//   token in Meta's dashboard is unnecessary churn while only one
//   channel uses it), which doesn't know the channel from the URL alone
//   and so must try every registered channel's secret. Once every
//   channel has migrated to its own URL, the shared route (and this
//   multi-secret support) can go away — see whatsapp_bot_registry.dart
//   and whatsapp_webhook_route.dart for where "legacy" mode is still
//   wired in.
//
// STILL VERIFIED BEFORE PARSING: the raw body is hashed and compared
// before whatsapp_webhook_route.dart ever calls jsonDecode on it — acting
// on (or even fully trusting) attacker-controlled JSON before this check
// runs would defeat the point of having it.
//
// USES pointycastle (already a dependency for
// channel_credential_encryption_service.dart's AES-256-GCM) rather than
// adding package:crypto — same "reuse before rebuilding" convention.

import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class WhatsAppSignatureVerifier {
  WhatsAppSignatureVerifier._();

  /// [signatureHeader] is the raw `X-Hub-Signature-256` header value,
  /// e.g. `"sha256=abc123..."`. Returns false immediately for a
  /// missing/malformed header, before computing any HMAC. Accepts if
  /// ANY secret in [candidateAppSecrets] matches — pass a single-item
  /// iterable when the channel (and its one correct secret) is already
  /// known from the URL; pass every registered secret only for the
  /// legacy shared route, which has no other way to narrow it down.
  static bool verify({
    required String rawBody,
    required String? signatureHeader,
    required Iterable<String> candidateAppSecrets,
  }) {
    if (signatureHeader == null || !signatureHeader.startsWith('sha256=')) {
      return false;
    }
    final expectedHex = signatureHeader
        .substring('sha256='.length)
        .toLowerCase();
    final bodyBytes = Uint8List.fromList(utf8.encode(rawBody));

    for (final secret in candidateAppSecrets.toSet()) {
      if (secret.isEmpty) continue;
      final mac = HMac(SHA256Digest(), 64)
        ..init(KeyParameter(Uint8List.fromList(utf8.encode(secret))));
      final digestHex = _bytesToHex(mac.process(bodyBytes));
      if (_constantTimeEquals(digestHex, expectedHex)) return true;
    }
    return false;
  }

  static String _bytesToHex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Constant-time-ish string compare — the HMAC computation above
  /// dominates timing either way, but this removes the one cheap-to-fix
  /// mistake (an early-exit `==` on a secret comparison).
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
