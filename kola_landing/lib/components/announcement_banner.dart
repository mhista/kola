// announcement_banner.dart
//
// The thin dismissible strip above the nav. Independent of waitlist/
// launched mode — it advertises the product itself, not the waitlist.
//
// Dismiss plays a slide-up-and-fade CSS animation (see .kola-banner-closing
// in web/styles.css) before actually leaving the DOM — app.dart's
// _closeBanner() sets [closing] true first, waits for the animation
// duration, then flips [visible] false. Rendering here just reflects
// whichever combination of those two flags it's given.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class AnnouncementBanner extends StatelessComponent {
  const AnnouncementBanner({
    required this.visible,
    required this.onClose,
    this.closing = false,
  });

  final bool visible;
  final bool closing;
  final void Function() onClose;

  @override
  Component build(BuildContext context) {
    if (!visible) return Component.empty();

    return div(
      classes: closing ? 'kola-banner-closing' : null,
      attributes: {
        'style':
            'background:${KolaColors.dark};color:${KolaColors.darkText};font-size:14px;'
            'text-align:center;padding:10px 44px 10px 16px;position:relative',
      },
      [
        Component.text("Try kolaa's WhatsApp customer-care bot free "),
        a(
          attributes: {'style': 'color:${KolaColors.peach};font-weight:600'},
          [Component.text(' →')],
          href: '#pricing',
        ),
        button(
          attributes: {
            'style':
                'position:absolute;right:14px;top:50%;transform:translateY(-50%);'
                'background:none;border:none;color:${KolaColors.textFaint};'
                'font-size:16px;cursor:pointer;line-height:1',
          },
          events: {'click': (e) => onClose()},
          [Component.text('×')],
        ),
      ],
    );
  }
}
