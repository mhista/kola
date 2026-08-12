// channels_page.dart — '/channels'. Both connect methods on
// ChannelEndpoint, confirmed against its real signatures. WhatsApp's
// own step-by-step walkthrough is a separate page (connect_whatsapp_page.dart)
// since it's long enough, and non-technical enough, to want its own URL —
// matches DESIGN_PROMPT.md §12's own "dedicated non-dev page" framing.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../components/code_block.dart';
import '../components/doc_page_kit.dart';
import '../theme.dart';

class ChannelsPage extends StatelessComponent {
  const ChannelsPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Channels'),
      docLede(
        "A Channel connects one bot to one messaging platform. Two platforms today: Telegram "
        '(zero external approval) and WhatsApp (Meta review, longer setup — see the dedicated '
        'walkthrough).',
      ),

      docH2('Telegram'),
      docP(
        'Create a bot with @BotFather (a two-message Telegram conversation), then hand its '
        'token to Kola. Kola validates it against Telegram\'s getMe before storing anything.',
      ),
      const CodeBlock(
        dart:
            "final channel = await client.channel.connectTelegramChannel(\n"
            "  accessToken, workspaceId, bot.id!,\n"
            '  "123456:ABC-your-bot-father-token",\n'
            ");",
      ),

      docH2('WhatsApp'),
      docP(
        'WhatsApp needs five values from your own Meta App: an access token, phone_number_id, '
        'WABA id, app id, and app secret. Getting all five is the long part — see the dedicated '
        'walkthrough below. Once you have them:',
      ),
      const CodeBlock(
        dart:
            "final channel = await client.channel.connectWhatsAppChannelManual(\n"
            "  accessToken, workspaceId, bot.id!,\n"
            '  whatsappAccessToken: "...",\n'
            '  phoneNumberId: "...",\n'
            '  wabaId: "...",\n'
            '  whatsappAppId: "...",\n'
            '  whatsappAppSecret: "...",\n'
            ");",
      ),
      docNote(
        "Kola checks whether your token is Meta's default 24-hour temporary token or a real "
        'permanent System User token, and warns you if it\'s about to expire — see the '
        'walkthrough\'s step 5 for how to generate the permanent kind up front.',
      ),
      div(
        attributes: {'style': 'margin-top:8px'},
        [
          Link(
            to: '/channels/connect-whatsapp',
            attributes: {
              'style':
                  'color:${KolaDocsColors.accent};text-decoration:none;font-size:13.5px;font-weight:600',
            },
            child: Component.text('Connect your WhatsApp — full walkthrough →'),
          ),
        ],
      ),

      docH2('Listing a bot\'s channels'),
      const CodeBlock(
        dart:
            "final channels = await client.channel.listChannelsForBot(\n"
            "  accessToken, workspaceId, bot.id!,\n"
            ");",
      ),
    ]);
  }
}
