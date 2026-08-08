// app_shell.dart — the frame every dashboard page renders inside.
//
// ── THE PAGE IS BUILT ONCE ───────────────────────────────────────────
//
// The obvious way to do a responsive shell is two complete layouts, one
// hidden by CSS. The design export does exactly that, and it is right
// for a design tool. It is wrong here: it would build every page twice,
// double every network call a page makes on mount, and put two elements
// with the same id in the document.
//
// So the structure is one column, and only the CHROME is duplicated:
//
//     ┌ top bar ──────────────┐  .kola-shell-mobile   (<1024px)
//     ├ sidebar │ page ───────┤  sidebar is .kola-shell-desktop
//     └ tab bar ──────────────┘  .kola-shell-mobile
//
// [child] appears exactly once, in the middle row, at every width.
//
// ── CSS DECIDES THE LAYOUT, NOT DART ─────────────────────────────────
//
// There is no width state and no resize listener. A listener cannot run
// before first paint, so the first frame would show the wrong chrome
// and then snap — visible on every page load, worst on the slow devices
// this is built for. A media query is correct from the first pixel.
//
// This is also why the design's Desktop/Mobile toggle buttons are not
// carried over. They are a preview control for a design tool. The real
// equivalent is resizing the window.
//
// ── OVERLAY STATE LIVES HERE ─────────────────────────────────────────
//
// Palette, More sheet and profile menu are shell concerns, not page
// concerns, so their state lives here and no page has to know they
// exist. They also must not stack: opening one closes the others, since
// two overlapping modals leave no clear way back.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import '../../services/feature_gate.dart';
import '../../theme.dart';
import 'command_palette.dart';
import 'mobile_chrome.dart';
import 'sidebar.dart';

class AppShell extends StatefulComponent {
  const AppShell({
    required this.gate,
    required this.currentRoute,
    required this.workspaceName,
    required this.workspaceSubtitle,
    required this.child,
  });

  final FeatureGate gate;
  final String currentRoute;
  final String workspaceName;
  final String workspaceSubtitle;

  /// The page. Rendered once, in the content region.
  final Component child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _paletteOpen = false;
  bool _moreOpen = false;
  bool _profileOpen = false;

  web.EventListener? _keyListener;

  @override
  void initState() {
    super.initState();

    // ⌘K / Ctrl-K opens the palette from anywhere, and Escape closes
    // whatever is open. Bound on the document rather than on a
    // component, because the shortcut has to work while focus is inside
    // a page's own input — which is most of the time.
    _keyListener = (web.Event event) {
      final e = event as web.KeyboardEvent;

      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() == 'k') {
        // Chrome binds Ctrl-K to the address bar. Without this the
        // shortcut appears not to work at all in the browser most of
        // this product's users are on.
        e.preventDefault();
        _openOnly(palette: true);
        return;
      }

      if (e.key == 'Escape') _closeAll();
    }.toJS;

    web.document.addEventListener('keydown', _keyListener);
  }

  @override
  void dispose() {
    if (_keyListener != null) {
      web.document.removeEventListener('keydown', _keyListener);
    }
    super.dispose();
  }

  /// Opens one overlay and closes the rest.
  ///
  /// Overlays must never stack. Two modals over each other leave no
  /// obvious way back — Escape closes one and the user cannot tell
  /// which, and the backdrop of the upper one swallows taps meant for
  /// the lower.
  void _openOnly({bool palette = false, bool more = false, bool profile = false}) {
    setState(() {
      _paletteOpen = palette;
      _moreOpen = more;
      _profileOpen = profile;
    });
  }

  void _closeAll() => _openOnly();

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'height:100vh;display:flex;flex-direction:column;'
            'background:${KolaVar.bg};color:${KolaVar.text};overflow:hidden',
      },
      [
        // ── Mobile top bar ───────────────────────────────────────────
        div(
          classes: 'kola-shell-mobile',
          attributes: {'style': 'flex-direction:column'},
          [
            MobileTopBar(
              workspaceName: component.workspaceName,
              onOpenPalette: () => _openOnly(palette: true),
              onOpenProfile: () => _openOnly(more: true),
            ),
          ],
        ),

        // ── Sidebar + page ───────────────────────────────────────────
        // min-height:0 is load-bearing. A flex child defaults to
        // min-height:auto, which refuses to shrink below its content —
        // so without this the row grows past the viewport and the page
        // scrolls the document instead of its own region, defeating the
        // viewport-locked shell entirely.
        div(
          attributes: {'style': 'flex:1;display:flex;min-height:0'},
          [
            div(
              classes: 'kola-shell-desktop',
              attributes: {'style': 'flex:none'},
              [
                Sidebar(
                  gate: component.gate,
                  currentRoute: component.currentRoute,
                  workspaceName: component.workspaceName,
                  workspaceSubtitle: component.workspaceSubtitle,
                  onOpenPalette: () => _openOnly(palette: true),
                  profileMenuOpen: _profileOpen,
                  onToggleProfileMenu: () =>
                      _profileOpen ? _closeAll() : _openOnly(profile: true),
                ),
              ],
            ),
            // role="main" rather than a <main> element. Identical to a
            // screen reader, and it uses only element helpers this
            // codebase already compiles — jaspr's name for <main> is
            // not something to guess at in the one component every page
            // depends on.
            div(
              attributes: {
                'role': 'main',
                'style': 'flex:1;min-width:0;overflow-y:auto;'
                    '-webkit-overflow-scrolling:touch',
              },
              [
                if (component.gate.loadFailed) _featureLoadWarning(),
                component.child,
              ],
            ),
          ],
        ),

        // ── Mobile tab bar ───────────────────────────────────────────
        div(
          classes: 'kola-shell-mobile',
          attributes: {'style': 'flex-direction:column'},
          [
            MobileTabBar(
              gate: component.gate,
              currentRoute: component.currentRoute,
              onOpenMore: () => _openOnly(more: true),
            ),
          ],
        ),

        // ── Overlays ─────────────────────────────────────────────────
        if (_paletteOpen)
          CommandPalette(gate: component.gate, onClose: _closeAll),
        if (_moreOpen)
          MobileMoreSheet(
            gate: component.gate,
            currentRoute: component.currentRoute,
            onClose: _closeAll,
          ),
      ],
    );
  }

  /// Shown when the enabled-feature set could not be fetched.
  ///
  /// FeatureGate fails closed, so a failed load hides everything gated.
  /// Without this banner the dashboard would silently present itself as
  /// a much smaller product, and a paying customer would reasonably
  /// conclude their features had been taken away. Saying so plainly is
  /// far better than a stripped-down screen with no explanation.
  Component _featureLoadWarning() => div(
        attributes: {
          'role': 'status',
          'style': 'margin:12px 16px 0;padding:10px 14px;'
              'background:${KolaVar.warningBg};color:${KolaVar.warning};'
              'border:1px solid ${KolaVar.warning};'
              'border-radius:${KolaRadius.md};font-size:${KolaType.small}',
        },
        [
          Component.text(
            'Could not check which features are available, so some pages '
            'are hidden. This is a connection problem, not a change to '
            'your plan — reload to try again.',
          ),
        ],
      );
}
