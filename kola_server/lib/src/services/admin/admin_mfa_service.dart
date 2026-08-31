// admin_mfa_service.dart — TOTP (RFC 6238) generation and verification
// for admin account MFA.
//
// WHY HAND-ROLLED RATHER THAN A PUB PACKAGE: adding a new pub dependency
// means a new `dart pub get` this environment cannot run and cannot
// verify resolves cleanly — the same reasoning that kept this project's
// AES-256-GCM work on `pointycastle` (already a dependency) instead of a
// dedicated crypto-box package. TOTP itself is a small, exactly-specified
// algorithm (RFC 6238, layered on RFC 4226's HOTP) built entirely from
// primitives ALREADY in this project's dependency tree: `package:crypto`
// (already used for sha256 hashing elsewhere — see document_ingestion_
// service.dart) provides HMAC-SHA1. The only piece with no existing
// helper is Base32 — TOTP secrets are conventionally base32 (RFC 4648)
// so they can be typed by hand into an authenticator app — implemented
// here directly since it is ~30 lines with no external dependency.
//
// COMPATIBILITY: standard 20-byte secret, SHA1, 6 digits, 30-second step
// — the exact defaults Google Authenticator, Authy, 1Password, etc. all
// assume when an otpauth:// URI omits algorithm/digits/period.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

/// RFC 4648 base32 encoding, no padding — the conventional shape for a
/// TOTP secret shown to a human or embedded in an otpauth:// URI.
String _base32Encode(List<int> bytes) {
  final buffer = StringBuffer();
  var bitBuffer = 0;
  var bitCount = 0;
  for (final byte in bytes) {
    bitBuffer = (bitBuffer << 8) | byte;
    bitCount += 8;
    while (bitCount >= 5) {
      bitCount -= 5;
      buffer.write(_base32Alphabet[(bitBuffer >> bitCount) & 0x1F]);
    }
  }
  if (bitCount > 0) {
    buffer.write(_base32Alphabet[(bitBuffer << (5 - bitCount)) & 0x1F]);
  }
  return buffer.toString();
}

/// Inverse of [_base32Encode]. Throws [FormatException] on any character
/// outside the base32 alphabet — a mistyped secret should fail loudly,
/// not silently decode to garbage.
List<int> _base32Decode(String input) {
  final cleaned = input.toUpperCase().replaceAll('=', '').replaceAll(RegExp(r'\s'), '');
  final out = <int>[];
  var bitBuffer = 0;
  var bitCount = 0;
  for (final char in cleaned.split('')) {
    final index = _base32Alphabet.indexOf(char);
    if (index == -1) {
      throw FormatException('Invalid base32 character: $char');
    }
    bitBuffer = (bitBuffer << 5) | index;
    bitCount += 5;
    if (bitCount >= 8) {
      bitCount -= 8;
      out.add((bitBuffer >> bitCount) & 0xFF);
    }
  }
  return out;
}

class AdminMfaService {
  const AdminMfaService();

  static const _stepSeconds = 30;
  static const _digits = 6;

  /// A fresh random 20-byte (160-bit) secret, base32-encoded — the
  /// standard TOTP secret length (RFC 4226 recommends at least 128 bits,
  /// 160 is what every mainstream authenticator app defaults to).
  String generateSecret() {
    final rng = Random.secure();
    final bytes = List<int>.generate(20, (_) => rng.nextInt(256));
    return _base32Encode(bytes);
  }

  /// The otpauth:// URI an authenticator app's QR scanner (or manual
  /// entry, for an app without camera access) expects. [accountEmail]
  /// and a fixed "Kola" issuer are both shown in the app so an admin can
  /// tell which of possibly several TOTP entries this one is.
  String provisioningUri({required String secretBase32, required String accountEmail}) {
    final label = Uri.encodeComponent('Kola:$accountEmail');
    final issuer = Uri.encodeComponent('Kola');
    return 'otpauth://totp/$label?secret=$secretBase32&issuer=$issuer&algorithm=SHA1&digits=$_digits&period=$_stepSeconds';
  }

  /// The 6-digit code for [secretBase32] at [counter] (a 30-second time
  /// step index) — RFC 4226's HOTP algorithm, the primitive TOTP layers
  /// a time-derived counter on top of.
  String _hotp(List<int> secretBytes, int counter) {
    final counterBytes = ByteData(8)..setUint64(0, counter, Endian.big);
    final hmac = Hmac(sha1, secretBytes);
    final digest = hmac.convert(counterBytes.buffer.asUint8List()).bytes;

    final offset = digest[digest.length - 1] & 0x0F;
    final binary = ((digest[offset] & 0x7F) << 24) |
        ((digest[offset + 1] & 0xFF) << 16) |
        ((digest[offset + 2] & 0xFF) << 8) |
        (digest[offset + 3] & 0xFF);

    final code = binary % pow(10, _digits).toInt();
    return code.toString().padLeft(_digits, '0');
  }

  /// True if [code] matches [secretBase32] at the current time, OR the
  /// one step immediately before/after it — a ±30s tolerance window for
  /// ordinary clock drift between this server and the admin's phone,
  /// same tolerance every mainstream TOTP verifier ships with by
  /// default. Wider windows are a real brute-force/replay tradeoff this
  /// pass deliberately does not widen further.
  bool verifyCode(String secretBase32, String code) {
    final trimmed = code.trim();
    if (trimmed.length != _digits || int.tryParse(trimmed) == null) return false;

    final secretBytes = _base32Decode(secretBase32);
    final currentStep = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000 ~/ _stepSeconds;

    for (final delta in [0, -1, 1]) {
      if (_hotp(secretBytes, currentStep + delta) == trimmed) return true;
    }
    return false;
  }
}
