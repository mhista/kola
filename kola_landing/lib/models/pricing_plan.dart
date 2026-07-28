// pricing_plan.dart
//
// Plain data holder for one pricing card. Values match PRD.md §10's
// Naira pricing and the plan table in Kola Landing.dc.html — kept as data
// (in pricing_section.dart's planDefs) rather than hardcoded markup so
// updating a price is a one-line change, not a markup hunt.

class PricingPlan {
  const PricingPlan({
    required this.name,
    required this.badge,
    required this.monthlyPriceNgn,
    required this.usdEquivalent,
    required this.features,
    required this.ctaLabel,
    this.popular = false,
  });

  final String name;
  final String badge;

  /// Naira price per month. Yearly billing is computed as a 15% discount
  /// on 12x this value (matches the "save 15%" toggle copy).
  final int monthlyPriceNgn;
  final String usdEquivalent;
  final List<String> features;
  final String ctaLabel;
  final bool popular;

  /// Formats a Naira amount with thousands separators, e.g. 45000 → "₦45,000".
  static String formatNgn(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '₦${buffer.toString()}';
  }

  String priceLabel({required bool yearly}) {
    if (monthlyPriceNgn == 0) return formatNgn(0);
    if (!yearly) return formatNgn(monthlyPriceNgn);
    final yearlyMonthly = (monthlyPriceNgn * 0.85).round();
    return formatNgn(yearlyMonthly);
  }
}
