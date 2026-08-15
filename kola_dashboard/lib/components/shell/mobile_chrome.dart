// mobile_chrome.dart — the top bar, bottom tab bar, and "More" sheet
// used below 1024px.
//
// ── FLUID, NOT A 390px FRAME ─────────────────────────────────────────
//
// The design export renders mobile inside a fixed 390px column centred
// on the page, because that is how a design tool previews a phone. That
// is a preview artifact and is NOT carried over. Here the mobile layout
// is fluid from 360px up: it fills a phone, and it fills a tablet at
// 800px rather than sitting as a narrow strip in the middle of it.
//
// 360px IS THE FLOOR, not 390. Tecno, Infinix and itel devices dominate
// this product's market and are commonly 360 logical px wide. Every
// value here has to survive that width — which is why the tab bar is
// three tabs plus More rather than five, and why labels are short.
//
// ── THE BOTTOM BAR CLEARS THE HOME INDICATOR ─────────────────────────
//
// `padding-bottom` combines a base with env(safe-area-inset-bottom), so
// the tabs sit above the gesture bar on a notched phone and are not
// pushed up by dead space on a phone without one.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../nav/nav_model.dart';
import '../../services/feature_gate.dart';
import '../../theme.dart';
import 'icons.dart';
import 'kola_icon.dart';

// ── Top bar ───────────────────────────────────────────────────────────

class MobileTopBar extends StatelessComponent {
  const MobileTopBar({
    required this.workspaceName,
    required this.onOpenPalette,
    required this.onOpenProfile,
  });

  final String workspaceName;
  final void Function() onOpenPalette;
  final void Function() onOpenProfile;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;justify-content:space-between;'
            'gap:10px;padding:12px 16px;flex:none;'
            'border-bottom:1px solid ${KolaVar.border};background:${KolaVar.bg}',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:8px;min-width:0'},
          [
            kolaMark(size: 18),
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.display};font-size:${KolaType.subhead};'
                    'font-weight:700;color:${KolaVar.text};letter-spacing:-0.01em',
              },
              [Component.text('kolaa')],
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px;flex:none'},
          [
            button(
              attributes: {
                'class': 'kola-pressable',
                'style': 'background:${KolaVar.pill};border:none;'
                    'border-radius:${KolaRadius.circle};width:34px;height:34px;'
                    'display:flex;align-items:center;justify-content:center;'
                    'color:${KolaVar.muted}',
                'type': 'button',
                'aria-label': 'Search',
              },
              events: {'click': (_) => onOpenPalette()},
              [kolaIcon(Icons.search, size: 16)],
            ),
            button(
              attributes: {
                'class': 'kola-pressable',
                'style': 'width:30px;height:30px;border-radius:${KolaRadius.circle};'
                    'background:${KolaVar.tintIcon(0)};color:${KolaVar.accent};'
                    'border:none;display:flex;align-items:center;'
                    'justify-content:center;font-size:${KolaType.tiny};'
                    'font-weight:700;font-family:inherit',
                'type': 'button',
                'aria-label': 'Account and settings',
              },
              events: {'click': (_) => onOpenProfile()},
              [Component.text(_initial(workspaceName))],
            ),
          ],
        ),
      ],
    );
  }

  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

// ── Bottom tab bar ────────────────────────────────────────────────────

class MobileTabBar extends StatelessComponent {
  const MobileTabBar({
    required this.gate,
    required this.currentRoute,
    required this.onOpenMore,
  });

  final FeatureGate gate;
  final String currentRoute;
  final void Function() onOpenMore;

  @override
  Component build(BuildContext context) {
    final tabs = [for (final t in bottomTabs) if (t.isVisibleTo(gate)) t];

    return nav(
      attributes: {
        'style': 'display:flex;flex:none;border-top:1px solid ${KolaVar.border};'
            'background:${KolaVar.bg};'
            'padding:8px 0 calc(12px + env(safe-area-inset-bottom, 0px))',
        'aria-label': 'Primary',
      },
      [
        for (final tab in tabs) _tab(tab),
        _moreTab(),
      ],
    );
  }

  Component _tab(NavItem item) {
    final active = item.route == '/'
        ? currentRoute == '/'
        : currentRoute == item.route || currentRoute.startsWith('${item.route}/');

    return Link(
      to: item.route,
      attributes: {
        'class': 'kola-tab kola-pressable',
        'style': _tabStyle(active),
        if (active) 'aria-current': 'page',
      },
      children: [
        kolaIcon(item.icon, size: 18),
        span(
          attributes: {'style': 'font-size:10.5px;font-weight:600'},
          [Component.text(item.label)],
        ),
      ],
    );
  }

  /// 'More' is a sheet, not a destination — so it is a button, and it
  /// never shows as the active tab. Marking it active would claim the
  /// user is "on" a page that does not exist.
  Component _moreTab() => button(
        attributes: {
          'class': 'kola-tab kola-pressable',
          'style': '${_tabStyle(false)};background:transparent;border:none;'
              'font-family:inherit',
          'type': 'button',
          'aria-haspopup': 'dialog',
        },
        events: {'click': (_) => onOpenMore()},
        [
          kolaIcon(Icons.more, size: 18),
          span(
            attributes: {'style': 'font-size:10.5px;font-weight:600'},
            [Component.text('More')],
          ),
        ],
      );

