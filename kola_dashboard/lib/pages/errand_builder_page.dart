// errand_builder_page.dart — rebuilt from the "Kola New Errand.dc.html"
// design export the owner supplied directly (following task #137's
// design-AI prompt). Structurally different from the Phase 4e/task #135
// version this replaces: a template-picker-first flow (7 cards: 6 real
// built-in handlers + "Custom Errand") instead of a bare dropdown, a
// single trigger textarea for built-in templates (no fields — the AI
// infers those, per task #134's tool-calling engine), and a
// "Describe it" (plain-language) vs. "Build it myself" (typed fields)
// split for custom Errands.
//
// COLOR MAPPING, NOT A LITERAL COPY: the mockup uses a 3-tier dark shade
// (#0E0E10 page / #121214 card / #1B1B1E inner-chip), one notch darker
// than this dashboard's existing 2-tier system (KolaDashboardColors.bg
// #121214 / .card #1B1B1E). Introducing a third literal shade just for
// this one page would make it look like a different app next to every
// other already-shipped page — instead: page background → .bg, the two
// outer cards (Details / Your Errands) → .card, and the one extra
// nesting level the mockup's template-picker rows/tag-chips need →
// .pill (#242220, already an established token, just not used on this
// page before). Fonts: Space Grotesk/Plus Jakarta Sans in the mockup →
// KolaDashboardFonts.display/.sans (Inter) — theme.dart's own header
// explains this was a deliberate, explicit, project-wide override, not
// something to re-introduce per page. IBM Plex Mono (the field-type
// badges) → KolaDashboardFonts.mono, same reasoning.
//
// TWO REAL DEVIATIONS FROM THE MOCKUP, BOTH FORCED BY WHAT THE BACKEND
// ACTUALLY SUPPORTS (same "don't build a UI path with no working
// backend behind it" rule this file's own original header already
// established):
//   1. "Describe it" mode gained a Name field the mockup doesn't show —
//      createWebhookErrand/createDbCredentialErrand both require a
//      non-empty name server-side; there's no AI-assisted "draft a name
//      from this description" endpoint to lean on instead.
//   2. Both custom-Errand modes gained real credential fields (webhook
//      URL + optional auth header, or a connection string + query
//      template) once a source/fulfillment type is picked — the mockup
//      shows the source/fulfillment PICKER but not what happens after,
//      and a webhook/database Errand is unusable without them. "MCP
//      (soon)" stays inert either way — genuinely unimplemented
//      server-side (errand_endpoint.dart's own header), not a UI gap.
//   3. Dev mode's "Test this Errand" button is disabled until the
//      Errand is actually saved (has a real id to execute) — there's no
//      "run this unsaved draft" endpoint, so pretending otherwise would
//      be exactly the kind of overstated UI this project has caught and
//      corrected before.
//
// Errands are scoped to a workspace, not a bot (confirmed — no method
// on EndpointErrand takes a botId), so this page needs only
// [workspaceId], not a bot selector.

import 'dart:convert';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

/// One selectable template card — the 7 real built-in handlers
/// BuiltinErrandExecutor registers (builtin_errand_executor.dart), plus
/// 'custom' for webhook/database Errands. [builtinHandlerKey] is null
/// only for 'custom'.
class _Template {
  const _Template({
    required this.id,
    required this.icon,
    required this.name,
    required this.desc,
    required this.defaultTrigger,
    this.builtinHandlerKey,
  });

  final String id;
  final String icon;
  final String name;
  final String desc;
  final String defaultTrigger;
  final String? builtinHandlerKey;

  bool get isCustom => builtinHandlerKey == null;
}

const _templates = [
  _Template(
    id: 'escalateToHuman',
    builtinHandlerKey: 'escalateToHuman',
    icon: '🧑‍💼',
    name: 'Escalate to human',
    desc: 'Hand the conversation to a real person on your team',
    defaultTrigger: "When a customer is frustrated, asks for a human, or kola can't resolve the issue.",
  ),
  _Template(
    id: 'collectPayment',
    builtinHandlerKey: 'collectPayment',
    icon: '💳',
    name: 'Collect a payment',
    desc: "Send a payment link and confirm once it's paid",
    defaultTrigger: 'When a customer is ready to pay for an order or service.',
  ),
  _Template(
    id: 'createSupportTicket',
    builtinHandlerKey: 'createSupportTicket',
    icon: '🎫',
    name: 'Log a support ticket',
    desc: 'File an issue so your team can follow up',
    defaultTrigger: 'When a customer reports a problem that needs follow-up from the team.',
  ),
  _Template(
    id: 'recordCustomerProfile',
    builtinHandlerKey: 'recordCustomerProfile',
    icon: '📅',
    name: 'Save a customer date',
    desc: 'Remember a birthday, anniversary, or reminder',
    defaultTrigger: "When a customer mentions their birthday, anniversary, or something to remind them about.",
  ),
  _Template(
    id: 'sendOtp',
    builtinHandlerKey: 'sendOtp',
    icon: '📧',
    name: 'Send a verification code',
    desc: "Email a one-time code to confirm it's really them",
    defaultTrigger: "When you need to confirm a customer's email before continuing — e.g. before an order or account change.",
  ),
  _Template(
    id: 'verifyOtp',
    builtinHandlerKey: 'verifyOtp',
    icon: '✅',
    name: 'Check a verification code',
    desc: 'Confirm the code a customer typed back matches',
    defaultTrigger: 'When a customer replies with the verification code you sent them.',
  ),
  _Template(
    id: 'createProductListTemplate',
    builtinHandlerKey: 'createProductListTemplate',
    icon: '🛍️',
    name: 'Send a product list on WhatsApp',
    desc: 'Submit a Meta-approved template so kola can send your product list to a customer who asked, as cheaply as WhatsApp allows',
    defaultTrigger: 'When a customer on WhatsApp asks for your product list, catalog, or price list.',
  ),
  _Template(
    id: 'custom',
    icon: '⚙️',
    name: 'Custom Errand',
    desc: 'Connect your own webhook or database',
    defaultTrigger: '',
  ),
];

