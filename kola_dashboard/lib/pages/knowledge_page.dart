// knowledge_page.dart — the Knowledge Center. What kola has been taught,
// and a way to check what it would actually retrieve.
//
// REBUILT on the new design system. The previous version of this file
// used KolaDashboardColors throughout; nothing here does.
//
// ── TWO TABS, BOTH REAL ──────────────────────────────────────────────
//
//   Documents        → listDocuments / addDocument / deleteDocument
//   Memory inspector → searchMemory
//
// The inspector is not a debug tool bolted on. It is the reason
// KnowledgeSearchHit exists: an owner can type a question a customer
// actually asked and see precisely which passages would ground the
// answer, with real similarity scores. That is what makes the bot's
// answers checkable rather than something to be trusted on faith.
//
// ── WHAT THE DESIGN SHOWS THAT IS NOT BUILT ──────────────────────────
//
//   UPLOAD A FILE — the picker accepts ANY file. What it cannot do is
//     extract text from every one: PDF, Word, Excel, images and audio
//     all need server-side extraction that does not exist yet. So every
//     file is IDENTIFIED (see services/file_intake.dart) and the owner
//     is told precisely what it is and what to do — never accepted and
//     silently mangled into binary garbage stored as knowledge.
//
//   BUILD FROM WHAT'S ALREADY HERE — offers to generate knowledge from
//     the product catalog. There is no catalog, no commerce backend and
//     no endpoint. Omitted entirely.
//
// ── DUPLICATES ARE A PROMPT, NOT AN ERROR ────────────────────────────
//
// addDocument refuses an exact duplicate and names the existing
// document, and takes allowDuplicate to override. That round trip is
// deliberate — see the endpoint's own header — so this page offers
// "save it anyway" rather than presenting a dead end.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' as web;
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/file_intake.dart';
import '../theme.dart';

enum _Tab { documents, inspector }

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

class _KnowledgePageState extends State<KnowledgePage> {
  _Tab _tab = _Tab.documents;

  bool _loading = true;
  String? _error;
  List<KnowledgeDocument> _docs = const [];

  String _search = '';
  String _statusFilter = 'all';

  // Add form
  String _newTitle = '';
  String _newText = '';
  bool _saving = false;
  String? _addMessage;
  bool _duplicateOffer = false;

  /// What the last picked file was judged to be. Drives the notice under
  /// the picker — see file_intake.dart on why every file is classified
  /// rather than optimistically read.
  FileAssessment? _picked;

