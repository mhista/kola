// admin_shell.dart — the sidebar + command palette chrome, lifted
// directly from the design spec's shared layout (every file under
// "Kola design system specs/kola_admin/exports/admin/*.dc.html" repeats
// this same 200px sidebar + Cmd+K palette structure). Centralized here
// rather than copy-pasted per page, same reasoning kola_dashboard's
// AppShell already established for its own sidebar.
//
// NAV_DEFS below is copied verbatim from Kola Admin Release Control's
// own script block — same 9 items, same order, same hrefs-as-labels
// shape (translated to route names here since this is Dart, not the
// mockup's static HTML export).
//
// HONESTY ABOUT WHAT'S REAL: only "Release control" is an actual route
// in this app (ADMIN_APP_SPEC.md build-order steps 4-7 — workspace
// administration, customer service, platform health, push
// notifications, support queue, admin accounts, audit log as its own
// page — are NOT built; see docs/ADMIN_CONTROL_PLANE_STATUS.md). Every
// other nav item is rendered dimmed and inert, exactly the way a real
// product shows a nav item that exists in the design but has no page
// behind it yet — clicking it surfaces an honest "not built yet" note
// via [onUnbuiltNav] rather than 404ing or silently doing nothing.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;

import '../theme.dart';

class AdminNavItem {
  const AdminNavItem(this.label, {this.route});
  final String label;
  /// Null for a nav item with no real page behind it yet.
  final String? route;
}

const List<AdminNavItem> kAdminNavItems = [
  AdminNavItem('Overview'),
  AdminNavItem('Workspaces'),
  AdminNavItem('Release control', route: '/'),
  AdminNavItem('Customer service'),
  AdminNavItem('Push notifications'),
  AdminNavItem('Platform health'),
  AdminNavItem('Support queue'),
  AdminNavItem('Audit log'),
  AdminNavItem('Admin accounts'),
];

class AdminShell extends StatefulComponent {
  const AdminShell({
    required this.activeLabel,
    required this.child,
    required this.onUnbuiltNav,
    required this.onSignOut,
    this.paletteExtras = const [],
  });

  /// Which [kAdminNavItems] label is the current page — highlighted per
  /// the spec's `active` styling.
  final String activeLabel;
  final Component child;
  final void Function(String label) onUnbuiltNav;
  final VoidCallback onSignOut;
  /// Extra searchable entries for the command palette beyond the nav
  /// list — e.g. feature keys/names on the release control page, same
  /// as the spec's own FEATURES-in-palette behavior.
  final List<AdminNavItem> paletteExtras;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _paletteOpen = false;
  String _paletteQuery = '';

  web.EventListener? _keyListener;