class ErrandBuilderPage extends StatefulComponent {
  const ErrandBuilderPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<ErrandBuilderPage> createState() => _ErrandBuilderPageState();
}

class _ErrandBuilderPageState extends State<ErrandBuilderPage> {
  List<Errand>? _errands;
  String? _loadError;
  int? _togglingErrandId;
  int? _deletingErrandId;

  // ── Template picker ────────────────────────────────────────────────────
  String? _templateId;

  // ── Built-in flow ──────────────────────────────────────────────────────
  String _builtinTrigger = '';

  // ── Custom flow — shared ────────────────────────────────────────────────
  String _customMode = 'chat'; // 'chat' | 'dev'

  // Custom / "Describe it" (chat mode)
  String _chatName = '';
  String _chatDesc = '';
  String _infoDraft = '';
  List<String> _neededInfo = [];
  String? _chatSource; // 'database' | 'webhook'
  String _chatWebhookUrl = '';
  String _chatAuthHeaderName = '';
  String _chatAuthHeaderValue = '';
  String _chatConnectionString = '';
  String _chatQuerySql = '';

  // Custom / "Build it myself" (dev mode)
  String _devName = '';
  String _devDesc = '';
  String _fieldDraft = '';
  List<_DevField> _devFields = [];
  String? _fulfillType; // 'webhook' | 'database' | 'mcp'
  String _devWebhookUrl = '';
  String _devAuthHeaderName = '';
  String _devAuthHeaderValue = '';
  String _devConnectionString = '';
  String _devQuerySql = '';

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final errands = await component.client.errand.listErrandsForWorkspace(
        component.accessToken,
        component.workspaceId,
      );
      setState(() => _errands = errands);
    } catch (_) {
      setState(() => _loadError = "Couldn't load errands. Check your connection and try again.");
    }
  }

  void _pickTemplate(_Template t) {
    setState(() {
      _templateId = t.id;
      _builtinTrigger = t.defaultTrigger;
    });
  }

  void _backToPicker() {
    setState(() {
      _templateId = null;
      _saveError = null;
    });
  }

  _Template? get _selectedTemplate {
    final id = _templateId;
    if (id == null) return null;
    for (final t in _templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _save() async {
    final template = _selectedTemplate;
    if (template == null) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      if (!template.isCustom) {
        await _saveBuiltin(template);
      } else if (_customMode == 'chat') {
        await _saveChatCustom();
      } else {
        await _saveDevCustom();
      }
      setState(() {
        _templateId = null;
        _saving = false;
        _resetCustomFields();
      });
      await _load();
    } catch (e) {
      setState(() {
        _saveError = "Couldn't create this Errand. Check the details and try again.";
        _saving = false;
      });
    }
  }

  Future<void> _saveBuiltin(_Template template) async {
    if (_builtinTrigger.trim().isEmpty) {
      throw Exception('trigger required');
    }
    await component.client.errand.createBuiltinErrand(
      component.accessToken,
      component.workspaceId,
      template.name,
      _builtinTrigger.trim(),
      template.builtinHandlerKey!,
      'api',
      permissionScope: 'readOnly',
      // Informational only for a built-in Errand — the tool-calling
      // engine (errand_tool_registry.dart) uses its own hardcoded
      // per-handler schema at runtime, not this field. Kept accurate
      // anyway for anyone inspecting the Errand later.
      inputSchemaJson: jsonEncode(const {}),
      sensitiveInputKeysJson: jsonEncode(const []),
    );
  }

  Future<void> _saveChatCustom() async {
    if (_chatName.trim().isEmpty || _chatDesc.trim().isEmpty || _chatSource == null) {
      throw Exception('missing fields');
    }
    final schema = {for (final tag in _neededInfo) tag: 'string'};

    if (_chatSource == 'webhook') {
      if (_chatWebhookUrl.trim().isEmpty) throw Exception('webhook url required');
      await component.client.errand.createWebhookErrand(
        component.accessToken,
        component.workspaceId,
        _chatName.trim(),
        _chatDesc.trim(),
        'api',
        _chatWebhookUrl.trim(),
        authHeaderName: _chatAuthHeaderName.trim().isEmpty ? null : _chatAuthHeaderName.trim(),
        authHeaderValue: _chatAuthHeaderValue.trim().isEmpty ? null : _chatAuthHeaderValue.trim(),
        // Explicit even though createWebhookErrand defaults this
        // server-side — the currently-generated kola_client predates
        // that default and still marks it required. Harmless either
        // way: 'readOnly' IS the default. Drop this once `dart run
        // serverpod generate` has been re-run and kola_client catches up.
        permissionScope: 'readOnly',
        inputSchemaJson: jsonEncode(schema),
        sensitiveInputKeysJson: jsonEncode(const []),
      );
    } else {
      if (_chatConnectionString.trim().isEmpty || _chatQuerySql.trim().isEmpty) {
        throw Exception('db fields required');
      }
      await component.client.errand.createDbCredentialErrand(
        component.accessToken,
        component.workspaceId,
        _chatName.trim(),
        _chatDesc.trim(),
        'api',
        _chatQuerySql.trim(),
        _chatConnectionString.trim(),
        // Same stale-generated-client note as above.
        permissionScope: 'readOnly',
        inputSchemaJson: jsonEncode(schema),
        sensitiveInputKeysJson: jsonEncode(const []),
      );
    }
  }

  Future<void> _saveDevCustom() async {
    if (_devName.trim().isEmpty || _devDesc.trim().isEmpty || _fulfillType == null) {
      throw Exception('missing fields');
    }
    final schema = {for (final f in _devFields) f.name: f.type};

    if (_fulfillType == 'webhook') {
      if (_devWebhookUrl.trim().isEmpty) throw Exception('webhook url required');
      await component.client.errand.createWebhookErrand(
        component.accessToken,
        component.workspaceId,
        _devName.trim(),
        _devDesc.trim(),
        'api',
        _devWebhookUrl.trim(),
        authHeaderName: _devAuthHeaderName.trim().isEmpty ? null : _devAuthHeaderName.trim(),
        authHeaderValue: _devAuthHeaderValue.trim().isEmpty ? null : _devAuthHeaderValue.trim(),
        // Same stale-generated-client note as _saveChatCustom above.
        permissionScope: 'readOnly',
        inputSchemaJson: jsonEncode(schema),
        sensitiveInputKeysJson: jsonEncode(const []),
      );
    } else if (_fulfillType == 'database') {
      if (_devConnectionString.trim().isEmpty || _devQuerySql.trim().isEmpty) {
        throw Exception('db fields required');
      }
      await component.client.errand.createDbCredentialErrand(
        component.accessToken,
        component.workspaceId,
        _devName.trim(),
        _devDesc.trim(),
        'api',
        _devQuerySql.trim(),
        _devConnectionString.trim(),
        permissionScope: 'readOnly',
        inputSchemaJson: jsonEncode(schema),
        sensitiveInputKeysJson: jsonEncode(const []),
      );
    } else {
      throw Exception('MCP fulfillment is not available yet');
    }
  }

  void _resetCustomFields() {
    _customMode = 'chat';
    _chatName = '';
    _chatDesc = '';
    _infoDraft = '';
    _neededInfo = [];
    _chatSource = null;
    _chatWebhookUrl = '';
    _chatAuthHeaderName = '';
    _chatAuthHeaderValue = '';
    _chatConnectionString = '';
    _chatQuerySql = '';
    _devName = '';
    _devDesc = '';
    _fieldDraft = '';
    _devFields = [];
    _fulfillType = null;
    _devWebhookUrl = '';
    _devAuthHeaderName = '';
    _devAuthHeaderValue = '';
    _devConnectionString = '';
    _devQuerySql = '';
  }

  Future<void> _toggleStatus(Errand errand) async {
    final next = errand.status == 'active' ? 'disabled' : 'active';
    setState(() => _togglingErrandId = errand.id);
    try {
      await component.client.errand.setErrandStatus(
        component.accessToken,
        component.workspaceId,
        errand.id!,
        next,
      );
      await _load();
    } catch (_) {
      setState(() => _loadError = "Couldn't update that Errand's status.");
    } finally {
      setState(() => _togglingErrandId = null);
    }
  }

  Future<void> _delete(Errand errand) async {
    setState(() => _deletingErrandId = errand.id);
    try {
      await component.client.errand.deleteErrand(
        component.accessToken,
        component.workspaceId,
        errand.id!,
      );
      await _load();
    } catch (_) {
      setState(() => _loadError = "Couldn't delete that Errand.");
    } finally {
      setState(() => _deletingErrandId = null);
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;box-sizing:border-box;'
            'padding:40px 32px 60px;display:flex;justify-content:center',
      },
      [
        div(
          attributes: {'style': 'max-width:1200px;width:100%'},
          [
            div(
              attributes: {
                'style': 'display:flex;align-items:center;justify-content:space-between;margin-bottom:20px',
              },
              [
                backLink(),
              ],
            ),
            div(
              attributes: {'style': 'margin-bottom:24px'},
              [
                div(
                  attributes: {
                    'style': "font-family:${KolaDashboardFonts.display};font-size:22px;font-weight:700;margin-bottom:6px",
                  },
                  [Component.text('New Errand')],
                ),
                div(
                  attributes: {
                    'style': 'font-size:14px;color:${KolaDashboardColors.mutedSecondary};line-height:1.5;max-width:640px',
                  },
                  [
                    Component.text(
                      'Errands are tools kola can call mid-conversation — the AI decides when to use one and figures out what values to pass.',
                    ),
                  ],
                ),
              ],
            ),
            div(
              attributes: {'style': 'display:flex;gap:24px;flex-wrap:wrap;align-items:flex-start'},
              [
                div(attributes: {'style': 'flex:1;min-width:380px;max-width:480px'}, [_detailsCard()]),
                div(attributes: {'style': 'flex:1;min-width:340px'}, [_errandsCard()]),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ── Details card ─────────────────────────────────────────────────────────

  Component _detailsCard() {
    final template = _selectedTemplate;
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:18px;overflow:hidden;'
            'background-image:radial-gradient(circle, rgba(255,255,255,0.04) 1.2px, transparent 1.2px);'
            'background-size:22px 22px',
      },
      [
        div(
          attributes: {
            'style':
                'padding:18px 20px;border-bottom:1px solid ${KolaDashboardColors.border};'
                'display:flex;align-items:center;justify-content:space-between',
          },
          [
            div(
              attributes: {'style': "font-family:${KolaDashboardFonts.display};font-size:15px;font-weight:600"},
              [Component.text('Details')],
            ),
            if (template != null)
              button(
                [Component.text('← Change type')],
                type: ButtonType.button,
                onClick: _backToPicker,
                attributes: {
                  'style':
                      'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                      'color:${KolaDashboardColors.mutedSecondary};border-radius:100px;padding:6px 12px;'
                      'font-size:12px;font-family:inherit;cursor:pointer',
                },
              ),
          ],
        ),

        if (template == null) _templatePicker(),
        if (template != null && !template.isCustom) _builtinForm(template),
        if (template != null && template.isCustom) _customForm(),

        if (template != null)
          div(
            attributes: {
              'style':
                  'padding:14px 20px;border-top:1px solid ${KolaDashboardColors.border};'
                  'display:flex;justify-content:flex-end;gap:10px',
            },
            [
              if (_saveError != null)
                div(
                  attributes: {
                    'style':
                        'flex:1;font-size:12.5px;color:#E8A8A8;display:flex;align-items:center',
                  },
                  [Component.text(_saveError!)],
                ),
              button(
                [Component.text('Cancel')],
                type: ButtonType.button,
                onClick: _backToPicker,
                attributes: {
                  'style':
                      'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                      'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:9px 18px;'
                      'font-size:13.5px;font-family:inherit;cursor:pointer',
                },
              ),
              button(
                [Component.text(_saving ? 'Saving…' : 'Save Errand')],
                type: ButtonType.button,
                disabled: _saving,
                onClick: _save,
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                      'border:none;border-radius:100px;padding:9px 20px;font-size:13.5px;font-weight:600;'
                      'font-family:inherit;cursor:pointer;opacity:${_saving ? '0.7' : '1'}',
                },
              ),
            ],
          ),
      ],
    );
  }

  Component _templatePicker() {
    return div(
      attributes: {'style': 'padding:20px;display:flex;flex-direction:column;gap:9px'},
      [
        div(
          attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:4px'},
          [Component.text('Choose what kind of Errand to create')],
        ),
        for (final t in _templates)
          div(
            events: {'click': (_) => _pickTemplate(t)},
            attributes: {
              'style':
                  'display:flex;align-items:center;gap:13px;padding:13px 14px;border:1.5px solid ${KolaDashboardColors.border};'
                  'border-radius:13px;cursor:pointer;background:${KolaDashboardColors.pill}',
            },
            [
              div(
                attributes: {
                  'style':
                      'width:36px;height:36px;border-radius:10px;background:${KolaDashboardColors.bg};'
                      'display:flex;align-items:center;justify-content:center;font-size:17px;flex:none',
                },
                [Component.text(t.icon)],
              ),
              div(
                attributes: {'style': 'min-width:0'},
                [
                  div(attributes: {'style': 'font-size:14px;font-weight:600'}, [Component.text(t.name)]),
                  div(
                    attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};line-height:1.4'},
                    [Component.text(t.desc)],
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Component _builtinForm(_Template template) {
    return div(
      attributes: {'style': 'padding:20px;display:flex;flex-direction:column;gap:16px'},
      [
        div(
          attributes: {
            'style':
                'display:flex;align-items:center;gap:11px;background:${KolaDashboardColors.pill};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:13px;padding:12px 14px',
          },
          [
            div(
              attributes: {
                'style':
                    'width:34px;height:34px;border-radius:9px;background:${KolaDashboardColors.bg};'
                    'display:flex;align-items:center;justify-content:center;font-size:16px;flex:none',
              },
              [Component.text(template.icon)],
            ),
            div([
              div(attributes: {'style': 'font-size:14px;font-weight:600'}, [Component.text(template.name)]),
              div(
                attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary}'},
                [Component.text(template.desc)],
              ),
            ]),
          ],
        ),
        _field(
          labelText: 'When should kola use this?',
          hint: 'plain language — the AI reads this',
          child: textarea(
            [Component.text(_builtinTrigger)],
            rows: 3,
            onInput: (v) => setState(() => _builtinTrigger = v),
            attributes: {'style': _inputStyle},
          ),
        ),
        div(
          attributes: {
            'style':
                'font-size:12px;color:${KolaDashboardColors.muted};background:${KolaDashboardColors.pill};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:11px;padding:11px 13px;line-height:1.5',
          },
          [
            Component.text(
              'kola will figure out what details to pass from the conversation — no fields to fill in for this Errand type.',
            ),
          ],
        ),
      ],
    );
  }

  Component _customForm() {
    return div([
      div(
        attributes: {
          'style':
              'display:flex;background:${KolaDashboardColors.pill};border-radius:100px;'
              'margin:14px 20px 0;padding:3px;width:fit-content',
        },
        [
          _modeTab('Describe it', _customMode == 'chat', () => setState(() => _customMode = 'chat')),
          _modeTab('Build it myself', _customMode == 'dev', () => setState(() => _customMode = 'dev')),
        ],
      ),
      if (_customMode == 'chat') _chatCustomForm() else _devCustomForm(),
    ]);
  }

  Component _modeTab(String label, bool active, void Function() onClick) => button(
    [Component.text(label)],
    type: ButtonType.button,
    onClick: onClick,
    attributes: {
      'style':
          'border:none;padding:7px 15px;border-radius:100px;font-size:12.5px;font-family:inherit;cursor:pointer;'
          'background:${active ? KolaDashboardColors.accent : 'transparent'};'
          'color:${active ? KolaDashboardColors.accentText : KolaDashboardColors.mutedSecondary}',
    },
  );

  Component _chatCustomForm() {
    return div(
      attributes: {'style': 'padding:18px 20px 20px;display:flex;flex-direction:column;gap:16px'},
      [
        _field(
          labelText: 'Name',
          child: input<String>(
            type: InputType.text,
            value: _chatName,
            onInput: (v) => setState(() => _chatName = v),
            attributes: {'style': _inputStyle, 'placeholder': 'Check order status'},
          ),
        ),
        _field(
          labelText: 'What does this Errand do, and when should kola use it?',
          child: textarea(
            [Component.text(_chatDesc)],
            rows: 3,
            onInput: (v) => setState(() => _chatDesc = v),
            attributes: {
              'style': _inputStyle,
              'placeholder': 'e.g. When a customer asks where their order is, look it up and tell them the status',
            },
          ),
        ),
        div([
          div(
            attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:8px'},
            [Component.text('What information will kola need to figure out? — just describe each, not exact values')],
          ),
          if (_neededInfo.isNotEmpty)
            div(
              attributes: {'style': 'display:flex;flex-wrap:wrap;gap:7px;margin-bottom:9px'},
              [for (final tag in _neededInfo) _infoChip(tag)],
            ),
          div(
            attributes: {'style': 'display:flex;gap:8px'},
            [
              input<String>(
                type: InputType.text,
                value: _infoDraft,
                onInput: (v) => setState(() => _infoDraft = v),
                attributes: {
                  'style':
                      'flex:1;box-sizing:border-box;background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
                      'border-radius:100px;padding:9px 14px;color:${KolaDashboardColors.text};font-family:inherit;font-size:13px',
                  'placeholder': 'e.g. order number',
                },
              ),
              button(
                [Component.text('Add')],
                type: ButtonType.button,
                onClick: _addInfoTag,
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
                      'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:9px 15px;'
                      'font-size:12.5px;font-family:inherit;cursor:pointer',
                },
              ),
            ],
          ),
        ]),
        div([
          div(
            attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:8px'},
            [Component.text('Where does this connect to?')],
          ),
          div(
            attributes: {'style': 'display:flex;gap:9px;flex-wrap:wrap'},
            [
              _sourceOption('A database or spreadsheet', 'database'),
              _sourceOption('A webhook / my developer', 'webhook'),
            ],
          ),
        ]),
        if (_chatSource == 'webhook') _webhookCredentialFields(isChat: true),
        if (_chatSource == 'database') _databaseCredentialFields(isChat: true),
      ],
    );
  }

  Component _infoChip(String tag) => div(
    attributes: {
      'style':
          'display:flex;align-items:center;gap:7px;background:${KolaDashboardColors.pill};'
          'border:1px solid ${KolaDashboardColors.border};border-radius:100px;padding:6px 6px 6px 12px;font-size:12.5px',
    },
    [
      Component.text(tag),
      span(
        events: {'click': (_) => setState(() => _neededInfo = _neededInfo.where((t) => t != tag).toList())},
        attributes: {
          'style':
              'cursor:pointer;color:${KolaDashboardColors.muted};width:15px;height:15px;border-radius:50%;'
              'background:${KolaDashboardColors.bg};display:flex;align-items:center;justify-content:center;font-size:10px',
        },
        [Component.text('✕')],
      ),
    ],
  );

  void _addInfoTag() {
    final v = _infoDraft.trim();
    if (v.isEmpty) return;
    setState(() {
      _neededInfo = [..._neededInfo, v];
      _infoDraft = '';
    });
  }

  Component _sourceOption(String label, String value) => div(
    events: {'click': (_) => setState(() => _chatSource = value)},
    attributes: {
      'style':
          'border:1.5px solid ${_chatSource == value ? KolaDashboardColors.accent : KolaDashboardColors.border};'
          'border-radius:11px;padding:11px 15px;font-size:13px;cursor:pointer;flex:1;min-width:150px;'
          'background:${KolaDashboardColors.pill}',
    },
    [Component.text(label)],
  );

  Component _devCustomForm() {
    return div(
      attributes: {'style': 'padding:18px 20px 20px;display:flex;flex-direction:column;gap:15px'},
      [
        _field(
          labelText: 'Name',
          child: input<String>(
            type: InputType.text,
            value: _devName,
            onInput: (v) => setState(() => _devName = v),
            attributes: {'style': _inputStyle},
          ),
        ),
        _field(
          labelText: 'Description',
          hint: 'used by the AI to decide when to call it',
          child: textarea(
            [Component.text(_devDesc)],
            rows: 2,
            onInput: (v) => setState(() => _devDesc = v),
            attributes: {'style': _inputStyle},
          ),
        ),
        div([
          div(
            attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:8px'},
            [Component.text('What information does this need? — kola infers the actual value at call time')],
          ),
          if (_devFields.isNotEmpty)
            div(
              attributes: {'style': 'display:flex;flex-direction:column;gap:7px;margin-bottom:9px'},
              [for (final f in _devFields) _devFieldRow(f)],
            ),
          div(
            attributes: {'style': 'display:flex;gap:8px'},
            [
              input<String>(
                type: InputType.text,
                value: _fieldDraft,
                onInput: (v) => setState(() => _fieldDraft = v),
                attributes: {
                  'style':
                      'flex:1;box-sizing:border-box;background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
                      'border-radius:9px;padding:9px 13px;color:${KolaDashboardColors.text};font-family:inherit;font-size:13px',
                  'placeholder': 'e.g. order_id',
                },
              ),
              button(
                [Component.text('Add field')],
                type: ButtonType.button,
                onClick: _addDevField,
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
                      'color:${KolaDashboardColors.navInactiveText};border-radius:9px;padding:9px 15px;'
                      'font-size:12.5px;font-family:inherit;cursor:pointer',
                },
              ),
            ],
          ),
        ]),
        div([
          div(
            attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:8px'},
            [Component.text('Fulfillment type')],
          ),
          div(
            attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap'},
            [
              _fulfillOption('Webhook URL', 'webhook'),
              _fulfillOption('Database credential', 'database'),
              _fulfillOption('MCP (soon)', 'mcp', disabled: true),
            ],
          ),
        ]),
        if (_fulfillType == 'webhook') _webhookCredentialFields(isChat: false),
        if (_fulfillType == 'database') _databaseCredentialFields(isChat: false),
        button(
          [Component.text('Test this Errand')],
          type: ButtonType.button,
          disabled: true,
          attributes: {
            'style':
                'align-self:flex-start;background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
                'color:${KolaDashboardColors.muted};border-radius:100px;padding:9px 17px;font-size:13px;'
                'font-family:inherit;cursor:not-allowed',
            'title': 'Save this Errand first — testing an unsaved draft isn\'t supported yet.',
          },
        ),
      ],
    );
  }

  Component _devFieldRow(_DevField f) => div(
    attributes: {
      'style':
          'display:flex;align-items:center;gap:8px;background:${KolaDashboardColors.pill};'
          'border:1px solid ${KolaDashboardColors.border};border-radius:9px;padding:8px 11px',
    },
    [
      div(attributes: {'style': 'flex:1;font-size:13px'}, [Component.text(f.name)]),
      span(
        events: {
          'click': (_) => setState(() {
            _devFields = _devFields.map((x) => x == f ? x.cycled() : x).toList();
          }),
        },
        attributes: {
          'style':
              "font-family:${KolaDashboardFonts.mono};font-size:11px;color:#9BE6C7;background:${KolaDashboardColors.bg};"
              'border-radius:6px;padding:3px 8px;cursor:pointer',
        },
        [Component.text(f.type)],
      ),
      span(
        events: {'click': (_) => setState(() => _devFields = _devFields.where((x) => x != f).toList())},
        attributes: {
          'style':
              'cursor:pointer;color:${KolaDashboardColors.muted};width:16px;height:16px;border-radius:50%;'
              'background:${KolaDashboardColors.bg};display:flex;align-items:center;justify-content:center;font-size:10px',
        },
        [Component.text('✕')],
      ),
    ],
  );

  void _addDevField() {
    final v = _fieldDraft.trim();
    if (v.isEmpty) return;
    setState(() {
      _devFields = [..._devFields, _DevField(v, 'string')];
      _fieldDraft = '';
    });
  }

  Component _fulfillOption(String label, String value, {bool disabled = false}) => div(
    events: disabled ? {} : {'click': (_) => setState(() => _fulfillType = value)},
    attributes: {
      'style':
          'border:1.5px solid ${_fulfillType == value ? KolaDashboardColors.accent : KolaDashboardColors.border};'
          'border-radius:9px;padding:8px 13px;font-size:12.5px;'
          'cursor:${disabled ? 'not-allowed' : 'pointer'};background:${KolaDashboardColors.pill};'
          'color:${disabled ? KolaDashboardColors.muted : KolaDashboardColors.text}',
    },
    [Component.text(label)],
  );

  Component _webhookCredentialFields({required bool isChat}) {
    final url = isChat ? _chatWebhookUrl : _devWebhookUrl;
    final headerName = isChat ? _chatAuthHeaderName : _devAuthHeaderName;
    final headerValue = isChat ? _chatAuthHeaderValue : _devAuthHeaderValue;
    return div(
      attributes: {
        'style':
            'display:flex;flex-direction:column;gap:10px;background:${KolaDashboardColors.pill};'
            'border:1px solid ${KolaDashboardColors.border};border-radius:12px;padding:14px',
      },
      [
        div(
          attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary}'},
          [Component.text('Webhook connection')],
        ),
        _field(
          labelText: 'URL',
          child: input<String>(
            type: InputType.url,
            value: url,
            onInput: (v) => setState(() => isChat ? _chatWebhookUrl = v : _devWebhookUrl = v),
            attributes: {'style': _inputStyle, 'placeholder': 'https://your-app.com/kola-hook'},
          ),
        ),
        div(
          attributes: {'style': 'display:flex;gap:10px'},
          [
            div(
              attributes: {'style': 'flex:1'},
              [
                _field(
                  labelText: 'Auth header name (optional)',
                  child: input<String>(
                    type: InputType.text,
                    value: headerName,
                    onInput: (v) => setState(() => isChat ? _chatAuthHeaderName = v : _devAuthHeaderName = v),
                    attributes: {'style': _inputStyle, 'placeholder': 'x-api-key'},
                  ),
                ),
              ],
            ),
            div(
              attributes: {'style': 'flex:1'},
              [
                _field(
                  labelText: 'Auth header value (optional)',
                  child: input<String>(
                    type: InputType.password,
                    value: headerValue,
                    onInput: (v) => setState(() => isChat ? _chatAuthHeaderValue = v : _devAuthHeaderValue = v),
                    attributes: {'style': _inputStyle},
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Component _databaseCredentialFields({required bool isChat}) {
    final connectionString = isChat ? _chatConnectionString : _devConnectionString;
    final querySql = isChat ? _chatQuerySql : _devQuerySql;
    return div(
      attributes: {
        'style':
            'display:flex;flex-direction:column;gap:10px;background:${KolaDashboardColors.pill};'
            'border:1px solid ${KolaDashboardColors.border};border-radius:12px;padding:14px',
      },
      [
        div(
          attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary}'},
          [Component.text('Database connection')],
        ),
        _field(
          labelText: 'Connection string',
          child: input<String>(
            type: InputType.password,
            value: connectionString,
            onInput: (v) => setState(() => isChat ? _chatConnectionString = v : _devConnectionString = v),
            attributes: {'style': _inputStyle, 'placeholder': 'postgresql://user:pass@host:5432/db'},
          ),
        ),
        _field(
          labelText: 'Query template',
          hint: 'one pre-approved query, e.g. select * from orders where id = @orderId',
          child: textarea(
            [Component.text(querySql)],
            rows: 2,
            onInput: (v) => setState(() => isChat ? _chatQuerySql = v : _devQuerySql = v),
            attributes: {
              'style': '$_inputStyle;font-family:${KolaDashboardFonts.mono}',
              'placeholder': 'select status from orders where id = @orderId',
            },
          ),
        ),
      ],
    );
  }

  // ── Errands list card ────────────────────────────────────────────────────

  Component _errandsCard() {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:18px;overflow:hidden',
      },
      [
        div(
          attributes: {
            'style':
                "padding:18px 20px;border-bottom:1px solid ${KolaDashboardColors.border};font-family:${KolaDashboardFonts.display};"
                'font-size:15px;font-weight:600',
          },
          [Component.text('Your Errands')],
        ),
        _errandsList(),
      ],
    );
  }

  Component _errandsList() {
    if (_loadError != null) return _emptyState(_loadError!);
    final errands = _errands;
    if (errands == null) return _emptyState('Loading…');
    if (errands.isEmpty) return _emptyState('No Errands yet — create one on the left.');
    return div(
      attributes: {'style': 'display:flex;flex-direction:column'},
      [for (final e in errands) _errandRow(e)],
    );
  }

  Component _emptyState(String text) => div(
    attributes: {
      'style':
          'padding:32px 20px;text-align:center;color:${KolaDashboardColors.muted};font-size:13.5px',
    },
    [Component.text(text)],
  );

  Component _errandRow(Errand errand) {
    final isLive = errand.status == 'active';
    final isToggling = _togglingErrandId == errand.id;
    final isDeleting = _deletingErrandId == errand.id;
    return div(
      attributes: {
        'style':
            'display:flex;align-items:center;gap:13px;padding:15px 20px;border-bottom:1px solid ${KolaDashboardColors.pill}',
      },
      [
        div(
          attributes: {
            'style':
                'width:36px;height:36px;border-radius:10px;background:${KolaDashboardColors.pill};'
                'display:flex;align-items:center;justify-content:center;font-size:17px;flex:none',
          },
          [Component.text(_iconFor(errand))],
        ),
        div(
          attributes: {'style': 'min-width:0;flex:1'},
          [
            div(attributes: {'style': 'font-size:14px;font-weight:600;margin-bottom:2px'}, [Component.text(errand.name)]),
            div(
              attributes: {
                'style':
                    'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};line-height:1.4;overflow:hidden;'
                    'text-overflow:ellipsis;white-space:nowrap',
              },
              [Component.text(errand.descriptionForAi)],
            ),
          ],
        ),
        div(
          events: isToggling ? {} : {'click': (_) => _toggleStatus(errand)},
          attributes: {
            'style':
                'display:flex;align-items:center;gap:6px;background:${isLive ? "rgba(126,216,176,0.1)" : KolaDashboardColors.pill};'
                'border:1px solid ${isLive ? "rgba(126,216,176,0.3)" : KolaDashboardColors.border};border-radius:100px;'
                'padding:5px 11px;cursor:${isToggling ? 'default' : 'pointer'};flex:none;opacity:${isToggling ? '0.6' : '1'}',
          },
          [
            span(
              attributes: {
                'style': 'width:6px;height:6px;border-radius:50%;background:${isLive ? '#7ED8B0' : KolaDashboardColors.muted}',
              },
              [],
            ),
            span(
              attributes: {
                'style': 'font-size:11.5px;color:${isLive ? '#7ED8B0' : KolaDashboardColors.mutedSecondary};font-weight:600',
              },
              [Component.text(isLive ? 'Live' : 'Disabled')],
            ),
          ],
        ),
        if (!isLive)
          button(
            [Component.text(isDeleting ? 'Deleting…' : 'Delete')],
            type: ButtonType.button,
            disabled: isDeleting,
            onClick: () => _delete(errand),
            attributes: {
              'style':
                  'background:transparent;border:1px solid #3A2622;color:#D97D6B;border-radius:100px;'
                  'padding:5px 11px;font-size:11.5px;font-family:inherit;cursor:pointer;flex:none;'
                  'opacity:${isDeleting ? '0.6' : '1'}',
            },
          ),
      ],
    );
  }

  String _iconFor(Errand errand) {
    if (errand.source == 'builtin') {
      for (final t in _templates) {
        if (t.builtinHandlerKey == errand.builtinHandlerKey) return t.icon;
      }
      return '⚙️';
    }
    if (errand.source == 'webhook') return '🔌';
    if (errand.source == 'dbCredential') return '🗄️';
    return '❓';
  }

  // ── Shared styles ─────────────────────────────────────────────────────────

  static const _inputStyle =
      'width:100%;box-sizing:border-box;background:#141416;border:1px solid #2C2A28;border-radius:10px;'
      'padding:10px 12px;font-size:13.5px;color:#F3EEE7;font-family:inherit;resize:none';

  Component _field({required String labelText, String? hint, required Component child}) => div(
    attributes: {},
    [
      div(
        attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:6px'},
        [
          Component.text(labelText),
          if (hint != null)
            span(attributes: {'style': 'color:${KolaDashboardColors.muted}'}, [Component.text(' — $hint')]),
        ],
      ),
      child,
    ],
  );
}

class _DevField {
  const _DevField(this.name, this.type);
  final String name;
  final String type;

  static const _typeOrder = ['string', 'number', 'date', 'boolean'];

  _DevField cycled() {
    final next = _typeOrder[(_typeOrder.indexOf(type) + 1) % _typeOrder.length];
    return _DevField(name, next);
  }

  @override
  bool operator ==(Object other) => other is _DevField && other.name == name && other.type == type;

  @override
  int get hashCode => Object.hash(name, type);
}
