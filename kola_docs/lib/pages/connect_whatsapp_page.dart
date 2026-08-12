// connect_whatsapp_page.dart — '/channels/connect-whatsapp'.
//
// Content is docs/WHATSAPP_MANUAL_SETUP.md's own 7 steps, carried over
// rather than rewritten — that file IS the source of truth for this
// flow (it's what Kola's own team follows). Its ~12 screenshot
// placeholder markers are carried over as real docScreenshotPlaceholder
// callouts too, per DESIGN_PROMPT.md §12's own explicit instruction
// ("Real screenshots... to be supplied once available; placeholder
// callout boxes until then") — task #88 (capture real screenshots) is
// still open, so faking images here would be worse than this honest gap.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../components/doc_page_kit.dart';

class ConnectWhatsAppPage extends StatelessComponent {
  const ConnectWhatsAppPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Connect your WhatsApp'),
      docLede(
        'Five values, one Meta App, about 20 minutes the first time. This is the manual path — '
        "the only path today; there's no one-click Embedded Signup flow yet.",
      ),

      docH2('1. Create a Meta App'),
      docP('developers.facebook.com → My Apps → Create App → Business type.'),
      docScreenshotPlaceholder('the Meta App creation form with "Business" type selected'),

      docH2('2. Add the WhatsApp product'),
      docP('In your new app\'s dashboard, add the WhatsApp product from the product list.'),
      docScreenshotPlaceholder('the "Add products to your app" screen with WhatsApp highlighted'),

      docH2('3. Add and verify a real phone number'),
      docP(
        'This number stops working in the consumer WhatsApp app the moment it\'s connected — '
        "that's permanent, not a trial. Use a number you're prepared to dedicate to this.",
      ),
      docScreenshotPlaceholder('the phone number verification step, code entry screen'),

      docH2('4. Get your Phone Number ID and WABA ID'),
      docP('Both are visible on the WhatsApp → API Setup page once your number is added.'),
      docScreenshotPlaceholder('the API Setup page with Phone Number ID and WABA ID circled'),

      docH2('4a. Get your App ID and App Secret'),
      docP('App Settings → Basic — App Secret requires re-entering your Meta password to reveal.'),
      docScreenshotPlaceholder('App Settings → Basic, with App ID and the "Show" App Secret button'),

      docH2('5. Generate a permanent access token'),
      docP(
        "The token shown by default on the API Setup page is temporary (~24 hours) — fine for "
        "testing, useless in production. Generate a System User token instead: Business "
        "Settings → Users → System Users → Add → assign it your WhatsApp asset with Standard "
        'Access → Generate Token.',
      ),
      docScreenshotPlaceholder('the System User token generation dialog with permission scopes'),

      docH2('6. Connect it in Kola'),
      docP('Paste all five values — access token, Phone Number ID, WABA ID, App ID, App Secret.'),
      docScreenshotPlaceholder("Kola's own Connect WhatsApp screen with the five fields"),
      docNote(
        'Kola checks whether the token is temporary or permanent and warns you if it\'s about '
        'to expire, before saving anything.',
      ),

      docH2("7. Point Meta's webhook at Kola"),
      docP(
        "WhatsApp → Configuration → Webhooks: set the Callback URL and Verify Token Kola's "
        'team currently provides you directly — the dashboard doesn\'t yet self-serve display '
        'these per-channel (a real gap, not a design choice).',
      ),
      docScreenshotPlaceholder('the Webhooks configuration screen with Callback URL field'),

      docH2('Keeping it working'),
      docP(
        "A permanent token can still be revoked from Meta's side (business changes, asset "
        'reassigned, etc.) — a nightly automatic health check for this is planned but not '
        "built yet. Until then, if messages silently stop arriving, re-check the token's "
        "validity in Meta's own Business Settings first.",
      ),
    ]);
  }
}
