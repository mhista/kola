// page_help_button.dart — Phase 14k. The "?" affordance every page in
// `Kola Dashboard Shell.dc.html` specifies (lines 48-60 of that export)
// but that did not exist anywhere in the built app before this — see
// PHASE_14_HANDOFF.pdf's 14k section for the grep that confirmed the
// gap. Built once, here, precisely because it is a shell-level concern
// the export itself groups with the shell rather than with any one
// page: every page needs the identical button/modal/localStorage
// behaviour, and only the copy changes.
//
// ── WHAT THIS MATCHES, EXACTLY ─────────────────────────────────────────
//
// - A circular 34x34 button, containing a literal "?" text character
//   (not an SVG glyph — the export uses text here on purpose, see its
//   own `onClick={{ openPageHelp }}` button).
// - A centred modal overlay (dark scrim) with a "Got it" dismiss.
// - Auto-opens once per page, per browser: keyed off
//   `kola-seen-help-{pageKey}` in localStorage (LocalStorage, the
//   project's existing thin wrapper over window.localStorage — see
//   services/local_storage.dart). Dismissing it — either the × or "Got
//   it" — sets that key so it never auto-opens again on that page for
//   that browser, exactly as the export's own script does at its lines
//   555-557. After that it stays reachable, dismissible-only, via the
//   "?" button.
//
// ── ONE NAMED DEVIATION FROM THE EXPORT ────────────────────────────────
//
// The export's modal also renders a "Read the full guide" link to
// `Kola Docs Site.dc.html`. There is no built, reachable docs site in
// this product yet (kola_docs/ is a separate, unshipped app) — linking
// to it here would be a dead link inside a help modal, which defeats
// the point of the feature. Left out rather than pointed at nothing;
// add it back once a real docs site has a real URL.
//
// ── WHY A SHARED COMPONENT AND NOT PER-PAGE COPIES ─────────────────────
//
// Every page needs the same button, same modal chrome, same
// auto-open-once mechanics. Duplicating that seventeen times means a
// future fix (a spacing tweak, an accessibility attribute) has to be
// found and applied seventeen times too. Only [title] and [body] vary
// per call site.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';

import '../../services/local_storage.dart';
import '../../theme.dart';

class PageHelpButton extends StatefulComponent {
  const PageHelpButton({
    required this.pageKey,
    this.title,
    required this.body,
  });

  /// Unique per page — e.g. 'overview', 'tasks'. Used to key both the
  /// localStorage auto-open flag and this component's own state.
  final String pageKey;

  /// The modal's heading. The export's own default is "What's this page
  /// for?" — kept as the convention rather than repeated as a literal
  /// at every call site, so pages that want the default omit it.
  final String? title;

  /// One or more paragraphs of real, page-specific explanatory copy —
  /// per DESIGN_DELTA.md's "named simplification beats fabricated
  /// finding" rule, never generic placeholder text.
  final List<String> body;

  @override
  State<PageHelpButton> createState() => _PageHelpButtonState();
}

class _PageHelpButtonState extends State<PageHelpButton> {
  bool _open = false;

  String get _storageKey => 'kola-seen-help-${component.pageKey}';

  @override
  void initState() {
    super.initState();
    // Auto-open once per page, per browser — matches the export's own
    // `if (!localStorage.getItem('kola-seen-help-overview')) { showPageHelp: true }`.
    if (LocalStorage.getItem(_storageKey) == null) {
      _open = true;
    }
  }

  void _dismiss() {
    LocalStorage.setItem(_storageKey, '1');
    setState(() => _open = false);
  }

  @override
  Component build(BuildContext context) {
    return div(
      // display:contents — this wrapper exists only so the button and
      // its (conditionally rendered) modal can be returned as one
      // Component from a single call site; it must not itself take up
      // layout space or affect the flex row a page places it in.
      attributes: {'style': 'display:contents'},
      [
        button(
          attributes: {
            'type': 'button',
            'aria-label': 'Help for this page',
            'style': 'width:34px;height:34px;border-radius:${KolaRadius.circle};'
                'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
                'color:${KolaVar.muted};cursor:pointer;flex:none;'
                'font-family:${KolaFonts.display};font-weight:700;'
                'font-size:14px;display:flex;align-items:center;'
                'justify-content:center',
          },
          events: {'click': (_) => setState(() => _open = true)},
          [Component.text('?')],
        ),
        if (_open) _modal(),
      ],
    );
  }

  Component _modal() => div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': component.title ?? "What's this page for?",
          'style': 'position:fixed;inset:0;z-index:300;'
              'background:rgba(0,0,0,0.55);display:flex;'
              'align-items:center;justify-content:center;padding:20px',
        },
        events: {'click': (_) => _dismiss()},
        [
          div(
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.xl};padding:26px;'
                  'width:100%;max-width:420px;box-sizing:border-box',
            },
            events: {'click': (e) => e.stopPropagation()},
            [
              div(
                attributes: {
                  'style': 'display:flex;justify-content:space-between;'
                      'align-items:center;margin-bottom:10px;gap:12px',
                },
                [
                  div(
                    attributes: {
                      'style': 'font-size:${KolaType.subhead};'
                          'font-weight:600;color:${KolaVar.text}',
                    },
                    [Component.text(component.title ?? "What's this page for?")],
                  ),
                  span(
                    attributes: {
                      'style': 'cursor:pointer;color:${KolaVar.muted};'
                          'font-size:18px;line-height:1;flex:none',
                      'aria-label': 'Close',
                      'role': 'button',
                    },
                    events: {'click': (_) => _dismiss()},
                    [Component.text('×')],
                  ),
                ],
              ),
              for (final p in component.body)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.bodyLg};'
                        'color:${KolaVar.text};line-height:1.6;'
                        'margin-bottom:${KolaSpace.md}',
                  },
                  [Component.text(p)],
                ),
              button(
                attributes: {
                  'type': 'button',
                  'style': 'background:transparent;'
                      'border:1px solid ${KolaVar.border};'
                      'color:${KolaVar.text};border-radius:${KolaRadius.pill};'
                      'padding:9px 16px;font-size:${KolaType.body};'
                      'font-weight:600;font-family:inherit;cursor:pointer',
                },
                events: {'click': (_) => _dismiss()},
                [Component.text('Got it')],
              ),
            ],
          ),
        ],
      );
}
