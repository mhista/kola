// catalog_import_page.dart — Kola Catalog Import.dc.html.
//
// ── WHAT THE FIRST VERSION GOT WRONG ─────────────────────────────────
//
// Import used to be one button on the Catalog header that went straight
// from "file chosen" to "creating products". The export is a whole
// screen with three methods and, critically, a MAPPING STEP in between:
//
//   upload → mapping → result
//
// Skipping the mapping step is not a shortcut, it is the dangerous part.
// A column called "cat" might be Category or might be a cat-food SKU
// prefix; "amount" might be price or might be quantity. Guessing
// silently writes wrong prices into a live catalog, and the owner finds
// out when a customer is quoted ₦42 for something that costs ₦42,000.
//
// So kola proposes, colour-coded by how sure it is, and the owner
// confirms. ProductCsv already knew all of this — confident alias
// matches, fuzzy guesses, unrecognised columns — and simply never
// showed it.
//
// ── THE THREE METHODS, AND WHICH ONE IS REAL ─────────────────────────
//
//   File            REAL. CSV today; the export also lists XLSX and PDF.
//   Photo of a list REAL DESIGN, NOT BUILT. Reading a handwritten price
//                   list needs vision — commerce.photo_capture, locked,
//                   R2. Shown and honest rather than hidden, because it
//                   is a promise the design makes.
//   From another app NOT POSSIBLE HERE, and this is worth stating
//                   plainly. The export shows kola detecting Square POS
//                   and Loyverse "on this device". A browser cannot
//                   enumerate installed applications — that is a
//                   deliberate platform restriction, not a gap in our
//                   work. On the mobile app it is achievable; on the web
//                   dashboard the honest equivalent is "export from that
//                   app, then bring the file here", which is what this
//                   tab says.

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/dom_files.dart';
import '../services/error_text.dart';
import '../services/file_intake.dart';
import '../services/money.dart';
import '../services/product_csv.dart';
import '../theme.dart';

class CatalogImportPage extends StatefulComponent {
  const CatalogImportPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<CatalogImportPage> createState() => _CatalogImportPageState();
}

/// The export's `step`, plus a running state it does not model because a
/// static export has nothing to wait for.
enum _Step { upload, mapping, running, result }

class _CatalogImportPageState extends State<CatalogImportPage> {
  /// 'file' | 'photo' | 'device'
  String _method = 'file';
  _Step _step = _Step.upload;

  String? _fileName;
  String _raw = '';
  CsvParseResult? _parsed;

  /// Column index → field id, or null for "do not import". Set when the
  /// owner corrects kola's proposal.
  final Map<int, String?> _overrides = {};

  int _done = 0;
  int _total = 0;
  List<String> _problems = [];
  String? _error;

  // ── Reading ─────────────────────────────────────────────────────────

  Future<void> _onFile(web.File file) async {
    setState(() {
      _error = null;
      _fileName = file.name;
    });

    final assessment = await FileIntake.assess(file);
    if (!assessment.canIngestNow) {
      setState(() => _error = assessment.explanation);
      return;
    }

    try {
      final text = await FileIntake.readText(file);
      final parsed = ProductCsv.parse(text);
      if (!mounted) return;
      setState(() {
        _raw = text;
        _overrides.clear();
        _parsed = parsed;
        _step = _Step.mapping;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorText.of(e));
    }
  }

  /// Re-parses with the owner's corrections applied.
  void _setOverride(int index, String? field) {
    _overrides[index] = field;
    setState(() => _parsed = ProductCsv.parse(_raw, overrides: _overrides));
  }

  // ── Importing ───────────────────────────────────────────────────────

  Future<void> _run() async {
    final parsed = _parsed;
    if (parsed == null) return;

    final problems = <String>[
      for (final s in parsed.skipped) 'Row ${s.row}: ${s.reason}',
    ];

    setState(() {
      _step = _Step.running;
      _done = 0;
      _total = parsed.rows.length;
      _problems = problems;
    });

    for (final row in parsed.rows) {
      try {
        final product = await component.client.product.createProduct(
          component.accessToken,
          component.workspaceId,
          row.name,
          description: row.description,
          archetype: row.archetype ?? 'packaged',
          sku: row.sku,
          category: row.category,
          priceMinor: row.price == null ? null : Money.parse(row.price!, 'NGN'),
          priceUnit: row.unit,
          costMinor: row.cost == null ? null : Money.parse(row.cost!, 'NGN'),
          stock: row.stock == null ? null : int.tryParse(row.stock!),
          lowStockThreshold:
              row.lowStock == null ? 5 : (int.tryParse(row.lowStock!) ?? 5),
        );

        if (row.imageUrl != null && product.id != null) {
          try {
            final media = await component.client.product.importMediaFromUrl(
              component.accessToken,
              component.workspaceId,
              product.id!,
              row.imageUrl!,
            );
            if (media == null) {
              problems.add(
                'Row ${row.rowNumber}: saved, but the photo link did not load',
              );
            }
          } catch (_) {
            problems.add(
              'Row ${row.rowNumber}: saved, but the photo link did not load',
            );
          }
        }
      } catch (e) {
        problems.add('Row ${row.rowNumber} (${row.name}): ${ErrorText.of(e)}');
      }

      if (!mounted) return;
      setState(() {
        _done++;
        _problems = [...problems];
      });
    }

    if (!mounted) return;
    setState(() => _step = _Step.result);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:820px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          Link(
            to: '/catalog',
            attributes: {
              'style': 'display:inline-flex;align-items:center;gap:6px;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'color:${KolaVar.accent};text-decoration:none;'
                  'padding:6px 10px;border-radius:${KolaRadius.md};'
                  'margin-bottom:10px',
            },
            children: [
              kolaIcon(Icons.arrowRight,
                  size: 14, extraStyle: 'transform:rotate(180deg)'),
              Component.text('Catalog'),
            ],
          ),
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Import your catalog')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'margin-bottom:${KolaSpace.md}',
            },
            [Component.text('Pick whichever path matches what you already '
                'have.')],
          ),

