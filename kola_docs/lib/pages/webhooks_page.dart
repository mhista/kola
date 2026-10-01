// webhooks_page.dart — '/webhooks'. The inbound routes and the two
// public API routes are Relic-based, not Serverpod Endpoint methods —
// they never appear in kola_client's generated client, and SRS.md §12
// explicitly calls this split out ("both flow through Relic-based
// routes for maximum control over response shape and latency").
// Documented separately from the Endpoint-method pages for that reason.
//
// OUTBOUND HAS TWO GENUINELY DIFFERENT MECHANISMS, BOTH REAL, VERIFIED
// SEPARATELY: a webhook-backed Errand (existing content below, on-
// demand, triggered by one Errand execution) and the event-subscription
// system (event_bus.dart / webhook_delivery_service.dart, Gate 2) —
// register a URL against a set of named events and kolaa POSTs to it,
// signed, whenever one fires. Added here rather than folded into the
// Errand section since they are unrelated code paths with unrelated
// registration flows (an Errand's own webhookUrl field vs.
// PlatformEndpoint.saveWebhookEndpoint).

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class WebhooksPage extends StatelessComponent {
  const WebhooksPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Webhooks'),
      docLede(
        "Two directions: things that call kolaa (WhatsApp, Telegram, the payment gateways), and "
        "things kolaa calls for you (a webhook-backed Errand, or a subscription to a named "
        'event). Inbound never uses accessToken — see Authentication for why. Outbound never '
        'uses accessToken either; the event-subscription system signs its own deliveries '
        'instead, described below.',
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

      docH2('Outbound, on demand: a webhook-backed Errand'),
      docP(
        'A webhook-backed Errand (see Errands) POSTs inputJson\'s decoded map as its JSON body '
        'to the webhookUrl you registered, with your configured auth header attached if you set '
        "one. Your response must be a 2xx with a JSON object body — that object becomes the "
        "Errand's result, returned as-is. A non-2xx status, or a body that doesn't parse as a "
        "JSON object, is treated as an execution failure (logged, no retry, surfaced back "
        "through executeErrand's own thrown error).",
      ),

      docH2('Outbound, event-driven: subscribing to workspace events'),
      docP(
        'Separately from any Errand, you can register a URL against a set of named events and '
        "kolaa will POST to it every time one genuinely new occurrence of that event happens — "
        'a new conversation starting, an errand executing, a sale completing, a message going '
        'out through POST /v1/messages, and so on. Register an endpoint from your dashboard '
        "(API & Webhooks) or via PlatformEndpoint.saveWebhookEndpoint. URLs must be https.",
      ),
      docList([
        'new_conversation — a new conversation started with the workspace\'s agent.',
        'errand_executed — an Errand (builtin or custom) finished executing.',
        'agent_drafted — the workspace agent was created in draft state.',
        'agent_published — the workspace agent went live.',
        'agent_paused — the workspace agent was paused.',
        'payment_confirmed — a payment gateway confirmed a transaction.',
        'sale_completed — a sale was rung up through the Till.',
        'message_sent — a message sent through POST /v1/messages reached the platform '
            'adapter.',
      ]),
      const CodeBlock(
        title: 'Register a subscription',
        curl:
            "curl -X POST https://api.kolaa.co/platform \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\n"
            '    "method": "saveWebhookEndpoint",\n'
            '    "accessToken": "<token>",\n'
            '    "workspaceId": 42,\n'
            '    "url": "https://example.com/kolaa-events",\n'
            '    "events": ["new_conversation", "sale_completed"]\n'
            "  }'",
      ),
      docP(
        "Every delivery is signed: an X-Kola-Signature header carrying sha256=<hex HMAC-SHA256 "
        "of the raw request body>, keyed with a secret generated when you register the "
        "endpoint. Verify it the same way you'd verify WhatsApp's own incoming X-Hub-"
        'Signature-256 — this scheme deliberately mirrors that shape. Your endpoint must '
        'respond 2xx; a delivery is retried on failure and an endpoint is marked failing if it '
        'keeps rejecting deliveries, same as any connector sync in this codebase.',
      ),
      docWarning(
        "Delivery is deduplicated by event, not resent on a schedule you control: there is no "
        "request-count or manual-replay endpoint exposed yet. Re-sending events an endpoint "
        'missed while it was down is a capability the delivery service supports internally '
        '(EventBus.replay) but nothing in the public or dashboard API triggers it today.',
      ),
    ]);
  }
}