  // Inspector
  String _probe = '';
  bool _probing = false;
  bool _probed = false;
  List<KnowledgeSearchHit> _hits = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await component.client.knowledge.listDocuments(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _add({bool allowDuplicate = false}) async {
    final title = _newTitle.trim();
    final text = _newText.trim();
    if (text.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _addMessage = null;
      _duplicateOffer = false;
    });

    try {
      await component.client.knowledge.addDocument(
        component.accessToken,
        component.workspaceId,
        title.isEmpty ? 'Untitled note' : title,
        text,
        allowDuplicate: allowDuplicate,
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _newTitle = '';
        _newText = '';
        _addMessage = 'Saved. kola can answer from this within a few seconds.';
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _saving = false;
        _addMessage = msg;
        // The endpoint refuses exact duplicates by design and names the
        // existing document. That is not a failure — offer the override
        // it was built to accept.
        _duplicateOffer = msg.toLowerCase().contains('already');
      });
    }
  }

  /// Classifies a picked file, and reads it only if that is safe.
  ///
  /// Anything not readable in the browser is REPORTED, not attempted —
  /// handing a zip or a PDF to a text reader stores binary garbage as
  /// business knowledge, and it looks like it worked.
  Future<void> _pickFile(web.File file) async {
    final assessment = await FileIntake.assess(file);
    if (!mounted) return;
    setState(() {
      _picked = assessment;
      _addMessage = null;
      _duplicateOffer = false;
    });

    if (!assessment.canIngestNow) return;

    try {
      final text = await FileIntake.readText(file);
      if (!mounted) return;
      setState(() {
        _newText = text;
        if (_newTitle.trim().isEmpty) _newTitle = assessment.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _addMessage = e.toString());
    }
  }

  Future<void> _delete(KnowledgeDocument doc) async {
    try {
      await component.client.knowledge.deleteDocument(
        component.accessToken,
        component.workspaceId,
        doc.id!,
      );
      if (!mounted) return;
      setState(() => _docs = [for (final d in _docs) if (d.id != doc.id) d]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not delete that document: $e');
    }
  }

  Future<void> _probeMemory() async {
    final q = _probe.trim();
    if (q.isEmpty || _probing) return;
    setState(() {
      _probing = true;
      _probed = true;
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
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _probing = false;
        _error = e.toString();
      });
    }
  }

  List<KnowledgeDocument> get _visible {
    final q = _search.trim().toLowerCase();
    return [
      for (final d in _docs)
        if ((_statusFilter == 'all' || d.status == _statusFilter) &&
            (q.isEmpty || d.title.toLowerCase().contains(q)))
          d,
    ];
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'max-width:1040px;margin:0 auto;width:100%;'
            'padding:28px 20px 40px;display:flex;flex-direction:column;gap:20px',
      },
      [
        _header(),
        if (_error != null) _errorBanner(),
        if (_tab == _Tab.documents) ..._documentsTab() else _inspectorTab(),
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:12px'},
        [
          h1(
            attributes: {
              'style': 'font-family:${KolaFonts.display};font-size:${KolaType.h2};'
                  'font-weight:700;color:${KolaVar.text};margin:0',
            },
            [Component.text('Knowledge')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.5;max-width:620px',
            },
            [
              Component.text(
                'What kola answers from. It cites these documents instead of '
                'guessing — anything not in here, it will not invent.',
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'display:flex;gap:4px;'
                  'border-bottom:1px solid ${KolaVar.border}',
            },
            [
              _tabButton(_Tab.documents, 'Documents', _docs.length),
              if (component.gate.isEnabled(Features.memoryInspector))
                _tabButton(_Tab.inspector, 'Memory inspector', 0),
            ],
          ),
        ],
      );

  Component _tabButton(_Tab tab, String label, int count) {
    final active = _tab == tab;
    return button(
      attributes: {
        'class': 'kola-pressable',
        'type': 'button',
        'aria-selected': active ? 'true' : 'false',
        'style': 'background:transparent;border:none;font-family:inherit;'
            'padding:9px 14px;font-size:${KolaType.body};font-weight:600;'
            'border-bottom:2px solid ${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accent : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _tab = tab)},
      [Component.text(count > 0 ? '$label ($count)' : label)],
    );
  }

  // ── Documents ───────────────────────────────────────────────────────

  List<Component> _documentsTab() => [
        _addPanel(),
        if (_loading)
          _skeleton()
        else if (_docs.isEmpty)
          _emptyDocs()
        else ...[
          _filters(),
          _table(),
        ],
      ];

  Component _addPanel() => div(
        attributes: {
          'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:18px',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Add knowledge')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'margin-bottom:14px;line-height:1.5',
            },
            [
              // Says what it takes, rather than offering a file picker
              // that rejects the formats people reach for first.
              Component.text(
                'Paste a price list, FAQ, returns policy or anything else kola '
                'should know. Text only for now — PDF and Word need parsing '
                'that is not built yet, so copy the text across.',
              ),
            ],
          ),
          input(
            type: InputType.text,
            attributes: {
              'aria-label': 'Document title',
              'placeholder': 'Title — e.g. "Returns policy"',
              'value': _newTitle,
              'style': _fieldCss,
            },
            events: {
              'input': (e) => _newTitle = (e.target as dynamic).value as String? ?? '',
            },
          ),
          textarea(
            attributes: {
              'aria-label': 'Document text',
              'placeholder': 'Paste the text here…',
              'rows': '6',
              'style': '$_fieldCss;resize:vertical;line-height:1.6;'
                  'min-height:120px;margin-top:10px',
            },
            events: {
              'input': (e) => _newText = (e.target as dynamic).value as String? ?? '',
            },
            [Component.text(_newText)],
          ),
          _filePicker(),
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:10px;'
                  'margin-top:12px;flex-wrap:wrap',
            },
            [
              button(
                attributes: {
                  'class': 'kola-pressable',
                  'type': 'button',
                  'style': 'background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};border:none;'
                      'border-radius:${KolaRadius.pill};padding:9px 18px;'
                      'font-size:${KolaType.small};font-weight:600;'
                      'font-family:inherit;${_saving ? 'opacity:0.6' : ''}',
                },
                events: {'click': (_) => _add()},
                [Component.text(_saving ? 'Saving…' : 'Teach kola this')],
              ),
              if (_duplicateOffer)
                button(
                  attributes: {
                    'class': 'kola-pressable',
                    'type': 'button',
                    'style': 'background:transparent;'
                        'border:1px solid ${KolaVar.border};'
                        'color:${KolaVar.text};'
                        'border-radius:${KolaRadius.pill};padding:9px 16px;'
                        'font-size:${KolaType.small};font-weight:600;'
                        'font-family:inherit',
                  },
                  events: {'click': (_) => _add(allowDuplicate: true)},
                  [Component.text('Save it anyway')],
                ),
            ],
          ),
          if (_addMessage != null)
            div(
              attributes: {
                'style': 'margin-top:10px;font-size:${KolaType.tiny};'
                    'line-height:1.5;'
                    'color:${_duplicateOffer ? KolaVar.warning : KolaVar.muted}',
              },
              [Component.text(_addMessage!)],
            ),
        ],
      );

  Component _filePicker() {
    final a = _picked;
    return div(
      attributes: {'style': 'margin-top:12px'},
      [
        label(
          attributes: {
            'class': 'kola-pressable',
            'style': 'display:inline-flex;align-items:center;gap:8px;'
                'border:1px dashed ${KolaVar.border};color:${KolaVar.mutedStrong};'
                'border-radius:${KolaRadius.md};padding:10px 16px;'
                'font-size:${KolaType.small};font-weight:600',
          },
          [
            kolaIcon(Icons.paperclip, size: 15),
            Component.text('Choose a file'),
            // Accepts EVERYTHING on purpose. Filtering by extension here
            // would silently hide a file the owner can see on their disk,
            // and they would conclude the product is broken. Better to
            // accept it, identify it, and explain.
            input(
              type: InputType.file,
              attributes: {'style': 'display:none', 'aria-label': 'Choose a file'},
              events: {
                'change': (e) {
                  final files = (e.target as dynamic).files;
                  if (files == null || files.length == 0) return;
                  _pickFile(files.item(0) as web.File);
                },
              },
            ),
          ],
        ),
        if (a != null) _pickedNotice(a),
      ],
    );
  }

  Component _pickedNotice(FileAssessment a) {
    final tone = a.canIngestNow
        ? KolaTone.positive
        : (a.kind == FileKind.rejected ? KolaTone.negative : KolaTone.caution);

    return div(
      attributes: {
        'style': 'margin-top:10px;padding:10px 14px;'
            'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;flex-wrap:wrap;'
                'margin-bottom:6px',
          },
          [
            span(
              attributes: {
                'style': 'font-size:${KolaType.tiny};font-weight:600;'
                    'color:${KolaVar.text};overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap;max-width:260px',
              },
              [Component.text(a.name)],
            ),
            span(attributes: {'style': tone.badgeCss}, [Component.text(a.label)]),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                'line-height:1.5',
          },
          [Component.text(a.explanation)],
        ),
      ],
    );
  }

  static const _fieldCss = 'width:100%;box-sizing:border-box;'
      'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
      'border-radius:${KolaRadius.md};padding:10px 14px;'
      'color:${KolaVar.text};font-family:inherit;'
      'font-size:${KolaType.body};outline:none';

  Component _filters() => div(
        attributes: {
          'style': 'display:flex;gap:10px;align-items:center;flex-wrap:wrap',
        },
        [
          input(
            type: InputType.text,
            attributes: {
              'aria-label': 'Search documents',
              'placeholder': 'Search titles…',
              'style': 'flex:1;min-width:180px;box-sizing:border-box;'
                  'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.pill};padding:9px 16px;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.small};outline:none',
            },
            events: {
              'input': (e) => setState(() =>
                  _search = (e.target as dynamic).value as String? ?? ''),
            },
          ),
          for (final f in const ['all', 'indexed', 'pending'])
            button(
              attributes: {
                'class': 'kola-pressable',
                'type': 'button',
                'style': 'border-radius:${KolaRadius.pill};padding:8px 14px;'
                    'font-size:${KolaType.micro};font-weight:600;'
                    'font-family:inherit;'
                    'border:1px solid ${KolaVar.border};'
                    'background:${_statusFilter == f ? KolaVar.pill : 'transparent'};'
                    'color:${_statusFilter == f ? KolaVar.text : KolaVar.muted}',
              },
              events: {'click': (_) => setState(() => _statusFilter = f)},
              [Component.text(f == 'all' ? 'All' : f)],
            ),
        ],
      );

  Component _table() {
    final rows = _visible;
    if (rows.isEmpty) {
      return div(
        attributes: {
          'style': 'padding:24px;text-align:center;'
              'font-size:${KolaType.small};color:${KolaVar.muted}',
        },
        [Component.text('No documents match that.')],
      );
    }

    return div(
      attributes: {
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};overflow:hidden;'
            'background:${KolaVar.card}',
      },
      [
        for (var i = 0; i < rows.length; i++) _row(rows[i], i > 0),
      ],
    );
  }

  Component _row(KnowledgeDocument d, bool divider) {
    final tone = switch (d.status) {
      'indexed' => KolaTone.positive,
      'pending' => KolaTone.caution,
      'failed' => KolaTone.negative,
      _ => KolaTone.neutral,
    };

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;'
            'padding:13px 16px;flex-wrap:wrap;'
            '${divider ? 'border-top:1px solid ${KolaVar.border}' : ''}',
      },
      [
        div(
          attributes: {'style': 'color:${KolaVar.muted};display:flex;flex:none'},
          [kolaIcon(Icons.book, size: 15)],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:160px'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${KolaVar.text};overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(d.title)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              [
                // chunkCount is what the design calls "Sections" — the
                // number of separately-searchable passages, which is the
                // number that actually affects retrieval.
                Component.text(
                  '${_sourceLabel(d.sourceType)} · '
                  '${d.chunkCount} ${d.chunkCount == 1 ? 'section' : 'sections'} · '
                  '${_shortDate(d.updatedAt)}',
                ),
              ],
            ),
          ],
        ),
        span(attributes: {'style': tone.badgeCss}, [Component.text(d.status)]),
        button(
          attributes: {
            'class': 'kola-pressable',
            'type': 'button',
            'aria-label': 'Delete ${d.title}',
            'style': 'flex:none;background:transparent;border:none;'
                'color:${KolaVar.muted};font-family:inherit;'
                'font-size:${KolaType.micro};font-weight:600',
          },
          events: {'click': (_) => _delete(d)},
          [Component.text('Delete')],
        ),
      ],
    );
  }

  Component _emptyDocs() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:32px 24px;'
              'text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.lead};font-weight:600;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('No documents yet')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:440px;margin:0 auto',
            },
            [
              Component.text(
                'Until kola is taught something, it can only fall back on '
                'general answers. One price list or returns policy changes '
                'that immediately.',
              ),
            ],
          ),
        ],
      );

  // ── Inspector ───────────────────────────────────────────────────────

  Component _inspectorTab() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:14px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:620px',
            },
            [
              Component.text(
                'Type a question a customer might ask and see exactly which '
                'passages kola would answer from, and how strong each match '
                'is. Nothing is sent to a customer — this only reads memory.',
              ),
            ],
          ),
          div(
            attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap'},
            [
              input(
                type: InputType.text,
                attributes: {
                  'aria-label': 'Test question',
                  'placeholder': 'e.g. Can I return this after a week?',
                  'style': 'flex:1;min-width:200px;box-sizing:border-box;'
                      'background:${KolaVar.card};'
                      'border:1px solid ${KolaVar.border};'
                      'border-radius:${KolaRadius.pill};padding:10px 16px;'
                      'color:${KolaVar.text};font-family:inherit;'
                      'font-size:${KolaType.body};outline:none',
                },
                events: {
                  'input': (e) =>
                      _probe = (e.target as dynamic).value as String? ?? '',
                  'keydown': (e) {
                    if ((e as dynamic).key == 'Enter') _probeMemory();
                  },
                },
              ),
              button(
                attributes: {
                  'class': 'kola-pressable',
                  'type': 'button',
                  'style': 'background:${KolaVar.accentFill};'
                      'color:${KolaVar.accentText};border:none;'
                      'border-radius:${KolaRadius.pill};padding:10px 20px;'
                      'font-size:${KolaType.small};font-weight:600;'
                      'font-family:inherit',
                },
                events: {'click': (_) => _probeMemory()},
                [Component.text('Test')],
              ),
            ],
          ),
          if (_probing)
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:80px;border-radius:${KolaRadius.md}'},
              [],
            )
          else if (_probed && _hits.isEmpty)
            div(
              attributes: {
                'style': 'background:${KolaVar.card};'
                    'border:1px solid ${KolaVar.border};'
                    'border-radius:${KolaRadius.lg};padding:16px;'
                    'font-size:${KolaType.small};color:${KolaVar.muted};'
                    'line-height:1.6',
              },
              [
                Component.text(
                  'Nothing in memory matches closely enough. A customer asking '
                  'this today would get a general answer, not one from your '
                  'documents — which is exactly the gap worth filling.',
                ),
              ],
            )
          else
            for (final h in _hits) _hitCard(h),
        ],
      );

  Component _hitCard(KnowledgeSearchHit h) {
    final c = KolaConfidenceStyle.fromScore(h.similarity);
    return div(
      attributes: {
        'style': 'background:${KolaVar.card};border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.md};padding:14px',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;align-items:center;gap:8px;'
                'margin-bottom:8px;flex-wrap:wrap',
          },
          [
            span(
              attributes: {
                'style': 'font-size:${KolaType.micro};font-weight:600;'
                    'color:${KolaVar.text}',
              },
              [Component.text(h.documentTitle)],
            ),
            span(
              attributes: {
                'style': 'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              [Component.text('section ${h.chunkIndex + 1}')],
            ),
            span(attributes: {'style': 'flex:1'}, []),
            span(
              attributes: {'style': _confTone(c).badgeCss},
              [Component.text(c.label)],
            ),
            span(
              attributes: {
                'style': 'font-family:${KolaFonts.mono};'
                    'font-size:${KolaType.micro};color:${KolaVar.muted}',
              },
              [Component.text(h.similarity.toStringAsFixed(2))],
            ),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.body};color:${KolaVar.mutedStrong};'
                'line-height:1.6;white-space:pre-wrap;overflow-wrap:anywhere',
          },
          [Component.text(h.content)],
        ),
      ],
    );
  }

  static KolaTone _confTone(KolaConfidence c) => switch (c) {
        KolaConfidence.high => KolaTone.positive,
        KolaConfidence.medium => KolaTone.caution,
        KolaConfidence.low => KolaTone.negative,
      };

  // ── Shared ──────────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
        [
          for (var i = 0; i < 4; i++)
            div(
              classes: 'kola-skel',
              attributes: {'style': 'height:56px;border-radius:${KolaRadius.md}'},
              [],
            ),
        ],
      );

  Component _errorBanner() => div(
        attributes: {
          'role': 'alert',
          'style': 'padding:10px 14px;background:${KolaVar.dangerBg};'
              'color:${KolaVar.danger};border:1px solid ${KolaVar.danger};'
              'border-radius:${KolaRadius.md};font-size:${KolaType.small}',
        },
        [Component.text(_error!)],
      );

  static String _sourceLabel(String sourceType) => switch (sourceType) {
        'paste' => 'Pasted',
        'upload' => 'Uploaded file',
        'url' => 'Web page',
        _ => sourceType,
      };

  static String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
