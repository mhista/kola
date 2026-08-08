// security_section.dart
//
// Dark card. Every claim here is factually true of the shipped system —
// checked against the codebase before writing, because a security
// section is the worst possible place to overstate.
//
// The payments line is the strongest and least obvious: kola never holds
// customer money. Funds go directly to the business's own gateway
// account. Most competitors cannot say that, and it is worth stating
// plainly rather than burying in a bullet.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class SecuritySection extends StatelessComponent {
  const SecuritySection();

  static const _points = [
    'Every stored credential encrypted at rest with AES-256-GCM',
    'Per-workspace data isolation — nothing crosses between businesses',
    'kola never holds your money — payments go straight to your own '
        'payment account',
    'No vendor lock-in on the AI provider behind the scenes',
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'id': 'security',
        'style': 'max-width:1000px;margin:110px auto 0;padding:0 32px',
      },
      [
        div(
          classes: 'kola-security-card',
          attributes: {
            'style': 'background:${KolaColors.dark};border-radius:24px;padding:48px;'
                'color:${KolaColors.darkText}',
          },
          [
            div(
              attributes: {
                'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                    'color:${KolaColors.orange};font-weight:600;margin-bottom:14px',
              },
              [Component.text('Serious about your data, from day one')],
            ),
            h2(
              classes: 'kola-h2',
              attributes: {
                'style': 'font-family:${KolaFonts.serif};font-size:32px;font-weight:500;'
                    'margin:0 0 32px;max-width:520px',
              },
              [Component.text('Built to hold real business data.')],
            ),
            div(
              classes: 'kola-grid-2',
              attributes: {
                'style': 'display:grid;grid-template-columns:repeat(2,1fr);gap:20px',
              },
              [
                for (final point in _points)
                  div(
                    attributes: {
                      'style': 'display:flex;gap:12px;align-items:flex-start',
                    },
                    [
                      span(
                        attributes: {
                          'style': 'color:${KolaColors.orange};font-size:16px;flex:none',
                          'aria-hidden': 'true',
                        },
                        [Component.text('✓')],
                      ),
                      div(
                        attributes: {
                          'style': 'font-size:14.5px;color:${KolaColors.darkTextSoft};'
                              'line-height:1.5',
                        },
                        [Component.text(point)],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
