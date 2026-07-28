// dev_channels_tab.dart — Structured Mode's Channels tab: WhatsApp/
// Telegram connection status cards, matching Kola Bot Detail Dev.dc.html.
// See models/channel_card_summary.dart's header for the one deliberate
// deviation (a real per-card status color instead of the design file's
// single hardcoded green for both cards).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/channel_card_summary.dart';

class DevChannelsTab extends StatelessComponent {
  const DevChannelsTab({required this.cards});

  final List<ChannelCardSummary> cards;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'display:flex;gap:14px;max-width:700px'},
      [
        for (final c in cards)
          div(
            attributes: {
              'style':
                  'flex:1;background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
                  'border-radius:14px;padding:18px',
            },
            [
              div(attributes: {'style': 'font-size:20px;margin-bottom:8px'}, [Component.text(c.icon)]),
              div(
                attributes: {'style': 'font-size:14.5px;font-weight:600;margin-bottom:4px'},
                [Component.text(c.name)],
              ),
              div(
                attributes: {'style': 'font-size:12.5px;color:${c.statusColor}'},
                [Component.text(c.status)],
              ),
            ],
          ),
      ],
    );
  }
}
