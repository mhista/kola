// sidebar.dart — the desktop navigation rail (248px, >=1024px only).
//
// Rendered by AppShell inside a `.kola-shell-desktop` wrapper, so it is
// display:none below the breakpoint rather than conditionally built.
// That is deliberate: building it conditionally would need a width
// listener and a rebuild on resize, and would flash the wrong chrome on
// first paint before the listener fired.
//
// ── ACTIVE STATE IS PASSED IN, NOT LOOKED UP ─────────────────────────
//
// [currentRoute] comes from whoever renders the shell. The alternative —
// reaching into jaspr_router from inside this component — would couple
// the sidebar to the router's internals and make it impossible to render
// in isolation. This way the highlight is a pure function of an argument.
//
// ── EVERY DESTINATION IS A REAL ROUTE ────────────────────────────────
//
// There is no '#' anywhere in this file. The previous sidebar used '#'
// for pages that did not exist, so the nav advertised destinations that
// did nothing when clicked. Feature gating replaces that: an item whose
// page is not built has its feature locked, so it is not drawn at all.
// See nav_model.dart.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../nav/nav_model.dart';
import '../../services/feature_gate.dart';
import '../../theme.dart';
import 'icons.dart';
import 'kola_icon.dart';

class Sidebar extends StatelessComponent {
  const Sidebar({
    required this.gate,
    required this.currentRoute,
    required this.workspaceName,
    required this.workspaceSubtitle,
    required this.onOpenPalette,
    required this.profileMenuOpen,
    required this.onToggleProfileMenu,
  });

  final FeatureGate gate;
  final String currentRoute;
  final String workspaceName;

  /// The line under the workspace name — plan, or role. Kept as free
  /// text rather than a Plan enum because the shell should not need to
  /// know how billing names its tiers.
  final String workspaceSubtitle;

