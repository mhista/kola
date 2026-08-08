// create_workspace_page.dart — shown when an authenticated user has
// zero workspaces (DashboardApp's redirect guard routes here in that
// case — see app.dart). Calls WorkspaceEndpoint.createWorkspace, whose
// own doc comment confirms this really is "the very first authenticated
// write path" a new user hits — no requireWorkspaceAccess check exists
// yet to satisfy, since there's no workspace to check membership
// against.
//
// [onCreated] hands the new Workspace back to DashboardApp's State,
// which selects it and lets the redirect guard proceed to '/'.
//
// [onSignOut] (added Phase 4e) — this page has no sidebar/nav chrome at
// all, and DashboardApp's redirect guard traps an authenticated,
// workspace-less visitor here with no other route reachable. Without
// an escape hatch, a stuck workspace-creation attempt (e.g. kola_server
// misconfigured) leaves no way back to /login short of manually
// clearing browser storage — a real dead end, not just a rough edge.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';

class CreateWorkspacePage extends StatefulComponent {
  const CreateWorkspacePage({
    required this.client,
    required this.accessToken,
    required this.onCreated,
    required this.onSignOut,
  });

  final Client client;
  final String accessToken;
  final void Function(Workspace workspace) onCreated;
  final void Function() onSignOut;

  @override
  State<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends State<CreateWorkspacePage> {
  String _name = '';
  String _industryTag = '';
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_name.trim().isEmpty) {
      setState(() => _error = 'Give your business a name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final workspace = await component.client.workspace.createWorkspace(
        component.accessToken,
        _name.trim(),
        _industryTag.trim().isEmpty ? null : _industryTag.trim(),
      );
      component.onCreated(workspace);
    } catch (_) {
      setState(() {
        _error = "Couldn't create your workspace. Check your connection and try again.";
        _loading = false;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {
        'style':
            "font-family:${KolaDashboardFonts.sans};background:${KolaDashboardColors.bg};"
            'color:${KolaDashboardColors.text};width:100%;height:100vh;overflow-y:auto;'
            'display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:24px',
      },
      [
        div(
          attributes: {
            'style':
                'width:100%;max-width:420px;background:${KolaDashboardColors.card};'
                'border:1px solid ${KolaDashboardColors.border};border-radius:16px;padding:32px;'
                'box-sizing:border-box',
          },
          [
            div(
              attributes: {
                'style': 'display:flex;justify-content:space-between;align-items:flex-start',
              },
              [
                div(
                  attributes: {'style': 'font-size:19px;font-weight:700;margin-bottom:6px'},
                  [Component.text('Set up your business')],
                ),
                span(
                  attributes: {
                    'style': 'font-size:12.5px;color:${KolaDashboardColors.muted};cursor:pointer;flex-shrink:0',
                  },
                  events: {'click': (_) => component.onSignOut()},
                  [Component.text('Sign out')],
                ),
              ],
            ),
            div(
              attributes: {'style': 'font-size:14px;color:${KolaDashboardColors.muted};margin-bottom:24px'},
              [Component.text("This is the workspace your bots and errands will live in.")],
            ),

            if (_error != null)
              div(
                attributes: {
                  'style':
                      'background:#2A1414;border:1px solid #4A2020;color:#E8A8A8;border-radius:8px;'
                      'padding:10px 12px;font-size:13px;margin-bottom:16px',
                },
                [Component.text(_error!)],
              ),

            _field(
              labelText: 'Business name',
              child: input<String>(
                type: InputType.text,
                value: _name,
                onInput: (v) => setState(() => _name = v),
                attributes: {'style': _inputStyle, 'placeholder': "Aisha's Fashion House"},
              ),
            ),
            _field(
              labelText: 'Industry (optional)',
              child: input<String>(
                type: InputType.text,
                value: _industryTag,
                onInput: (v) => setState(() => _industryTag = v),
                attributes: {'style': _inputStyle, 'placeholder': 'Retail, food, services…'},
              ),
            ),

            button(
              [Component.text(_loading ? 'Creating…' : 'Create workspace')],
              type: ButtonType.submit,
              disabled: _loading,
              onClick: _submit,
              attributes: {
                'style':
                    'width:100%;background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                    'border:none;border-radius:10px;padding:12px;font-size:14.5px;font-weight:600;'
                    'margin-top:8px;cursor:pointer;opacity:${_loading ? '0.7' : '1'}',
              },
            ),
          ],
        ),
      ],
    );
  }

  static const _inputStyle =
      'width:100%;background:#141416;border:1px solid #2C2A28;border-radius:9px;'
      'padding:11px 12px;font-size:14px;color:#F3EEE7;box-sizing:border-box';

  Component _field({required String labelText, required Component child}) => div(
    attributes: {'style': 'margin-bottom:14px'},
    [
      label(
        [Component.text(labelText)],
        attributes: {
          'style': 'display:block;font-size:12.5px;color:${KolaDashboardColors.mutedStrong};margin-bottom:6px',
        },
      ),
      child,
    ],
  );
}
