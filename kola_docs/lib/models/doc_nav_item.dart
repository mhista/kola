// doc_nav_item.dart — one entry in the left nav tree. Matches
// DESIGN_PROMPT.md §12's spec: Quickstart, Authentication, Errands,
// Webhooks, Channels, Rate limits & plans, SDKs — SRS.md §12's own
// content plan, verbatim, not reinterpreted.

class DocNavItem {
  const DocNavItem({required this.label, required this.path});

  final String label;
  final String path;
}

class DocNavSection {
  const DocNavSection({required this.title, required this.items});

  final String title;
  final List<DocNavItem> items;
}

/// The one place this site's whole page list lives — DocsShell (nav
/// rendering) and the search box (task-scoped to filtering this same
/// list, see search_box.dart) both read from here, so adding a page is
/// a one-line change, not a two-file edit that can drift out of sync.
const kDocsNav = [
  DocNavSection(
    title: 'Get started',
    items: [
      DocNavItem(label: 'Quickstart', path: '/'),
      DocNavItem(label: 'Authentication', path: '/authentication'),
    ],
  ),
  DocNavSection(
    title: 'Building',
    items: [
      DocNavItem(label: 'Errands', path: '/errands'),
      DocNavItem(label: 'Webhooks', path: '/webhooks'),
      DocNavItem(label: 'Business memory', path: '/business-memory'),
      DocNavItem(label: 'Channels', path: '/channels'),
      DocNavItem(label: 'Connect your WhatsApp', path: '/channels/connect-whatsapp'),
    ],
  ),
  // The rest of kolaa's real, callable capabilities beyond the AI
  // messaging core above — the sales counter, catalog, customer graph,
  // invoicing/payments, business intelligence, human-in-the-loop
  // messaging, the connector marketplace, and lightweight tracking.
  // Every page here was previously entirely undocumented; added after a
  // full audit against kola_dashboard's real pages and their backing
  // endpoints, confirmed against each endpoint's own source.
  DocNavSection(
    title: 'Core features',
    items: [
      DocNavItem(label: 'Sales & Till', path: '/sales'),
      DocNavItem(label: 'Catalog & Products', path: '/catalog'),
      DocNavItem(label: 'Customers', path: '/customers'),
      DocNavItem(label: 'Invoices & Payments', path: '/invoices-payments'),
      DocNavItem(label: 'Business Intelligence', path: '/intelligence'),
      DocNavItem(label: 'Conversations & Support', path: '/conversations-support'),
      DocNavItem(label: 'Connectors', path: '/connectors'),
      DocNavItem(label: 'Tasks & Timeline', path: '/tasks-timeline'),
    ],
  ),
  DocNavSection(
    title: 'Reference',
    items: [
      // The one page on this site meant for a caller outside kolaa
      // entirely, in any language — see public_api_page.dart's header.
      // Placed first in Reference: it is the page a non-Dart integrator
      // is actually looking for, not SDKs (Dart-only) or Rate limits.
      DocNavItem(label: 'Public API', path: '/public-api'),
      DocNavItem(label: 'Rate limits & plans', path: '/rate-limits'),
      DocNavItem(label: 'SDKs', path: '/sdks'),
      // Phase 10 — explains why a capability may not be visible in a
      // given workspace yet. Sits in Reference rather than Billing
      // because it answers a question anyone may ask, not only owners
      // worried about cost.
      DocNavItem(label: 'Feature availability', path: '/feature-availability'),
    ],
  ),
  // Task #152 — the one page on this site written for business owners
  // (Kola's own dashboard users) rather than developers integrating the
  // API, hence its own section rather than folding into "Reference."
  DocNavSection(
    title: 'Billing',
    items: [
      DocNavItem(
        label: 'Avoiding excessive WhatsApp billing',
        path: '/billing/avoiding-excessive-whatsapp-billing',
      ),
    ],
  ),
];
