// channel_credential_encryption_service.dart
//
// AES-256-GCM encryption/decryption for Channel.encryptedCredential — a
// Telegram bot token today, a WhatsApp long-lived access token once
// Phase 2b's Embedded Signup flow exists. Ported directly from
// degenbot_server's wallet_encryption_service.dart: same algorithm, same
// storage format, same key requirements — channel.spy.yaml's header
// comment calls this out explicitly as "the same AES-256-GCM approach
// already implemented for wallet keys in Degenbot ... reused, not
// reinvented." The only real difference from the wallet version is the
// public API shape: callers here always have a plaintext *string*
// credential (a bot token), never raw key bytes, so encrypt/decrypt work
// directly in String, with the UTF-8 conversion handled internally
// instead of pushed onto every call site.
//
// USAGE:
//   Call ChannelCredentialEncryptionService.init(Env.channelCredentialMasterKey)
//   once at server startup (server.dart), before any channel-connect
//   endpoint or startup bootstrap runs.
//
// STORAGE FORMAT:
//   encrypt() returns a single base64url string:
//     base64url( IV[12 bytes] || ciphertext || GCM-tag[16 bytes] )
//   The IV is randomly generated per-call so encrypting the same token
//   twice never produces the same ciphertext.
//
// KEY REQUIREMENTS:
//   The master key must be exactly 32 bytes, supplied as a base64url
//   string. Generate once — `dart -e` is NOT a real Dart CLI flag (an
//   earlier version of this comment claimed otherwise; caught when it
//   failed on a real machine), so use Node instead:
//
//     node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
//
//   No Node available? PowerShell (Windows, no extra installs):
//     $b=New-Object byte[] 32; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); ([Convert]::ToBase64String($b)).Replace('+','-').Replace('/','_').TrimEnd('=')
//
//   Copy the output → CHANNEL_CREDENTIAL_MASTER_KEY in .env, then run:
//     dart run build_runner build

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class ChannelCredentialEncryptionService {
  static Uint8List? _key;

  /// Call once at server startup before any channel credential is
  /// encrypted or decrypted. [masterKeyBase64] is
  /// Env.channelCredentialMasterKey.
  static void init(String masterKeyBase64) {
    if (masterKeyBase64.isEmpty) {
      throw StateError(
        'CHANNEL_CREDENTIAL_MASTER_KEY is not set. '
        'Generate a key and add it to your .env file. '
        'See channel_credential_encryption_service.dart for instructions.',
      );
    }

    final decoded = base64Url.decode(base64Url.normalize(masterKeyBase64));
    if (decoded.length != 32) {
      throw StateError(
        'CHANNEL_CREDENTIAL_MASTER_KEY must decode to exactly 32 bytes. '
        'Got ${decoded.length} bytes.',
      );
    }
    _key = Uint8List.fromList(decoded);
  }

  /// Encrypt a plaintext credential (a bot token, a WhatsApp access
  /// token) with AES-256-GCM. Returns base64url( IV[12] || ciphertext ||
  /// GCM-tag[16] ) — safe to store directly in Channel.encryptedCredential.
  static String encrypt(String plaintext) {
    final key = _requireKey();
    final iv = _randomBytes(12);
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final ciphertext = cipher.process(plaintextBytes);

    final combined = Uint8List(12 + ciphertext.length);
    combined.setRange(0, 12, iv);
    combined.setRange(12, combined.length, ciphertext);

    return base64Url.encode(combined);
  }

  /// Decrypt a value produced by [encrypt] back to the plaintext
  /// credential string. Throws on tampered/corrupt data (GCM
  /// authentication fails) — never returns a partially-decrypted value.
  static String decrypt(String encryptedBase64) {
    final key = _requireKey();
    final combined = base64Url.decode(base64Url.normalize(encryptedBase64));

    if (combined.length < 12 + 16) {
      throw ArgumentError('Encrypted value is too short to be valid.');
    }

    final iv = combined.sublist(0, 12);
    final ciphertext = combined.sublist(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final plaintextBytes = cipher.process(ciphertext);
    return utf8.decode(plaintextBytes);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  static Uint8List _requireKey() {
    return _key ??
        (throw StateError(
          'ChannelCredentialEncryptionService.init() has not been called. '
          'Call it in server.dart before starting any channel-related code.',
        ));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
