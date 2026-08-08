// timeline_statement_section.dart
//
// One question, centred. The Timeline's value is correlation, not a log,
// and the fastest way to convey that is to show the question it answers
// rather than describe the feature.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class TimelineStatementSection extends StatelessComponent {
  const TimelineStatementSection();

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'timeline',
        'style': 'max-width:900px;margin:110px auto 0;padding:0 32px;text-align:center',
      },
      [
        div(
          attributes: {
            'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:14px',
          },
          [Component.text('Business timeline')],
        ),
        h2(
          classes: 'kola-h2',
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:34px;font-weight:500;'
                'margin:0 0 16px',
          },
          [Component.text('"What changed just before sales dropped?"')],
        ),
        p(
          attributes: {
            'style': 'font-size:15.5px;color:${KolaColors.textMuted};max-width:560px;'
                'margin:0 auto;line-height:1.6',
          },
          [
            Component.text(
              'Every price change, restock, sale, conversation and payment lands on '
              'one timeline — so a question like that has an answer, not a guess.',
            ),
          ],
        ),
      ],
    );
  }
}
