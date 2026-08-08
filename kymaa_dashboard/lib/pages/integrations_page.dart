// integrations_page.dart — Phase 4e's own remaining scope item
// (DEVELOPMENT_PLAN.md line 133: "Still pending: ... Integrations page").
// No .dc.html design export exists for this page — same situation as
// conversations_page.dart, a functional build using this shell's
// existing theme tokens, not a from-scratch design.
//
// Backed by the real ChannelEndpoint (Phase 2a/2b): pick a bot, see its
// current Telegram/WhatsApp connection status, connect either one.
// connectTelegramChannel/connectWhatsAppChannelManual both really probe
// the credential against Telegram/Meta before persisting anything (see
// channel_endpoint.dart's own header comments) — a bad paste here fails
// with a real error, not a silently-broken "connected" channel.
//
// KNOWN GAP SURFACED WHILE BUILDING THIS: connecting a channel needs an
// existing botId, but nothing in kola_dashboard can create a bot yet —
// BotEndpoint.createBot exists server-side, but the sidebar's "+ New
// Bot" is still a plain '#' link (Phase 4c). Flagged honestly below
// (empty state) rather than silently building a bot-creation flow here
// too, which is its own separate scope.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

class IntegrationsPage extends StatefulComponent {
  const IntegrationsPage({required this.client, required this.accessToken, required this.workspaceId});

