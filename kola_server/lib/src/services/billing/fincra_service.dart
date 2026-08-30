// fincra_service.dart — Gate 11 (breadth). Low-level wrapper around
// Fincra's collections API — plain HTTPS via package:http, same
// role/shape as PaystackService/FlutterwaveService/MonnifyService in
// this same directory.
//
// SCOPE — SYNC-ONLY, DELIBERATELY, SAME CUT AS MONNIFY: no checkout
// initiation, no webhook verification. Only what FincraAdapter's sync()
// needs — resolve the business ID, list wallet top-ups (pay-ins) — is
// built. See payment_checkout_service.dart's checkoutSupportedGateways
// for where this is enforced in code.
//
// AUTH MODEL — SIMPLER THAN MONNIFY, CLOSER TO PAYSTACK: a single
// static secret key sent as the `api-key` header on every call. No
// login/token-exchange step. Confirmed against
// https://docs.fincra.com/docs/authentication on 2026-08-27 (three key
// types exist — Secret Key via `api-key` header for server-side calls,
// Public Key via `x-pub-key` for the client-side checkout widget, and a
// separate Webhook Encryption Key for signature validation; this
// service only ever uses the secret key).
//
// BASE URL: confirmed against https://docs.fincra.com/docs/live-
// environment on 2026-08-27 — live is https://api.fincra.com. (Sandbox
// is https://sandboxapi.fincra.com, per the `servers` block on every
// page of Fincra's own OpenAPI reference — not used here since this
// service always targets live, same as every other gateway service in
// this directory.)
//
// BUSINESS ID — REQUIRED, FETCHED NOT STORED: unlike Paystack/
// Flutterwave/Monnify, Fincra's own transaction-listing endpoint takes
// a `business` query parameter (the merchant's own internal ID, not the
// secret key) rather than inferring the caller's business from the
// api-key alone. Confirmed against
// https://docs.fincra.com/reference/get-business-information.md on
// 2026-08-27 — GET /profile/business/me returns `data._id`, which is
// that business ID. This service resolves it fresh on each sync() call
// (see _resolveBusinessId) rather than persisting it anywhere new,
// matching MonnifyService's "no cross-call caching" stance — one extra
// authenticated GET per sync run is a small, deliberate cost for not
// adding another encrypted column solely to cache a non-secret ID.
//
// TRANSACTION LIST — REAL ENDPOINT, RESPONSE SHAPE UNDOCUMENTED:
// GET /wallets/topups, confirmed as a real, paginated (`page`/`perPage`
// query params) endpoint against
// https://docs.fincra.com/reference/get-wallet-top-ups.md on
// 2026-08-27 — "view both a single or multiple collections made to a
// business wallet." This is the closest real analog Fincra's docs
// expose to Paystack's `/transaction` list or Monnify's
// `/merchant/transactions/search` — NOT a dedicated "list charges/
// checkouts" endpoint (no such endpoint was found; Fincra's Checkout
// Standard and Direct Charge APIs only expose per-reference
// verify/get-by-reference calls plus webhook delivery, not a list). The
// response schema for this specific endpoint is undocumented (Fincra's
// own reference page shows an empty `{}` example body for both the 200
// and 400 cases) — genuinely unconfirmed, same category of uncertainty
// MonnifyService's header already flags for Monnify's search-transactions
// envelope. [FincraAdapter] therefore parses defensively. A real
// sandbox account is needed to tighten this past guesswork.
//
// A REAL, NAMED UNCERTAINTY WORTH FLAGGING EXPLICITLY: "wallet top-ups"
// may be a broader concept than "customer checkout payments" — it could
// include manual funding, settlements from other Fincra products, etc.,
// not just money a business's own customers paid in through a Fincra
// checkout/charge. This service (and the adapter built on top of it)
// treats every row this endpoint returns as a candidate customer
// payment, same blunt inclusion PaystackAdapter/FlutterwaveAdapter/
// MonnifyAdapter apply to their own "success/PAID only" filters — worth
// revisiting once a real account's data can be inspected.

import 'dart:convert';
import 'package:http/http.dart' as http;

class FincraService {
  FincraService({required this.secretKey});

  final String secretKey;

  static const _baseUrl = 'https://api.fincra.com';

  Map<String, String> get _headers => {
        'api-key': secretKey,
        'Content-Type': 'application/json',
      };

  /// Resolves this merchant's business ID — required by [listTopups].
  /// See this file's header on why it's re-fetched rather than cached
  /// across calls. Throws on failure (bad/revoked key), a run-level
  /// failure matching every other adapter's "auth rejected outright"
  /// contract.
  Future<String> _resolveBusinessId() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/profile/business/me'),
      headers: _headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Fincra business lookup failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final businessId = data?['_id'] as String?;
    if (businessId == null) {
      throw Exception('Fincra business lookup returned no _id: ${response.body}');
    }
    return businessId;
  }

  /// Lists wallet top-ups (pay-ins) for this business, paginated. See
  /// this file's header for what's confirmed vs. not about this
  /// endpoint. [page] is 1-indexed unless proven otherwise — Fincra's
  /// docs don't say either way for this endpoint, so [FincraAdapter]
  /// treats an empty page as "no more data" rather than relying on
  /// indexing assumptions.
  ///
  /// Returns the raw decoded response — [FincraAdapter] is responsible
  /// for defensively locating the row list within it.
  Future<Map<String, dynamic>> listTopups({int page = 1, int perPage = 50}) async {
    final businessId = await _resolveBusinessId();
    final uri = Uri.parse('$_baseUrl/wallets/topups').replace(
      queryParameters: {
        'business': businessId,
        'page': '$page',
        'perPage': '$perPage',
      },
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Fincra topup list failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Cheap, side-effect-free authenticated probe — same role as
  /// MonnifyService.probe/PaystackService.probe: validate the key
  /// before persisting it (PaymentEndpoint.connectGateway) and for
  /// [FincraAdapter.health]. Business lookup itself IS the probe here.
  Future<void> probe() async {
    await _resolveBusinessId();
  }
}
