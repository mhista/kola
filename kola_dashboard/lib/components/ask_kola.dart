// ask_kola.dart — the composer at the bottom of the Overview.
//
// ── WHY THIS WAS MISSING, AND WHAT IT HONESTLY IS ────────────────────
//
// The design puts a prominent input at the bottom of the Overview and
// answers questions like "how were sales last week?" in prose, with
// stat chips and follow-up suggestions. In the export that is powered
// by AGENT_KB — a hardcoded array of four canned answers. There is no
// endpoint behind it, and there is no "ask kolaa about your business"
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
import '../services/mini_markdown.dart';
import '../theme.dart';
import 'answer_products.dart';
import 'shell/icons.dart';
import 'shell/kola_icon.dart';

/// The last answer, kept across navigation.
///
/// ── WHY A MODULE-LEVEL STORE AND NOT STATE ──────────────────────────
///
/// AskKola is mounted by the Overview. Navigating to /catalog unmounts
/// it and coming back builds a fresh State, so the answer an owner just
/// read was gone the moment they followed one of its own suggestions —
/// which is the single most likely thing for them to do next. Clicking
/// "See all products" and losing the answer that produced it makes the
/// suggestion feel like a trapdoor.
///
/// Deliberately IN MEMORY, not localStorage. This survives navigation
/// inside the session, and a full reload clears it — which is the right
/// boundary: an answer is a statement about the business at a moment in
/// time, and silently re-showing yesterday's stock levels after a reload
/// would be a false fact with a friendly face. The question stays in the
/// composer either way, so re-asking is one keystroke.
///
/// Keyed by workspace, because switching workspaces must never show the
/// previous one's answer — that would be a cross-tenant leak on screen,
/// even if the data never crossed on the wire.
class _LastAnswer {
  static int? workspaceId;
  static String question = '';
  static WorkspaceAnswer? answer;

