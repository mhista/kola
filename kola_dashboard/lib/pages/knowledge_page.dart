// knowledge_page.dart — Knowledge Center.
//
// REBUILT against Kola Knowledge Base.dc.html, structure-first.
//
// ── HOW THIS WAS BUILT, BECAUSE THE METHOD WAS THE BUG ───────────────
//
// The previous version was written by opening the old page and asking
// "what should change?". That anchors everything to the old screen, and
// whatever it happened to do survives without ever being decided. The
// result had two underline tabs and an inline add-card; the export
// specifies three pill tabs, a document table with status filters, and a
// "Build from what's already here" panel. None of those omissions was a
// trade-off anyone weighed.
//
// So this file was built from the export's own `state` keys and arrays,
// listed first, then built to:
//
//   state : view · tab · searchQuery · statusFilter · inspectorQuery ·
//           inspectorResult · addText · uploadQueue · generatedSources ·
//           emptyDocsView
//   arrays: DOCS(7) · EXAMPLES(3) · DATA_SOURCES(3)
//
// ── THE TABLE WAS ALWAYS SERVABLE ────────────────────────────────────
//
// Worth recording because it kills the usual excuse. KnowledgeDocument
// already carries every column the design's table wants:
//
//   TITLE    → title          SECTIONS → chunkCount
//   SOURCE   → sourceRef      UPDATED  → updatedAt
//   STATUS   → status         reason   → errorMessage
//
// The table, the filter chips and the status badges were missing for no
// backend reason at all. They were simply never built.
//
// ── STATUS: SERVER VOCABULARY vs DESIGN VOCABULARY ───────────────────
//
// The server writes 'indexed' and 'failed'. The design shows
// searchable / processing / failed. `indexed` IS `searchable` — same
// state, owner-facing word. Mapped at the boundary rather than renaming
// the server, because 'indexed' is accurate to what the ingestion
// pipeline did and 'searchable' is accurate to what the owner gets.
//
// `processing` is never written today — ingestion is synchronous — so
// that chip legitimately reads (0). It is still rendered, because it
// becomes real the moment extraction moves to a queue, and a filter that
// appears later is a worse surprise than one that reads zero.
//
// ── NO TITLE FIELD, DELIBERATELY ─────────────────────────────────────
//
// The design's "Paste it in" card is one textarea and one button. The
// old page had a separate Title input. addDocument still requires a
// title, so it is DERIVED from the first line rather than asked for —
// following the design without dropping data the server needs.

import 'dart:js_interop';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../components/shell/page_help_button.dart';
import '../services/feature_gate.dart';
import '../services/dom_files.dart';
import '../services/file_intake.dart';
import '../services/money.dart';
import '../services/error_text.dart';
import '../services/mini_markdown.dart';
import '../services/responsive.dart';
import '../theme.dart';

/// One file the owner dropped, and what became of it.
///
/// The design's `uploadQueue`. A queue rather than a single slot because
/// owners drop a folder's worth at once, and reporting only the first
/// failure means the other four look like they worked.
class _QueuedFile {
  _QueuedFile(this.assessment);

  final FileAssessment assessment;
  String state = 'pending'; // pending · saving · done · failed
  String? message;

  /// Index into [_KnowledgePageState.uploadStages], advanced on a timer
  /// while [state] is 'saving'.
  int stage = 0;
}

class KnowledgePage extends StatefulComponent {
  const KnowledgePage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;
  final FeatureGate gate;

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage>
    with ResponsiveViewport<KnowledgePage> {
  // tab: documents · inspector · add
  String _tab = 'documents';

  List<KnowledgeDocument> _docs = const [];

  /// How many products the workspace has.
  ///
  /// The precondition for "Build from what's already here" is DATA, not
  /// a feature flag — see _dataSourceRow. Null means not counted yet.
  int? _productCount;

  /// Which build-from row is currently generating, if any.
  String? _generating;
  bool _loading = true;
  String? _loadError;

  String _search = '';
  String _statusFilter = 'all';

  // Add knowledge
  String _pasteText = '';
  bool _saving = false;
  String? _addMessage;
  bool _duplicateOffer = false;
  final List<_QueuedFile> _queue = [];

  // Memory inspector
  String _probe = '';
  bool _probing = false;
  bool _probed = false;
  List<KnowledgeSearchHit> _hits = const [];

  /// EXAMPLES(3) — sample questions with the kind of match each is meant
  /// to demonstrate. Pure UI, carried verbatim from the export.
  static const _examples = <(String, String)>[
    ('Do you deliver to Abuja?', 'match'),
    ('Can I exchange an item after a week?', 'nearmiss'),
    ('Do you accept crypto payments?', 'none'),
  ];

  /// DATA_SOURCES(3) — "Build from what's already here".
  static const _dataSources = <(String, String, String, String)>[
    ('catalog', 'Product catalog', 'Prices, stock, descriptions', Icons.catalog),
    ('inventory', 'Inventory & stock levels',
        'Turns stock counts into "in stock / low / out" answers', Icons.catalog),
    ('sales', 'Sales history',
        'What sells together, popular sizes, repeat customers', Icons.activity),
  ];

  @override
  void initState() {
    super.initState();
    initResponsive();
    _load();
  }

  @override
  void dispose() {
    disposeResponsive();
    super.dispose();
  }

  /// First load. Shows the skeleton, because there is genuinely nothing
  /// on screen yet.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _fetch();
  }