  final void Function() onOpenPalette;
  final bool profileMenuOpen;
  final void Function() onToggleProfileMenu;

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        // height:100% and NOT 100vh. The sidebar sits inside AppShell's
        // flex row, which is already the exact height of the viewport
        // minus nothing. 100vh here would ignore that and overflow by
        // however tall any future chrome above it is — the kind of bug
        // that only shows up once something is added.
        'style': 'width:248px;flex-shrink:0;border-right:1px solid ${KolaVar.border};'
            'height:100%;display:flex;flex-direction:column;'
            'padding:16px 10px 12px;gap:2px;overflow-y:auto;'
            'background:${KolaVar.bg}',
      },
      [
        _brand(),
        _searchButton(),
        for (final item in navPrimary)
          if (item.isVisibleTo(gate)) _navRow(item),
        for (final group in navGroups) ..._group(group),

        // Pushes the profile block to the bottom. A spacer rather than
        // margin-top:auto on the profile block itself, because the
        // profile block is wrapped in a positioning container for its
        // popover and `auto` margins interact badly with that.
        div(attributes: {'style': 'flex:1;min-height:12px'}, []),

        _profileBlock(),
      ],
    );
  }

  // ── Brand ───────────────────────────────────────────────────────────

  Component _brand() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:9px;'
              'padding:6px 8px 12px',
        },
        [
          kolaMark(size: 20),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.display};font-size:${KolaType.title};'
                  'font-weight:700;color:${KolaVar.text};letter-spacing:-0.01em',
            },
            [Component.text('kolaa')],
          ),
        ],
      );

  // ── Search / command palette trigger ────────────────────────────────

  Component _searchButton() => button(
        attributes: {
          'class': 'kola-pressable',
          'style': 'display:flex;align-items:center;gap:8px;width:100%;'
              'background:${KolaVar.pill};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.sm};padding:8px 10px;margin-bottom:10px;'
              'color:${KolaVar.muted};font-family:inherit;'
              'font-size:${KolaType.small};text-align:left',
          'type': 'button',
          'aria-label': 'Search or jump to a page',
        },
        events: {'click': (_) => onOpenPalette()},
        [
          kolaIcon(Icons.search, size: 15, extraStyle: 'flex:none'),
          span(attributes: {'style': 'flex:1'}, [Component.text('Search or jump to…')]),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};font-size:${KolaType.micro};'
                  'color:${KolaVar.muted}',
            },
            // Not platform-detected. A Mac user reads ⌘K correctly and a
            // Windows user reads it as "the shortcut key", which is
            // enough — detecting the platform to swap in Ctrl costs a
            // user-agent sniff for a label almost nobody reads twice.
            [Component.text('⌘K')],
          ),
        ],
      );

  // ── Groups ──────────────────────────────────────────────────────────

  List<Component> _group(NavGroup group) {
    final items = group.visibleItems(gate);

    // No heading over nothing. On a launch-scope workspace most groups
    // are empty, and a column of bare category labels reads as a
    // rendering failure rather than as a product staged in phases.
    if (items.isEmpty) return const [];

    return [
      div(
        attributes: {
          'style': 'padding:12px 12px 4px;font-size:${KolaType.micro};'
              'letter-spacing:0.08em;text-transform:uppercase;'
              'font-weight:700;color:${KolaVar.muted}',
        },
        [Component.text(group.label)],
      ),
      for (final item in items) _navRow(item),
    ];
  }

  // ── One navigation row ──────────────────────────────────────────────

  Component _navRow(NavItem item) {
    final active = _isActive(item.route);

    final style = 'display:flex;align-items:center;gap:12px;'
        'padding:8px 12px;border-radius:${KolaRadius.sm};'
        'font-size:${KolaType.body};font-weight:${active ? 600 : 500};'
        'text-decoration:none;'
        'background:${active ? KolaVar.tintSurface(0) : 'transparent'};'
        'color:${active ? KolaVar.accent : KolaVar.mutedStrong}'
        '${item.comingSoon ? ';opacity:0.5;pointer-events:none' : ''}';

    final children = <Component>[
      kolaIcon(item.icon, size: 17, extraStyle: 'flex:none'),
      span(attributes: {'style': 'flex:1'}, [Component.text(item.label)]),
      if (item.badge != null)
        span(
          attributes: {
            'style': 'font-size:9.5px;font-weight:700;letter-spacing:0.04em;'
                'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                'border-radius:${KolaRadius.pill};padding:2px 7px',
          },
          [Component.text(item.badge!)],
        ),
      if (item.comingSoon)
        span(
          attributes: {
            'style': 'font-size:9.5px;font-weight:600;color:${KolaVar.muted}',
          },
          [Component.text('SOON')],
        ),
    ];

    // A coming-soon row is not a link. Rendering it as one that goes
    // nowhere is the '#' problem again — it looks clickable, so people
    // click it, and nothing happens.
    if (item.comingSoon) {
      return div(
        attributes: {'class': 'kola-nav-row', 'style': style},
        children,
      );
    }

    return Link(
      to: item.route,
      attributes: {
        'class': 'kola-nav-row',
        'style': style,
        if (active) 'aria-current': 'page',
      },
      children: children,
    );
  }

  /// Exact match for the root, prefix match for everything else.
  ///
  /// Without the special case, '/' is a prefix of every route and the
  /// Overview row would highlight on every page. With it, '/bots/42'
  /// correctly highlights 'Agents' — which is the behaviour a detail
  /// page needs, since it has no nav row of its own.
  bool _isActive(String route) {
    if (route == '/') return currentRoute == '/';
    return currentRoute == route || currentRoute.startsWith('$route/');
  }

  // ── Workspace / profile ─────────────────────────────────────────────

  Component _profileBlock() => div(
        attributes: {
          'style': 'position:relative',
          // Marks the trigger AND the menu as one region, so AppShell's
          // outside-click listener can ask "did this land inside?" with
          // a single closest() call. Without it the listener would close
          // the menu on the very click that opened it — the button is
          // inside the document too.
          'data-kola-overlay': 'profile',
        },
        [
          if (profileMenuOpen) _profileMenu(),
          button(
            attributes: {
              'class': 'kola-pressable',
              'style': 'display:flex;align-items:center;gap:10px;width:100%;'
                  'padding:9px 10px;border-radius:${KolaRadius.md};'
                  'background:transparent;border:1px solid ${KolaVar.border};'
                  'font-family:inherit;text-align:left',
              'type': 'button',
              'aria-haspopup': 'menu',
              'aria-expanded': profileMenuOpen ? 'true' : 'false',
            },
            events: {'click': (_) => onToggleProfileMenu()},
            [
              div(
                attributes: {
                  'style': 'width:28px;height:28px;border-radius:${KolaRadius.circle};'
                      'background:${KolaVar.tintIcon(0)};color:${KolaVar.accent};'
                      'display:flex;align-items:center;justify-content:center;'
                      'font-size:${KolaType.tiny};font-weight:700;flex:none',
                },
                [Component.text(_initial(workspaceName))],
              ),
              div(
                attributes: {'style': 'flex:1;min-width:0'},
                [
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.body};font-weight:600;'
                          'color:${KolaVar.text};overflow:hidden;'
                          'text-overflow:ellipsis;white-space:nowrap',
                    },
                    [Component.text(workspaceName)],
                  ),
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                          'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
                    },
                    [Component.text(workspaceSubtitle)],
                  ),
                ],
              ),
              div(
                attributes: {'style': 'color:${KolaVar.muted};flex:none;display:flex'},
                [kolaIcon(Icons.chevronDown, size: 15)],
              ),
            ],
          ),
        ],
      );

  Component _profileMenu() => div(
        attributes: {
          'role': 'menu',
          'style': 'position:absolute;bottom:calc(100% + 8px);left:0;right:0;'
              'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:6px;'
              'box-shadow:0 16px 40px rgba(0,0,0,0.35);z-index:20',
        },
        [
          for (final entry in profileEntries)
            Link(
              to: entry.route,
              attributes: {
                'class': 'kola-nav-row',
                'role': 'menuitem',
                'style': 'display:flex;align-items:center;gap:10px;'
                    'padding:9px 10px;border-radius:${KolaRadius.sm};'
                    'font-size:${KolaType.small};text-decoration:none;'
                    'color:${entry.danger ? KolaVar.danger : KolaVar.text}',
              },
              children: [
                kolaIcon(entry.icon, size: 15, extraStyle: 'flex:none'),
                Component.text(entry.label),
              ],
            ),
        ],
      );

  /// First letter of the workspace name, for the avatar.
  ///
  /// Guards the empty string: `''[0]` throws, and a workspace can be
  /// mid-rename or freshly created with a blank name for a moment.
  static String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  // profileEntries moved to nav_model.dart — see its own header on why:
  // the mobile top bar needs the exact same list, and this codebase's
  // rule is one definition shared across surfaces, not a private copy
  // per surface.
}
