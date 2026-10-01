// public_api_page.dart — '/public-api'.
//
// THE ONE SURFACE ON THIS SITE MEANT FOR AN EXTERNAL, NON-DART, NON-
// KOLA-DASHBOARD CALLER. Everything documented elsewhere on this site
// (Quickstart, the kola_client examples on other pages) goes through
// Serverpod's generated Endpoint/accessToken mechanism — built for
// kola_dashboard, kola_admin, and other Dart apps in this codebase, not
// a stable contract for a third party. These two routes are different:
// they live on webServer as custom Routes (see send_message_route.dart
// and ai_query_route.dart's own headers on why), authenticate with an
// API key instead of a Supabase session token, and return real HTTP
// status codes a caller in any language can branch on.
//
// Every request/response shape, error code, and scope rule below is
// copied directly from send_message_route.dart, ai_query_route.dart,
// api_key_service.dart, and platform_endpoint.dart — not written from
// memory of what a REST API "should" look like.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class PublicApiPage extends StatelessComponent {
  const PublicApiPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Public API'),
      docLede(
        'Two routes are built for callers outside kolaa entirely, in any language: sending an '
        'outbound message, and asking kolaa a question about the workspace. Both authenticate '
        "with an API key, not the Supabase session token every other page on this site uses — "
        'see Authentication for how the two auth mechanisms fit together.',
      ),

      docH2('Getting an API key'),
      docP(
        'Create one from your dashboard, under API & Webhooks. You choose a name and a scope; '
        'the key itself is shown exactly once at creation and never again, only a hash of it is '
        'stored, so losing it means revoking and issuing a new one rather than looking it up.',
      ),
      docList([
        'full — read, write, and execute. The only scope that can call POST /v1/messages, and '
            'the only scope that lets POST /v1/ai/query take real actions.',
        'read_only — answers and citations from POST /v1/ai/query, with no action ever '
            'executed. Cannot call POST /v1/messages at all.',
        'errands_only — stored and accepted at key-creation time, but see the warning below: '
            'no live route currently accepts it.',
      ]),
      docWarning(
        'A key created with errands_only scope cannot call either route documented on this '
        'page today. POST /v1/messages requires full scope exactly; POST /v1/ai/query accepts '
        'full or read_only and rejects everything else, errands_only included, with a 403. The '
        'scope exists in storage ahead of the "restricted to one named errand" mode it is meant '
        'for, which has not been built yet, rather than being faked as read-only or full.',
      ),

      docH2('Authenticating a request'),
      docP(
        'Send the key as a bearer token. workspaceId is never a parameter on these two routes: '
        'the key itself is scoped to exactly one workspace, so trusting a value in the request '
        'body over what the key already carries would be a second, weaker source of truth for '
        'the one thing that must never be ambiguous on an authenticated write.',
      ),
      const CodeBlock(
        // Deliberately NOT a real-looking key — a run of 32 lowercase
        // hex-ish characters after "sk_live_" matches the same shape
        // Stripe's own live secret keys use, and GitHub's push
        // protection scans for that shape regardless of whether the
        // value is real. This placeholder breaks the pattern on
        // purpose so docs commits never get blocked over an example.
        curl: 'Authorization: Bearer sk_live_<your-kolaa-api-key>',
      ),
      docNote(
        'A missing or malformed header, an unknown key, and a revoked key all return the same '
        '401 — a response that told a caller "no such key" apart from "revoked key" would let '
        'someone enumerate which keys had once been valid.',
      ),

      docH2('POST /v1/messages'),
      docP(
        'Sends a message through a channel already connected to the workspace (WhatsApp or '
        'Telegram today). Requires a full-scope key, and requires the messaging.send capability '
        'to be switched on for the workspace — see Feature availability if this 403s '
        "unexpectedly.",
      ),
      const CodeBlock(
        title: 'Request',
        curl:
            "curl -X POST https://api.kolaa.co/v1/messages \\\n"
            "  -H 'Authorization: Bearer sk_live_...' \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\n"
            '    "platform": "whatsapp",\n'
            '    "to": "2348012345678",\n'
            '    "text": "Your order has shipped.",\n'
            '    "idempotencyKey": "order-4471-shipped"\n'
            "  }'",
      ),
      const CodeBlock(
        title: 'Response — 200',
        curl:
            "{\n"
            '  "ok": true,\n'
            '  "messageId": 9123,\n'
            '  "conversationId": 442,\n'
            '  "deduped": false\n'
            "}",
      ),
      docP('idempotencyKey is optional and caller-chosen. Reusing one returns the original '
          'result with deduped: true instead of sending a second message — safe to retry a '
          'request you are not sure went through.'),
      docH2('POST /v1/messages — error responses', id: 'messages-errors'),
      docList([
        '401 — missing, malformed, unknown, or revoked API key.',
        '403 — the key\'s scope is not full, or messaging.send is not enabled on this '
            'workspace yet.',
        '400 — the request body is not valid JSON, or platform/to/text fail validation.',
        '502 — kolaa reached the channel but the send itself failed (channel not currently '
            'connected, or the platform rejected the message).',
        '500 — an unhandled internal error.',
      ]),

      docH2('POST /v1/ai/query'),
      docP(
        'Asks kolaa a free-text question about the workspace — the same cross-source Q&A the '
        "owner dashboard's own Ask kola box calls, with the same memory retrieval, the same "
        'catalog and connector digests, and the same citations. This route is a thin '
        'authentication shell around a capability that already existed.',
      ),
      docP(
        'Scope decides whether the model is allowed to act on the answer, not just produce it. '
        'A full-scope key can trigger a real action (book a calendar event, run an errand) when '
        'the model chooses to, exactly like the owner dashboard. A read_only-scope key gets '
        'real answers and real citations with the model never offered an action to take, which '
        'is what makes read-only an enforced guarantee rather than a label.',
      ),
      const CodeBlock(
        title: 'Request',
        curl:
            "curl -X POST https://api.kolaa.co/v1/ai/query \\\n"
            "  -H 'Authorization: Bearer sk_live_...' \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{ \"question\": \"How many orders shipped this week?\" }'",
      ),
      const CodeBlock(
        title: 'Response — 200',
        curl:
            "{\n"
            '  "ok": true,\n'
            '  "answer": "12 orders shipped this week, up from 9 last week.",\n'
            '  "productIds": [],\n'
            '  "citations": [\n'
            "    {\n"
            '      "chunkId": 881,\n'
            '      "documentId": 55,\n'
            '      "documentTitle": "Order log — September",\n'
            '      "chunkIndex": 3,\n'
            '      "content": "...",\n'
            '      "similarity": 0.87\n'
            "    }\n"
            "  ],\n"
            '  "generated": true,\n'
            '  "providerName": "groq"\n'
            "}",
      ),
      docH2('POST /v1/ai/query — error responses', id: 'query-errors'),
      docList([
        '401 — missing, malformed, unknown, or revoked API key.',
        '403 — the key\'s scope is errands_only (or anything other than full/read_only), or '
            'platform.public_api is not enabled on this workspace yet.',
        '400 — the request body is not valid JSON, or question is empty.',
        '500 — an unhandled internal error.',
      ]),

      docNote(
        'Both routes set permissive CORS headers (access-control-allow-origin: *) — they are '
        "meant to be called server-to-server with a secret bearer token, not from a browser "
        "where that token would be exposed to anyone viewing the page's source.",
      ),
    ]);
  }
}
