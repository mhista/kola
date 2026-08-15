// hero_section.dart
//
// The repositioning lands or fails here. Headline confirmed from the v2
// design export: "Your business already has the data. / kolaa turns it
// into decisions." — the design lab's improvement on the supplied
// "Now It Has A Brain", and the better line: it says what kolaa DOES
// rather than anthropomorphising it, which also keeps it inside the
// product's own voice rules.
//
// ── THE HERO IS A DIFFERENT CONTROL IN EACH MODE, NOT THE SAME ONE
//    WITH DIFFERENT WORDS ──────────────────────────────────────────────
//
// `mode` is Env.launchMode, a BUILD FLAG — see config/env.dart.
//
//   waitlist    an email field. The product does not exist yet for this
//               visitor, so the only thing they can do is ask to be told
//               when it does. Collecting the address IS the conversion.
//   launched    a link to the app. There is nothing to collect: signup
//               happens in the dashboard, which already owns the email,
//               the password rules and the confirmation mail.
//
// An earlier pass changed only the BUTTON LABEL between the two, which
// left "Start free" sitting beside an email box that posted to
// waitlist_signups. That is worse than either mode alone: the visitor
// hands over an address expecting an account and gets a waitlist row,
// and the row is indistinguishable from a genuine pre-launch signup.
// So the field is removed in launched mode rather than relabelled.
//
// It is an <a>, not a <button> with a click handler, so it middle-clicks,
// right-click-copies and shows its destination on hover like every other
// link on the page. Styled to match the waitlist button exactly — the
// two modes should look identical to anyone who never sees both.
//
// Fields (waitlist mode only) are uncontrolled and read via interop at
// submit time — see web/script.js's header.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../config/links.dart';
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
            if (!_isWaitlist)
              _launchedCta()
            else if (submitted)
              _successCard()
            else
              _form(),
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

  /// Launched mode: a link to the dashboard, and no email field.
  ///
  /// The destination is [Links.app] rather than a literal, so the header
  /// CTA and this one cannot drift apart — they are the same promise made
  /// twice on one screen, and a visitor who tries both should not land in
  /// two places.
  Component _launchedCta() {
    return div(
      attributes: {
        'style': 'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
            'border-radius:26px;box-shadow:0 20px 50px rgba(28,24,21,0.07);'
            'padding:26px 22px;text-align:center;max-width:600px;margin:0 auto',
      },
      [
        div(
          attributes: {
            'style': 'font-size:14.5px;color:${KolaColors.textMuted};margin-bottom:16px',
          },
          [Component.text(s.heroLaunchedPrompt)],
        ),
        a(
          href: Links.app,
          classes: 'kola-btn-lift',
          attributes: {
            'style': 'display:inline-block;text-decoration:none;'
                'background:${KolaColors.accent};color:${KolaColors.accentText};'
                'border-radius:100px;padding:13px 28px;font-size:15px;'
                'font-weight:600;font-family:inherit;white-space:nowrap',
          },
          [Component.text(s.ctaStartFree)],
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
