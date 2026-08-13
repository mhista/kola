// quick_actions_list.dart — mobile single-column quick-actions list,
// matching Kola Dashboard Shell.dc.html's mobile quickActions markup:
// icon + label in a row, no sub line, no grid. See quick_actions_grid.dart
// for the desktop 2×2 variant this deliberately does NOT share a file
// with — the two layouts diverge enough (grid vs. row, sub line present
// vs. dropped) that a single flag-branching component would be messier
// than two small ones.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/quick_action.dart';

class QuickActionsList extends StatelessComponent {
  const QuickActionsList({required this.actions});

  final List<QuickAction> actions;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'width:100%;display:flex;flex-direction:column;gap:10px;margin-top:18px',
      },
      [for (final qa in actions) _row(qa)],
    );
  }

  Component _row(QuickAction qa) {
    final children = [
      div(
        attributes: {
          'style':
              'width:32px;height:32px;border-radius:9px;'
              'background:${KolaDashboardColors.quickActionIconBgs[qa.colorIndex]};'
              'display:flex;align-items:center;justify-content:center;font-size:15px;'
              'flex-shrink:0',
        },
        [Component.text(qa.icon)],
      ),
      span(
        attributes: {'style': 'font-size:14px;font-weight:600'},
        [Component.text(qa.label)],
      ),
    ];
    final style =
        'background:${KolaDashboardColors.quickActionBgs[qa.colorIndex]};'
        'border:1px solid transparent;border-radius:14px;padding:14px;'
        'display:flex;align-items:center;gap:12px;text-decoration:none;color:inherit';

    // Same '#' vs. real-route convention as sidebar_nav.dart/quick_actions_grid.dart.
    if (qa.href == '#') {
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
    return Link(to: qa.href, attributes: {'style': style}, children: children);
  }
}
