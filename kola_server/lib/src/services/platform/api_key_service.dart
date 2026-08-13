// api_key_service.dart — generating, hashing and verifying API keys.
//
// ── THE WHOLE SECURITY MODEL, IN ONE PLACE ───────────────────────────
//
// 1. Generate 32 bytes from Random.secure().
// 2. Show the owner `sk_live_<base64url>` exactly once.
// 3. Store SHA-256 of that string, plus its last four characters.
// 4. On every request, hash what was presented and look for a match.
//
// The plaintext exists in memory for the duration of one endpoint call
// and is never written anywhere. Losing it means revoking and reissuing
// — which is the correct behaviour, not a gap.
//
// ── WHY HASHED AND NOT ENCRYPTED ─────────────────────────────────────
//
// kola_server already has AES-256-GCM (ChannelCredentialEncryptionService)
// and uses it for channel tokens, gateway secrets and Slack webhook URLs.
// Not here.
//
// The dividing line is whether the secret must be USED or merely MATCHED:
//
//   Telegram bot token   kola must SEND it to Telegram    → encrypt
//   Webhook secret       kola must SIGN payloads with it  → encrypt
//   API key              kola only ever COMPARES it       → hash
//
// A reversible secret nobody needs to reverse is a liability with no
// upside: it means a database leak hands over working credentials.
// Hashing removes that entirely.
//
// ── WHY SHA-256 AND NOT BCRYPT/ARGON2 ────────────────────────────────
//
// Worth stating, because "hash a credential" usually means a slow KDF.
// Slow hashing exists to defend LOW-ENTROPY secrets — passwords people
// choose. These keys are 32 bytes of CSPRNG output: brute-forcing one is
// not a matter of making each guess expensive, there are 2^256 of them.
//
// A KDF here would cost real latency on every authenticated API request
// to defend against an attack that is already impossible. SHA-256 of a
// high-entropy random token is what Stripe, GitHub and every other
// issuer of `sk_live_…` keys do, for this reason.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/services/repository/api_key_repository.dart';

class ApiKeyService {
  ApiKeyService({required ApiKeyRepository keys}) : _keys = keys;

  final ApiKeyRepository _keys;

  /// The design's SCOPES, in storage form. Rendered by the dashboard as
  /// 'Full access' / 'Read-only' / 'Errands only'.
  static const scopes = <String>['full', 'read_only', 'errands_only'];

  static const _prefixLive = 'sk_live';
  static const _prefixTest = 'sk_test';

  /// Creates a key and returns the plaintext ONCE.
  ///
  /// The returned [CreatedApiKey.plaintext] is the only copy that will
  /// ever exist outside the caller's browser.
  Future<CreatedApiKey> create({
    required int workspaceId,
    required String name,
    required String scope,
    bool live = true,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Give this key a name so you can recognise it.');
    }
    if (!scopes.contains(scope)) {
      throw ArgumentError('Unknown scope "$scope".');
    }

    final prefix = live ? _prefixLive : _prefixTest;
    final secret = _randomToken();
    final plaintext = '${prefix}_$secret';

    final stored = await _keys.create(
      workspaceId: workspaceId,
      name: name.trim(),
      keyPrefix: prefix,
      keyHash: hashOf(plaintext),
      lastFour: plaintext.substring(plaintext.length - 4),
      scope: scope,
    );

    return CreatedApiKey(key: stored, plaintext: plaintext);
  }

  /// Authenticates a presented key.
  ///
  /// Returns the row on success and null on any failure — unknown key,
  /// revoked key, malformed input all look identical to the caller. A
  /// response that distinguished "no such key" from "revoked key" would
  /// let someone enumerate which keys had once been valid.
  ///
  /// Stamps `last_used_at` on success. Deliberately not awaited: the
  /// request should not pay for the bookkeeping, and a failed stamp must
  /// not fail an otherwise valid call.
  Future<ApiKey?> verify(String presented) async {
    final trimmed = presented.trim();
    if (trimmed.isEmpty) return null;

    final match = await _keys.findLiveByHash(hashOf(trimmed));
    if (match == null) return null;

    final id = match.id;
    if (id != null) {
      unawaited(_keys.touch(id));
    }
    return match;
  }

  /// SHA-256 hex. The only transformation applied to a key, anywhere.
  static String hashOf(String plaintext) =>
      sha256.convert(utf8.encode(plaintext)).toString();

  /// 32 bytes of CSPRNG output, base64url without padding.
  ///
  /// `Random.secure()` rather than `Random()` — the latter is seeded
  /// predictably and would make every key guessable from any other.
  static String _randomToken() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

/// Fire-and-forget without importing dart:async at the call site.
///
/// Named rather than inlined as `ignore: unawaited_futures` so the
/// intent is visible: the stamp is bookkeeping, and an authenticated
/// request must not fail because recording its timestamp did.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
