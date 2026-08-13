// ask_kola.dart — the composer at the bottom of the Overview.
//
// ── WHY THIS WAS MISSING, AND WHAT IT HONESTLY IS ────────────────────
//
// The design puts a prominent input at the bottom of the Overview and
// answers questions like "how were sales last week?" in prose, with
// stat chips and follow-up suggestions. In the export that is powered
// by AGENT_KB — a hardcoded array of four canned answers. There is no
// endpoint behind it, and there is no "ask kola about your business"
// service on the server.
//
// I left it out of the first pass and did not say so. That was wrong:
// it is the most visible element on the screen, and its absence made
// the page look unfinished rather than deliberately scoped.
//
// ── WHAT IT DOES INSTEAD ─────────────────────────────────────────────
//
// It runs a REAL query against business memory —
// KnowledgeEndpoint.searchMemory — and shows the passages that actually
// ground an answer, each with its source document and a confidence
// score derived from real vector similarity.
//
// That is deliberately NOT dressed up as conversational AI. It cannot
// answer "how were sales last week" because nothing measures sales yet.
// It can answer "what is our returns policy" from documents the owner
// has taught it, and show exactly which passage it came from — which is
// the thing that makes the answer trustworthy, and the reason
// searchMemory was built as an inspection tool in the first place.
//
// When the reasoning layer exists this component gets an answer above
// the citations. The citations do not get removed; they are the point.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../services/dom_files.dart';
import '../theme.dart';
import 'shell/icons.dart';
import 'shell/kola_icon.dart';

