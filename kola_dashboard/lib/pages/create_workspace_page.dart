// create_workspace_page.dart — the three-step create-workspace wizard.
//
// REBUILT against Kola Create Workspace.dc.html, structure-first.
//
//   state : step · bizName · archetype · ownerName · ownerPhone
//   array : ARCHETYPES(5)
//
// This is the FIRST screen every owner sees after signing up — before
// Overview, before agents, before anything. It stayed on the pre-redesign
// single-page form long after the wizard existed in the exports, because
// DESIGN_DELTA never enumerated the export folder. See the coverage
// table there.
//
// ── THE THREE STEPS ──────────────────────────────────────────────────
//
//   1  "Let's set up your workspace"  business name + what do you sell
//   2  "And you're the owner"         name + WhatsApp number
//   3  "Ready to create {name}"       what happens next
//
// ── STEP 3 IS NOT A CONFIRMATION SCREEN ──────────────────────────────
//
// It looks like one and it is not. Its subtitle is "Here's what happens
// next, so nothing feels sudden" — the product telling a first-time
// owner it will not surprise them. For an audience that has been sold
// non-working software before, that sentence is doing real work, so it
// is carried verbatim rather than paraphrased into "Confirm details".
//
// ── THE PHONE NUMBER NOW DOES SOMETHING ──────────────────────────────
//
// The old flow asked for nothing; this asks for a name and a number and
// both are actually stored. The number is seeded into
// owner_notification_settings server-side, so escalation alerts work
// from the moment the workspace exists — see
// WorkspaceEndpoint.createWorkspace. Asking for something and dropping
// it is worse than not asking.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../services/error_text.dart';
import '../theme.dart';

class CreateWorkspacePage extends StatefulComponent {
  const CreateWorkspacePage({
    required this.client,
    required this.accessToken,
    required this.onCreated,
    required this.onSignOut,
    this.loadFailed = false,
  });

  final Client client;
  final String accessToken;
  final void Function(Workspace workspace) onCreated;
  final void Function() onSignOut;

  /// True when the workspace list could not be FETCHED, as opposed to
  /// genuinely being empty. Both land on this page, and telling a
  /// returning owner to create the business they already have is a bad
  /// way to report a network problem.
  final bool loadFailed;

  @override
  State<CreateWorkspacePage> createState() => _CreateWorkspacePageState();
}

class _CreateWorkspacePageState extends State<CreateWorkspacePage> {
  int _step = 1;

  String _bizName = '';
  String? _archetype;
  String _ownerName = '';
  String _ownerPhone = '';

  bool _creating = false;
  String? _error;

  /// ARCHETYPES(5), verbatim from the export.
  ///
  /// These are shop-owner words, not taxonomy: "Sizes & variants" is how
  /// someone who sells clothing describes their problem, and it maps to
  /// a catalog shape kolaa has to handle differently. Kept as the label
  /// the owner picked so the server stores what they actually said.
  static const _archetypes = <String>[
    'Packaged goods',
    'Sizes & variants',
    'Services',
    'Prepared food',
    'Something else',
  ];

  /// The label that opens a free-text field instead of standing alone.
  static const _otherLabel = 'Something else';

  /// What the owner typed after choosing "Something else".
  String _otherArchetype = '';

  /// What actually gets stored as `workspaces.industry_tag`.
  ///
  /// The four named archetypes store their own label. "Something else"
  /// stores what the owner TYPED, because the label itself is worthless
  /// as a tag — it records only that none of the four fitted. The live
  /// database already has a workspace tagged literally "Something else",
  /// which tells kolaa nothing about what that business sells and is
  /// exactly the outcome this replaces.
  String? get _effectiveArchetype {
    if (_archetype == null) return null;
    if (_archetype != _otherLabel) return _archetype;
    final typed = _otherArchetype.trim();
    return typed.isEmpty ? null : typed;
  }

