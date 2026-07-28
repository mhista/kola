// home_content.dart — desktop main content pane: greeting, composer,
// quick-actions grid. Sits next to SidebarNav inside the
// .kola-dash-desktop wrapper (see app.dart). Mobile has its own
// mobile_home_content.dart since the design's mobile content column
// has different padding/greeting size and swaps the grid for a list.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';
import '../theme.dart';
import '../models/quick_action.dart';
import 'composer.dart';
import 'quick_actions_grid.dart';

class HomeContent extends StatelessComponent {
  const HomeContent({
    required this.greetingName,
    required this.quickActions,
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final String greetingName;
  final List<QuickAction> quickActions;
  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  Component build(BuildContext context) {
    // task #139 — the owner asked for this pane to never need scrolling:
    // 80px top/bottom padding plus a 34px greeting overflowed a typical
    // laptop viewport once the (now 5-action) grid sat below the
    // composer. Trimmed padding/greeting/grid sizing (quick_actions_
    // grid.dart's own card padding/icon size came down too) so the pane
    // fits at common viewport heights instead of relying on
    // overflow-y:auto as a silent fallback.
    return div(
      attributes: {
        'style':
            'flex:1;min-height:0;overflow-y:auto;padding:36px 40px;'
            'display:flex;flex-direction:column;align-items:center;justify-content:center',
      },
      [
        div(
          attributes: {
            'style':
                'font-family:${KolaDashboardFonts.display};font-size:28px;font-weight:600;'
                'margin-bottom:18px;white-space:nowrap',
          },
          [Component.text('Evening, $greetingName')],
        ),
        Composer(client: client, accessToken: accessToken, workspaceId: workspaceId),
        QuickActionsGrid(actions: quickActions),
      ],
    );
  }
}
