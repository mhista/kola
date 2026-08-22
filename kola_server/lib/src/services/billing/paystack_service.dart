// paystack_service.dart
//
// Low-level wrapper around Paystack's Transactions API — plain HTTPS calls
// via package:http, same role/shape as WhatsAppService (whatsapp_service.dart):
// everything that needs to talk to Paystack does it THROUGH this, never
// builds an api.paystack.co URL directly.
//
// SCOPE — PHASE 5C IS "THE SERVICE EXISTS", NOT "PAYMENT IS LIVE": this
// file wraps initialize/verify against Paystack's real, documented API
// (confirmed against https://paystack.com/docs/payments/accept-payments/,
// https://paystack.com/docs/payments/verify-payments/, and
// https://paystack.com/docs/payments/webhooks/ — not guessed at). Nothing
// in kola_dashboard or any Endpoint calls this yet — there is no "Upgrade
// now" button wired up, no gateway-config table for which secret key a
// workspace even uses, and no webhook route registered in server.dart.
// That's deliberate: PRD.md's billing section doesn't yet specify exact
// plan prices/currency/billing-cycle behavior, and wiring a real checkout
// without those numbers means guessing at them. This is the seam the
// actual "Upgrade" flow plugs into once that product decision is made.
//
// AUTH MODEL: every call authenticates with Paystack's SECRET key (never
// the public key) as a Bearer token — same shape as WhatsAppService's
// bearer-token calls, different provider.
//
// VERIFY IS THE SOURCE OF TRUTH, NOT THE CALLBACK REDIRECT: Paystack's own
// docs are explicit that the top-level `status` field on every response
// (including verify's) only means "did the API call itself succeed" — the
// actual payment outcome is `data.status` (e.g. 'success', 'failed',
// 'abandoned'). A caller of [verifyTransaction] MUST check
// `result.data['status'] == 'success'` AND that `data['amount']` matches
// the amount actually expected before treating a payment as real — this
// service intentionally does not do that comparison itself, since it
// doesn't know what amount was expected; that belongs to whatever billing
// logic calls this once it exists.
//
// WEBHOOK SIGNATURE (for whenever a webhook route is actually registered):
// Paystack signs the raw JSON request body with HMAC-SHA512 using the
// SECRET key, sent as the `x-paystack-signature` header. Verifying that
// signature is [verifyWebhookSignature] below — kept here since it's pure
// crypto over Paystack-shaped input, even though no route calls it yet.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pointycastle/export.dart';

class PaystackService {
  PaystackService({required this.secretKey});

  final String secretKey;

  static const _baseUrl = 'https://api.paystack.co';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $secretKey',
    'Content-Type': 'application/json',
  };

  /// Starts a transaction. [amount] is in the currency's smallest unit
  /// (kobo for NGN — e.g. ₦500 is `amount: 50000`), matching how Paystack
  /// itself defines the field; this service does not do any unit
  /// conversion, so callers must pass the smallest-unit value already.
  /// Returns the raw decoded response — `data['authorization_url']` is
  /// where the customer should be redirected to pay, `data['reference']`
  /// is what [verifyTransaction] later needs.
  Future<Map<String, dynamic>> initializeTransaction({
    required String email,
    required int amount,
    String? callbackUrl,
    String? reference,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/transaction/initialize'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'amount': amount,
        if (callbackUrl != null) 'callback_url': callbackUrl,
        if (reference != null) 'reference': reference,
        if (metadata != null) 'metadata': metadata,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Paystack initialize failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetches the final state of a transaction by [reference]. See this
  /// file's header — callers must check `data['status'] == 'success'` AND
  /// `data['amount']` themselves; the top-level `status` field only means
  /// the API call succeeded, not that the payment did.
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/transaction/verify/$reference'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Paystack verify failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Gate 4 — pulls a page of this account's transactions, newest API
  /// shape confirmed against https://paystack.com/docs/api/transaction/#list
  /// on 2026-08-21 (not guessed). [from] is Paystack's own incremental
  /// filter (`created_at >= from`) — the sync engine's cursor is this
  /// value, so re-syncing never re-reads a page it already processed.
  /// Only `status: success` need ever reach the graph — pending/abandoned/
  /// failed attempts are not payments, and PaymentWebhookHandler already
  /// never marks anything completed off a status other than success.
  /// Returns the raw decoded response; `data` is the list, `meta` carries
  /// pagination (`perPage`, and Paystack's own `next`/`previous` opaque
  /// cursors — this adapter uses `page`/`perPage` numeric paging instead,
  /// since it is simpler to persist as [SyncCursor] and Paystack documents
  /// both as equally valid).
  Future<Map<String, dynamic>> listTransactions({
    DateTime? from,
    int page = 1,
    int perPage = 50,
    String status = 'success',
  }) async {
    final uri = Uri.parse('$_baseUrl/transaction').replace(queryParameters: {
      'page': '$page',
      'perPage': '$perPage',
      'status': status,
      if (from != null) 'from': from.toUtc().toIso8601String(),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Paystack list transactions failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Gate 4 — pulls a page of this account's customers, confirmed against
  /// https://paystack.com/docs/api/customer/#list on 2026-08-21. Used
  /// alongside [listTransactions] so a customer who exists in the
  /// business's Paystack account but has no successful transaction yet
  /// (an initialized-but-never-completed checkout, a customer created for
  /// a future recurring charge) still lands in the graph rather than only
  /// appearing the day they first pay.
  Future<Map<String, dynamic>> listCustomers({
    DateTime? from,
    int page = 1,
    int perPage = 50,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer').replace(queryParameters: {
      'page': '$page',
      'perPage': '$perPage',
      if (from != null) 'from': from.toUtc().toIso8601String(),
    });
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Paystack list customers failed (${response.statusCode}): ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Cheap, side-effect-free authenticated probe — same call
  /// PaymentEndpoint.connectGateway already uses to validate a key before
  /// persisting it, exposed here as a real method rather than duplicated
  /// as a second private extension for [PaystackAdapter.health] to call.
  Future<void> probe() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/bank?currency=NGN'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Paystack probe failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Confirms [signatureHeader] (the `x-paystack-signature` request
  /// header) is a valid HMAC-SHA512 of [rawBody] using [secretKey] — the
  /// exact check Paystack's webhook docs specify. [rawBody] must be the
  /// UNPARSED request body bytes/string (signing the re-serialized JSON
  /// can produce a different byte sequence than what was actually sent,
  /// e.g. differing key order or whitespace, and silently fail this
  /// check). Uses pointycastle (same crypto package already used by
  /// channel_credential_encryption_service.dart) rather than pulling in a
  /// separate `crypto` dependency just for one HMAC check.
  bool verifyWebhookSignature({
    required String rawBody,
    required String? signatureHeader,
  }) {
    if (signatureHeader == null || signatureHeader.isEmpty) return false;
    // SHA-512's block size is 128 bytes — required by HMac's constructor.
    final hmac = HMac(SHA512Digest(), 128)
      ..init(KeyParameter(Uint8List.fromList(utf8.encode(secretKey))));
    final computed = hmac
        .process(Uint8List.fromList(utf8.encode(rawBody)))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return computed == signatureHeader;
  }
}
