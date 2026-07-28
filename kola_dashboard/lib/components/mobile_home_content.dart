// mobile_home_content.dart — mobile content column: greeting, composer
// (compact), quick-actions list. Sits between MobileTopBar and
// BottomTabBar inside the .kola-dash-mobile wrapper (see app.dart).

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';
import '../theme.dart';
import '../models/quick_action.dart';
import 'composer.dart';
import 'quick_actions_list.dart';

class MobileHomeContent extends StatelessComponent {
  const MobileHomeContent({
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
    return div(
      attributes: {
        'style':
            'flex:1;min-height:0;overflow-y:auto;padding:20px;'
            'display:flex;flex-direction:column;align-items:center',
      },
      [
        div(
          attributes: {
            'style':
                'font-family:${KolaDashboardFonts.display};font-size:23px;font-weight:600;'
                'margin:14px 0 18px;align-self:flex-start',
          },
          [Component.text('Evening, $greetingName')],
        ),
        Composer(client: client, accessToken: accessToken, workspaceId: workspaceId, compact: true),
        QuickActionsList(actions: quickActions),
      ],
    );
  }
}
