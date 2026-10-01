// customers_page.dart — '/customers'.
//
// Documents CustomerEndpoint and CustomerProfileEndpoint — kolaa's
// cross-source customer graph. Previously undocumented entirely.
// Confirmed directly against both endpoints' source.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class CustomersPage extends StatelessComponent {
  const CustomersPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Customers'),
      docLede(
        'One customer record per real person, built by matching identity signals (phone, '
        'name) across every source: a WhatsApp conversation, a till sale, a payment webhook. '
        'Gated on customers.core. A customer is never created by a caller directly — every '
        'intake path (the till, a conversation starting, a payment confirming) resolves or '
        "creates one through the same deterministic matcher, so this endpoint's job is reading "
        'and correcting the graph, not writing to it directly.',
      ),

      docH2('Listing customers'),
      docP(
        'listCustomersWithSummary is the one to reach for over plain listCustomers — it '
        'computes lifetime value, order count, and last-activity (with the channel that '
        'produced it, e.g. "Till" or "WhatsApp") for every customer in one call, rather than a '
        'detail call per row.',
      ),
      const CodeBlock(
        title: 'CustomerEndpoint.listCustomersWithSummary',
        dart:
            "final summaries = await client.customer.listCustomersWithSummary(accessToken, workspaceId);\n"
            "for (final s in summaries) {\n"
            "  print('\${s.customer.displayName}: \${s.ltvMinor} minor units, '\n"
            "      '\${s.orderCount} orders, last seen via \${s.lastActivityChannel}');\n"
            "}",
      ),
      docNote(
        "Lifetime value never double-counts: a sale whose payment was separately reconciled to "
        "the same customer is credited once, through whichever side actually resolved the "
        'customerId, not both.',
      ),

      docH2('One customer, every source'),
      docP(
        'getCustomerDetail always resolves through any merge first, so a stale link (a browser '
        'tab open on a customer since merged into another) lands on the survivor rather than '
        '404ing or showing half a history.',
      ),
      const CodeBlock(
        title: 'CustomerEndpoint.getCustomerDetail',
        dart:
            "final detail = await client.customer.getCustomerDetail(accessToken, workspaceId, customerId);\n"
            "detail.signals;       // phone/name identity signals that matched this person\n"
            "detail.conversations; // every conversation across every channel\n"
            "detail.payments;      // every payment transaction\n"
            "detail.sales;         // every till sale",
      ),
      docP(
        'updateCustomerNotes sets a free-text note — owner-written only, nothing automated '
        'calls it. getForConversation (CustomerProfileEndpoint) reads a saved birthday or '
        'anniversary captured during a conversation, if one exists; null is a normal, expected '
        'result, not an error.',
      ),

      docH2('The merge-review queue'),
      docP(
        'Merges are proposed, never applied automatically. When the identity resolver finds '
        'two customer records that are probably the same person, it creates a pending '
        'CustomerMergeProposal instead of merging outright — an owner confirms or rejects each '
        'one.',
      ),
      const CodeBlock(
        title: 'CustomerEndpoint.listMergeProposals / resolveMergeProposal',
        dart:
            "final pending = await client.customer.listMergeProposals(accessToken, workspaceId);\n"
            "await client.customer.resolveMergeProposal(\n"
            "  accessToken, workspaceId, proposal.id!,\n"
            "  true, // approve — false rejects, leaving both customers independent\n"
            ");",
      ),
      docNote(
        'Approving a merge folds the newer record into the older one (the lower customer id '
        'always survives) by pointing it at the survivor — nothing else about either record is '
        'rewritten. Rejecting leaves both permanently independent for that proposal.',
      ),
    ]);
  }
}
