// mobile_top_bar.dart — mobile-only header: logo + avatar circle.
// Matches Kola Dashboard Shell.dc.html's mobile top row exactly.
//
// [onSignOut] (added Phase 4e) — the design file has no sign-out
// affordance anywhere, but a real Supabase session now exists with no
// way to end it from the UI at all, which is a real gap, not a design
// nicety to skip. Rendered as a small text link next to the avatar
// rather than inventing new iconography for a one-off action.
//
// WORKSPACE SWITCHER (task #131 / Phase 8d) — same reasoning as
// sidebar_nav.dart's own header: the design file also has no concept of
// multiple workspaces (mobile shows no workspace name at all today), but
// an agency/reseller account with 2+ workspaces has no way to switch on
// mobile otherwise, which is the same "real gap, not nicety to skip"
// category as onSignOut above. Rendered only when [workspaces] has 2+
// entries — the common (0 or 1 workspace) case keeps today's exact
// logo+avatar layout, unchanged.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';
import '../theme.dart';

class MobileTopBar extends StatelessComponent {
  const MobileTopBar({
    required this.avatarInitial,
    required this.onSignOut,
    required this.workspaces,
    required this.selectedWorkspaceId,
    required this.onWorkspaceSwitch,
  });

  final String avatarInitial;
  final void Function() onSignOut;

  /// Every workspace the signed-in user belongs to — see file header.
  final List<Workspace> workspaces;
  final int? selectedWorkspaceId;
  final void Function(Workspace) onWorkspaceSwitch;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'display:flex;align-items:center;justify-content:space-between;padding:18px 20px 8px',
      },
      [
        span(
          attributes: {
            'style': 'font-family:${KolaDashboardFonts.display};font-size:19px;font-weight:700',
          },
          [Component.text('kolaa')],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            if (workspaces.length > 1)
              select(
                [
                  for (final ws in workspaces)
                    option(
                      [Component.text(ws.name)],
                      value: ws.id.toString(),
                      selected: ws.id == selectedWorkspaceId,
                    ),
                ],
                value: selectedWorkspaceId?.toString(),
                onChange: (values) {
                  final pickedId = int.tryParse(values.first);
                  for (final ws in workspaces) {
                    if (ws.id == pickedId) {
                      onWorkspaceSwitch(ws);
                      break;
                    }
                  }
                },
                attributes: {
                  'style':
                      'font-size:12.5px;font-weight:600;background:transparent;border:none;'
                      'color:${KolaDashboardColors.text};padding:0;margin:0;cursor:pointer;'
                      'max-width:110px;appearance:none;font-family:inherit',
                },
              ),
            span(
              attributes: {
                'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};cursor:pointer',
              },
              events: {'click': (_) => onSignOut()},
              [Component.text('Sign out')],
            ),
            div(
              attributes: {
                'style':
                    'width:30px;height:30px;border-radius:50%;background:${KolaDashboardColors.avatarBg};'
                    'display:flex;align-items:center;justify-content:center;font-size:13px;'
                    'color:${KolaDashboardColors.text}',
              },
              [Component.text(avatarInitial)],
            ),
          ],
        ),
      ],
    );
  }
}