  @override
  void initState() {
    super.initState();
    // Same document-level Ctrl/Cmd-K + Escape binding as kola_dashboard's
    // AppShell (app_shell.dart) — bound on the document, not a component,
    // so it fires even while focus sits inside a page's own input.
    _keyListener = (web.Event event) {
      final e = event as web.KeyboardEvent;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() == 'k') {
        e.preventDefault();
        _openPalette();
        return;
      }
      if (e.key == 'Escape') _closePalette();
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

  void _openPalette() => setState(() {
        _paletteOpen = true;
        _paletteQuery = '';
      });
  void _closePalette() => setState(() => _paletteOpen = false);

  List<AdminNavItem> get _paletteItems => [...kAdminNavItems, ...component.paletteExtras];

  List<AdminNavItem> get _paletteResults {
    final q = _paletteQuery.trim().toLowerCase();
    final items = q.isEmpty
        ? _paletteItems
        : _paletteItems.where((i) => i.label.toLowerCase().contains(q)).toList();
    return items.take(8).toList();
  }

  void _handlePaletteSelect(AdminNavItem item) {
    _closePalette();
    if (item.route != null) return; // already on the only real route
    component.onUnbuiltNav(item.label);
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': "font-family:${AdminFonts.body};background:${AdminColors.bg};"
            'color:${AdminColors.text};min-height:100vh;box-sizing:border-box;font-size:13px',
      },
      [
        div(
          attributes: {'style': 'display:flex'},
          [
            _sidebar(),
            if (_paletteOpen) _palette(),
            div(
              attributes: {
                'style': 'flex:1;padding:22px 28px;box-sizing:border-box;max-width:1400px;min-width:0',
              },
              [component.child],
            ),
          ],
        ),
      ],
    );
  }

  Component _sidebar() => div(
        attributes: {
          'style': 'width:200px;flex-shrink:0;border-right:1px solid ${AdminColors.border};'
              'height:100vh;position:sticky;top:0;padding:16px 10px;box-sizing:border-box;'
              'display:flex;flex-direction:column;gap:2px',
        },
        [
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:8px;padding:6px 8px 14px'},
            [
              div(
                attributes: {
                  'style': 'width:16px;height:16px;border-radius:4px;background:${AdminColors.accent};flex:none',
                },
                [],
              ),
              span(
                [Component.text('kola_admin')],
                attributes: {
                  'style': "font-family:${AdminFonts.display};font-size:14px;font-weight:700;color:${AdminColors.heading}",
                },
              ),
            ],
          ),
          div(
            events: {'click': (_) => _openPalette()},
            attributes: {
              'style': 'display:flex;align-items:center;gap:8px;background:${AdminColors.card};'
                  'border:1px solid ${AdminColors.border};border-radius:6px;padding:7px 10px;'
                  'font-size:12px;color:${AdminColors.muted};margin-bottom:10px;cursor:pointer',
            },
            [
              span([Component.text('Command…')], attributes: {'style': 'flex:1'}),
              span(
                [Component.text('Ctrl K')],
                attributes: {'style': "font-family:${AdminFonts.mono};font-size:10.5px;flex:none"},
              ),
            ],
          ),
          for (final n in kAdminNavItems) _navRow(n),
          div(attributes: {'style': 'flex:1'}, []),
          button(
            [Component.text('Sign out')],
            onClick: component.onSignOut,
            attributes: {
              'style': 'font-size:11.5px;color:${AdminColors.faint};padding:6px 10px;'
                  'background:transparent;border:none;text-align:left;cursor:pointer;font-family:inherit',
            },
          ),
        ],
      );

  Component _navRow(AdminNavItem n) {
    final active = n.label == component.activeLabel;
    return div(
      events: {
        'click': (_) {
          if (n.route == null) component.onUnbuiltNav(n.label);
        },
      },
      attributes: {
        'style': 'padding:7px 10px;border-radius:6px;font-size:12.5px;'
            'background:${active ? AdminColors.sidebarItemActiveBg : 'transparent'};'
            'color:${active ? AdminColors.heading : AdminColors.muted};'
            'cursor:pointer;user-select:none',
      },
      [Component.text(n.label)],
    );
  }

  Component _palette() => div(
        events: {'click': (_) => _closePalette()},
        attributes: {
          'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.6);z-index:100;'
              'display:flex;align-items:flex-start;justify-content:center;padding-top:14vh',
        },
        [
          div(
            events: {'click': (e) => e.stopPropagation()},
            attributes: {
              'style': 'width:480px;max-width:90vw;background:${AdminColors.card};'
                  'border:1px solid ${AdminColors.borderLight};border-radius:10px;'
                  'box-shadow:0 24px 60px rgba(0,0,0,0.5);overflow:hidden',
            },
            [
              input<String>(
                type: InputType.text,
                value: _paletteQuery,
                onInput: (v) => setState(() => _paletteQuery = v),
                attributes: {
                  'placeholder': 'Search pages or features…',
                  'style': 'width:100%;background:transparent;border:none;'
                      'border-bottom:1px solid ${AdminColors.border};padding:14px 16px;'
                      "color:${AdminColors.text};font-family:${AdminFonts.body};font-size:14px;"
                      'box-sizing:border-box;outline:none',
                },
              ),
              div(
                attributes: {'style': 'max-height:320px;overflow-y:auto;padding:6px'},
                [
                  for (final p in _paletteResults)
                    div(
                      events: {'click': (_) => _handlePaletteSelect(p)},
                      attributes: {
                        'style': 'display:flex;justify-content:space-between;align-items:center;'
                            'padding:9px 12px;border-radius:6px;font-size:13px;'
                            'color:${AdminColors.text};cursor:pointer',
                      },
                      [
                        Component.text(p.label),
                        span(
                          [Component.text(p.route != null ? 'Page' : 'Not built')],
                          attributes: {'style': 'font-size:10.5px;color:${AdminColors.faint}'},
                        ),
                      ],
                    ),
                  if (_paletteResults.isEmpty)
                    div(
                      attributes: {
                        'style': 'padding:16px;text-align:center;font-size:12.5px;color:${AdminColors.faint}',
                      },
                      [Component.text('No matches.')],
                    ),
                ],
              ),
            ],
          ),
        ],
      );
}
