// settings_page.dart — Kola Settings.dc.html.
//
// ── WHY THIS PAGE EXISTS NOW ─────────────────────────────────────────
//
// /settings was linked from three places and registered from none:
// Sidebar's profile menu points Profile AND Settings here, and the
// Overview's day-one card wanted it for the completed workspace step's
// "Edit". All three painted nothing. The page is the fix; the alternative
// was deleting designed UI, which is the wrong direction.
//
// ── THE EXPORT'S EIGHT SECTIONS, AND WHAT IS BEHIND EACH ─────────────
//
// SECTIONS = ['workspaces','team','appearance','notifications',
//             'security','data','billing','danger']
//
// All eight render. Four are real, four say so:
//
//   workspaces    REAL — lists every workspace, switches between them,
//                 and edits the current one's name / what it sells /
//                 owner name via WorkspaceEndpoint.updateWorkspace,
//                 which was written for this screen.
//   appearance    PARTLY REAL — theme is real. See _appearance().
//   notifications REAL — OwnerNotificationEndpoint, all five channels.
//                 The export's channel list and the server's model agree
//                 exactly, including SMS being unavailable.
//   billing       REAL — defers to /billing rather than duplicating it.
//
//   team          Not built. workspace_members exists as a table with no
//                 endpoint, and enterprise.advanced_roles is locked.
//   security      Not built. 2FA would be Supabase Auth MFA; nothing is
//                 wired to it.
//   data          Not built. No export or erase pipeline exists.
//   danger        Not built. There is no delete-workspace endpoint, and
//                 inventing one that only pretends to delete would be
//                 the worst possible thing on this particular screen.
//
// A section that cannot do its job says which thing is missing and what
// to do meanwhile. It does NOT render a dead control — this page was
// written because dead controls were the problem.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:kola_client/kola_client.dart';
import 'package:web/web.dart' as web;

import '../components/shell/icons.dart';
import '../components/shell/kola_icon.dart';
import '../services/error_text.dart';
import '../services/feature_gate.dart';
import '../services/local_storage.dart';
import '../theme.dart';

class SettingsPage extends StatefulComponent {
  const SettingsPage({
    required this.client,
    required this.accessToken,
    required this.workspace,
    required this.workspaces,
    required this.onWorkspaceSwitch,
    required this.onWorkspaceUpdated,
    required this.gate,
  });

  final Client client;
  final String accessToken;
  final Workspace workspace;
  final List<Workspace> workspaces;
  final void Function(Workspace) onWorkspaceSwitch;
  final void Function(Workspace) onWorkspaceUpdated;
  final FeatureGate gate;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

/// The export's SECTIONS list, in its order.
enum _Section { workspaces, team, appearance, notifications, security, data, billing, danger }

extension on _Section {
  /// SECTION_LABEL, verbatim.
  String get label => switch (this) {
        _Section.workspaces => 'Workspaces',
        _Section.team => 'Team & roles',
        _Section.appearance => 'Appearance',
        _Section.notifications => 'Notifications',
        _Section.security => 'Security',
        _Section.data => 'Data',
        _Section.billing => 'Billing',
        _Section.danger => 'Danger zone',
      };

  bool get danger => this == _Section.danger;
}

class _SettingsPageState extends State<SettingsPage> {
  _Section _section = _Section.workspaces;

  // ── Workspace form ──────────────────────────────────────────────────
  late String _name = component.workspace.name;
  late String _industry = component.workspace.industryTag ?? '';
  late String _ownerName = component.workspace.ownerName ?? '';
  bool _savingWorkspace = false;
  String? _workspaceError;
  String? _workspaceSaved;

  // ── Notifications ───────────────────────────────────────────────────
  OwnerNotificationSettings? _notify;
  bool _notifyLoading = true;
  bool _savingNotify = false;
  String? _notifyError;
  String? _notifySaved;

  String _email = '';
  String _whatsapp = '';
  String _telegram = '';
  String _slackUrl = '';
  bool _emailOn = false;
  bool _whatsappOn = false;
  bool _telegramOn = false;
  bool _slackOn = false;

  // ── Appearance ──────────────────────────────────────────────────────
  static const _themeKey = 'kola_theme';
  static const _fontKey = 'kola_font';
  String _theme = 'system';
  String _font = 'Plus Jakarta Sans';

  @override
  void initState() {
    super.initState();
    _theme = LocalStorage.getItem(_themeKey) ?? 'system';
    _font = LocalStorage.getItem(_fontKey) ?? 'Plus Jakarta Sans';
    _loadNotifications();
  }

