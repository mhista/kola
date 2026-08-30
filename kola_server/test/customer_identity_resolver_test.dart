// customer_identity_resolver_test.dart
//
// GATE 14. Rev 5's testing-requirements section asks for "a fixture set
// with deliberate near-misses — same name different phone, same phone
// different name, shared family email" for identity resolution. The
// resolving logic itself (CustomerIdentityResolver.resolve) takes three
// repositories by constructor injection, none of them behind an
// interface — faking it means either a live/staging database or a real
// repository-interface refactor, neither invented here (see
// GATE_14_STATUS.md). What CAN be tested for real without either is the
// layer every match actually depends on: normalization. A phone or
// email that normalizes to two different strings for what a person
// would call "the same contact" is exactly how a near-miss slips past
// the resolver's deliberately strict, no-fuzzy-matching design — see
// this file's own header on why name is never matched on at all.
//
// Run with: dart test test/

import 'package:test/test.dart';
import 'package:kola_server/src/services/connectors/contract/customer_identity_resolver.dart';

void main() {
  group('CustomerIdentityResolver.normalizePhone', () {
    test('strips formatting so the same number matches regardless of how it was typed', () {
      const same = [
        '+234 803 555 1234',
        '234-803-555-1234',
        '(234) 803 555 1234',
        '2348035551234',
      ];
      final normalized = same.map(CustomerIdentityResolver.normalizePhone).toSet();
      expect(normalized, hasLength(1),
          reason: 'every formatting of the same number must collapse to one value');
    });

    test('does not silently collapse two genuinely different numbers — the near-miss case', () {
      // Same length, same country code, one digit apart — a real
      // "same-looking, different person" case a fuzzy matcher could get
      // wrong. Exact normalization must keep these distinct.
      final a = CustomerIdentityResolver.normalizePhone('+234 803 555 1234');
      final b = CustomerIdentityResolver.normalizePhone('+234 803 555 1235');
      expect(a, isNot(equals(b)));
    });

    test('a local-format and international-format write of the same number are NOT '
        'unified by this helper alone — a documented limitation, not a silent bug', () {
      // normalizePhone only strips non-digits; it does not add or infer
      // a country code. '0803...' and '234803...' are therefore treated
      // as different signals today. Asserting this explicitly so a
      // future change to the normalization rule shows up here as an
      // intentional decision, not an accidental behavior change.
      final local = CustomerIdentityResolver.normalizePhone('08035551234');
      final intl = CustomerIdentityResolver.normalizePhone('+2348035551234');
      expect(local, isNot(equals(intl)));
    });
  });

  group('CustomerIdentityResolver.normalizeEmail', () {
    test('is case-insensitive and trims whitespace', () {
      const same = [
        'buyer@example.com',
        'Buyer@Example.com',
        '  buyer@example.com  ',
        'BUYER@EXAMPLE.COM',
      ];
      final normalized = same.map(CustomerIdentityResolver.normalizeEmail).toSet();
      expect(normalized, hasLength(1));
    });

    test('does not treat two different mailboxes as the same — the shared-family-email near-miss', () {
      // "shared family email" from Rev 5's fixture list: two people
      // using the same inbox is a real business scenario this resolver
      // is NOT trying to solve (see header — no fuzzy matching, no
      // inference beyond the literal signal). What matters here is the
      // negative: two DIFFERENT addresses must never normalize equal.
      final a = CustomerIdentityResolver.normalizeEmail('family@example.com');
      final b = CustomerIdentityResolver.normalizeEmail('family+dad@example.com');
      expect(a, isNot(equals(b)),
          reason: 'plus-addressing produces a different literal signal; this '
              'resolver deliberately does not fold it, since assuming '
              'family@ and family+dad@ are the same person is exactly the '
              'kind of inference Rev 5 rules out');
    });
  });

  group('CustomerIdentityResolver.normalizeName — near-miss awareness', () {
    test('same name, different casing/whitespace, normalizes identically', () {
      final a = CustomerIdentityResolver.normalizeName('  Ada Obi ');
      final b = CustomerIdentityResolver.normalizeName('ada obi');
      expect(a, equals(b));
    });

    test('name normalization exists but this resolver never matches on it alone', () {
      // The near-miss this guards against isn't in the string helper —
      // it's architectural: two different people named "Ada Obi" must
      // never be merged just because normalizeName() agrees. That
      // guarantee lives in CustomerIdentityResolver.resolve() only
      // ever calling findMatch() with type 'phone' or 'email' (see
      // this file's own header, "WHY NAME IS NOT MATCHED ON HERE").
      // Asserting the helper's pure output here; the "never used for
      // matching" guarantee itself would need a database-backed test
      // of resolve() to exercise end-to-end — named as an open gap in
      // GATE_14_STATUS.md rather than assumed covered by this test.
      expect(CustomerIdentityResolver.normalizeName('Ada Obi'), 'ada obi');
    });
  });

  group('CustomerIdentityResolver.normalizePlatformUser', () {
    test('namespaces by platform, so the same external id on two platforms cannot collide', () {
      final whatsapp = CustomerIdentityResolver.normalizePlatformUser('whatsapp', '12345');
      final telegram = CustomerIdentityResolver.normalizePlatformUser('telegram', '12345');
      expect(whatsapp, isNot(equals(telegram)));
    });

    test('the same platform and id always normalizes identically', () {
      final a = CustomerIdentityResolver.normalizePlatformUser('whatsapp', '12345');
      final b = CustomerIdentityResolver.normalizePlatformUser('whatsapp', '12345');
      expect(a, equals(b));
    });
  });
}
