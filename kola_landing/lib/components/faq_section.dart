// faq_section.dart
//
// Objection handling. Every answer here is checked against what the
// system actually does — the payments and data answers in particular,
// since those are the two a cautious buyer will test.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class FaqSection extends StatelessComponent {
  const FaqSection({required this.openIndexes, required this.onToggle});

  final Set<int> openIndexes;
  final void Function(int index) onToggle;

  static const faqs = [
    ('Do I need a developer?',
        'No. Most owners set up their agent entirely by describing it in plain '
        'language. Developers can go further with the API if they want to.'),
    ('Does it work without internet?',
        'The sales counter does. You can scan, take payment and print a receipt '
        'with no connection at all — everything syncs when the network returns, '
        'and you can see exactly what is waiting. Answering customers needs a '
        'connection, since the messages themselves do.'),
    ('What happens after the trial?',
        'A 48-hour full trial, then a 14-day step-down, then a capped free tier. '
        'Nothing is disconnected and nothing is deleted — you can upgrade any time '
        'and everything is exactly where you left it.'),
    ('Does kolaa hold my money?',
        'No. Payments go directly to your own payment provider account. kolaa '
        'never touches the funds \u2014 you connect the provider you already use.'),
    ('Will messaging cost me extra?',
        'Messaging providers set their own rates, and those change over time. kolaa '
        'never adds a markup, shows you what a send costs before it happens, and '
        'takes the cheaper route where one exists — including channels with no '
        'per-message fee at all. You can see exactly what you are spending in the '
        'dashboard.'),
    ('Is my data safe?',
        'Every credential is encrypted at rest, and each business\'s data is isolated '
        'from every other business on the platform.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'faq',
        'style': 'max-width:760px;margin:100px auto 0;padding:0 32px',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:34px;font-weight:500;'
                'margin:0 0 30px;text-align:center',
          },
          [Component.text('Questions, answered.')],
        ),
        for (var i = 0; i < faqs.length; i++) _row(i),
      ],
    );
  }

  Component _row(int i) {
    final (q, a) = faqs[i];
    final open = openIndexes.contains(i);
    return div(
      attributes: {
        'style': 'border-top:1px solid ${KolaColors.border}',
      },
      [
        button(
          classes: 'kola-faq-q',
          attributes: {
            'aria-expanded': open ? 'true' : 'false',
            'style': 'width:100%;background:none;border:none;padding:20px 0;'
                'cursor:pointer;font-family:inherit;color:${KolaColors.text};'
                'display:flex;justify-content:space-between;align-items:center;gap:16px;'
                'font-size:16px;font-weight:600;text-align:left',
          },
          events: {'click': (_) => onToggle(i)},
          [
            span([Component.text(q)]),
            span(
              attributes: {
                'style': 'color:${KolaColors.textFaint};font-size:20px;flex:none',
                'aria-hidden': 'true',
              },
              [Component.text(open ? '−' : '+')],
            ),
          ],
        ),
        if (open)
          div(
            attributes: {
              'style': 'font-size:14.5px;color:${KolaColors.textMuted};line-height:1.6;'
                  'padding:0 0 20px;max-width:620px',
            },
            [Component.text(a)],
          ),
      ],
    );
  }
}
