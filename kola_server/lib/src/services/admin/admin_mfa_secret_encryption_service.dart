// admin_mfa_secret_encryption_service.dart — AES-256-GCM encryption for
// admin_users.mfa_secret (migration 056).
//
// Deliberately a near-identical copy of channel_credential_encryption
// _service.dart rather than a shared generic import: same reasoning
// that file's own header gives for keeping CHANNEL_CREDENTIAL_MASTER_KEY
// separate from ADMIN_JWT_SECRET — "a different secret class... rotating
// one should never require touching another." A TOTP secret protecting
// admin platform access is a different asset, with a different blast
// radius, than a customer's Telegram bot token; sharing either the key
// OR the encryption service instance risks a future change to one
// silently affecting the other. The duplication cost (one small file) is
// worth that isolation.
//
// USAGE: call AdminMfaSecretEncryptionService.init(Env.adminMfaMasterKey)
// once at server startup (server.dart), same timing as
// ChannelCredentialEncryptionService.init.
//
// STORAGE FORMAT: identical to the channel version —
// base64url( IV[12] || ciphertext || GCM-tag[16] ).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

class AdminMfaSecretEncryptionService {
  static Uint8List? _key;

  static void init(String masterKeyBase64) {
    if (masterKeyBase64.isEmpty) {
      throw StateError(
        'ADMIN_MFA_MASTER_KEY is not set. Generate a key and add it to '
        'your .env file — see this file\'s header for the command '
        '(same one channel_credential_encryption_service.dart documents).',
      );
    }

    final decoded = base64Url.decode(base64Url.normalize(masterKeyBase64));
    if (decoded.length != 32) {
      throw StateError(
        'ADMIN_MFA_MASTER_KEY must decode to exactly 32 bytes. '
        'Got ${decoded.length} bytes.',
      );
    }
    _key = Uint8List.fromList(decoded);
  }

  static bool get isInitialized => _key != null;

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

  static Uint8List _requireKey() {
    return _key ??
        (throw StateError(
          'AdminMfaSecretEncryptionService.init() has not been called. '
          'Call it in server.dart before any MFA enrollment/verification runs.',
        ));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }
}
