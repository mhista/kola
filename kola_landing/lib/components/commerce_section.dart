// commerce_section.dart
//
// ADDED BY ENGINEERING — NOT IN THE DESIGN EXPORT. Confirmed with the
// project owner before writing.
//
// WHY: the v2 landing design sells memory, intelligence, agents and
// automations, and never once mentions that kolaa runs the business's
// sales counter, keeps working with no internet, and prints receipts.
// All of that ships in V1.
//
// For this market specifically, "keeps selling when the network is
// down" is plausibly the single most persuasive sentence on the whole
// page — and it is the one claim no competitor here can make. Leaving
// it off undersells V1 badly.
//
// PLACED AFTER MEMORY, BEFORE INTELLIGENCE, deliberately. The argument
// only lands in that order: memory establishes that kolaa knows the
// business, commerce shows the fastest way it learns, and the
// intelligence section that follows is then obviously grounded in real
// sales rather than assertion.
//
// TERMINOLOGY: "sales counter", never "till" or "POS" — confirmed
// product naming.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class CommerceSection extends StatelessComponent {
  const CommerceSection();

  static const _points = [
    // Replaces a "sell offline" card that repeated the panel directly
    // above it. This is the answer to the real objection — "I am not
    // typing in my whole shop" — and it was missing from the page.
    (
      'It fills its own catalog',
      'Scan a barcode and kolaa suggests the product. Photograph a shelf and '
          'it reads what is there. Three thousand items becomes an afternoon, '
          'not a fortnight of typing.',
    ),
    (
      'Your catalog answers customers',
      'The same prices and stock your counter uses are what the bot replies '
          'with on WhatsApp. Ask "do you have this in size 12" and the '
          'answer is real, not a guess.',
    ),
    (
      'Receipts that bring people back',
      'Printed or sent to WhatsApp — carrying the return window, the '
          'warranty, and a way to order again. Attached to the customer, so '
          'next time kolaa knows what they bought.',
    ),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'commerce',
        'style': 'max-width:1100px;margin:110px auto 0;padding:0 32px',
      },
      [
        div(
          attributes: {
            'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px;'
                'text-align:center',
          },
          [Component.text('Sales counter')],
        ),
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 14px;text-align:center',
          },
          [Component.text('It runs your counter. And learns from every sale.')],
        ),
        p(
          attributes: {
            'style': 'font-size:15.5px;color:${KolaColors.textMuted};text-align:center;'
                'max-width:600px;margin:0 auto 40px;line-height:1.6',
          },
          [
            Component.text(
              'Ring up a sale on the phone you already have — nothing new to buy. '
              'It keeps working when the network does not, and everything it sees '
              'makes the rest of kolaa sharper.',
            ),
          ],
        ),

        // ── The offline claim, given its own weight ──────────────────
        // Set apart from the three cards below because it is the line
        // that wins the customer, not a feature bullet among others.
        div(
          attributes: {
            'style': 'background:${KolaColors.dark};border-radius:20px;padding:32px;'
                'color:${KolaColors.darkText};text-align:center;margin-bottom:24px',
          },
          [
            div(
              classes: 'kola-offline-row',
              attributes: {
                'style': 'display:flex;align-items:center;justify-content:center;'
                    'gap:14px;flex-wrap:wrap;margin-bottom:12px',
              },
              [
                span(
                  attributes: {
                    'style': 'width:9px;height:9px;border-radius:50%;'
                        'background:${KolaColors.orange};display:inline-block;flex:none',
                  },
                  [],
                ),
                span(
                  attributes: {
                    'style': 'font-family:${KolaFonts.mono};font-size:13px;'
                        'color:${KolaColors.orange};letter-spacing:0.02em',
                  },
                  [Component.text('Offline — 6 sales waiting to sync')],
                ),
              ],
            ),
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.serif};font-size:24px;'
                    'font-weight:500;margin-bottom:8px;line-height:1.3',
              },
              [Component.text('No data? Keep selling.')],
            ),
            div(
              attributes: {
                'style': 'font-size:14.5px;color:${KolaColors.darkTextMuted};'
                    'max-width:520px;margin:0 auto;line-height:1.6',
              },
              [
                Component.text(
                  'Most tools stop the moment the network does. kolaa keeps selling, '
                  'queues every sale, and syncs itself when you are back — nothing '
                  'is lost, and the count is always on screen.',
                ),
              ],
            ),
          ],
        ),

        div(
          classes: 'kola-grid-3',
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(3,1fr);gap:20px',
          },
          [
            for (final (title, body) in _points)
              div(
                attributes: {
                  'style': 'background:${KolaColors.cardBg};'
                      'border:1px solid ${KolaColors.border};border-radius:18px;padding:26px',
                },
                [
                  div(
                    attributes: {
                      'style': 'font-size:17px;font-weight:600;margin-bottom:10px',
                    },
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

        div(
          attributes: {
            'style': 'font-size:13px;color:${KolaColors.textFaint};text-align:center;'
                'margin-top:20px',
          },
          [Component.text('Optional. If you do not sell products, you will never see it.')],
        ),
      ],
    );
  }
}
