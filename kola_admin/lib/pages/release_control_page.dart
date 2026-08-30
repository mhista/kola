// release_control_page.dart — ADMIN_APP_SPEC.md §3.1, matched against
// the real design spec: "Kola design system specs/kola_admin/exports/
// admin/Kola Admin Release Control.dc.html". That mockup is a READ view
// — a filterable table of flags with state pills, a reconciliation
// banner, and wave-filter pills — and shows no mutation UI at all. This
// page keeps that exact read layout (same grid columns, same colors,
// same header/banner/filter shape) and adds the real mutating
// functionality ADMIN_APP_SPEC.md §3.1 actually requires — state
// transitions, wave release, overrides — behind a right-side detail
// drawer opened by clicking a row, styled with the same tokens rather
// than improvised.
//
// Backed by AdminFeatureEndpoint (kola_server/lib/src/endpoints/admin/
// admin_feature_endpoint.dart) — every mutating call there writes an
// audit log entry before returning.
//
// STATE VALUES: 'locked', 'internal', 'beta', 'released' — see
// FeatureFlagService's header for what each means to a workspace.
// Moving TO 'released' requires Owner level server-side; every other
// transition (including the kill switch) requires only Operator.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../components/admin_shell.dart';
import '../theme.dart';

class ReleaseControlPage extends StatefulComponent {
  const ReleaseControlPage({
    required this.client,
    required this.adminToken,
    required this.onSignOut,
  });

  final Client client;
  final String adminToken;
  final VoidCallback onSignOut;

  @override
  State<ReleaseControlPage> createState() => _ReleaseControlPageState();
}

class _ReleaseControlPageState extends State<ReleaseControlPage> {
  static const _states = ['locked', 'internal', 'beta', 'released'];

  bool _loading = true;
  String? _error;

  List<FeatureFlag> _flags = const [];
  List<String> _missing = const [];
  List<String> _orphaned = const [];

  String _search = '';
  String _waveFilter = 'All';

  // Detail drawer — the one flag currently open, plus its pending edit.
  FeatureFlag? _drawerFlag;
  String _drawerState = '';
  String _drawerNote = '';
  bool _drawerSubmitting = false;

  List<WorkspaceFeatureOverride> _overrides = const [];
  bool _overridesLoading = false;
  String _newOverrideWorkspaceId = '';
  String _newOverrideNote = '';
  bool _newOverrideEnabled = true;
  bool _overrideSubmitting = false;

  bool _waveToolOpen = false;
  String _wave = '';
  String _waveNote = '';
  bool _waveSubmitting = false;

