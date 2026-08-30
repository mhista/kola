// announcements_page.dart — ADMIN_APP_SPEC.md §3.4 "push notifications",
// build-order step 7, built this pass. Backed by
// AdminAnnouncementEndpoint — see that file's header for the deliberate
// scope cuts (no "feature-enabled" audience mode, no persisted
// announcement history beyond the audit log, no dollar cost estimate —
// recipient count is the real number this platform can show).
//
// FLOW: pick an audience, preview the resolved recipient list/count,
// then compose subject/body and send — send is disabled until a preview
// has been run for the CURRENT audience selection, so nobody sends
// blind.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class AnnouncementsPage extends StatefulComponent {
  const AnnouncementsPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  String _audience = 'all';
  String _audienceValue = '';
  String _subject = '';
  String _body = '';
  String _note = '';

  bool _previewLoading = false;
  List<String> _preview = const [];
  bool _previewedForCurrentSelection = false;

  bool _sending = false;
  String? _banner;
  bool _bannerIsError = false;

  Future<void> _preview_() async {
    setState(() => _previewLoading = true);
    try {
      final rows = await component.client.adminAnnouncement.previewAudience(
        component.adminToken,
        _audience,
        _audienceValue,
      );
      if (!mounted) return;
      setState(() {
        _preview = rows;
        _previewLoading = false;
        _previewedForCurrentSelection = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _banner = 'Preview failed: $e';
        _bannerIsError = true;
      });
    }
  }

  Future<void> _send() async {
    if (_subject.trim().isEmpty || _body.trim().isEmpty) {
      setState(() {
        _banner = 'Subject and body are both required.';
        _bannerIsError = true;
      });
      return;
    }
    if (_note.trim().isEmpty) {
      setState(() {
        _banner = 'A reason/note is required to send a platform announcement.';
        _bannerIsError = true;
      });
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await component.client.adminAnnouncement.sendAnnouncement(
        component.adminToken,
        _audience,
        _audienceValue,
        _subject,
        _body,
        _note,
      );
      if (!mounted) return;
      final parts = result.split('|');
      setState(() {
        _banner = 'Sent to ${parts.isNotEmpty ? parts[0] : "?"} of ${parts.length > 1 ? parts[1] : "?"} workspace(s).';
        _bannerIsError = false;
        _sending = false;
        _previewedForCurrentSelection = false;
        _preview = const [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _banner = 'Send failed: $e';
        _bannerIsError = true;
      });
    }
  }

  @override
  Component build(BuildContext context) => AdminShell(
        activeLabel: 'Push notifications',
        onUnbuiltNav: (_) {},
        onSignOut: component.onSignOut,
        child: div(attributes: {'style': 'max-width:720px'}, [
          div(
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:20px;font-weight:700;"
                  'color:${AdminColors.heading};margin-bottom:4px',
            },
            [Component.text('Platform announcements')],
          ),
          div(
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};margin-bottom:16px'},
            [
              Component.text(
                'Sends through the existing OwnerNotificationDispatcher — every channel a workspace has '
                'enabled and configured. No per-message dollar cost is tracked, so the preview below shows '
                'the real number this platform knows: how many workspaces would receive it.',
              ),
            ],
          ),
          if (_banner != null) _bannerBox(),
          _card([
            _label('Audience'),
            div(attributes: {'style': 'display:flex;gap:8px;margin-bottom:10px'}, [
              _audienceButton('all', 'All workspaces'),
              _audienceButton('plan', 'One plan'),
              _audienceButton('named', 'Named list'),
            ]),
            if (_audience != 'all')
              input<String>(
                type: InputType.text,
                value: _audienceValue,
                onInput: (v) => setState(() {
                  _audienceValue = v;
                  _previewedForCurrentSelection = false;
                }),
                attributes: {
                  'placeholder': _audience == 'plan' ? 'plan e.g. free, pro' : 'workspace ids, comma-separated',
                  'style': _inputStyle,
                },
              ),
            div(attributes: {'style': 'margin-top:10px'}, [
              button(
                [Component.text(_previewLoading ? 'Loading…' : 'Preview recipients')],
                events: {'click': (_) => _preview_()},
                attributes: {'style': _secondaryButtonStyle},
              ),
            ]),
            if (_previewedForCurrentSelection)
              div(
                attributes: {'style': 'margin-top:10px;font-size:12.5px;color:${AdminColors.text}'},
                [Component.text('${_preview.length} workspace(s) will receive this.')],
              ),
            if (_previewedForCurrentSelection && _preview.isNotEmpty)
              div(
                attributes: {
                  'style': 'max-height:140px;overflow-y:auto;border:1px solid ${AdminColors.border};'
                      'border-radius:6px;margin-top:6px',
                },
                [
                  for (final row in _preview.take(50))
                    div(
                      attributes: {
                        'style': 'padding:6px 10px;font-size:11.5px;color:${AdminColors.muted};'
                            'border-bottom:1px solid ${AdminColors.rowBorder}',
                      },
                      [Component.text(row)],
                    ),
                ],
              ),
          ]),
          _card([
            _label('Subject'),
            input<String>(
              type: InputType.text,
              value: _subject,
              onInput: (v) => _subject = v,
              attributes: {'style': _inputStyle, 'placeholder': 'e.g. New feature: broadcast scheduling'},
            ),
            div(attributes: {'style': 'height:10px'}, []),
            _label('Body'),
            textarea(
              attributes: {'rows': '5', 'style': _inputStyle},
              onInput: (v) => _body = v,
              [Component.text(_body)],
            ),
            div(attributes: {'style': 'height:10px'}, []),
            _label('Reason (required, audit-logged)'),
            input<String>(
              type: InputType.text,
              value: _note,
              onInput: (v) => _note = v,
              attributes: {'style': _inputStyle, 'placeholder': 'Why this announcement is going out'},
            ),
            div(attributes: {'style': 'margin-top:14px'}, [
              button(
                [Component.text(_sending ? 'Sending…' : 'Send announcement')],
                events: {
                  'click': (_) => (_sending || !_previewedForCurrentSelection) ? null : _send(),
                },
                attributes: {
                  'style': 'padding:10px 18px;border-radius:6px;border:none;'
                      'background:${_previewedForCurrentSelection ? AdminColors.accent : AdminColors.border};'
                      'color:${_previewedForCurrentSelection ? AdminColors.accentText : AdminColors.faint};'
                      'font-weight:600;cursor:${_previewedForCurrentSelection ? "pointer" : "not-allowed"}',
                },
              ),
              if (!_previewedForCurrentSelection)
                div(
                  attributes: {'style': 'font-size:11.5px;color:${AdminColors.faint};margin-top:6px'},
                  [Component.text('Preview the audience above before sending.')],
                ),
            ]),
          ]),
        ]),
      );

  static const _inputStyle = 'width:100%;box-sizing:border-box;padding:9px 12px;border-radius:6px;'
      'border:1px solid #232323;background:#0C0C0D;color:#D8D6D2;font-family:inherit;font-size:13px';

  static const _secondaryButtonStyle = 'padding:8px 14px;border-radius:6px;border:1px solid #232323;'
      'background:transparent;color:#5B9BD1;font-size:12.5px;cursor:pointer';

  Component _card(List<Component> children) => div(
        attributes: {
          'style': 'border:1px solid ${AdminColors.border};border-radius:8px;background:${AdminColors.card};'
              'padding:16px;margin-bottom:16px',
        },
        children,
      );

  Component _label(String t) => div(
        attributes: {'style': 'font-size:11.5px;font-weight:700;color:${AdminColors.muted};margin-bottom:6px'},
        [Component.text(t)],
      );

  Component _audienceButton(String value, String label) {
    final active = _audience == value;
    return button(
      [Component.text(label)],
      events: {
        'click': (_) => setState(() {
              _audience = value;
              _audienceValue = '';
              _previewedForCurrentSelection = false;
            }),
      },
      attributes: {
        'style': 'padding:7px 12px;border-radius:6px;font-size:12px;cursor:pointer;'
            'border:1px solid ${active ? AdminColors.filterActiveBorder : AdminColors.border};'
            'background:${active ? AdminColors.filterActiveBg : "transparent"};'
            'color:${active ? AdminColors.filterActiveFg : AdminColors.muted}',
      },
    );
  }

  Component _bannerBox() => div(
        attributes: {
          'style': 'padding:10px 14px;border-radius:8px;margin-bottom:14px;font-size:13px;'
              'background:${_bannerIsError ? AdminColors.dangerBg : AdminColors.releasedBg};'
              'color:${_bannerIsError ? AdminColors.danger : AdminColors.releasedFg};'
              'border:1px solid ${_bannerIsError ? AdminColors.dangerBorder : AdminColors.border}',
        },
        [Component.text(_banner!)],
      );
}
