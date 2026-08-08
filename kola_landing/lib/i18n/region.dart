// region.dart
//
// Region, currency and pricing. ONE file decides what a visitor is shown
// as a price, and nothing else in the app hardcodes a currency symbol.
//
// WHY THIS EXISTS: Kola started Nigeria-first, and it showed — "₦10,000",
// "priced for Naija" and "Nigerian SMEs" were baked into component
// markup. Nothing about the product is Nigeria-specific: a business in
// Nairobi, São Paulo or Manila has the same problem and connects its own
// payment provider exactly the same way. The geography was in the copy,
// not the product.
//
// PRICING IS REGIONAL BY PURCHASING POWER, not a single converted price.
// The model Spotify, Netflix and JetBrains use, and the right one here:
// a number that works in Lagos is trivial in London, and a number that
// works in London is impossible in Lagos. A single global price would
// either close the emerging markets this product is built for, or leave
// most of the revenue on the table in wealthy ones.
//
// ADDING A REGION is one entry below. No component changes.

/// A pricing region: the currency to display and what Pro costs there.
class Region {
  const Region({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
    required this.proPrice,
    required this.symbolLeads,
  });

  /// ISO-3166 alpha-2, or a group code like 'EU'. 'XX' is the fallback.
  final String code;
  final String name;

  /// ISO-4217. Shown in contexts where the symbol alone is ambiguous —
  /// '$' means at least a dozen different currencies.
  final String currencyCode;
  final String currencySymbol;

  /// Pro plan, per month, in MAJOR units (not minor/cents) — this is a
  /// display value. The server holds the authoritative minor-unit amount
  /// it actually charges; this must never be the number a payment is
  /// built from.
  final num proPrice;

  /// Whether the symbol precedes the amount. False for most European
  /// conventions, which write "10 €".
  final bool symbolLeads;

  /// Formatted with thousands separators — "₦10,000", "$12", "1 200 KES".
  String get formattedProPrice {
    final whole = proPrice.round();
    final digits = whole.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final amount = buf.toString();
    return symbolLeads ? '$currencySymbol$amount' : '$amount $currencySymbol';
  }
}

abstract class Regions {
  // Prices below are DISPLAY PLACEHOLDERS outside Nigeria and are not yet
  // confirmed commercially. Only the Nigerian price is settled. They are
  // set at rough purchasing-power parity with ₦10,000 rather than a
  // market-rate conversion of it — see this file's header.
  static const nigeria = Region(
    code: 'NG', name: 'Nigeria',
    currencyCode: 'NGN', currencySymbol: '₦',
    proPrice: 10000, symbolLeads: true,
  );

  static const kenya = Region(
    code: 'KE', name: 'Kenya',
    currencyCode: 'KES', currencySymbol: 'KSh',
    proPrice: 900, symbolLeads: true,
  );

  static const ghana = Region(
    code: 'GH', name: 'Ghana',
    currencyCode: 'GHS', currencySymbol: '₵',
    proPrice: 90, symbolLeads: true,
  );

  static const southAfrica = Region(
    code: 'ZA', name: 'South Africa',
    currencyCode: 'ZAR', currencySymbol: 'R',
    proPrice: 130, symbolLeads: true,
  );

  static const brazil = Region(
    code: 'BR', name: 'Brazil',
    currencyCode: 'BRL', currencySymbol: r'R$',
    proPrice: 35, symbolLeads: true,
  );

  static const india = Region(
    code: 'IN', name: 'India',
    currencyCode: 'INR', currencySymbol: '₹',
    proPrice: 500, symbolLeads: true,
  );

  /// Everywhere not listed above. Deliberately NOT called "United
  /// States" — it is the default for any unrecognised market, and naming
  /// it after one country would invite pricing the whole world like that
  /// country.
  static const international = Region(
    code: 'XX', name: 'International',
    currencyCode: 'USD', currencySymbol: r'$',
    proPrice: 12, symbolLeads: true,
  );

  static const all = [
    nigeria, kenya, ghana, southAfrica, brazil, india, international,
  ];

  /// Resolves a region from a country code, falling back to
  /// [international]. Unknown input NEVER throws — an unrecognised
  /// country must see a working price, not an error.
  static Region fromCountryCode(String? code) {
    if (code == null || code.isEmpty) return international;
    final upper = code.toUpperCase();
    for (final r in all) {
      if (r.code == upper) return r;
    }
    return international;
  }
}