          // Method tabs stay visible during upload, and disappear once an
          // import is under way — switching method mid-run would abandon
          // work already committed to the database.
          if (_step == _Step.upload)
            div(
              attributes: {
                'style': 'display:inline-flex;gap:4px;padding:4px;'
                    'border-radius:${KolaRadius.pill};'
                    'background:${KolaVar.pill};margin-bottom:${KolaSpace.md}',
              },
              [
                _tab('file', 'File (CSV)'),
                _tab('photo', 'Photo of a list'),
                _tab('device', 'From another app'),
              ],
            ),

          switch (_step) {
            _Step.upload => _uploadStep(),
            _Step.mapping => _mappingStep(),
            _Step.running => _runningStep(),
            _Step.result => _resultStep(),
          },
        ],
      );

  Component _tab(String id, String label) {
    final active = _method == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:9px 16px;border-radius:${KolaRadius.pill};'
            'border:none;cursor:pointer;font-family:inherit;'
            'font-size:${KolaType.small};font-weight:600;'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.muted}',
      },
      events: {'click': (_) => setState(() => _method = id)},
      [Component.text(label)],
    );
  }

  // ── Step 1: choose a source ─────────────────────────────────────────

  Component _uploadStep() => switch (_method) {
        'photo' => _notBuilt(
            'Reading a photo of a price list is not built yet',
            'It needs kola to read handwriting and printed columns from an '
                'image, and get it right often enough that you are not '
                'checking every row. Until that is true, a spreadsheet is '
                'the honest path — and if your list is on paper, typing ten '
                'products takes less time than correcting fifty wrong ones.',
          ),
        'device' => _notBuilt(
            'kola cannot see other apps from your browser',
            'The web dashboard has no way to look at what is installed on '
                'your device — browsers block that deliberately, and that is '
                'a good thing. Export your products from Square, Loyverse or '
                'whatever you use — nearly all of them offer a CSV export — '
                'and bring the file here. kola will read the columns whatever '
                'they are called.',
          ),
        _ => _filePicker(),
      };

  Component _filePicker() => div([
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:14px;max-width:62ch',
          },
          [
            Component.text(
              'Upload whatever shape your file is in — kola reads the '
              'columns and shows you what it understood before anything is '
              'added. Nothing is saved until you confirm.',
            ),
          ],
        ),
        label(
          htmlFor: 'kola-import-file',
          attributes: {
            'style': 'display:block;border:1px dashed ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};padding:40px 20px;'
                'text-align:center;cursor:pointer;background:${KolaVar.bg}',
          },
          [
            div(
              attributes: {'style': 'color:${KolaVar.muted};margin-bottom:10px'},
              [kolaIcon(Icons.paperclip, size: 24)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${KolaVar.text};margin-bottom:4px',
              },
              [Component.text('Choose your spreadsheet')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              [Component.text('CSV — any column layout')],
            ),
            input(
              type: InputType.file,
              attributes: {
                'id': 'kola-import-file',
                'accept': '.csv,text/csv,text/plain',
                'style': 'display:none',
              },
              events: {
                'change': (e) {
                  final target = e.target;
                  if (target == null) return;
                  final files = filesFrom(target as JSObject);
                  if (files.isNotEmpty) _onFile(files.first);
                  resetFileInput(target);
                },
              },
            ),
          ],
        ),
        if (_error != null) _msg(_error!, KolaVar.danger),
      ]);

  // ── Step 2: the mapping. The point of this screen. ──────────────────

  Component _mappingStep() {
    final parsed = _parsed!;
    final unsure = parsed.mappings
        .where((m) => m.confidence == MappingConfidence.unsure)
        .length;

    return div([
      div(
        attributes: {
          'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:6px',
        },
        [Component.text('Check what kola understood')],
      ),
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.55;margin-bottom:14px;max-width:62ch',
        },
        [
          Component.text(
            unsure == 0
                ? '${_fileName ?? 'Your file'} — ${parsed.rows.length} '
                    'products. Change anything that looks wrong before you '
                    'import.'
                : '${_fileName ?? 'Your file'} — ${parsed.rows.length} '
                    'products. $unsure column${unsure == 1 ? '' : 's'} kola '
                    'is unsure about, marked below. Worth a look: a wrong '
                    'column here becomes a wrong price on every product.',
          ),
        ],
      ),

      div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};overflow:hidden;'
              'margin-bottom:14px',
        },
        [
          for (var i = 0; i < parsed.mappings.length; i++)
            _mappingRow(parsed.mappings[i], i == 0),
        ],
      ),

      if (!parsed.hasName)
        _msg(
          "kola could not find a column with product names, and that is the "
          'one thing it cannot do without. Point one of the columns above at '
          '"Product name" to continue.',
          KolaVar.danger,
        ),

      if (parsed.skipped.isNotEmpty)
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'line-height:1.5;margin-bottom:14px',
          },
          [
            Component.text(
              '${parsed.skipped.length} row'
              '${parsed.skipped.length == 1 ? '' : 's'} will be skipped for '
              'having no product name.',
            ),
          ],
        ),

      div(
        attributes: {'style': 'display:flex;gap:10px;flex-wrap:wrap'},
        [
          button(
            attributes: {
              'type': 'button',
              'style': 'padding:11px 18px;border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};background:transparent;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.small};font-weight:600;cursor:pointer',
            },
            events: {
              'click': (_) => setState(() {
                    _step = _Step.upload;
                    _parsed = null;
                    _overrides.clear();
                  }),
            },
            [Component.text('Choose a different file')],
          ),
          button(
            attributes: {
              'type': 'button',
              if (!parsed.hasName || parsed.rows.isEmpty)
                'disabled': 'disabled',
              'style': 'flex:1;min-width:180px;padding:11px 18px;'
                  'border-radius:${KolaRadius.md};border:none;'
                  'background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.small};font-weight:600;'
                  'cursor:pointer;'
                  'opacity:${parsed.hasName && parsed.rows.isNotEmpty ? '1' : '0.5'}',
            },
            events: {
              'click': (_) {
                if (parsed.hasName && parsed.rows.isNotEmpty) _run();
              },
            },
            [Component.text('Import ${parsed.rows.length} products')],
          ),
        ],
      ),
    ]);
  }

  Component _mappingRow(ColumnMapping m, bool first) {
    final (tone, note) = switch (m.confidence) {
      MappingConfidence.confident => (KolaTone.positive, ''),
      MappingConfidence.unsure => (KolaTone.caution, ' — check this'),
      MappingConfidence.ignored => (KolaTone.neutral, ''),
    };

    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;flex-wrap:wrap;'
            'padding:12px 14px;'
            '${first ? '' : 'border-top:1px solid ${KolaVar.border};'}',
      },
      [
        // The owner's own column name, in mono. It is a value from their
        // file rather than our prose, and the design sets it apart the
        // same way.
        div(
          attributes: {
            'style': 'flex:1;min-width:120px;font-family:${KolaFonts.mono};'
                'font-size:${KolaType.tiny};color:${KolaVar.text}',
          },
          [Component.text(m.source)],
        ),
        div(
          attributes: {
            'style': 'flex:none;color:${KolaVar.muted}',
            'aria-hidden': 'true',
          },
          [kolaIcon(Icons.arrowRight, size: 13)],
        ),
        div(
          attributes: {'style': 'flex:none;${tone.badgeCss}'},
          [Component.text('${m.targetLabel}$note')],
        ),
        // A picker, not a label. Every guess is correctable — that is
        // what makes an unsure guess safe to make at all.
        _targetPicker(m),
      ],
    );
  }

  /// The override picker.
  ///
  /// Uses jaspr's TYPED onChange rather than an events-map handler.
  /// select() declares `ValueChanged<List<String>>? onChange` — a list
  /// because a multi-select can yield several — so there is no event
  /// target to reach into and no interop to get wrong. Confirmed
  /// against jaspr's published signature rather than assumed.
  Component _targetPicker(ColumnMapping m) => select(
        [
          option(
            value: '',
            selected: m.field == null,
            [Component.text('Not imported')],
          ),
          for (final f in csvTargetFields)
            option(
              value: f.id,
              selected: m.field == f.id,
              [Component.text(f.label)],
            ),
        ],
        onChange: (values) {
          final v = values.isEmpty ? '' : values.first;
          _setOverride(m.index, v.isEmpty ? null : v);
        },
        attributes: {
          'aria-label': 'What is "${m.source}"?',
          'style': 'flex:none;padding:7px 10px;'
              'border-radius:${KolaRadius.sm};'
              'border:1px solid ${KolaVar.border};background:${KolaVar.bg};'
              'color:${KolaVar.text};font-family:inherit;'
              'font-size:${KolaType.tiny}',
        },
      );

  // ── Step 3 / 4 ──────────────────────────────────────────────────────

  Component _runningStep() {
    final pct = _total == 0 ? 0.0 : _done / _total;
    return div([
      div(
        attributes: {
          'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:6px',
        },
        [Component.text('Adding your products…')],
      ),
      div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'margin-bottom:12px',
        },
        [Component.text('$_done of $_total')],
      ),
      _bar(pct),
      div(
        attributes: {
          'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
              'line-height:1.5;margin-top:12px;max-width:60ch',
        },
        [
          Component.text(
            'Photos are fetched as each product is added, so a long list '
            'takes a minute. Leave this open — anything already added is '
            'saved.',
          ),
        ],
      ),
    ]);
  }

  Component _resultStep() => div([
        div(
          attributes: {
            'style': 'font-size:${KolaType.lead};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:6px',
          },
          [Component.text('Added $_done of $_total')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:14px;max-width:62ch',
          },
          [
            Component.text(
              _problems.isEmpty
                  ? 'Everything came through. kola can quote prices and check '
                      'stock from these now.'
                  : 'Everything else came through. The rest are listed below '
                      'so you can fix them by hand — they are the only ones '
                      'that need you.',
            ),
          ],
        ),
        if (_problems.isNotEmpty)
          div(
            attributes: {
              'style': 'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};padding:10px 12px;'
                  'max-height:260px;overflow-y:auto;background:${KolaVar.bg};'
                  'margin-bottom:16px',
            },
            [
              for (final p in _problems)
                div(
                  attributes: {
                    'style': 'font-size:${KolaType.tiny};'
                        'color:${KolaVar.muted};line-height:1.55;padding:3px 0',
                  },
                  [Component.text(p)],
                ),
            ],
          ),
        Link(
          to: '/catalog',
          attributes: {
            'class': 'kola-pressable',
            'style': 'display:inline-block;padding:11px 20px;'
                'border-radius:${KolaRadius.pill};'
                'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                'font-size:${KolaType.small};font-weight:600;'
                'text-decoration:none',
          },
          children: [Component.text('See your catalog')],
        ),
      ]);

  // ── Shared ──────────────────────────────────────────────────────────

  Component _bar(double pct) => div(
        attributes: {
          'style': 'height:6px;border-radius:3px;background:${KolaVar.border};'
              'overflow:hidden',
        },
        [
          div(
            attributes: {
              'style': 'height:100%;width:${(pct * 100).round()}%;'
                  'background:${KolaVar.accent};'
                  'transition:width 160ms linear',
            },
            [],
          ),
        ],
      );

  Component _msg(String text, String color) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:$color;'
              'line-height:1.55;margin:12px 0;max-width:62ch',
        },
        [Component.text(text)],
      );

  /// An honest wall.
  ///
  /// Says what is missing, why, and what to do instead — the third part
  /// being the one that matters. "Coming soon" leaves someone holding a
  /// price list with nowhere to put it.
  Component _notBuilt(String headline, String body) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:24px;'
              'background:${KolaVar.bg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:8px',
            },
            [Component.text(headline)],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.6;max-width:62ch',
            },
            [Component.text(body)],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'margin-top:14px;padding:10px 16px;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};background:transparent;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => setState(() => _method = 'file')},
            [Component.text('Upload a spreadsheet instead')],
          ),
        ],
      );
}