class AskKola extends StatefulComponent {
  const AskKola({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.hasDocuments,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  /// Whether the workspace has taught kola anything yet. Changes the
  /// placeholder, because inviting someone to ask a question of an
  /// empty memory produces one confusing empty answer and no second
  /// attempt.
  final bool hasDocuments;

  @override
  State<AskKola> createState() => _AskKolaState();
}

class _AskKolaState extends State<AskKola> {
  String _query = '';
  bool _searching = false;
  bool _hasSearched = false;
  String? _error;
  List<KnowledgeSearchHit> _hits = const [];
  String _answeredQuestion = '';

  Future<void> _ask() async {
    final q = _query.trim();
    if (q.isEmpty || _searching) return;

    setState(() {
      _searching = true;
      _error = null;
      _hasSearched = true;
      _answeredQuestion = q;
    });

    try {
      final hits = await component.client.knowledge.searchMemory(
        component.accessToken,
        component.workspaceId,
        q,
      );
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'display:flex;flex-direction:column;gap:12px;'
            'position:sticky;bottom:16px;z-index:5',
      },
      [
        if (_hasSearched) _results(),
        _composer(),
      ],
    );
  }

  // ── Composer ────────────────────────────────────────────────────────

  Component _composer() => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:8px;'
              'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.pill};padding:6px 6px 6px 18px;'
              'box-shadow:0 10px 30px rgba(0,0,0,0.28)',
        },
        [
          // A TEXTAREA, not a single-line input.
          //
          // A real question about a business is often a sentence, not a
          // phrase. In an <input> it scrolls sideways and the beginning
          // disappears, so you cannot read back what you typed before
          // sending it. A textarea wraps, and grows to a readable
          // height.
          //
          // Enter still sends, because that is what the control looks
          // like it does. Shift+Enter makes a new line, which is the
          // convention everywhere this pattern appears.
          textarea(
            attributes: {
              'aria-label': 'Ask what kola knows',
              'rows': '1',
              'placeholder': component.hasDocuments
                  ? 'Ask what kola knows — "what is our returns policy?"'
                  : 'Teach kola something first, then ask it anything',
              'style': 'flex:1;min-width:0;border:none;outline:none;'
                  'background:transparent;color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.ui};'
                  'padding:9px 0;resize:none;line-height:1.5;'
                  'max-height:132px;overflow-y:auto',
            },
            events: {
              // BOTH HANDLERS USED `as dynamic` AND BOTH THREW.
              //
              // Erased extension types have no Dart member called
              // `value`, `style` or `key`, so every keystroke raised
              // NoSuchMethodError inside the handler — swallowed by the
              // event loop. The composer never captured what was typed
              // and never grew, and Enter never sent. Same root cause as
              // main.dart's `(root as dynamic).style`, which was fatal
              // only because it ran before runApp. See dom_files.dart.
              'input': (e) {
                final target = e.target;
                if (target == null) return;
                _query = valueOf(target as JSObject);
                autoGrow(target);
              },
              'keydown': (e) {
                // web.KeyboardEvent, the cast app_shell.dart already
                // uses for ⌘K and which demonstrably works.
                final ev = e as web.KeyboardEvent;
                if (ev.key == 'Enter' && !ev.shiftKey) {
                  ev.preventDefault();
                  _ask();
                }
              },
            },
            [Component.text(_query)],
          ),
          button(
            attributes: {
              'class': 'kola-pressable',
              'type': 'button',
              'aria-label': 'Ask',
              'style': 'flex:none;width:36px;height:36px;border:none;'
                  'border-radius:${KolaRadius.circle};'
                  'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                  'display:flex;align-items:center;justify-content:center;'
                  '${_searching ? 'opacity:0.6' : ''}',
            },
            events: {'click': (_) => _ask()},
            [kolaIcon(Icons.arrowRight, size: 16, strokeWidth: 2)],
          ),
        ],
      );

  // ── Results ─────────────────────────────────────────────────────────

  Component _results() {
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};padding:16px;'
            'max-height:46vh;overflow-y:auto',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;margin-bottom:12px',
          },
          [
            div(
              attributes: {'style': 'color:${KolaVar.accent};display:flex'},
              [kolaIcon(Icons.sparkles, size: 15)],
            ),
            span(
              attributes: {
                'style': 'font-size:${KolaType.tiny};font-weight:600;'
                    'color:${KolaVar.muted};flex:1;min-width:0;'
                    'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text('From memory · "$_answeredQuestion"')],
            ),
            button(
              attributes: {
                'class': 'kola-pressable',
                'type': 'button',
                'aria-label': 'Dismiss',
                'style': 'flex:none;background:transparent;border:none;'
                    'color:${KolaVar.muted};font-size:${KolaType.subhead};'
                    'font-family:inherit;line-height:1',
              },
              events: {
                'click': (_) => setState(() {
                      _hasSearched = false;
                      _hits = const [];
                      _error = null;
                    }),
              },
              [Component.text('×')],
            ),
          ],
        ),
        if (_searching)
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
            [
              for (var i = 0; i < 2; i++)
                div(
                  classes: 'kola-skel',
                  attributes: {
                    'style': 'height:52px;border-radius:${KolaRadius.md}',
                  },
                  [],
                ),
            ],
          )
        else if (_error != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5',
            },
            [Component.text("Couldn't search memory: $_error")],
          )
        else if (_hits.isEmpty)
          _noMatch()
        else
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
            [for (final h in _hits) _hit(h)],
          ),
      ],
    );
  }

  /// Nothing matched.
  ///
  /// Says WHY rather than just "no results". The two causes need
  /// different actions from the owner — nothing taught yet vs. nothing
  /// relevant taught — and only they can tell which applies.
  Component _noMatch() => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.6',
        },
        [
          Component.text(component.hasDocuments
              ? 'Nothing in memory is close enough to answer that. kola only '
                  'answers from what you have taught it — it will not guess. '
                  'Adding a document that covers this makes it answerable.'
              : 'kola has not been taught anything yet, so it has nothing to '
                  'answer from. Add a price list, FAQ or policy and ask again.'),
        ],
      );

  /// One retrieved passage.
  Component _hit(KnowledgeSearchHit hit) {
    final confidence = KolaConfidenceStyle.fromScore(hit.similarity);

    return div(
      attributes: {
        'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:12px 14px',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;margin-bottom:8px;'
                'flex-wrap:wrap',
          },
          [
            div(
              attributes: {'style': 'color:${KolaVar.muted};display:flex'},
              [kolaIcon(Icons.book, size: 13)],
            ),
            span(
              attributes: {
                'style': 'font-size:${KolaType.micro};font-weight:600;'
                    'color:${KolaVar.text}',
              },
              [Component.text(hit.documentTitle)],
            ),
            span(attributes: {'style': 'flex:1'}, []),
            _confidenceDots(confidence),
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};'
                    'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              // The raw score, not just the band. Someone tuning what
              // they teach kola needs to see 0.61 move to 0.78, which a
              // three-step label cannot show.
              [Component.text(hit.similarity.toStringAsFixed(2))],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};color:${KolaVar.mutedStrong};'
                'line-height:1.6;white-space:pre-wrap;overflow-wrap:anywhere',
          },
          [Component.text(hit.content)],
        ),
      ],
    );
  }

  static String _dotColor(KolaConfidence c) => switch (c) {
        KolaConfidence.high => KolaVar.success,
        KolaConfidence.medium => KolaVar.warning,
        KolaConfidence.low => KolaVar.danger,
      };

  /// Three dots, filled by confidence — never colour alone.
  ///
  /// Matches the design system's own confidence treatment. Colour alone
  /// fails for anyone who cannot distinguish these hues, and fails
  /// completely in a printed report.
  Component _confidenceDots(KolaConfidence c) => div(
        attributes: {
          'style': 'display:flex;align-items:center;gap:3px',
          'title': c.label,
          'aria-label': c.label,
        },
        [
          for (var i = 0; i < 3; i++)
            span(
              attributes: {
                // KolaVar, not KolaConfidence.colorOn(KolaDark.tokens).
                // That returns a literal dark-mode hex, which would stay
                // dark in light mode — the exact bug the whole variable
                // indirection exists to prevent.
                'style': 'width:6px;height:6px;border-radius:${KolaRadius.circle};'
                    'background:${i < c.filledDots ? _dotColor(c) : KolaVar.border}',
              },
              [],
            ),
        ],
      );
}
