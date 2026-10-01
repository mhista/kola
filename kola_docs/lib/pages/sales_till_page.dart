// sales_till_page.dart — '/sales'.
//
// Documents SaleEndpoint, StockConflictEndpoint, ReportEndpoint, and
// TillDisplayEndpoint.getState — kolaa's till/POS layer, previously
// undocumented entirely. Every method, field name, and gate confirmed
// directly against each endpoint's own source, not written from memory
// of what a POS API "should" expose.
//
// These are all Serverpod Endpoint methods (accessToken, not API key) —
// same convention as Quickstart and Errands, not the Public API page's
// Bearer-token shape.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class SalesTillPage extends StatelessComponent {
  const SalesTillPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Sales & Till'),
      docLede(
        "kolaa's sales counter: ring up a sale, track stock against it, close out the day. "
        'Gated on commerce.core and commerce.pos together — a workspace without both enabled '
        'gets a clear error rather than a partial till.',
      ),

      docH2('Ringing up a sale'),
      docP(
        'One line per item. productId is optional per line — a hand-typed, non-catalog line is '
        'valid and simply skips the stock decrement that follows. Tax is computed server-side '
        "from the workspace's own taxRateBps, not supplied by the caller.",
      ),
      const CodeBlock(
        title: 'SaleEndpoint.ringUpSale',
        dart:
            "final sale = await client.sale.ringUpSale(\n"
            "  accessToken,\n"
            "  workspaceId,\n"
            '  linesJson: \'[{"productId": 9, "name": "Tote", "unitPriceMinor": 4500000, '
            '"quantity": 1}]\',\n'
            '  paymentMethod: "cash",\n'
            "  cashReceivedMinor: 5000000,\n"
            "  clientReference: \"offline-queue-8821\",\n"
            '  customerPhone: "2348012345678",\n'
            "  customerName: \"Aisha\",\n"
            ");",
      ),
      docNote(
        'linesJson is a JSON-encoded string, not a Dart list — the generated client on this '
        "install can't deserialize List<CustomType> parameters (see the endpoint's own header "
        'for the full trace), so every list-shaped parameter across the sales/invoicing/till-'
        'display endpoints takes its list pre-encoded as JSON text instead.',
      ),
      docList([
        'Amounts are minor units (kobo) and integers throughout — unitPriceMinor: 4500000 is '
            '₦45,000.00.',
        'clientReference makes the call idempotent: replaying the same reference (an offline '
            'till resending a sale after a lost response) returns the original Sale instead of '
            'creating a duplicate.',
        'customerPhone/customerName are optional. When present, the sale resolves or creates a '
            'Customer through the same deterministic identity matcher every other intake path '
            'uses (a WhatsApp conversation, a payment webhook), so a till sale shows up on that '
            "customer's unified timeline rather than sitting outside the graph.",
        "A cash sale with cashReceivedMinor set gets its changeMinor computed server-side; "
            "paying less than the total is rejected before the sale is created.",
      ]),
      docP(
        'Each line with a productId decrements that product\'s stock. Selling past zero does '
        'not fail the sale (the money is real either way) — it creates an open StockConflict '
        'instead, see below.',
      ),

      docH2('Reading sales back'),
      const CodeBlock(
        title: 'SaleEndpoint.listSales / getSaleLines',
        dart:
            "final recent = await client.sale.listSales(accessToken, workspaceId, limit: 50);\n"
            "final lines = await client.sale.getSaleLines(accessToken, workspaceId, sale.id!);",
      ),

      docH2('Stock conflicts'),
      docP(
        'An oversold line (stock decremented below zero) is recorded, never silently corrected '
        'and never used to reverse or block the sale that revealed it. Resolving one is a '
        "plain-language decision, not an inventory edit — Product.stock is already clamped at "
        'zero by the time a conflict exists.',
      ),
      const CodeBlock(
        title: 'StockConflictEndpoint.listOpen / resolve',
        dart:
            "final open = await client.stockConflict.listOpen(accessToken, workspaceId);\n"
            "await client.stockConflict.resolve(\n"
            "  accessToken, workspaceId, conflict.id!,\n"
            '  "backordered", // or "adjusted" | "dismissed"\n'
            ");",
      ),

      docH2('End-of-day report'),
      docP(
        'Computed fresh from that calendar day\'s Sale rows on every call, nothing here is '
        "persisted as its own table. Includes a plain-language trend line comparing today's "
        "gross takings to yesterday's, only when yesterday actually had completed sales to "
        'compare against — a shop\'s first day gets no insight rather than a fabricated one.',
      ),
      const CodeBlock(
        title: 'ReportEndpoint.getEndOfDayReport',
        dart:
            "final report = await client.report.getEndOfDayReport(accessToken, workspaceId);\n"
            "print(report.grossMinor);      // total completed sales, minor units\n"
            "print(report.byPaymentMethodJson); // {\"cash\": 1200000, \"card\": 800000}\n"
            "print(report.insightText);     // \"Takings are 12% higher than yesterday...\"",
      ),

      docH2('In-store customer display'),
      docP(
        'A second-screen display staff can leave open at the counter, updated live as the cart '
        'changes. Writing state is authenticated (TillDisplayEndpoint.pushState); reading it is '
        'deliberately public, no accessToken, since the screen showing it has no session of its '
        'own — the same split ProductEndpoint.getPublicCatalog already uses. Gated on both '
        'commerce.customer_display and the workspace\'s own customerDisplayEnabled toggle, both '
        'collapsed into one generic "not available" error so a probe against a random '
        'workspaceId learns nothing from the failure.',
      ),
      const CodeBlock(
        title: 'TillDisplayEndpoint.getState — public, no accessToken',
        curl: "curl -X POST https://api.kolaa.co/tillDisplay \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\"method\": \"getState\", \"workspaceId\": 42}'",
      ),
    ]);
  }
}
