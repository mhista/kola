// authentication_page.dart — '/authentication'.
//
// TWO REAL AUTH MECHANISMS COEXIST, VERIFIED SEPARATELY AGAINST SOURCE:
//
// 1. accessToken (Supabase session token) — what every Serverpod
//    Endpoint method on this site's other pages takes, built for
//    kola_dashboard/kola_admin and any other Dart app in this codebase.
//    requireWorkspaceAccess checks it, as documented below.
//
// 2. API key (Bearer sk_live_...) — what the two public REST routes
//    take, confirmed against api_key_service.dart, send_message_route.
//    dart, and ai_query_route.dart. Built for a caller outside kolaa
//    entirely, in any language. Full detail lives on the Public API
//    page rather than duplicated here.
//
// This page previously said no API-key system existed at all — true
// when it was written, no longer true once Gate 8 (POST /v1/messages)
// and Gate 12 (POST /v1/ai/query) shipped. Fixed here rather than left
// stale, per this project's own "don't describe a backend that doesn't
// match reality" discipline.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class AuthenticationPage extends StatelessComponent {
  const AuthenticationPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Authentication'),
      docLede(
        "kolaa has two separate auth mechanisms, for two separate audiences. Every Serverpod "
        "Endpoint method documented on this site (and everything kola_dashboard/kola_admin "
        "call) takes an accessToken — a Supabase Auth session token. The two public REST "
        'routes meant for external, non-Dart callers take an API key instead — see Public API.',
      ),

      docNote(
        'Building against kolaa from outside this codebase, in any language? You almost '
        'certainly want an API key and the Public API page, not the accessToken flow below — '
        'that flow expects a real Supabase user session, which an external integration should '
        'not need to hold.',
      ),

      docH2('Getting a token'),
      docP(
        "Kola doesn't issue its own tokens — sign in against Supabase Auth's REST API directly "
        "(the same call kola_dashboard's own auth_service.dart makes) and use the accessToken "
        'it returns.',
      ),
      const CodeBlock(
        title: 'Sign in via Supabase Auth',
        curl:
            "curl -X POST 'https://<your-project>.supabase.co/auth/v1/token?grant_type=password' \\\n"
            "  -H 'apikey: <your-supabase-anon-key>' \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\"email\": \"owner@example.com\", \"password\": \"...\"}'",
      ),
      docNote(
        'The response\'s access_token field is what every kola_client call and every raw HTTP '
        'call below expects as accessToken. Its refresh_token is what keeps a long-running '
        "integration signed in without re-prompting for a password — Supabase's own docs cover "
        'the refresh call; Kola does nothing special with it.',
      ),

      docH2('Using it'),
      docP(
        'kola_client methods take accessToken as their first real parameter (after the implicit '
        'Session Serverpod adds server-side). Raw HTTP calls pass it as a plain JSON field in '
        'the request body, alongside every other parameter — not as an Authorization header, '
        "since these endpoints check it themselves rather than relying on Serverpod's own "
        'session-auth mechanism.',
      ),
      const CodeBlock(
        dart:
            "final client = Client('https://api.kolaa.co');\n"
            "final bots = await client.bot.listBotsForWorkspace(accessToken, workspaceId);",
        curl:
            "curl -X POST https://api.kolaa.co/bot \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\"method\": \"listBotsForWorkspace\", \"accessToken\": \"<token>\", \"workspaceId\": 42}'",
      ),

      docH2('What requireWorkspaceAccess actually checks'),
      docP(
        'Almost every method (everything except WaitlistEndpoint.joinWaitlist, which is fully '
        'public, and the first two WorkspaceEndpoint methods, which run before any workspace '
        'exists to check) calls requireWorkspaceAccess(accessToken, workspaceId) before doing '
        'anything else: it verifies the token is a real, current Supabase session, then '
        "confirms that session's user is a member of workspaceId. Fail either check and the "
        'call throws before touching any data — there is no partial-auth state.',
      ),

      docH2('API keys are a separate mechanism'),
      docP(
        'POST /v1/messages and POST /v1/ai/query take an API key instead of an accessToken — '
        'Bearer sk_live_... in the Authorization header, not a body parameter. A key is scoped '
        'to exactly one workspace and one of three permission scopes at creation, so it carries '
        'its own workspace identity rather than needing one supplied per request. See Public '
        'API for how to create one, the full request/response shapes, and error codes.',
      ),

      docH2('Inbound webhooks are a separate story'),
      docP(
        "Meta (WhatsApp), Telegram, and the payment gateways call Kola, not the other way "
        'around — those requests carry no accessToken at all, because they never had one to '
        "begin with. WhatsApp and the payment gateways are verified with the sender's own "
        "signature scheme (Meta's X-Hub-Signature-256, Paystack's HMAC-SHA512, Flutterwave's "
        "verif-hash). Telegram's webhook route has no signature check at all today — it relies "
        'on each channel getting its own unguessable, per-channel URL instead of a shared one. '
        'See Webhooks for the specifics of each.',
      ),
    ]);
  }
}