  /// "Something else" is not a complete answer on its own — it commits
  /// the owner to describing the business, so Continue stays disabled
  /// until they do rather than silently storing the placeholder.
  bool get _canContinueStep1 =>
      _bizName.trim().isNotEmpty && _effectiveArchetype != null;

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      // industryTag is positional — see WorkspaceEndpoint.createWorkspace
      // on why it stayed that way.
      final workspace = await component.client.workspace.createWorkspace(
        component.accessToken,
        _bizName.trim(),
        _effectiveArchetype,
        ownerName: _ownerName.trim(),
        ownerPhone: _ownerPhone.trim(),
      );
      if (!mounted) return;
      component.onCreated(workspace);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = ErrorText.of(e);
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Component build(BuildContext context) => div(
        attributes: {
          'style': 'min-height:100vh;display:flex;align-items:center;'
              'justify-content:center;padding:${KolaSpace.lg};'
              'background-image:${KolaVar.glow};background-repeat:no-repeat',
        },
        [
          div(
            attributes: {
              'style': 'width:100%;max-width:560px;margin:0 auto;'
                  'box-sizing:border-box',
            },
            [
              _progress(),
              if (component.loadFailed) _loadFailedNotice(),
              switch (_step) {
                1 => _stepOne(),
                2 => _stepTwo(),
                _ => _stepThree(),
              },
              if (_error != null) _errorBox(_error!),
              _signOut(),
            ],
          ),
        ],
      );

  /// Three bars. Filled ones are the accent; the rest are inert.
  ///
  /// Deliberately not "Step 2 of 3" in words — the export uses bars, and
  /// a first-time owner reads three short bars as "this is nearly over"
  /// faster than they read a sentence.
  Component _progress() => div(
        attributes: {
          'style': 'display:flex;gap:8px;justify-content:center;'
              'margin-bottom:${KolaSpace.lg}',
        },
        [
          for (var i = 1; i <= 3; i++)
            div(
              attributes: {
                'style': 'width:40px;height:3px;border-radius:2px;'
                    'background:${i <= _step ? KolaVar.accent : KolaVar.border}',
              },
              const [],
            ),
        ],
      );

  // ── Step 1 ─────────────────────────────────────────────────────────

  Component _stepOne() => div([
        _heading("Let's set up your workspace"),
        _sub('A workspace is one business — its own bot, its own memory, '
            'its own team.'),
        _label('Business name'),
        input<String>(
          type: InputType.text,
          value: _bizName,
          onInput: (v) => setState(() => _bizName = v),
          attributes: {
            'placeholder': "e.g. Aisha's Fashion House",
            'aria-label': 'Business name',
            'style': _fieldCss,
          },
        ),
        _label('What do you sell?'),
        div(
          attributes: {
            'style': 'display:flex;flex-wrap:wrap;gap:8px;'
                'margin-bottom:${KolaSpace.md}',
          },
          [for (final a in _archetypes) _archetypeChip(a)],
        ),
        // Revealed only on "Something else". Rendered after the chips
        // rather than as a fifth chip-shaped input so it reads as a
        // follow-up question, which is what it is.
        if (_archetype == _otherLabel) ...[
          // Deliberately not "What do you sell?" again — that label is
          // already above the chips, and repeating it reads as the form
          // not having registered the answer.
          _label('Tell kolaa in your own words'),
          input<String>(
            type: InputType.text,
            value: _otherArchetype,
            onInput: (v) => setState(() => _otherArchetype = v),
            attributes: {
              'placeholder': 'e.g. Auto parts, event rentals, tutoring',
              'aria-label': 'Describe what your business sells',
              'style': _fieldCss,
            },
          ),
        ],
        _primary(
          'Continue',
          enabled: _canContinueStep1,
          onTap: () => setState(() => _step = 2),
        ),
      ]);