  final Client client;
  final String accessToken;
  final int workspaceId;

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> {
  List<Bot>? _bots;
  String? _loadError;

  Bot? _selected;
  List<Channel> _channels = const [];
  String? _channelsError;

  String _telegramToken = '';
  bool _connectingTelegram = false;
  String? _telegramError;
  String? _telegramSuccess;

  String _waToken = '';
  String _waPhoneNumberId = '';
  String _waWabaId = '';
  String _waAppId = '';
  String _waAppSecret = '';
  bool _connectingWhatsApp = false;
  String? _whatsAppError;
  String? _whatsAppSuccess;

  // TASK #150 — programmatic WhatsApp message templates. Workspace-
  // scoped (not per-bot), so this loads once, independently of which
  // bot is selected in the left column — see WhatsAppTemplateEndpoint.
  // listTemplatesForWorkspace.
  List<WhatsAppMessageTemplate> _templates = const [];
  bool _loadingTemplates = false;
  String _templateProductList = '';
  String _templateCustomerExample = 'Chidi';
  bool _creatingTemplate = false;
  String? _templateCreateError;
  String? _templateCreateSuccess;
  final Set<int> _refreshingTemplateIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _loadingTemplates = true);
    try {
      final templates = await component.client.whatsAppTemplate.listTemplatesForWorkspace(
        component.accessToken,
        component.workspaceId,
      );
      if (mounted) setState(() { _templates = templates; _loadingTemplates = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  Future<void> _createProductListTemplate(Channel whatsapp) async {
    if (whatsapp.id == null || _templateProductList.trim().isEmpty) {
      setState(() => _templateCreateError = 'Paste in the product list first.');
      return;
    }
    setState(() {
      _creatingTemplate = true;
      _templateCreateError = null;
      _templateCreateSuccess = null;
    });
    try {
      await component.client.whatsAppTemplate.createProductListTemplate(
        component.accessToken,
        component.workspaceId,
        whatsapp.id!,
        'product_list',
        _templateCustomerExample.trim().isEmpty ? 'Customer' : _templateCustomerExample.trim(),
        _templateProductList.trim(),
      );
      if (mounted) {
        setState(() {
          _creatingTemplate = false;
          _templateCreateSuccess = 'Submitted to Meta for review — usually minutes to a few days.';
          _templateProductList = '';
        });
        await _loadTemplates();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _creatingTemplate = false;
          _templateCreateError = "Couldn't submit this template. Check the connection and try again.";
        });
      }
    }
  }

  Future<void> _refreshTemplateStatus(WhatsAppMessageTemplate template) async {
    if (template.id == null) return;
    setState(() => _refreshingTemplateIds.add(template.id!));
    try {
      await component.client.whatsAppTemplate.refreshTemplateStatus(
        component.accessToken,
        component.workspaceId,
        template.id!,
      );
      await _loadTemplates();
    } catch (_) {
      // Silent — the status badge just keeps showing its last known
      // value; the user can try "Refresh" again.
    } finally {
      if (mounted) setState(() => _refreshingTemplateIds.remove(template.id));
    }
  }

  Future<void> _load() async {
    try {
      final bots = await component.client.bot.listBotsForWorkspace(component.accessToken, component.workspaceId);
      setState(() {
        _bots = bots;
        if (bots.isNotEmpty) _select(bots.first);
      });
    } catch (_) {
      setState(() => _loadError = "Couldn't load your bots. Check your connection and try again.");
    }
  }

  Future<void> _select(Bot bot) async {
    setState(() {
      _selected = bot;
      _channels = const [];
      _channelsError = null;
      _telegramError = null;
      _telegramSuccess = null;
      _whatsAppError = null;
      _whatsAppSuccess = null;
    });
    await _loadChannels();
  }

  Future<void> _loadChannels() async {
    final bot = _selected;
    if (bot == null || bot.id == null) return;
    try {
      final channels = await component.client.channel.listChannelsForBot(
        component.accessToken,
        component.workspaceId,
        bot.id!,
      );
      if (mounted) setState(() => _channels = channels);
    } catch (_) {
      if (mounted) setState(() => _channelsError = "Couldn't load this bot's channels.");
    }
  }

  Channel? _channelFor(String platform) {
    try {
      return _channels.firstWhere((c) => c.platformType == platform);
    } catch (_) {
      return null;
    }
  }

  Future<void> _connectTelegram() async {
    final bot = _selected;
    if (bot == null || bot.id == null || _telegramToken.trim().isEmpty) return;
    setState(() {
      _connectingTelegram = true;
      _telegramError = null;
      _telegramSuccess = null;
    });
    try {
      await component.client.channel.connectTelegramChannel(
        component.accessToken,
        component.workspaceId,
        bot.id!,
        _telegramToken.trim(),
      );
      if (mounted) {
        setState(() {
          _connectingTelegram = false;
          _telegramSuccess = 'Telegram connected.';
          _telegramToken = '';
        });
        await _loadChannels();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _connectingTelegram = false;
          _telegramError = "Couldn't verify that bot token with Telegram — double-check it and try again.";
        });
      }
    }
  }

  Future<void> _connectWhatsApp() async {
    final bot = _selected;
    if (bot == null || bot.id == null) return;
    if ([_waToken, _waPhoneNumberId, _waWabaId, _waAppId, _waAppSecret].any((v) => v.trim().isEmpty)) {
      setState(() => _whatsAppError = 'All five fields are required.');
      return;
    }
    setState(() {
      _connectingWhatsApp = true;
      _whatsAppError = null;
      _whatsAppSuccess = null;
    });
    try {
      await component.client.channel.connectWhatsAppChannelManual(
        component.accessToken,
        component.workspaceId,
        bot.id!,
        _waToken.trim(),
        _waPhoneNumberId.trim(),
        _waWabaId.trim(),
        _waAppId.trim(),
        _waAppSecret.trim(),
      );
      if (mounted) {
        setState(() {
          _connectingWhatsApp = false;
          _whatsAppSuccess = 'WhatsApp connected.';
          _waToken = '';
          _waPhoneNumberId = '';
          _waWabaId = '';
          _waAppId = '';
          _waAppSecret = '';
        });
        await _loadChannels();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _connectingWhatsApp = false;
          _whatsAppError = "Couldn't verify those details with Meta — double-check them and try again.";
        });
      }
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;'
            'box-sizing:border-box;padding:40px 32px 60px;display:flex;justify-content:center',
      },
      [
        div(
          attributes: {'style': 'max-width:1000px;width:100%'},
          [
            div(attributes: {'style': 'margin-bottom:14px'}, [backLink()]),
            div(
              attributes: {'style': 'font-size:20px;font-weight:700;margin-bottom:4px'},
              [Component.text('Integrations')],
            ),
            div(
              attributes: {'style': 'font-size:13.5px;color:${KolaDashboardColors.muted};margin-bottom:24px'},
              [Component.text('Connect a bot to Telegram or WhatsApp so it can actually receive messages.')],
            ),
            if (_loadError != null) _note(_loadError!) else _body(),
          ],
        ),
      ],
    );
  }

  Component _body() {
    final bots = _bots;
    if (bots == null) return _note('Loading…');
    if (bots.isEmpty) {
      // Was stale — task #114 wired up real bot creation (/bots/new)
      // after this empty state's original copy was written.
      return _note('No bots yet — create one first, then come back here to connect it.');
    }
    return div(
      attributes: {'style': 'display:flex;gap:24px;flex-wrap:wrap'},
      [
        div(attributes: {'style': 'flex:1;min-width:200px'}, [_botList(bots)]),
        div(attributes: {'style': 'flex:3;min-width:420px'}, [_selected == null ? _note('Select a bot.') : _channelsPanel()]),
      ],
    );
  }

  Component _botList(List<Bot> bots) {
    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:6px'},
      [
        for (final bot in bots)
          div(
            attributes: {
              'style':
                  'padding:10px 12px;border-radius:9px;cursor:pointer;font-size:13.5px;'
                  'background:${_selected?.id == bot.id ? KolaDashboardColors.navActiveBg : "transparent"};'
                  'color:${_selected?.id == bot.id ? KolaDashboardColors.accent : KolaDashboardColors.navInactiveText}',
            },
            events: {'click': (_) => _select(bot)},
            [Component.text(bot.name)],
          ),
      ],
    );
  }

  Component _channelsPanel() {
    if (_channelsError != null) return _note(_channelsError!);
    final telegram = _channelFor('telegram');
    final whatsapp = _channelFor('whatsapp');
    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:20px;max-width:520px'},
      [
        _channelCard(
          icon: '✈️',
          title: 'Telegram',
          connected: telegram?.status == 'connected',
          connectedLabel: telegram?.displayName,
          error: _telegramError,
          success: _telegramSuccess,
          fields: [
            _textField(
              label: 'Bot token (from @BotFather)',
              value: _telegramToken,
              onInput: (v) => setState(() => _telegramToken = v),
              placeholder: '123456:ABC-DEF...',
              isPassword: true,
            ),
          ],
          onConnect: _connectTelegram,
          connecting: _connectingTelegram,
        ),
        _channelCard(
          icon: '💬',
          title: 'WhatsApp',
          connected: whatsapp?.status == 'connected',
          connectedLabel: whatsapp?.displayName,
          error: _whatsAppError,
          success: _whatsAppSuccess,
          fields: [
            _textField(
              label: 'Access token',
              value: _waToken,
              onInput: (v) => setState(() => _waToken = v),
              placeholder: 'EAAG...',
              isPassword: true,
            ),
            _textField(
              label: 'Phone number ID',
              value: _waPhoneNumberId,
              onInput: (v) => setState(() => _waPhoneNumberId = v),
              placeholder: '109...',
            ),
            _textField(
              label: 'WhatsApp Business Account ID',
              value: _waWabaId,
              onInput: (v) => setState(() => _waWabaId = v),
              placeholder: '102...',
            ),
            _textField(
              label: 'App ID',
              value: _waAppId,
              onInput: (v) => setState(() => _waAppId = v),
              placeholder: '900...',
            ),
            _textField(
              label: 'App secret',
              value: _waAppSecret,
              onInput: (v) => setState(() => _waAppSecret = v),
              placeholder: '••••••••',
              isPassword: true,
            ),
          ],
          onConnect: _connectWhatsApp,
          connecting: _connectingWhatsApp,
        ),
        if (whatsapp?.status == 'connected') _templatesCard(whatsapp!),
      ],
    );
  }

  /// TASK #150 — lets a business submit a Meta-reviewed WhatsApp
  /// template for the one case that actually needs one: messaging a
  /// customer OUTSIDE an open 24-hour window (see
  /// whatsapp_template_endpoint.dart's header). Deliberately does NOT
  /// claim this is needed for every WhatsApp send — a bot replying to a
  /// customer who just messaged never needs a template at all, and that
  /// note is shown here so the feature isn't mistaken for a blanket
  /// requirement.
  Component _templatesCard(Channel whatsapp) {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:14px;padding:20px;box-sizing:border-box',
      },
      [
        div(attributes: {'style': 'font-size:14.5px;font-weight:600;margin-bottom:4px'}, [
          Component.text('Send a product list outside the free reply window'),
        ]),
        div(
          attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};margin-bottom:14px'},
          [
            Component.text(
              "If a customer messaged you in the last 24 hours, just reply normally — that's free and needs "
              "nothing here. This is only for reaching out first: Meta requires a pre-approved template for "
              "that, and this submits one as 'utility' (the cheaper category for a requested update, vs. "
              "'marketing') for review.",
            ),
          ],
        ),
        _textField(
          label: "Customer's first name (example only, for Meta's review)",
          value: _templateCustomerExample,
          onInput: (v) => setState(() => _templateCustomerExample = v),
          placeholder: 'Chidi',
        ),
        div(
          attributes: {'style': 'margin-bottom:10px'},
          [
            div(
              attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:4px'},
              [Component.text('Product list')],
            ),
            textarea(
              [Component.text(_templateProductList)],
              rows: 4,
              onInput: (v) => setState(() => _templateProductList = v),
              attributes: {
                'placeholder': '1. Rice — ₦5,000\n2. Beans — ₦3,000\n3. Garri — ₦1,500',
                'style':
                    'width:100%;box-sizing:border-box;background:#141416;border:1px solid ${KolaDashboardColors.border};'
                    'border-radius:8px;padding:9px 10px;font-size:13px;color:${KolaDashboardColors.text};resize:vertical',
              },
            ),
          ],
        ),
        if (_templateCreateError != null)
          div(attributes: {'style': 'font-size:12.5px;color:#E8A8A8;margin-bottom:8px'}, [Component.text(_templateCreateError!)]),
        if (_templateCreateSuccess != null)
          div(attributes: {'style': 'font-size:12.5px;color:#7ED8B0;margin-bottom:8px'}, [Component.text(_templateCreateSuccess!)]),
        button(
          [Component.text(_creatingTemplate ? 'Submitting…' : 'Submit template to Meta')],
          onClick: () => _createProductListTemplate(whatsapp),
          disabled: _creatingTemplate,
          attributes: {
            'style':
                'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};border:none;'
                'border-radius:9px;padding:10px 18px;font-size:13.5px;font-weight:600;cursor:pointer;'
                'opacity:${_creatingTemplate ? "0.7" : "1"}',
          },
        ),
        if (_templates.isNotEmpty) ...[
          div(attributes: {'style': 'height:1px;background:${KolaDashboardColors.border};margin:16px 0'}, []),
          div(attributes: {'style': 'font-size:12.5px;font-weight:600;margin-bottom:8px'}, [Component.text('Submitted templates')]),
          for (final t in _templates.where((t) => t.channelId == whatsapp.id)) _templateRow(t),
        ] else if (_loadingTemplates)
          div(attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.muted};margin-top:12px'}, [Component.text('Loading…')]),
      ],
    );
  }

  Component _templateRow(WhatsAppMessageTemplate t) {
    final refreshing = _refreshingTemplateIds.contains(t.id);
    const statusColors = {
      'pending': '#D9B25C',
      'approved': '#7ED8B0',
      'rejected': '#E8A8A8',
      'disabled': '#6B655E',
    };
    return div(
      attributes: {'style': 'display:flex;align-items:center;gap:10px;padding:8px 0;font-size:12.5px'},
      [
        span(
          attributes: {
            'style':
                'font-weight:600;padding:2px 9px;border-radius:100px;background:#00000030;'
                'color:${statusColors[t.status] ?? KolaDashboardColors.muted}',
          },
          [Component.text(t.status)],
        ),
        div(attributes: {'style': 'flex:1;color:${KolaDashboardColors.muted}'}, [Component.text(t.metaTemplateName)]),
        if (t.status == 'pending')
          button(
            [Component.text(refreshing ? '…' : 'Refresh')],
            onClick: () => _refreshTemplateStatus(t),
            disabled: refreshing,
            attributes: {
              'style':
                  'background:transparent;border:1px solid ${KolaDashboardColors.border};'
                  'color:${KolaDashboardColors.navInactiveText};border-radius:100px;padding:4px 10px;'
                  'font-size:11.5px;font-family:inherit;cursor:pointer',
            },
          ),
        if (t.status == 'rejected' && t.rejectionReason != null)
          div(attributes: {'style': 'font-size:11px;color:#E8A8A8;max-width:180px'}, [Component.text(t.rejectionReason!)]),
      ],
    );
  }

  Component _channelCard({
    required String icon,
    required String title,
    required bool connected,
    required String? connectedLabel,
    required String? error,
    required String? success,
    required List<Component> fields,
    required void Function() onConnect,
    required bool connecting,
  }) {
    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:14px;padding:20px;box-sizing:border-box',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;gap:10px;margin-bottom:4px'},
          [
            span(attributes: {'style': 'font-size:18px'}, [Component.text(icon)]),
            div(attributes: {'style': 'font-size:14.5px;font-weight:600;flex:1'}, [Component.text(title)]),
            span(
              attributes: {
                'style':
                    'font-size:11.5px;font-weight:600;padding:3px 10px;border-radius:100px;'
                    'background:#00000030;color:${connected ? "#7ED8B0" : "#6B655E"}',
              },
              [Component.text(connected ? '● Connected' : 'Not connected')],
            ),
          ],
        ),
        if (connected && connectedLabel != null && connectedLabel.isNotEmpty)
          div(
            attributes: {'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};margin-bottom:12px'},
            [Component.text(connectedLabel)],
          ),
        div(
          attributes: {
            'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};margin:12px 0',
          },
          [Component.text(connected ? 'Reconnect with a different credential:' : 'Connect:')],
        ),
        ...fields,
        if (error != null)
          div(
            attributes: {'style': 'font-size:12.5px;color:#E8A8A8;margin-top:8px'},
            [Component.text(error)],
          ),
        if (success != null)
          div(
            attributes: {'style': 'font-size:12.5px;color:#7ED8B0;margin-top:8px'},
            [Component.text(success)],
          ),
        button(
          [Component.text(connecting ? 'Connecting…' : 'Connect')],
          onClick: onConnect,
          disabled: connecting,
          attributes: {
            'style':
                'margin-top:12px;background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                'border:none;border-radius:9px;padding:10px 18px;font-size:13.5px;font-weight:600;'
                'cursor:pointer;opacity:${connecting ? "0.7" : "1"}',
          },
        ),
      ],
    );
  }

  Component _textField({
    required String label,
    required String value,
    required void Function(String) onInput,
    String? placeholder,
    bool isPassword = false,
  }) {
    return div(
      attributes: {'style': 'margin-bottom:10px'},
      [
        div(
          attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:4px'},
          [Component.text(label)],
        ),
        input<String>(
          type: isPassword ? InputType.password : InputType.text,
          value: value,
          onInput: (v) => onInput(v),
          attributes: {
            'style':
                'width:100%;background:#141416;border:1px solid ${KolaDashboardColors.border};border-radius:8px;'
                'padding:9px 10px;font-size:13px;color:${KolaDashboardColors.text};box-sizing:border-box',
            if (placeholder != null) 'placeholder': placeholder,
          },
        ),
      ],
    );
  }

  Component _note(String text) => div(
    attributes: {'style': 'color:${KolaDashboardColors.muted};font-size:13.5px'},
    [Component.text(text)],
  );
}
