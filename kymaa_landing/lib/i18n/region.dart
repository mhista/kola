// region.dart
//
// Region, currency and pricing for the kymaa landing page. ONE file
// decides what a visitor is shown as a price; nothing else in the app
// hardcodes a currency symbol.
//
// ── WHY THIS EXISTS ──────────────────────────────────────────────────
//
// This page was Nigeria-first and it showed: "₦45,000", "priced for
// Naija", Naira hardcoded into the plan model itself. Nothing about the
// product is Nigeria-specific — a business in Nairobi, São Paulo or
// Manila has the same problem. The geography was in the copy, not in
// the product.
//
// ── DOLLARS ARE THE DEFAULT HERE ─────────────────────────────────────
//
// Unlike kola_landing, which defaults to Nigeria, this page defaults to
// [Regions.international] — USD. That is a deliberate difference: this
// is the version being shown to a general audience, and a price in
// Naira asks a reader who does not know the exchange rate to do
// homework before they can tell whether it is cheap or expensive.
//
// ── PRICING IS REGIONAL BY PURCHASING POWER ──────────────────────────
//
// Not one converted price. The model Spotify, Netflix and JetBrains
// use, and the right one here: a number that works in Lagos is trivial
// in London, and a number that works in London is impossible in Lagos.
// A single global price either closes the emerging markets this product
// is built for, or leaves most of the revenue on the table in wealthy
// ones.
//
// ⚠ ONLY TWO COLUMNS BELOW ARE REAL COMMERCIAL DECISIONS:
//
//     NGN  ₦45,000 / ₦120,000  — the settled prices this page shipped
//     USD  $28 / $75           — the equivalents this page already
//                                displayed alongside them
//
//   EVERY OTHER REGION IS A PLACEHOLDER I derived, set at rough
//   purchasing-power parity against the Naira figure. They are not
//   confirmed and should not be treated as decided.
//
//   Note also that the two real columns disagree about method: $28 is a
//   market conversion of ₦45,000, not its purchasing-power equivalent —
//   PPP against Nigeria would put the US price considerably higher. I
//   have kept $28 because it is the number this page already showed and
//   raising it is a commercial call, not a formatting one. Worth
//   deciding deliberately before this is judged.
//
// ADDING A REGION is one entry below. No component changes.

/// A pricing region: the currency to display, and what each paid plan
/// costs there.
class Region {
  const Region({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.proPrice,
    required this.businessPrice,
    this.symbolLeads = true,
  });

  /// ISO-3166 alpha-2, or a group code. 'XX' is the fallback.
  final String code;
  final String name;

  /// ISO-4217. Shown where the symbol alone is ambiguous — '$' means at
  /// least a dozen different currencies.
  final String currencyCode;
  final String currencySymbol;

  /// Per month, in MAJOR units (not minor/cents). DISPLAY VALUES ONLY.
  /// The server holds the authoritative minor-unit amount it charges;
  /// no payment may ever be built from these numbers.
  final num proPrice;
  final num businessPrice;

  /// Whether the symbol precedes the amount. False for most European
  /// conventions, which write "10 €".
  final bool symbolLeads;

  /// Formats an amount in this region's currency — "$28", "₦45,000".
  String format(num amount) {
    final whole = amount.round();
    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return symbolLeads ? '$currencySymbol$s' : '$s $currencySymbol';
  }

  /// The yearly-billing monthly rate — 15% off, matching the toggle copy.
  ///
  /// Rounded to a whole unit. For low-denomination currencies that is
  /// invisible; for Naira it avoids showing "₦38,250.00".
  num yearlyRate(num monthly) => (monthly * 0.85).round();
}

abstract class Regions {
  /// The default. Deliberately NOT named "United States" — it is what
  /// every unrecognised market sees, and naming it after one country
  /// invites pricing the whole world like that country.
  static const international = Region(
    code: 'XX',
    name: 'International',
    currencyCode: 'USD',
    currencySymbol: r'$',
    proPrice: 28,
    businessPrice: 75,
  );

  /// The settled prices. This is the one column that is not a guess.
  static const nigeria = Region(
    code: 'NG',
    name: 'Nigeria',
    currencyCode: 'NGN',
    currencySymbol: '₦',
    proPrice: 45000,
    businessPrice: 120000,
  );

  // ── Placeholders, at rough PPP against the Naira figure ────────────

  static const kenya = Region(
    code: 'KE',
    name: 'Kenya',
    currencyCode: 'KES',
    currencySymbol: 'KSh',
    proPrice: 4000,
    businessPrice: 11000,
  );

  static const ghana = Region(
    code: 'GH',
    name: 'Ghana',
    currencyCode: 'GHS',
    currencySymbol: '₵',
    proPrice: 400,
    businessPrice: 1100,
  );

  static const southAfrica = Region(
    code: 'ZA',
    name: 'South Africa',
    currencyCode: 'ZAR',
    currencySymbol: 'R',
    proPrice: 600,
    businessPrice: 1600,
  );

  static const brazil = Region(
    code: 'BR',
    name: 'Brazil',
    currencyCode: 'BRL',
    currencySymbol: r'R$',
    proPrice: 160,
    businessPrice: 430,
  );

  static const india = Region(
    code: 'IN',
    name: 'India',
    currencyCode: 'INR',
    currencySymbol: '₹',
    proPrice: 2250,
    businessPrice: 6000,
  );

  static const all = [
    international, nigeria, kenya, ghana, southAfrica, brazil, india,
  ];

  /// Resolves a region from a country code, falling back to
  /// [international]. Unknown input NEVER throws — an unrecognised
  /// country must see a working price, not an error page.
  static Region fromCountryCode(String? code) {
    if (code == null || code.isEmpty) return international;
    final upper = code.toUpperCase();
    for (final r in all) {
      if (r.code == upper) return r;
    }
    return international;
  }
}
