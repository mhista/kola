// authentication_page.dart — '/authentication'.
//
// HONESTY CHECKPOINT: SRS.md §12 describes the eventual auth model as
// "workspace-scoped API keys for programmatic access; session auth for
// the dashboard." Only the second half is real — grepped kola_server's
// entire lib/ for apiKey/api_key/ApiKey and found nothing but AI
// provider keys (Groq/Gemini/OpenRouter), which are a different thing
// entirely (Kola's own server calling AI vendors, not a third party
// calling Kola). There is no workspace-scoped API key system today.
// This page says so plainly instead of describing SRS's planned system
// as if it already shipped — same discipline as every other
// "don't promise a backend that doesn't exist" call this project makes.

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
        "Every Kola endpoint that touches a workspace takes an accessToken as an explicit "
        "parameter — there's no separate API-key system yet (see the note below). The token is "
        "a normal Supabase Auth session token, the same one the dashboard itself holds after "
        'sign-in.',
      ),

      docWarning(
        "Workspace-scoped API keys are planned (see the project's own SRS §12) but not built. "
        "Today, calling Kola programmatically means using a real user's Supabase session "
        'token — there is no way to mint a token scoped to just one workspace, and no way to '
        'revoke a single integration without signing that user out everywhere. Treat this page '
        "as \"how auth works right now,\" not the long-term shape.",
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
            "final client = Client('https://api.kola.app');\n"
            "final bots = await client.bot.listBotsForWorkspace(accessToken, workspaceId);",
        curl:
            "curl -X POST https://api.kola.app/bot \\\n"
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
