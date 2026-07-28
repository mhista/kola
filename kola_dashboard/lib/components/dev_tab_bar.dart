// dev_tab_bar.dart — Structured Mode's Overview/Errands/Knowledge/
// Channels/Logs/API tab row, matching Kola Bot Detail Dev.dc.html's
// tabs exactly. This is real interactive UI state (unlike most of this
// shell pass) — [currentTab]/[onTabChange] are owned by
// BotDetailDevPage, which is a StatefulComponent for exactly this
// reason: tab switching and errand-row selection are genuine
// client-side UI state, not mock data standing in for a backend call.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../theme.dart';

class DevTabBar extends StatelessComponent {
  const DevTabBar({required this.currentTab, required this.onTabChange});

  final String currentTab;
  final void Function(String tab) onTabChange;

  static const _tabs = ['Overview', 'Errands', 'Knowledge', 'Channels', 'Logs', 'API'];

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'display:flex;gap:28px;padding:0 24px;border-bottom:1px solid ${KolaDashboardColors.border}',
      },
      [for (final tab in _tabs) _tabItem(tab)],
    );
  }

  Component _tabItem(String tab) {
    final key = tab.toLowerCase();
    final active = key == currentTab;
    return div(
      attributes: {
        'style':
            'padding:16px 0;font-size:14.5px;font-weight:600;cursor:pointer;'
            'color:${active ? KolaDashboardColors.text : KolaDashboardColors.mutedSecondary};'
            'border-bottom:2px solid ${active ? KolaDashboardColors.accent : "transparent"}',
      },
      events: {'click': (_) => onTabChange(key)},
      [Component.text(tab)],
    );
  }
}
