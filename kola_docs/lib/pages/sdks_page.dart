// sdks_page.dart — '/sdks'. Only one real SDK exists (kola_client, the
// Serverpod-generated Dart client) — no JS/Python/other-language client
// has ever been built. Says so plainly rather than listing hypothetical
// future SDKs as if they were on a roadmap with dates.

import 'package:jaspr/jaspr.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class SdksPage extends StatelessComponent {
  const SdksPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('SDKs'),
      docLede(
        'One real client library today: kola_client, generated directly from kola_server\'s '
        'Serverpod endpoint definitions. Every method on it maps 1:1 to a real endpoint method — '
        "there's no hand-written wrapper layer drifting out of sync with the server.",
      ),

      docH2('Dart — kola_client'),
      docP(
        "Add it as a path or git dependency, construct a Client pointed at your kola_server "
        'instance, then call methods grouped by endpoint (client.bot.*, client.errand.*, '
        'client.channel.*, client.conversation.*, client.workspace.*, client.ownerNotification.*, '
        'client.waitlist.*).',
      ),
      const CodeBlock(
        dart:
            "import 'package:kola_client/kola_client.dart';\n\n"
            "final client = Client('https://api.kola.app');\n"
            "final workspaces = await client.workspace.listMyWorkspaces(accessToken);",
      ),

      docH2('No other language SDK exists'),
      docP(
        "If you're not using Dart, call the raw HTTP contract directly — see Authentication and "
        "the cURL examples throughout these docs for the exact request/response shape. It's a "
        "plain POST-based RPC convention (one route per endpoint, a method field in the JSON "
        "body naming which method to call), not anything that needs a generated client to use "
        'correctly.',
      ),
    ]);
  }
}