  Component _archetypeChip(String label) {
    final active = _archetype == label;
    return button(
      attributes: {
        'type': 'button',
        'aria-pressed': active ? 'true' : 'false',
        'style': 'padding:10px 18px;border-radius:${KolaRadius.pill};'
            'border:1px solid ${active ? KolaVar.accent : KolaVar.border};'
            'background:${active ? KolaVar.accent : 'transparent'};'
            'color:${active ? KolaVar.accentText : KolaVar.text};'
            'font-family:inherit;font-size:${KolaType.body};'
            'font-weight:600;cursor:pointer',
      },
      events: {'click': (_) => setState(() => _archetype = label)},
      [Component.text(label)],
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────

  Component _stepTwo() => div([
        _heading("And you're the owner"),
        _sub('This becomes the account with full control — you can add '
            'your team afterward.'),
        input<String>(
          type: InputType.text,
          value: _ownerName,
          onInput: (v) => setState(() => _ownerName = v),
          attributes: {
            'placeholder': 'Your full name',
            'aria-label': 'Your full name',
            'style': _fieldCss,
          },
        ),
        input<String>(
          type: InputType.tel,
          value: _ownerPhone,
          onInput: (v) => setState(() => _ownerPhone = v),
          attributes: {
            'placeholder': 'WhatsApp number',
            'aria-label': 'WhatsApp number',
            'style': _fieldCss,
          },
        ),
        // Says what the number is FOR. A phone field with no explanation
        // on a signup screen reads as marketing collection, and an owner
        // who suspects that types a fake one — which then silently breaks
        // every escalation alert.
        div(
          attributes: {
            'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
                'line-height:1.55;margin-bottom:${KolaSpace.md}',
          },
          [
            Component.text('kolaa messages you here when a customer needs a '
                'person — not for marketing.'),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:10px'},
          [
            _secondary('Back', () => setState(() => _step = 1)),
            _primary(
              'Continue',
              enabled: true,
              onTap: () => setState(() => _step = 3),
            ),
          ],
        ),
      ]);

  // ── Step 3 ─────────────────────────────────────────────────────────

  Component _stepThree() => div([
        _heading('Ready to create ${_bizName.trim()}'),
        _sub("Here's what happens next, so nothing feels sudden."),
        div(
          attributes: {
            'style': 'border:1px solid ${KolaVar.border};'
                'border-radius:${KolaRadius.lg};background:${KolaVar.card};'
                'padding:${KolaSpace.md};margin-bottom:${KolaSpace.md}',
          },
          [
            _nextStep(1, 'Your workspace is created',
                'You land on your Overview, with a clean starting point.'),
            _nextStep(2, 'Connect a channel',
                'WhatsApp or Telegram — this is where customers actually '
                    'reach you.'),
            // Kept in step with the Overview's day-one card, which
            // lists these same three steps. Two screens describing the
            // same task in different words reads as two different
            // tasks, and the owner sees this one minutes before that
            // one.
            _nextStep(3, 'Add knowledge',
                'Your prices, stock, delivery areas and refund rules — '
                    'kolaa answers from these instead of guessing.'),
          ],
        ),
        div(
          attributes: {'style': 'display:flex;gap:10px'},
          [
            _secondary('Back', () => setState(() => _step = 2)),
            _primary(
              _creating ? 'Creating…' : 'Create workspace',
              enabled: !_creating,
              onTap: _create,
            ),
          ],
        ),
      ]);

  Component _nextStep(int n, String title, String body) => div(
        attributes: {
          'style': 'display:flex;gap:14px;align-items:flex-start;'
              'padding:12px 0',
        },
        [
          div(
            attributes: {
              'style': 'width:24px;height:24px;flex:none;border-radius:50%;'
                  'background:${KolaVar.pill};color:${KolaVar.muted};'
                  'display:flex;align-items:center;justify-content:center;'
                  'font-size:${KolaType.micro};font-weight:700',
            },
            [Component.text('$n')],
          ),
          div(attributes: {'style': 'flex:1'}, [
            div(
              attributes: {
                'style': 'font-size:${KolaType.body};font-weight:700;'
                    'color:${KolaVar.text};margin-bottom:2px',
              },
              [Component.text(title)],
            ),
            div(
              attributes: {
                'style': 'font-size:${KolaType.small};'
                    'color:${KolaVar.muted};line-height:1.55',
              },
              [Component.text(body)],
            ),
          ]),
        ],
      );

  // ── Shared ─────────────────────────────────────────────────────────

  static const _fieldCss =
      'width:100%;box-sizing:border-box;padding:13px 15px;'
      'border-radius:10px;border:1px solid var(--kola-border);'
      'background:var(--kola-card);color:var(--kola-text);'
      'font-family:inherit;font-size:15px;margin-bottom:14px;outline:none';

  Component _heading(String t) => div(
        attributes: {
          'style': 'font-family:${KolaFonts.display};'
              'font-size:${KolaType.h2};font-weight:700;'
              'color:${KolaVar.text};margin-bottom:6px;text-align:center',
        },
        [Component.text(t)],
      );

  Component _sub(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.body};color:${KolaVar.muted};'
              'line-height:1.55;margin-bottom:${KolaSpace.lg};'
              'text-align:center',
        },
        [Component.text(t)],
      );

  Component _label(String t) => div(
        attributes: {
          'style': 'font-size:${KolaType.small};color:${KolaVar.muted};'
              'margin-bottom:6px',
        },
        [Component.text(t)],
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
          'style': 'flex:1;padding:14px 20px;border-radius:${KolaRadius.pill};'
              'border:none;font-family:inherit;font-size:${KolaType.body};'
              'font-weight:700;width:100%;'
              'background:${enabled ? KolaVar.accentFill : KolaVar.pill};'
              'color:${enabled ? KolaVar.accentText : KolaVar.muted};'
              'cursor:${enabled ? 'pointer' : 'default'}',
        },
        events: {
          'click': (_) {
            if (enabled) onTap();
          },
        },
        [Component.text(label)],
      );