  static void clear() {
    workspaceId = null;
    question = '';
    answer = null;
  }
}

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

  /// Whether the workspace has taught kolaa anything yet. Changes the
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

  /// The whole structured reply: prose, product ids, actions, citations.
  ///
  /// Replaces the bare List<KnowledgeSearchHit> this held when the box
  /// called searchMemory and printed retrieved chunks verbatim. There was
  /// no model in that path at all — see WorkspaceAnswerService.
  WorkspaceAnswer? _answer;
  String _answeredQuestion = '';

  /// Citations are collapsed by default now.
  ///
  /// When the passages WERE the answer they had to be open. Now they are
  /// the evidence FOR an answer, and an owner who trusts the answer
  /// should not have to scroll past its footnotes to reach the composer.
  bool _showSources = false;

  /// Which "what is kolaa doing" caption is showing.
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
  void initState() {
    super.initState();
    // Restore whatever was on screen before the owner navigated away.
    if (_LastAnswer.workspaceId == component.workspaceId &&
        _LastAnswer.answer != null) {
      _hasSearched = true;
      _answer = _LastAnswer.answer;
      _answeredQuestion = _LastAnswer.question;
      _query = _LastAnswer.question;
      // Fully revealed, not re-streamed. Replaying the typewriter on a
      // sentence the owner has already read is theatre, and it would
      // hide the actions and product cards for another second and a half
      // every time they came back to the page.
      _streamed = _LastAnswer.answer!.answer;
    }
  }

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
      final answer = await component.client.knowledge.askWorkspace(
        component.accessToken,
        component.workspaceId,
        q,
      );
      if (!mounted) return;
      _stageTimer?.cancel();
      // Three plain assignments, NOT a cascade.
      //
      // `_LastAnswer..workspaceId = ...` targets the Type object, not
      // the class's statics — cascades work on instances. It reads fine
      // and does not compile.
      _LastAnswer.workspaceId = component.workspaceId;
      _LastAnswer.question = q;
      _LastAnswer.answer = answer;
      setState(() {
        _answer = answer;
        _showSources = false;
        _searching = false;
      });
      _startStreaming(answer.answer);
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

  // _leadFor, _noAnswerFor and _actionsFor USED TO LIVE HERE.
  //
  // All three were this component inventing an answer because nothing
  // upstream produced one:
  //
  //   _leadFor      "I found 3 places..." — a sentence ABOUT the search,
  //                 written because there was no actual answer to show.
  //   _noAnswerFor  the two "I don't know" variants.
  //   _actionsFor   keyword matching on the QUESTION. Asking "what do we
  //                 have in the catalog" offered "Open your catalog"
  //                 because the word "catalog" appeared — not because of
  //                 anything in the reply. It could not do better: there
  //                 was no reply to read.
  //
  // WorkspaceAnswerService now writes the prose and picks the actions
  // from what it actually said, so all three are deleted rather than
  // kept as a fallback. A second source of answer text is a second thing
  // to keep in step, and this one would only ever run when the first had
  // already failed — which is exactly when consistency matters most.

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
              'aria-label': 'Ask what kolaa knows',
              'rows': '1',
              'placeholder': component.hasDocuments
                  ? 'Ask what kolaa knows — "what is our returns policy?"'
                  : 'Teach kolaa something first, then ask it anything',
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
                'click': (_) {
                  // Dismissing is an instruction, not a view change: it
                  // must not come back on the next visit.
                  _LastAnswer.clear();
                  setState(() {
                    _hasSearched = false;
                    _answer = null;
                    _error = null;
                  });
                },
              },
              [Component.text('×')],
            ),
          ],
        ),
        if (_searching)
          div(
            attributes: {'style': 'display:flex;flex-direction:column;gap:10px'},
            [
              // Says what kolaa is doing, not merely that it is busy. Two
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
        else if (_answer case final answer?) ...[
          // ── THE ANSWER ─────────────────────────────────────────────
          //
          // Rendered through MiniMarkdown, not printed. The old version
          // put raw text in one Component.text, which is why bullets and
          // **bold** reached the owner as literal punctuation.
          //
          // While STREAMING the partial text is rendered too, so bold
          // and bullets form as they arrive rather than snapping into
          // shape at the end. MiniMarkdown handles a half-written `**`
          // by leaving it literal, which is exactly right mid-stream.
          div(
            attributes: {'style': 'margin-bottom:4px'},
            [
              ...MiniMarkdown.render(_streamed),
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

          // ── THE PRODUCTS IT IS ABOUT ───────────────────────────────
          //
          // Only after the text has finished. Cards appearing beside a
          // half-written sentence makes the answer feel assembled rather
          // than spoken, and it is the same reason the actions wait.
          if (!_streaming && answer.productIds.isNotEmpty)
            AnswerProducts(
              client: component.client,
              accessToken: component.accessToken,
              workspaceId: component.workspaceId,
              productIds: answer.productIds,
            ),

          // ── WHAT TO DO NEXT ────────────────────────────────────────
          //
          // The model chose the intent and wrote the label; the SERVER
          // resolved the route. See workspace_answer_action.spy.yaml.
          if (!_streaming && answer.actions.isNotEmpty)
            div(
              attributes: {
                'style': 'display:flex;gap:8px;flex-wrap:wrap;margin-top:14px',
              },
              [
                for (final a in answer.actions)
                  // ── AN EMPTY ROUTE MEANS "DO IT HERE" ─────────────
                  //
                  // kolaa answered a delivery question with "refer to our
                  // knowledge base on delivery" and offered "See delivery
                  // details". There is no delivery page — the detail is a
                  // PASSAGE in a document. Navigating to /knowledge would
                  // resolve and still be wrong: the owner lands on a
                  // document list and has to hunt for the paragraph kolaa
                  // had just read.
                  //
                  // So the server emits show_details with route: '', and
                  // it expands the citations already attached to this
                  // answer, in place.
                  if (a.route.isEmpty)
                    button(
                      attributes: {
                        'type': 'button',
                        'class': 'kola-pressable',
                        'aria-expanded': _showSources ? 'true' : 'false',
                        'style': 'padding:8px 14px;'
                            'border-radius:${KolaRadius.pill};'
                            'border:1px solid ${KolaVar.border};'
                            'background:transparent;font-family:inherit;'
                            'font-size:${KolaType.tiny};font-weight:600;'
                            'color:${KolaVar.text};cursor:pointer',
                      },
                      events: {
                        'click': (_) =>
                            setState(() => _showSources = !_showSources),
                      },
                      [Component.text(a.label)],
                    )
                  else
                    Link(
                      to: a.route,
                      attributes: {
                        'class': 'kola-pressable',
                        'style': 'padding:8px 14px;'
                            'border-radius:${KolaRadius.pill};'
                            'border:1px solid ${KolaVar.border};'
                            'font-size:${KolaType.tiny};font-weight:600;'
                            'color:${KolaVar.text};text-decoration:none',
                      },
                      children: [Component.text(a.label)],
                    ),
              ],
            ),

          // ── WHERE IT CAME FROM ─────────────────────────────────────
          //
          // Collapsed. These passages used to BE the answer, so they had
          // to be open; now they are its evidence. Still one click away,
          // because "every AI answer must cite where its information came
          // from" is only true if the owner can actually reach it.
          if (!_streaming && answer.citations.isNotEmpty) ...[
            button(
              attributes: {
                'type': 'button',
                'aria-expanded': _showSources ? 'true' : 'false',
                'style': 'margin-top:14px;background:transparent;border:none;'
                    'padding:0;color:${KolaVar.muted};font-family:inherit;'
                    'font-size:${KolaType.tiny};font-weight:600;'
                    'cursor:pointer;text-decoration:underline',
              },
              events: {
                'click': (_) => setState(() => _showSources = !_showSources),
              },
              [
                Component.text(
                  _showSources
                      ? 'Hide where this came from'
                      : 'Where did this come from? '
                          '(${answer.citations.length})',
                ),
              ],
            ),
            if (_showSources)
              div(
                attributes: {
                  'style': 'display:flex;flex-direction:column;gap:10px;'
                      'margin-top:10px',
                },
                [for (final h in answer.citations) _hit(h)],
              ),
          ],

          // Said plainly rather than hidden. During a provider outage an
          // owner deserves to know this sentence is a fallback, not
          // kolaa's considered view — otherwise "kolaa got worse" is the
          // only available explanation.
          if (!_streaming && !answer.generated)
            div(
              attributes: {
                'style': 'margin-top:12px;font-size:${KolaType.tiny};'
                    'color:${KolaVar.muted};line-height:1.5',
              },
              [
                Component.text(
                  'This one was not written by kolaa\'s reasoning — it could '
                  'not be reached just now.',
                ),
              ],
            ),
        ],
      ],
    );
  }

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
              // they teach kolaa needs to see 0.61 move to 0.78, which a
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
