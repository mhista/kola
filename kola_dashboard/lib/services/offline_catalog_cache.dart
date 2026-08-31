// offline_catalog_cache.dart — Phase 11g-f. The last-known product list,
// so till_page.dart's lookup/search/browse keeps working with zero
// connection, not just the checkout call itself.
//
// DESIGN_BRIEF_COMMERCE.md §1 is explicit that "look up any product, by
// scan, search or browse" and "see correct price and last-known stock"
// must both work offline — and equally explicit that the number shown
// must be honest about being stale: *"Stock is last known, not certain.
// Say so plainly without making the number feel useless — '12 in stock,
// as of 9:40 this morning.'"* This is the cache half of that; the label
// itself is till_page.dart's job (`_catalogAsOf`), since only the page
// knows whether it's currently showing a live fetch or this fallback.
//
// SAME window.localStorage MECHANISM AS OfflineSaleQueue, for the same
// reason (see that file's header): a shop's own catalog is realistically
// a few dozen to a few hundred products, comfortably inside
// localStorage's per-origin ceiling, and the existing, proven wrapper
// (`local_storage.dart`) needs nothing new built under it.
//
// Scoped per workspace — `_key(workspaceId)` — so a cashier device that
// (rarely, but possible via workspace switching) serves more than one
// business never shows one shop's stale catalog while signed into
// another's.

import 'dart:convert';

import 'package:kola_client/kola_client.dart';

import 'local_storage.dart';

abstract class OfflineCatalogCache {
  static String _key(int workspaceId) => 'kola_offline_catalog_$workspaceId';

  /// Overwrites the cache with the current, just-fetched product list.
  /// Called after every successful live fetch in till_page.dart — the
  /// cache is always "the last time this page actually reached the
  /// server," never anything older or hand-curated.
  static void save(int workspaceId, List<Product> products) {
    final payload = {
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
      'products': [for (final p in products) p.toJson()],
    };
    LocalStorage.setItem(_key(workspaceId), jsonEncode(payload));
  }

  /// Null when nothing has ever been cached for this workspace (a brand
  /// new device, or a workspace never opened on this browser before) —
  /// the caller falls through to a real error in that case, since there
  /// is no honest "last known" to offer.
  static ({DateTime fetchedAt, List<Product> products})? load(int workspaceId) {
    final raw = LocalStorage.getItem(_key(workspaceId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(decoded['fetchedAt'] as String);
      final products = [
        for (final p in decoded['products'] as List)
          Product.fromJson(p as Map<String, dynamic>),
      ];
      return (fetchedAt: fetchedAt, products: products);
    } catch (_) {
      // A corrupted or shape-mismatched cache (e.g. left over from a
      // build where Product's fields differed) must never crash the
      // till — treat it as "nothing cached," same as a fresh device.
      return null;
    }
  }
}
