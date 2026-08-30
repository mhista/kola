// monnify_service.dart — Gate 11 (breadth). Low-level wrapper around
// Monnify's (Moniepoint's payment gateway) Transactions API — plain
// HTTPS via package:http, same role/shape as PaystackService/
// FlutterwaveService in this same directory.
//
// SCOPE — SYNC-ONLY, DELIBERATELY: unlike Paystack/Flutterwave, this
// service does NOT implement checkout initiation (initializeTransaction)
// or webhook signature verification. Only what MonnifyAdapter's sync()
// needs — authenticate, list/search transactions — is built. This is a
// real, named scope cut, not a partial implementation of a bigger plan:
// Gate 11 on the roadmap asks for a connector that "connects, syncs, and
// lands in the graph," not full checkout parity with Paystack/Flutterwave.
// See payment_checkout_service.dart's own explicit refusal for 'monnify'
// (added alongside this file) for where that line is enforced in code,
// not just documented here.
//
// AUTH MODEL — DIFFERENT FROM PAYSTACK/FLUTTERWAVE: those two use a
// single static secret key as a Bearer token on every call. Monnify
// requires a SEPARATE login step first: POST /api/v1/auth/login with
// `Authorization: Basic base64(apiKey:secretKey)`, which returns a
// short-lived (1 hour) accessToken to use as the Bearer token on every
// subsequent call. Confirmed against
// https://developers.monnify.com/docs/collections/quickstart (Path B —
// API-First Integration, Step 1) on 2026-08-27. This service therefore
// takes BOTH an apiKey and a secretKey (see connector_catalog.dart's
// 'monnify' entry, which asks for both as separate fields), and
// re-authenticates on every call rather than caching a token across
// calls — same "never cache an access token across sync runs" reasoning
// GoogleOAuthService.refreshAccessToken documents, applied here because
// this service has no long-lived process state to cache it in either.
//
// SEARCH TRANSACTIONS — REAL ENDPOINT, RESPONSE SHAPE PARSED
// DEFENSIVELY: GET /api/v1/merchant/transactions/search, confirmed
// against https://developers.monnify.com/docs/collections/manage-
// payments/reconciliation ("Key API Endpoints for Reconciliation") on
// 2026-08-27 — that same page confirms `from`/`to` are Unix timestamps
// in MILLISECONDS (not Paystack/Flutterwave's ISO-8601 strings), and
// names the fields a caller cross-references against internal records:
// `paymentReference`, `transactionReference`, `paymentStatus` (values
// include PAID, PARTIALLY_PAID, OVERPAID, REVERSED, PENDING —
// reconciliation explicitly warns to fetch more than just PAID for a
// COMPLETE reconciliation; this service still only treats PAID as a
// real payment, matching PaystackAdapter/FlutterwaveAdapter's own
// "success/successful only" filtering), `amountPaid` (gross), and
// `settlementAmount` (net of fees). The EXACT response envelope/pagination
// field names (e.g. whether results sit under `responseBody.content` or
// a bare list, exact customer-field nesting) were NOT independently
// confirmed — Monnify's interactive API reference at
// https://developers.monnify.com/api is a JS-rendered app this session's
// fetch tool could not read past its shell. [MonnifyAdapter] therefore
// parses defensively (tries a small set of plausible key names, logs a
// warning with the raw row's keys on a genuine miss rather than crashing
// the whole sync) instead of asserting a schema this pass never actually
// saw. Worth tightening the first time a real Monnify sandbox account is
// available to test against.

import 'dart:convert';
import 'package:http/http.dart' as http;

class MonnifyService {
  MonnifyService({required this.apiKey, required this.secretKey});

  final String apiKey;
  final String secretKey;

  static const _baseUrl = 'https://api.monnify.com';

  /// Every call re-authenticates — see this file's header on why no
  /// token is cached across calls. Returns the raw `accessToken` string.
  /// Throws if login itself fails (wrong apiKey/secretKey pair, account
  /// suspended) — a run-level failure, matching every other adapter's
  /// "auth rejected outright" contract (connector_adapter.dart's sync()
  /// doc).
  Future<String> _authenticate() async {
    final credentials = base64Encode(utf8.encode('$apiKey:$secretKey'));
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/auth/login'),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Monnify authentication failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final body = decoded['responseBody'] as Map<String, dynamic>?;
    final accessToken = body?['accessToken'] as String?;
    if (accessToken == null) {
      throw Exception('Monnify authentication returned no accessToken: ${response.body}');
    }
    return accessToken;
  }

  /// Searches this merchant's transactions in [from]..[to] (inclusive),
  /// paginated. [page] is 0-indexed — Monnify's own dashboard and every
  /// other list endpoint in this codebase's Google/Microsoft adapters
  /// that expose page numbers use 0-indexing; NOT independently confirmed
  /// for this specific endpoint (see this file's header), so
  /// [MonnifyAdapter] treats an empty result page as "no more data"
  /// rather than relying on a total-page-count field that may not exist
  /// under the name this service guesses at.
  ///
  /// Returns the raw decoded response — [MonnifyAdapter] is responsible
  /// for defensively locating the row list within it.
  Future<Map<String, dynamic>> searchTransactions({
    required DateTime from,
    required DateTime to,
    int page = 0,
    int size = 50,
  }) async {
    final accessToken = await _authenticate();
    final uri = Uri.parse('$_baseUrl/api/v1/merchant/transactions/search').replace(
      queryParameters: {
        // Confirmed millisecond Unix timestamps — see this file's header.
        'from': '${from.toUtc().millisecondsSinceEpoch}',
        'to': '${to.toUtc().millisecondsSinceEpoch}',
        'page': '$page',
        'size': '$size',
      },
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Monnify transaction search failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Cheap, side-effect-free authenticated probe — same role as
  /// PaystackService.probe/FlutterwaveService.probe: validate a key pair
  /// before persisting it (PaymentEndpoint.connectGateway) and for
  /// [MonnifyAdapter.health]. Authentication itself IS the probe here —
  /// there is no cheaper authenticated read to layer on top of it the
  /// way Paystack's bank-list or Flutterwave's bank-list calls are, so a
  /// successful login is treated as proof the credentials are valid.
  Future<void> probe() async {
    await _authenticate();
  }
}
