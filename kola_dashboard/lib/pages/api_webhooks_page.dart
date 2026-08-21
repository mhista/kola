// api_webhooks_page.dart — API keys and outbound webhooks.
//
// Backs `Kola API Webhooks.dc.html`. This is the dashboard's first real
// surface for Gate 2's event bus: the events themselves (new_conversation,
// errand_executed, agent_drafted, agent_published, agent_paused,
// payment_confirmed) have had a working delivery pipeline
// (EventBus -> WebhookDeliveryService, see kola_server's Gate 2 build)
// with nowhere for an owner to register an endpoint from the UI — only
// through raw API calls. This page closes that gap.
//
// ── SAME SHAPE AS integrations_page.dart, ON PURPOSE ─────────────────
//
// Load -> render from server state -> mutate through the endpoint ->
// replace the one row that changed. No client-side list of its own, no
// optimistic guessing at what the server will say. `IntegrationsPage`
// already proved this pattern for a similar "cards backed by a small
// CRUD endpoint" screen; this page follows it rather than inventing a
// second one.
//
// ── THE PLAINTEXT KEY RULE ────────────────────────────────────────────
//
// `CreatedApiKey.plaintext` is the ONLY time the full key is ever sent
// to a browser (see api_key_service.dart's header). It lives in
// [_newKeyPlaintext] only, is never stored in [_keys], and is cleared
// the moment the create-key modal closes. There is deliberately no
// "show it again" — losing it means revoking and reissuing, which is
// the correct behaviour, not a gap.
//
// ── EVENT_TYPES IS HARDCODED HERE, AND THAT IS A KNOWN COST ──────────
//
// `PlatformEndpoint.eventTypes` on the server is the source of truth,
// but it is not exposed over the wire (no `listEventTypes` call) — the
// server enforces it on `saveWebhookEndpoint`, this list only decides
// what checkboxes to draw. Same maintenance shape as
// `feature_gate.dart`'s `Features` mirroring `FeatureKeys` server-side:
// two lists, kept in sync by hand, checked here rather than invented as
// a new pattern. If Gate 2's event set changes again, this list and
// `platform_endpoint.dart`'s need updating together.
//
// ── "AGENT", NOT "BOT" ────────────────────────────────────────────────
//
// The design export's own script still says 'Bot published' — it
// predates Gate 2's product-facing rename. The labels below use the
// current names (`agent_drafted` / `agent_published` / `agent_paused`),
// matching `platform_endpoint.dart`'s `eventTypes` and
// `agent_lifecycle_events.dart`. See that file's header for why "Bot"
// stays the internal identifier while "agent" is what ships in events,
// labels and docs.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/shell/kola_icon.dart';
import '../components/shell/icons.dart';
import '../config/env.dart';
import '../services/error_text.dart';
import '../services/feature_gate.dart';
import '../theme.dart';

/// Mirrors `PlatformEndpoint.eventTypes`. Keep in sync by hand — see
/// this file's header.
const _eventTypes = <(String value, String label)>[
  ('new_conversation', 'New conversation'),
  ('errand_executed', 'Errand executed'),
  ('agent_drafted', 'Agent drafted'),
  ('agent_published', 'Agent published'),
  ('agent_paused', 'Agent paused'),
  ('payment_confirmed', 'Payment confirmed'),
];

/// Mirrors `ApiKeyService.scopes`.
const _scopes = <(String value, String label)>[
  ('full', 'Full access'),
  ('read_only', 'Read-only'),
  ('errands_only', 'Errands only'),
];

