// intelligence_page.dart — '/intelligence'.
//
// Documents IntelligenceEndpoint and FindingEndpoint — previously
// undocumented entirely. Confirmed directly against both endpoints'
// source, including the two gaps intelligence_endpoint.dart's own
// header names outright (no response-time metric, no CSAT field
// anywhere in this codebase) — carried into this page rather than
// smoothed over.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class IntelligencePage extends StatelessComponent {
  const IntelligencePage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Business Intelligence'),
      docLede(
        'Two related capabilities: a computed intelligence summary (top products, a plain-'
        'English narrative, a revenue/escalation correlation callout) and a standing list of '
        "findings — things the workspace's own data suggests need attention, surfaced without "
        'anyone having to ask.',
      ),

      docH2('The intelligence summary'),
      docP(
        'periodDays is one of 7, 30, or 90. Every number is computed fresh from real Sale and '
        'Conversation data for that window, compared against the equivalent prior window.',
      ),
      const CodeBlock(
        title: 'IntelligenceEndpoint.getIntelligence',
        dart:
            "final summary = await client.intelligence.getIntelligence(\n"
            "  accessToken, workspaceId,\n"
            "  periodDays: 30,\n"
            ");\n"
            "print(summary.revenueMinor);\n"
            "print(summary.revenueDeltaPct);   // null if there's no prior-period revenue to compare\n"
            "print(summary.narrative);         // a real generated paragraph, or an honest template\n"
            "print(summary.narrativeIsTemplate); // true if every AI provider failed for this call\n"
            "print(summary.correlationCallout);  // null unless revenue fell AND escalations rose\n"
            "print(summary.topProducts);       // up to 8, by revenue, with velocity + margin",
      ),
      docList([
        "Each top product's marginMinor/marginPct is null whenever that product's cost was "
            'never set — never a fabricated margin.',
        'velocityLabel/velocityTone (e.g. "Sells out in 3 days" / fast, "Slow mover" / slow, '
            '"Out of stock 2 days" / out) are both null when the product isn\'t stock-tracked '
            '(Product.stock is null) — there\'s no honest sell-through figure to give it.',
        'correlationCallout is a plain two-condition check, not a statistical claim: it fires '
            'only when revenue fell versus the prior period AND escalated conversations rose '
            'over the same two windows, both real numbers already computed for this call.',
      ]),
      docWarning(
        "Two cards this endpoint's own design calls for are not real numbers yet, and say so "
        'rather than showing a fabricated one: response time (no average-response-time '
        'computation exists anywhere in this codebase) and customer satisfaction (no rating/'
        'CSAT field exists on a conversation or ticket anywhere in this codebase). Both render '
        'as an honest "not measured yet" state on the dashboard rather than being silently '
        'dropped from the layout.',
      ),

      docH2('Findings'),
      docP(
        'listFindings runs a real, indexed sweep of the workspace on every call and returns '
        'what it finds, worst first — there is no scheduled background pass yet, so this is '
        'always fresh, never a stale cached row. An empty list is the normal, common answer for '
        'a workspace with nothing wrong, not an error state.',
      ),
      const CodeBlock(
        title: 'FindingEndpoint.listFindings / dismissFinding',
        dart:
            "final findings = await client.finding.listFindings(accessToken, workspaceId);\n"
            "// e.g. a WorkspaceFinding with kind 'product_out_of_stock', subjectId: 9\n"
            "await client.finding.dismissFinding(accessToken, workspaceId, findings.first.id!);",
      ),
      docNote(
        'A dismissal is permanent for that specific finding — "I know about this one," not a '
        'snooze. If the same underlying condition is detected again on a later sweep, it comes '
        'back as a new finding.',
      ),
    ]);
  }
}
