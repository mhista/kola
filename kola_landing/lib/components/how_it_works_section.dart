// how_it_works_section.dart
//
// Four steps, maximum. This is the section that makes an unfamiliar
// category graspable — "AI Operating System" means nothing until it's
// four verbs.
//
// Step 2 mentions the sales counter deliberately: it's the fastest way a
// business teaches kolaa anything, and it's what makes the intelligence
// layers work later.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class HowItWorksSection extends StatelessComponent {
  const HowItWorksSection();

  static const _steps = [
    ('01', 'Connect', 'WhatsApp, Telegram, your payment gateway, your spreadsheets.'),
    ('02', 'It learns', 'Paste in price lists and policies, or just start selling — '
        'every sale teaches it something.'),
    ('03', 'It works', 'Answers customers, rings up sales, tracks orders, drafts the '
        'next action.'),
    ('04', 'You approve', 'kolaa tells you what it did and what it recommends — you '
        'stay in control.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'how',
        'style': 'max-width:1000px;margin:100px auto 0;padding:0 32px',
      },
      [
        div(
          attributes: {
            'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px',
          },
          [Component.text('How it works')],
        ),
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 44px;max-width:560px',
          },
          [Component.text('Connect. It learns. It works. You approve.')],
        ),
        div(
          classes: 'kola-grid-4',
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(4,1fr);gap:24px',
          },
          [
            for (final (n, title, body) in _steps)
              div([
                div(
                  attributes: {
                    'style': 'width:40px;height:40px;border-radius:11px;'
                        'background:${KolaColors.dark};color:${KolaColors.darkText};'
                        'display:flex;align-items:center;justify-content:center;'
                        'font-family:${KolaFonts.serif};font-size:16px;margin-bottom:16px',
                  },
                  [Component.text(n)],
                ),
                div(
                  attributes: {'style': 'font-size:16px;font-weight:600;margin-bottom:6px'},
                  [Component.text(title)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:13.5px;color:${KolaColors.textMutedLight};'
                        'line-height:1.5',
                  },
                  [Component.text(body)],
                ),
              ]),
          ],
        ),
      ],
    );
  }
}