class ApiWebhooksPage extends StatefulComponent {
  const ApiWebhooksPage({
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
  State<ApiWebhooksPage> createState() => _ApiWebhooksPageState();
}

class _ApiWebhooksPageState extends State<ApiWebhooksPage> {
  List<ApiKey> _keys = const [];
  List<WebhookEndpoint> _hooks = const [];
  bool _loading = true;
  String? _loadError;

  // ── Create key modal ──────────────────────────────────────────────
  bool _showCreateKey = false;
  String _keyName = '';
  String _keyScope = 'full';
  bool _creatingKey = false;
  String? _createKeyError;

  /// The ONLY copy of a just-created key's plaintext. See this file's
  /// header on why this never joins [_keys].
  String? _newKeyPlaintext;

  // ── Add endpoint modal ────────────────────────────────────────────
  bool _showAddEndpoint = false;
  String _endpointUrl = '';
  final Set<String> _endpointEvents = {'new_conversation'};
  bool _addingEndpoint = false;
  String? _addEndpointError;

  /// Row-level busy state, keyed by "key:$id" / "hook:$id", so revoking
  /// one key does not disable every other row's button.
  final Set<String> _busyRows = {};

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
      final results = await Future.wait([
        component.client.platform.listApiKeys(
          component.accessToken,
          component.workspaceId,
        ),
        component.client.platform.listWebhookEndpoints(
          component.accessToken,
          component.workspaceId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _keys = results[0] as List<ApiKey>;
        _hooks = results[1] as List<WebhookEndpoint>;
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

  // ── API keys ───────────────────────────────────────────────────────

  void _openCreateKey() {
    setState(() {
      _showCreateKey = true;
      _keyName = '';
      _keyScope = 'full';
      _createKeyError = null;
      _newKeyPlaintext = null;
    });
  }

  void _closeCreateKey() {
    setState(() {
      _showCreateKey = false;
      _creatingKey = false;
      _createKeyError = null;
      // The plaintext leaves memory the moment the modal that showed it
      // closes — see this file's header.
      _newKeyPlaintext = null;
    });
  }

  Future<void> _createKey() async {
    if (_keyName.trim().isEmpty || _creatingKey) return;
    setState(() {
      _creatingKey = true;
      _createKeyError = null;
    });
    try {
      final created = await component.client.platform.createApiKey(
        component.accessToken,
        component.workspaceId,
        _keyName.trim(),
        _keyScope,
      );
      if (!mounted) return;
      setState(() {
        _keys = [..._keys, created.key];
        _newKeyPlaintext = created.plaintext;
        _creatingKey = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingKey = false;
        _createKeyError = ErrorText.of(e);
      });
    }
  }

  Future<void> _revokeKey(ApiKey key) async {
    final id = key.id;
    if (id == null) return;
    final rowKey = 'key:$id';
    setState(() => _busyRows.add(rowKey));
    try {
      await component.client.platform.revokeApiKey(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      // Revoking is not deleting — the design still lists revoked keys
      // (see PlatformEndpoint.listApiKeys' own doc comment), so re-load
      // rather than filter the row out.
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyRows.remove(rowKey);
        _loadError = ErrorText.of(e);
      });
    }
  }

  // ── Webhook endpoints ──────────────────────────────────────────────

  void _openAddEndpoint() {
    setState(() {
      _showAddEndpoint = true;
      _endpointUrl = '';
      _endpointEvents
        ..clear()
        ..add('new_conversation');
      _addEndpointError = null;
    });
  }

  void _closeAddEndpoint() {
    setState(() {
      _showAddEndpoint = false;
      _addingEndpoint = false;
      _addEndpointError = null;
    });
  }

  Future<void> _addEndpoint() async {
    if (_endpointUrl.trim().isEmpty || _addingEndpoint) return;
    setState(() {
      _addingEndpoint = true;
      _addEndpointError = null;
    });
    try {
      final saved = await component.client.platform.saveWebhookEndpoint(
        component.accessToken,
        component.workspaceId,
        _endpointUrl.trim(),
        _endpointEvents.toList(),
      );
      if (!mounted) return;
      final withoutSameUrl = [
        for (final h in _hooks)
          if (h.id != saved.id) h,
      ];
      setState(() {
        _hooks = [...withoutSameUrl, saved];
        _showAddEndpoint = false;
        _addingEndpoint = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addingEndpoint = false;
        _addEndpointError = ErrorText.of(e);
      });
    }
  }

  Future<void> _deleteEndpoint(WebhookEndpoint hook) async {
    final id = hook.id;
    if (id == null) return;
    final rowKey = 'hook:$id';
    setState(() => _busyRows.add(rowKey));
    try {
      await component.client.platform.deleteWebhookEndpoint(
        component.accessToken,
        component.workspaceId,
        id,
      );
      if (!mounted) return;
      setState(() {
        _hooks = [
          for (final h in _hooks)
            if (h.id != id) h,
        ];
        _busyRows.remove(rowKey);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyRows.remove(rowKey);
        _loadError = ErrorText.of(e);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lg};max-width:900px;margin:0 auto;'
            'width:100%;box-sizing:border-box',
      },
      [
        _header(),
        if (_loading)
          _skeleton()
        else if (_loadError != null)
          _errorState()
        else ...[
          _stats(),
          _keysSection(),
          _hooksSection(),
        ],
        if (_showCreateKey) _createKeyModal(),
        if (_showAddEndpoint) _addEndpointModal(),
      ],
    );
  }

  Component _header() => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;'
              'align-items:flex-start;gap:${KolaSpace.md};'
              'flex-wrap:wrap;margin-bottom:${KolaSpace.lg}',
        },
        [
          div([
            div(
              attributes: {
                'style': 'font-family:${KolaFonts.display};'
                    'font-size:${KolaType.h2};color:${KolaVar.text};'
                    'font-weight:700;margin-bottom:6px',
              },
              [Component.text('API & Webhooks')],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                    'line-height:1.55;max-width:56ch',
              },
              [Component.text('Programmatic access to your agent and Errands.')],
            ),
          ]),
          a(
            href: Env.kolaDocsUrl,
            attributes: {
              'target': '_blank',
              'rel': 'noopener',
              'style': 'font-size:${KolaType.small};color:${KolaVar.text};'
                  'background:${KolaVar.pill};border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.pill};padding:8px 16px;'
                  'text-decoration:none;white-space:nowrap;font-weight:600',
            },
            [Component.text('Full API docs')],
          ),
        ],
      );

  Component _stats() {
    final activeHooks = _hooks.where((h) => h.status != 'paused').length;
    final items = [
      ('Active keys', '${_keys.where((k) => k.revokedAt == null).length}'),
      ('Webhook endpoints', '$activeHooks'),
      ('Events wired', '${_eventTypes.length}'),
    ];
    return div(
      attributes: {
        'style': 'display:grid;grid-template-columns:repeat(3,1fr);'
            'gap:${KolaSpace.smd};margin-bottom:${KolaSpace.xxl}',
      },
      [
        for (final (label, value) in items)
          div(
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.md};padding:${KolaSpace.md} ${KolaSpace.lg}',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.micro};color:${KolaVar.muted};'
                      'margin-bottom:5px',
                },
                [Component.text(label)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.h3};font-weight:700;'
                      'color:${KolaVar.text};font-family:${KolaFonts.mono}',
                },
                [Component.text(value)],
              ),
            ],
          ),
      ],
    );
  }

  // ── API keys section ──────────────────────────────────────────────

  Component _keysSection() => div(
        attributes: {'style': 'margin-bottom:${KolaSpace.xxl}'},
        [
          _sectionHeader('API keys', '+ Create key', _openCreateKey),
          if (_keys.isEmpty)
            _emptyRow('No API keys yet — create one to call kolaa programmatically.')
          else
            _card([for (final k in _keys) _keyRow(k)]),
        ],
      );

  Component _keyRow(ApiKey key) {
    final revoked = key.revokedAt != null;
    final busy = _busyRows.contains('key:${key.id}');
    return _row([
      div(
        attributes: {'style': 'min-width:0;flex:1'},
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:8px;'
                  'margin-bottom:3px',
            },
            [
              div(
                attributes: {
                  'style': 'font-size:${KolaType.bodyLg};font-weight:600;'
                      'color:${KolaVar.text}',
                },
                [Component.text(key.name)],
              ),
              if (revoked)
                span(
                  attributes: {'style': KolaTone.negative.badgeCss},
                  [Component.text('Revoked')],
                ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'font-family:${KolaFonts.mono}',
            },
            [
              Component.text(
                '${key.keyPrefix}_••••${key.lastFour} · scope: '
                '${_scopeLabel(key.scope)} · '
                '${key.lastUsedAt == null ? 'never used' : 'last used ${_ago(key.lastUsedAt!)}'}',
              ),
            ],
          ),
        ],
      ),
      if (!revoked)
        button(
          attributes: {
            'type': 'button',
            if (busy) 'disabled': 'disabled',
            'style': 'background:transparent;border:none;'
                'color:${KolaVar.danger};font-size:${KolaType.small};'
                'font-weight:600;cursor:${busy ? 'default' : 'pointer'};'
                'flex:none;padding:4px',
          },
          events: {
            'click': (_) {
              if (!busy) _revokeKey(key);
            },
          },
          [Component.text(busy ? 'Revoking…' : 'Revoke')],
        ),
    ]);
  }

  // ── Webhook endpoints section ─────────────────────────────────────

  Component _hooksSection() => div(
        [
          _sectionHeader('Webhook endpoints', '+ Add endpoint', _openAddEndpoint),
          if (_hooks.isEmpty)
            _emptyRow('No webhook endpoints yet — add one to receive events as they happen.')
          else
            _card([for (final h in _hooks) _hookRow(h)]),
        ],
      );

  Component _hookRow(WebhookEndpoint hook) {
    final busy = _busyRows.contains('hook:${hook.id}');
    final (tone, label) = switch (hook.status) {
      'active' => (KolaTone.positive, 'Active'),
      'failing' => (KolaTone.negative, 'Failing'),
      _ => (KolaTone.neutral, 'Paused'),
    };
    return div(
      attributes: {
        'style': 'padding:${KolaSpace.lmd} ${KolaSpace.lg};'
            'border-top:1px solid ${KolaVar.border}',
      },
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;'
                'align-items:center;gap:${KolaSpace.smd};flex-wrap:wrap;'
                'margin-bottom:8px',
          },
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};color:${KolaVar.text};'
                    'font-family:${KolaFonts.mono};word-break:break-all',
              },
              [Component.text(hook.url)],
            ),
            div(
              attributes: {'style': 'display:flex;align-items:center;gap:10px;flex:none'},
              [
                span(attributes: {'style': tone.badgeCss}, [Component.text(label)]),
                button(
                  attributes: {
                    'type': 'button',
                    if (busy) 'disabled': 'disabled',
                    'style': 'background:transparent;border:none;'
                        'color:${KolaVar.danger};font-size:${KolaType.tiny};'
                        'font-weight:600;cursor:${busy ? 'default' : 'pointer'};'
                        'padding:2px',
                  },
                  events: {
                    'click': (_) {
                      if (!busy) _deleteEndpoint(hook);
                    },
                  },
                  [Component.text(busy ? 'Deleting…' : 'Delete')],
                ),
              ],
            ),
          ],
        ),
        if (hook.status == 'failing' && hook.lastError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.danger};'
                  'margin-bottom:8px;line-height:1.45',
            },
            [Component.text(hook.lastError!)],
          ),
        div(
          attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap'},
          [
            for (final ev in hook.events)
              span(
                attributes: {
                  'style': 'font-size:${KolaType.micro};background:${KolaVar.pill};'
                      'color:${KolaVar.mutedStrong};padding:4px 9px;'
                      'border-radius:${KolaRadius.pill}',
                },
                [Component.text(_eventLabel(ev))],
              ),
          ],
        ),
      ],
    );
  }

  // ── Modals ─────────────────────────────────────────────────────────

  Component _createKeyModal() => _modalShell(
        onScrimClick: _closeCreateKey,
        child: _newKeyPlaintext != null
            ? _createKeyRevealBody()
            : _createKeyFormBody(),
      );

  Component _createKeyFormBody() => div([
        _modalHeader('Create API key', _closeCreateKey),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                'margin-bottom:${KolaSpace.md}',
          },
          [Component.text('Shown once — copy it somewhere safe.')],
        ),
        input<String>(
          type: InputType.text,
          attributes: {
            'placeholder': 'Key name — e.g. Storefront integration',
            'style': 'width:100%;box-sizing:border-box;padding:11px 13px;'
                'border-radius:${KolaRadius.md};border:1px solid ${KolaVar.border};'
                'background:${KolaVar.bg};color:${KolaVar.text};'
                'font-family:inherit;font-size:${KolaType.body};'
                'margin-bottom:${KolaSpace.md}',
          },
          value: _keyName,
          onInput: (v) => setState(() => _keyName = v),
        ),
        div(
          attributes: {'style': 'margin-bottom:${KolaSpace.md}'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                    'margin-bottom:6px',
              },
              [Component.text('Scope')],
            ),
            div(
              attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap'},
              [
                for (final (value, label) in _scopes)
                  _scopeChip(value, label),
              ],
            ),
          ],
        ),
        if (_createKeyError != null)
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                  'line-height:1.5;margin-bottom:${KolaSpace.sm}',
            },
            [Component.text(_createKeyError!)],
          ),
        _primaryButton(
          label: _creatingKey ? 'Creating…' : 'Create key',
          disabled: _keyName.trim().isEmpty || _creatingKey,
          onClick: _createKey,
        ),
      ]);

  Component _scopeChip(String value, String label) {
    final active = _keyScope == value;
    return button(
      attributes: {
        'type': 'button',
        'style': 'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.pill : 'transparent'};'
            'color:${active ? KolaVar.text : KolaVar.muted};'
            'border-radius:${KolaRadius.pill};padding:8px 14px;'
            'font-size:${KolaType.tiny};font-family:inherit;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _keyScope = value)},
      [Component.text(label)],
    );
  }

  Component _createKeyRevealBody() => div([
        div(
          attributes: {
            'style': 'font-size:${KolaType.title};font-weight:700;'
                'color:${KolaVar.text};margin-bottom:6px',
          },
          [Component.text('Your new key')],
        ),
        div(
          attributes: {
            'style': 'font-size:${KolaType.tiny};color:${KolaVar.warning};'
                'margin-bottom:${KolaSpace.md}',
          },
          [Component.text("This is the only time it's shown in full.")],
        ),
        div(
          attributes: {
            'style': 'background:${KolaVar.bg};border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.md};padding:12px 14px;'
                'font-family:${KolaFonts.mono};font-size:${KolaType.small};'
                'color:${KolaVar.successBright};word-break:break-all;'
                'margin-bottom:${KolaSpace.md};user-select:all',
          },
          [Component.text(_newKeyPlaintext!)],
        ),
        _primaryButton(label: 'Done', disabled: false, onClick: () async => _closeCreateKey()),
      ]);

  Component _addEndpointModal() => _modalShell(
        onScrimClick: _closeAddEndpoint,
        child: div([
          _modalHeader('Add webhook endpoint', _closeAddEndpoint),
          input<String>(
            type: InputType.text,
            attributes: {
              'placeholder': 'https://your-app.com/webhooks/kolaa',
              'style': 'width:100%;box-sizing:border-box;padding:11px 13px;'
                  'border-radius:${KolaRadius.md};border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:${KolaFonts.mono};font-size:${KolaType.small};'
                  'margin-bottom:${KolaSpace.md}',
            },
            value: _endpointUrl,
            onInput: (v) => setState(() => _endpointUrl = v),
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted};'
                  'margin-bottom:8px',
            },
            [Component.text('Events to send')],
          ),
          div(
            attributes: {
              'style': 'display:flex;flex-direction:column;gap:6px;'
                  'margin-bottom:${KolaSpace.md}',
            },
            [for (final (value, label) in _eventTypes) _eventCheckbox(value, label)],
          ),
          if (_addEndpointError != null)
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};color:${KolaVar.danger};'
                    'line-height:1.5;margin-bottom:${KolaSpace.sm}',
              },
              [Component.text(_addEndpointError!)],
            ),
          _primaryButton(
            label: _addingEndpoint ? 'Adding…' : 'Add endpoint',
            disabled: _endpointUrl.trim().isEmpty ||
                _endpointEvents.isEmpty ||
                _addingEndpoint,
            onClick: _addEndpoint,
          ),
        ]),
      );

  /// A toggle row, not an `<input type="checkbox">`.
  ///
  /// `InputType.checkbox` is a documented landmine in this codebase —
  /// see media_upload.dart's header: it "analysed clean and failed" at
  /// runtime once already. `IntegrationsPage`'s category chips proved a
  /// button-based toggle works, so events use the same shape: a button,
  /// `aria-pressed`, and a small square that fills in when selected.
  Component _eventCheckbox(String value, String eventLabel) {
    final checked = _endpointEvents.contains(value);
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': checked ? 'true' : 'false',
        'style': 'display:flex;align-items:center;gap:10px;'
            'background:transparent;border:none;padding:2px 0;'
            'font-family:inherit;font-size:${KolaType.body};'
            'color:${KolaVar.text};cursor:pointer;text-align:left',
      },
      events: {
        'click': (_) => setState(() {
              if (checked) {
                _endpointEvents.remove(value);
              } else {
                _endpointEvents.add(value);
              }
            }),
      },
      [
        div(
          attributes: {
            'style': 'width:16px;height:16px;flex:none;'
                'border-radius:4px;'
                'border:1px solid ${checked ? KolaVar.accent : KolaVar.border};'
                'background:${checked ? KolaVar.accentFill : 'transparent'};'
                'color:${KolaVar.accentText};'
                'display:flex;align-items:center;justify-content:center',
          },
          [if (checked) kolaIcon(Icons.check, size: 11, strokeWidth: 3)],
        ),
        Component.text(eventLabel),
      ],
    );
  }

  // ── Shared building blocks ────────────────────────────────────────

  // `void Function()` rather than `VoidCallback` — that name is defined
  // in BOTH jaspr and kola_client (via serverpod_client), and importing
  // both packages (which every page here does) makes the bare name
  // ambiguous. The function-type spelling has no such collision.
  Component _sectionHeader(String title, String actionLabel, void Function() onAction) =>
      div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;'
              'align-items:center;margin-bottom:${KolaSpace.md}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.uiLg};font-weight:700;'
                  'color:${KolaVar.text}',
            },
            [Component.text(title)],
          ),
          button(
            attributes: {
              'type': 'button',
              'style': 'background:${KolaVar.pill};border:1px solid ${KolaVar.border};'
                  'color:${KolaVar.text};border-radius:${KolaRadius.sm};'
                  'padding:9px 16px;font-size:${KolaType.small};'
                  'font-weight:700;font-family:inherit;cursor:pointer;'
                  'white-space:nowrap',
            },
            events: {'click': (_) => onAction()},
            [Component.text(actionLabel)],
          ),
        ],
      );

  Component _card(List<Component> rows) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.md};overflow:hidden;'
              'background:${KolaVar.card}',
        },
        rows,
      );

  Component _row(List<Component> children) => div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'padding:${KolaSpace.lmd} ${KolaSpace.lg};gap:${KolaSpace.md};'
              'flex-wrap:wrap;border-top:1px solid ${KolaVar.border}',
        },
        children,
      );

  Component _emptyRow(String message) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:${KolaSpace.xl};'
              'text-align:center;font-size:${KolaType.small};'
              'color:${KolaVar.muted}',
        },
        [Component.text(message)],
      );

  Component _modalShell({required void Function() onScrimClick, required Component child}) =>
      div(
        attributes: {
          'role': 'dialog',
          'aria-modal': 'true',
          'style': 'position:fixed;inset:0;z-index:60;display:flex;'
              'align-items:center;justify-content:center;'
              'padding:${KolaSpace.md};background:rgba(0,0,0,0.55)',
        },
        events: {'click': (_) => onScrimClick()},
        [
          div(
            events: {'click': (e) => e.stopPropagation()},
            attributes: {
              'style': 'background:${KolaVar.card};'
                  'border:1px solid ${KolaVar.border};'
                  'border-radius:${KolaRadius.lg};padding:${KolaSpace.lg};'
                  'width:min(440px,100%);max-height:86vh;overflow-y:auto;'
                  'box-sizing:border-box',
            },
            [child],
          ),
        ],
      );

  Component _modalHeader(String title, void Function() onClose) => div(
        attributes: {
          'style': 'display:flex;justify-content:space-between;'
              'align-items:center;margin-bottom:${KolaSpace.md}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.title};font-weight:700;'
                  'color:${KolaVar.text}',
            },
            [Component.text(title)],
          ),
          button(
            attributes: {
              'type': 'button',
              'aria-label': 'Close',
              'style': 'background:transparent;border:none;'
                  'color:${KolaVar.muted};cursor:pointer;display:flex;'
                  'padding:4px;line-height:1',
            },
            events: {'click': (_) => onClose()},
            [kolaIcon(Icons.close, size: 17)],
          ),
        ],
      );

  Component _primaryButton({
    required String label,
    required bool disabled,
    required Future<void> Function() onClick,
  }) =>
      button(
        attributes: {
          'type': 'button',
          if (disabled) 'disabled': 'disabled',
          'style': 'width:100%;background:${disabled ? KolaVar.pill : KolaVar.accentFill};'
              'color:${disabled ? KolaVar.muted : KolaVar.accentText};'
              'border:none;border-radius:${KolaRadius.sm};padding:12px;'
              'font-size:${KolaType.bodyLg};font-weight:700;font-family:inherit;'
              'cursor:${disabled ? 'default' : 'pointer'};min-height:44px',
        },
        events: {
          'click': (_) {
            if (!disabled) onClick();
          },
        },
        [Component.text(label)],
      );

  // ── States ─────────────────────────────────────────────────────────

  Component _skeleton() => div(
        [
          for (var i = 0; i < 2; i++)
            div(
              attributes: {
                'style': 'height:120px;border-radius:${KolaRadius.md};'
                    'border:1px solid ${KolaVar.border};'
                    'background:${KolaVar.card};margin-bottom:${KolaSpace.lg}',
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
            [Component.text('Could not load your API keys and webhooks')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;margin-bottom:12px',
            },
            [
              Component.text('This is a connection problem, not a sign that '
                  'anything was lost. Nothing here has changed.'),
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
              'style': 'padding:9px 15px;border-radius:${KolaRadius.sm};'
                  'border:none;background:${KolaVar.accentFill};'
                  'color:${KolaVar.accentText};font-family:inherit;'
                  'font-size:${KolaType.body};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => _load()},
            [Component.text('Try again')],
          ),
        ],
      );

  // ── Helpers ────────────────────────────────────────────────────────

  String _scopeLabel(String value) {
    for (final (v, label) in _scopes) {
      if (v == value) return label;
    }
    return value;
  }

  String _eventLabel(String value) {
    for (final (v, label) in _eventTypes) {
      if (v == value) return label;
    }
    return value;
  }

  /// "3h ago" / "2d ago" — same phrasing as product_detail_page.dart's
  /// own `_ago`. Not shared, because none of this codebase's per-page
  /// time formatters are shared yet; duplicating a five-line private
  /// helper is the existing convention here, not a shortcut.
  String _ago(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 7}w ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}
