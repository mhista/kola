// command_palette.dart — ⌘K / Ctrl-K jump-to-page.
//
// ── IT RENDERS FROM nav_model, NOT FROM ITS OWN LIST ─────────────────
//
// The design export hardcodes six palette entries alongside a separate
// hardcoded sidebar. Kept that way, the palette silently rots: someone
// adds a page to the sidebar, nobody adds it here, and the feature that
// exists to reach any page quietly reaches an arbitrary subset.
//
// So entries come from [paletteEntries], which flattens the same gated
// navigation the sidebar draws. A page reachable in the sidebar is
// reachable here, always, with no second edit.
//
// ── IT SHOWS ONLY WHAT THE WORKSPACE HAS ─────────────────────────────
//
// Gated the same way as everything else. A palette that autocompletes
// 'Forecasting' for a workspace that cannot use it would leak the
// roadmap more efficiently than the sidebar ever could — search is
// exactly where someone would go looking.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../nav/nav_model.dart';
import '../../services/feature_gate.dart';
import '../../theme.dart';
import 'icons.dart';
import 'kola_icon.dart';

class CommandPalette extends StatefulComponent {
  const CommandPalette({required this.gate, required this.onClose});

  final FeatureGate gate;
  final void Function() onClose;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  String _query = '';

  @override
  Component build(BuildContext context) {
    final entries = paletteEntries(component.gate);
    final matches = _filter(entries, _query);

    return div(
      attributes: {
        'style': 'position:fixed;inset:0;z-index:200;'
            'background:rgba(0,0,0,0.55);display:flex;'
            'align-items:flex-start;justify-content:center;'
            'padding:12vh 16px 16px',
        'role': 'dialog',
        'aria-modal': 'true',
        'aria-label': 'Jump to a page',
      },
      events: {'click': (_) => component.onClose()},
      [
        div(
          attributes: {
            'style': 'width:560px;max-width:100%;background:${KolaVar.card};'
                'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};overflow:hidden;'
                'box-shadow:0 24px 60px rgba(0,0,0,0.45);'
                'display:flex;flex-direction:column;max-height:70vh',
          },
          events: {'click': (e) => e.stopPropagation()},
          [
            _searchRow(),
            _results(matches),
          ],
        ),
      ],
    );
  }

  Component _searchRow() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:10px;'
              'padding:14px 16px;border-bottom:1px solid ${KolaVar.border};'
              'color:${KolaVar.muted};flex:none',
        },
        [
          kolaIcon(Icons.search, size: 16),
          input(
            type: InputType.text,
            attributes: {
              'placeholder': 'Jump to a page…',
              'autofocus': 'true',
              'aria-label': 'Search pages',
              'style': 'flex:1;border:none;outline:none;background:transparent;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.ui}',
            },
            events: {
              'input': (e) {
                final value = (e.target as dynamic).value as String? ?? '';
                setState(() => _query = value);
              },
              'keydown': (e) {
                if ((e as dynamic).key == 'Escape') component.onClose();
              },
            },
          ),
          span(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};font-size:${KolaType.micro};'
                  'color:${KolaVar.muted};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.sm};padding:2px 6px',
            },
            [Component.text('esc')],
          ),
        ],
      );

  Component _results(List<({NavItem item, String group})> matches) {
    if (matches.isEmpty) {
      return div(
        attributes: {
          'style': 'padding:28px 16px;text-align:center;'
              'font-size:${KolaType.small};color:${KolaVar.muted}',
        },
        [
          // Names the query back. "No results" alone leaves people
          // wondering whether the search ran at all.
          Component.text('Nothing matches "$_query".'),
        ],
      );
    }

    return div(
      attributes: {'style': 'padding:8px;overflow-y:auto'},
      [
        // The click handler sits on a wrapper, not on the Link.
        //
        // Navigating leaves the palette open over the new page unless
        // something closes it — the router changes the route and knows
        // nothing about this overlay. The wrapper catches the bubbling
        // click, which uses only element helpers already proven in this
        // codebase rather than assuming Link forwards event handlers.
        for (final match in matches)
          div(
            events: {'click': (_) => component.onClose()},
            [
              Link(
                to: match.item.route,
                attributes: {
                  'class': 'kola-nav-row',
                  'style': 'display:flex;align-items:center;gap:12px;'
                      'padding:10px 12px;border-radius:${KolaRadius.sm};'
                      'text-decoration:none;color:${KolaVar.text}',
                },
                children: [
                  kolaIcon(match.item.icon, size: 16, extraStyle: 'flex:none'),
                  span(
                    attributes: {'style': 'font-size:${KolaType.ui}'},
                    [Component.text(match.item.label)],
                  ),
                  span(
                    attributes: {
                      'style': 'margin-left:auto;font-size:${KolaType.micro};'
                          'color:${KolaVar.muted}',
                    },
                    [Component.text(match.group)],
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  /// Case-insensitive substring match on the label, then on the group.
  ///
  /// Substring rather than prefix, on purpose: someone looking for
  /// 'Sales counter' very often types 'counter'. Prefix matching would
  /// return nothing for that, which reads as "the page does not exist".
  ///
  /// Label matches are ordered before group matches, so typing 'sell'
  /// surfaces the Sell group's pages beneath any page actually named
  /// with it rather than mixed in among them.
  static List<({NavItem item, String group})> _filter(
    List<({NavItem item, String group})> entries,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;

    final byLabel = <({NavItem item, String group})>[];
    final byGroup = <({NavItem item, String group})>[];

    for (final e in entries) {
      if (e.item.label.toLowerCase().contains(q)) {
        byLabel.add(e);
      } else if (e.group.toLowerCase().contains(q)) {
        byGroup.add(e);
      }
    }
    return [...byLabel, ...byGroup];
  }
}
