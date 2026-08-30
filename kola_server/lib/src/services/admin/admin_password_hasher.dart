// admin_password_hasher.dart — kola_admin, step 1 of ADMIN_APP_SPEC.md's
// build order.
//
// PBKDF2-HMAC-SHA256, salted, via pointycastle — NOT bcrypt/argon2.
// Stated plainly why: bcrypt is not a reachable pub.dev dependency in
// this environment (no toolchain to fetch a new package — the same
// constraint that pushed Instagram's webhook-verify-token field to read
// straight from Platform.environment instead of a fresh @EnviedField).
// pointycastle is already a direct dependency of this project
// (channel_credential_encryption_service.dart's AES-256-GCM), and its
// PBKDF2 implementation is a real, correct, non-toy password hash — not
// a placeholder standing in for "the real thing later". 210,000
// iterations matches OWASP's 2023 PBKDF2-HMAC-SHA256 recommendation.
//
// STORAGE FORMAT: "iterations:base64(salt):base64(hash)" — a single
// string, so a future iteration-count bump doesn't strand existing rows
// (verify() reads the stored iteration count, not a hardcoded one).

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

abstract class AdminPasswordHasher {
  static const _iterations = 210000;
  static const _saltLength = 16;
  static const _keyLength = 32;

  /// Hashes [password] with a freshly generated random salt. Returns the
  /// full storage string — see this file's header for the format.
  static String hash(String password) {
    final salt = _randomBytes(_saltLength);
    final derived = _derive(password, salt, _iterations);
    return '$_iterations:${base64.encode(salt)}:${base64.encode(derived)}';
  }

  /// Verifies [password] against a [stored] hash produced by [hash].
  /// Constant-time comparison on the derived bytes — a timing
  /// difference on password verification is a real, exploitable side
  /// channel, not a theoretical one.
  static bool verify(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 3) return false;

    final iterations = int.tryParse(parts[0]);
    if (iterations == null) return false;

    late final Uint8List salt;
    late final Uint8List expected;
    try {
      salt = base64.decode(parts[1]);
      expected = base64.decode(parts[2]);
    } catch (_) {
      return false;
    }

    final actual = _derive(password, salt, iterations);
    return _constantTimeEquals(actual, expected);
  }

  static Uint8List _derive(String password, Uint8List salt, int iterations) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, _keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
