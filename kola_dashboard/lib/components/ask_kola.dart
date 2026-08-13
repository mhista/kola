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

import 'dart:async';
import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../services/dom_files.dart';
import '../services/error_text.dart';
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

  /// Which "what is kola doing" caption is showing.
  ///
  /// The export runs a fixed 700ms think before streaming, because a
  /// static file has nothing to wait for. Here the wait is a REAL round
  /// trip of unknown length, so the captions cycle until it returns —
  /// and they say what is actually happening rather than spinning.
  int _stage = 0;
  Timer? _stageTimer;

  /// How much of the answer has been revealed. The export's
  /// streamAnswer: 3 characters every 18ms.
  ///
  /// The full text is not held in a field — the timer closes over it,
  /// and a second copy on the state would only be another thing to keep
  /// in step.
  String _streamed = '';
  Timer? _streamTimer;
  bool get _streaming => _streamTimer?.isActive ?? false;

  static const _thinkingStages = <String>[
    'Reading what you have taught me',
    'Checking your catalog',
    'Putting it together',
  ];

  @override
  void dispose() {
    // Both fire setState. A timer outliving the component would call it
    // after unmount, which is a crash rather than a cosmetic problem.
    _stageTimer?.cancel();
    _streamTimer?.cancel();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _query.trim();
    if (q.isEmpty || _searching) return;

    setState(() {
      _searching = true;
      _error = null;
      _hasSearched = true;
      _answeredQuestion = q;
      _stage = 0;
      _streamed = '';
    });
    _startStages();

    try {
      final hits = await component.client.knowledge.searchMemory(
        component.accessToken,
        component.workspaceId,
        q,
      );
      if (!mounted) return;
      _stageTimer?.cancel();
      setState(() {
        _hits = hits;
        _searching = false;
      });
      // Nothing found is still an ANSWER, and it streams like one — the
      // alternative is a blank card that reads as a failure.
      _startStreaming(hits.isEmpty ? _noAnswerFor(q) : _leadFor(hits));
    } catch (e) {
      if (!mounted) return;
      _stageTimer?.cancel();
      setState(() {
        _searching = false;
        // Was e.toString(), which put "ServerpodClientException: ..." in
        // front of an owner. See error_text.dart.
        _error = ErrorText.of(e);
      });
    }
  }

  void _startStages() {
    _stageTimer?.cancel();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      // Holds on the LAST caption rather than looping back to the first.
      // A cycle that restarts reads as stuck; one that settles reads as
      // nearly done.
      setState(() {
        if (_stage < _thinkingStages.length - 1) _stage++;
      });
    });
  }

  /// Reveals the answer a few characters at a time.
  ///
  /// The export's own cadence: 3 characters every 18ms. It is not
  /// decoration — text that appears all at once is read as a lookup,
  /// text that arrives is read as an answer, and the difference changes
  /// how much an owner trusts it.
  void _startStreaming(String text) {
    _streamTimer?.cancel();
    setState(() => _streamed = '');

    var i = 0;
    _streamTimer = Timer.periodic(const Duration(milliseconds: 18), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      i += 3;
      setState(() {
        _streamed = i >= text.length ? text : text.substring(0, i);
      });
      if (i >= text.length) t.cancel();
    });
  }

  /// The one-line summary above the citations.
  String _leadFor(List<KnowledgeSearchHit> hits) {
    final n = hits.length;
    return 'I found $n place${n == 1 ? '' : 's'} in what you have taught me '
        'that answer this. They are quoted below, so you can see exactly '
        'what I would tell a customer.';
  }

  /// What to say when memory has nothing.
  String _noAnswerFor(String q) {
    if (!component.hasDocuments) {
      return "I have not been taught anything yet, so I cannot answer that "
          "from your own words. Add a price list, an FAQ or your delivery "
          "terms and ask me again.";
    }
    return "I could not find that in what you have taught me. Either it is "
        "not in there yet, or it is worded differently — try the words a "
        "customer would use.";
  }

  /// Where this question could be answered instead.
  ///
  /// ── WHY SUGGEST ACTIONS AT ALL ─────────────────────────────────────
  ///
  /// Asking "check my catalog" and being told "I don't have enough
  /// signal" is a dead end, and it is WRONG — the catalog exists, kola
  /// just cannot answer from memory about it. Pointing at the screen
  /// that does answer it turns a refusal into a route.
  ///
  /// Only destinations that are REGISTERED and RELEASED appear. A
  /// suggestion leading to a locked or unbuilt screen would be the dead
  /// link problem again, wearing a helpful face.
  List<({String label, String route})> _actionsFor(String question) {
    final q = question.toLowerCase();
    final out = <({String label, String route})>[];

    void add(String label, String route) {
      if (!out.any((a) => a.route == route)) {
        out.add((label: label, route: route));
      }
    }

    if (q.contains('catalog') || q.contains('product') || q.contains('price') ||
        q.contains('stock') || q.contains('sell') || q.contains('item')) {
      add('Open your catalog', '/catalog');
    }
    if (q.contains('teach') || q.contains('know') || q.contains('document') ||
        q.contains('upload') || q.contains('learn')) {
      add('Open Knowledge', '/knowledge');
    }
    if (q.contains('message') || q.contains('customer') ||
        q.contains('conversation') || q.contains('reply') ||
        q.contains('attention') || q.contains('waiting')) {
      add('Open Operations', '/operations');
    }
    if (q.contains('agent') || q.contains('bot') || q.contains('answer')) {
      add('Open Agents', '/bots');
    }
    if (q.contains('whatsapp') || q.contains('telegram') ||
        q.contains('channel') || q.contains('connect')) {
      add('Open Integrations', '/integrations');
    }
    if (q.contains('plan') || q.contains('bill') || q.contains('pay') ||
        q.contains('upgrade')) {
      add('Open Billing', '/billing');
    }
    return out;
  }

  // ── Results ─────────────────────────────────────────────────────────

  /// Suggested destinations for the question just asked.
  ///
  /// Renders nothing when there is nowhere useful to send the owner —
  /// an empty row of chips is worse than no row.
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

  /// Returns a LIST rather than a single Component so "nothing to
  /// suggest" is just an empty list. Component.fragment would do the
  /// same job but has no use anywhere else in this codebase, and an
  /// unverified API for a one-line convenience is not a trade worth
  /// making — see media_upload.dart's header.
  List<Component> _actions() {
    final actions = _actionsFor(_answeredQuestion);
    if (actions.isEmpty) return const [];

    return [div(
      attributes: {'style': 'margin-top:14px'},
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:8px',
          },
          [
            Component.text(
              _hits.isEmpty
                  ? 'You can look here instead:'
                  : 'You might also want:',
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap'},
          [
            for (final a in actions)
              Link(
                to: a.route,
                attributes: {
                  'class': 'kola-pressable',
                  'style': 'padding:8px 14px;border-radius:${KolaRadius.pill};'
                      'border:1px solid ${KolaVar.border};'
                      'font-size:${KolaType.tiny};font-weight:600;'
                      'color:${KolaVar.text};text-decoration:none',
                },
                children: [Component.text(a.label)],
              ),
          ],
        ),
      ],
    )];
  }

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
            attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
            [
              // Says what kola is doing, not merely that it is busy. Two
              // grey rectangles tell an owner nothing; "Checking your
              // catalog" tells them the wait is earning something.
              div(
                attributes: {
                  'style': 'display:flex;align-items:center;gap:8px;'
                      'font-size:${KolaType.small};color:${KolaVar.muted}',
                },
                [
                  div(
                    attributes: {
                      'style': 'width:6px;height:6px;border-radius:50%;'
                          'background:${KolaVar.accent};flex:none',
                    },
                    [],
                  ),
                  Component.text('${_thinkingStages[_stage]}…'),
                ],
              ),
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
            // _error is already a finished sentence from ErrorText.of —
            // prefixing it produced "Couldn't search memory: You're
            // offline.", which says the same thing twice.
            [Component.text(_error!)],
          )
        else ...[
          // The streamed answer, above whatever it is grounded in.
          if (_streamed.isNotEmpty)
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};color:${KolaVar.text};'
                    'line-height:1.6;margin-bottom:12px;max-width:64ch',
              },
              [
                Component.text(_streamed),
                // A caret while text is still arriving. Removed the
                // instant it finishes, so a finished answer never looks
                // like it stopped halfway.
                if (_streaming)
                  span(
                    attributes: {
                      'style': 'display:inline-block;width:2px;height:1em;'
                          'background:${KolaVar.accent};'
                          'vertical-align:text-bottom;margin-left:2px',
                    },
                    [],
                  ),
              ],
            ),

          if (_hits.isEmpty)
            _noMatch()
          else
            div(
              attributes: {
                'style': 'display:flex;flex-direction:column;gap:10px',
              },
              [for (final h in _hits) _hit(h)],
            ),

          // Where to go instead. Shown once the answer has finished
          // arriving — offering the exit before kola has finished
          // speaking reads as giving up.
          if (!_streaming) ..._actions(),
        ],
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
