// pricing_plan.dart
//
// Plain data holder for one pricing card.
//
// ── CURRENCY LIVES IN Region, NOT HERE ───────────────────────────────
//
// This model used to hold `monthlyPriceNgn` and format Naira itself.
// That put a currency decision inside the plan definition, which meant
// showing any other currency required editing the plans — and it meant
// the ₦ symbol was compiled into three different places.
//
// A plan now names WHICH price it is (free, pro, business) and the
// active [Region] supplies the number and the symbol. Adding a market
// touches one file; adding a plan touches this one.

import '../i18n/region.dart';

/// Which price line a card reads from its region.
///
/// An enum rather than a raw number so a plan cannot silently disagree
/// with the region table — every plan resolves through [priceIn], and
/// there is no way to hand a card a price the region has not defined.
enum PlanTier { free, pro, business }

class PricingPlan {
  const PricingPlan({
    required this.name,
    required this.badge,
    required this.tier,
    required this.features,
    required this.ctaLabel,
    this.popular = false,
  });

  final String name;
  final String badge;
  final PlanTier tier;
  final List<String> features;
  final String ctaLabel;
  final bool popular;

  /// The monthly amount for this plan in [region], in major units.
  num priceIn(Region region) => switch (tier) {
        PlanTier.free => 0,
        PlanTier.pro => region.proPrice,
        PlanTier.business => region.businessPrice,
      };

  /// The formatted price, honouring the monthly/yearly toggle.
  ///
  /// Free stays formatted rather than becoming the word "Free": the card
  /// already says Free in its title, and a currency-formatted zero keeps
  /// the three cards visually aligned on the same baseline.
  String priceLabel({required Region region, required bool yearly}) {
    final monthly = priceIn(region);
    if (monthly == 0) return region.format(0);
    return region.format(yearly ? region.yearlyRate(monthly) : monthly);
  }
}
