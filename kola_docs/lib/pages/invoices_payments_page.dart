// invoices_payments_page.dart — '/invoices-payments'.
//
// Documents InvoiceEndpoint and PaymentEndpoint — previously
// undocumented entirely. Confirmed directly against both endpoints'
// source, including the honest gap invoice_endpoint.dart's own header
// states plainly: recordPayment is a manual "mark as paid," not an
// automatic webhook-to-invoice credit (that reconciliation link is
// unbuilt). Not glossed over here either.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class InvoicesPaymentsPage extends StatelessComponent {
  const InvoicesPaymentsPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Invoices & Payments'),
      docLede(
        "Two related but separate capabilities: generating an invoice document from a sale (or "
        "from scratch), and collecting a real payment against a workspace's own connected "
        'payment gateway.',
      ),

      docH2('Invoices'),
      docP(
        'Gated on the same commerce.core + commerce.pos flags the till uses — an invoice is '
        'the till\'s own output in another form, not a separate opt-in. Totals are always '
        'recomputed server-side from the submitted lines, never trusted from the caller.',
      ),
      const CodeBlock(
        title: 'InvoiceEndpoint.createInvoice',
        dart:
            "final invoice = await client.invoice.createInvoice(\n"
            "  accessToken, workspaceId,\n"
            '  "Aisha Bello", // billToName\n'
            '  \'[{"name": "Tote", "quantity": 1, "unitPriceMinor": 4500000}]\', // linesJson\n'
            "  saleId: sale.id, // optional — links the invoice back to a till sale\n"
            "  taxRateBps: 750,\n"
            '  dueAt: DateTime.now().add(const Duration(days: 14)),\n'
            ");",
      ),
      docList([
        'listInvoices / getInvoice — the usual read paths.',
        'getInvoiceForSale returns the most recently issued invoice for a given sale, or null '
            '— lets a "Documents" view reuse one instead of creating a duplicate every time it '
            'opens.',
        'updateInvoiceStatus moves an invoice through draft → sent → viewed → partly_paid → '
            'paid (or backward, to correct a mistake) — the caller decides the transition, '
            'nothing here validates the state graph.',
      ]),
      docWarning(
        'recordPayment is a manual "mark as paid" the owner triggers themselves — it is NOT '
        'wired to any payment webhook. Completing a checkout through PaymentEndpoint does not '
        'automatically credit an invoice\'s paidMinor; that reconciliation link does not exist '
        'yet. Call recordPayment explicitly once a payment is confirmed by whatever means.',
      ),
      const CodeBlock(
        title: 'InvoiceEndpoint.recordPayment',
        dart:
            "await client.invoice.recordPayment(accessToken, workspaceId, invoice.id!, 4500000);",
      ),

      docH2('Connecting a payment gateway'),
      docP(
        'A workspace connects its own Paystack, Flutterwave, Stripe, Monnify, or Fincra '
        'account — kolaa never holds a shared merchant account. Every credential is probed '
        "against the real gateway before it's stored: a wrong secret key is rejected "
        'immediately with a specific error, rather than sitting in the database looking '
        "connected until the first real checkout fails. Monnify is the one gateway that needs "
        'both a secret key and a separate apiKey.',
      ),
      const CodeBlock(
        title: 'PaymentEndpoint.connectGateway',
        dart:
            "await client.payment.connectGateway(\n"
            "  accessToken, workspaceId,\n"
            '  "paystack", secretKeyFromDashboard,\n'
            "  webhookSecret: webhookSecretFromDashboard, // required for Flutterwave\n"
            ");\n"
            "final gateways = await client.payment.listConnectedGateways(accessToken, workspaceId);\n"
            "// never returns the decrypted key — only enough to show \"Paystack: connected\"",
      ),

      docH2('Collecting a payment'),
      docP(
        "initializeCheckout starts a real checkout against the workspace's own connected "
        'gateway. holdInEscrow is bookkeeping-only — it marks the transaction as held in '
        "kolaa's own records so an owner can track an escrow-style flow manually; it is not a "
        'real fund hold at the gateway. releaseHold flips that bookkeeping status once the '
        'underlying transaction has actually completed.',
      ),
      const CodeBlock(
        title: 'PaymentEndpoint.initializeCheckout / releaseHold',
        dart:
            "final tx = await client.payment.initializeCheckout(\n"
            "  accessToken, workspaceId,\n"
            '  "paystack", 4500000, "customer@example.com",\n'
            "  holdInEscrow: true,\n"
            ");\n"
            "// ... once tx.status == 'completed' ...\n"
            "await client.payment.releaseHold(accessToken, workspaceId, tx.id!);",
      ),
    ]);
  }
}
