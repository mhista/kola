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
// a placeholder standing in for "the real thing later".
//
// ITERATION COUNT — LOWERED FROM 210,000 TO 50,000, DELIBERATELY, NOT
// OWASP'S FULL RECOMMENDATION (2026-08-30, same incident as the
// Isolate.run() note below): OWASP's 210,000 baseline assumes normal
// server hardware. This app's Northflank service is hard-capped at 0.2
// vCPU (the free-tier ceiling — confirmed with the project owner that a
// vCPU upgrade isn't available on the current plan), where 210,000
// iterations cost ~20 SECONDS of wall-clock time per login — long enough
// to trip the edge proxy's first-byte timeout even after the
// server-freezing bug below was fixed. 50,000 iterations costs roughly a
// quarter of that (~4-6s), comfortably inside the timeout window, while
// remaining a real, salted, iterated KDF — nowhere near a bare hash.
// This is a conscious, CPU-budget-driven trade for THIS specific
// deployment constraint, confirmed with the project owner rather than
// picked unilaterally, and it only affects kola_admin's two accounts,
// not any customer-facing auth. Revisit upward the moment more CPU is
// available.
//
// STORAGE FORMAT: "iterations:base64(salt):base64(hash)" — a single
// string, so a future iteration-count bump doesn't strand existing rows
// (verify() reads the stored iteration count, not a hardcoded one). This
// is exactly what makes the 210,000 -> 50,000 change here safe for
// EXISTING accounts too: their stored hash still carries "210000" and
// verifies correctly (just slowly) until they next set a password via
// AdminAuthEndpoint.changePassword (see migration 055's forced-reset
// flow) — hash() only applies the new lower count going forward, no
// backfill/migration needed.
//
// WHY Isolate.run() WRAPS THE ACTUAL DERIVATION (added after a real
// production incident, 2026-08-30): pointycastle's PBKDF2 is a pure-Dart
// software implementation with no hardware acceleration, and 210,000
// iterations is CPU-bound work, not I/O — on a CPU-constrained container
// (this app's Northflank service runs at 0.2 vCPU) a single call took
// ~20 SECONDS. Dart is single-threaded per isolate: running that
// synchronously on the main isolate (the old shape of this file) froze
// the ENTIRE server process for that whole window — not just the login
// request, but every other request, the Telegram long-poller, and every
// scheduled sweep, confirmed by BroadcastRepository's 15-second heartbeat
// log visibly skipping a beat during a real login attempt. The 503s an
// admin saw in the browser were the edge proxy's first-byte timeout
// giving up on a server that was still alive but computationally stuck —
// the login call itself succeeded 20 seconds later, just too late to
// matter. Isolate.run() spawns a short-lived worker isolate for just the
// derivation step, so THIS call still takes however long the CPU quota
// makes it take, but every OTHER request and background task keeps
// running on the main isolate the whole time instead of queuing behind
// it. This does not make login itself fast — raising the service's vCPU
// allocation is the actual fix for that — it stops one slow login from
// taking the whole platform down with it.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Arguments bundled for [Isolate.run] — its closure must not capture
/// the enclosing instance/static context in a way that isn't sendable
/// across isolates, so parameters are passed explicitly instead of
/// closed over.
class _DeriveArgs {
  const _DeriveArgs(this.password, this.salt, this.iterations, this.keyLength);
  final String password;
  final Uint8List salt;
  final int iterations;
  final int keyLength;
}

abstract class AdminPasswordHasher {
  static const _iterations = 50000;
  static const _saltLength = 16;
  static const _keyLength = 32;

  /// Hashes [password] with a freshly generated random salt. Returns the
  /// full storage string — see this file's header for the format.
  static Future<String> hash(String password) async {
    final salt = _randomBytes(_saltLength);
    final derived = await Isolate.run(
      () => _derive(_DeriveArgs(password, salt, _iterations, _keyLength)),
    );
    return '$_iterations:${base64.encode(salt)}:${base64.encode(derived)}';
  }

  /// Verifies [password] against a [stored] hash produced by [hash].
  /// Constant-time comparison on the derived bytes — a timing
  /// difference on password verification is a real, exploitable side
  /// channel, not a theoretical one.
  static Future<bool> verify(String password, String stored) async {
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

    final actual = await Isolate.run(
      () => _derive(_DeriveArgs(password, salt, iterations, expected.length)),
    );
    return _constantTimeEquals(actual, expected);
  }

  /// Runs on a worker isolate via [Isolate.run] (see [hash]/[verify]) —
  /// a top-level-callable static function taking one bundled argument,
  /// which is what `Isolate.run`'s closure actually needs to be safely
  /// sendable.
  static Uint8List _derive(_DeriveArgs args) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(args.salt, args.iterations, args.keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(args.password)));
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
