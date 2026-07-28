// team_split_section.dart
//
// "Built for the whole team" — the no-code vs developer split panel that
// visually sells the dual-interface / Errand story from PRD.md §8.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class TeamSplitSection extends StatelessComponent {
  const TeamSplitSection();

  @override
  Component build(BuildContext context) {
    return div(
      id: 'reveal-team-split',
      attributes: {'style': 'max-width:1100px;margin:110px auto 0;padding:0 32px'},
      [
        Component.element(
          tag: 'h2',
          classes: 'kola-h2',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:40px;font-weight:500;'
                'margin:0 0 44px;text-align:center;color:${KolaColors.text}',
          },
          children: [Component.text('Built for the whole team.')],
        ),
        div(classes: 'kola-grid-2', [
          div(
            attributes: {
              'style':
                  'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
                  'border-radius:22px;padding:36px',
            },
            [
              div(
                attributes: {
                  'style':
                      'font-size:13px;letter-spacing:0.05em;text-transform:uppercase;'
                      'color:${KolaColors.accent};font-weight:600;margin-bottom:12px',
                },
                [Component.text('No code needed')],
              ),
              div(
                attributes: {'style': 'font-size:20px;font-weight:600;margin-bottom:16px;color:${KolaColors.text}'},
                [Component.text('Describe it in plain language.')],
              ),
              div(
                attributes: {
                  'style':
                      'background:${KolaColors.bg};border-radius:14px;padding:16px;font-size:14.5px;'
                      'color:${KolaColors.textNav};line-height:1.6',
                },
                [
                  Component.text(
                    '"When someone asks about delivery, check their order status and reply with the estimated date."',
                  ),
                ],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'background:${KolaColors.dark};border-radius:22px;padding:36px;color:${KolaColors.darkText}',
            },
            [
              div(
                attributes: {
                  'style':
                      'font-size:13px;letter-spacing:0.05em;text-transform:uppercase;'
                      'color:${KolaColors.orange};font-weight:600;margin-bottom:12px',
                },
                [Component.text('Built for developers')],
              ),
              div(
                attributes: {'style': 'font-size:20px;font-weight:600;margin-bottom:16px'},
                [Component.text('Or wire it up yourself.')],
              ),
              div(
                attributes: {
                  'style':
                      'background:${KolaColors.codeBg};border-radius:14px;padding:16px;'
                      'font-family:${KolaFonts.mono};font-size:13px;color:${KolaColors.codeText};'
                      'line-height:1.7;overflow-x:auto',
                },
                [
                  Component.text('curl https://api.kola.dev/errands \\'),
                  Component.element(tag: 'br', children: const []),
                  Component.text('  -H "Authorization: Bearer sk_live_..." \\'),
                  Component.element(tag: 'br', children: const []),
                  Component.text('  -d \'{ "trigger": "order.status" }\''),
                ],
              ),
            ],
          ),
        ]),
      ],
    );
  }
}
