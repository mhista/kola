// nav_model.dart — the dashboard's navigation, as data.
//
// ── ONE DEFINITION, THREE SURFACES ───────────────────────────────────
//
// The desktop sidebar, the mobile "More" sheet, and the command palette
// all render from this list. They looked like three different problems
// in the design export and were built as three hardcoded lists there;
// building them that way here would mean every new page has to be added
// in three places, and the one everybody forgets is the palette.
//
// The mobile bottom tab bar is the exception and is defined separately
// below — see [bottomTabs] for why it is not simply "the first four".
//
// ── EVERY DESTINATION IS GATED ───────────────────────────────────────
//
// Each item names the feature key(s) it needs. An item whose features
// are not enabled is not rendered — not greyed out, not shown with a
// padlock. This follows the server's absence-not-false design: a locked
// item is one a customer should not know exists yet, and a padlocked
// row labelled "Forecasting" tells them precisely what is coming.
//
// The exception is [NavItem.comingSoon], for the handful of surfaces we
// have deliberately announced. Those render visibly disabled, because
// hiding something a customer has already been told about reads as a
// bug rather than as discretion.
//
// ── GROUPS DISAPPEAR WHEN EMPTY ──────────────────────────────────────
//
// A group with no visible items renders nothing at all — no heading. On
// a launch-scope workspace that is most of them, and a sidebar of bare
// category labels over empty space looks broken rather than staged.

import '../services/feature_gate.dart';
import '../components/shell/icons.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.features,
    this.badge,
    this.comingSoon = false,
  });

  final String label;

  /// A path from [Icons].
  final String icon;

  /// A real router path. Never '#'.
  ///
  /// The previous build used '#' for unbuilt destinations, which meant
  /// the sidebar advertised pages that did nothing when clicked. Gating
  /// on features replaces that entirely: if the page does not exist yet,
  /// its feature is locked and the item is not drawn.
  final String route;

  /// Every key that must be enabled. ALL of them, not any — a surface
  /// that needs two features is incoherent with one of them missing.
  final List<String> features;

  /// Short uppercase tag beside the label. The design uses it to mark
  /// the commerce surfaces as a distinct product area.
  final String? badge;

  /// Render visibly disabled rather than hidden. Only for surfaces
  /// already announced publicly — see this file's header.
  final bool comingSoon;

  bool isVisibleTo(FeatureGate gate) =>
      comingSoon || gate.allEnabled(features);
}

class NavGroup {
  const NavGroup({required this.label, required this.items});

  final String label;
  final List<NavItem> items;

  List<NavItem> visibleItems(FeatureGate gate) =>
      [for (final i in items) if (i.isVisibleTo(gate)) i];
}

/// Always visible, above the groups. These are the two surfaces that
/// are never gated: the overview is the app's front door, and the
/// timeline is where "what happened" lives — both are meaningless to
/// lock, since a workspace with no features still has an account and a
/// history.
const navPrimary = <NavItem>[
  NavItem(
    label: 'Overview',
    icon: Icons.diamond,
    route: '/',
    features: [],
  ),
  NavItem(
    label: 'Timeline',
    icon: Icons.list,
    route: '/timeline',
    features: [Features.timeline],
  ),
];

/// The grouped navigation, in the design's own order.
///
/// The order is not alphabetical and not by build status. It runs from
/// what a shop owner does hourly (Sell), through what needs them today
/// (Attention), to what they review weekly (Grow), to what they set up
/// once (Build). A sidebar ordered by our implementation convenience
/// would put Developer near the top, which is exactly wrong for the
/// person this is for.
const navGroups = <NavGroup>[
  NavGroup(label: 'Sell', items: [
    NavItem(
      label: 'Sales counter',
      icon: Icons.salesCounter,
      route: '/counter',
      features: [Features.commerceCore, Features.commercePos],
      badge: 'SELL',
    ),
    NavItem(
      label: 'Catalog',
      icon: Icons.catalog,
      route: '/catalog',
      features: [Features.commerceCore, Features.commerceCatalog],
      badge: 'SELL',
    ),
    // Phase 14a-4. Was a tab inside documents_page.dart's "Documents"
    // surface (see till_page.dart's old header link) — now its own
    // sidebar-reachable page (invoices_page.dart), same commerce gate
    // Sales counter/Catalog already use, since an invoice is the till's
    // own output in another form.
    NavItem(
      label: 'Invoices',
      icon: Icons.invoice,
      route: '/invoices',
      features: [Features.commerceCore, Features.commercePos],
      badge: 'SELL',
    ),
  ]),
  NavGroup(label: 'Attention', items: [
    NavItem(
      label: 'Recommendations',
      icon: Icons.sparkles,
      route: '/recommendations',
      features: [Features.recommendations],
    ),
    NavItem(
      label: 'Observations',
      icon: Icons.eye,
      route: '/observations',
      features: [Features.observations],
    ),
    NavItem(
      label: 'Operations',
      icon: Icons.headset,
      route: '/operations',
      features: [Features.operations],
    ),
    NavItem(
      label: 'Tasks',
      icon: Icons.checkSquare,
      route: '/tasks',
      features: [Features.tasks],
    ),
  ]),
  NavGroup(label: 'Grow', items: [
    NavItem(
      label: 'Intelligence',
      icon: Icons.barChart,
      route: '/intelligence',
      features: [Features.businessIntelligence],
    ),
    NavItem(
      label: 'Analytics',
      icon: Icons.activity,
      route: '/analytics',
      features: [Features.analytics],
    ),
    NavItem(
      label: 'Customers',
      icon: Icons.user,
      route: '/customers',
      features: [Features.customers],
    ),
  ]),
  NavGroup(label: 'Build', items: [
    NavItem(
      label: 'Agents',
      icon: Icons.bot,
      route: '/bots',
      features: [Features.bots],
    ),
    NavItem(
      label: 'Knowledge',
      icon: Icons.book,
      route: '/knowledge',
      features: [Features.memoryDocuments],
    ),
    // 14j: renamed from "Automations" — the route (/errands) and page
    // file (errand_builder_page.dart) were already "Errand"-named; only
    // the visible nav label was wrong. Rename only — the bigger scope
    // question (does Errand Builder become auto-firing on
    // customer-lifecycle events?) is still open with the owner; see
    // PHASE_14_HANDOFF.pdf's 14j section.
    NavItem(
      label: 'Errands',
      icon: Icons.workflow,
      route: '/errands',
      features: [Features.errandsBuiltin],
    ),
    NavItem(
      label: 'Integrations',
      icon: Icons.plug,
      route: '/integrations',
      features: [Features.channelWhatsapp],
    ),
  ]),
  NavGroup(label: 'Developer', items: [
    NavItem(
      label: 'Developer portal',
      icon: Icons.terminal,
      route: '/developer',
      features: [Features.developerPortal],
    ),
    // Gated on publicApi, matching PlatformEndpoint._require exactly —
    // not developerPortal, which is a separate, still-unbuilt page (see
    // api_webhooks_page.dart's header). Reuses Icons.terminal rather
    // than inventing a new path — same call as logOut/switchWorkspace
    // sharing one path in icons.dart; the label tells the two apart.
    NavItem(
      label: 'API & Webhooks',
      icon: Icons.terminal,
      route: '/api-webhooks',
      features: [Features.publicApi],
    ),
  ]),
];

