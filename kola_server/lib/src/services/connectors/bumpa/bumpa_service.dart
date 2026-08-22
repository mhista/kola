// bumpa_service.dart — Gate 4. Low-level wrapper around Bumpa's commerce
// API, same role as PaystackService (billing/paystack_service.dart):
// everything that needs to talk to Bumpa does it THROUGH this, never
// builds an api.getbumpa.com URL directly.
//
// EVERYTHING BELOW IS VERIFIED AGAINST REAL, LIVE CALLS MADE WITH A REAL
// ACCOUNT ON 2026-08-21/22, not guessed from docs.bumpa.io's Postman
// collection alone (that collection has NO example response bodies
// anywhere — every field name and type here came from an actual
// response). Specifically confirmed live:
//   - base URL: https://api.getbumpa.com/api/commerce/v1 (production;
//     api.bumpa.xyz is the documented staging host, untested)
//   - auth: X-Api-Key header, and the two-key split is REAL, not
//     documentation flourish — GET /products with the secret key returns
//     "Invalid or inactive public API key", so the public key is
//     required there and the secret key is required for /orders. Mixing
//     them up fails loud with a clear message, not a silent wrong
//     result, which is why [listProducts] and [listOrders]/[probe] take
//     their key from separate constructor fields rather than one shared
//     one.
//   - GET /orders returns {"success": bool, "orders": {<Laravel
//     paginator>: current_page, data: [...], per_page, total, ...}} —
//     note the extra "orders" wrapper layer, which List Products and
//     Create Cart do NOT have (those paginators sit at the top level).
//     Losing that extra unwrap is the single easiest mistake to make
//     copying this shape to another Bumpa endpoint.
//   - Amounts are plain decimal Naira, NOT kobo — order.total "100.00"
//     against a product priced at 50.00 with quantity 2 confirms no
//     ×100 conversion happens on Bumpa's side, unlike Paystack. BUT the
//     type is inconsistent across fields: order-level totals (total,
//     sub_total, amount_paid, grand_total) are STRINGS, while each
//     items[] entry's price/total are raw JSON numbers. grand_total
//     even carries 4 decimal places where everything else has 2. Every
//     amount here is parsed through num.parse/num.tryParse rather than
//     assumed to already be a specific Dart type — this exact class of
//     bug (assuming a currency field's shape instead of checking it) is
//     what caused a real amount-unit mismatch in the Flutterwave
//     integration earlier in this project.
//   - The Analytics endpoints (GET /analytics/summary, GET
//     /analytics/detail) exist and return 200, but came back {"data":
//     []} even immediately after two real paid orders in range — not
//     reliable enough to build on. Deliberately not wrapped here;
//     BumpaAdapter computes kolaa's own numbers from synced orders
//     instead of depending on Bumpa's own analytics.
//   - There is no /customers endpoint — confirmed 404 ("route ... could
//     not be found"). Customer identity is derived from each order's own
//     customer_details/shipping_details, not fetched separately.
//   - /orders/export, /orders/exports, /orders/csv all 404. No export
//     endpoint found at any guessed path.
//
// NOT YET CONFIRMED: per-variant product detail (individual SKU, cost,
// and selling price per size/color combination — the product CSV
// template proves these exist, e.g. VGT-001-S-GRY vs VGT-001-L-BLK-WL
// each having their own cost/price/stock) is not visible in the List
// Products response, which only returns aggregate min_selling_price/
// max_selling_price and a variationCount. [listProducts] intentionally
// does not attempt to reconstruct or guess variant-level pricing.

import 'dart:convert';
import 'package:http/http.dart' as http;

class BumpaService {
  BumpaService({required this.secretKey, required this.publicKey});

  /// Used for order and account-level reads — orders, analytics.
  final String secretKey;

  /// Used for public-catalog reads — products, carts. Confirmed the
  /// secret key does NOT work here (see this file's header).
  final String publicKey;

  static const _baseUrl = 'https://api.getbumpa.com/api/commerce/v1';

  Map<String, String> _headers(String apiKey) => {
        'Accept': 'application/json',
        'X-Api-Key': apiKey,
      };

  /// Pulls a page of this store's orders, newest-first as Bumpa itself
  /// returns them (confirmed by id descending in a live test run, not
  /// independently guaranteed by any documented sort parameter — see
  /// BumpaAdapter's header on why sync does not rely on that ordering
  /// for early-exit).
  ///
  /// Returns the decoded `orders` object directly (already unwrapped
  /// from the outer {"success": ...} envelope) — `data` is the row
  /// list, the rest is Laravel's standard pagination metadata.
  Future<Map<String, dynamic>> listOrders({
    int page = 1,
    int perPage = 100,
  }) async {
    final uri = Uri.parse('$_baseUrl/orders').replace(queryParameters: {
      'page': '$page',
      'limit': '$perPage',
    });
    final response = await http.get(uri, headers: _headers(secretKey));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bumpa list orders failed (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (decoded['orders'] as Map<String, dynamic>?) ?? const {};
  }

  /// Pulls a page of this store's published products. Public-catalog
  /// route — see this file's header on why the PUBLIC key, not the
  /// secret key, is required here.
  Future<Map<String, dynamic>> listProducts({
    int page = 1,
    int perPage = 100,
  }) async {
    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: {
      'page': '$page',
      'limit': '$perPage',
    });
    final response = await http.get(uri, headers: _headers(publicKey));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bumpa list products failed (${response.statusCode}): ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Cheap, side-effect-free authenticated probe against the secret key
  /// — same role as PaystackService.probe, used to validate a key before
  /// persisting it and for [BumpaAdapter.health].
  Future<void> probe() async {
    final uri = Uri.parse('$_baseUrl/orders').replace(queryParameters: {'limit': '1'});
    final response = await http.get(uri, headers: _headers(secretKey));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Bumpa probe failed (${response.statusCode}): ${response.body}');
    }
  }
}
