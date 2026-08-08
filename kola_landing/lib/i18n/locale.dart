// locale.dart
//
// The five languages Kola ships in, and the machinery for picking one.
//
// WHY THESE FIVE: the product's fit is not "Africa", it is WhatsApp-first
// SME commerce — Nigeria, Kenya, Brazil, Mexico, Indonesia, India. Those
// markets run on English, French, Portuguese, Spanish and Swahili far
// more than on anything else. Portuguese and Spanish in particular reach
// Latin America, where the "business runs out of a WhatsApp inbox"
// pattern is arguably larger than anywhere in Africa.
//
// WHY NOT ARABIC (yet): it would be the obvious sixth, and it is
// deliberately deferred rather than forgotten. Arabic is right-to-left,
// and RTL is not a translation job — it is a layout job across every
// screen, worst on the sales counter and printed receipts. Shipping it
// badly would be worse than not shipping it.
//
// BUT THE SYSTEM IS RTL-CAPABLE FROM DAY ONE. [Locale.direction] exists,
// components read it rather than assuming, and adding Arabic later is a
// language pack plus layout work — not a rewrite. Building the escape
// hatch costs almost nothing now and a great deal later.

enum TextDirection { ltr, rtl }

class Locale {
  const Locale({
    required this.code,
    required this.englishName,
    required this.nativeName,
    this.direction = TextDirection.ltr,
  });

  /// ISO-639-1. Used for the `lang` attribute and for persistence.
  final String code;

  /// For internal listings and admin tooling.
  final String englishName;

  /// What a speaker of the language calls it. ALWAYS what a language
  /// picker shows — a French speaker looks for "Français", not "French",
  /// and showing the English name to someone who does not read English
  /// defeats the purpose of offering the language at all.
  final String nativeName;

  final TextDirection direction;

  bool get isRtl => direction == TextDirection.rtl;

  /// For the `dir` attribute on <html>.
  String get dirAttribute => isRtl ? 'rtl' : 'ltr';
}

abstract class Locales {
  static const en = Locale(code: 'en', englishName: 'English',    nativeName: 'English');
  static const fr = Locale(code: 'fr', englishName: 'French',     nativeName: 'Français');
  static const pt = Locale(code: 'pt', englishName: 'Portuguese', nativeName: 'Português');
  static const es = Locale(code: 'es', englishName: 'Spanish',    nativeName: 'Español');
  static const sw = Locale(code: 'sw', englishName: 'Swahili',    nativeName: 'Kiswahili');

  /// Order matters — this is the order a language picker renders.
  static const all = [en, fr, pt, es, sw];

  static const fallback = en;

  /// Resolves a language tag to a supported locale.
  ///
  /// Handles the regional forms a browser actually sends — 'pt-BR',
  /// 'fr-CI', 'en-NG' — by matching on the primary subtag only. Kola
  /// does not distinguish Brazilian from European Portuguese today; if
  /// that ever matters it becomes a separate locale rather than a
  /// special case here.
  ///
  /// NEVER throws. An unsupported language falls back to English, which
  /// is the right failure: a working page in the wrong language beats a
  /// broken one in the right language.
  static Locale resolve(String? languageTag) {
    if (languageTag == null || languageTag.isEmpty) return fallback;
    final primary = languageTag.split(RegExp(r'[-_]')).first.toLowerCase();
    for (final locale in all) {
      if (locale.code == primary) return locale;
    }
    return fallback;
  }

  /// Picks the best supported locale from a browser's ordered preference
  /// list (navigator.languages). Respects the user's ranking rather than
  /// taking the first entry — someone whose list is ['de', 'fr', 'en']
  /// should get French, not English.
  static Locale resolveBest(List<String> preferred) {
    for (final tag in preferred) {
      final primary = tag.split(RegExp(r'[-_]')).first.toLowerCase();
      for (final locale in all) {
        if (locale.code == primary) return locale;
      }
    }
    return fallback;
  }
}
