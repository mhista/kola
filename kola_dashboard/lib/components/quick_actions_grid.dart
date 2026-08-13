// quick_actions_grid.dart — desktop 2×2 quick-actions grid on the home
// page, matching Kola Dashboard Shell.dc.html's desktop quickActions
// markup exactly (icon box + label + sub line, card padding 18px).
// Mobile has its own single-column variant (quick_actions_list.dart)
// since the design drops the sub line and switches to a row layout
// there — different enough visually to warrant a separate file rather
// than one component branching on a flag.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/quick_action.dart';

class QuickActionsGrid extends StatelessComponent {
  const QuickActionsGrid({required this.actions});

  final List<QuickAction> actions;

  @override
  Component build(BuildContext context) {
    // task #139 — an odd action count (5, as of the Conversations quick
    // action) left the last card alone in its row, filling only the left
    // column and leaving an empty-looking gap next to it — the "grid
    // seems to bug" the owner flagged. Rather than pad the list with a
    // dummy filler card, the last card spans both columns whenever the
    // count is odd — a real design choice (that action reads fine full-
    // width), not a workaround.
    final lastIsOdd = actions.length.isOdd;
    return div(
      attributes: {
        'style':
            'width:100%;max-width:680px;display:grid;grid-template-columns:1fr 1fr;'
            'gap:12px;margin-top:18px',
      },
      [
        for (var i = 0; i < actions.length; i++) _card(actions[i], spanFull: lastIsOdd && i == actions.length - 1),
      ],
    );
  }

  Component _card(QuickAction qa, {required bool spanFull}) {
    final children = [
      div(
        attributes: {
          'style':
              'width:32px;height:32px;border-radius:9px;'
              'background:${KolaDashboardColors.quickActionIconBgs[qa.colorIndex]};'
              'display:flex;align-items:center;justify-content:center;font-size:15px;'
              'margin-bottom:10px',
        },
        [Component.text(qa.icon)],
      ),
      div(
        attributes: {'style': 'font-size:14px;font-weight:600'},
        [Component.text(qa.label)],
      ),
      div(
        attributes: {
          'style': 'font-size:12px;color:${KolaDashboardColors.muted};margin-top:2px',
        },
        [Component.text(qa.sub)],
      ),
    ];
    final style =
        'background:${KolaDashboardColors.quickActionBgs[qa.colorIndex]};'
        'border:1px solid transparent;border-radius:14px;padding:14px;'
        'text-decoration:none;color:inherit;display:block;box-sizing:border-box;'
        '${spanFull ? 'grid-column:1 / -1' : ''}';

    // '#' means "not built yet" — a plain inert anchor, same convention
    // as sidebar_nav.dart's _link(). Real routes ('/errands',
    // '/knowledge' as of Phase 4e) get a real jaspr_router Link for
    // client-side navigation instead of a full page reload.
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
