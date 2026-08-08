// stripe_service.dart
//
// Stripe, as a third BYO-credential payment gateway alongside Paystack
// and Flutterwave. Same shape as both: a business connects its OWN
// Stripe secret key, money goes straight to that business's own Stripe
// account, and Kola never touches the funds.
//
// WHY STRIPE WAS ADDED: nothing about this product is country-specific.
// A shop in Nairobi, São Paulo or Manila has the same problem as one in
// Lagos, and the only thing that was stopping them was that Kola spoke
// exclusively to two African gateways. Stripe covers most of the rest of
// the world. The set of supported gateways is meant to grow — see
// [validPaymentGateways] in payment_checkout_service.dart, which is the
// one list that needs touching to add another.
//
// ── THREE REAL DIFFERENCES FROM PAYSTACK/FLUTTERWAVE ─────────────────
//
// 1. FORM ENCODING, NOT JSON. Stripe's API takes
//    application/x-www-form-urlencoded, including for nested fields,
//    which use bracket syntax (`line_items[0][price_data][currency]`).
//    Sending JSON to Stripe fails; this is not a stylistic choice.
//
// 2. ZERO-DECIMAL CURRENCIES. Every gateway here takes amounts in the
//    currency's smallest unit, but Stripe has currencies with NO minor
//    unit at all — JPY, KRW and others. For those, ¥1000 is `1000`, not
//    `100000`. Getting this backwards charges a customer 100× the
//    intended amount, so [zeroDecimalCurrencies] exists and callers must
//    respect it. This is the single most dangerous detail in this file.
//
// 3. WEBHOOK SIGNATURES ARE TIMESTAMPED. Stripe signs
//    `{timestamp}.{body}` rather than the body alone, and sends both in
//    one `Stripe-Signature` header. That defeats replay attacks, and it
//    means the header has to be parsed rather than compared directly —
//    see [verifyWebhookSignature].

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

class StripeService {
  StripeService({required this.secretKey});

  final String secretKey;

  static const _baseUrl = 'https://api.stripe.com/v1';

  /// Currencies with no minor unit — an amount is the whole unit, not
  /// hundredths of it. See this file's header: treating one of these as
  /// two-decimal charges 100× the intended amount.
  ///
  /// From Stripe's published zero-decimal list. Kept here rather than
  /// fetched so that a network failure can never silently change how an
  /// amount is interpreted.
  static const zeroDecimalCurrencies = {
    'BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF', 'KRW', 'MGA',
    'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
  };

  static bool isZeroDecimal(String currency) =>
      zeroDecimalCurrencies.contains(currency.toUpperCase());

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

  /// Cheap authenticated call used to PROBE a key before persisting it —
  /// same probe-before-persist rule every other BYO-credential connect
  /// flow in this codebase follows (see ChannelEndpoint's Telegram and
  /// WhatsApp connects). Retrieving the account is read-only and does
  /// not create anything.
  Future<Map<String, dynamic>> retrieveAccount() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/account'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Stripe account probe failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Creates a hosted Checkout Session and returns the raw response —
  /// `url` is where the customer should be sent to pay, `id` is what
  /// [retrieveCheckoutSession] later needs.
  ///
  /// [amount] is in the currency's SMALLEST unit, consistent with the
  /// other gateway services here — except for the zero-decimal
  /// currencies above, where smallest unit IS the whole unit. Callers
  /// should use [isZeroDecimal] rather than assuming two decimals.
  ///
  /// A hosted session is used rather than PaymentIntents deliberately:
  /// it keeps card data entirely on Stripe's own page, so Kola never
  /// handles card details and the business inherits Stripe's compliance
  /// posture rather than needing its own.
  Future<Map<String, dynamic>> createCheckoutSession({
    required String currency,
    required int amount,
    required String productName,
    String? customerEmail,
    String? successUrl,
    String? cancelUrl,
    String? clientReferenceId,
    Map<String, String>? metadata,
  }) async {
    // Stripe takes form encoding with bracketed nested keys — see this
    // file's header on why JSON does not work here.
    final form = <String, String>{
      'mode': 'payment',
      'line_items[0][quantity]': '1',
      'line_items[0][price_data][currency]': currency.toLowerCase(),
      'line_items[0][price_data][unit_amount]': amount.toString(),
      'line_items[0][price_data][product_data][name]': productName,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (successUrl != null) 'success_url': successUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
      if (clientReferenceId != null) 'client_reference_id': clientReferenceId,
    };
    metadata?.forEach((k, v) => form['metadata[$k]'] = v);

    final response = await http.post(
      Uri.parse('$_baseUrl/checkout/sessions'),
      headers: _headers,
      body: form,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Stripe checkout session failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetches a session's final state.
  ///
  /// Callers MUST check `payment_status == 'paid'` and the amount
  /// themselves — a 200 response only means the API call worked, not
  /// that the customer paid. Same rule as Paystack's verifyTransaction,
  /// and the same reason: never trust a webhook body or a bare 200,
  /// always re-verify with the gateway directly.
  Future<Map<String, dynamic>> retrieveCheckoutSession(String sessionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/checkout/sessions/$sessionId'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Stripe session retrieve failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Verifies a `Stripe-Signature` header.
  ///
  /// Stripe signs `{timestamp}.{rawBody}` with HMAC-SHA256 and sends
  /// `t=<unix>,v1=<hex>[,v1=<hex>...]`. Multiple v1 values appear during
  /// a signing-secret rotation, and ANY of them matching is valid — so
  /// this checks all of them rather than only the first.
  ///
  /// [rawBody] must be the UNPARSED request body. Re-serialising the
  /// JSON can change key order or whitespace and silently fail the
  /// check — the same trap documented in paystack_service.dart.
  ///
  /// [toleranceSeconds] rejects timestamps outside a window, which is
  /// what actually defeats replay: without it, a captured valid request
  /// stays valid forever.
  bool verifyWebhookSignature({
    required String rawBody,
    required String? signatureHeader,
    required String webhookSecret,
    int toleranceSeconds = 300,
    DateTime? now,
  }) {
    if (signatureHeader == null || signatureHeader.isEmpty) return false;
    if (webhookSecret.isEmpty) return false;

    String? timestamp;
    final signatures = <String>[];
    for (final part in signatureHeader.split(',')) {
      final kv = part.trim().split('=');
      if (kv.length != 2) continue;
      if (kv[0] == 't') timestamp = kv[1];
      if (kv[0] == 'v1') signatures.add(kv[1]);
    }
    if (timestamp == null || signatures.isEmpty) return false;

    final sent = int.tryParse(timestamp);
    if (sent == null) return false;
    final current =
        ((now ?? DateTime.now()).millisecondsSinceEpoch / 1000).floor();
    if ((current - sent).abs() > toleranceSeconds) return false;

    final hmac = HMac(SHA256Digest(), 64)
      ..init(KeyParameter(Uint8List.fromList(utf8.encode(webhookSecret))));
    final computed = hmac
        .process(Uint8List.fromList(utf8.encode('$timestamp.$rawBody')))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    // Constant-time-ish comparison: compare every candidate fully rather
    // than short-circuiting on first mismatch.
    var matched = false;
    for (final sig in signatures) {
      if (sig.length != computed.length) continue;
      var diff = 0;
      for (var i = 0; i < sig.length; i++) {
        diff |= sig.codeUnitAt(i) ^ computed.codeUnitAt(i);
      }
      if (diff == 0) matched = true;
    }
    return matched;
  }
}
