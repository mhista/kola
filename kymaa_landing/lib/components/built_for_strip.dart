// built_for_strip.dart — "Built for" industry pills, static content.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class BuiltForStrip extends StatelessComponent {
  const BuiltForStrip();

  static const _industries = [
    'Fashion & beauty',
    'Food & logistics',
    'Services & agencies',
    'Retail & pharmacy',
    'Events & bookings',
  ];

  @override
  Component build(BuildContext context) {
    return div(
      id: 'reveal-built-for-strip',
      attributes: {'style': 'max-width:1000px;margin:56px auto 0;padding:0 32px;text-align:center'},
      [
        div(
          attributes: {
            'style':
                'font-size:12px;letter-spacing:0.08em;text-transform:uppercase;'
                'color:${KolaColors.textFaint};margin-bottom:18px',
          },
          [Component.text('Built for')],
        ),
        div(
          attributes: {'style': 'display:flex;gap:12px;justify-content:center;flex-wrap:wrap'},
          [
            for (final ind in _industries)
              div(
                attributes: {
                  'style':
                      'background:${KolaColors.pillBg};border-radius:100px;padding:9px 18px;'
                      'font-size:14px;color:${KolaColors.textNav}',
                },
                [Component.text(ind)],
              ),
          ],
        ),
      ],
    );
  }
}
