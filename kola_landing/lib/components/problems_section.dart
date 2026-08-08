// problems_section.dart
//
// The before-state, named specifically. Deliberately concrete rather
// than generic SaaS pain — a shop owner anywhere should recognise her
// own week here, not a category. Nothing in it is region-specific.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class ProblemsSection extends StatelessComponent {
  const ProblemsSection();

  static const _problems = [
    (
      'The same question, forty times a day',
      'Every customer asks about price, stock and delivery separately, one '
          'WhatsApp thread at a time.',
    ),
    (
      'A message missed overnight is a sale lost',
      'By morning, the customer already bought from whoever replied first.',
    ),
    (
      'Nobody knows what actually makes money',
      'Revenue is visible. Which product is worth restocking is a guess.',
    ),
    (
      "The business runs on one person's memory",
      'Prices, policies and customer history live in someone’s head, not '
          'somewhere anyone can check.',
    ),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'problems',
        'style': 'max-width:1000px;margin:110px auto 0;padding:0 32px',
      },
      [
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 44px;text-align:center',
          },
          [Component.text('The same problems, every day.')],
        ),
        div(
          classes: 'kola-grid-2',
          attributes: {
            'style': 'display:grid;grid-template-columns:repeat(2,1fr);gap:20px',
          },
          [
            for (final (title, body) in _problems)
              div(
                attributes: {
                  'style': 'background:${KolaColors.cardBg};'
                      'border:1px solid ${KolaColors.border};border-radius:18px;padding:24px',
                },
                [
                  div(
                    attributes: {
                      'style': 'font-size:16px;font-weight:600;margin-bottom:8px',
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
      ],
    );
  }
}
