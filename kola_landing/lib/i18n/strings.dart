// strings.dart
//
// Every user-visible string on the landing page.
//
// ── WHY A CLASS PER LOCALE, NOT A MAP ────────────────────────────────
//   A Map<String,String> lookup fails at RUNTIME — a missing key renders
//   as a blank, or a literal 'hero.title', in front of a customer. With
//   getters on a class, a missing string is impossible: the subclass
//   simply inherits it, and a TYPO in a key name is a compile error
//   rather than a blank space nobody notices until launch.
//
// ── WHY ENGLISH IS THE BASE CLASS, NOT AN INTERFACE ──────────────────
//   Because partial translation is the normal state of every real i18n
//   rollout, and this makes it safe. A locale translates what it has and
//   inherits the rest — so French can ship with thirty strings done and
//   the page still works end to end, in English where French is missing.
//   An abstract interface would force all ~50 strings to be translated
//   before a locale could exist at all, which in practice means no
//   locale ever ships.
//
//   The trade-off, stated: an untranslated string is silently English
//   rather than loudly missing. That is the right trade for a customer
//   (a readable page beats a broken one) and the wrong one for tracking
//   progress — so [Strings.translatedCount] exists to measure coverage
//   honestly instead of guessing.
//
// ── NO INTERPOLATION IN STORED STRINGS ───────────────────────────────
//   Anything with a value in it is a METHOD taking that value, not a
//   string with a placeholder to be find-and-replaced. Word order
//   differs between languages, and a translator moving a placeholder is
//   a normal thing to do — a method lets them.

import 'locale.dart';

/// English. Also the fallback for every other locale.
class Strings {
  const Strings();

  Locale get locale => Locales.en;

  // ── Navigation ────────────────────────────────────────────────────
  String get navProduct => 'Product';
  String get navSalesCounter => 'Sales counter';
  String get navDocs => 'Docs';
  String get navPricing => 'Pricing';
  String get navChangelog => 'Changelog';
  String get ctaStartFree => 'Start free';
  String get ctaJoinWaitlist => 'Join waitlist';
  String get ctaSending => 'Sending…';

  // ── Hero ──────────────────────────────────────────────────────────
  String get heroEyebrow => 'The operating intelligence layer for businesses';
  String get heroTitleLine1 => 'Your business already has the data.';
  String get heroTitleLine2 => 'kolaa turns it into decisions.';
  String get heroSubtitle =>
      'It connects the tools you already use, remembers every conversation '
      'and document, watches what is happening across your business, and '
      'gets the next step done — with your approval.';
  String get heroWaitlistPrompt =>
      "kolaa isn't live yet — join the waitlist and we'll message you the "
      "moment it's your turn.";
  String get heroLaunchedPrompt => 'Start free — no card required.';
  String get heroEmailPlaceholder => 'Email address';
  String get heroSuccessTitle => "You're on the list.";
  String get heroSuccessBody => "We'll message you as soon as it's your turn.";
  String get errorEmailRequired => 'Please enter your email address.';
  String get errorGeneric => 'Something went wrong — please try again.';

  // ── Proof / demo ──────────────────────────────────────────────────
  String get proofEyebrow => 'See it work — no login required';
  String get proofTitle => 'Every answer cites its source.';
  String get proofSubtitle =>
      "kolaa isn't live yet, so instead of a testimonial, here's the thing "
      'itself. Paste something you would teach it, then ask a question a '
      'customer might send.';
  String get demoStep1 => '1. Teach it something';
  String get demoStep2 => '2. Ask what a customer would ask';
  String get demoQuestionPlaceholder => 'e.g. Can I return this after a week?';
  String get demoAsk => 'Ask kolaa';
  String get demoIdle => 'The answer, with its source, appears here.';
  String get demoNoMatch =>
      "I don't have that in what you gave me — I'd pass this to a person "
      'rather than guess.';
  String get demoNoMatchLabel => 'No matching section — kolaa never invents an answer';
  String get demoPrivacyNote =>
      'Nothing leaves your browser — this demo runs entirely on your device. '
      'It matches on words; the real kolaa matches on meaning, so it finds '
      'answers this demo will miss.';

  /// Interpolated — a METHOD, not a template. See this file's header.
  String demoMatchLabel(int percent, int section) =>
      '$percent% match — answered from your text (section $section)';

  // ── Sections ──────────────────────────────────────────────────────
  String get problemsTitle => 'The same problems, every day.';
  String get howEyebrow => 'How it works';
  String get howTitle => 'Connect. It learns. It works. You approve.';
  String get memoryEyebrow => 'Business memory';
  String get commerceEyebrow => 'Sales counter';
  String get commerceTitle => 'It runs your counter. And learns from every sale.';
  String get commerceOfflineTitle => 'No data? Keep selling.';
  String get commerceOptional =>
      'Optional. If you do not sell products, you will never see it.';
  String get capabilitiesTitle => 'Watches, explains, and acts.';
  String get timelineEyebrow => 'Business timeline';
  String get securityTitle => 'Built to hold real business data.';
  String get integrationsTitle =>
      'Connects to what you already use — more added regularly';
  String get faqTitle => 'Questions, answered.';

