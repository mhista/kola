// docs_shell.dart — shared chrome every page renders inside: top bar
// (brand + search), left nav tree (kDocsNav), content column. Matches
// DESIGN_PROMPT.md §12's "classic docs layout" — MINUS a version
// switcher, which that section also asks for: there is only ever one
// API version that has shipped (no v1/v2 split exists anywhere in
// kola_server), so a switcher would be a dropdown with one dead entry —
// deferred honestly rather than built as a decoration. The right-hand
// "on this page" anchor nav DESIGN_PROMPT.md also asks for lives per-page
// (see on_this_page_nav.dart) since it needs each page's own heading
// list, not something this shared shell can generate generically.
//
// SEARCH: a real, working client-side filter over kDocsNav's titles —
// not wired to any backend (there's nothing to search server-side; this
// whole site is static content already loaded in the page), so "real"
// here means "actually filters the nav you see," not "hits a search
// index." Good enough for a nav tree this size; revisit with a proper
// index (e.g. lunr.js) if/when the page count grows past what a title
// filter usefully narrows.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import '../theme.dart';
import '../models/doc_nav_item.dart';

class DocsShell extends StatefulComponent {
  const DocsShell({required this.currentPath, required this.child});

  final String currentPath;
  final Component child;

  @override
  State<DocsShell> createState() => _DocsShellState();
}

class _DocsShellState extends State<DocsShell> {
  String _query = '';

  bool _matches(DocNavItem item) =>
      _query.isEmpty || item.label.toLowerCase().contains(_query.toLowerCase());

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDocsFonts.sans};background:${KolaDocsColors.bg};"
            'color:${KolaDocsColors.text};min-height:100vh',
      },
      [
        _topBar(),
        div(
          classes: 'docs-shell-row',
          attributes: {
            'style':
                'display:flex;max-width:1280px;margin:0 auto;align-items:flex-start',
          },
          [
            _leftNav(),
            div(
              classes: 'docs-shell-content',
              attributes: {
                'style': 'flex:1;min-width:0;padding:40px 48px;max-width:760px',
              },
              [component.child],
            ),
          ],
        ),
      ],
    );
  }

  Component _topBar() {
    return div(
      attributes: {
        'style':
            'display:flex;align-items:center;gap:20px;padding:14px 24px;'
            'border-bottom:1px solid ${KolaDocsColors.border};position:sticky;top:0;'
            'background:${KolaDocsColors.bg};z-index:10',
      },
      [
        Link(
          to: '/',
          attributes: {
            'style':
                'font-family:${KolaDocsFonts.display};font-size:18px;font-weight:600;'
                'color:${KolaDocsColors.text};text-decoration:none',
          },
          child: Component.text('kola docs'),
        ),
        div(attributes: {'style': 'flex:1'}, []),
        input<String>(
          type: InputType.text,
          value: _query,
          onInput: (v) => setState(() => _query = v),
          attributes: {
            'style':
                'background:${KolaDocsColors.surface};border:1px solid ${KolaDocsColors.border};'
                'border-radius:8px;padding:7px 12px;font-size:13px;color:${KolaDocsColors.text};'
                'width:200px;box-sizing:border-box',
            'placeholder': 'Search pages…',
          },
        ),
      ],
    );
  }

  Component _leftNav() {
    return div(
      classes: 'docs-shell-nav',
      attributes: {
        'style':
            'width:220px;flex-shrink:0;padding:32px 16px;position:sticky;top:57px;'
            'height:calc(100vh - 57px);overflow-y:auto;box-sizing:border-box',
      },
      [
        for (final section in kDocsNav) _navSection(section),
      ],
    );
  }

  Component _navSection(DocNavSection section) {
    final visible = section.items.where(_matches).toList();
    if (visible.isEmpty) return div([]);
    return div(
      attributes: {'style': 'margin-bottom:22px'},
      [
        div(
          attributes: {
            'style':
                'font-size:11.5px;letter-spacing:0.05em;text-transform:uppercase;'
                'color:${KolaDocsColors.textFaint};padding:0 10px 8px',
          },
          [Component.text(section.title)],
        ),
        for (final item in visible) _navLink(item),
      ],
    );
  }

  Component _navLink(DocNavItem item) {
    final active = item.path == component.currentPath;
    return Link(
      to: item.path,
      attributes: {
        'style':
            'display:block;padding:7px 10px;border-radius:8px;font-size:13.5px;'
            'text-decoration:none;margin-bottom:2px;'
            'background:${active ? KolaDocsColors.accentSoft : "transparent"};'
            'color:${active ? KolaDocsColors.accent : KolaDocsColors.textMuted}',
      },
      child: Component.text(item.label),
    );
  }
}