  Component _secondary(String label, void Function() onTap) => button(
        attributes: {
          'type': 'button',
          'style': 'padding:14px 24px;border-radius:${KolaRadius.pill};'
              'border:1px solid ${KolaVar.border};background:transparent;'
              'color:${KolaVar.text};font-family:inherit;'
              'font-size:${KolaType.body};font-weight:600;cursor:pointer',
        },
        events: {'click': (_) => onTap()},
        [Component.text(label)],
      );

  Component _errorBox(String message) => div(
        attributes: {
          'style': 'background:#2A1414;border:1px solid #4A2020;'
              'color:#E8A8A8;border-radius:8px;padding:11px 13px;'
              'font-size:${KolaType.small};line-height:1.55;'
              'margin-top:${KolaSpace.sm}',
        },
        [Component.text(message)],
      );

  Component _loadFailedNotice() => div(
        attributes: {
          'style': 'background:#2A2114;border:1px solid #4A3A20;'
              'color:#E9C88C;border-radius:8px;padding:11px 13px;'
              'font-size:${KolaType.small};line-height:1.55;'
              'margin-bottom:${KolaSpace.md}',
        },
        [
          Component.text(
            "We couldn't load your workspaces just now — this looks like a "
            'connection problem rather than a missing workspace. If you '
            'already have one, reload before creating another.',
          ),
        ],
      );

  Component _signOut() => div(
        attributes: {
          'style': 'text-align:center;margin-top:${KolaSpace.lg}',
        },
        [
          button(
            attributes: {
              'type': 'button',
              'style': 'background:transparent;border:none;'
                  'color:${KolaVar.muted};font-family:inherit;'
                  'font-size:${KolaType.small};cursor:pointer',
            },
            events: {'click': (_) => component.onSignOut()},
            [Component.text('Sign out')],
          ),
        ],
      );
}
