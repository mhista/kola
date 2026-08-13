// bottom_tab_bar.dart — mobile-only 3-tab bar (Home / Chats / Settings).
// Fixed navigation chrome (not data pulled from a backend list like
// NavItem/RecentItem), so the three tabs are defined inline as Dart
// records rather than warranting their own model file. Only "Home" is
// a real link right now (a real jaspr_router Link to '/', added in
// Phase 4d once the router existed) — Chats/Settings are '#'
// placeholders, same convention as NavItem's header comment.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';

class BottomTabBar extends StatelessComponent {
  const BottomTabBar();

  static const _tabs = [
    (icon: '🏠', label: 'Home', href: '/', active: true),
    (icon: '💬', label: 'Chats', href: '#', active: false),
    (icon: '⚙️', label: 'Settings', href: '#', active: false),
  ];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'display:flex;border-top:1px solid ${KolaDashboardColors.border};padding:10px 0 22px',
      },
      [for (final tab in _tabs) _tabLink(tab)],
    );
  }

  Component _tabLink(({String icon, String label, String href, bool active}) tab) {
    final style =
        'flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;'
        'text-decoration:none;'
        'color:${tab.active ? KolaDashboardColors.accent : KolaDashboardColors.muted}';
    final children = [
      span(attributes: {'style': 'font-size:19px'}, [Component.text(tab.icon)]),
      span(attributes: {'style': 'font-size:11px;font-weight:600'}, [Component.text(tab.label)]),
    ];

    if (tab.href == '#') {
      // NOT an <a href="#">. A '#' anchor still navigates: it appends
      // the fragment to the URL and pushes a HISTORY ENTRY, so Back walks
      // back through phantom entries instead of leaving the page. That is
      // the reported "back button doesn't go back properly".
      //
      // A span carries no href, so it cannot navigate and cannot pollute
      // history. aria-disabled tells assistive tech it is inert.
      return span(
        attributes: {'style': '$style;cursor:default',
            'aria-disabled': 'true'},
        children,
      );
    }
    return Link(to: tab.href, attributes: {'style': style}, children: children);
  }
}
