// hero_section.dart
//
// The headline + primary CTA. Behavior branches on `mode`:
//   - 'launched': shows a decorative bot-builder textarea (matches the
//     .dc.html's isLaunched branch) — cosmetic preview only, not wired to
//     a real endpoint yet, since Bot Mother doesn't exist until Phase 3.
//   - 'waitlist' (default, pre-launch): a real email/phone capture form
//     that posts to WaitlistApiService — this is the actual working path
//     right now.
//
// Fields are uncontrolled (read via interop.dart at submit time) — see
// web/script.js's header comment for why.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../interop.dart' as interop;

class HeroSection extends StatelessComponent {
  const HeroSection({
    required this.mode,
    required this.submitting,
    required this.submitted,
    required this.error,
    required this.onSubmit,
  });

  final String mode;
  final bool submitting;
  final bool submitted;
  final String? error;
  final void Function(String email, String phone) onSubmit;

  static const _quickPills = [
    'Customer care',
    'Ecommerce / catalog',
    'Order tracking',
    'Complaints',
    'Reminders',
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'max-width:900px;margin:0 auto;padding:88px 32px 40px;text-align:center;'
            'background-image:radial-gradient(circle,#DED4C2 1.4px,transparent 1.4px);'
            'background-size:22px 22px;background-position:center 40px;background-repeat:repeat;',
      },
      [
        div(
          attributes: {
            'style':
                'font-size:13px;letter-spacing:0.06em;text-transform:uppercase;'
                'color:${KolaColors.accent};font-weight:600;margin-bottom:20px',
          },
          [Component.text('Say it. Get a bot.')],
        ),
        Component.element(
          tag: 'h1',
          classes: 'kola-hero-title',
          attributes: {
            'style':
                'font-family:${KolaFonts.serif};font-size:64px;line-height:1.06;'
                'font-weight:500;letter-spacing:-0.02em;margin:0 0 22px;color:${KolaColors.text}',
          },
          children: [
            Component.text('Say it.'),
            Component.element(tag: 'br', children: const []),
            Component.text('kymaa builds the bot.'),
          ],
        ),
        p(
          attributes: {
            'style':
                'font-size:19px;color:${KolaColors.textMuted};max-width:560px;'
                'margin:0 auto 40px;line-height:1.5',
          },
          [
            Component.text(
              "For the shop owner who doesn't have a developer, doesn't have "
              'time, and just wants customers answered — on WhatsApp, in minutes.',
            ),
          ],
        ),

        if (mode == 'launched') _launchedPreview() else _waitlistForm(),

        div(
          attributes: {
            'style':
                'display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:22px',
          },
          [
            for (final label in _quickPills)
              button(
                classes: 'kola-quick-pill',
                attributes: {
                  'style':
                      'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
                      'border-radius:100px;padding:9px 16px;font-size:14px;'
                      'color:${KolaColors.textBody};cursor:pointer;font-family:inherit',
                },
                events: {'click': (e) => interop.scrollToId('waitlist')},
                [Component.text(label)],
              ),
          ],
        ),
      ],
    );
  }

  Component _cardWrap(List<Component> children) => div(
    attributes: {
      'style':
          'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
          'border-radius:26px;box-shadow:0 20px 50px rgba(28,24,21,0.07);'
          'padding:22px;text-align:left',
    },
    children,
  );

  Component _launchedPreview() => _cardWrap([
    Component.element(
      tag: 'textarea',
      attributes: {
        'placeholder':
            "Describe the bot you want — e.g. 'Answer customer questions from my price list'",
        'rows': '2',
        'style':
            'width:100%;border:none;outline:none;resize:none;font-family:${KolaFonts.sans};'
            'font-size:17px;color:${KolaColors.text};background:transparent;box-sizing:border-box',
      },
      children: const [],
    ),
    div(
      attributes: {
        'style': 'display:flex;align-items:center;justify-content:space-between;margin-top:10px',
      },
      [
        div(attributes: {'style': 'display:flex;gap:10px'}, [
          _roundIcon('🎙'),
          _roundIcon('📎'),
        ]),
        div(
          attributes: {
            'style':
                'width:38px;height:38px;border-radius:50%;background:${KolaColors.accent};'
                'display:flex;align-items:center;justify-content:center;color:#FFF6EE;'
                'font-size:16px;cursor:pointer',
          },
          [Component.text('→')],
        ),
      ],
    ),
  ]);

  Component _roundIcon(String glyph) => div(
    attributes: {
      'style':
          'width:34px;height:34px;border-radius:50%;background:${KolaColors.bg};'
          'display:flex;align-items:center;justify-content:center;color:${KolaColors.textFaint};'
          'font-size:15px;cursor:pointer',
    },
    [Component.text(glyph)],
  );

  Component _waitlistForm() {
    if (submitted) {
      return div(
        attributes: {
          'style':
              'background:${KolaColors.cardBg};border:1px solid ${KolaColors.success};'
              'border-radius:26px;box-shadow:0 20px 50px rgba(28,24,21,0.07);'
              'padding:32px;text-align:center',
        },
        [
          div(
            attributes: {
              'style':
                  'width:44px;height:44px;border-radius:50%;background:${KolaColors.successBg};'
                  'color:${KolaColors.success};display:flex;align-items:center;justify-content:center;'
                  'font-size:20px;margin:0 auto 14px',
            },
            [Component.text('✓')],
          ),
          div(
            attributes: {'style': 'font-size:17px;font-weight:600;margin-bottom:4px'},
            [Component.text("You're on the list.")],
          ),
          div(
            attributes: {'style': 'font-size:14.5px;color:${KolaColors.textMutedLight}'},
            [Component.text("We'll message you as soon as it's your turn.")],
          ),
        ],
      );
    }

    return _cardWrap([
      Component.element(
        tag: 'textarea',
        attributes: {
          'placeholder': "Tell us what your business needs — we'll notify you the moment it's ready",
          'rows': '2',
          'style':
              'width:100%;border:none;outline:none;resize:none;font-family:${KolaFonts.sans};'
              'font-size:17px;color:${KolaColors.text};background:transparent;'
              'margin-bottom:14px;box-sizing:border-box',
        },
        children: const [],
      ),
      div(
        attributes: {'style': 'display:flex;gap:10px;flex-wrap:wrap'},
        [
          input(
            attributes: {
              'id': 'heroEmail',
              'type': 'email',
              'placeholder': 'Email address',
              'style':
                  'flex:1;min-width:180px;border:1px solid ${KolaColors.border};border-radius:100px;'
                  'padding:11px 16px;font-size:14px;font-family:inherit;color:${KolaColors.text}',
            },
          ),
          input(
            attributes: {
              'id': 'heroPhone',
              'type': 'tel',
              'placeholder': 'WhatsApp number (optional)',
              'style':
                  'flex:1;min-width:180px;border:1px solid ${KolaColors.border};border-radius:100px;'
                  'padding:11px 16px;font-size:14px;font-family:inherit;color:${KolaColors.text}',
            },
          ),
          button(
            classes: 'kola-btn-lift',
            attributes: {
              'style':
                  'background:${KolaColors.accent};color:#FFF6EE;border:none;border-radius:100px;'
                  'padding:11px 22px;font-size:14px;font-weight:600;font-family:inherit;'
                  'cursor:pointer;white-space:nowrap;opacity:${submitting ? "0.6" : "1"}',
            },
            events: {
              'click': (e) {
                if (submitting) return;
                onSubmit(
                  interop.fieldValue('heroEmail'),
                  interop.fieldValue('heroPhone'),
                );
              },
            },
            [Component.text(submitting ? 'Joining…' : 'Join waitlist →')],
          ),
        ],
      ),
      if (error != null)
        div(
          attributes: {
            'style': 'color:#B33B2E;font-size:13px;margin-top:10px',
          },
          [Component.text(error!)],
        ),
    ]);
  }
}
