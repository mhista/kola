// webhooks_page.dart — '/webhooks'. These routes are Relic-based, not
// Serverpod Endpoint methods — they never appear in kola_client's
// generated client, and SRS.md §12 explicitly calls this split out
// ("both flow through Relic-based routes for maximum control over
// response shape and latency"). Documented separately from the
// Endpoint-method pages for that reason.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../components/doc_page_kit.dart';

class WebhooksPage extends StatelessComponent {
  const WebhooksPage();

  @override
  Component build(BuildContext context) {
    return fragment([
      docH1('Webhooks'),
      docLede(
        "Two directions: things that call Kola (WhatsApp, Telegram, the payment gateways), and "
        "things Kola calls for you (a webhook-backed Errand hitting your own endpoint). Neither "
        'direction uses accessToken — see Authentication for why.',
      ),

      docH2('Inbound: things that call Kola'),
      docP('Each channel/gateway gets its own route and its own verification mechanism:'),
      docList([
        'WhatsApp — one route per connected channel, verified against the X-Hub-Signature-256 '
            "header Meta attaches to every request (HMAC-SHA256, keyed with your Meta app "
            'secret). An unsigned or mis-signed request is rejected before any message is read.',
        'Telegram — one route per connected bot. No signature check today — the route\'s own '
            'URL is the secret (long, random, per-channel), not a per-request signature. '
            'Treat that URL like a credential.',
        'Paystack — inbound event delivery (e.g. charge.success), verified via HMAC-SHA512 of '
            "the raw request body using your Paystack secret key, compared against the "
            'x-paystack-signature header. Not wired to a live route yet — see Rate limits & '
            "plans / the SDKs page for what's actually switched on.",
        'Flutterwave — inbound event delivery, verified by comparing the verif-hash header '
            "against a plain shared-secret string you set in Flutterwave's own dashboard (not "
            'an HMAC — Flutterwave sends the secret back verbatim). Also not wired to a live '
            'route yet.',
      ]),
      docWarning(
        "Paystack and Flutterwave's HTTP wrappers (initialize/verify transaction, signature "
        "checks) exist and are written against each provider's real documented API — but no "
        "checkout endpoint or webhook route is exposed anywhere yet. There's no live \"pay now\" "
        'flow to point a webhook at today.',
      ),

      docH2('Outbound: things Kola calls for you'),
      docP(
        'A webhook-backed Errand (see Errands) POSTs inputJson\'s decoded map as its JSON body '
        'to the webhookUrl you registered, with your configured auth header attached if you set '
        "one. Your response must be a 2xx with a JSON object body — that object becomes the "
        "Errand's result, returned as-is. A non-2xx status, or a body that doesn't parse as a "
        "JSON object, is treated as an execution failure (logged, no retry, surfaced back "
        "through executeErrand's own thrown error).",
      ),
    ]);
  }
}