  String _tabStyle(bool active) =>
      'flex:1;display:flex;flex-direction:column;align-items:center;'
      'justify-content:center;gap:3px;text-decoration:none;padding:2px 4px;'
      'color:${active ? KolaVar.accent : KolaVar.muted}';
}

// ── "More" sheet ──────────────────────────────────────────────────────

class MobileMoreSheet extends StatelessComponent {
  const MobileMoreSheet({
    required this.gate,
    required this.currentRoute,
    required this.onClose,
  });

  final FeatureGate gate;
  final String currentRoute;
  final void Function() onClose;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'position:fixed;inset:0;z-index:200;'
            'background:rgba(0,0,0,0.55);display:flex;align-items:flex-end',
        'role': 'dialog',
        'aria-modal': 'true',
        'aria-label': 'All pages',
      },
      events: {'click': (_) => onClose()},
      [
        div(
          attributes: {
            'style': 'width:100%;background:${KolaVar.card};'
                'border-top-left-radius:${KolaRadius.xl};'
                'border-top-right-radius:${KolaRadius.xl};'
                'border-top:1px solid ${KolaVar.border};'
                'padding:10px 10px calc(20px + env(safe-area-inset-bottom, 0px));'
                'max-height:80vh;overflow-y:auto',
          },
          // Stops a tap inside the sheet from reaching the backdrop and
          // closing it. Without this, tapping a nav row closes the sheet
          // AND navigates, which is fine — but tapping the padding
          // between rows would close it too, which feels broken.
          events: {'click': (e) => e.stopPropagation()},
          [
            div(
              attributes: {
                'style': 'width:36px;height:4px;background:${KolaVar.border};'
                    'border-radius:${KolaRadius.pill};margin:2px auto 12px',
              },
              [],
            ),
            for (final group in navGroups) ..._group(group),
            _signOutRow(),
          ],
        ),
      ],
    );
  }

  List<Component> _group(NavGroup group) {
    final items = group.visibleItems(gate);
    if (items.isEmpty) return const [];

    return [
      div(
        attributes: {
          'style': 'padding:10px 14px 4px;font-size:${KolaType.small};'
              'letter-spacing:0.06em;text-transform:uppercase;'
              'font-weight:700;color:${KolaVar.muted}',
        },
        [Component.text(group.label)],
      ),
      // Each row closes the sheet on its way out.
      //
      // The sheet body stops click propagation so that tapping the
      // padding between rows does not dismiss it. That same guard means
      // a tap on a row never reaches the backdrop either — so without
      // this wrapper the app would navigate and leave the sheet sitting
      // open over the page it just opened.
      for (final item in items)
        div(
          events: {'click': (_) => onClose()},
          [
            Link(
              to: item.route,
              attributes: {
                'class': 'kola-nav-row kola-tab',
                'style': 'display:flex;align-items:center;gap:12px;'
                    'padding:11px 14px;border-radius:${KolaRadius.sm};'
                    'font-size:${KolaType.ui};text-decoration:none;'
                    'color:${_isActive(item.route) ? KolaVar.accent : KolaVar.text}',
              },
              children: [
                kolaIcon(item.icon, size: 17, extraStyle: 'flex:none'),
                span(attributes: {'style': 'flex:1'}, [Component.text(item.label)]),
                if (item.badge != null)
                  span(
                    attributes: {
                      'style': 'font-size:9.5px;font-weight:700;'
                          'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                          'border-radius:${KolaRadius.pill};padding:2px 7px',
                    },
                    [Component.text(item.badge!)],
                  ),
              ],
            ),
          ],
        ),
    ];
  }

  /// Sign out, on mobile.
  ///
  /// This sheet is built entirely from `navGroups`, which describes the
  /// PRODUCT's pages — so it had no sign-out row, and the mobile layout
  /// hides the desktop sidebar that carries the profile menu. Between
  /// them there was no way to log out on a phone at all. The desktop
  /// entry was separately broken (it linked at an unregistered /logout);
  /// now that /logout is a real route, the same link works here.
  ///
  /// Separated from the nav groups by a rule and rendered last, because
  /// it is not a page you visit — it is an action that ends the session,
  /// and it should not read as one more destination in the list.
  Component _signOutRow() => div(
        attributes: {
          'style': 'border-top:1px solid ${KolaVar.border};'
              'margin-top:10px;padding-top:8px',
        },
        [
          div(
            events: {'click': (_) => onClose()},
            [
              Link(
                to: '/logout',
                attributes: {
                  'class': 'kola-nav-row kola-tab',
                  'style': 'display:flex;align-items:center;gap:12px;'
                      'padding:11px 14px;border-radius:${KolaRadius.sm};'
                      'font-size:${KolaType.ui};text-decoration:none;'
                      'color:${KolaVar.danger}',
                },
                children: [
                  kolaIcon(Icons.logOut, size: 17, extraStyle: 'flex:none'),
                  span(
                    attributes: {'style': 'flex:1'},
                    [Component.text('Log out')],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

  bool _isActive(String route) =>
      currentRoute == route || currentRoute.startsWith('$route/');
}
