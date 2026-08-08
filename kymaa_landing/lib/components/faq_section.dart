// faq_section.dart — accordion FAQ, addressing the Nigeria-specific
// concerns DESIGN_PROMPT.md called out (developer requirement, own
// database, trial behavior, dual-channel support).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../models/faq_item.dart';

class FaqSection extends StatelessComponent {
  const FaqSection({required this.openIndexes, required this.onToggle});

  final Set<int> openIndexes;
  final void Function(int index) onToggle;

  static const _faqs = [
    FaqItem(
      question: 'Do I need a developer?',
      answer:
          'No. Most owners build and launch their bot entirely by describing '
          'it in chat. Developers can go further with Structured Mode if they want to.',
    ),
    FaqItem(
      question: 'Can I use my own database?',
      answer: 'Yes — connect a database, spreadsheet, or hand it to your developer via our API and webhooks.',
    ),
    FaqItem(
      question: 'What happens after the 14-day trial?',
      answer:
          "You drop to a limited free plan automatically — nothing is disconnected, "
          'and you can upgrade any time.',
    ),
    FaqItem(
      question: 'Does this work if my customers are on WhatsApp and Telegram?',
      answer: 'Yes — one bot, one set of Errands, both channels at once.',
    ),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      id: 'faq',
      attributes: {'style': 'max-width:760px;margin:120px auto 0;padding:0 32px'},
      [
        Component.element(
          tag: 'h2',
          classes: 'kola-h2',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:36px;font-weight:500;'
                'margin:0 0 36px;text-align:center;color:${KolaColors.text}',
          },
          children: [Component.text('Questions, answered.')],
        ),
        for (var i = 0; i < _faqs.length; i++) _faqRow(i, _faqs[i]),
      ],
    );
  }

  Component _faqRow(int index, FaqItem faq) {
    final open = openIndexes.contains(index);
    return div(
      attributes: {'style': 'border-top:1px solid ${KolaColors.border};padding:22px 0;cursor:pointer'},
      events: {'click': (e) => onToggle(index)},
      [
        div(
          attributes: {
            'style':
                'display:flex;justify-content:space-between;align-items:center;font-size:16.5px;'
                'font-weight:600;color:${KolaColors.text}',
          },
          [
            Component.text(faq.question),
            span(
              attributes: {'style': 'color:${KolaColors.textFaint};font-size:20px'},
              [Component.text(open ? '−' : '+')],
            ),
          ],
        ),
        // Always rendered (never conditionally omitted) so the
        // grid-template-rows 0fr→1fr transition in web/styles.css has an
        // actual element to animate — swapping the div in/out of the tree
        // on toggle (the old `if (open)` approach) would just snap
        // instantly, since Jaspr would mount/unmount rather than resize.
        div(
          classes: 'kola-faq-answer-wrap${open ? ' kola-faq-open' : ''}',
          [
            div(
              classes: 'kola-faq-answer-inner',
              [
                div(
                  attributes: {
                    'style':
                        'font-size:15px;color:${KolaColors.textMuted};line-height:1.6;'
                        'margin-top:12px;max-width:640px',
                  },
                  [Component.text(faq.answer)],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
