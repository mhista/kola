// integrations_page.dart — the connector marketplace.
//
// REBUILT against Kola Integrations.dc.html. The previous version of this
// file grouped channels by bot, which is a different screen from the one
// the design specifies — see DESIGN_DELTA.md, "Integrations — WRONG".
//
// ── WHAT THE DESIGN SPECIFIES ────────────────────────────────────────
//
//   15 connectors, 4 categories        ← served, not hardcoded
//   search                             ← name + description
//   category filter with counts        ← "All (15)", "Sell (5)" …
//   per-connector modal                ← 5 auth types
//   4 states                           ← connected / available / soon / error
//
// ── THE LIST COMES FROM THE SERVER ───────────────────────────────────
//
// ConnectorEndpoint.listConnectors returns all 15 with this workspace's
// state already resolved. This page holds NO connector list of its own.
// The previous one did, which meant the server and the UI could disagree
// about what exists — and the UI always won, because it was the one
// drawing the screen.
//
// So: no catalog here, no hardcoded names, no client-side decision about
// what is coming soon. `soon` arrives from the server, computed from the
// capability flag.
//
// ── WHY `soon` TILES APPEAR AT ALL ───────────────────────────────────
//
// FeatureGate deliberately hides the unreleased roadmap — the server
// returns only enabled keys. This screen is a narrow, deliberate
// exception: the design shows coming-soon tiles, and a connector NAME is
// a much smaller disclosure than a feature key and its state. Nothing
// here reveals which flag governs what.
//
// ── FIVE AUTH TYPES, NOT FOUR ────────────────────────────────────────
//
//   fields      paste credentials into a form        → connectConnector
//   whatsapp    Meta's setup, its own copy           → same endpoint
//   manage      configured elsewhere; link there     → manageRoute
//   oauth       redirect to the provider             → NOT BUILT
//   keydisplay  we show a key to paste into THEM     → NOT BUILT
//
// `whatsapp` is its own type in the export, branching in two places.
// Reading that file with a field-order regex reports four types and
// silently loses it.
//
// oauth and keydisplay render an honest explanation rather than a button
// that does nothing. A connect button that fails silently is worse than
// one that says why it cannot work yet.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/feature_gate.dart';
import '../services/error_text.dart';
import '../theme.dart';

