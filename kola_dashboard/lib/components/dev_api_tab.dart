// dev_api_tab.dart — Structured Mode's API tab: a curl snippet showing
// how to call this bot directly, matching Kola Bot Detail Dev.dc.html.
// [botId] is threaded into the snippet's URL for real (it's the actual
// route parameter this page was loaded with) — the bearer token stays
// the design's own placeholder string since there's no real API key
// issuance flow yet (that's the API & Webhooks page, Phase 4e).
// "Manage API keys →" stays a plain inert '#' link for the same reason.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class DevApiTab extends StatelessComponent {
  const DevApiTab({required this.botId});

  final String botId;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'max-width:700px'},
      [
        div(
          attributes: {'style': 'font-size:14px;color:${KolaDashboardColors.mutedStrong};margin-bottom:14px'},
          [Component.text('Call this bot directly:')],
        ),
        pre(
          attributes: {
            'style':
                'background:#000;border-radius:10px;padding:16px;font-family:${KolaDashboardFonts.mono};'
                'font-size:12.5px;color:#9BE6C7;line-height:1.7',
          },
          [
            Component.text('curl https://api.kola.dev/bots/$botId/message \\'),
            Component.element(tag: 'br', children: const []),
            Component.text('  -H "Authorization: Bearer sk_live_..." \\'),
            Component.element(tag: 'br', children: const []),
            Component.text('  -d \'{ "text": "Do you have size 12?" }\''),
          ],
        ),
        a(
          attributes: {
            'style':
                'color:#E9A87C;font-size:13.5px;display:inline-block;margin-top:14px;text-decoration:none',
          },
          [Component.text('Manage API keys →')],
          href: '#',
        ),
      ],
    );
  }
}
