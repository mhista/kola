// flutterwave_service.dart
//
// Low-level wrapper around Flutterwave's Standard payment flow — plain
// HTTPS calls via package:http, same role/shape as PaystackService in this
// same directory and WhatsAppService (whatsapp_service.dart): everything
// that needs to talk to Flutterwave does it THROUGH this, never builds an
// api.flutterwave.com URL directly.
//
// SCOPE — SAME "SERVICE EXISTS, NOT WIRED TO A CHECKOUT" FRAMING AS
// PAYSTACK: confirmed against Flutterwave's real, documented Standard
// flow (https://developer.flutterwave.com/docs/collecting-payments/standard)
// and its webhook signing scheme (https://developer.flutterwave.com/docs/webhooks —
// via search, since that page didn't render on direct fetch here; the
// verif-hash mechanism is corroborated by Flutterwave's own help-center
// article "What is a Secret Hash"). No Endpoint or dashboard button calls
// this yet — see paystack_service.dart's header for the full reasoning
// (no gateway-config table, no confirmed plan pricing/currency yet).
//
// AUTH MODEL: every call authenticates with Flutterwave's SECRET key as a
// Bearer token, same shape as PaystackService.
//
// VERIFY IS THE SOURCE OF TRUTH: Flutterwave's own guide is explicit that
// after a redirect back from checkout, you must call verify and check
// `data.status == 'successful'` AND `data.amount`/`data.currency` against
// what you actually expected — a `status=successful` on the REDIRECT query
// parameters alone is not sufficient, since redirects are client-supplied
// and can be spoofed. Same division of responsibility as PaystackService:
// this service returns the raw verify response; the amount/currency check
// belongs to whatever billing logic calls this once it exists.
//
// WEBHOOK VERIFICATION IS DIFFERENT FROM PAYSTACK'S: Flutterwave does NOT
// use an HMAC signature. Instead, you configure an arbitrary "secret hash"
// string in the Flutterwave dashboard, and every webhook request carries
// that exact string back in the `verif-hash` header — verification is a
// plain string comparison, not a cryptographic computation. (Flutterwave's
// docs also mention a newer HMAC-SHA256 `flutterwave-signature` header on
// some integrations, but the simple verif-hash check is the
// long-documented, universally-supported mechanism, so that's what
// [verifyWebhookSignature] implements here.)

import 'dart:convert';
import 'package:http/http.dart' as http;

class FlutterwaveService {
  FlutterwaveService({required this.secretKey});

  final String secretKey;

  static const _baseUrl = 'https://api.flutterwave.com/v3';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $secretKey',
    'Content-Type': 'application/json',
  };

  /// Starts a Standard-flow payment. [amount] is a plain decimal string in
  /// [currency]'s major unit (e.g. "5000" for ₦5,000 — unlike Paystack,
  /// Flutterwave does NOT want kobo/cents here). [txRef] must be unique
  /// per attempt — generate a fresh one per checkout, never reuse.
  /// Returns the raw decoded response — `data['link']` is the hosted
  /// checkout URL to redirect the customer to.
  Future<Map<String, dynamic>> initializePayment({
    required String txRef,
    required String amount,
    required String redirectUrl,
    required String customerEmail,
    String currency = 'NGN',
    String? customerName,
    String? customerPhoneNumber,
    Map<String, dynamic>? meta,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/payments'),
      headers: _headers,
      body: jsonEncode({
        'tx_ref': txRef,
        'amount': amount,
        'currency': currency,
        'redirect_url': redirectUrl,
        'customer': {
          'email': customerEmail,
          if (customerName != null) 'name': customerName,
          if (customerPhoneNumber != null) 'phonenumber': customerPhoneNumber,
        },
        if (meta != null) 'meta': meta,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Flutterwave initialize failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetches the final state of a transaction by Flutterwave's own
  /// [transactionId] (the `data.id` field from the redirect query params
  /// or the initialize response — NOT [txRef], which is your own
  /// reference; see this file's header on why the caller must also check
  /// `data['status']`/`data['amount']`/`data['currency']` before treating
  /// the payment as real).
  Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transactions/$transactionId/verify'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Flutterwave verify failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Gate 4 — pulls a page of this account's transactions, confirmed
  /// against https://developer.flutterwave.com/reference/endpoints/transactions
  /// ("Get multiple Transactions") on 2026-08-21. Unlike Paystack there is
  /// no documented `status` query filter here — Flutterwave's own example
  /// only takes `from`/`to`/pagination, so this pulls everything in range
  /// and [FlutterwaveAdapter] filters to `status == 'successful'` itself,
  /// same place PaymentWebhookHandler already does that check. Pagination
  /// is `meta.page_info: {total, current_page, total_pages}` — a fixed
  /// count you walk to the end of, unlike Paystack's "fewer than perPage
  /// means last page" signal, because Flutterwave's response actually
  /// tells you the total page count.
  ///
  /// NOTE: no separate "list customers" endpoint is documented for
  /// Flutterwave the way Paystack has one (checked
  /// developer.flutterwave.com/docs/customers — nothing there). Customer
  /// identity for this gateway comes only from each transaction's own
  /// customer_email/customer_name/phone_number fields, not a standalone
  /// customer backfill pass. Documented here rather than silently
  /// building a narrower adapter than Paystack's without saying why.
  Future<Map<String, dynamic>> listTransactions({
    DateTime? from,
    DateTime? to,
    int page = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/transactions').replace(queryParameters: {
      'page': '$page',
      if (from != null) 'from': _dateOnly(from),
      if (to != null) 'to': _dateOnly(to),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Flutterwave list transactions failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Flutterwave's `from`/`to` filters are documented and demonstrated
  /// as plain dates (`"2020-01-01"`), not full timestamps like
  /// Paystack's — kept as its own helper rather than assumed identical.
  String _dateOnly(DateTime d) => d.toUtc().toIso8601String().split('T').first;

  /// Cheap, side-effect-free authenticated probe — same call
  /// PaymentEndpoint.connectGateway already uses to validate a key before
  /// persisting it, exposed here as a real method for
  /// [FlutterwaveAdapter.health] rather than a second private extension.
  Future<void> probe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/banks/NG'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Flutterwave probe failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Confirms [verifHashHeader] (the `verif-hash` request header on an
  /// incoming webhook) matches [configuredSecretHash] — the exact string
  /// you set in the Flutterwave dashboard's webhook settings. Unlike
  /// Paystack, this is a plain constant-value comparison, not a computed
  /// HMAC — Flutterwave's secret hash IS the shared secret, sent back
  /// verbatim, not used as a signing key.
  bool verifyWebhookSignature({
    required String? verifHashHeader,
    required String configuredSecretHash,
  }) {
    if (verifHashHeader == null || verifHashHeader.isEmpty) return false;
    if (configuredSecretHash.isEmpty) return false;
    return verifHashHeader == configuredSecretHash;
  }
}
