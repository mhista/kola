// feature_gate.dart
//
// The dashboard's view of release control. Loaded once per session,
// read synchronously everywhere after that.
//
// ── WHY A CACHE AND NOT A CALL PER CHECK ─────────────────────────────
//
// The nav alone asks about ~18 features, and every page asks about a
// few more. Per-check calls would mean dozens of round trips to draw
// one screen, on connections where a round trip can be 400ms. The
// server was built for this: FeatureEndpoint.listEnabledFeatures
// returns the whole enabled set in one call, precisely so the client
// can render navigation and routes before drawing anything.
//
// ── ABSENCE MEANS LOCKED, AND THAT IS THE WHOLE POINT ────────────────
//
// The server returns ONLY enabled keys. A locked feature is absent, not
// present-and-false, because the locked set is an unreleased roadmap
// and a customer reading network traffic should not be able to read it.
//
// This class must preserve that property. [isEnabled] answers from the
// set it was given; it never consults a list of all known keys, so it
// cannot accidentally reveal that a key exists. There is deliberately
// no `allKeys` here and no `isLocked` — "locked" and "never heard of
// it" are the same answer, by design.
//
// ── FAIL CLOSED ──────────────────────────────────────────────────────
//
// If the call fails, the set stays empty and everything gated is
// hidden. That is the safe direction: a network blip degrades the
// dashboard to its core, it does not unlock the roadmap. [loadFailed]
// exists so the shell can say "couldn't check what's available" rather
// than silently presenting a stripped-down product as if it were
// complete — a user seeing half their paid features vanish with no
// explanation is worse than an honest error.

import 'package:kola_client/kola_client.dart';

class FeatureGate {
  FeatureGate._(this._enabled, this.loadFailed);

  /// Nothing enabled. The starting state, and the state after a failed
  /// load — see this file's header on failing closed.
  FeatureGate.empty()
      : _enabled = const <String>{},
        loadFailed = false;

  final Set<String> _enabled;

  /// True when the enabled set could not be fetched. The set is empty
  /// either way; this distinguishes "nothing is enabled for you" from
  /// "we could not find out", which are very different things to say to
  /// someone paying for the product.
  final bool loadFailed;

  /// Fetches the enabled set. Never throws — a failure returns a gate
  /// that hides everything and reports [loadFailed].
  static Future<FeatureGate> load(
    Client client, {
    required String accessToken,
    required int workspaceId,
  }) async {
    try {
      final keys = await client.feature.listEnabledFeatures(
        accessToken,
        workspaceId,
      );
      return FeatureGate._(keys.toSet(), false);
    } catch (_) {
      return FeatureGate._(const <String>{}, true);
    }
  }

  /// Whether [key] is available to this workspace right now.
  bool isEnabled(String key) => _enabled.contains(key);

  /// True when every key is available. For a surface that genuinely
  /// needs several — the sales counter needs both commerce.core and
  /// commerce.pos, and is incoherent with either missing.
  bool allEnabled(Iterable<String> keys) => keys.every(_enabled.contains);

  /// True when at least one is available. For a container that should
  /// appear if any of its children will — a nav group, a settings
  /// section — so an empty group never renders as a bare heading.
  bool anyEnabled(Iterable<String> keys) => keys.any(_enabled.contains);

  /// How many features are on. For diagnostics and the shell's own
  /// "couldn't check" message. Deliberately a count, not the keys.
  int get enabledCount => _enabled.length;
}

/// The feature keys this dashboard actually references.
///
/// MIRRORS kola_server's FeatureKeys, but deliberately only the subset
/// the dashboard renders — this is not a copy of the server's list and
/// must not become one. The server's file is the full roadmap; shipping
/// the full roadmap to the browser would hand every visitor the thing
/// the absence-not-false design exists to protect.
///
/// A key here that the server has never heard of is harmless: it is
/// simply never in the enabled set, so the surface stays hidden.
abstract class Features {
  // ── Available at launch ────────────────────────────────────────────
  static const bots = 'bots.core';
  static const conversations = 'conversations.inbox';
  static const escalation = 'conversations.escalation';
  static const memoryDocuments = 'memory.documents';
  static const memoryInspector = 'memory.inspector';
  static const errandsBuiltin = 'errands.builtin';
  static const billing = 'billing.core';
  static const channelWhatsapp = 'channels.whatsapp';
  static const channelTelegram = 'channels.telegram';

  // ── Commerce ───────────────────────────────────────────────────────
  static const commerceCore = 'commerce.core';
  static const commerceCatalog = 'commerce.catalog';
  static const commercePos = 'commerce.pos';
  static const commerceReceipts = 'commerce.receipts';
  static const commerceInvoices = 'commerce.invoices';
  static const commerceReports = 'commerce.reports';

  // ── Intelligence ───────────────────────────────────────────────────
  static const observations = 'intelligence.observations';
  static const recommendations = 'intelligence.recommendations';
  static const businessIntelligence = 'intelligence.dashboards';
  static const analytics = 'intelligence.analytics';

  // ── Operations ─────────────────────────────────────────────────────
  static const timeline = 'timeline.core';
  static const customers = 'customers.core';
  static const operations = 'operations.core';
  static const tasks = 'tasks.core';

  // ── Build ──────────────────────────────────────────────────────────
  static const agents = 'agents.core';
  static const automations = 'automations.workflows';

  // ── Developer ──────────────────────────────────────────────────────
  static const developerPortal = 'platform.developer_portal';
}
