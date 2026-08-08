// site_footer.dart — dark footer with link columns, a footer waitlist
// mini-form (waitlist mode only), and the big wordmark moment.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';
import '../interop.dart' as interop;

class _FooterCol {
  const _FooterCol(this.title, this.items);
  final String title;
  final List<String> items;
}

class SiteFooter extends StatelessComponent {
  const SiteFooter({
    required this.mode,
    required this.submitting,
    required this.submitted,
    required this.onSubmit,
  });

  final String mode;
  final bool submitting;
  final bool submitted;
  final void Function(String email) onSubmit;

  static const _cols = [
    _FooterCol('Product', ['Bots', 'Errands', 'Knowledge', 'Pricing']),
    _FooterCol('Resources', ['Docs', 'API reference', 'Templates', 'Blog']),
    _FooterCol('Company', ['About', 'Careers', 'Contact', 'Legal']),
  ];

  @override
  Component build(BuildContext context) {
    final isWaitlist = mode == 'waitlist';

    return div(
      attributes: {
        'style': 'background:${KolaColors.dark};color:${KolaColors.darkText};margin-top:130px;padding-top:80px',
      },
      [
        div(
          classes: 'kola-grid-footer',
          attributes: {'style': 'max-width:1100px;margin:0 auto;padding:0 32px 50px'},
          [
            div(
              attributes: {'style': 'font-size:14.5px;color:${KolaColors.darkTextMuted};line-height:1.6;max-width:280px'},
              [
                Component.text(
                  'Describe the bot. kymaa builds it, trains it, and puts it on WhatsApp '
                  '& Telegram — no developer required.',
                ),
              ],
            ),
            for (final col in _cols)
              div([
                div(
                  attributes: {
                    'style':
                        'font-size:12px;letter-spacing:0.06em;text-transform:uppercase;'
                        'color:${KolaColors.darkTextFaint};margin-bottom:16px',
                  },
                  [Component.text(col.title)],
                ),
                for (final item in col.items)
                  div(
                    attributes: {'style': 'font-size:14.5px;color:${KolaColors.darkTextSoft};padding:6px 0'},
                    [Component.text(item)],
                  ),
              ]),
          ],
        ),
        div(
          attributes: {'style': 'text-align:center;padding:20px 0 10px;overflow:hidden'},
          [
            if (isWaitlist) _footerForm(),
            div(
              attributes: {
                'style':
                    "font-family:${KolaFonts.serif};font-size:min(18vw,220px);font-weight:600;"
                    'color:#2A2622;letter-spacing:-0.03em;line-height:0.9',
              },
              [Component.text('kymaa')],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'border-top:1px solid ${KolaColors.darkBorder};padding:20px 32px;text-align:center;'
                'font-size:13px;color:${KolaColors.darkTextFaint}',
          },
          [Component.text('© 2026 kymaa. Made for businesses that never open a laptop.')],
        ),
      ],
    );
  }

  Component _footerForm() {
    final label = submitted ? "You're in ✓" : 'Join';
    return div(
      attributes: {'style': 'max-width:420px;margin:0 auto 40px;display:flex;gap:8px'},
      [
        input(
          attributes: {
            'id': 'footerEmail',
            'type': 'email',
            'placeholder': 'Join the waitlist — email address',
            'style':
                'flex:1;border:1px solid ${KolaColors.darkInputBorder};background:${KolaColors.darkInputBg};'
                'border-radius:100px;padding:11px 16px;font-size:13.5px;font-family:inherit;color:${KolaColors.darkText}',
          },
        ),
        button(
          classes: 'kola-btn-lift',
          attributes: {
            'style':
                'background:${KolaColors.accent};color:#FFF6EE;border:none;border-radius:100px;'
                'padding:11px 20px;font-size:13.5px;font-weight:600;font-family:inherit;'
                'cursor:pointer;white-space:nowrap;opacity:${submitting ? "0.6" : "1"}',
          },
          events: {
            'click': (e) {
              if (submitting) return;
              onSubmit(interop.fieldValue('footerEmail'));
            },
          },
          [Component.text(label)],
        ),
      ],
    );
  }
}
