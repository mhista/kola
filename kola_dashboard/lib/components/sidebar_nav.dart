// sidebar_nav.dart — desktop-only left sidebar: logo, "+ New Bot" CTA,
// primary nav, Recent list, workspace/account footer. Matches Kola
// Dashboard Shell.dc.html's desktop sidebar exactly on layout/copy.
//
// Visibility (desktop vs. mobile) is decided one level up, by app.dart's
// outer '.kola-dash-desktop' wrapper (a pure-CSS breakpoint — see
// web/styles.css). This component is always a flex child of that
// wrapper, never the class holder itself — it just sets its own
// 'display:flex;flex-direction:column' to lay out its own children.
//
// LINK VS. PLAIN ANCHOR (added Phase 4d): a NavItem/RecentItem whose
// href is '#' is a page that isn't built yet — rendered as a plain
// inert anchor. Anything else is a real jaspr_router route (e.g. '/'
// or '/bots/bot_8f2a1c') and gets a real Link for client-side
// navigation. See dashboard_home_page.dart's header for which hrefs
// are currently real.
//
// WORKSPACE SWITCHER (task #131 / Phase 8d): [workspaces] is the FULL
// list of workspaces the signed-in user belongs to (app.dart's own
// `_workspaces`, unused by any UI until now — see that file's header).
// When there are 2+, the static workspace-name text in the footer card
// becomes a real `<select>` instead — the agency/reseller case this was
// built for. With 0 or 1 workspace (every account today, pre-agency-tier)
// nothing changes visually: no switcher chrome for the common case,
// same "don't add UI for a scenario that doesn't apply yet" instinct as
// [recentEmptyLabel] being nullable below.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';
import '../theme.dart';
import '../models/nav_item.dart';
import '../models/recent_item.dart';

class SidebarNav extends StatelessComponent {
  const SidebarNav({
    required this.navItems,
    required this.recentItems,
    required this.workspaceName,
    required this.workspacePlan,
    required this.avatarInitial,
    required this.onSignOut,
    required this.workspaces,
    required this.selectedWorkspaceId,
    required this.onWorkspaceSwitch,
    this.recentEmptyLabel,
  });

  final List<NavItem> navItems;
  final List<RecentItem> recentItems;
  final String workspaceName;
  final String workspacePlan;
  final String avatarInitial;

  /// Every workspace the signed-in user belongs to — see file header.
  final List<Workspace> workspaces;

  /// Which of [workspaces] is currently selected — used only to mark
  /// the right `<option>` as `selected` when the switcher renders.
  final int? selectedWorkspaceId;

  /// Called with the newly-picked Workspace the moment the `<select>`
  /// changes — app.dart's `_handleWorkspaceSwitch` is the one real
  /// implementation today.
  final void Function(Workspace) onWorkspaceSwitch;

  /// Shown in place of the Recent list when [recentItems] is empty —
  /// e.g. "No bots yet" for a brand-new workspace, or "Loading bots…"
  /// while DashboardHomePage's first fetch is still in flight. Null
  /// means "render nothing" (kola_dashboard's other callers of this
  /// component, if any ever pass a genuinely-always-populated list,
  /// don't need to supply this).
  final String? recentEmptyLabel;

  // Added Phase 4e — the design file's workspace/account footer has no
  // sign-out affordance (it predates real auth existing at all), but
  // now that a real Supabase session exists, there needs to be a real
  // way to end it. Rendered as a plain text link inside the existing
  // footer card rather than redesigning it.
  final void Function() onSignOut;

