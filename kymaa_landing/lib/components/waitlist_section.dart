// waitlist_section.dart
//
// The dedicated #waitlist section — email (required) + WhatsApp number
// (optional), matching the hero form's fields. Only rendered when
// mode == 'waitlist'; disappears once the toggle (or, at real launch, the
// removed default) flips to 'launched'.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../interop.dart' as interop;

class WaitlistSection extends StatelessComponent {
  const WaitlistSection({
    required this.visible,
    required this.revealed,
    required this.submitting,
    required this.submitted,
    required this.error,
    required this.onSubmit,
  });

  final bool visible;

  // Whether app.dart's scroll-reveal state already reported this section
  // as visible — this section manages its own `classes:` (unlike most
  // sections, which get 'kola-reveal' merged on by app.dart's
  // Component.wrapElement) so it needs the flag passed in directly. See
  // interop.dart's header comment for why this is Dart state rather than
  // a class script.js adds straight to the DOM.
  final bool revealed;

  final bool submitting;
  final bool submitted;
  final String? error;
  final void Function(String email, String phone) onSubmit;

  @override
  Component build(BuildContext context) {
    if (!visible) return Component.empty();

    return div(
      id: 'waitlist',
      classes: revealed ? 'kola-reveal kola-reveal-in' : 'kola-reveal',
      attributes: {'style': 'max-width:640px;margin:110px auto 0;padding:0 32px;text-align:center'},
      [
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.serif};font-size:34px;font-weight:500;'
                'margin:0 0 10px;color:${KolaColors.text}',
          },
          [Component.text('Be first in line.')],
        ),
        p(
          attributes: {
            'style': 'font-size:15.5px;color:${KolaColors.textMuted};margin:0 0 32px;line-height:1.5',
          },
          [
            Component.text(
              "kola isn't live yet — join the waitlist for early access and "
              'founding-member pricing when we open the doors.',
            ),
          ],
        ),
        if (submitted) _submittedCard() else _form(),
      ],
    );
  }

  Component _submittedCard() => div(
    attributes: {
      'style':
          'background:${KolaColors.cardBg};border:1px solid ${KolaColors.success};'
          'border-radius:20px;padding:28px;text-align:center',
    },
    [
      div(
        attributes: {'style': 'font-size:16px;font-weight:600;color:${KolaColors.text}'},
        [Component.text("You're on the list — thank you!")],
      ),
    ],
  );

  Component _form() => div(
    attributes: {
      'style':
          'background:${KolaColors.cardBg};border:1px solid ${KolaColors.border};'
          'border-radius:20px;padding:24px;text-align:left',
    },
    [
      div(
        attributes: {'style': 'display:flex;gap:10px;flex-wrap:wrap'},
        [
          input(
            attributes: {
              'id': 'wlEmail',
              'type': 'email',
              'placeholder': 'Email address',
              'style': _fieldStyle,
            },
          ),
          input(
            attributes: {
              'id': 'wlPhone',
              'type': 'tel',
              'placeholder': 'WhatsApp number (optional)',
              'style': _fieldStyle,
            },
          ),
          button(
            classes: 'kola-btn-lift',
            attributes: {
              'style':
                  'background:${KolaColors.accent};color:#FFF6EE;border:none;border-radius:100px;'
                  'padding:11px 26px;font-size:14px;font-weight:600;font-family:inherit;'
                  'cursor:pointer;white-space:nowrap;opacity:${submitting ? "0.6" : "1"}',
            },
            events: {
              'click': (e) {
                if (submitting) return;
                onSubmit(
                  interop.fieldValue('wlEmail'),
                  interop.fieldValue('wlPhone'),
                );
              },
            },
            [Component.text(submitting ? 'Joining…' : 'Join waitlist')],
          ),
        ],
      ),
      if (error != null)
        div(
          attributes: {'style': 'color:#B33B2E;font-size:13px;margin-top:10px'},
          [Component.text(error!)],
        ),
    ],
  );

  static const _fieldStyle =
      'flex:1;min-width:150px;border:1px solid ${KolaColors.border};border-radius:100px;'
      'padding:11px 16px;font-size:14px;font-family:inherit;color:${KolaColors.text};background:${KolaColors.cardBg}';
}
