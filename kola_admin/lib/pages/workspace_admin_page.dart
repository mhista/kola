// workspace_admin_page.dart — ADMIN_APP_SPEC.md §3.2, build-order step 4.
//
// SCOPE, STATED HONESTLY: this covers search by name/exact id, a
// per-workspace detail drawer (plan/status/trial dates/isInternal, bots,
// channels), and the five mutating actions (change plan, extend trial,
// reset trial, suspend, reinstate, mark internal). It does NOT cover
// search by owner email/phone, usage-against-limits, knowledge-document
// index status, subscription/payment history, or impersonation — see
// AdminWorkspaceEndpoint's header for why each of those is a real,
// separate gap rather than something quietly skipped. The detail drawer
// shows a visible note about this rather than pretending the missing
// sections don't exist.
//
// Same structural pattern as release_control_page.dart: a filterable
// table, a right-side detail drawer opened by clicking a row, one banner
// for success/error feedback, styled with the same design-spec tokens.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class WorkspaceAdminPage extends StatefulComponent {
  const WorkspaceAdminPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<WorkspaceAdminPage> createState() => _WorkspaceAdminPageState();
}

class _WorkspaceAdminPageState extends State<WorkspaceAdminPage> {
  bool _loading = true;
  String? _error;
  List<Workspace> _workspaces = const [];
  String _search = '';

  String? _banner;
  bool _bannerIsError = false;

  // Detail drawer.
  Workspace? _drawerWorkspace;
  List<Bot> _drawerBots = const [];
  Map<int, List<Channel>> _drawerChannelsByBot = const {};
  bool _drawerLoading = false;

  String _planChoice = '';
  String _planNote = '';
  bool _planSubmitting = false;

  String _extendDays = '7';
  String _extendNote = '';
  bool _extendSubmitting = false;

  String _resetNote = '';
  bool _resetSubmitting = false;

  String _statusNote = '';
  bool _statusSubmitting = false;

  String _internalNote = '';
  bool _internalSubmitting = false;

