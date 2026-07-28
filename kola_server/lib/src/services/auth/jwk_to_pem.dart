// jwk_to_pem.dart
//
// Converts a JSON Web Key (as published by Supabase Auth's JWKS discovery
// endpoint, GET /auth/v1/.well-known/jwks.json) into the PEM-encoded
// SubjectPublicKeyInfo format dart_jsonwebtoken's ECPublicKey/RSAPublicKey
// constructors expect — dart_jsonwebtoken has no built-in JWK support (its
// own pub.dev docs only show PEM-string constructors), so this bridges
// that gap with a minimal, purpose-built DER encoder rather than pulling
// in a general-purpose ASN.1 library for two struct shapes.
//
// SUPPORTED: EC keys on the P-256 curve (kty=EC, crv=P-256) — the
// algorithm Supabase's own docs recommend ("Elliptic Curves are a faster
// alternative than RSA... We recommend using the P-256 elliptic curve
// instead" — supabase.com/docs/guides/auth/signing-keys) — and RSA keys
// (kty=RSA). Ed25519 (EdDSA) is listed by Supabase as "Coming soon" as of
// this file's writing and is NOT implemented here; add it if/when Supabase
// actually ships it as a signing key option (dart_jsonwebtoken already
// supports EdDSA verification, so only the JWK->PEM side would be new).
//
// UNVERIFIED AGAINST A REAL KEY: this file was written in a sandbox with
// no Dart toolchain and no live Supabase project on the new Signing Keys
// system to test against. The DER byte layouts below are standard,
// widely-documented constants (RFC 5480 for EC SubjectPublicKeyInfo,
// RFC 3447 Appendix A.1 for RSA's AlgorithmIdentifier), hand-verified
// byte-by-byte against their length fields in this file's own commit —
// but "correctly transcribed from spec" is not the same as "verified
// against a real Supabase-issued ES256/RS256 token." Run this against a
// real migrated Supabase project (see session_verifier.dart's header)
// before trusting it in production.

import 'dart:convert';
import 'dart:typed_data';

/// Builds a PEM "PUBLIC KEY" block for an EC JWK on the P-256 curve.
/// [x]/[y] are the JWK's own base64url-encoded coordinate strings
/// (unpadded, per RFC 7517) — pass them exactly as received from the
/// JWKS response, no pre-decoding needed.
String ecP256JwkToPem({required String x, required String y}) {
  final xBytes = _decodeBase64UrlFixedLength(x, 32);
  final yBytes = _decodeBase64UrlFixedLength(y, 32);

  // Fixed SubjectPublicKeyInfo prefix for "EC public key, P-256 curve"
  // (RFC 5480): SEQUENCE { SEQUENCE { OID ecPublicKey (1.2.840.10045.2.1),
  // OID prime256v1 (1.2.840.10045.3.1.7) }, BIT STRING <66 bytes: 0x00
  // unused-bits count + 0x04 uncompressed-point marker + 64 bytes of
  // point> }. This exact 26-byte prefix is standard and identical for
  // every P-256 SPKI regardless of the actual key — only the point bytes
  // that follow (x || y) differ per key.
  const prefix = [
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00,
  ];

  final der = Uint8List.fromList([
    ...prefix,
    0x04, // uncompressed EC point marker
    ...xBytes,
    ...yBytes,
  ]);

  return _wrapPem(der);
}

/// Builds a PEM "PUBLIC KEY" block for an RSA JWK. [n]/[e] are the JWK's
/// own base64url-encoded modulus/exponent strings, passed as-is.
String rsaJwkToPem({required String n, required String e}) {
  final modulus = _decodeBase64Url(n);
  final exponent = _decodeBase64Url(e);

  final rsaPublicKey = _derSequence([
    ..._derInteger(modulus),
    ..._derInteger(exponent),
  ]);

  // Fixed AlgorithmIdentifier for rsaEncryption (1.2.840.113549.1.1.1)
  // + NULL parameters (RFC 3447 Appendix A.1) — another constant that
  // never changes regardless of the actual key.
  const algorithmIdentifier = [
    0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
    0x01, 0x05, 0x00,
  ];

  final der = _derSequence([
    ...algorithmIdentifier,
    ..._derBitString(rsaPublicKey),
  ]);

  return _wrapPem(Uint8List.fromList(der));
}

// ── DER helpers (minimal — just enough for the two shapes above) ───────────

List<int> _derLength(int length) {
  if (length < 0x80) return [length];
  final bytes = <int>[];
  var remaining = length;
  while (remaining > 0) {
    bytes.insert(0, remaining & 0xff);
    remaining >>= 8;
  }
  return [0x80 | bytes.length, ...bytes];
}

List<int> _derInteger(Uint8List magnitude) {
  // DER INTEGER is signed — prepend a 0x00 byte if the high bit of the
  // first byte is set, so a positive value (every JWK modulus/exponent
  // here is positive) isn't misread as negative.
  final needsPad = magnitude.isNotEmpty && (magnitude[0] & 0x80) != 0;
  final content = needsPad ? [0x00, ...magnitude] : magnitude;
  return [0x02, ..._derLength(content.length), ...content];
}

List<int> _derSequence(List<int> content) => [
  0x30,
  ..._derLength(content.length),
  ...content,
];

List<int> _derBitString(List<int> content) => [
  0x03,
  ..._derLength(content.length + 1),
  0x00, // zero unused bits in the last content byte
  ...content,
];

String _wrapPem(Uint8List der) {
  final b64 = base64.encode(der);
  final lines = <String>[];
  for (var i = 0; i < b64.length; i += 64) {
    lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
  }
  return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----';
}

Uint8List _decodeBase64Url(String value) =>
    base64Url.decode(base64Url.normalize(value));

/// Same as [_decodeBase64Url] but pads/trims to exactly [length] bytes —
/// EC coordinates from a conforming JWK encoder are already fixed-width
/// (32 bytes for P-256), but a small guard here is cheap insurance against
/// a coordinate arriving one byte short (some encoders trim leading zero
/// bytes) producing a silently-misaligned point instead of an obvious
/// failure.
Uint8List _decodeBase64UrlFixedLength(String value, int length) {
  final decoded = _decodeBase64Url(value);
  if (decoded.length == length) return decoded;
  if (decoded.length > length) return decoded.sublist(decoded.length - length);
  final padded = Uint8List(length);
  padded.setRange(length - decoded.length, length, decoded);
  return padded;
}
