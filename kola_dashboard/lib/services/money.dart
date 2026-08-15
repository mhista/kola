// money.dart — display and parse prices without ever using a double.
//
// ── WHY THIS EXISTS AS A FILE ────────────────────────────────────────
//
// The server stores prices as an integer count of the currency's
// smallest unit (kobo for NGN) — see product.spy.yaml. The catalog
// editor takes "4500" from an owner who means four thousand five
// hundred naira. Something has to sit between those, and the moment it
// is written inline in a page it gets written slightly differently in
// the next page.
//
// The rule this file exists to hold: NO STEP OF A PRICE IS EVER A
// DOUBLE. `4500.10` cannot be represented exactly in binary floating
// point, so `(4500.10 * 100).round()` is a coin flip on the last kobo.
// Parsing splits on the decimal point and works in integers throughout.
//
// ── DECIMALS ARE PER CURRENCY ────────────────────────────────────────
//
// NGN and USD have two. Others have none — ¥100 is one hundred yen, not
// one yen. A shared "divide by 100" would price a zero-decimal currency
// a hundred times wrong, which is the specific mistake
// WorkspaceEndpoint.getBillingSummary already returns `priceDecimals` to
// prevent. Only the currencies kolaa actually quotes in are listed;
// anything unknown gets two, which is the common case and is stated
// here rather than assumed silently.

abstract class Money {
  /// Symbols for the currencies kolaa quotes in. An unlisted currency
  /// falls back to its own code — "KES 4,500" is honest and readable,
  /// whereas guessing a symbol produces the wrong country's money.
  static const _symbols = <String, String>{
    'NGN': '₦',
    'USD': '\$',
    'GBP': '£',
    'EUR': '€',
    'GHS': 'GH₵',
    'KES': 'KSh',
    'ZAR': 'R',
  };

  /// Currencies with no minor unit. See the header.
  static const _zeroDecimal = <String>{'JPY', 'KRW', 'VND', 'XOF', 'XAF'};

  static int decimalsFor(String currency) =>
      _zeroDecimal.contains(currency.toUpperCase()) ? 0 : 2;

  static String symbolFor(String currency) {
    final code = currency.toUpperCase();
    return _symbols[code] ?? '$code ';
  }

  /// "₦4,500" / "₦4,500.50" / "$18,500".
  ///
  /// Trailing zeros in the minor part are dropped, so a whole-naira
  /// price reads "₦4,500" rather than "₦4,500.00" — a price list of
  /// round numbers should not be a wall of decimal zeros. A price with
  /// real kobo keeps them.
  static String format(int minor, String currency) {
    final decimals = decimalsFor(currency);
    final symbol = symbolFor(currency);

    if (decimals == 0) return '$symbol${_group(minor.abs())}';

    final unit = minor.abs() ~/ 100;
    final frac = minor.abs() % 100;
    final sign = minor < 0 ? '-' : '';

    if (frac == 0) return '$sign$symbol${_group(unit)}';
    return '$sign$symbol${_group(unit)}.${frac.toString().padLeft(2, '0')}';
  }

  /// What an owner typed, as minor units. Null when it is not a price.
  ///
  /// Returning null rather than 0 for unparseable input is the whole
  /// point: 0 is a real price meaning "free", and an empty or mistyped
  /// box must never become one.
  ///
  /// Accepts a leading symbol, thousands separators and surrounding
  /// space, because people paste prices out of their own price lists.
  static int? parse(String input, String currency) {
    var s = input.trim();
    if (s.isEmpty) return null;

    // Strip everything that is not a digit, a dot or a minus. This
    // removes the symbol and any grouping commas in one pass.
    s = s.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (s.isEmpty || s == '-' || s == '.') return null;

    final negative = s.startsWith('-');
    if (negative) s = s.substring(1);

    final decimals = decimalsFor(currency);
    if (decimals == 0) {
      final whole = int.tryParse(s.split('.').first);
      if (whole == null) return null;
      return negative ? -whole : whole;
    }

    final parts = s.split('.');
    // "4.5.6" is a typo, not a price. Refused rather than read as 4.5.
    if (parts.length > 2) return null;

    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (whole == null) return null;

    var frac = 0;
    if (parts.length == 2 && parts[1].isNotEmpty) {
      // Pad "5" to "50" and truncate "567" to "56". Truncating rather
      // than rounding, so a price can never come out higher than the
      // one the owner typed.
      final digits = parts[1].padRight(2, '0').substring(0, 2);
      frac = int.tryParse(digits) ?? 0;
    }

    final total = whole * 100 + frac;
    return negative ? -total : total;
  }

  /// Minor units back into the plain string an editor field shows.
  /// "450000" → "4500", "450050" → "4500.50". No symbol, no grouping:
  /// this goes into an input the owner will type over.
  static String toInput(int minor, String currency) {
    if (decimalsFor(currency) == 0) return minor.toString();
    final unit = minor ~/ 100;
    final frac = minor % 100;
    if (frac == 0) return unit.toString();
    return '$unit.${frac.toString().padLeft(2, '0')}';
  }

  /// Thousands separators, done by hand.
  ///
  /// `package:intl` is not a dependency of kola_dashboard and pulling it
  /// in for one grouping rule would add a locale database to every
  /// browser download. Kola's markets all group in threes.
  static String _group(int value) {
    final digits = value.toString();
    if (digits.length <= 3) return digits;

    final buffer = StringBuffer();
    final firstGroup = digits.length % 3;
    if (firstGroup > 0) buffer.write(digits.substring(0, firstGroup));

    for (var i = firstGroup; i < digits.length; i += 3) {
      if (buffer.isNotEmpty) buffer.write(',');
      buffer.write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }
}