  static const _plans = ['free', 'pro', 'business'];

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
      final workspaces = await component.client.adminWorkspace.listWorkspaces(
        component.adminToken,
        query: _search.trim().isEmpty ? null : _search.trim(),
      );
      if (!mounted) return;
      setState(() {
        _workspaces = workspaces;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _describe(e);
        _loading = false;
      });
    }
  }

  bool _isSessionError(Object e) => e.toString().contains('admin_session_invalid');

  String _describe(Object e) {
    if (_isSessionError(e)) return 'Your session has expired. Please sign in again.';
    if (e.toString().contains('admin_access_denied')) {
      return "Your admin level doesn't permit this action.";
    }
    return 'Something went wrong: $e';
  }

  void _showBanner(String message, {bool isError = false}) {
    setState(() {
      _banner = message;
      _bannerIsError = isError;
    });
  }

  Future<void> _openDrawer(Workspace w) async {
    setState(() {
      _drawerWorkspace = w;
      _planChoice = w.plan;
      _planNote = '';
      _extendDays = '7';
      _extendNote = '';
      _resetNote = '';
      _statusNote = '';
      _internalNote = '';
      _drawerBots = const [];
      _drawerChannelsByBot = const {};
      _drawerLoading = true;
    });
    try {
      final bots = await component.client.adminWorkspace.listBotsForWorkspace(
        component.adminToken,
        w.id!,
      );
      final channelsByBot = <int, List<Channel>>{};
      for (final bot in bots) {
        channelsByBot[bot.id!] = await component.client.adminWorkspace.listChannelsForBot(
          component.adminToken,
          bot.id!,
        );
      }
      if (!mounted) return;
      setState(() {
        _drawerBots = bots;
        _drawerChannelsByBot = channelsByBot;
        _drawerLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _drawerLoading = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  void _closeDrawer() => setState(() => _drawerWorkspace = null);

  void _replaceInList(Workspace updated) {
    setState(() {
      _workspaces = [for (final w in _workspaces) if (w.id == updated.id) updated else w];
      _drawerWorkspace = updated;
    });
  }

  Future<void> _changePlan() async {
    final w = _drawerWorkspace;
    if (w == null) return;
    final note = _planNote.trim();
    if (_planChoice == w.plan) {
      _showBanner('Already on plan "${w.plan}" — nothing to change.');
      return;
    }
    if (note.isEmpty) {
      _showBanner('A note is required for a plan change.', isError: true);
      return;
    }
    setState(() => _planSubmitting = true);
    try {
      final updated = await component.client.adminWorkspace.setPlan(
        component.adminToken,
        w.id!,
        _planChoice,
        note,
      );
      if (!mounted) return;
      _replaceInList(updated);
      setState(() {
        _planNote = '';
        _planSubmitting = false;
      });
      _showBanner('${updated.name}: plan → ${updated.plan}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _planSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _extendTrial() async {
    final w = _drawerWorkspace;
    if (w == null) return;
    final days = int.tryParse(_extendDays.trim());
    final note = _extendNote.trim();
    if (days == null || days <= 0) {
      _showBanner('Enter a positive number of days.', isError: true);
      return;
    }
    if (note.isEmpty) {
      _showBanner('A note is required for a trial extension.', isError: true);
      return;
    }
    setState(() => _extendSubmitting = true);
    try {
      final updated = await component.client.adminWorkspace.extendTrial(
        component.adminToken,
        w.id!,
        days,
        note,
      );
      if (!mounted) return;
      _replaceInList(updated);
      setState(() {
        _extendNote = '';
        _extendSubmitting = false;
      });
      _showBanner('${updated.name}: trial extended by $days day(s).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _extendSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _resetTrial() async {
    final w = _drawerWorkspace;
    if (w == null) return;
    final note = _resetNote.trim();
    if (note.isEmpty) {
      _showBanner('A note is required for a trial reset.', isError: true);
      return;
    }
    setState(() => _resetSubmitting = true);
    try {
      final updated = await component.client.adminWorkspace.resetTrial(
        component.adminToken,
        w.id!,
        note,
      );
      if (!mounted) return;
      _replaceInList(updated);
      setState(() {
        _resetNote = '';
        _resetSubmitting = false;
      });
      _showBanner('${updated.name}: trial reset — fresh 14-day window.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _resetSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _toggleSuspend() async {
    final w = _drawerWorkspace;
    if (w == null) return;
    final note = _statusNote.trim();
    if (note.isEmpty) {
      _showBanner('A note is required for this action.', isError: true);
      return;
    }
    setState(() => _statusSubmitting = true);
    try {
      final updated = w.status == 'paused'
          ? await component.client.adminWorkspace.reinstate(component.adminToken, w.id!, note)
          : await component.client.adminWorkspace.suspend(component.adminToken, w.id!, note);
      if (!mounted) return;
      _replaceInList(updated);
      setState(() {
        _statusNote = '';
        _statusSubmitting = false;
      });
      _showBanner('${updated.name}: status → ${updated.status}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _toggleInternal() async {
    final w = _drawerWorkspace;
    if (w == null) return;
    final note = _internalNote.trim();
    if (note.isEmpty) {
      _showBanner('A note is required for this action.', isError: true);
      return;
    }
    setState(() => _internalSubmitting = true);
    try {
      final updated = await component.client.adminWorkspace.setInternal(
        component.adminToken,
        w.id!,
        !w.isInternal,
        note,
      );
      if (!mounted) return;
      _replaceInList(updated);
      setState(() {
        _internalNote = '';
        _internalSubmitting = false;
      });
      _showBanner('${updated.name}: internal → ${updated.isInternal}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _internalSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  (String, String) _statusPair(String status) => switch (status) {
        'active' => (AdminColors.releasedBg, AdminColors.releasedFg),
        'trialing' => (AdminColors.internalBg, AdminColors.internalFg),
        'paused' => (AdminColors.dangerBg, AdminColors.danger),
        _ => (AdminColors.lockedBg, AdminColors.lockedFg),
      };

  String _daysUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now().toUtc()).inHours;
    if (diff < 0) return '${(-diff / 24).ceil()}d ago';
    if (diff < 24) return '${diff}h left';
    return '${(diff / 24).floor()}d left';
  }

  @override
  Component build(BuildContext context) {
    return AdminShell(
      activeLabel: 'Workspaces',
      onSignOut: component.onSignOut,
      onUnbuiltNav: (label) => _showBanner("$label isn't built yet — see docs/ADMIN_CONTROL_PLANE_STATUS.md."),
      paletteExtras: [
        for (final w in _workspaces) AdminNavItem(w.name, route: null),
      ],
      child: div(
        attributes: {'style': 'display:contents'},
        [_content(), if (_drawerWorkspace != null) _drawer(_drawerWorkspace!)],
      ),
    );
  }

  Component _content() {
    return div(
      [
        div(
          [Component.text('Workspaces')],
          attributes: {
            'style': "font-family:${AdminFonts.display};font-size:19px;font-weight:700;color:${AdminColors.heading};margin-bottom:4px",
          },
        ),
        div(
          [Component.text('Search by name or exact id · owner email and phone search not built yet.')],
          attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-bottom:16px'},
        ),

        if (_banner != null) _bannerBar(),

        div(
          attributes: {'style': 'display:flex;gap:10px;margin-bottom:16px'},
          [
            input<String>(
              type: InputType.text,
              value: _search,
              onInput: (v) => setState(() => _search = v),
              attributes: {
                'placeholder': 'Search by name or id, or leave blank for most recent…',
                'style': 'flex:1;background:${AdminColors.card};'
                    'border:1px solid ${AdminColors.border};border-radius:6px;padding:8px 12px;'
                    "color:${AdminColors.text};font-family:${AdminFonts.body};font-size:12.5px;box-sizing:border-box",
              },
            ),
            button(
              [Component.text('Search')],
              onClick: () => _load(),
              attributes: {
                'style': 'border:1px solid ${AdminColors.filterActiveBorder};background:${AdminColors.filterActiveBg};'
                    'color:${AdminColors.filterActiveFg};border-radius:6px;padding:8px 16px;'
                    "font-size:12.5px;font-family:${AdminFonts.body};cursor:pointer;white-space:nowrap",
              },
            ),
          ],
        ),

        if (_loading)
          div([Component.text('Loading workspaces…')], attributes: {'style': 'color:${AdminColors.muted};font-size:13px'})
        else if (_error != null)
          div(
            [Component.text(_error!)],
            attributes: {
              'style': 'background:${AdminColors.dangerBg};border:1px solid ${AdminColors.dangerBorder};'
                  'color:${AdminColors.danger};border-radius:8px;padding:12px 14px;font-size:13px',
            },
          )
        else
          _table(_workspaces),
      ],
    );
  }

  Component _bannerBar() => div(
        attributes: {
          'style': 'background:${_bannerIsError ? AdminColors.dangerBg : AdminColors.releasedBg};'
              'border:1px solid ${_bannerIsError ? AdminColors.dangerBorder : '#23362C'};'
              'color:${_bannerIsError ? AdminColors.danger : AdminColors.releasedFg};border-radius:8px;'
              'padding:10px 14px;font-size:13px;margin-bottom:12px;display:flex;'
              'justify-content:space-between;align-items:center',
        },
        [
          Component.text(_banner!),
          button(
            [Component.text('×')],
            onClick: () => setState(() => _banner = null),
            attributes: {'style': 'background:transparent;border:none;color:inherit;cursor:pointer;font-size:15px'},
          ),
        ],
      );

  Component _table(List<Workspace> workspaces) => div(
        attributes: {'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden'},
        [
          div(
            attributes: {
              'style': 'display:grid;grid-template-columns:60px 1.4fr 90px 100px 130px 80px;gap:8px;'
                  'padding:8px 14px;background:${AdminColors.tableHeaderBg};font-size:10.5px;'
                  'color:${AdminColors.faint};text-transform:uppercase;letter-spacing:0.04em;font-weight:600',
            },
            [
              div([Component.text('ID')]),
              div([Component.text('Name')]),
              div([Component.text('Plan')]),
              div([Component.text('Status')]),
              div([Component.text('Trial')]),
              div([Component.text('Internal')]),
            ],
          ),
          for (final w in workspaces) _row(w),
          if (workspaces.isEmpty)
            div(
              [Component.text('No workspaces match this search.')],
              attributes: {'style': 'padding:20px;text-align:center;color:${AdminColors.faint};font-size:12.5px'},
            ),
        ],
      );

  Component _row(Workspace w) {
    final (bg, fg) = _statusPair(w.status);
    return div(
      events: {'click': (_) => _openDrawer(w)},
      attributes: {
        'style': 'display:grid;grid-template-columns:60px 1.4fr 90px 100px 130px 80px;gap:8px;'
            'padding:8px 14px;border-top:1px solid ${AdminColors.rowBorder};align-items:center;'
            'min-height:38px;cursor:pointer',
      },
      [
        div(
          [Component.text('${w.id}')],
          attributes: {'style': "font-family:${AdminFonts.mono};font-size:11px;color:${AdminColors.muted}"},
        ),
        div(
          [Component.text(w.name)],
          attributes: {
            'style': 'font-size:12.5px;color:${AdminColors.text};overflow:hidden;text-overflow:ellipsis;'
                'white-space:nowrap;min-width:0',
          },
        ),
        div([Component.text(w.plan)], attributes: {'style': 'font-size:12px;color:${AdminColors.muted}'}),
        div([
          span(
            [Component.text(w.status)],
            attributes: {
              'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;background:$bg;color:$fg',
            },
          ),
        ]),
        div(
          [Component.text(_daysUntil(w.status == 'trialing' ? w.trialEndsAt : w.trialFullAccessEndsAt))],
          attributes: {'style': 'font-size:11.5px;color:${AdminColors.faint}'},
        ),
        div(
          [Component.text(w.isInternal ? 'Yes' : '—')],
          attributes: {
            'style': 'font-size:11.5px;color:${w.isInternal ? AdminColors.betaFg : AdminColors.faint}',
          },
        ),
      ],
    );
  }

  Component _label(String text) =>
      div([Component.text(text)], attributes: {'style': 'font-size:11.5px;color:${AdminColors.muted};margin-bottom:4px'});

  String _fieldStyle() => 'box-sizing:border-box;background:${AdminColors.bg};'
      "border:1px solid ${AdminColors.border};border-radius:6px;padding:6px 8px;color:${AdminColors.text};"
      "font-family:${AdminFonts.mono};font-size:12.5px;outline:none";

  Component _section(String title, List<Component> children) => div(
        attributes: {'style': 'margin-top:22px'},
        [
          div(
            [Component.text(title)],
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:13px;font-weight:600;color:${AdminColors.heading};margin-bottom:10px",
            },
          ),
          ...children,
        ],
      );

  Component _drawer(Workspace w) {
    final (bg, fg) = _statusPair(w.status);
    return div(
      attributes: {'style': 'display:contents'},
      [
        div(
          events: {'click': (_) => _closeDrawer()},
          attributes: {'style': 'position:fixed;inset:0;background:rgba(0,0,0,0.5);z-index:90'},
          [],
        ),
        div(
          events: {'click': (e) => e.stopPropagation()},
          attributes: {
            'style': 'position:fixed;top:0;right:0;bottom:0;width:440px;max-width:92vw;'
                'background:${AdminColors.card};border-left:1px solid ${AdminColors.borderLight};'
                'z-index:91;overflow-y:auto;padding:22px 22px 40px;box-sizing:border-box',
          },
          [
            div(
              attributes: {'style': 'display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:4px'},
              [
                div(
                  [Component.text('Workspace #${w.id}')],
                  attributes: {'style': "font-family:${AdminFonts.mono};font-size:13px;color:${AdminColors.muted}"},
                ),
                button(
                  [Component.text('Close')],
                  onClick: () => _closeDrawer(),
                  attributes: {
                    'style': 'background:transparent;border:none;color:${AdminColors.faint};font-size:12.5px;cursor:pointer',
                  },
                ),
              ],
            ),
            div(
              [Component.text(w.name)],
              attributes: {
                'style': "font-family:${AdminFonts.display};font-size:17px;font-weight:700;color:${AdminColors.heading};margin-bottom:6px",
              },
            ),
            div(
              attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap;margin-bottom:6px'},
              [
                span(
                  [Component.text(w.status)],
                  attributes: {
                    'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;background:$bg;color:$fg',
                  },
                ),
                span(
                  [Component.text(w.plan)],
                  attributes: {
                    'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;'
                        'background:${AdminColors.lockedBg};color:${AdminColors.lockedFg}',
                  },
                ),
                if (w.isInternal)
                  span(
                    [Component.text('internal')],
                    attributes: {
                      'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;'
                          'background:${AdminColors.betaBg};color:${AdminColors.betaFg}',
                    },
                  ),
              ],
            ),
            div(
              [
                Component.text(
                  'Trial: ${w.trialStartedAt.toIso8601String().split('T').first} → '
                  'full-access ends ${w.trialFullAccessEndsAt.toIso8601String().split('T').first}, '
                  'trial ends ${w.trialEndsAt.toIso8601String().split('T').first}. Region ${w.region}.',
                ),
              ],
              attributes: {'style': 'font-size:11.5px;color:${AdminColors.faint};line-height:1.5;margin-top:6px'},
            ),

            _section('Bots & channels', [
              if (_drawerLoading)
                div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.faint};font-size:12.5px'})
              else if (_drawerBots.isEmpty)
                div(
                  [Component.text('No bots in this workspace.')],
                  attributes: {'style': 'color:${AdminColors.faint};font-size:12.5px'},
                )
              else
                for (final bot in _drawerBots)
                  div(
                    attributes: {
                      'style': 'padding:8px 0;border-bottom:1px solid ${AdminColors.rowBorder};font-size:12.5px',
                    },
                    [
                      Component.text('${bot.name} — ${bot.status}'),
                      div(
                        [
                          Component.text(
                            (_drawerChannelsByBot[bot.id!] ?? const [])
                                    .map((c) => '${c.platformType}: ${c.status}')
                                    .join(', ')
                                    .let((s) => s.isEmpty ? 'no channels connected' : s),
                          ),
                        ],
                        attributes: {'style': 'color:${AdminColors.faint};font-size:11px;margin-top:2px'},
                      ),
                    ],
                  ),
            ]),

            div(
              [
                Component.text(
                  'Usage limits, knowledge-document index status, and subscription/payment '
                  'history are not built yet — see AdminWorkspaceEndpoint\'s header.',
                ),
              ],
              attributes: {'style': 'font-size:11px;color:${AdminColors.faint};margin-top:12px;line-height:1.5'},
            ),

            div(attributes: {'style': 'height:1px;background:${AdminColors.border};margin:22px 0'}, []),

            _section('Change plan (Operator+)', [
              select(
                [for (final p in _plans) option(value: p, selected: _planChoice == p, [Component.text(p)])],
                onChange: (values) {
                  if (values.isEmpty) return;
                  setState(() => _planChoice = values.first);
                },
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _planNote,
                onInput: (v) => setState(() => _planNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why this change'},
              ),
              button(
                [Component.text(_planSubmitting ? '…' : 'Apply plan change')],
                disabled: _planSubmitting,
                onClick: _changePlan,
                attributes: {
                  'style': 'width:100%;background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                      "border-radius:6px;padding:9px;font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ]),

            _section('Extend trial (Support+)', [
              _label('Days to add'),
              input<String>(
                type: InputType.text,
                value: _extendDays,
                onInput: (v) => setState(() => _extendDays = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:8px', 'placeholder': '7'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _extendNote,
                onInput: (v) => setState(() => _extendNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why extending'},
              ),
              button(
                [Component.text(_extendSubmitting ? '…' : 'Extend trial')],
                disabled: _extendSubmitting,
                onClick: _extendTrial,
                attributes: {
                  'style': 'width:100%;background:transparent;color:${AdminColors.accent};'
                      "border:1px solid ${AdminColors.filterActiveBorder};border-radius:6px;padding:9px;"
                      "font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ]),

            _section('Reset trial (Operator+)', [
              div(
                [Component.text('Restarts a fresh 48h/14d window and sets status back to trialing.')],
                attributes: {'style': 'font-size:11px;color:${AdminColors.faint};margin-bottom:8px'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _resetNote,
                onInput: (v) => setState(() => _resetNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why resetting'},
              ),
              button(
                [Component.text(_resetSubmitting ? '…' : 'Reset trial')],
                disabled: _resetSubmitting,
                onClick: _resetTrial,
                attributes: {
                  'style': 'width:100%;background:transparent;color:${AdminColors.accent};'
                      "border:1px solid ${AdminColors.filterActiveBorder};border-radius:6px;padding:9px;"
                      "font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ]),

            _section(w.status == 'paused' ? 'Reinstate (Operator+)' : 'Suspend (Operator+)', [
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _statusNote,
                onInput: (v) => setState(() => _statusNote = v),
                attributes: {
                  'style': '${_fieldStyle()};width:100%;margin-bottom:10px',
                  'placeholder': w.status == 'paused' ? 'why reinstating' : 'why suspending',
                },
              ),
              button(
                [
                  Component.text(
                    _statusSubmitting ? '…' : (w.status == 'paused' ? 'Reinstate workspace' : 'Suspend workspace'),
                  ),
                ],
                disabled: _statusSubmitting,
                onClick: _toggleSuspend,
                attributes: {
                  'style': 'width:100%;background:transparent;'
                      'color:${w.status == 'paused' ? AdminColors.releasedFg : AdminColors.danger};'
                      "border:1px solid ${w.status == 'paused' ? '#23362C' : AdminColors.dangerBorder};"
                      "border-radius:6px;padding:9px;font-size:12.5px;font-weight:600;"
                      "font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ]),

            _section('Mark ${w.isInternal ? "not internal" : "internal"} (Owner only)', [
              div(
                [
                  Component.text(
                    'Internal workspaces get access to features still in the "internal" '
                    'release state, ahead of any customer. This is the only path that can '
                    'set this flag.',
                  ),
                ],
                attributes: {'style': 'font-size:11px;color:${AdminColors.faint};margin-bottom:8px'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _internalNote,
                onInput: (v) => setState(() => _internalNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why this change'},
              ),
              button(
                [Component.text(_internalSubmitting ? '…' : (w.isInternal ? 'Unmark internal' : 'Mark internal'))],
                disabled: _internalSubmitting,
                onClick: _toggleInternal,
                attributes: {
                  'style': 'width:100%;background:transparent;color:${AdminColors.betaFg};'
                      "border:1px solid #4A3420;border-radius:6px;padding:9px;"
                      "font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
