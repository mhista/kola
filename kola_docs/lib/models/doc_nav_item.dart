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
      DocNavItem(label: 'Channels', path: '/channels'),
      DocNavItem(label: 'Connect your WhatsApp', path: '/channels/connect-whatsapp'),
    ],
  ),
  DocNavSection(
    title: 'Reference',
    items: [
      DocNavItem(label: 'Rate limits & plans', path: '/rate-limits'),
      DocNavItem(label: 'SDKs', path: '/sdks'),
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
