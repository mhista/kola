// app.dart — root component. Every route wraps its page in DocsShell so
// the nav/search chrome is identical everywhere; jaspr_router hands
// DocsShell the current path so it can highlight the active nav item.
//
// Routes (all real content, all pages listed — nothing links to a page
// that doesn't exist here):
//   /                         → QuickstartPage
//   /authentication           → AuthenticationPage
//   /errands                  → ErrandsPage
//   /webhooks                 → WebhooksPage
//   /channels                 → ChannelsPage
//   /channels/connect-whatsapp → ConnectWhatsAppPage
//   /rate-limits              → RateLimitsPage
//   /sdks                     → SdksPage
//   /billing/avoiding-excessive-whatsapp-billing → AvoidingExcessiveWhatsAppBillingPage

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/docs_shell.dart';
import 'pages/quickstart_page.dart';
import 'pages/authentication_page.dart';
import 'pages/errands_page.dart';
import 'pages/webhooks_page.dart';
import 'pages/channels_page.dart';
import 'pages/connect_whatsapp_page.dart';
import 'pages/rate_limits_page.dart';
import 'pages/sdks_page.dart';
import 'pages/avoiding_excessive_whatsapp_billing_page.dart';

class DocsApp extends StatelessComponent {
  const DocsApp();

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        _route('/', const QuickstartPage()),
        _route('/authentication', const AuthenticationPage()),
        _route('/errands', const ErrandsPage()),
        _route('/webhooks', const WebhooksPage()),
        _route('/channels', const ChannelsPage()),
        _route('/channels/connect-whatsapp', const ConnectWhatsAppPage()),
        _route('/rate-limits', const RateLimitsPage()),
        _route('/sdks', const SdksPage()),
        _route(
          '/billing/avoiding-excessive-whatsapp-billing',
          const AvoidingExcessiveWhatsAppBillingPage(),
        ),
      ],
    );
  }

  Route _route(String path, Component page) => Route(
    path: path,
    builder: (context, state) => DocsShell(currentPath: path, child: page),
  );
}
