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
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';
import '../components/shell/page_help_button.dart';

/// One selectable template card — the built-in handlers that are still
/// registered as Errands (BuiltinErrandExecutor.registrableHandlerKeys
/// in builtin_errand_executor.dart), plus 'custom' for webhook/database
/// Errands. [builtinHandlerKey] is null only for 'custom'.
///
/// 'collectPayment' and 'bookCalendarEvent' are deliberately absent —
/// see the comment above the removed collectPayment template below for
/// why.
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
    defaultTrigger: "When a customer is frustrated, asks for a human, or kolaa can't resolve the issue.",
  ),
  // 'collectPayment' removed as a selectable template (Connect Gate,
  // subphase 4b): collecting payment is no longer something an owner
  // registers as an Errand — it becomes available to the agent
  // automatically the moment a payment gateway (Paystack/Flutterwave)
  // is connected under Integrations. See
  // connector_capability_registry.dart on the server. Same is true of
  // booking a calendar event once Google Calendar is connected, which
  // is why there's no 'bookCalendarEvent' template here either.
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
    desc: 'Submit a Meta-approved template so kolaa can send your product list to a customer who asked, as cheaply as WhatsApp allows',
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

  // Gate 5 — guided builder state, "Describe it" (chat) mode.
  List<Map<String, dynamic>>? _chatSchemaTables;
  bool _chatSchemaLoading = false;
  String? _chatSchemaError;
  Map<String, dynamic>? _chatWebhookTestResult;
  bool _chatWebhookTesting = false;
  String? _chatWebhookTestError;

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

  // Gate 5 — guided builder state, "Build it myself" (dev) mode.
  List<Map<String, dynamic>>? _devSchemaTables;
  bool _devSchemaLoading = false;
  String? _devSchemaError;
  Map<String, dynamic>? _devWebhookTestResult;
  bool _devWebhookTesting = false;
  String? _devWebhookTestError;

  bool _saving = false;
  String? _saveError;

  // Gate 5's second half — "map to customers" panel, expandable per row
  // in the already-saved Errands list (see _errandRow / _mappingPanel).
  // Only ever one open at a time; null means none.
  int? _mappingErrandId;
  bool _mappingLoading = false;
  String? _mappingLoadError;
  bool _mappingEnabled = false;
  String _mappingPhoneColumn = '';
  String _mappingEmailColumn = '';
  String _mappingNameColumn = '';
  bool _mappingSaving = false;
  String? _mappingSaveError;
  bool _mappingJustSaved = false;

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
    _chatSchemaTables = null;
    _chatSchemaLoading = false;
    _chatSchemaError = null;
    _chatWebhookTestResult = null;
    _chatWebhookTesting = false;
    _chatWebhookTestError = null;
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
    _devSchemaTables = null;
    _devSchemaLoading = false;
    _devSchemaError = null;
    _devWebhookTestResult = null;
    _devWebhookTesting = false;
    _devWebhookTestError = null;
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

  // ── Gate 5's second half — map to customers ─────────────────────────────
  //
  // "Someone else's system, mapped to entities." Only meaningful for a
  // dbCredential Errand — see ErrandEndpoint.setEntityMapping
  // (kola_server) on why. Expands/collapses in place under the Errand's
  // row rather than opening a second flow, since there is nothing else
  // to configure beyond three column names.

  Future<void> _toggleMappingPanel(Errand errand) async {
    final id = errand.id;
    if (id == null) return;

    if (_mappingErrandId == id) {
      setState(() => _mappingErrandId = null);
      return;
    }

    setState(() {
      _mappingErrandId = id;
      _mappingLoading = true;
      _mappingLoadError = null;
      _mappingSaveError = null;
      _mappingJustSaved = false;
    });

    try {
      final json = await component.client.errand.getEntityMapping(
        component.accessToken,
        component.workspaceId,
        id,
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      setState(() {
        _mappingEnabled = decoded['enabled'] == true;
        _mappingPhoneColumn = (decoded['phoneColumn'] as String?) ?? '';
        _mappingEmailColumn = (decoded['emailColumn'] as String?) ?? '';
        _mappingNameColumn = (decoded['nameColumn'] as String?) ?? '';
        _mappingLoading = false;
      });
    } catch (_) {
      setState(() {
        _mappingLoadError = "Couldn't load this Errand's mapping.";
        _mappingLoading = false;
      });
    }
  }

  Future<void> _saveMapping(Errand errand) async {
    final id = errand.id;
    if (id == null) return;

    if (_mappingEnabled && _mappingPhoneColumn.trim().isEmpty && _mappingEmailColumn.trim().isEmpty) {
      setState(() {
        _mappingSaveError =
            'Add at least a phone or email column name — kola needs one to match customers on.';
      });
      return;
    }

    setState(() {
      _mappingSaving = true;
      _mappingSaveError = null;
      _mappingJustSaved = false;
    });

    final mapping = {
      'enabled': _mappingEnabled,
      'phoneColumn': _mappingPhoneColumn.trim(),
      'emailColumn': _mappingEmailColumn.trim(),
      'nameColumn': _mappingNameColumn.trim(),
    };

    try {
      await component.client.errand.setEntityMapping(
        component.accessToken,
        component.workspaceId,
        id,
        jsonEncode(mapping),
      );
      setState(() {
        _mappingSaving = false;
        _mappingJustSaved = true;
      });
    } catch (_) {
      setState(() {
        _mappingSaving = false;
        _mappingSaveError = "Couldn't save this mapping. Check the details and try again.";
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;height:100svh;overflow-y:auto;box-sizing:border-box;'
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
                const PageHelpButton(
                  pageKey: 'errands',
                  body: [
                    "Errands are tools kola can call mid-conversation — "
                        "the AI decides when to use one and figures out "
                        "what values to pass, rather than you triggering "
                        "it by hand.",
                    "Pick a built-in template on the left for common "
                        "cases (payment links, tickets, reminders), or "
                        "build a custom one that calls a webhook or "
                        "database credential you supply.",
                  ],
                ),
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
                      'Errands are tools kolaa can call mid-conversation — the AI decides when to use one and figures out what values to pass.',
                    ),
                  ],
                ),
              ],
            ),
            div(
              attributes: {'style': 'display:flex;gap:24px;flex-wrap:wrap;align-items:flex-start'},
              [
                // min-width:380px/340px inside a wrapping flex row meant
                // either card, alone, was already wider than a 375px
                // phone — the row didn't overflow (it wraps), but each
                // card did, since `min-width` still floors below its own
                // container. min() lets the floor give way to the
                // viewport instead of past it, and stops shrinking once
                // there's room to.
                div(attributes: {'style': 'flex:1;min-width:min(380px,100%);max-width:480px;box-sizing:border-box'}, [_detailsCard()]),
                div(attributes: {'style': 'flex:1;min-width:min(340px,100%);box-sizing:border-box'}, [_errandsCard()]),
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
          labelText: 'When should kolaa use this?',
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
              'kolaa will figure out what details to pass from the conversation — no fields to fill in for this Errand type.',
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
          labelText: 'What does this Errand do, and when should kolaa use it?',
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
            [Component.text('What information will kolaa need to figure out? — just describe each, not exact values')],
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
            [Component.text('What information does this need? — kolaa infers the actual value at call time')],
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

  // ── Gate 5 — guided builder actions ─────────────────────────────────────
  //
  // Direction doc (Kolaa Rev 5, Part VIII, Gate 5): "Guided REST builder +
  // read-only Postgres with schema discovery." Both actions below call a
  // new endpoint BEFORE the Errand is saved — see errand_endpoint.dart's
  // discoverDbSchema/testWebhookErrand — so a wrong connection string or a
  // broken URL shows up here, not the first time a real conversation
  // needs it.

  Future<void> _discoverSchema({required bool isChat}) async {
    final connectionString = (isChat ? _chatConnectionString : _devConnectionString).trim();
    if (connectionString.isEmpty) {
      setState(() {
        if (isChat) {
          _chatSchemaError = 'Enter a connection string first.';
        } else {
          _devSchemaError = 'Enter a connection string first.';
        }
      });
      return;
    }

    setState(() {
      if (isChat) {
        _chatSchemaLoading = true;
        _chatSchemaError = null;
        _chatSchemaTables = null;
      } else {
        _devSchemaLoading = true;
        _devSchemaError = null;
        _devSchemaTables = null;
      }
    });

    try {
      final resultJson = await component.client.errand.discoverDbSchema(
        component.accessToken,
        component.workspaceId,
        connectionString,
      );
      final decoded = jsonDecode(resultJson) as Map<String, dynamic>;
      final tables = (decoded['tables'] as List).cast<Map<String, dynamic>>();
      setState(() {
        if (isChat) {
          _chatSchemaTables = tables;
          _chatSchemaLoading = false;
        } else {
          _devSchemaTables = tables;
          _devSchemaLoading = false;
        }
      });
    } catch (_) {
      setState(() {
        if (isChat) {
          _chatSchemaError = "Couldn't read this database's schema — check the connection string.";
          _chatSchemaLoading = false;
        } else {
          _devSchemaError = "Couldn't read this database's schema — check the connection string.";
          _devSchemaLoading = false;
        }
      });
    }
  }

  /// Turns a picked table (and optional column, for a WHERE clause) into
  /// a starter query template — a guess the owner can still edit, not a
  /// final answer. [columnName] null means "just the table", producing a
  /// broad preview query; non-null produces the far more common
  /// "look this customer's row up by X" shape.
  void _applySchemaPick({
    required bool isChat,
    required String tableName,
    String? columnName,
  }) {
    final query = columnName == null
        ? 'select * from $tableName limit 20'
        : 'select * from $tableName where $columnName = @$columnName';
    setState(() {
      if (isChat) {
        _chatQuerySql = query;
      } else {
        _devQuerySql = query;
      }
    });
  }

  Future<void> _testWebhook({required bool isChat}) async {
    final url = (isChat ? _chatWebhookUrl : _devWebhookUrl).trim();
    if (url.isEmpty) {
      setState(() {
        if (isChat) {
          _chatWebhookTestError = 'Enter a URL first.';
        } else {
          _devWebhookTestError = 'Enter a URL first.';
        }
      });
      return;
    }

    final headerName = (isChat ? _chatAuthHeaderName : _devAuthHeaderName).trim();
    final headerValue = (isChat ? _chatAuthHeaderValue : _devAuthHeaderValue).trim();
    // Sample payload built from whatever input fields have been declared
    // so far (the "needed info" tags in chat mode, the typed fields in
    // dev mode) — same shape a real invocation's input would eventually
    // be, filled with placeholder values purely to exercise the
    // connection.
    final fieldNames = isChat ? _neededInfo : _devFields.map((f) => f.name).toList();
    final sampleInput = {for (final name in fieldNames) name: 'test'};

    setState(() {
      if (isChat) {
        _chatWebhookTesting = true;
        _chatWebhookTestError = null;
        _chatWebhookTestResult = null;
      } else {
        _devWebhookTesting = true;
        _devWebhookTestError = null;
        _devWebhookTestResult = null;
      }
    });

    try {
      final resultJson = await component.client.errand.testWebhookErrand(
        component.accessToken,
        component.workspaceId,
        url,
        jsonEncode(sampleInput),
        authHeaderName: headerName.isEmpty ? null : headerName,
        authHeaderValue: headerValue.isEmpty ? null : headerValue,
      );
      final decoded = jsonDecode(resultJson) as Map<String, dynamic>;
      setState(() {
        if (isChat) {
          _chatWebhookTestResult = decoded;
          _chatWebhookTesting = false;
        } else {
          _devWebhookTestResult = decoded;
          _devWebhookTesting = false;
        }
      });
    } catch (_) {
      setState(() {
        if (isChat) {
          _chatWebhookTestError = "Couldn't reach this webhook.";
          _chatWebhookTesting = false;
        } else {
          _devWebhookTestError = "Couldn't reach this webhook.";
          _devWebhookTesting = false;
        }
      });
    }
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
        _webhookTestSection(isChat: isChat),
      ],
    );
  }

  /// Gate 5 — "test this before you save it" for a webhook Errand. A
  /// button that fires an unsaved test call (see _testWebhook above),
  /// plus whatever the last test returned: a plain status line if it
  /// worked, and a body preview either way so the owner can tell a
  /// wrong URL from a URL that's reachable but answering the wrong
  /// thing.
  Component _webhookTestSection({required bool isChat}) {
    final testing = isChat ? _chatWebhookTesting : _devWebhookTesting;
    final error = isChat ? _chatWebhookTestError : _devWebhookTestError;
    final result = isChat ? _chatWebhookTestResult : _devWebhookTestResult;

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            button(
              [Component.text(testing ? 'Testing…' : 'Test this webhook')],
              type: ButtonType.button,
              disabled: testing,
              onClick: () => _testWebhook(isChat: isChat),
              attributes: {
                'style':
                    'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                    'color:${KolaDashboardColors.text};border-radius:100px;padding:7px 14px;'
                    'font-size:12.5px;font-family:inherit;cursor:pointer;opacity:${testing ? '0.7' : '1'}',
              },
            ),
            if (result != null)
              span(
                attributes: {
                  'style':
                      'font-size:12px;font-weight:600;'
                      'color:${result['ok'] == true ? '#7ED9A8' : '#E8A8A8'}',
                },
                [
                  Component.text(
                    result['ok'] == true
                        ? 'Reached — HTTP ${result['statusCode']} (${result['latencyMs']}ms)'
                        : (result['errorMessage'] as String? ?? 'Failed'),
                  ),
                ],
              ),
          ],
        ),
        if (error != null)
          div(
            attributes: {'style': 'font-size:12px;color:#E8A8A8'},
            [Component.text(error)],
          ),
        if (result != null && result['bodyPreview'] != null)
          div(
            attributes: {
              'style':
                  'background:${KolaDashboardColors.bg};border:1px solid ${KolaDashboardColors.border};'
                  'border-radius:8px;padding:10px;font-size:11.5px;font-family:${KolaDashboardFonts.mono};'
                  'color:${KolaDashboardColors.mutedSecondary};max-height:120px;overflow:auto;'
                  'white-space:pre-wrap;word-break:break-all',
            },
            [Component.text(result['bodyPreview'] as String)],
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
        _schemaDiscoverySection(isChat: isChat),
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

  /// Gate 5's namesake feature: "Discover schema" reads the database's
  /// own information_schema (never a row of business data — see
  /// DbSchemaDiscoveryService's header on the server) and turns the
  /// result into a table/column picker. Clicking a table drops a
  /// starter "select * from X limit 20" into the query template above;
  /// clicking a column under it narrows that to a "where column = @column"
  /// lookup — either way, a starting point the owner edits rather than
  /// hand-typing SQL against a schema they're guessing at.
  Component _schemaDiscoverySection({required bool isChat}) {
    final loading = isChat ? _chatSchemaLoading : _devSchemaLoading;
    final error = isChat ? _chatSchemaError : _devSchemaError;
    final tables = isChat ? _chatSchemaTables : _devSchemaTables;

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:8px'},
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px'},
          [
            button(
              [Component.text(loading ? 'Reading schema…' : 'Discover schema')],
              type: ButtonType.button,
              disabled: loading,
              onClick: () => _discoverSchema(isChat: isChat),
              attributes: {
                'style':
                    'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                    'color:${KolaDashboardColors.text};border-radius:100px;padding:7px 14px;'
                    'font-size:12.5px;font-family:inherit;cursor:pointer;opacity:${loading ? '0.7' : '1'}',
              },
            ),
            if (tables != null)
              span(
                attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary}'},
                [Component.text('${tables.length} table${tables.length == 1 ? '' : 's'} found — click one')],
              ),
          ],
        ),
        if (error != null)
          div(
            attributes: {'style': 'font-size:12px;color:#E8A8A8'},
            [Component.text(error)],
          ),
        if (tables != null && tables.isEmpty)
          div(
            attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.muted}'},
            [Component.text('No tables found in the public schema.')],
          ),
        if (tables != null && tables.isNotEmpty)
          div(
            attributes: {
              'style':
                  'display:flex;flex-direction:column;gap:6px;max-height:220px;overflow:auto;'
                  'background:${KolaDashboardColors.bg};border:1px solid ${KolaDashboardColors.border};'
                  'border-radius:8px;padding:8px',
            },
            [for (final t in tables) _schemaTableRow(isChat: isChat, table: t)],
          ),
      ],
    );
  }

  Component _schemaTableRow({required bool isChat, required Map<String, dynamic> table}) {
    final tableName = table['name'] as String;
    final columns = (table['columns'] as List).cast<Map<String, dynamic>>();
    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:4px'},
      [
        div(
          events: {'click': (_) => _applySchemaPick(isChat: isChat, tableName: tableName)},
          attributes: {
            'style':
                'cursor:pointer;font-size:12.5px;font-family:${KolaDashboardFonts.mono};'
                'color:${KolaDashboardColors.text};font-weight:600',
          },
          [Component.text(tableName)],
        ),
        div(
          attributes: {'style': 'display:flex;flex-wrap:wrap;gap:5px;padding-left:10px'},
          [
            for (final c in columns)
              span(
                events: {
                  'click': (_) => _applySchemaPick(
                    isChat: isChat,
                    tableName: tableName,
                    columnName: c['name'] as String,
                  ),
                },
                attributes: {
                  'style':
                      'cursor:pointer;font-size:11px;font-family:${KolaDashboardFonts.mono};'
                      'color:${KolaDashboardColors.mutedSecondary};background:${KolaDashboardColors.pill};'
                      'border-radius:6px;padding:2px 7px',
                },
                [Component.text('${c['name']}: ${c['dataType']}')],
              ),
          ],
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
      [
        for (final e in errands) ...[
          _errandRow(e),
          if (_mappingErrandId == e.id) _mappingPanel(e),
        ],
      ],
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
        if (errand.source == 'dbCredential')
          _mappingToggleChip(errand),
        // Phase 13d — links into automation_runs_page.dart, the new
        // read-only run-history view. Not part of the original mockup
        // (this row predates it); added because a run history that
        // exists but has no entry point from anywhere is as good as not
        // existing.
        Link(
          to: '/errands/${errand.id}/runs',
          attributes: {
            'style': 'display:flex;align-items:center;gap:6px;'
                'background:${KolaDashboardColors.pill};'
                'border:1px solid ${KolaDashboardColors.border};'
                'border-radius:100px;padding:5px 11px;flex:none;'
                'text-decoration:none;font-size:11.5px;font-weight:600;'
                'color:${KolaDashboardColors.mutedSecondary}',
          },
          children: [Component.text('History')],
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

  /// Pill that opens/closes [_mappingPanel] for a dbCredential Errand —
  /// same shape as the Live/Disabled status pill just to its right, so
  /// it reads as one family of row-level controls rather than a
  /// bolted-on extra.
  Component _mappingToggleChip(Errand errand) {
    final isOpen = _mappingErrandId == errand.id;
    return div(
      events: {'click': (_) => _toggleMappingPanel(errand)},
      attributes: {
        'style':
            'display:flex;align-items:center;gap:6px;'
            'background:${isOpen ? KolaDashboardColors.accent : KolaDashboardColors.pill};'
            'border:1px solid ${isOpen ? KolaDashboardColors.accent : KolaDashboardColors.border};'
            'border-radius:100px;padding:5px 11px;cursor:pointer;flex:none',
      },
      [
        span(
          attributes: {
            'style':
                'font-size:11.5px;font-weight:600;'
                'color:${isOpen ? KolaDashboardColors.accentText : KolaDashboardColors.mutedSecondary}',
          },
          [Component.text('🔗 Map to customers')],
        ),
      ],
    );
  }

  /// Expanded under a dbCredential Errand's row when [_mappingErrandId]
  /// matches it. Same "pill card" treatment as _webhookCredentialFields/
  /// _databaseCredentialFields above (background: .pill, 12px radius,
  /// 14px padding) so it reads as the same kind of surface rather than a
  /// new visual language.
  Component _mappingPanel(Errand errand) {
    return div(
      attributes: {
        'style':
            'padding:0 20px 18px;border-bottom:1px solid ${KolaDashboardColors.pill};'
            'background:${KolaDashboardColors.bg}',
      },
      [
        div(
          attributes: {
            'style':
                'display:flex;flex-direction:column;gap:12px;background:${KolaDashboardColors.pill};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:12px;padding:14px',
          },
          [
            div(
              attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary}'},
              [
                Component.text(
                  "Map this Errand's query results to customers — kola resolves or creates a "
                  'Customer for each row using the columns below, the same identity matching '
                  'already used for Paystack and Flutterwave.',
                ),
              ],
            ),
            if (_mappingLoading)
              div(
                attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.muted}'},
                [Component.text('Loading…')],
              ),
            if (_mappingLoadError != null)
              div(
                attributes: {'style': 'font-size:12px;color:#E8A8A8'},
                [Component.text(_mappingLoadError!)],
              ),
            if (!_mappingLoading && _mappingLoadError == null) ...[
              _mappingEnabledToggle(),
              if (_mappingEnabled) ...[
                div(
                  attributes: {'style': 'display:flex;gap:10px'},
                  [
                    div(
                      attributes: {'style': 'flex:1'},
                      [
                        _field(
                          labelText: 'Phone column',
                          hint: 'exact column name from your query results',
                          child: input<String>(
                            type: InputType.text,
                            value: _mappingPhoneColumn,
                            onInput: (v) => setState(() {
                              _mappingPhoneColumn = v;
                              _mappingJustSaved = false;
                            }),
                            attributes: {'style': _inputStyle, 'placeholder': 'phone'},
                          ),
                        ),
                      ],
                    ),
                    div(
                      attributes: {'style': 'flex:1'},
                      [
                        _field(
                          labelText: 'Email column',
                          child: input<String>(
                            type: InputType.text,
                            value: _mappingEmailColumn,
                            onInput: (v) => setState(() {
                              _mappingEmailColumn = v;
                              _mappingJustSaved = false;
                            }),
                            attributes: {'style': _inputStyle, 'placeholder': 'email'},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _field(
                  labelText: 'Name column (optional)',
                  child: input<String>(
                    type: InputType.text,
                    value: _mappingNameColumn,
                    onInput: (v) => setState(() {
                      _mappingNameColumn = v;
                      _mappingJustSaved = false;
                    }),
                    attributes: {'style': _inputStyle, 'placeholder': 'customer_name'},
                  ),
                ),
              ],
              div(
                attributes: {'style': 'display:flex;align-items:center;gap:10px'},
                [
                  button(
                    [Component.text(_mappingSaving ? 'Saving…' : 'Save mapping')],
                    type: ButtonType.button,
                    disabled: _mappingSaving,
                    onClick: () => _saveMapping(errand),
                    attributes: {
                      'style':
                          'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                          'border:none;border-radius:100px;padding:7px 16px;font-size:12.5px;font-weight:600;'
                          'font-family:inherit;cursor:pointer;opacity:${_mappingSaving ? '0.7' : '1'}',
                    },
                  ),
                  if (_mappingJustSaved)
                    span(
                      attributes: {'style': 'font-size:12px;color:#7ED9A8;font-weight:600'},
                      [Component.text('Saved')],
                    ),
                  if (_mappingSaveError != null)
                    span(
                      attributes: {'style': 'font-size:12px;color:#E8A8A8'},
                      [Component.text(_mappingSaveError!)],
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Custom checkbox — a `button` with `role="checkbox"`, not
  /// `input<bool>(type: InputType.checkbox)`. This codebase has an
  /// established, documented reason to avoid that: see
  /// integrations_page.dart / api_webhooks_page.dart's own comments,
  /// "InputType.checkbox is a documented landmine in this codebase."
  /// Screen readers treat this identically given the role and
  /// aria-checked.
  Component _mappingEnabledToggle() => button(
    [
      span(
        attributes: {
          'style':
              'width:16px;height:16px;border-radius:4px;flex:none;display:flex;align-items:center;'
              'justify-content:center;font-size:10px;font-weight:700;line-height:1;'
              'border:1px solid ${_mappingEnabled ? KolaDashboardColors.accent : KolaDashboardColors.border};'
              'background:${_mappingEnabled ? KolaDashboardColors.accent : 'transparent'};'
              'color:${KolaDashboardColors.accentText}',
        },
        [if (_mappingEnabled) Component.text('✓')],
      ),
      span(
        attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.text}'},
        [Component.text('Link matching rows to customers when this Errand runs')],
      ),
    ],
    type: ButtonType.button,
    onClick: () => setState(() {
      _mappingEnabled = !_mappingEnabled;
      _mappingJustSaved = false;
    }),
    attributes: {
      'role': 'checkbox',
      'aria-checked': _mappingEnabled ? 'true' : 'false',
      'style':
          'display:flex;align-items:center;gap:8px;background:transparent;border:none;padding:0;'
          'cursor:pointer;font-family:inherit;width:fit-content',
    },
  );

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
