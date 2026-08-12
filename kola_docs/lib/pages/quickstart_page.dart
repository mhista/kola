// quickstart_page.dart — '/'. Every step here calls a real Endpoint
// method that exists in kola_server today (BotEndpoint.createBot,
// ChannelEndpoint.connectTelegramChannel, ErrandEndpoint.createBuiltinErrand)
// — confirmed directly against each Endpoint's source, not written from
// memory of what "should" exist.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';
import '../theme.dart';

class QuickstartPage extends StatelessComponent {
  const QuickstartPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Quickstart'),
      docLede(
        "Four calls take you from a new workspace to a bot that's live on Telegram and can "
        'hand off to a human. This page uses Telegram throughout because it needs zero '
        'external approval — WhatsApp works the same way once a number is connected (see '
        'Channels).',
      ),

      docH2('0. Get a workspace and an access token'),
      docP(
        'Sign up at the Kola dashboard — that flow creates your first Workspace and signs you '
        'in via Supabase Auth. Every call below needs the accessToken that sign-in returns; see '
        'Authentication for exactly how to fetch and refresh it outside the dashboard.',
      ),

      docH2('1. Create a bot'),
      docP('A bot belongs to a workspace and starts life with no channel, no knowledge, and no Errands.'),
      const CodeBlock(
        title: 'BotEndpoint.createBot',
        dart:
            "final bot = await client.bot.createBot(\n"
            "  accessToken,\n"
            "  workspaceId,\n"
            "  \"Aisha Assistant\",\n"
            "  \"customerCare\", // or 'catalog' | 'custom'\n"
            ");\n"
            "print(bot.id); // save this — every call below needs it",
        curl:
            "curl -X POST https://api.kola.app/bot \\\n"
            "  -H 'Content-Type: application/json' \\\n"
            "  -d '{\n"
            '    "method": "createBot",\n'
            '    "accessToken": "<accessToken>",\n'
            '    "workspaceId": 42,\n'
            '    "name": "Aisha Assistant",\n'
            '    "archetype": "customerCare"\n'
            "  }'",
      ),

      docH2('2. Connect a channel'),
      docP(
        'Create a bot with @BotFather on Telegram (a two-message conversation, no approval '
        'process), then hand its token straight to Kola:',
      ),
      const CodeBlock(
        title: 'ChannelEndpoint.connectTelegramChannel',
        dart:
            "final channel = await client.channel.connectTelegramChannel(\n"
            "  accessToken,\n"
            "  workspaceId,\n"
            "  bot.id!,\n"
            '  "123456:ABC-your-bot-father-token",\n'
            ");",
      ),
      docNote(
        'Kola validates the token against Telegram (getMe) before it ever gets stored — a bad '
        'token fails this call immediately rather than silently connecting.',
      ),

      docH2('3. Teach it something'),
      docP(
        "Kola's knowledge model today is deliberately minimal — one plain-text field per bot, "
        "not document upload/parsing (that's a real, flagged gap, not an oversight — see the "
        'Knowledge page comments in the dashboard source).',
      ),
      const CodeBlock(
        title: 'BotEndpoint.setKnowledgeSeed',
        dart:
            "await client.bot.setKnowledgeSeed(\n"
            "  accessToken,\n"
            "  workspaceId,\n"
            "  bot.id!,\n"
            '  "We sell handmade leather bags. Prices: Tote ₦45,000, Crossbody ₦28,000. '
            'Lagos delivery in 2-3 days.",\n'
            ");",
      ),

      docH2('4. Give it an escalation path'),
      docP(
        "The one built-in Errand handler that ships today is escalateToHuman — the bot's way "
        'of saying "a person should take this."',
      ),
      const CodeBlock(
        title: 'ErrandEndpoint.createBuiltinErrand',
        dart:
            "await client.errand.createBuiltinErrand(\n"
            "  accessToken,\n"
            "  workspaceId,\n"
            '  "Escalate to human",\n'
            '  "When the customer sounds frustrated, or you\'re not confident in your answer.",\n'
            '  "escalateToHuman",\n'
            '  "api",\n'
            ");",
      ),

      docH2("You're live"),
      docP(
        'Message your Telegram bot — Kola will answer from the knowledge you gave it, or '
        'escalate and notify you, depending on how confident the answer is. Next: ',
      ),
      docList([
        'Authentication — how accessToken actually works, and what it doesn\'t (yet) support.',
        'Errands — webhook and database-backed Errands, permission scopes, execution.',
        'Channels — WhatsApp\'s longer setup path, and every Channel method.',
      ]),
      div(
        attributes: {'style': 'display:flex;gap:16px;margin-top:8px'},
        [
          Link(
            to: '/authentication',
            attributes: {
              'style':
                  'color:${KolaDocsColors.accent};text-decoration:none;font-size:13.5px;font-weight:600',
            },
            child: Component.text('Authentication →'),
          ),
        ],
      ),
    ]);
  }
}
