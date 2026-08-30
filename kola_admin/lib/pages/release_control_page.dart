// release_control_page.dart — ADMIN_APP_SPEC.md §3.1, the primary
// surface of this whole app for this pass. Everything on this page is
// backed by AdminFeatureEndpoint (kola_server/lib/src/endpoints/admin/
// admin_feature_endpoint.dart) — every mutating call there writes an
// audit log entry before returning, so nothing on this page is a
// silent action.
//
// STATE VALUES are the four in FeatureFlagService: 'locked', 'internal',
// 'beta', 'released' (see that file's header comment for what each
// means to a workspace). Moving TO 'released' requires Owner level
// server-side; every other transition, including the kill switch (→
// 'locked'), requires only Operator — see AdminFeatureEndpoint's own
// doc comments. This page does not duplicate that authorization check
// client-side; it just shows the server's rejection if one comes back,
// since the token's level isn't decoded here (see app.dart's header).
//
// NOT ON THIS PAGE (ADMIN_APP_SPEC.md build-order steps 4-7, explicitly
// deferred — see docs/ADMIN_CONTROL_PLANE_STATUS.md): workspace
// administration, customer service diagnostics, platform health,
// push notifications.

import 'package:jaspr/jaspr.dart' hide VoidCallback;
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

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

  // Per-row pending edit state, keyed by feature key. Kept separate from
  // the flag list itself so typing a note doesn't need a full reload to
  // be reflected, and a reload doesn't wipe an in-progress edit on an
  // unrelated row.
  final Map<String, String> _pendingState = {};
  final Map<String, String> _pendingNote = {};
  final Set<String> _submitting = {};

  String _wave = '';
  String _waveNote = '';
  bool _waveSubmitting = false;

  // Overrides panel — scoped to one feature key at a time, chosen from
  // the flags table above ("Overrides" button per row).
  String? _overrideFeatureKey;
  List<WorkspaceFeatureOverride> _overrides = const [];
  bool _overridesLoading = false;
  String _newOverrideWorkspaceId = '';
  String _newOverrideNote = '';
  bool _newOverrideEnabled = true;
  bool _overrideSubmitting = false;

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
        for (final f in flags) {
          _pendingState[f.key] = f.state;
          _pendingNote.putIfAbsent(f.key, () => '');
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _describe(e);
        _loading = false;
      });
    }
  }

  /// Session-expiry is the one error this page treats specially — every
  /// other failure just shows [_describe]'s message inline.
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

  Future<void> _applyStateChange(FeatureFlag flag) async {
    final newState = _pendingState[flag.key] ?? flag.state;
    final note = (_pendingNote[flag.key] ?? '').trim();
    if (newState == flag.state) {
      _showBanner('${flag.key} is already $newState — nothing to change.');
      return;
    }
    if (note.isEmpty) {
      _showBanner('A note is required before changing ${flag.key}.', isError: true);
      return;
    }
    setState(() => _submitting.add(flag.key));
    try {
      final updated = await component.client.adminFeature.setFeatureState(
        component.adminToken,
        flag.key,
        newState,
        note,
      );
      if (!mounted) return;
      setState(() {
        _flags = [for (final f in _flags) if (f.key == updated.key) updated else f];
        _pendingNote[flag.key] = '';
        _submitting.remove(flag.key);
      });
      _showBanner('${updated.key} → ${updated.state}.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting.remove(flag.key));
      if (_isSessionError(e)) {
        component.onSignOut();
        return;
      }
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
        for (final f in updated) {
          _pendingState[f.key] = f.state;
        }
        _waveSubmitting = false;
        _wave = '';
        _waveNote = '';
      });
      _showBanner('Wave $wave: ${updated.length} flag(s) released.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _waveSubmitting = false);
      if (_isSessionError(e)) {
        component.onSignOut();
        return;
      }
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _openOverrides(String featureKey) async {
    setState(() {
      _overrideFeatureKey = featureKey;
      _overrides = const [];
      _overridesLoading = true;
      _newOverrideWorkspaceId = '';
      _newOverrideNote = '';
      _newOverrideEnabled = true;
    });
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

  Future<void> _addOverride() async {
    final key = _overrideFeatureKey;
    if (key == null) return;
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
        key,
        _newOverrideEnabled,
        note,
      );
      if (!mounted) return;
      await _openOverrides(key);
      setState(() => _overrideSubmitting = false);
      _showBanner('Override saved for workspace $workspaceId.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _overrideSubmitting = false);
      if (_isSessionError(e)) {
        component.onSignOut();
        return;
      }
      _showBanner(_describe(e), isError: true);
    }
  }

  Future<void> _removeOverride(WorkspaceFeatureOverride o) async {
    final key = _overrideFeatureKey;
    if (key == null) return;
    try {
      await component.client.adminFeature.removeOverride(component.adminToken, o.workspaceId, key);
      if (!mounted) return;
      await _openOverrides(key);
      _showBanner('Override removed for workspace ${o.workspaceId}.');
    } catch (e) {
      if (!mounted) return;
      if (_isSessionError(e)) {
        component.onSignOut();
        return;
      }
      _showBanner(_describe(e), isError: true);
    }
  }

  static const _labelStyle = 'font-size:11.5px;color:${AdminColors.muted};margin-bottom:4px';
  static const _smallInputStyle =
      'box-sizing:border-box;background:${AdminColors.bg};border:1px solid ${AdminColors.border};'
      'border-radius:6px;padding:6px 8px;color:${AdminColors.text};font-family:${AdminFonts.mono};'
      'font-size:12.5px;outline:none';

  Component _pill(String text, String bg, String fg, String border) => div(
        attributes: {
          'style': 'display:inline-block;background:$bg;color:$fg;border:1px solid $border;'
              'border-radius:999px;padding:2px 9px;font-size:11.5px;font-family:${AdminFonts.mono};'
              'white-space:nowrap',
        },
        [Component.text(text)],
      );

  Component _stateBadge(String state) {
    switch (state) {
      case 'released':
        return _pill(state, '#132A18', AdminColors.ok, '#204A2A');
      case 'locked':
        return _pill(state, AdminColors.dangerBg, AdminColors.danger, AdminColors.dangerBorder);
      case 'beta':
      case 'internal':
        return _pill(state, AdminColors.warnBg, AdminColors.warn, AdminColors.warnBorder);
      default:
        return _pill(state, AdminColors.card, AdminColors.muted, AdminColors.border);
    }
  }

  Component _flagRow(FeatureFlag flag) {
    final busy = _submitting.contains(flag.key);
    return div(
      attributes: {
        'style': 'display:flex;flex-wrap:wrap;align-items:center;gap:12px;padding:14px 0;'
            'border-bottom:1px solid ${AdminColors.border}',
      },
      [
        div(
          attributes: {'style': 'min-width:220px;flex:1'},
          [
            div(
              attributes: {'style': 'font-family:${AdminFonts.mono};font-size:13px;font-weight:600'},
              [Component.text(flag.key)],
            ),
            div(
              attributes: {'style': 'font-size:12px;color:${AdminColors.muted};margin-top:2px'},
              [Component.text(flag.name)],
            ),
            div(
              attributes: {'style': 'display:flex;gap:6px;margin-top:6px;flex-wrap:wrap'},
              [
                _stateBadge(flag.state),
                _pill(flag.releasePhase, AdminColors.card, AdminColors.muted, AdminColors.border),
                if (flag.externallyGated)
                  _pill('externally gated', AdminColors.warnBg, AdminColors.warn, AdminColors.warnBorder),
                if (flag.minimumPlan != null)
                  _pill('plan: ${flag.minimumPlan}', AdminColors.card, AdminColors.muted, AdminColors.border),
              ],
            ),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;align-items:flex-end;gap:8px;flex-wrap:wrap'},
          [
            div(
              [
                div(attributes: {'style': _labelStyle}, [Component.text('New state')]),
                select(
                  [
                    for (final s in _states)
                      option(value: s, selected: (_pendingState[flag.key] ?? flag.state) == s, [Component.text(s)]),
                  ],
                  onChange: (values) {
                    if (values.isEmpty) return;
                    setState(() => _pendingState[flag.key] = values.first);
                  },
                  attributes: {'style': _smallInputStyle},
                ),
              ],
            ),
            div(
              [
                div(attributes: {'style': _labelStyle}, [Component.text('Note (required)')]),
                input<String>(
                  type: InputType.text,
                  value: _pendingNote[flag.key] ?? '',
                  onInput: (v) => setState(() => _pendingNote[flag.key] = v),
                  attributes: {'style': '$_smallInputStyle;width:220px', 'placeholder': 'why this change'},
                ),
              ],
            ),
            button(
              [Component.text(busy ? '…' : 'Apply')],
              disabled: busy,
              onClick: () => _applyStateChange(flag),
              attributes: {
                'style': 'background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                    'border-radius:6px;padding:8px 12px;font-size:12.5px;font-weight:600;cursor:pointer;'
                    'opacity:${busy ? '0.6' : '1'}',
              },
            ),
            button(
              [Component.text('Overrides')],
              onClick: () => _openOverrides(flag.key),
              attributes: {
                'style': 'background:transparent;color:${AdminColors.text};border:1px solid ${AdminColors.border};'
                    'border-radius:6px;padding:8px 12px;font-size:12.5px;cursor:pointer',
              },
            ),
          ],
        ),
      ],
    );
  }

  Component _reconciliationBanner() {
    if (_missing.isEmpty && _orphaned.isEmpty) return div([]);
    return div(
      attributes: {
        'style': 'background:${AdminColors.warnBg};border:1px solid ${AdminColors.warnBorder};'
            'border-radius:10px;padding:14px 16px;margin-bottom:20px;font-size:13px;color:${AdminColors.warn}',
      },
      [
        if (_missing.isNotEmpty)
          div([Component.text('In code but not in the database (run reconciliation): ${_missing.join(', ')}')]),
        if (_orphaned.isNotEmpty)
          div(
            attributes: {'style': 'margin-top:${_missing.isNotEmpty ? '6px' : '0'}'},
            [Component.text('In the database but no longer in code: ${_orphaned.join(', ')}')],
          ),
      ],
    );
  }

  Component _overridesPanel() {
    final key = _overrideFeatureKey;
    if (key == null) return div([]);
    return div(
      attributes: {
        'style': 'background:${AdminColors.card};border:1px solid ${AdminColors.border};border-radius:12px;'
            'padding:18px;margin-top:24px',
      },
      [
        div(
          attributes: {'style': 'display:flex;justify-content:space-between;align-items:center;margin-bottom:12px'},
          [
            div(
              attributes: {'style': 'font-size:14px;font-weight:600'},
              [Component.text('Overrides — $key')],
            ),
            button(
              [Component.text('Close')],
              onClick: () => setState(() => _overrideFeatureKey = null),
              attributes: {
                'style': 'background:transparent;color:${AdminColors.muted};border:none;'
                    'font-size:12.5px;cursor:pointer',
              },
            ),
          ],
        ),
        if (_overridesLoading)
          div(attributes: {'style': 'color:${AdminColors.muted};font-size:13px'}, [Component.text('Loading…')])
        else if (_overrides.isEmpty)
          div(
            attributes: {'style': 'color:${AdminColors.muted};font-size:13px;margin-bottom:12px'},
            [Component.text('No workspace overrides for this feature.')],
          )
        else
          div(
            [
              for (final o in _overrides)
                div(
                  attributes: {
                    'style': 'display:flex;justify-content:space-between;align-items:center;'
                        'padding:8px 0;border-bottom:1px solid ${AdminColors.border};font-size:13px',
                  },
                  [
                    div(
                      [
                        Component.text('workspace ${o.workspaceId} — '),
                        _stateBadge(o.enabled ? 'released' : 'locked'),
                        div(
                          attributes: {'style': 'color:${AdminColors.muted};font-size:11.5px;margin-top:3px'},
                          [Component.text('${o.note} · by ${o.createdBy}')],
                        ),
                      ],
                    ),
                    button(
                      [Component.text('Remove')],
                      onClick: () => _removeOverride(o),
                      attributes: {
                        'style': 'background:transparent;color:${AdminColors.danger};'
                            'border:1px solid ${AdminColors.dangerBorder};border-radius:6px;'
                            'padding:5px 10px;font-size:11.5px;cursor:pointer',
                      },
                    ),
                  ],
                ),
            ],
          ),
        div(
          attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap;align-items:flex-end;margin-top:14px'},
          [
            div(
              [
                div(attributes: {'style': _labelStyle}, [Component.text('Workspace id')]),
                input<String>(
                  type: InputType.text,
                  value: _newOverrideWorkspaceId,
                  onInput: (v) => setState(() => _newOverrideWorkspaceId = v),
                  attributes: {'style': '$_smallInputStyle;width:110px', 'placeholder': '123'},
                ),
              ],
            ),
            div(
              [
                div(attributes: {'style': _labelStyle}, [Component.text('Enabled')]),
                select(
                  [
                    option(value: 'true', selected: _newOverrideEnabled, [Component.text('true (grant)')]),
                    option(value: 'false', selected: !_newOverrideEnabled, [Component.text('false (deny)')]),
                  ],
                  onChange: (values) {
                    if (values.isEmpty) return;
                    setState(() => _newOverrideEnabled = values.first == 'true');
                  },
                  attributes: {'style': _smallInputStyle},
                ),
              ],
            ),
            div(
              [
                div(attributes: {'style': _labelStyle}, [Component.text('Note (required)')]),
                input<String>(
                  type: InputType.text,
                  value: _newOverrideNote,
                  onInput: (v) => setState(() => _newOverrideNote = v),
                  attributes: {'style': '$_smallInputStyle;width:220px', 'placeholder': 'why this override'},
                ),
              ],
            ),
            button(
              [Component.text(_overrideSubmitting ? '…' : 'Save override')],
              disabled: _overrideSubmitting,
              onClick: _addOverride,
              attributes: {
                'style': 'background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                    'border-radius:6px;padding:8px 12px;font-size:12.5px;font-weight:600;cursor:pointer',
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style': 'font-family:${AdminFonts.sans};background:${AdminColors.bg};color:${AdminColors.text};'
            'min-height:100vh;box-sizing:border-box;padding:28px 32px',
      },
      [
        div(
          attributes: {'style': 'display:flex;justify-content:space-between;align-items:center;margin-bottom:6px'},
          [
            div(
              attributes: {
                'style': 'font-family:${AdminFonts.mono};font-size:13px;letter-spacing:0.08em;'
                    'color:${AdminColors.muted};text-transform:uppercase',
              },
              [Component.text('kola / control plane')],
            ),
            button(
              [Component.text('Sign out')],
              onClick: component.onSignOut,
              attributes: {
                'style': 'background:transparent;color:${AdminColors.muted};border:1px solid ${AdminColors.border};'
                    'border-radius:6px;padding:6px 12px;font-size:12.5px;cursor:pointer',
              },
            ),
          ],
        ),
        div(
          attributes: {'style': 'font-size:22px;font-weight:600;margin-bottom:20px'},
          [Component.text('Release control')],
        ),

        if (_banner != null)
          div(
            attributes: {
              'style':
                  'background:${_bannerIsError ? AdminColors.dangerBg : '#132A18'};'
                  'border:1px solid ${_bannerIsError ? AdminColors.dangerBorder : '#204A2A'};'
                  'color:${_bannerIsError ? AdminColors.danger : AdminColors.ok};border-radius:8px;'
                  'padding:10px 14px;font-size:13px;margin-bottom:16px;display:flex;'
                  'justify-content:space-between;align-items:center',
            },
            [
              Component.text(_banner!),
              button(
                [Component.text('×')],
                onClick: () => setState(() => _banner = null),
                attributes: {
                  'style': 'background:transparent;border:none;color:inherit;cursor:pointer;font-size:15px',
                },
              ),
            ],
          ),

        _reconciliationBanner(),

        div(
          attributes: {
            'style': 'background:${AdminColors.card};border:1px solid ${AdminColors.border};border-radius:12px;'
                'padding:16px 18px;margin-bottom:20px',
          },
          [
            div(
              attributes: {'style': 'font-size:13px;font-weight:600;margin-bottom:10px'},
              [Component.text('Release a wave')],
            ),
            div(
              attributes: {'style': 'display:flex;gap:8px;flex-wrap:wrap;align-items:flex-end'},
              [
                div(
                  [
                    div(attributes: {'style': _labelStyle}, [Component.text('Wave (e.g. R2)')]),
                    input<String>(
                      type: InputType.text,
                      value: _wave,
                      onInput: (v) => setState(() => _wave = v),
                      attributes: {'style': '$_smallInputStyle;width:110px', 'placeholder': 'R2'},
                    ),
                  ],
                ),
                div(
                  [
                    div(attributes: {'style': _labelStyle}, [Component.text('Note (required)')]),
                    input<String>(
                      type: InputType.text,
                      value: _waveNote,
                      onInput: (v) => setState(() => _waveNote = v),
                      attributes: {'style': '$_smallInputStyle;width:260px', 'placeholder': 'why releasing this wave'},
                    ),
                  ],
                ),
                button(
                  [Component.text(_waveSubmitting ? '…' : 'Release wave')],
                  disabled: _waveSubmitting,
                  onClick: _releaseWave,
                  attributes: {
                    'style': 'background:${AdminColors.accent};color:${AdminColors.accentText};border:none;'
                        'border-radius:6px;padding:8px 12px;font-size:12.5px;font-weight:600;cursor:pointer',
                  },
                ),
              ],
            ),
            div(
              attributes: {'style': 'font-size:11.5px;color:${AdminColors.muted};margin-top:8px'},
              [
                Component.text(
                  'Owner level only. Skips any flag that is externally gated — see '
                  "AdminFeatureEndpoint.releaseWave's doc comment.",
                ),
              ],
            ),
          ],
        ),

        if (_loading)
          div(attributes: {'style': 'color:${AdminColors.muted};font-size:13px'}, [Component.text('Loading flags…')])
        else if (_error != null)
          div(
            attributes: {
              'style': 'background:${AdminColors.dangerBg};border:1px solid ${AdminColors.dangerBorder};'
                  'color:${AdminColors.danger};border-radius:8px;padding:12px 14px;font-size:13px',
            },
            [Component.text(_error!)],
          )
        else
          div(
            attributes: {
              'style': 'background:${AdminColors.card};border:1px solid ${AdminColors.border};border-radius:12px;'
                  'padding:6px 18px',
            },
            [for (final f in _flags) _flagRow(f)],
          ),

        _overridesPanel(),
      ],
    );
  }
}