/// The mobile bottom bar.
///
/// DELIBERATELY NOT "the first four nav items". A tab bar is not a
/// shortened sidebar — it is the four things worth reaching with a
/// thumb, and one of them ('More') is not a destination at all. Deriving
/// it from [navGroups] would put Sales counter and Catalog in the bar
/// for a workspace with no commerce, and would silently reshuffle every
/// time the sidebar order changed.
///
/// Overview and More are ungated so the bar is never shorter than two:
/// a one-item tab bar is worse than none.
const bottomTabs = <NavItem>[
  NavItem(
    label: 'Home',
    icon: Icons.home,
    route: '/',
    features: [],
  ),
  NavItem(
    label: 'Sell',
    icon: Icons.salesCounter,
    route: '/counter',
    features: [Features.commerceCore, Features.commercePos],
  ),
  NavItem(
    label: 'Attention',
    icon: Icons.sparkles,
    route: '/recommendations',
    features: [Features.recommendations],
  ),
];

/// The account menu — Connectors, Settings, Billing, Switch workspace,
/// Log out. Shared by the desktop sidebar's profile dropdown and the
/// mobile top bar's account sheet, per this file's own "one definition,
/// three surfaces" rule — it used to live as a private list inside
/// sidebar.dart alone, which meant the mobile top bar's avatar button had
/// nowhere real to point and was wired to open the full destinations
/// sheet instead (see mobile_chrome.dart's MobileProfileSheet header for
/// why that reads as broken: an avatar is an account control, not a
/// second copy of the nav).
///
/// Deliberately NOT part of [navGroups] or [bottomTabs] — these are
/// account actions, not product destinations, and mixing them into the
/// page list would put "Log out" next to "Catalog" as if they were the
/// same kind of thing.
const profileEntries = <({
  String label,
  String icon,
  String route,
  bool danger,
})>[
  // Phase 14a-5. The owner's own instruction: remove "Documents" from
  // the Sales Counter header entirely, add "Invoices" here instead — a
  // walk-in-focused till screen doesn't need a document-browser button
  // in its own top bar when the sidebar (and now this menu) already
  // reach it. Not gated here the way NavItem entries are (this list has
  // no gating mechanism today — see the header note on sidebar.dart), so
  // it always shows; invoices_page.dart's own load will simply come back
  // empty for a workspace that hasn't rung up a sale yet.
  (label: 'Invoices', icon: Icons.invoice, route: '/invoices', danger: false),
  (label: 'Connectors', icon: Icons.plug, route: '/integrations', danger: false),
  (label: 'Settings', icon: Icons.settings, route: '/settings', danger: false),
  (label: 'Billing', icon: Icons.billing, route: '/billing', danger: false),
  (
    label: 'Switch workspace',
    icon: Icons.switchWorkspace,
    route: '/settings',
    danger: false
  ),
  (label: 'Log out', icon: Icons.logOut, route: '/logout', danger: true),
];

/// Everything the command palette can jump to, flattened.
///
/// Derived rather than hand-listed, so a page added to the sidebar is
/// reachable from the palette without anyone remembering to add it.
List<({NavItem item, String group})> paletteEntries(FeatureGate gate) {
  return [
    for (final i in navPrimary)
      if (i.isVisibleTo(gate)) (item: i, group: 'Go to'),
    for (final g in navGroups)
      for (final i in g.visibleItems(gate)) (item: i, group: g.label),
  ];
}
