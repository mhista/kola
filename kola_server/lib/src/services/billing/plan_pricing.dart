// plan_pricing.dart
//
// What Kola charges a workspace for its own Pro plan, by region.
//
// ── WHY REGIONAL AND NOT ONE CONVERTED PRICE ─────────────────────────
//   A number that works in Lagos is trivial in London, and a number that
//   works in London is impossible in Lagos. A single global price
//   converted at the day's rate would either close the emerging markets
//   this product is built for, or leave most of the revenue on the table
//   in wealthy ones. So prices are set per region at rough
//   purchasing-power parity — the model Spotify, Netflix and JetBrains
//   use.
//
// ── THIS FILE MUST AGREE WITH kola_landing/lib/i18n/region.dart ──────
//   The landing page quotes a price; this file charges it. If they drift,
//   a customer is shown one number and billed another — which is the
//   worst class of pricing bug there is, because it looks like deception
//   rather than a mistake. Any change here needs the same change there.
//
//   They are deliberately NOT shared code: the landing page is a public
//   client bundle and the server is trusted. The server is authoritative
//   — [priceFor] is what actually gets charged, and a client can never
//   influence it.
//
// ── AMOUNTS ARE IN THE CURRENCY'S SMALLEST UNIT ──────────────────────
//   Same convention as PaymentTransaction.amountKobo, and the same trap:
//   "smallest unit" is NOT always 1/100. JPY, KRW, XOF and others have no
//   minor unit at all — see StripeService.zeroDecimalCurrencies. Each
//   entry below states its own multiplier rather than assuming.

import 'stripe_service.dart';

/// One region's Pro-plan price and how Kola collects it.
class RegionalPrice {
  const RegionalPrice({
    required this.regionCode,
    required this.currency,
    required this.amountMinor,
    required this.gateway,
  });

  /// ISO-3166 alpha-2, or 'XX' for the international default.
  final String regionCode;

  /// ISO-4217.
  final String currency;

  /// In [currency]'s smallest unit. See this file's header.
  final int amountMinor;

  /// Which of KOLA'S OWN gateway accounts collects this — not the
  /// business's. Kola's Paystack account cannot charge a card in Brazil,
  /// and Stripe is not the practical choice for naira, so the gateway
  /// genuinely varies by region rather than being a preference.
  final String gateway;

  /// Major units, for display and logging only. NEVER use this to build
  /// a charge — [amountMinor] is the authoritative value.
  num get displayAmount => StripeService.isZeroDecimal(currency)
      ? amountMinor
      : amountMinor / 100;
}

abstract class PlanPricing {
  /// Nigeria — ₦10,000/month. CONFIRMED WITH THE USER (2026-07-27). The
  /// only price here that is commercially settled.
  static const nigeria = RegionalPrice(
    regionCode: 'NG', currency: 'NGN', amountMinor: 1000000, gateway: 'paystack',
  );

  // ── EVERYTHING BELOW IS A PLACEHOLDER ──────────────────────────────
  // Set at rough purchasing-power parity with the Nigerian price, NOT
  // converted from it, and NOT commercially confirmed. Treat every one
  // as provisional and revisit before it bills a real customer.
  static const kenya = RegionalPrice(
    regionCode: 'KE', currency: 'KES', amountMinor: 90000, gateway: 'stripe',
  );
  static const ghana = RegionalPrice(
    regionCode: 'GH', currency: 'GHS', amountMinor: 9000, gateway: 'stripe',
  );
  static const southAfrica = RegionalPrice(
    regionCode: 'ZA', currency: 'ZAR', amountMinor: 13000, gateway: 'stripe',
  );
  static const brazil = RegionalPrice(
    regionCode: 'BR', currency: 'BRL', amountMinor: 3500, gateway: 'stripe',
  );
  static const india = RegionalPrice(
    regionCode: 'IN', currency: 'INR', amountMinor: 50000, gateway: 'stripe',
  );

  /// Every market not listed above. Deliberately not named after one
  /// country — naming it 'US' would invite pricing the whole world like
  /// the United States.
  static const international = RegionalPrice(
    regionCode: 'XX', currency: 'USD', amountMinor: 1200, gateway: 'stripe',
  );

  static const all = [
    nigeria, kenya, ghana, southAfrica, brazil, india, international,
  ];

  /// The price for a region code.
  ///
  /// Unknown or missing codes resolve to [international] and NEVER
  /// throw. A workspace with a region nobody anticipated must still be
  /// able to pay — failing here would mean a customer who wants to give
  /// you money cannot.
  static RegionalPrice forRegion(String? regionCode) {
    if (regionCode == null || regionCode.isEmpty) return international;
    final upper = regionCode.toUpperCase();
    for (final p in all) {
      if (p.regionCode == upper) return p;
    }
    return international;
  }

  /// Whether a gateway can actually collect for a region. Used to fail
  /// early with a clear message rather than at the gateway API, where
  /// the error is opaque.
  static bool gatewaySupports(String gateway, RegionalPrice price) =>
      gateway == price.gateway;
}
