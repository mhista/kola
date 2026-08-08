// integrations_section.dart
//
// Pill chips, centred. Only tools that are actually connected today are
// listed — a logo wall of things that don't work yet is the same class
// of overstatement as a fabricated testimonial.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class IntegrationsSection extends StatelessComponent {
  const IntegrationsSection();

  // Naming payment providers HERE is factual — these are the ones
  // actually supported, and a business needs to know if theirs is among
  // them. That is different from writing product copy AROUND a provider,
  // which ties the whole pitch to one market.
  static const _integrations = [
    ('💬', 'WhatsApp'),
    ('✈️', 'Telegram'),
    ('💳', 'Stripe'),
    ('💳', 'Paystack'),
    ('💳', 'Flutterwave'),
    ('📊', 'Spreadsheets'),
    ('🖨️', 'Receipt printers'),
    ('🔔', 'Slack'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'integrations',
        'style': 'max-width:1100px;margin:100px auto 0;padding:0 32px;text-align:center',
      },
      [
        div(
          attributes: {
            'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.textFaint};margin-bottom:24px',
          },
          [Component.text('Connects to what you already use \u2014 more added regularly')],
        ),
        div(
          attributes: {
            'style': 'display:flex;gap:14px;justify-content:center;flex-wrap:wrap',
          },
          [
            for (final (icon, label) in _integrations)
              div(
                attributes: {
                  'style': 'display:flex;align-items:center;gap:8px;'
                      'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
                      'border-radius:100px;padding:10px 18px;font-size:14px;'
                      'color:${KolaColors.textBody};white-space:nowrap',
                },
                [
                  span(attributes: {'aria-hidden': 'true'}, [Component.text(icon)]),
                  span([Component.text(label)]),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