  /// Reload WITHOUT flipping the page back to a skeleton.
  ///
  /// This is why adding knowledge appeared to reload the whole screen:
  /// _onFiles finished by calling _load(), which set _loading = true, so
  /// the upload queue the owner was watching — with its own progress
  /// stages — vanished and the entire page redrew as placeholders. The
  /// list they were waiting for was replaced by a spinner at the exact
  /// moment it finally had something to show.
  ///
  /// A refresh after a write should update what changed and disturb
  /// nothing else.
  Future<void> _refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      final docs = await component.client.knowledge.listDocuments(
        component.accessToken,
        component.workspaceId,
      );

      // Product count, for the build-from rows. Failure is silent: those
      // rows degrading to "nothing to build from" is a smaller problem
      // than the documents list not appearing.
      int? products;
      try {
        final list = await component.client.product.listProducts(
          component.accessToken,
          component.workspaceId,
          includeArchived: false,
        );
        products = list.length;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _docs = docs;
        if (products != null) _productCount = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  // ── Derived ────────────────────────────────────────────────────────

  /// 'indexed' → 'searchable'. See the header on why this maps rather
  /// than renaming either side.
  String _designStatus(KnowledgeDocument d) => switch (d.status) {
        'indexed' => 'searchable',
        'failed' => 'failed',
        _ => 'processing',
      };

  int _countFor(String filter) => filter == 'all'
      ? _docs.length
      : _docs.where((d) => _designStatus(d) == filter).length;

  List<KnowledgeDocument> get _visibleDocs {
    final q = _search.trim().toLowerCase();
    return [
      for (final d in _docs)
        if (_statusFilter == 'all' || _designStatus(d) == _statusFilter)
          if (q.isEmpty || d.title.toLowerCase().contains(q)) d,
    ];
  }

  // ── Actions ────────────────────────────────────────────────────────

  /// The design has no Title input. addDocument needs one, so it comes
  /// from the first non-empty line — which is what a price list or
  /// policy almost always leads with anyway.
  String _deriveTitle(String text) {
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      return t.length <= 70 ? t : '${t.substring(0, 67)}…';
    }
    return 'Pasted note';
  }

  Future<void> _savePaste({bool allowDuplicate = false}) async {
    final text = _pasteText.trim();
    if (text.isEmpty) {
      setState(() => _addMessage = 'Paste some text first.');
      return;
    }
    setState(() {
      _saving = true;
      _addMessage = null;
      _duplicateOffer = false;
    });
    try {
      await component.client.knowledge.addDocument(
        component.accessToken,
        component.workspaceId,
        _deriveTitle(text),
        text,
        allowDuplicate: allowDuplicate,
      );
      if (!mounted) return;
      setState(() {
        _pasteText = '';
        _saving = false;
        _addMessage = 'Saved. kolaa can answer from this now.';
        _tab = 'documents';
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorText.of(e);
      setState(() {
        _saving = false;
        _addMessage = msg;
        _duplicateOffer = msg.toLowerCase().contains('already');
      });
    }
  }

  /// What kolaa is doing to a file, in the owner's language.
  ///
  /// Ingestion is one server call with no progress events, so a
  /// percentage bar would be a lie. These are the real phases that call
  /// performs — read, split, embed, index — said in words a shop owner
  /// recognises, cycling until the call returns.
  ///
  /// The point is not decoration. Uploading a price list and getting no
  /// acknowledgement at all reads as "nothing happened", and the owner
  /// uploads it again.
  static const uploadStages = <String>[
    'Received your file',
    'Reading it through',
    'Breaking it into passages',
    'Learning what it says',
    'Filing it away',
  ];

  /// Advances the stage caption of every file still saving.
  void _tickStages() {
    if (!mounted) return;
    final active = _queue.where((q) => q.state == 'saving').toList();
    if (active.isEmpty) return;
    setState(() {
      for (final q in active) {
        q.stage = (q.stage + 1) % uploadStages.length;
      }
    });
    Future.delayed(const Duration(milliseconds: 900), _tickStages);
  }

  Future<void> _onFiles(List<web.File> files) async {
    for (final f in files) {
      final assessment = await FileIntake.assess(f);
      if (!mounted) return;
      final q = _QueuedFile(assessment);
      setState(() => _queue.add(q));

      if (!assessment.canIngestNow) {
        // The design already has a home for this: a `failed` row with a
        // plain-language reason. Extraction for PDF/DOCX/XLSX is not
        // built, and saying so per-file is better than a disabled drop
        // zone that never explains itself.
        setState(() {
          q.state = 'failed';
          q.message = assessment.explanation;
        });
        continue;
      }

      setState(() {
        q.state = 'saving';
        q.stage = 0;
      });
      _tickStages();
      try {
        // EVERY file goes through addDocumentFromFile now, text
        // included. A branch here would mean two upload paths that can
        // drift; the server decodes plain text with allowMalformed and
        // unzips a spreadsheet, and either way the result lands in the
        // same addDocument.
        //
        // readBase64 rather than readText: a .xlsx is a binary zip, and
        // reading it as text corrupts it before it is ever sent.
        final base64 = await FileIntake.readBase64(f);
        await component.client.knowledge.addDocumentFromFile(
          component.accessToken,
          component.workspaceId,
          assessment.name,
          base64,
          allowDuplicate: false,
        );
        if (!mounted) return;
        setState(() => q.state = 'done');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          q.state = 'failed';
          q.message = ErrorText.of(e);
        });
      }
    }
    await _refresh();
  }

  /// Which document's feed toggle is mid-flight, if any. Blocks a second
  /// click on the same row while the first is still in transit — the
  /// same guard _generating already uses for the build-from buttons.
  int? _togglingId;

  /// Set only on a failed toggle. Deliberately its OWN field rather than
  /// reusing [_loadError]: [_loadError] swaps the whole Documents tab for
  /// [_errorState], which would hide every other row's table over one
  /// row's failed click — a much bigger reaction than the failure
  /// deserves.
  String? _toggleError;