class IntegrationsPage extends StatefulComponent {
  const IntegrationsPage({
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
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  List<ConnectorStatus> _connectors = const [];
  bool _loading = true;
  String? _loadError;

  String _search = '';
  String _category = 'all';

  /// Key of the connector whose modal is open. Null means none.
  String? _openKey;

  final Map<String, String> _formValues = {};
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final list = await component.client.connector.listConnectors(
        component.accessToken,
        component.workspaceId,
      );
      if (!mounted) return;
      setState(() {
        _connectors = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Named, not swallowed. An empty marketplace and a failed fetch
      // look identical otherwise, and "my integrations disappeared" then
      // has no answer — the mistake app.dart's workspace loader made and
      // had to be corrected for.
      setState(() {
        _loadError = ErrorText.of(e);
        _loading = false;
      });
    }
  }

  // ── Derived ────────────────────────────────────────────────────────

  List<ConnectorStatus> get _visible {
    final q = _search.trim().toLowerCase();
    return [
      for (final c in _connectors)
        if (_category == 'all' || c.category == _category)
          if (q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
            c,
    ];
  }

  ConnectorStatus? get _open {
    final key = _openKey;
    if (key == null) return null;
    for (final c in _connectors) {
      if (c.key == key) return c;
    }
    return null;
  }

  /// Counted over EVERYTHING, not the filtered list — a chip reading
  /// "Sell (5)" must keep saying 5 while a search narrows the grid, or
  /// it is reporting the search rather than the category.
  int _countFor(String id) => id == 'all'
      ? _connectors.length
      : _connectors.where((c) => c.category == id).length;

  // ── Actions ────────────────────────────────────────────────────────

  void _openModal(ConnectorStatus c) {
    setState(() {
      _openKey = c.key;
      _submitError = null;
      _formValues
        ..clear()
        ..addEntries(c.fields.map((f) => MapEntry(f.key, '')));
    });
  }

  void _closeModal() {
    setState(() {
      _openKey = null;
      _submitError = null;
      _submitting = false;
      _formValues.clear();
    });
  }

  void _replace(ConnectorStatus updated) {
    _connectors = [
      for (final existing in _connectors)
        if (existing.key == updated.key) updated else existing,
    ];
  }

  Future<void> _submit(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.connectConnector(
        component.accessToken,
        component.workspaceId,
        c.key,
        Map<String, String>.from(_formValues),
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
        _formValues.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }

  Future<void> _disconnect(ConnectorStatus c) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final updated = await component.client.connector.disconnectConnector(
        component.accessToken,
        component.workspaceId,
        c.key,
      );
      if (!mounted) return;
      setState(() {
        _replace(updated);
        _openKey = null;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = ErrorText.of(e);
      });
    }
  }


  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'style': 'padding:${KolaSpace.lg};max-width:1080px;margin:0 auto;width:100%;box-sizing:border-box'},
      [
        _header(),
        if (_loading)
          _skeleton()
        else if (_loadError != null)
          _errorState()
        else ...[
          _controls(),
          if (_visible.isEmpty) _emptyState() else _grid(),
        ],
        if (_open != null) _modal(_open!),
      ],
    );
  }

  Component _header() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.lg}'},
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};color:${KolaVar.text};'
                  'font-weight:700;margin-bottom:6px',
            },
            [Component.text('Integrations')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:60ch',
            },
            [
              Component.text(
                'Connect the tools you already use. kola reads from them so '
                'you do not have to enter the same thing twice.',
              ),
            ],
          ),
        ],
      );

  Component _controls() => div(
        attributes: {
          'style': 'display:flex;flex-wrap:wrap;gap:${KolaSpace.smd};'
              'align-items:center;margin-bottom:${KolaSpace.md}',
        },
        [
          input<String>(
            type: InputType.search,
            attributes: {
              'aria-label': 'Search integrations',
              'placeholder': 'Search integrations',
              'style': 'flex:1 1 220px;min-width:180px;padding:9px 12px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.card};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body}',
            },
            value: _search,
            onInput: (v) => setState(() => _search = v),
          ),
          div(
            attributes: {'style': 'display:flex;flex-wrap:wrap;gap:6px'},
            [
              _chip('all', 'All'),
              _chip('sell', 'Sell'),
              _chip('pay', 'Get paid'),
              _chip('know', 'Know'),
              _chip('operate', 'Operate'),
            ],
          ),
        ],
      );

  Component _chip(String id, String label) {
    final active = _category == id;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:7px 13px;border-radius:${KolaRadius.pill};'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.mutedStrong};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _category = id)},
      [Component.text('$label (${_countFor(id)})')],
    );
  }

  Component _grid() => div(
        attributes: {
          'style': 'display:grid;gap:${KolaSpace.smd};'
              'grid-template-columns:repeat(auto-fill,minmax(280px,1fr))',
        },
        [for (final c in _visible) _card(c)],
      );

  Component _card(ConnectorStatus c) {
    final soon = c.status == 'soon';
    return div(
      attributes: {
        // Coming-soon tiles are dimmed AND labelled. Opacity alone is not
        // a state anyone can perceive reliably, and it disappears
        // entirely in a printed report.
        'style': 'border:1px solid ${KolaVar.border};'
            'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
            'padding:${KolaSpace.md};display:flex;flex-direction:column;'
            'gap:10px;opacity:${soon ? '0.62' : '1'}',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            div(
              attributes: {
                'style': 'width:34px;height:34px;flex:none;'
                    'border-radius:${KolaRadius.md};'
                    'background:${KolaVar.tintSurface(_tintFor(c.category))};'
                    'color:${KolaVar.tintIcon(_tintFor(c.category))};'
                    'display:flex;align-items:center;justify-content:center',
              },
              [kolaIcon(_iconFor(c.category), size: 17)],
            ),
            div(
              attributes: {
                'style': 'flex:1;min-width:0;font-size:${KolaType.ui};'
                    'font-weight:700;color:${KolaVar.text}',
              },
              [Component.text(c.name)],
            ),
            _badge(c),
          ],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.5',
          },
          [Component.text(c.description)],
        ),
        if (c.displayDetail != null)
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.tiny};color:${KolaVar.mutedStrong};'
                  'word-break:break-all',
            },
            [Component.text(c.displayDetail!)],
          ),
        if (c.lastError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                  'line-height:1.45',
            },
            [Component.text(c.lastError!)],
          ),
        div(
          attributes: {'style': 'margin-top:auto;padding-top:4px'},
          [_cardAction(c)],
        ),
      ],
    );
  }

  Component _cardAction(ConnectorStatus c) {
    if (c.status == 'soon') {
      return div(
        attributes: {
          'style': 'font-size:${KolaType.micro};font-weight:600;'
              'color:${KolaVar.muted}',
        },
        [Component.text('Coming soon')],
      );
    }
    final connected = c.status == 'connected';
    final label = switch (c.status) {
      'connected' => 'Manage',
      'error' => 'Reconnect',
      _ => 'Connect',
    };
    return button(
      attributes: {
        'type': 'button',
        'style': 'padding:8px 14px;border-radius:${KolaRadius.md};'
            'border:1px solid ${connected ? KolaVar.border : 'transparent'};'
            'background:${connected ? 'transparent' : KolaVar.accentFill};'
            'color:${connected ? KolaVar.text : KolaVar.accentText};'
            'font-family:inherit;font-size:${KolaType.small};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => _openModal(c)},
      [Component.text(label)],
    );
  }

  Component _badge(ConnectorStatus c) {
    final (tone, label) = switch (c.status) {
      'connected' => (KolaTone.positive, 'Connected'),
      'error' => (KolaTone.negative, 'Needs attention'),
      'available' => (KolaTone.neutral, 'Not connected'),
      _ => (KolaTone.neutral, 'Soon'),
    };
    return span(
      attributes: {'style': '${tone.badgeCss};flex:none;white-space:nowrap'},
      [Component.text(label)],
    );
  }

  // ── Modal ──────────────────────────────────────────────────────────

  Component _modal(ConnectorStatus c) => div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'aria-label': '${c.name} setup',
          'style': 'position:fixed;inset:0;z-index:60;display:flex;'
              'align-items:center;justify-content:center;'
              'padding:${KolaSpace.md};background:rgba(0,0,0,0.55)',
        },
        events: {'click': (_) => _closeModal()},
        [
          div(
            // Stops a click inside the form from dismissing the thing
            // being typed into.
            events: {'click': (e) => e.stopPropagation()},
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:${KolaSpace.lg};'
                  'width:min(520px,100%);max-height:86vh;overflow-y:auto',
            },
            [
              div(
                attributes: {
                  'style': 'display:flex;align-items:flex-start;gap:10px;'
                      'margin-bottom:${KolaSpace.sm}',
                },
                [
                  div(attributes: {'style': 'flex:1'}, [
                    div(
                      attributes: {
                        'style': 'font-family:${KolaFonts.display};'
                            'font-size:${KolaType.title};font-weight:700;'
                            'color:${KolaVar.text};margin-bottom:4px',
                      },
                      [Component.text(c.name)],
                    ),
                    div(
                      attributes: {
                        'style': 'font-size:${KolaType.small};'
                            'color:${KolaVar.muted};line-height:1.5',
                      },
                      [Component.text(c.description)],
                    ),
                  ]),
                  button(
                    attributes: {
                      'type': 'button',
                      'aria-label': 'Close',
                      'style': 'background:transparent;border:none;'
                          'color:${KolaVar.muted};cursor:pointer;'
                          'display:flex;padding:4px;line-height:1',
                    },
                    events: {'click': (_) => _closeModal()},
                    [kolaIcon(Icons.close, size: 17)],
                  ),
                ],
              ),
              ..._modalBody(c),
            ],
          ),
        ],
      );

  List<Component> _modalBody(ConnectorStatus c) => switch (c.authType) {
        'fields' || 'whatsapp' => _formBody(c),
        'manage' => _manageBody(c),
        'oauth' => _notYet(
            'Connecting ${c.name} works by signing in with ${c.name}. That '
            'sign-in flow is not built yet.',
          ),
        'keydisplay' => _notYet(
            'This works by giving you a kola API key to paste into '
            '${c.name}. The public API that key would open does not exist '
            'yet, so kola will not hand out one that cannot work.',
          ),
        _ => _notYet('This connector cannot be set up here yet.'),
      };

  List<Component> _formBody(ConnectorStatus c) => [
        if (c.authType == 'whatsapp')
          _note('WhatsApp needs five values from your Meta app. The last '
              'one — the verify token — is any phrase you choose; you '
              'paste the same phrase into Meta.'),
        if (c.helpText.isNotEmpty) _note(c.helpText),
        for (final f in c.fields) _field(f),
        if (_submitError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5;margin-top:10px',
            },
            [Component.text(_submitError!)],
          ),
        div(
          attributes: {
            'style': 'display:flex;gap:8px;margin-top:${KolaSpace.md}',
          },
          [
            button(
              attributes: {
                'type': 'button',
                if (_submitting) 'disabled': 'disabled',
                'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                    'border:none;background:${KolaVar.accentFill};'
                    'color:${KolaVar.accentText};font-family:inherit;'
                    'font-size:${KolaType.body};font-weight:600;'
                    'cursor:${_submitting ? 'default' : 'pointer'};'
                    'opacity:${_submitting ? '0.65' : '1'}',
              },
              events: {
                'click': (_) {
                  if (!_submitting) _submit(c);
                },
              },
              [Component.text(_submitting ? 'Connecting…' : 'Connect')],
            ),
            if (c.status == 'connected' || c.status == 'error')
              button(
                attributes: {
                  'type': 'button',
                  if (_submitting) 'disabled': 'disabled',
                  'style': 'padding:10px 16px;border-radius:${KolaRadius.md};'
                      'border:1px solid ${KolaVar.border};'
                      'background:transparent;color:${KolaVar.danger};'
                      'font-family:inherit;font-size:${KolaType.body};'
                      'font-weight:600;cursor:pointer',
                },
                events: {
                  'click': (_) {
                    if (!_submitting) _disconnect(c);
                  },
                },
                [Component.text('Disconnect')],
              ),
          ],
        ),
      ];

  List<Component> _manageBody(ConnectorStatus c) => [
        _note('${c.name} is set up in your billing settings, so kola keeps '
            'one copy of those details rather than two that can disagree.'),
        if (c.displayDetail != null)
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.mono};'
                  'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
                  'margin-bottom:${KolaSpace.sm};word-break:break-all',
            },
            [Component.text(c.displayDetail!)],
          ),
        Link(
          to: c.manageRoute ?? '/billing',
          attributes: {
            'style': 'display:inline-block;padding:10px 16px;'
                'border-radius:${KolaRadius.md};'
                'background:${KolaVar.accentFill};'
                'color:${KolaVar.accentText};font-size:${KolaType.body};'
                'font-weight:600;text-decoration:none',
          },
          children: [Component.text('Open settings')],
        ),
      ];

  List<Component> _notYet(String explanation) => [
        _note(explanation),
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55',
          },
          [
            Component.text('Nothing is broken — this part simply is not '
                'finished. It will appear here when it is.'),
          ],
        ),
      ];

  Component _note(String message) => div(
        attributes: {
          'style': 'background:${KolaVar.pill};'
              'border-radius:${KolaRadius.md};padding:10px 12px;'
              'font-size:${KolaType.small};color:${KolaVar.mutedStrong};'
              'line-height:1.55;margin-bottom:${KolaSpace.sm}',
        },
        [Component.text(message)],
      );

  Component _field(ConnectorFieldSpec f) => label(
        attributes: {'style': 'display:block;margin-bottom:10px'},
        [
          span(
            attributes: {
              'style': 'display:block;font-size:${KolaType.small};'
                  'font-weight:600;color:${KolaVar.mutedStrong};'
                  'margin-bottom:4px',
            },
            [Component.text(f.label)],
          ),
          input<String>(
            type: f.secret ? InputType.password : InputType.text,
            attributes: {
              'placeholder': f.placeholder,
              'autocomplete': 'off',
              'style': 'width:100%;box-sizing:border-box;padding:9px 12px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:${f.secret ? KolaFonts.mono : 'inherit'};'
                  'font-size:${KolaType.body}',
            },
            value: _formValues[f.key] ?? '',
            // Deliberately NOT setState: rebuilding on every keystroke
            // would reset the caret in every other field on the form.
            // The map is read on submit.
            onInput: (v) => _formValues[f.key] = v,
          ),
        ],
      );

  // ── States ─────────────────────────────────────────────────────────

  Component _skeleton() => div(
        attributes: {
          'style': 'display:grid;gap:${KolaSpace.smd};'
              'grid-template-columns:repeat(auto-fill,minmax(280px,1fr))',
        },
        [
          for (var i = 0; i < 6; i++)
            div(
              attributes: {
                'style': 'height:150px;border-radius:${KolaRadius.lg};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.card}',
              },
              const [],
            ),
        ],
      );

  Component _errorState() => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.lg}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:6px',
            },
            [Component.text('Could not load your integrations')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:12px',
            },
            [
              Component.text('This is a connection problem, not a sign that '
                  'anything was disconnected. Your existing integrations are '
                  'untouched.'),
            ],
          ),
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
        ],
      );

  Component _emptyState() => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};padding:${KolaSpace.lg};'
              'text-align:center',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.ui};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Nothing matches that')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted}',
            },
            [
              Component.text('Try a different word, or clear the category '
                  'filter.'),
            ],
          ),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────

  /// Fixed category → tint mapping rather than index-modulo, so a
  /// category keeps its colour when another is added.
  int _tintFor(String category) => switch (category) {
        'pay' => 0,
        'sell' => 1,
        'know' => 2,
        _ => 3,
      };

  String _iconFor(String category) => switch (category) {
        'sell' => Icons.catalog,
        'pay' => Icons.billing,
        'know' => Icons.book,
        _ => Icons.workflow,
      };
}
