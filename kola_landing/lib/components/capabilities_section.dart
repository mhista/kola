// capabilities_section.dart
//
// Intelligence, agents and automations in one band. Three cards rather
// than three sections, because none of them is shipping at launch —
// giving each a full section would over-promise relative to what a
// visitor can actually use on day one.
//
// REWORDED 2026-09-09: each card now names what it actually pulls from —
// payments, sales and messages for intelligence; every connector for
// shared agent context; real connector-native actions (collect a
// payment, book a slot, check a transaction) for automations — instead
// of staying abstract. This is the section that should convince a
// visitor kolaa is a business intelligence layer with a chat interface,
// not a chat interface with some reports bolted on.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class CapabilitiesSection extends StatelessComponent {
  const CapabilitiesSection();

  static const _caps = [
    ('Business intelligence', 'Explains, not just charts',
        'Every number comes with a sentence: why it moved, and what to do about it — '
            'pulled from your payments, sales and messages together, not one spreadsheet '
            'at a time.'),
    ('Agents', 'Specialists, one shared memory',
        'Different jobs, same business context, gathered from every connector — nothing '
            'has to be re-explained.'),
    ('Automations', 'Multi-step, with your sign-off',
        'Collect a payment, book a slot, check a transaction, draft the next step — '
            'kolaa proposes it, you approve before anything goes out.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'capabilities',
        'style': 'max-width:1100px;margin:110px auto 0;padding:0 32px',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 44px;text-align:center',
          },
          [Component.text('Watches, explains, and acts.')],
        ),
        div(
          classes: 'kola-grid-3',
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(3,1fr);gap:20px',
          },
          [
            for (final (eyebrow, title, body) in _caps)
              div(
                attributes: {
                  'style': 'background:${KolaColors.cardBg};'
                      'border:1px solid ${KolaColors.border};border-radius:18px;padding:26px',
                },
                [
                  div(
                    attributes: {
                      'style': 'font-size:13px;letter-spacing:0.05em;'
                          'text-transform:uppercase;color:${KolaColors.accent};'
                          'font-weight:600;margin-bottom:10px',
                    },
                    [Component.text(eyebrow)],
                  ),
                  div(
                    attributes: {'style': 'font-size:17px;font-weight:600;margin-bottom:10px'},
                    [Component.text(title)],
                  ),
                  div(
                    attributes: {
                      'style': 'font-size:14px;color:${KolaColors.textMutedLight};'
                          'line-height:1.55',
                    },
                    [Component.text(body)],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