  /// Flips a document's feedingEnabled — "Pause"/"Resume" in
  /// owner-facing terms. The row updates from the server's own returned
  /// document (not a locally-guessed value), so a failure never leaves
  /// the toggle showing a state the database doesn't actually have.
  Future<void> _toggleFeeding(KnowledgeDocument d) async {
    if (d.id == null || _togglingId != null) return;
    setState(() {
      _togglingId = d.id;
      _toggleError = null;
    });
    try {
      final updated = await component.client.knowledge.setFeedingEnabled(
        component.accessToken,
        component.workspaceId,
        d.id!,
        !d.feedingEnabled,
      );
      if (!mounted) return;
      setState(() {
        _docs = [
          for (final existing in _docs)
            if (existing.id == updated.id) updated else existing,
        ];
        _togglingId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _togglingId = null;
        _toggleError = ErrorText.of(e);
      });
    }
  }

  Future<void> _runProbe([String? preset]) async {
    final q = (preset ?? _probe).trim();
    if (q.isEmpty) return;
    setState(() {
      _probe = q;
      _probing = true;
      _probed = false;
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
        _probing = false;
        _probed = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hits = const [];
        _probing = false;
        _probed = true;
        _loadError = ErrorText.of(e);
      });
    }
  }


  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// Confidence → badge tone.
  ///
  /// KolaConfidenceStyle deliberately exposes `filledDots`, `label` and
  /// `colorOn(KolaTokens)` — NOT a tone, and not a CSS-variable colour.
  /// `colorOn` needs a resolved KolaTokens instance, which pages do not
  /// hold (they interpolate KolaVar custom properties instead). So the
  /// mapping happens here, reusing fromScore's thresholds rather than
  /// inventing a second set that could drift from the design system.
  KolaTone _confidenceTone(double score) =>
      switch (KolaConfidenceStyle.fromScore(score)) {
        KolaConfidence.high => KolaTone.positive,
        KolaConfidence.medium => KolaTone.caution,
        KolaConfidence.low => KolaTone.neutral,
      };

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'padding:${KolaSpace.lg};max-width:1180px;margin:0 auto;width:100%;box-sizing:border-box'},
      [
        _header(),
        _tabs(),
        if (_loading)
          _skeleton()
        else if (_loadError != null && _tab == 'documents')
          _errorState()
        else if (_tab == 'documents')
          _documentsTab()
        else if (_tab == 'inspector')
          _inspectorTab()
        else
          _addTab(),
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.md}'},
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:flex-start;'
                  'justify-content:space-between;gap:12px',
            },
            [
              div(
                attributes: {
                  'style': 'font-family:${KolaFonts.display};'
                      'font-size:${KolaType.h2};font-weight:700;'
                      'color:${KolaVar.text};margin-bottom:6px',
                },
                [Component.text('Knowledge Center')],
              ),
              const PageHelpButton(
                pageKey: 'knowledge',
                body: [
                  "What kolaa knows, and exactly which passage it would "
                      "answer a customer's question from. Documents "
                      "lists everything it's been given; Memory "
                      "Inspector lets you test a question and see the "
                      "exact source it would draw from; Add knowledge is "
                      "where you upload or paste something new.",
                ],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:70ch',
            },
            [
              Component.text("What kolaa knows, and exactly which passage it "
                  "would answer a customer's question from."),
            ],
          ),
        ],
      );

  /// Three PILL tabs, per the export. The old page had two underline
  /// tabs and hid "Add knowledge" inside the Documents view.
  Component _tabs() => div(
        attributes: {
          'style': 'display:inline-flex;gap:4px;padding:4px;'
              'border-radius:${KolaRadius.pill};background:${KolaVar.pill};'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          // "Documents (0)" reads as an error state. The count appears
          // once there is something to count.
          _tabPill(
            'documents',
            _docs.isEmpty ? 'Documents' : 'Documents (${_docs.length})',
          ),
          _tabPill('inspector', 'Memory Inspector'),
          _tabPill('add', 'Add knowledge'),
        ],
      );

  Component _tabPill(String id, String label) {
    final active = _tab == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:8px 16px;border-radius:${KolaRadius.pill};'
            'border:none;font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer;'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong}',
      },
      events: {'click': (_) => setState(() => _tab = id)},
      [Component.text(label)],
    );
  }

  // ── Documents ──────────────────────────────────────────────────────

  Component _documentsTab() => div([
        // A toggle failure gets its own small banner rather than
        // swapping in [_errorState] — see [_toggleError]'s doc comment.
        if (_toggleError != null)
          div(
            attributes: {
              'style': 'padding:10px 14px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.danger};'
                  'background:${KolaVar.dangerBg};'
                  'color:${KolaVar.danger};font-size:${KolaType.small};'
                  'margin-bottom:${KolaSpace.sm}',
            },
            [Component.text(_toggleError!)],
          ),
        if (_docs.isNotEmpty) ...[
          input<String>(
            type: InputType.search,
            attributes: {
              'aria-label': 'Search documents',
              'placeholder': 'Search documents…',
              'style': 'width:100%;box-sizing:border-box;padding:11px 14px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.card};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body};'
                  'margin-bottom:${KolaSpace.sm}',
            },
            value: _search,
            onInput: (v) => setState(() => _search = v),
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-wrap:wrap;gap:6px;'
                  'margin-bottom:${KolaSpace.md}',
            },
            [
              _filterChip('all', 'All'),
              _filterChip('searchable', 'Searchable'),
              _filterChip('processing', 'Processing'),
              _filterChip('failed', 'Failed'),
            ],
          ),
        ],
        if (_docs.isEmpty) _emptyDocs() else _docTable(),
      ]);

  /// A filter chip, or nothing.
  ///
  /// "Failed (0)" and "Processing (0)" are noise on a healthy workspace —
  /// they advertise problems the owner does not have. A chip appears
  /// only when it would actually filter something. `All` always shows,
  /// since it is the reset.
  Component _filterChip(String id, String label) {
    if (id != 'all' && _countFor(id) == 0) {
      return div(const []);
    }
    final active = _statusFilter == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:6px 13px;border-radius:${KolaRadius.pill};'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _statusFilter = id)},
      [Component.text('$label (${_countFor(id)})')],
    );
  }

  Component _docTable() {
    if (isMobile) {
      return div([
        if (_visibleDocs.isEmpty)
          div(
            attributes: {
              'style': 'padding:${KolaSpace.lg};text-align:center;'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};'
                  'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [Component.text('Nothing matches that filter.')],
          )
        else
          for (final d in _visibleDocs) _docCard(d),
      ]);
    }
    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden',
      },
      [
        div(
          attributes: {
            'style': 'display:grid;'
                'grid-template-columns:minmax(200px,3fr) 1.2fr .7fr .8fr 1.4fr;'
                'gap:12px;padding:12px 16px;'
                'border-bottom:1px solid ${KolaVar.border};'
                'font-size:${KolaType.micro};font-weight:700;'
                'letter-spacing:.06em;color:${KolaVar.muted}',
          },
          [
            for (final h in const [
              'TITLE',
              'SOURCE',
              'SECTIONS',
              'UPDATED',
              'STATUS',
            ])
              div([Component.text(h)]),
          ],
        ),
        if (_visibleDocs.isEmpty)
          div(
            attributes: {
              'style': 'padding:${KolaSpace.lg};text-align:center;'
                  'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [Component.text('Nothing matches that filter.')],
          )
        else
          for (final d in _visibleDocs) _docRow(d),
      ],
    );
  }

  Component _docRow(KnowledgeDocument d) {
    final status = _designStatus(d);
    final failed = status == 'failed';
    final paused = !d.feedingEnabled;
    return div(
      attributes: {
        // Red left border on a failed row, amber on a paused one, per the
        // design — the row is findable by shape, not only by the badge's
        // colour. Failed wins when a row is somehow both: a row that
        // can't be searched at all is the more urgent fact.
        'style': 'display:grid;'
            'grid-template-columns:minmax(200px,3fr) 1.2fr .7fr .8fr 1.4fr;'
            'gap:12px;padding:14px 16px;align-items:start;'
            'border-bottom:1px solid ${KolaVar.border};'
            'border-left:3px solid ${failed ? KolaVar.danger : paused ? KolaVar.warning : 'transparent'}',
      },
      [
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};font-weight:600;'
                'color:${paused ? KolaVar.muted : KolaVar.text};'
                'word-break:break-word',
          },
          [Component.text(d.title)],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
          },
          // sourceRef holds a filename when one exists. The server only
          // ever writes sourceType 'paste' today, so this reports what is
          // true rather than guessing an origin.
          [Component.text(d.sourceRef == null ? 'Pasted text' : 'Uploaded file')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'font-family:${KolaFonts.mono}',
          },
          [Component.text('${d.chunkCount}')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
          },
          [Component.text(_shortDate(d.updatedAt))],
        ),
        div([
          _statusBadge(status),
          if (failed && d.errorMessage != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                    'line-height:1.45;margin-top:6px',
              },
              [Component.text(d.errorMessage!)],
            ),
          if (paused)
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.warning};'
                    'line-height:1.45;margin-top:6px',
              },
              [Component.text('Not answering questions')],
            ),
          div(
            attributes: {'style': 'margin-top:8px'},
            [_feedingToggleButton(d)],
          ),
        ]),
      ],
    );
  }

  /// Pause/Resume for one document's [KnowledgeDocument.feedingEnabled].
  ///
  /// Text-labelled rather than an icon: the icon set has an open [eye]
  /// but no eye-off/pause counterpart, and a mismatched pair (real icon
  /// for one state, a bare glyph standing in for the other) is worse
  /// than a plain button both states share.
  Component _feedingToggleButton(KnowledgeDocument d) {
    final busy = _togglingId == d.id;
    final paused = !d.feedingEnabled;
    return button(
      attributes: {
        'type': 'button',
        if (busy) 'disabled': 'disabled',
        'style': 'padding:5px 12px;border-radius:${KolaRadius.pill};'
            'border:1px solid ${KolaVar.border};background:transparent;'
            'color:${KolaVar.mutedStrong};font-family:inherit;'
            'font-size:${KolaType.tiny};font-weight:600;'
            'cursor:${busy ? 'default' : 'pointer'}',
      },
      events: {
        'click': (_) {
          if (!busy) _toggleFeeding(d);
        },
      },
      [Component.text(busy ? 'Working…' : (paused ? 'Resume' : 'Pause'))],
    );
  }

  /// The same row, collapsed to a stacked card. The grid's five columns
  /// (`minmax(200px,3fr)` alone is wider than a 375px phone) don't have
  /// a narrower arrangement that keeps them legible — this is a
  /// different layout, not a squeezed one, same treatment the mobile
  /// audit gave bot_detail_dev_page.dart's errand table.
  Component _docCard(KnowledgeDocument d) {
    final status = _designStatus(d);
    final failed = status == 'failed';
    final paused = !d.feedingEnabled;
    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:12px 14px;'
            'margin-bottom:8px;'
            'border-left:3px solid ${failed ? KolaVar.danger : paused ? KolaVar.warning : 'transparent'}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;gap:10px;'
                'align-items:flex-start;margin-bottom:6px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${paused ? KolaVar.muted : KolaVar.text};'
                    'word-break:break-word;flex:1',
              },
              [Component.text(d.title)],
            ),
            _statusBadge(status),
          ],
        ),
        div(
          attributes: {
            'style': 'display:flex;flex-wrap:wrap;gap:6px 12px;'
                'font-size:${KolaType.tiny};color:${KolaVar.muted}',
          },
          [
            span([Component.text(d.sourceRef == null ? 'Pasted text' : 'Uploaded file')]),
            span([Component.text('${d.chunkCount} section${d.chunkCount == 1 ? '' : 's'}')]),
            span([Component.text(_shortDate(d.updatedAt))]),
          ],
        ),
        if (failed && d.errorMessage != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                  'line-height:1.45;margin-top:6px',
            },
            [Component.text(d.errorMessage!)],
          ),
        if (paused)
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.warning};'
                  'line-height:1.45;margin-top:6px',
            },
            [Component.text('Not answering questions')],
          ),
        div(
          attributes: {'style': 'margin-top:8px'},
          [_feedingToggleButton(d)],
        ),
      ],
    );
  }

  Component _statusBadge(String status) {
    final (tone, label) = switch (status) {
      'searchable' => (KolaTone.positive, 'Searchable'),
      'processing' => (KolaTone.caution, 'Still processing'),
      _ => (KolaTone.negative, "Failed — bot can't see this"),
    };
    return span(
      attributes: {'style': '${tone.badgeCss};white-space:nowrap'},
      [Component.text(label)],
    );
  }

  Component _emptyDocs() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:56px 24px;'
              'text-align:center',
        },
        [
          div(
            attributes: {'style': 'color:${KolaVar.muted};margin-bottom:12px'},
            [kolaIcon(Icons.book, size: 30)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.title};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('No documents yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55',
            },
            [
              Component.text('Upload a file or paste text in "Add knowledge" '
                  'to get started.'),
            ],
          ),
        ],
      );

  // ── Memory Inspector ───────────────────────────────────────────────

  Component _inspectorTab() => div([
        _card([
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Ask kolaa a question a customer might send')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:14px',
            },
            [
              Component.text('See exactly which saved passages it would answer '
                  'from, and how confident the match is.'),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap'},
            [
              input<String>(
                type: InputType.text,
                attributes: {
                  'aria-label': 'Question to test',
                  'placeholder': 'e.g. Do you deliver to Abuja?',
                  'style': 'flex:1 1 260px;padding:11px 14px;'
                      'border-radius:${KolaRadius.md};'
                      'border:1px solid ${KolaVar.border};'
                      'background:${KolaVar.bg};color:${KolaVar.text};'
                      'font-family:inherit;font-size:${KolaType.body}',
                },
                value: _probe,
                onInput: (v) => _probe = v,
              ),
              button(
                attributes: {
                  'type': 'button',
                  if (_probing) 'disabled': 'disabled',
                  'style': 'padding:11px 22px;border-radius:${KolaRadius.md};'
                      'border:none;background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};font-family:inherit;'
                      'font-size:${KolaType.body};font-weight:600;'
                      'cursor:pointer;opacity:${_probing ? '0.65' : '1'}',
                },
                events: {
                  'click': (_) {
                    if (!_probing) _runProbe();
                  },
                },
                [Component.text(_probing ? 'Testing…' : 'Test')],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-wrap:wrap;gap:6px;align-items:center;'
                  'margin-top:12px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                      'margin-right:2px',
                },
                [Component.text('Try:')],
              ),
              for (final (q, _) in _examples)
                button(
                  attributes: {
                    'type': 'button',
                    'style': 'padding:6px 13px;'
                        'border-radius:${KolaRadius.pill};'
                        'border:1px solid ${KolaVar.border};'
                        'background:transparent;color:${KolaVar.mutedStrong};'
                        'font-family:inherit;font-size:${KolaType.small};'
                        'cursor:pointer',
                  },
                  events: {'click': (_) => _runProbe(q)},
                  [Component.text(q)],
                ),
            ],
          ),
        ]),
        if (_probed) _probeResult(),
      ]);

  Component _probeResult() {
    if (_hits.isEmpty) {
      return _card([
        div(
          attributes: {
            'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:6px',
          },
          [Component.text('Nothing in your saved knowledge matches this')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55',
          },
          [
            Component.text('kolaa would not invent an answer here — it would '
                'say it does not know, or hand the conversation to you. Add a '
                'document covering this and test again.'),
          ],
        ),
      ]);
    }
    return _card([
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};font-weight:700;'
              'color:${KolaVar.mutedStrong};margin-bottom:12px',
        },
        [
          Component.text('${_hits.length} passage'
              '${_hits.length == 1 ? '' : 's'} would ground this answer'),
        ],
      ),
      for (final h in _hits)
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};padding:12px 14px;'
                'margin-bottom:8px',
          },
          [
            div(
              attributes: {
                'style': 'display:flex;justify-content:space-between;'
                    'gap:10px;align-items:center;margin-bottom:6px',
              },
              [
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.small};font-weight:600;'
                        'color:${KolaVar.text}',
                  },
                  [Component.text(h.documentTitle)],
                ),
                span(
                  attributes: {
                    'style': '${_confidenceTone(h.similarity).badgeCss};'
                        'white-space:nowrap',
                  },
                  [
                    Component.text(
                      '${KolaConfidenceStyle.fromScore(h.similarity).label}'
                      ' · ${(h.similarity * 100).round()}%',
                    ),
                  ],
                ),
              ],
            ),
            // ── RENDERED, NOT DUMPED ──────────────────────────────
            //
            // This printed the raw chunk with `white-space:pre-wrap`, so
            // an owner inspecting their own memory saw literal ** and
            // "## Sizing" and a stray "---" — the same thing that made
            // the Overview's answers look broken.
            //
            // It is still the EXACT stored passage, which is the whole
            // point of an inspection tool: MiniMarkdown reformats, it
            // never edits. Nothing is summarised or dropped, headings
            // keep their words, and a construct outside the subset falls
            // through as plain text rather than disappearing.
            div(
              attributes: {'style': 'margin-top:2px'},
              MiniMarkdown.render(
                h.content,
                color: KolaVar.muted,
                fontSize: KolaType.small,
              ),
            ),
          ],
        ),
    ]);
  }

  // ── Add knowledge ──────────────────────────────────────────────────

  Component _addTab() => div([
        _pasteCard(),
        _uploadCard(),
        _buildFromCard(),
      ]);

  Component _pasteCard() => _card([
        _cardTitle('Paste it in'),
        _cardSub('Price lists, FAQs, policies, anything a customer might ask '
            'about. Plain text works best — kolaa can use it right away.'),
        textarea(
          attributes: {
            'aria-label': 'Text to save',
            'placeholder': 'Paste your price list, FAQ or policy here…',
            'rows': '8',
            'style': 'width:100%;box-sizing:border-box;padding:12px 14px;'
                'border-radius:${KolaRadius.md};'
                'border:1px solid ${KolaVar.border};'
                'background:${KolaVar.bg};color:${KolaVar.text};'
                'font-family:inherit;font-size:${KolaType.body};'
                'line-height:1.6;resize:vertical',
          },
          onInput: (v) => _pasteText = v,
          [Component.text(_pasteText)],
        ),
        if (_addMessage != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};margin-top:10px;'
                  'line-height:1.5;color:${_duplicateOffer ? KolaVar.warning : KolaVar.mutedStrong}',
            },
            [Component.text(_addMessage!)],
          ),
        div(
          attributes: {'style': 'display:flex;gap:8px;margin-top:14px'},
          [
            button(
              attributes: {
                'type': 'button',
                if (_saving) 'disabled': 'disabled',
                'style': 'padding:11px 18px;border-radius:${KolaRadius.md};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;'
                    'cursor:pointer;opacity:${_saving ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (!_saving) _savePaste();
                },
              },
              [Component.text(_saving ? 'Saving…' : 'Paste text to save')],
            ),
            if (_duplicateOffer)
              button(
                attributes: {
                  'type': 'button',
                  'style': 'padding:11px 18px;'
                      'border-radius:${KolaRadius.md};'
                      'border:1px solid ${KolaVar.border};'
                      'background:transparent;color:${KolaVar.text};'
                      'font-family:inherit;font-size:${KolaType.body};'
                      'font-weight:600;cursor:pointer',
                },
                events: {'click': (_) => _savePaste(allowDuplicate: true)},
                [Component.text('Save it anyway')],
              ),
          ],
        ),
      ]);

  Component _uploadCard() => _card([
        _cardTitle('Upload a file'),
        _cardSub("PDF, Word, Excel or plain text. kolaa extracts the text and "
            "flags anything it couldn't read cleanly."),
        label(
          attributes: {
            'style': 'display:block;border:1px dashed ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:38px 20px;'
                'text-align:center;cursor:pointer',
          },
          [
            div(
              attributes: {'style': 'color:${KolaVar.muted};margin-bottom:10px'},
              [kolaIcon(Icons.paperclip, size: 22)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:4px',
              },
              [Component.text('Drop files here, or click to browse')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
              },
              [Component.text('PDF, DOCX, XLSX, CSV, TXT — up to 20MB each')],
            ),
            input(
              type: InputType.file,
              attributes: {
                'multiple': 'multiple',
                'style': 'display:none',
              },
              events: {
                // THIS IS WHY UPLOAD DID NOTHING.
                //
                // It used to be `(e.target as dynamic).files`, with a
                // comment claiming the pattern was "known to work"
                // because it compiled. It compiled and it threw:
                // dart:js_interop extension types are erased, so a
                // dynamic member access looks for a Dart member named
                // `files` on a plain JS object and raises
                // NoSuchMethodError.
                //
                // Inside a `change` handler that exception is swallowed
                // by the event loop, so the picker opened, a file was
                // chosen, and absolutely nothing happened — no error,
                // no queue row, no progress. The whole staged progress
                // UI below has been correct this entire time and simply
                // never ran.
                //
                // Same root cause as main.dart's `(root as dynamic)
                // .style`, which blanked the app. See dom_files.dart.
                'change': (e) {
                  final target = e.target;
                  if (target == null) return;
                  final files = filesFrom(target as JSObject);
                  if (files.isNotEmpty) _onFiles(files);
                  // Lets the same file be re-picked after a failure.
                  resetFileInput(target);
                },
              },
            ),
          ],
        ),
        // uploadQueue — per-file outcome. Reporting only the first
        // failure would make the other four look like they worked.
        if (_queue.isNotEmpty) ...[
          div(
            attributes: {'style': 'margin-top:14px'},
            [for (final q in _queue) _queueRow(q)],
          ),
          // A finished upload must SAY it finished. Silence after a save
          // reads as "nothing happened", and the owner uploads the same
          // price list again.
          if (_queue.any((q) => q.state == 'done'))
            div(
              attributes: {
                'style': 'display:flex;gap:8px;align-items:center;'
                    'margin-top:10px;font-size:${KolaType.small};'
                    'color:${KolaVar.success}',
              },
              [
                kolaIcon(Icons.check, size: 15, strokeWidth: 2.2),
                Component.text(
                  '${_queue.where((q) => q.state == 'done').length} '
                  'file${_queue.where((q) => q.state == 'done').length == 1 ? '' : 's'} '
                  'added — kolaa can answer from them now. '
                  'See them under Documents.',
                ),
              ],
            ),
        ],
      ]);

  Component _queueRow(_QueuedFile q) {
    final (tone, label) = switch (q.state) {
      'done' => (KolaTone.positive, 'Searchable'),
      'saving' => (KolaTone.caution, uploadStages[q.stage]),
      'failed' => (KolaTone.negative, "Couldn't read this"),
      _ => (KolaTone.neutral, 'Waiting'),
    };
    return div(
      attributes: {
        'style': 'display:flex;gap:10px;align-items:flex-start;'
            'padding:10px 12px;border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};margin-bottom:6px;'
            'border-left:3px solid '
            '${q.state == 'failed' ? KolaVar.danger : 'transparent'}',
      },
      [
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};font-weight:600;'
                    'color:${KolaVar.text};word-break:break-all',
              },
              [Component.text(q.assessment.name)],
            ),
            if (q.message != null)
              div(
                attributes: {
                  'style': 'font-size:${KolaType.tiny};'
                      'color:${KolaVar.muted};line-height:1.45;margin-top:4px',
                },
                [Component.text(q.message!)],
              ),
          ],
        ),
        span(
          attributes: {'style': '${tone.badgeCss};white-space:nowrap'},
          [Component.text(label)],
        ),
      ],
    );
  }

  /// Turns the catalog into a document kolaa can answer from.
  ///
  /// ── WHY THIS IS COMPOSED HERE AND NOT ON THE SERVER ────────────────
  ///
  /// It writes a normal knowledge document through the normal endpoint,
  /// so it is chunked, embedded and cited exactly like something the
  /// owner pasted. No second retrieval path, no special-casing at answer
  /// time, and if the wording is wrong the owner can open it and edit it
  /// like any other document.
  ///
  /// ── IT REPEATS THE NULL RULES, BECAUSE THIS IS TEXT A BOT WILL QUOTE ─
  ///
  /// A null price becomes "price on request", never ₦0. A null stock
  /// becomes "made to order", never "out of stock". Getting that wrong
  /// here would be worse than on a screen — a screen is read by the
  /// owner, this is read back to a customer.
  Future<void> _generateFrom(String key) async {
    setState(() {
      _generating = key;
      _addMessage = null;
    });

    try {
      final products = await component.client.product.listProducts(
        component.accessToken,
        component.workspaceId,
        includeArchived: false,
      );

      final buffer = StringBuffer();
      final isInventory = key == 'inventory';
      buffer.writeln(
        isInventory
            ? 'What we have in stock right now.'
            : 'What we sell, with prices.',
      );
      buffer.writeln();

      for (final p in products) {
        buffer.write('- ${p.name}');
        if (p.category != null) buffer.write(' (${p.category})');
        buffer.writeln();

        if (!isInventory) {
          buffer.writeln(
            p.priceMinor == null
                ? '  Price: on request — ask us for a quote.'
                : '  Price: ${Money.format(p.priceMinor!, p.priceCurrency)}'
                    '${p.priceUnit ?? ''}',
          );
          if (p.description != null && p.description!.trim().isNotEmpty) {
            buffer.writeln('  ${p.description!.trim()}');
          }
        }

        final stock = p.stock;
        buffer.writeln(
          stock == null
              ? '  Made to order — not something we keep in stock.'
              : stock == 0
                  ? '  Currently out of stock.'
                  : stock <= p.lowStockThreshold
                      ? '  Only a few left.'
                      : '  In stock.',
        );
        if (p.sku != null) buffer.writeln('  Reference: ${p.sku}');
        buffer.writeln();
      }

      final title = isInventory ? 'Stock levels' : 'Product catalog';

      // ── REPLACE THE PREVIOUS BUILD, DO NOT STACK ANOTHER COPY ───────
      //
      // This used to pass `allowDuplicate: true` with a comment saying
      // re-generating "SHOULD replace". It did not replace. allowDuplicate
      // only switches OFF the identical-content refusal; the write is
      // still an insert, so every press of this button left another
      // "Product catalog" behind. Three presses, three live documents
      // with the same content hash, all of them searchable.
      //
      // That is worse than clutter on the Documents tab. Retrieval pulls
      // the top six passages by relevance, and identical copies score
      // identically — so the duplicates crowd out the OTHER documents
      // that would have made the answer better, and kolaa keeps answering
      // from the same text no matter what else has been uploaded.
      //
      // updateDocument reindexes in place: same row id, old chunks
      // deleted, new ones embedded. Which is what "re-generate" meant.
      final previous = [
        for (final d in _docs)
          if (d.title == title && d.id != null) d,
      ];

      if (previous.isEmpty) {
        await component.client.knowledge.addDocument(
          component.accessToken,
          component.workspaceId,
          title,
          buffer.toString(),
          allowDuplicate: false,
        );
      } else {
        await component.client.knowledge.updateDocument(
          component.accessToken,
          component.workspaceId,
          previous.first.id!,
          title,
          buffer.toString(),
        );
        // Copies left behind by the old behaviour. Cleared on the next
        // re-generate rather than requiring the owner to find and delete
        // them by hand — they never chose to create these.
        for (final stale in previous.skip(1)) {
          try {
            await component.client.knowledge.deleteDocument(
              component.accessToken,
              component.workspaceId,
              stale.id!,
            );
          } catch (_) {
            // A leftover duplicate is untidy, not broken.
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _generating = null;
        _addMessage =
            'Built from ${products.length} products. kolaa can answer from '
            'this now.';
        _tab = 'documents';
      });
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = null;
        _addMessage = ErrorText.of(e);
      });
    }
  }

  Component _buildFromCard() => _card([
        _cardTitle("Build from what's already here"),
        _cardSub('Turn your catalog, inventory and sales history into '
            'knowledge kolaa can answer from — no re-typing.'),
        for (final (key, label, detail, icon) in _dataSources)
          _dataSourceRow(key, label, detail, icon),
      ]);

  Component _dataSourceRow(
    String key,
    String label,
    String detail,
    String icon,
  ) {
    // ENABLED means "there is something to generate FROM", which is not
    // the same question as "is the capability released".
    //
    // This originally gated on Features.commerceCatalog and was
    // therefore always enabled, because the flag said `released` while
    // no products table existed. Then it was hardcoded false, because
    // there was genuinely nothing to build from. Now there is: the
    // catalog is real, so the precondition is a COUNT.
    //
    // A flag was always the wrong signal for a button whose precondition
    // is data.
    //
    // 'sales' stays unavailable on its own terms — there is no orders
    // table, so sales history has nothing behind it regardless of how
    // many products exist.
    final count = _productCount ?? 0;
    final available = key == 'sales' ? false : count > 0;

    // The design's own detail line carries the count: "6 products —
    // prices, stock, descriptions". [detail] is the tail of that.
    final subtitle = available
        ? '$count product${count == 1 ? '' : 's'} — $detail'
        : (key == 'sales'
            ? 'Nothing to build from yet — this needs sales to have '
                'happened.'
            : 'Nothing to build from yet — this needs your catalog.');

    final icon_ = div(
      attributes: {
        'style': 'width:34px;height:34px;flex:none;'
            'border-radius:${KolaRadius.md};'
            'background:${KolaVar.tintSurface(2)};'
            'color:${KolaVar.tintIcon(2)};display:flex;'
            'align-items:center;justify-content:center',
      },
      [kolaIcon(icon, size: 17)],
    );
    final text = div(attributes: {'style': 'flex:1;min-width:0'}, [
      div(
        attributes: {
          'style': 'font-size:${KolaType.body};font-weight:700;'
              'color:${KolaVar.text}',
        },
        [Component.text(label)],
      ),
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.5;margin-top:2px',
        },
        [Component.text(subtitle)],
      ),
    ]);
    final action = button(
      attributes: {
        'type': 'button',
        if (!available || _generating != null) 'disabled': 'disabled',
        'style': 'padding:9px 15px;border-radius:${KolaRadius.pill};'
            'border:none;font-family:inherit;'
            'font-size:${KolaType.small};font-weight:600;'
            'cursor:${available ? 'pointer' : 'default'};'
            'background:'
            '${available ? KolaVar.accentFill : KolaVar.pill};'
            'color:${available ? KolaVar.accentText : KolaVar.muted};'
            '${isMobile ? 'width:100%' : 'flex:none'}',
      },
      events: {
        'click': (_) {
          if (available && _generating == null) _generateFrom(key);
        },
      },
      [
        Component.text(
          _generating == key ? 'Building…' : 'Generate knowledge',
        ),
      ],
    );

    // The row and the button used to sit side by side, `align-items:
    // center` against each other. On a phone the button's fixed content
    // width (~150px) left barely 170px for label + subtitle, so both
    // wrapped to several lines while the button sat vertically centred
    // beside a text block several times its own height — legible, but
    // not "aligned" in any sense a normal mobile catalog/list uses.
    // Stacking icon+text above a full-width button, the same shape
    // knowledge_page.dart's own document table and bot_detail_dev_page's
    // errand table already adopted for mobile, reads as one coherent
    // card instead.
    if (isMobile) {
      return div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:14px;margin-bottom:8px;'
              'opacity:${available ? '1' : '0.7'}',
        },
        [
          div(
            attributes: {'style': 'display:flex;gap:12px;align-items:center;margin-bottom:12px'},
            [icon_, text],
          ),
          action,
        ],
      );
    }

    return div(
      attributes: {
        'style': 'display:flex;gap:12px;align-items:center;'
            'padding:14px;border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};margin-bottom:8px;'
            'opacity:${available ? '1' : '0.7'}',
      },
      [icon_, text, action],
    );
  }

  // ── Shared ─────────────────────────────────────────────────────────

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md};margin-bottom:${KolaSpace.smd}',
        },
        children,
      );

  Component _cardTitle(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:4px',
        },
        [Component.text(t)],
      );

  Component _cardSub(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.55;margin-bottom:14px',
        },
        [Component.text(t)],
      );

  Component _skeleton() => div(
        attributes: {
          'style': 'height:220px;border-radius:${KolaRadius.lg};'
              'border:1px solid ${KolaVar.border};background:${KolaVar.card}',
        },
        const [],
      );

  Component _errorState() => _card([
        _cardTitle('Could not load your documents'),
        _cardSub('This is a connection problem. Nothing was deleted.'),
        div(
          attributes: {
            'style': 'font-family:${KolaFonts.mono};'
                'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:12px;word-break:break-word',
          },
          [Component.text(_loadError ?? '')],
        ),
        button(
          attributes: {
            'type': 'button',
            'style': 'padding:9px 15px;border-radius:${KolaRadius.md};'
                'border:none;background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-family:inherit;'
                'font-size:${KolaType.body};font-weight:600;cursor:pointer',
          },
          events: {'click': (_) => _load()},
          [Component.text('Try again')],
        ),
      ]);
}