  String? _banner;
  bool _bannerIsError = false;

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
      final flags = await component.client.adminFeature.listFlags(component.adminToken);
      final missing = await component.client.adminFeature.listMissingFeatureKeys(component.adminToken);
      final orphaned = await component.client.adminFeature.listOrphanedFeatureKeys(component.adminToken);
      if (!mounted) return;
      setState(() {
        _flags = flags;
        _missing = missing;
        _orphaned = orphaned;
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
    if (e.toString().contains('feature_externally_gated')) {
      return 'That feature is blocked on something outside the product and '
          "cannot be enabled early — see the flag's externallyGated note.";
    }
    return 'Something went wrong: $e';
  }

  void _showBanner(String message, {bool isError = false}) {
    setState(() {
      _banner = message;
      _bannerIsError = isError;
    });
  }

  List<String> get _waves {
    final phases = _flags.map((f) => f.releasePhase).toSet().toList()..sort();
    return ['All', ...phases, 'Externally gated'];
  }

  /// "49 features · R1–R7", matching the design spec's header meta line
  /// — real release phases only (excludes the synthetic 'All'/
  /// 'Externally gated' filter entries), first through last once sorted.
  String get _headerMeta {
    final phases = _flags.map((f) => f.releasePhase).toSet().toList()..sort();
    if (phases.isEmpty) return '${_flags.length} features';
    final range = phases.length == 1 ? phases.first : '${phases.first}–${phases.last}';
    return '${_flags.length} features · $range';
  }

  List<FeatureFlag> get _visibleFlags {
    final q = _search.trim().toLowerCase();
    return _flags.where((f) {
      if (_waveFilter == 'Externally gated' && !f.externallyGated) return false;
      if (_waveFilter != 'All' && _waveFilter != 'Externally gated' && f.releasePhase != _waveFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return f.key.toLowerCase().contains(q) ||
          f.name.toLowerCase().contains(q) ||
          f.releasePhase.toLowerCase().contains(q);
    }).toList();
  }

  void _openDrawer(FeatureFlag flag) {
    setState(() {
      _drawerFlag = flag;
      _drawerState = flag.state;
      _drawerNote = '';
      _overrides = const [];
    });
    _loadOverrides(flag.key);
  }

  void _closeDrawer() => setState(() => _drawerFlag = null);

  Future<void> _loadOverrides(String featureKey) async {
    setState(() => _overridesLoading = true);
    try {
      final overrides = await component.client.adminFeature.listOverridesForFeature(
        component.adminToken,
        featureKey,
      );
      if (!mounted) return;
      setState(() {
        _overrides = overrides;
        _overridesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _overridesLoading = false);
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _applyStateChange() async {
    final flag = _drawerFlag;
    if (flag == null) return;
    final note = _drawerNote.trim();
    if (_drawerState == flag.state) {
      _showBanner('${flag.key} is already ${flag.state} — nothing to change.');
      return;
    }
    if (note.isEmpty) {
      _showBanner('A note is required before changing ${flag.key}.', isError: true);
      return;
    }
    setState(() => _drawerSubmitting = true);
    try {
      final updated = await component.client.adminFeature.setFeatureState(
        component.adminToken,
        flag.key,
        _drawerState,
        note,
      );
      if (!mounted) return;
      setState(() {
        _flags = [for (final f in _flags) if (f.key == updated.key) updated else f];
        _drawerFlag = updated;
        _drawerNote = '';
        _drawerSubmitting = false;
      });
      _showBanner('${updated.key} → ${updated.state}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _drawerSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _releaseWave() async {
    final wave = _wave.trim();
    final note = _waveNote.trim();
    if (wave.isEmpty || note.isEmpty) {
      _showBanner('Wave and note are both required.', isError: true);
      return;
    }
    setState(() => _waveSubmitting = true);
    try {
      final updated = await component.client.adminFeature.releaseWave(component.adminToken, wave, note);
      if (!mounted) return;
      final byKey = {for (final f in updated) f.key: f};
      setState(() {
        _flags = [for (final f in _flags) byKey[f.key] ?? f];
        _waveSubmitting = false;
        _wave = '';
        _waveNote = '';
        _waveToolOpen = false;
      });
      _showBanner('Wave $wave: ${updated.length} flag(s) released.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _waveSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _addOverride() async {
    final flag = _drawerFlag;
    if (flag == null) return;
    final workspaceId = int.tryParse(_newOverrideWorkspaceId.trim());
    final note = _newOverrideNote.trim();
    if (workspaceId == null) {
      _showBanner('Enter a numeric workspace id.', isError: true);
      return;
    }
    if (note.isEmpty) {
      _showBanner('A note is required for an override.', isError: true);
      return;
    }
    setState(() => _overrideSubmitting = true);
    try {
      await component.client.adminFeature.setOverride(
        component.adminToken,
        workspaceId,
        flag.key,
        _newOverrideEnabled,
        note,
      );
      if (!mounted) return;
      await _loadOverrides(flag.key);
      setState(() {
        _overrideSubmitting = false;
        _newOverrideWorkspaceId = '';
        _newOverrideNote = '';
      });
      _showBanner('Override saved for workspace $workspaceId.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _overrideSubmitting = false);
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _removeOverride(WorkspaceFeatureOverride o) async {
    final flag = _drawerFlag;
    if (flag == null) return;
    try {
      await component.client.adminFeature.removeOverride(component.adminToken, o.workspaceId, flag.key);
      if (!mounted) return;
      await _loadOverrides(flag.key);
      _showBanner('Override removed for workspace ${o.workspaceId}.');
    } catch (e) {
      if (!mounted) return;
      if (_isSessionError(e)) return component.onSignOut();
      _showBanner(_describe(e), isError: true);
    }
  }

  // ── state pill colors — exact STATE_META pairs from the design spec ──
  (String, String) _statePair(String state) => switch (state) {
        'locked' => (AdminColors.lockedBg, AdminColors.lockedFg),
        'internal' => (AdminColors.internalBg, AdminColors.internalFg),
        'beta' => (AdminColors.betaBg, AdminColors.betaFg),
        'released' => (AdminColors.releasedBg, AdminColors.releasedFg),
        _ => (AdminColors.lockedBg, AdminColors.lockedFg),
      };

  @override
  Component build(BuildContext context) {
    return AdminShell(
      activeLabel: 'Release control',
      onSignOut: component.onSignOut,
      onUnbuiltNav: (label) => _showBanner("$label isn't built yet — see docs/ADMIN_CONTROL_PLANE_STATUS.md."),
      paletteExtras: [
        for (final f in _flags) AdminNavItem(f.name, route: null),
      ],
      child: div(
        attributes: {'style': 'display:contents'},
        [_content(), if (_drawerFlag != null) _drawer(_drawerFlag!)],
      ),
    );
  }

  Component _content() {
    final visible = _visibleFlags;
    return div(
      [
        div(
          attributes: {
            'style': 'display:flex;justify-content:space-between;align-items:baseline;'
                'margin-bottom:4px;gap:10px;flex-wrap:wrap',
          },
          [
            div(
              [Component.text('Release control')],
              attributes: {
                'style': "font-family:${AdminFonts.display};font-size:19px;font-weight:700;color:${AdminColors.heading}",
              },
            ),
            div(
              [Component.text(_headerMeta)],
              attributes: {
                'style': "font-size:11.5px;color:${AdminColors.faint};font-family:${AdminFonts.mono};white-space:nowrap",
              },
            ),
          ],
        ),
        div(
          [Component.text('Feature keys, states, and who has an override.')],
          attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-bottom:16px'},
        ),

        if (_banner != null) _bannerBar(),

        if (!_loading && _error == null) _reconciliationBanner(),

        div(
          attributes: {'style': 'display:flex;gap:10px;margin-bottom:16px;flex-wrap:wrap'},
          [
            input<String>(
              type: InputType.text,
              value: _search,
              onInput: (v) => setState(() => _search = v),
              attributes: {
                'placeholder': 'Filter by key, name or wave…',
                'style': 'flex:1;min-width:200px;background:${AdminColors.card};'
                    'border:1px solid ${AdminColors.border};border-radius:6px;padding:8px 12px;'
                    "color:${AdminColors.text};font-family:${AdminFonts.body};font-size:12.5px;box-sizing:border-box",
              },
            ),
            for (final w in _waves) _waveChip(w),
            button(
              [Component.text(_waveToolOpen ? 'Cancel' : 'Release wave')],
              onClick: () => setState(() => _waveToolOpen = !_waveToolOpen),
              attributes: {
                'style': 'border:1px solid ${AdminColors.filterActiveBorder};'
                    'background:${_waveToolOpen ? 'transparent' : AdminColors.filterActiveBg};'
                    'color:${AdminColors.filterActiveFg};border-radius:6px;padding:8px 14px;'
                    "font-size:12px;font-family:${AdminFonts.body};cursor:pointer;white-space:nowrap",
              },
            ),
          ],
        ),

        if (_waveToolOpen) _waveTool(),

        if (_loading)
          div([Component.text('Loading flags…')], attributes: {'style': 'color:${AdminColors.muted};font-size:13px'})
        else if (_error != null)
          div(
            [Component.text(_error!)],
            attributes: {
              'style': 'background:${AdminColors.dangerBg};border:1px solid ${AdminColors.dangerBorder};'
                  'color:${AdminColors.danger};border-radius:8px;padding:12px 14px;font-size:13px',
            },
          )
        else
          _table(visible),
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

  Component _reconciliationBanner() {
    final drift = _missing.isNotEmpty || _orphaned.isNotEmpty;
    return div(
      attributes: {
        'style': 'background:${drift ? AdminColors.dangerBg : AdminColors.releasedBg};'
            'border:1px solid ${drift ? AdminColors.dangerBorder : '#23362C'};border-radius:8px;'
            'padding:10px 16px;margin-bottom:14px;font-size:12.5px;'
            'color:${drift ? AdminColors.danger : AdminColors.releasedFg};'
            'display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap',
      },
      [
        span([
          Component.text(
            drift
                ? 'Drift: ${_missing.length} missing from DB, ${_orphaned.length} orphaned in DB.'
                : 'No drift — code and database agree on all ${_flags.length} features.',
          ),
        ]),
        button(
          [Component.text('Recheck')],
          onClick: () => _load(),
          attributes: {
            'style': "background:transparent;border:none;color:inherit;font-family:${AdminFonts.mono};"
                'font-size:11px;cursor:pointer;text-decoration:underline',
          },
        ),
      ],
    );
  }

  Component _waveChip(String w) {
    final active = w == _waveFilter;
    return button(
      [Component.text(w)],
      onClick: () => setState(() => _waveFilter = w),
      attributes: {
        'style': 'border:1px solid ${active ? AdminColors.filterActiveBorder : AdminColors.border};'
            'background:${active ? AdminColors.filterActiveBg : 'transparent'};'
            'color:${active ? AdminColors.filterActiveFg : AdminColors.muted};'
            "border-radius:6px;padding:8px 14px;font-size:12px;font-family:${AdminFonts.body};"
            'cursor:pointer;white-space:nowrap',
      },
    );
  }

  Component _waveTool() => div(
        attributes: {
          'style': 'background:${AdminColors.card};border:1px solid ${AdminColors.border};border-radius:8px;'
              'padding:14px 16px;margin-bottom:14px;display:flex;gap:8px;flex-wrap:wrap;align-items:flex-end',
        },
        [
          div(
            [
              _label('Wave (e.g. R2)'),
              input<String>(
                type: InputType.text,
                value: _wave,
                onInput: (v) => setState(() => _wave = v),
                attributes: {'style': '${_fieldStyle()};width:110px', 'placeholder': 'R2'},
              ),
            ],
          ),
          div(
            [
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _waveNote,
                onInput: (v) => setState(() => _waveNote = v),
                attributes: {'style': '${_fieldStyle()};width:260px', 'placeholder': 'why releasing this wave'},
              ),
            ],
          ),
          button(
            [Component.text(_waveSubmitting ? '…' : 'Release')],
            disabled: _waveSubmitting,
            onClick: _releaseWave,
            attributes: {
              'style': 'background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                  "border-radius:6px;padding:8px 14px;font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
            },
          ),
          div(
            [
              Component.text(
                'Owner level only. Skips any externally-gated flag in the wave.',
              ),
            ],
            attributes: {'style': 'font-size:11px;color:${AdminColors.faint};flex-basis:100%'},
          ),
        ],
      );

  Component _table(List<FeatureFlag> flags) => div(
        attributes: {'style': 'border:1px solid ${AdminColors.border};border-radius:8px;overflow:hidden'},
        [
          div(
            attributes: {
              'style': 'display:grid;grid-template-columns:110px 1.3fr 110px 110px 90px 70px;gap:8px;'
                  'padding:8px 14px;background:${AdminColors.tableHeaderBg};font-size:10.5px;'
                  'color:${AdminColors.faint};text-transform:uppercase;letter-spacing:0.04em;font-weight:600',
            },
            [
              div([Component.text('Key')]),
              div([Component.text('Name')]),
              div([Component.text('State')]),
              div([Component.text('Min plan')]),
              div([Component.text('Gated')]),
              div([Component.text('Overrides')]),
            ],
          ),
          for (final f in flags) _row(f),
          if (flags.isEmpty)
            div(
              [Component.text('No features match this filter.')],
              attributes: {'style': 'padding:20px;text-align:center;color:${AdminColors.faint};font-size:12.5px'},
            ),
        ],
      );

  Component _row(FeatureFlag f) {
    final (bg, fg) = _statePair(f.state);
    return div(
      events: {'click': (_) => _openDrawer(f)},
      attributes: {
        'style': 'display:grid;grid-template-columns:110px 1.3fr 110px 110px 90px 70px;gap:8px;'
            'padding:8px 14px;border-top:1px solid ${AdminColors.rowBorder};align-items:center;'
            'min-height:38px;cursor:pointer',
      },
      [
        div(
          [Component.text(f.key)],
          attributes: {
            'style': "font-family:${AdminFonts.mono};font-size:10.5px;color:${AdminColors.muted};"
                'overflow:hidden;text-overflow:ellipsis;white-space:nowrap',
          },
        ),
        div(
          [Component.text(f.name)],
          attributes: {
            'style': 'font-size:12.5px;color:${AdminColors.text};overflow:hidden;text-overflow:ellipsis;'
                'white-space:nowrap;min-width:0',
          },
        ),
        div([
          span(
            [Component.text(f.state)],
            attributes: {
              'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;background:$bg;color:$fg',
            },
          ),
        ]),
        div([Component.text(f.minimumPlan ?? '—')], attributes: {'style': 'font-size:12px;color:${AdminColors.muted}'}),
        div(
          [Component.text(f.externallyGated ? 'External' : '—')],
          attributes: {
            'style': 'font-size:11.5px;color:${f.externallyGated ? AdminColors.betaFg : AdminColors.faint}',
          },
        ),
        // Design spec's "Overrides" column shows a live per-flag count.
        // Not fetched eagerly here — that would mean one
        // listOverridesForFeature call per row on every page load
        // (an N+1 against ~49 flags for a number nobody acts on from the
        // table itself). The real count is one click away: opening the
        // drawer fetches and shows it. This dash is an honest "not
        // loaded", not a claim that there are zero.
        div([Component.text('—')], attributes: {'style': 'font-size:12px;color:${AdminColors.faint}'}),
      ],
    );
  }

  Component _label(String text) =>
      div([Component.text(text)], attributes: {'style': 'font-size:11.5px;color:${AdminColors.muted};margin-bottom:4px'});

  String _fieldStyle() => 'box-sizing:border-box;background:${AdminColors.bg};'
      "border:1px solid ${AdminColors.border};border-radius:6px;padding:6px 8px;color:${AdminColors.text};"
      "font-family:${AdminFonts.mono};font-size:12.5px;outline:none";

  Component _drawer(FeatureFlag flag) {
    final (bg, fg) = _statePair(flag.state);
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
          'style': 'position:fixed;top:0;right:0;bottom:0;width:420px;max-width:92vw;'
              'background:${AdminColors.card};border-left:1px solid ${AdminColors.borderLight};'
              'z-index:91;overflow-y:auto;padding:22px 22px 40px;box-sizing:border-box',
        },
        [
          div(
            attributes: {'style': 'display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:4px'},
            [
              div(
                [Component.text(flag.key)],
                attributes: {
                  'style': "font-family:${AdminFonts.mono};font-size:13px;color:${AdminColors.muted}",
                },
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
            [Component.text(flag.name)],
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:17px;font-weight:700;color:${AdminColors.heading};margin-bottom:6px",
            },
          ),
          div(
            [Component.text(flag.description)],
            attributes: {'style': 'font-size:12.5px;color:${AdminColors.muted};line-height:1.5;margin-bottom:12px'},
          ),
          div(
            attributes: {'style': 'display:flex;gap:6px;flex-wrap:wrap;margin-bottom:20px'},
            [
              span(
                [Component.text(flag.state)],
                attributes: {
                  'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;background:$bg;color:$fg',
                },
              ),
              if (flag.externallyGated)
                span(
                  [Component.text('externally gated')],
                  attributes: {
                    'style': 'font-size:11px;font-weight:600;padding:2px 9px;border-radius:100px;'
                        'background:${AdminColors.betaBg};color:${AdminColors.betaFg}',
                  },
                ),
            ],
          ),

          div(
            [Component.text('Change state')],
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:13px;font-weight:600;color:${AdminColors.heading};margin-bottom:10px",
            },
          ),
          div(
            [
              _label('New state'),
              select(
                [
                  for (final s in _states) option(value: s, selected: _drawerState == s, [Component.text(s)]),
                ],
                onChange: (values) {
                  if (values.isEmpty) return;
                  setState(() => _drawerState = values.first);
                },
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _drawerNote,
                onInput: (v) => setState(() => _drawerNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why this change'},
              ),
              button(
                [Component.text(_drawerSubmitting ? '…' : 'Apply')],
                disabled: _drawerSubmitting,
                onClick: _applyStateChange,
                attributes: {
                  'style': 'width:100%;background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                      "border-radius:6px;padding:10px;font-size:13px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ],
          ),

          div(
            attributes: {'style': 'height:1px;background:${AdminColors.border};margin:22px 0'},
            [],
          ),

          div(
            [Component.text('Workspace overrides')],
            attributes: {
              'style': "font-family:${AdminFonts.display};font-size:13px;font-weight:600;color:${AdminColors.heading};margin-bottom:10px",
            },
          ),
          if (_overridesLoading)
            div([Component.text('Loading…')], attributes: {'style': 'color:${AdminColors.faint};font-size:12.5px'})
          else if (_overrides.isEmpty)
            div(
              [Component.text('No workspace overrides for this feature.')],
              attributes: {'style': 'color:${AdminColors.faint};font-size:12.5px;margin-bottom:12px'},
            )
          else
            div(
              [
                for (final o in _overrides)
                  div(
                    attributes: {
                      'style': 'display:flex;justify-content:space-between;align-items:center;padding:8px 0;'
                          'border-bottom:1px solid ${AdminColors.rowBorder};font-size:12.5px',
                    },
                    [
                      div(
                        [
                          Component.text('workspace ${o.workspaceId} — ${o.enabled ? 'enabled' : 'disabled'}'),
                          div(
                            [Component.text('${o.note} · by ${o.createdBy}')],
                            attributes: {'style': 'color:${AdminColors.faint};font-size:11px;margin-top:2px'},
                          ),
                        ],
                      ),
                      button(
                        [Component.text('Remove')],
                        onClick: () => _removeOverride(o),
                        attributes: {
                          'style': 'background:transparent;color:${AdminColors.danger};'
                              'border:1px solid ${AdminColors.dangerBorder};border-radius:6px;'
                              'padding:5px 10px;font-size:11px;cursor:pointer',
                        },
                      ),
                    ],
                  ),
              ],
            ),
          div(
            attributes: {'style': 'margin-top:12px'},
            [
              _label('Workspace id'),
              input<String>(
                type: InputType.text,
                value: _newOverrideWorkspaceId,
                onInput: (v) => setState(() => _newOverrideWorkspaceId = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:8px', 'placeholder': '123'},
              ),
              _label('Enabled'),
              select(
                [
                  option(value: 'true', selected: _newOverrideEnabled, [Component.text('true (grant)')]),
                  option(value: 'false', selected: !_newOverrideEnabled, [Component.text('false (deny)')]),
                ],
                onChange: (values) {
                  if (values.isEmpty) return;
                  setState(() => _newOverrideEnabled = values.first == 'true');
                },
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:8px'},
              ),
              _label('Note (required)'),
              input<String>(
                type: InputType.text,
                value: _newOverrideNote,
                onInput: (v) => setState(() => _newOverrideNote = v),
                attributes: {'style': '${_fieldStyle()};width:100%;margin-bottom:10px', 'placeholder': 'why this override'},
              ),
              button(
                [Component.text(_overrideSubmitting ? '…' : 'Save override')],
                disabled: _overrideSubmitting,
                onClick: _addOverride,
                attributes: {
                  'style': 'width:100%;background:transparent;color:${AdminColors.accent};'
                      "border:1px solid ${AdminColors.filterActiveBorder};border-radius:6px;padding:9px;"
                      "font-size:12.5px;font-weight:600;font-family:${AdminFonts.body};cursor:pointer",
                },
              ),
            ],
          ),
        ],
      ),
      ],
    );
  }
}