  static const _kolaDropSvg =
      '<svg width="22" height="22" viewBox="0 0 26 26" fill="none">'
      '<path d="M13 2C13 2 6 8.5 6 15.5C6 20 9 24 13 24C17 24 20 20 20 15.5C20 8.5 13 2 13 2Z" fill="#C1552E"/>'
      '</svg>';

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            'display:flex;width:272px;flex-shrink:0;border-right:1px solid ${KolaDashboardColors.border};'
            'padding:20px 16px;flex-direction:column;height:100vh;overflow-y:auto;position:sticky;top:0;'
            'box-sizing:border-box',
      },
      [
        // ── Logo ──────────────────────────────────────────────────────
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:9px;padding:6px 8px 22px'},
          [
            RawText(_kolaDropSvg),
            span(
              attributes: {
                'style': 'font-family:${KolaDashboardFonts.display};font-size:19px;font-weight:700',
              },
              [Component.text('kolaa')],
            ),
          ],
        ),

        // ── + New Bot ─────────────────────────────────────────────────
        // Real route since task #114 — CreateBotPage. Was a plain
        // inert `href:'#'` anchor before; a real Link now, same as
        // every other built route (see this file's header note on the
        // '#' vs. real-Link convention).
        Link(
          to: '/bots/new',
          attributes: {
            'style':
                'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                'border:none;border-radius:11px;padding:12px;font-size:14.5px;font-weight:600;'
                'margin-bottom:20px;text-align:center;display:block;text-decoration:none',
          },
          child: Component.text('+ New Bot'),
        ),

        // ── Primary nav ───────────────────────────────────────────────
        for (final item in navItems)
          _link(
            href: item.href,
            style:
                'display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:10px;'
                'font-size:14.5px;text-decoration:none;'
                'background:${item.active ? KolaDashboardColors.navActiveBg : "transparent"};'
                'color:${item.active ? KolaDashboardColors.accent : KolaDashboardColors.navInactiveText}',
            children: [
              span(attributes: {'style': 'font-size:16px'}, [Component.text(item.icon)]),
              Component.text(item.label),
            ],
          ),

        // ── Recent ────────────────────────────────────────────────────
        div(
          attributes: {
            'style':
                'margin-top:26px;font-size:12px;letter-spacing:0.05em;text-transform:uppercase;'
                'color:${KolaDashboardColors.muted};padding:0 12px 10px',
          },
          [Component.text('Recent')],
        ),
        if (recentItems.isEmpty && recentEmptyLabel != null)
          div(
            attributes: {
              'style': 'padding:8px 12px;font-size:13px;color:${KolaDashboardColors.muted}',
            },
            [Component.text(recentEmptyLabel!)],
          ),
        for (final item in recentItems)
          _link(
            href: item.href,
            style:
                'display:flex;align-items:center;gap:10px;padding:8px 12px;border-radius:9px;'
                'font-size:13.5px;color:${KolaDashboardColors.mutedStrong};text-decoration:none',
            children: [
              span(attributes: {'style': 'font-size:13px'}, [Component.text(item.icon)]),
              Component.text(item.label),
            ],
          ),

        div(attributes: {'style': 'flex:1'}, []),

        // ── Workspace / account footer ────────────────────────────────
        div(
          attributes: {
            'style':
                'display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:10px;'
                'border:1px solid ${KolaDashboardColors.border};margin-top:12px',
          },
          [
            div(
              attributes: {
                'style':
                    'width:30px;height:30px;border-radius:50%;background:${KolaDashboardColors.avatarBg};'
                    'display:flex;align-items:center;justify-content:center;font-size:13px;color:${KolaDashboardColors.text}',
              },
              [Component.text(avatarInitial)],
            ),
            div(
              attributes: {'style': 'flex:1;min-width:0'},
              [
                if (workspaces.length > 1)
                  _workspaceSwitcher()
                else
                  div(
                    attributes: {'style': 'font-size:13.5px;font-weight:600'},
                    [Component.text(workspaceName)],
                  ),
                div(
                  attributes: {'style': 'font-size:11.5px;color:${KolaDashboardColors.muted}'},
                  [Component.text(workspacePlan)],
                ),
              ],
            ),
            span(
              attributes: {
                'style':
                    'font-size:11.5px;color:${KolaDashboardColors.muted};cursor:pointer;flex-shrink:0',
              },
              events: {'click': (_) => onSignOut()},
              [Component.text('Sign out')],
            ),
          ],
        ),
      ],
    );
  }

  /// A native `<select>` of every workspace the user belongs to — see
  /// this file's header. `value` on each `<option>` is the workspace's
  /// own id (stringified, since Jaspr's onChange hands back Strings),
  /// looked back up in [workspaces] on change rather than relying on
  /// index — safe against the list's order ever differing from render
  /// order for any reason.
  Component _workspaceSwitcher() {
    return select(
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
            'font-size:13.5px;font-weight:600;background:transparent;border:none;'
            'color:${KolaDashboardColors.text};padding:0;margin:0;cursor:pointer;'
            'width:100%;appearance:none;font-family:inherit',
      },
    );
  }

  /// '#' means "not built yet" — a plain inert anchor. An `http(s)://`
  /// href (task #138 — the Docs nav item) is a real page but NOT one
  /// jaspr_router owns, so it gets a plain anchor too — with
  /// target="_blank" so leaving the dashboard for docs doesn't lose the
  /// user's place — rather than jaspr_router's `Link`, which is for
  /// internal SPA routes only and would try to client-side-navigate an
  /// external URL. Anything else is a real internal route and gets a
  /// real Link. See this file's header comment.
  Component _link({required String href, required String style, required List<Component> children}) {
    if (href == '#') {
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
    if (href.startsWith('http://') || href.startsWith('https://')) {
      return a(
        attributes: {'style': style, 'target': '_blank', 'rel': 'noopener'},
        children,
        href: href,
      );
    }
    return Link(to: href, attributes: {'style': style}, children: children);
  }
}
