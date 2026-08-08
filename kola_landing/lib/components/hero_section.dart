// hero_section.dart
//
// The repositioning lands or fails here. Headline confirmed from the v2
// design export: "Your business already has the data. / kola turns it
// into decisions." — the design lab's improvement on the supplied
// "Now It Has A Brain", and the better line: it says what kola DOES
// rather than anthropomorphising it, which also keeps it inside the
// product's own voice rules.
//
// Form behaviour branches on `mode` (Env.launchMode, a BUILD FLAG — see
// config/env.dart). Waitlist copy pre-launch, "Start free" after.
// Fields are uncontrolled and read via interop at submit time, same
// technique as the previous build — see web/script.js's header.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../interop.dart' as interop;
import '../i18n/strings.dart';  

class HeroSection extends StatelessComponent {
  const HeroSection({
    required this.s,
    required this.mode,
    required this.submitting,
    required this.submitted,
    required this.error,
    required this.onSubmit,
  });

  /// Localised copy. Passed in from app.dart — a component never
  /// resolves its own locale. See i18n/strings.dart.
  final Strings s;

  final String mode;
  final bool submitting;
  final bool submitted;
  final String? error;
  final void Function(String email) onSubmit;

  bool get _isWaitlist => mode != 'launched';

  // Deliberately not geographic. Nothing about the product is
  // country-specific — a shop in Lagos, Nairobi or Manila has the same
  // problem and connects its own payment provider the same way.
  static const _audiences = [
    'Small businesses',
    'Agencies',
    'Retail',
    'Growing startups',
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'id': 'top'},
      [
        div(
          classes: 'kola-hero',
          attributes: {
            'style': 'max-width:920px;margin:0 auto;padding:88px 32px 40px;'
                'text-align:center;'
                'background-image:radial-gradient(circle,#DED4C2 1.4px,transparent 1.4px);'
                'background-size:22px 22px;background-position:center 40px;'
                'background-repeat:repeat',
          },
          [
            div(
              attributes: {
                'style': 'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                    'color:${KolaColors.accent};font-weight:600;margin-bottom:20px',
              },
              [Component.text(s.heroEyebrow)],
            ),
            h1(
              classes: 'kola-hero-title',
              attributes: {
                'style': 'font-family:${KolaFonts.serif};font-size:58px;line-height:1.08;'
                    'font-weight:500;letter-spacing:-0.02em;margin:0 0 22px',
              },
              [
                Component.text(s.heroTitleLine1),
                br(),
                Component.text(s.heroTitleLine2),
              ],
            ),
            p(
              classes: 'kola-hero-sub',
              attributes: {
                'style': 'font-size:18px;color:${KolaColors.textMuted};max-width:600px;'
                    'margin:0 auto 36px;line-height:1.55',
              },
              [
                Component.text(s.heroSubtitle),
              ],
            ),
            if (submitted) _successCard() else _form(),
            div(
              attributes: {
                'style': 'display:flex;gap:12px;justify-content:center;flex-wrap:wrap;'
                    'margin-top:20px;font-size:13px;color:${KolaColors.textFaint}',
              },
              [
                for (var i = 0; i < _audiences.length; i++) ...[
                  if (i > 0) span([Component.text('·')]),
                  span([Component.text(_audiences[i])]),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Component _form() {
    return div(
      attributes: {
        'style': 'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
            'border-radius:26px;box-shadow:0 20px 50px rgba(28,24,21,0.07);'
            'padding:22px;text-align:left;max-width:600px;margin:0 auto',
      },
      [
        div(
          attributes: {
            'style': 'font-size:14.5px;color:${KolaColors.textMuted};margin-bottom:12px',
          },
          [
            Component.text(_isWaitlist ? s.heroWaitlistPrompt : s.heroLaunchedPrompt),
          ],
        ),
        div(
          classes: 'kola-hero-form-row',
          attributes: {'style': 'display:flex;gap:10px;flex-wrap:wrap'},
          [
            input(
              type: InputType.email,
              id: 'heroEmail',
              attributes: {
                'placeholder': s.heroEmailPlaceholder,
                'autocomplete': 'email',
                'aria-label': s.heroEmailPlaceholder,
                'style': 'flex:1;min-width:180px;border:1px solid ${KolaColors.border};'
                    'border-radius:100px;padding:11px 16px;font-size:14px;'
                    'font-family:inherit;color:${KolaColors.text};box-sizing:border-box',
              },
            ),
            button(
              classes: 'kola-btn-lift',
              attributes: {
                'style': 'background:${KolaColors.accent};color:${KolaColors.accentText};'
                    'border:none;border-radius:100px;padding:11px 22px;font-size:14px;'
                    'font-weight:600;font-family:inherit;cursor:pointer;white-space:nowrap',
                if (submitting) 'disabled': 'disabled',
              },
              events: {
                'click': (_) => onSubmit(interop.fieldValue('heroEmail')),
              },
              [
                Component.text(submitting
                    ? s.ctaSending
                    : (_isWaitlist ? s.ctaJoinWaitlist : s.ctaStartFree)),
              ],
            ),
          ],
        ),
        if (error != null)
          div(
            attributes: {
              'style': 'font-size:13px;color:#B3341A;margin-top:10px',
              'role': 'alert',
            },
            [Component.text(error!)],
          ),
      ],
    );
  }

  Component _successCard() {
    return div(
      attributes: {
        'style': 'background:${KolaColors.cardBg};border:1px solid ${KolaColors.success};'
            'border-radius:26px;box-shadow:0 20px 50px rgba(28,24,21,0.07);'
            'padding:32px;text-align:center;max-width:600px;margin:0 auto',
      },
      [
        div(
          attributes: {
            'style': 'width:44px;height:44px;border-radius:50%;'
                'background:${KolaColors.successBg};color:${KolaColors.success};'
                'display:flex;align-items:center;justify-content:center;'
                'font-size:20px;margin:0 auto 14px',
          },
          [Component.text('✓')],
        ),
        div(
          attributes: {'style': 'font-size:17px;font-weight:600;margin-bottom:4px'},
          [Component.text(s.heroSuccessTitle)],
        ),
        div(
          attributes: {'style': 'font-size:14.5px;color:${KolaColors.textMutedLight}'},
          [Component.text(s.heroSuccessBody)],
        ),
      ],
    );
  }
}
