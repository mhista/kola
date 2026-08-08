// integrations_section.dart — "Connects to what you already use" row.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class _Integration {
  const _Integration(this.icon, this.label, {this.soon = false});
  final String icon;
  final String label;
  final bool soon;
}

class IntegrationsSection extends StatelessComponent {
  const IntegrationsSection();

  static const _integrations = [
    _Integration('💬', 'WhatsApp'),
    _Integration('✈️', 'Telegram'),
    // Paystack, Flutterwave, and Facebook chips are disabled for now —
    // not launch-ready yet. Re-add here when they're ready to ship:
    //   _Integration('💳', 'Paystack', soon: true),
    //   _Integration('💳', 'Flutterwave', soon: true),
    //   _Integration('📘', 'Facebook', soon: true),
    _Integration('📊', 'Google Sheets'),
    _Integration('🗄️', 'Your database'),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      id: 'reveal-integrations',
      attributes: {'style': 'max-width:1100px;margin:100px auto 0;padding:0 32px;text-align:center'},
      [
        div(
          attributes: {
            'style':
                'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.textFaint};margin-bottom:24px',
          },
          [Component.text('Connects to what you already use')],
        ),
        div(
          attributes: {'style': 'display:flex;gap:14px;justify-content:center;flex-wrap:wrap'},
          [
            for (final intg in _integrations)
              div(
                attributes: {
                  'style':
                      'display:flex;align-items:center;gap:8px;background:${KolaColors.cardBg};'
                      'border:1px solid ${KolaColors.border};border-radius:100px;padding:10px 18px;'
                      'font-size:14px;color:${KolaColors.textBody}',
                },
                [
                  span([Component.text(intg.icon)]),
                  span([Component.text(intg.label)]),
                  if (intg.soon)
                    span(
                      attributes: {
                        'style':
                            'font-size:11px;background:${KolaColors.pillBg};color:${KolaColors.badgeBrown};'
                            'padding:2px 7px;border-radius:100px',
                      },
                      [Component.text('soon')],
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
