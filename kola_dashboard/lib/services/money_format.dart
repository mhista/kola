// money_format.dart — one comma-grouped, symbol-prefixed formatter for
// money already in a currency's smallest unit (kobo for NGN), used by
// the sales counter and its receipts.
//
// WHY THIS EXISTS RATHER THAN toStringAsFixed(2)
//
// Kola Till.dc.html and Kola Documents.dc.html both format every amount
// as whole units with thousands separators — '₦4,500', never '₦4,500.00'
// — matching how Naira prices are actually quoted in the shops this
// product is built for. No `intl` package is a dependency of
// kola_dashboard, so this is a small hand-rolled grouping function
// rather than pulling in a package for one job.
//
// Rounds to the nearest whole unit rather than truncating — a price of
// 450050 minor units (₦4,500.50) reads as ₦4,501, never silently
// dropped to ₦4,500, which would understate what was actually charged.

String formatMinor(int minorUnits, {String symbol = '₦'}) {
  final whole = (minorUnits / 100).round();
  final negative = whole < 0;
  final digits = whole.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return '$symbol${negative ? '-' : ''}$buffer';
}
