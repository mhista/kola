// how_it_works_section.dart — the 4-step "How it works" grid.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class _Step {
  const _Step(this.n, this.title, this.body);
  final String n;
  final String title;
  final String body;
}

class HowItWorksSection extends StatelessComponent {
  const HowItWorksSection();

  static const _steps = [
    _Step('01', 'Describe your business',
        "Tell kola what you sell and how you talk to customers — in your own words."),
    _Step('02', 'kola drafts the bot',
        'Bot Mother writes the Errands your bot needs and a first plan, ready to review.'),
    _Step('03', 'Connect WhatsApp or Telegram',
        'Link a number or a bot handle. Takes about a minute.'),
    _Step('04', 'Go live',
        'Your bot starts answering customers immediately. Adjust anytime, in chat.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      id: 'reveal-how-it-works',
      attributes: {'style': 'max-width:1100px;margin:100px auto 0;padding:0 32px'},
      [
        div(
          attributes: {
            'style':
                'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px',
          },
          [Component.text('How it works')],
        ),
        Component.element(
          tag: 'h2',
          classes: 'kola-h2',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:40px;font-weight:500;'
                'margin:0 0 48px;max-width:600px;color:${KolaColors.text}',
          },
          children: [Component.text('From description to live bot, same afternoon.')],
        ),
        div(
          classes: 'kola-grid-4',
          [
            for (final step in _steps)
              div([
                div(
                  attributes: {
                    'style':
                        'width:44px;height:44px;border-radius:12px;background:${KolaColors.dark};'
                        'color:${KolaColors.darkText};display:flex;align-items:center;'
                        'justify-content:center;font-family:${KolaFonts.serif};font-size:18px;'
                        'margin-bottom:18px',
                  },
                  [Component.text(step.n)],
                ),
                div(
                  attributes: {'style': 'font-size:17px;font-weight:600;margin-bottom:8px;color:${KolaColors.text}'},
                  [Component.text(step.title)],
                ),
                div(
                  attributes: {
                    'style': 'font-size:14.5px;color:${KolaColors.textMutedLight};line-height:1.5',
                  },
                  [Component.text(step.body)],
                ),
              ]),
          ],
        ),
      ],
    );
  }
}
