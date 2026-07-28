// errands_page.dart — '/errands'. Content sourced directly from
// errand_endpoint.dart's real method signatures/validation — three
// create methods (builtin/webhook/dbCredential), one dispatch-by-source
// execute method, plus the older executeBuiltinErrand kept for backward
// compatibility. 'mcp' is source-supported in the model but has no
// create method anywhere — flagged as genuinely unimplemented, not
// glossed over.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';

class ErrandsPage extends StatelessComponent {
  const ErrandsPage();

  @override
  Component build(BuildContext context) {
    return fragment([
      docH1('Errands'),
      docLede(
        "An Errand is a named, described task a bot can hand off to — either running Kola's "
        "own built-in logic, calling your webhook, or running one pre-approved query against "
        'your database. The AI reads descriptionForAi to decide when an Errand is relevant; it '
        "never sees your webhook URL or connection string directly.",
      ),

      docH2('1. Built-in'),
      docP(
        "The only registered handler today is escalateToHuman — see BuiltinErrandExecutor's own "
        'handlerKeys for the current, authoritative list if this changes.',
      ),
      const CodeBlock(
        dart:
            "await client.errand.createBuiltinErrand(\n"
            "  accessToken, workspaceId,\n"
            '  "Escalate to human",\n'
            '  "When the customer sounds frustrated or you\'re unsure.",\n'
            '  "escalateToHuman",\n'
            '  "api", // createdVia: \'naturalLanguage\' | \'api\'\n'
            "  permissionScope: 'readOnly', // or 'readWrite'\n"
            ");",
      ),

      docH2('2. Webhook'),
      docP(
        "Registers the Errand AND its credential in one call — a business never ends up with a "
        'half-registered Errand that has nowhere to send calls. The URL is checked for validity '
        "at registration; the auth header (if any) is encrypted at rest with the same "
        'AES-256-GCM scheme protecting channel credentials.',
      ),
      const CodeBlock(
        dart:
            "await client.errand.createWebhookErrand(\n"
            "  accessToken, workspaceId,\n"
            '  "Check order status",\n'
            '  "When a customer asks where their order is.",\n'
            '  "api",\n'
            '  "https://your-api.example.com/order-status",\n'
            "  authHeaderName: 'Authorization',\n"
            "  authHeaderValue: 'Bearer your-secret',\n"
            ");",
      ),

      docH2('3. Database-credential'),
      docP(
        'One pre-approved, named-parameter SQL template per Errand — never open SQL, never '
        "string-concatenated. If permissionScope is 'readOnly' (the default), queryTemplateSql "
        "must start with SELECT — checked at registration AND again at execution.",
      ),
      const CodeBlock(
        dart:
            "await client.errand.createDbCredentialErrand(\n"
            "  accessToken, workspaceId,\n"
            '  "Look up stock level",\n'
            '  "When a customer asks if an item is in stock.",\n'
            '  "api",\n'
            "  'SELECT quantity FROM inventory WHERE sku = @sku',\n"
            "  'postgres://user:pass@your-db-host:5432/yourdb',\n"
            ");",
      ),

      docH2('Running one'),
      docP(
        'executeErrand dispatches by the Errand\'s own source field — one method regardless of '
        'type. inputJson is a JSON-encoded map matching that Errand\'s inputSchemaJson; the '
        'security filter runs on it before any executor sees it.',
      ),
      const CodeBlock(
        dart:
            "final resultJson = await client.errand.executeErrand(\n"
            "  accessToken, workspaceId, errand.id!,\n"
            "  jsonEncode({'sku': 'BAG-042'}),\n"
            ");",
      ),

      docH2('Managing Errands'),
      docList([
        'listErrandsForWorkspace(accessToken, workspaceId) — every Errand, any status.',
        'getErrand(accessToken, workspaceId, errandId) — one Errand.',
        "setErrandStatus(accessToken, workspaceId, errandId, status) — 'active' or 'disabled'; "
            "history/logs aren't deleted on disable.",
      ]),

      docH2('Plan limits'),
      docP(
        "A workspace on the free-tier cap (past the 48-hour full-access window, or paused) can "
        'have at most 3 active Errands — disabled ones don\'t count. Every create* method above '
        'throws immediately if this cap is already reached, rather than creating the Errand and '
        'leaving it nowhere to be enforced later.',
      ),
    ]);
  }
}