  // ── Pricing ───────────────────────────────────────────────────────
  String get pricingTitle => 'Simple pricing.';
  String get pricingWaitlistNote =>
      'Launching soon — join the waitlist to lock in this pricing';
  String get planFree => 'Free';
  String get planFreeSub => 'Everything you need to start';
  String get planPro => 'Pro';
  String get planProSub => '48-hour full trial, then step-down';
  String get planPopular => 'Most popular';
  String get pricingNoSurprisesTitle => 'No surprises on the bill.';
  String get pricingNoSurprisesBody =>
      'One monthly price. No setup fee, no charge for the sales counter, '
      'and nothing added on top of what your messaging provider charges. '
      'Where a message does cost something, kolaa shows you before it '
      'sends and takes the cheaper route when there is one.';

  String pricingRegionNote(String currencyCode) =>
      'Shown in $currencyCode. Pricing is set per region, so it reflects '
      'what a business in that market can actually pay.';

  // ── What it replaces ──────────────────────────────────────────────
  String get replacesTitle => 'What it replaces.';
  String replacesSubtitle(String price) =>
      'kolaa is $price a month. Worth comparing that against what it stands in for.';

  // ── Footer ────────────────────────────────────────────────────────
  String get footerBlurb =>
      'kolaa connects your tools, remembers everything, runs your counter, '
      'and gets the next step done — on WhatsApp and Telegram, no '
      'developer required.';
  String get footerRights =>
      '© 2026 kolaa. Made for businesses that never open a laptop.';

  /// How many strings this locale actually translates, for honest
  /// coverage reporting. English is by definition complete.
  int get translatedCount => -1;
}

// ─────────────────────────────────────────────────────────────────────
// Other locales override what they have translated and inherit the rest.
// Partial coverage is expected and safe — see this file's header.
// ─────────────────────────────────────────────────────────────────────

class StringsFr extends Strings {
  const StringsFr();
  @override
  Locale get locale => Locales.fr;

  @override
  String get navProduct => 'Produit';
  @override
  String get navSalesCounter => 'Caisse';
  @override
  String get navPricing => 'Tarifs';
  @override
  String get ctaStartFree => 'Commencer gratuitement';
  @override
  String get ctaJoinWaitlist => "Rejoindre la liste d'attente";
  @override
  String get heroTitleLine1 => 'Votre entreprise a déjà les données.';
  @override
  String get heroTitleLine2 => 'kolaa les transforme en décisions.';
  @override
  String get heroEmailPlaceholder => 'Adresse e-mail';
  @override
  String get pricingTitle => 'Des tarifs simples.';
  @override
  String get planFree => 'Gratuit';
  @override
  String get faqTitle => 'Questions, répondues.';
  @override
  int get translatedCount => 11;
}

class StringsPt extends Strings {
  const StringsPt();
  @override
  Locale get locale => Locales.pt;

  @override
  String get navProduct => 'Produto';
  @override
  String get navSalesCounter => 'Balcão de vendas';
  @override
  String get navPricing => 'Preços';
  @override
  String get ctaStartFree => 'Começar grátis';
  @override
  String get ctaJoinWaitlist => 'Entrar na lista de espera';
  @override
  String get heroTitleLine1 => 'A sua empresa já tem os dados.';
  @override
  String get heroTitleLine2 => 'A kolaa transforma-os em decisões.';
  @override
  String get heroEmailPlaceholder => 'Endereço de e-mail';
  @override
  String get pricingTitle => 'Preços simples.';
  @override
  String get planFree => 'Grátis';
  @override
  String get faqTitle => 'Perguntas, respondidas.';
  @override
  int get translatedCount => 11;
}

class StringsEs extends Strings {
  const StringsEs();
  @override
  Locale get locale => Locales.es;

  @override
  String get navProduct => 'Producto';
  @override
  String get navSalesCounter => 'Mostrador de ventas';
  @override
  String get navPricing => 'Precios';
  @override
  String get ctaStartFree => 'Empezar gratis';
  @override
  String get ctaJoinWaitlist => 'Unirse a la lista de espera';
  @override
  String get heroTitleLine1 => 'Su negocio ya tiene los datos.';
  @override
  String get heroTitleLine2 => 'kolaa los convierte en decisiones.';
  @override
  String get heroEmailPlaceholder => 'Correo electrónico';
  @override
  String get pricingTitle => 'Precios sencillos.';
  @override
  String get planFree => 'Gratis';
  @override
  String get faqTitle => 'Preguntas, respondidas.';
  @override
  int get translatedCount => 11;
}

class StringsSw extends Strings {
  const StringsSw();
  @override
  Locale get locale => Locales.sw;

  @override
  String get navProduct => 'Bidhaa';
  @override
  String get navSalesCounter => 'Kaunta ya mauzo';
  @override
  String get navPricing => 'Bei';
  @override
  String get ctaStartFree => 'Anza bure';
  @override
  String get ctaJoinWaitlist => 'Jiunge na orodha ya kusubiri';
  @override
  String get heroTitleLine1 => 'Biashara yako tayari ina data.';
  @override
  String get heroTitleLine2 => 'kolaa inaibadilisha kuwa maamuzi.';
  @override
  String get heroEmailPlaceholder => 'Anwani ya barua pepe';
  @override
  String get pricingTitle => 'Bei rahisi.';
  @override
  String get planFree => 'Bure';
  @override
  String get faqTitle => 'Maswali, yamejibiwa.';
  @override
  int get translatedCount => 11;
}

/// The strings for a locale. Unknown locales get English.
Strings stringsFor(Locale locale) => switch (locale.code) {
      'fr' => const StringsFr(),
      'pt' => const StringsPt(),
      'es' => const StringsEs(),
      'sw' => const StringsSw(),
      _ => const Strings(),
    };