  // ── Loads ───────────────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    try {
      final s = await component.client.ownerNotification.getSettings(
        component.accessToken,
        component.workspace.id!,
      );
      if (!mounted) return;
      setState(() {
        _notify = s;
        _email = s?.ownerEmail ?? '';
        _whatsapp = s?.ownerWhatsappNumber ?? '';
        _telegram = s?.telegramChatId ?? '';
        _emailOn = s?.emailEnabled ?? false;
        _whatsappOn = s?.whatsappEnabled ?? false;
        _telegramOn = s?.telegramEnabled ?? false;
        _slackOn = s?.slackEnabled ?? false;
        // encryptedSlackWebhookUrl is NEVER decrypted to the browser —
        // see the model's header. The field starts empty and an empty
        // submit leaves the stored URL alone, so an owner who is not
        // changing it does not have to re-enter it.
        _notifyLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifyError = ErrorText.of(e);
        _notifyLoading = false;
      });
    }
  }

  // ── Saves ───────────────────────────────────────────────────────────

  Future<void> _saveWorkspace() async {
    setState(() {
      _savingWorkspace = true;
      _workspaceError = null;
      _workspaceSaved = null;
    });
    try {
      final updated = await component.client.workspace.updateWorkspace(
        component.accessToken,
        component.workspace.id!,
        name: _name,
        industryTag: _industry,
        ownerName: _ownerName,
      );
      if (!mounted) return;
      component.onWorkspaceUpdated(updated);
      setState(() {
        _savingWorkspace = false;
        _workspaceSaved = 'Saved.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingWorkspace = false;
        _workspaceError = ErrorText.of(e);
      });
    }
  }

  Future<void> _saveNotifications() async {
    setState(() {
      _savingNotify = true;
      _notifyError = null;
      _notifySaved = null;
    });
    try {
      final updated = await component.client.ownerNotification.updateSettings(
        component.accessToken,
        component.workspace.id!,
        ownerEmail: _email.trim().isEmpty ? null : _email.trim(),
        emailEnabled: _emailOn,
        ownerWhatsappNumber: _whatsapp.trim().isEmpty ? null : _whatsapp.trim(),
        whatsappEnabled: _whatsappOn,
        telegramChatId: _telegram.trim().isEmpty ? null : _telegram.trim(),
        telegramEnabled: _telegramOn,
        // SMS is hard-off, and it has to be passed explicitly.
        //
        // SERVERPOD DROPS DEFAULT VALUES WHEN IT GENERATES THE CLIENT.
        // The endpoint declares `bool smsEnabled = false`, but the
        // generated signature is `required bool smsEnabled` — so an
        // omitted argument is a compile error, not the server's default.
        // Same for emailEnabled, whatsappEnabled, telegramEnabled and
        // slackEnabled above; those only compiled because they happened
        // to be passed anyway.
        //
        // The VALUE is false because SmsOwnerNotifier throws
        // UnimplementedError — enabling it would promise a message that
        // never arrives.
        ownerSmsNumber: null,
        smsEnabled: false,
        slackWebhookUrl: _slackUrl.trim().isEmpty ? null : _slackUrl.trim(),
        slackEnabled: _slackOn,
      );
      if (!mounted) return;
      setState(() {
        _notify = updated;
        _savingNotify = false;
        _notifySaved = 'Saved.';
        _slackUrl = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingNotify = false;
        _notifyError = ErrorText.of(e);
      });
    }
  }

  // ── Appearance side effects ─────────────────────────────────────────

  /// Applies the theme by setting (or clearing) `data-theme` on <html>.
  ///
  /// The whole light/dark mechanism already existed in styles.css and in
  /// theme.dart's KolaTheme — `:root[data-theme='light']` rules, plus a
  /// `prefers-color-scheme` fallback for `:root:not([data-theme])`. It
  /// had NO callers, so the app was permanently dark and the light
  /// palette someone designed had never been seen. This is the caller.
  ///
  /// 'system' REMOVES the attribute rather than writing a third value,
  /// because that is what the CSS is written against: absence means
  /// follow the OS.
  void _applyTheme(String value) {
    LocalStorage.setItem(_themeKey, value);
    final root = web.document.documentElement;
    if (root == null) return;
    if (value == 'system') {
      root.removeAttribute(KolaTheme.attribute);
    } else {
      root.setAttribute(KolaTheme.attribute, value);
    }
    setState(() => _theme = value);
  }

  /// Overrides `--kola-font-sans`, which every body/UI surface already
  /// resolves through. Display and mono faces are deliberately left
  /// alone — the export offers one control labelled for body text, and
  /// swapping Space Grotesk out from under the headings would change
  /// the product's character rather than its readability.
  void _applyFont(String value) {
    LocalStorage.setItem(_fontKey, value);
    final family = switch (value) {
      'Inter' => "'Inter', sans-serif",
      'System default' => 'system-ui, sans-serif',
      _ => "'Plus Jakarta Sans', sans-serif",
    };
    // setAttribute, not `.style.setProperty`. See main.dart's note on
    // the same line: reaching `.style` through `dynamic` analyses clean
    // and throws at runtime, because package:web's DOM types are
    // extension types that are erased when compiled. This is the same
    // method used for data-theme, on the same element, so it needs no
    // cast and no assumption.
    web.document.documentElement
        ?.setAttribute('style', '--kola-font-sans: $family');
    setState(() => _font = value);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'padding:${KolaSpace.lg};max-width:1040px;margin:0 auto;'
              'width:100%;box-sizing:border-box',
        },
        [
          div(
            attributes: {
              'style': 'font-family:${KolaFonts.display};'
                  'font-size:${KolaType.h2};font-weight:700;'
                  'color:${KolaVar.text};margin-bottom:4px',
            },
            [Component.text('Settings')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
                  'margin-bottom:${KolaSpace.lg}',
            },
            [Component.text('Your workspace, how kolaa reaches you, and how '
                'this dashboard looks.')],
          ),
          div(
            attributes: {
              'style': 'display:flex;gap:${KolaSpace.lg};align-items:flex-start;'
                  'flex-wrap:wrap',
            },
            [_rail(), _body()],
          ),
        ],
      );

  Component _rail() => div(
        attributes: {
          'style': 'flex:none;width:200px;min-width:180px;'
              'display:flex;flex-direction:column;gap:2px',
        },
        [
          for (final s in _Section.values)
            button(
              attributes: {
                'type': 'button',
                'aria-current': _section == s ? 'true' : 'false',
                'style': 'text-align:left;padding:9px 12px;'
                    'border-radius:${KolaRadius.sm};border:none;cursor:pointer;'
                    'font-family:inherit;font-size:${KolaType.ui};'
                    'background:${_section == s ? KolaVar.card : 'transparent'};'
                    'font-weight:${_section == s ? '600' : '400'};'
                    'color:${_railColor(s)}',
              },
              events: {'click': (_) => setState(() => _section = s)},
              [Component.text(s.label)],
            ),
        ],
      );

  /// The export tints the danger row even when it is not selected — it is
  /// the one row whose consequences differ in kind from the others.
  String _railColor(_Section s) {
    if (s.danger) return _section == s ? KolaVar.danger : '#B9756E';
    return _section == s ? KolaVar.text : KolaVar.muted;
  }

  Component _body() => div(
        attributes: {'style': 'flex:1;min-width:320px'},
        [
          switch (_section) {
            _Section.workspaces => _workspaces(),
            _Section.team => _team(),
            _Section.appearance => _appearance(),
            _Section.notifications => _notifications(),
            _Section.security => _security(),
            _Section.data => _data(),
            _Section.billing => _billing(),
            _Section.danger => _danger(),
          },
        ],
      );

  // ── Section: Workspaces ─────────────────────────────────────────────

  Component _workspaces() => _card([
        _sectionTitle('This workspace'),
        _field('Business name', _name, (v) => setState(() => _name = v),
            placeholder: "e.g. Aisha's Fashion House"),
        _field('What you sell', _industry, (v) => setState(() => _industry = v),
            placeholder: 'e.g. Ankara fabric and ready-made outfits'),
        _field('Your name', _ownerName, (v) => setState(() => _ownerName = v),
            placeholder: 'The name kolaa greets you with'),
        if (_workspaceError != null) _msg(_workspaceError!, KolaVar.danger),
        if (_workspaceSaved != null) _msg(_workspaceSaved!, KolaVar.successBright),
        _primary(_savingWorkspace ? 'Saving…' : 'Save changes',
            enabled: !_savingWorkspace, onTap: _saveWorkspace),

        // The switcher. Rendered only with something to switch TO —
        // a list of one, labelled "current", is chrome that explains
        // nothing.
        if (component.workspaces.length > 1) ...[
          div(attributes: {'style': 'height:${KolaSpace.lg}'}, []),
          _sectionTitle('Your workspaces'),
          for (final w in component.workspaces) _workspaceRow(w),
        ],
      ]);

  Component _workspaceRow(Workspace w) {
    final current = w.id == component.workspace.id;
    return div(
      attributes: {
        'style': 'display:flex;align-items:center;gap:12px;padding:12px;'
            'border:1px solid ${current ? KolaVar.accent : KolaVar.border};'
            'border-radius:${KolaRadius.md};margin-bottom:8px',
      },
      [
        div(
          attributes: {
            'style': 'width:32px;height:32px;flex:none;border-radius:'
                '${KolaRadius.circle};background:${KolaVar.pill};'
                'color:${KolaVar.text};display:flex;align-items:center;'
                'justify-content:center;font-weight:700;'
                'font-size:${KolaType.small}',
          },
          [
            Component.text(
              w.name.trim().isEmpty ? '?' : w.name.trim()[0].toUpperCase(),
            ),
          ],
        ),
        div(
          attributes: {'style': 'flex:1;min-width:0'},
          [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:600;'
                    'color:${KolaVar.text}',
              },
              [Component.text(w.name)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
              },
              // The plan, as the server actually has it. The export shows
              // "Pro plan / Free plan / Agency"; only the real value is
              // rendered here, because a plan is a billing fact.
              [Component.text('${w.plan} plan')],
            ),
          ],
        ),
        if (current)
          div(
            attributes: {'style': KolaTone.positive.badgeCss},
            [Component.text('Current')],
          )
        else
          button(
            attributes: {
              'type': 'button',
              'style': 'flex:none;padding:7px 14px;'
                  'border-radius:${KolaRadius.pill};'
                  'border:1px solid ${KolaVar.border};background:transparent;'
                  'color:${KolaVar.text};font-family:inherit;'
                  'font-size:${KolaType.tiny};font-weight:600;cursor:pointer',
            },
            events: {'click': (_) => component.onWorkspaceSwitch(w)},
            [Component.text('Switch')],
          ),
      ],
    );
  }

  // ── Section: Notifications ──────────────────────────────────────────

  Component _notifications() {
    if (_notifyLoading) return _card([_msg('Loading…', KolaVar.muted)]);

    return _card([
      _sectionTitle('How kolaa reaches you'),
      _hint('When kolaa cannot answer something confidently it hands the '
          'conversation to you. This is where that alert lands.'),
      _toggleRow('WhatsApp', _whatsappOn, (v) => setState(() => _whatsappOn = v)),
      if (_whatsappOn)
        _field('Your WhatsApp number', _whatsapp,
            (v) => setState(() => _whatsapp = v),
            placeholder: '+234…'),
      _toggleRow('Telegram', _telegramOn, (v) => setState(() => _telegramOn = v)),
      if (_telegramOn)
        _field('Telegram chat ID', _telegram, (v) => setState(() => _telegram = v),
            placeholder: 'Message the kolaa notifier bot to get this'),
      _toggleRow('Email', _emailOn, (v) => setState(() => _emailOn = v)),
      if (_emailOn)
        _field('Email address', _email, (v) => setState(() => _email = v),
            placeholder: 'you@yourbusiness.com'),
      _toggleRow('Slack', _slackOn, (v) => setState(() => _slackOn = v)),
      if (_slackOn)
        _field(
          _notify?.encryptedSlackWebhookUrl == null
              ? 'Slack incoming webhook URL'
              : 'Slack webhook URL (leave blank to keep the current one)',
          _slackUrl,
          (v) => setState(() => _slackUrl = v),
          placeholder: 'https://hooks.slack.com/services/…',
        ),

      // SMS is in the export's channel list as "SMS (coming soon)", and
      // the server agrees — SmsOwnerNotifier throws UnimplementedError.
      // Shown, disabled, and labelled, rather than hidden: it is the one
      // channel that has been publicly named.
      div(
        attributes: {
          'style': 'display:flex;align-items:center;justify-content:space-between;'
              'padding:12px 0;opacity:0.55',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.text}',
            },
            [Component.text('SMS')],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};color:${KolaVar.muted}',
            },
            [Component.text('Not available yet')],
          ),
        ],
      ),

      if (_notifyError != null) _msg(_notifyError!, KolaVar.danger),
      if (_notifySaved != null) _msg(_notifySaved!, KolaVar.successBright),
      _primary(_savingNotify ? 'Saving…' : 'Save changes',
          enabled: !_savingNotify, onTap: _saveNotifications),
    ]);
  }

  // ── Section: Appearance ─────────────────────────────────────────────

  /// Theme and body font are real and take effect immediately.
  ///
  /// The export also offers a font-SIZE slider and a comfortable/compact
  /// density switch. Neither is here, and neither is a judgement about
  /// the design — they are simply not expressible against this
  /// stylesheet yet. Type sizes live in KolaType as fixed px strings
  /// interpolated into inline styles, so a root font-size has nothing to
  /// scale; density has no spacing variable to drive. Both need the
  /// tokens to become CSS variables first. A slider that moved and
  /// changed nothing would be the same dead control this page exists to
  /// remove.
  Component _appearance() => _card([
        _sectionTitle('Theme'),
        _hint('Match system follows your phone or computer, including its '
            'night setting.'),
        _choices(
          const [
            (id: 'dark', label: 'Dark'),
            (id: 'light', label: 'Light'),
            (id: 'system', label: 'Match system'),
          ],
          _theme,
          _applyTheme,
        ),
        div(attributes: {'style': 'height:${KolaSpace.md}'}, []),
        _sectionTitle('Body text'),
        _choices(
          const [
            (id: 'Plus Jakarta Sans', label: 'Plus Jakarta Sans'),
            (id: 'Inter', label: 'Inter'),
            (id: 'System default', label: 'System default'),
          ],
          _font,
          _applyFont,
        ),
        _hint('Headings keep their own typeface.'),
      ]);

  // ── Section: Billing ────────────────────────────────────────────────

  Component _billing() => _card([
        _sectionTitle('Plan and payments'),
        _hint('This workspace is on the ${component.workspace.plan} plan.'),
        // Defers rather than duplicates. Two screens showing plan state
        // is two screens that can disagree.
        Link(
          to: '/billing',
          attributes: {
            'class': 'kola-pressable',
            'style': 'display:inline-block;margin-top:10px;padding:10px 18px;'
                'border-radius:${KolaRadius.pill};'
                'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
                'font-size:${KolaType.small};font-weight:600;'
                'text-decoration:none',
          },
          children: [Component.text('Open billing')],
        ),
      ]);

  // ── Sections not built yet ──────────────────────────────────────────

  Component _team() => _card([
        _sectionTitle('Team & roles'),
        _notYet(
          'Only you can sign in to this workspace right now.',
          'Inviting a colleague and giving them a limited role — support '
              'only, no billing — is designed and not built. Until it is, '
              'anyone who needs access has to share your sign-in, so keep '
              'that in mind before you do.',
        ),
      ]);

  Component _security() => _card([
        _sectionTitle('Security'),
        _notYet(
          'Two-factor authentication is not available yet.',
          'Your account is protected by your password alone. Use one you '
              'do not use anywhere else, and change it if you think it has '
              'been seen.',
        ),
      ]);

  Component _data() => _card([
        _sectionTitle('Data'),
        _notYet(
          'Downloading a copy of your data is not available yet.',
          'Everything kolaa has learned — your documents, conversations and '
              'settings — is stored and is not going anywhere. Ask us and '
              'we will export it for you by hand in the meantime.',
        ),
      ]);

  Component _danger() => _card([
        _sectionTitle('Danger zone'),
        _notYet(
          'Deleting a workspace is not available from here yet.',
          'Deletion has to remove conversations, documents, connected '
              'channels and stored credentials together, and a button that '
              'only appeared to do that would be worse than no button. Ask '
              'us and it will be done properly and confirmed to you.',
        ),
      ]);

  // ── Shared pieces ───────────────────────────────────────────────────

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${KolaVar.border};'
              'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
              'padding:${KolaSpace.md}',
        },
        children,
      );

  Component _sectionTitle(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.bodyLg};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:6px',
        },
        [Component.text(text)],
      );

  Component _hint(String text) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'line-height:1.5;margin-bottom:14px;max-width:60ch',
        },
        [Component.text(text)],
      );

  Component _msg(String text, String color) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:$color;'
              'line-height:1.5;margin:10px 0',
        },
        [Component.text(text)],
      );

  /// The honest empty state for a section with nothing behind it.
  ///
  /// Two parts on purpose: what is missing, then what to do about it.
  /// "Coming soon" on its own tells someone running a business nothing
  /// they can act on.
  Component _notYet(String headline, String body) => div(
        attributes: {
          'style': 'border:1px dashed ${KolaVar.border};'
              'border-radius:${KolaRadius.md};padding:16px;'
              'background:${KolaVar.bg}',
        },
        [
          div(
            attributes: {
              'style': 'display:flex;align-items:center;gap:8px;'
                  'margin-bottom:6px',
            },
            [
              div(
                attributes: {'style': 'color:${KolaVar.muted};flex:none'},
                [kolaIcon(Icons.eye, size: 15)],
              ),
              div(
                attributes: {
                  'style': 'font-size:${KolaType.body};font-weight:600;'
                      'color:${KolaVar.text}',
                },
                [Component.text(headline)],
              ),
            ],
          ),
          div(
            attributes: {
              'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                  'line-height:1.55;max-width:62ch',
            },
            [Component.text(body)],
          ),
        ],
      );

  Component _field(
    String label,
    String value,
    void Function(String) onChanged, {
    String placeholder = '',
  }) =>
      div(
        attributes: {'style': 'margin-bottom:14px'},
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.tiny};font-weight:600;'
                  'color:${KolaVar.mutedStrong};margin-bottom:6px',
            },
            [Component.text(label)],
          ),
          input<String>(
            type: InputType.text,
            value: value,
            onInput: onChanged,
            attributes: {
              'placeholder': placeholder,
              'aria-label': label,
              'style': 'width:100%;box-sizing:border-box;padding:11px 13px;'
                  'border-radius:${KolaRadius.md};'
                  'border:1px solid ${KolaVar.border};'
                  'background:${KolaVar.bg};color:${KolaVar.text};'
                  'font-family:inherit;font-size:${KolaType.body}',
            },
          ),
        ],
      );

  /// The export's pill-and-knob switch.
  Component _toggleRow(String label, bool on, void Function(bool) onChanged) =>
      div(
        attributes: {
          'style': 'display:flex;align-items:center;'
              'justify-content:space-between;padding:12px 0;'
              'border-top:1px solid ${KolaVar.border}',
        },
        [
          div(
            attributes: {
              'style': 'font-size:${KolaType.body};color:${KolaVar.text}',
            },
            [Component.text(label)],
          ),
          button(
            attributes: {
              'type': 'button',
              'role': 'switch',
              'aria-checked': on ? 'true' : 'false',
              'aria-label': label,
              'style': 'width:38px;height:22px;flex:none;border:none;'
                  'cursor:pointer;padding:3px;'
                  'border-radius:${KolaRadius.pill};'
                  'background:${on ? KolaVar.accentFill : KolaVar.border};'
                  'display:flex;align-items:center',
            },
            events: {'click': (_) => onChanged(!on)},
            [
              div(
                attributes: {
                  'style': 'width:16px;height:16px;border-radius:50%;'
                      'background:#FFF6EE;'
                      'transform:translateX(${on ? '16px' : '0px'});'
                      'transition:transform 140ms ease',
                },
                [],
              ),
            ],
          ),
        ],
      );

  Component _choices(
    List<({String id, String label})> options,
    String selected,
    void Function(String) onPick,
  ) =>
      div(
        attributes: {'style': 'display:flex;flex-wrap:wrap;gap:8px'},
        [
          for (final o in options)
            button(
              attributes: {
                'type': 'button',
                'aria-pressed': selected == o.id ? 'true' : 'false',
                'style': 'padding:9px 16px;border-radius:${KolaRadius.pill};'
                    'cursor:pointer;font-family:inherit;'
                    'font-size:${KolaType.small};font-weight:600;'
                    'border:1px solid '
                    '${selected == o.id ? KolaVar.accent : KolaVar.border};'
                    'background:'
                    '${selected == o.id ? KolaVar.accent : 'transparent'};'
                    'color:'
                    '${selected == o.id ? KolaVar.accentText : KolaVar.text}',
              },
              events: {'click': (_) => onPick(o.id)},
              [Component.text(o.label)],
            ),
        ],
      );

  Component _primary(
    String label, {
    required bool enabled,
    required void Function() onTap,
  }) =>
      button(
        attributes: {
          'type': 'button',
          if (!enabled) 'disabled': 'disabled',
          'style': 'margin-top:6px;padding:11px 20px;'
              'border-radius:${KolaRadius.md};border:none;'
              'background:${KolaVar.accentFill};color:${KolaVar.accentText};'
              'font-family:inherit;font-size:${KolaType.body};'
              'font-weight:600;cursor:pointer;'
              'opacity:${enabled ? '1' : '0.65'}',
        },
        events: {
          'click': (_) {
            if (enabled) onTap();
          },
        },
        [Component.text(label)],
      );
}
