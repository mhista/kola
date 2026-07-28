// billing_page.dart — task #139/#8d: closes two gaps at once.
//
// 1. The sidebar's "Billing" nav item was a '#' placeholder (no page
//    existed). This is that page — plan, trial standing, and current
//    usage against PlanLimits for the signed-in workspace.
// 2. DEVELOPMENT_PLAN.md §8d's still-flagged "cross-workspace billing/
//    summary view" for the agency/reseller tier: when the signed-in
//    user belongs to more than one workspace (SidebarNav's own
//    workspace-switcher threshold, task #131), this page also renders
//    a comparison row per workspace instead of just the current one.
//
// DATA SOURCE: WorkspaceEndpoint.getBillingSummary (new this pass) —
// see that method's own doc comment for why it reads Workspace.plan/
// .status/.trial* + TrialStateMachine + UsageRecordRepository rather
// than the Subscription model. Subscription stays null for virtually
// every workspace today (it's only populated once Phase 5c's gateway
// integration actually charges someone for the first time — see
// subscription.spy.yaml's header) — showing it here would mean an
// almost-always-empty page. This page shows what's actually true today:
// plan tier, trial countdown, and usage against the two CONFIRMED plan
// caps (PlanLimits.cappedFreeDailyMessageCap / .cappedFreeErrandCap).
//
// A NEW ENDPOINT METHOD, SO CODEGEN MUST RUN FIRST: WorkspaceEndpoint.
// getBillingSummary is brand new — kola_client won't expose
// `client.workspace.getBillingSummary` until `serverpod generate` runs
// in kola_server and kola_client's generated code is refreshed. This
// page will fail to compile against the CURRENT kola_client until then
// — same "re-run codegen" step every other new endpoint method in this
// project has needed (see README.md's WhatsApp manual-connect note).
//
// TASK #148 — same codegen requirement now applies to
// WorkspaceEndpoint.initiateUpgrade AND the new KolaBillingCheckout
// model this page's upgrade card depends on. This is Kola's OWN
// subscription checkout (₦10,000/month — CONFIRMED WITH THE USER
// 2026-07-27), via KOLA'S OWN Paystack/Flutterwave account, NOT a
// business's own gateway — see kola_billing_service.dart's header for
// why that's a fully separate flow from PaymentEndpoint.
// initializeCheckout.
//
// STANDALONE PAGE, NO SIDEBAR — same convention as every other page
// reachable from a real nav link (bots_page.dart, errand_builder_page.
// dart, knowledge_page.dart, conversations_page.dart, integrations_
// page.dart).

import 'dart:convert';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:kola_client/kola_client.dart';

import '../theme.dart';
import '../components/back_link.dart';

class BillingPage extends StatefulComponent {
  const BillingPage({
    required this.client,
    required this.accessToken,
    required this.workspaceId,
    required this.workspaces,
    required this.userEmail,
  });

  final Client client;
  final String accessToken;
  final int workspaceId;

  /// Every workspace the signed-in user belongs to — same list app.dart
  /// already threads into SidebarNav for the workspace switcher (task
  /// #131). Rendering a per-workspace row only kicks in above 1, same
  /// threshold as that switcher.
  final List<Workspace> workspaces;

  /// TASK #148 — the signed-in user's own email, needed by
  /// WorkspaceEndpoint.initiateUpgrade (Paystack/Flutterwave both
  /// require an email on the checkout, regardless of who's actually
  /// paying).
  final String? userEmail;

  @override
  State<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  Map<int, Map<String, dynamic>> _summaries = {};
  Map<int, String> _errors = {};
  bool _loading = true;

  // TASK #148 — per-workspace upgrade state. Both gateways at once, per
  // the user's own choice — a per-workspace gateway picker defaulting
  // to Paystack, not a global one, since a user with multiple
  // workspaces (the agency tier) might reasonably prefer different
  // gateways for different ones.
  final Map<int, String> _selectedGateway = {};
  final Set<int> _upgrading = {};
  final Map<int, String> _upgradeError = {};
  final Map<int, String> _checkoutUrl = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final targets = component.workspaces.isEmpty
        ? [component.workspaceId]
        : component.workspaces.map((w) => w.id!).toList();

    final summaries = <int, Map<String, dynamic>>{};
    final errors = <int, String>{};

    for (final id in targets) {
      try {
        final raw = await component.client.workspace.getBillingSummary(component.accessToken, id);
        summaries[id] = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        errors[id] = "Couldn't load billing info for this workspace.";
      }
    }

    if (mounted) {
      setState(() {
        _summaries = summaries;
        _errors = errors;
        _loading = false;
      });
    }
  }

  /// TASK #148 — starts a Kola subscription checkout for [workspaceId]
  /// via whichever gateway is selected for it (defaulting to Paystack).
  /// On success, stores the gateway's own checkout URL rather than
  /// navigating there automatically — same "no imperative navigation"
  /// convention every other page in this codebase follows (see
  /// bot_detail_dev_page.dart's header), just applied to an EXTERNAL
  /// redirect here: a real `<a>` the owner clicks themselves, not a
  /// silent tab-hijack away from the dashboard they were just looking at.
  Future<void> _upgrade(int workspaceId) async {
    final email = component.userEmail;
    if (email == null || email.isEmpty) {
      setState(() => _upgradeError[workspaceId] = 'No email on file for your account — sign in again.');
      return;
    }
    setState(() {
      _upgrading.add(workspaceId);
      _upgradeError.remove(workspaceId);
    });
    try {
      final checkout = await component.client.workspace.initiateUpgrade(
        component.accessToken,
        workspaceId,
        _selectedGateway[workspaceId] ?? 'paystack',
        email,
      );
      if (mounted) {
        setState(() {
          _upgrading.remove(workspaceId);
          if (checkout.checkoutUrl != null) {
            _checkoutUrl[workspaceId] = checkout.checkoutUrl!;
          } else {
            _upgradeError[workspaceId] = "Checkout started but no payment link came back — try again.";
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _upgrading.remove(workspaceId);
          _upgradeError[workspaceId] = "Couldn't start checkout. Check your connection and try again.";
        });
      }
    }
  }

  static String _planLabel(String plan) => plan.isEmpty ? 'Free' : '${plan[0].toUpperCase()}${plan.substring(1)}';

  static (String, String) _tierChip(String tier) {
    switch (tier) {
      case 'fullTrial':
        return ('#7ED8B0', 'Full trial access');
      case 'paid':
        return ('#7ED8B0', 'Active');
      case 'cappedFree':
        return ('#E0B168', 'Trial — capped');
      case 'paused':
        return ('#D97D6B', 'Paused');
      default:
        return (KolaDashboardColors.muted, tier);
    }
  }

  static int? _daysUntil(String? iso) {
    if (iso == null) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    final diff = date.difference(DateTime.now().toUtc()).inHours;
    return (diff / 24).ceil();
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
          attributes: {'style': 'max-width:800px;width:100%'},
          [
            div(
              attributes: {'style': 'margin-bottom:20px'},
              [backLink()],
            ),
            div(
              attributes: {'style': 'margin-bottom:24px'},
              [
                div(
                  attributes: {
                    'style': "font-family:${KolaDashboardFonts.display};font-size:22px;font-weight:700;margin-bottom:6px",
                  },
                  [Component.text('Billing')],
                ),
                div(
                  attributes: {
                    'style': 'font-size:14px;color:${KolaDashboardColors.mutedSecondary};line-height:1.5;max-width:560px',
                  },
                  [
                    Component.text(
                      component.workspaces.length > 1
                          ? 'Plan and usage across every workspace you belong to.'
                          : "Your plan, trial standing, and this month's usage.",
                    ),
                  ],
                ),
              ],
            ),
            _content(),
          ],
        ),
      ],
    );
  }

  Component _content() {
    if (_loading) return _emptyCard('Loading…');
    if (_summaries.isEmpty) return _emptyCard("Couldn't load billing info. Check your connection and try again.");

    final ids = component.workspaces.isEmpty
        ? [component.workspaceId]
        : component.workspaces.map((w) => w.id!).toList();

    return div(
      attributes: {'style': 'display:flex;flex-direction:column;gap:16px'},
      [for (final id in ids) _workspaceCard(id)],
    );
  }

  Component _emptyCard(String text) => div(
    attributes: {
      'style':
          'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
          'border-radius:18px;padding:40px 20px;text-align:center;color:${KolaDashboardColors.muted};font-size:13.5px',
    },
    [Component.text(text)],
  );

  Component _workspaceCard(int id) {
    final summary = _summaries[id];
    if (summary == null) {
      return div(
        attributes: {
          'style':
              'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
              'border-radius:18px;padding:20px;color:${KolaDashboardColors.muted};font-size:13px',
        },
        [Component.text(_errors[id] ?? "Couldn't load this workspace's billing info.")],
      );
    }

    final tier = summary['effectiveTier'] as String;
    final (dotColor, tierLabel) = _tierChip(tier);
    final plan = summary['plan'] as String;
    final workspaceName = summary['workspaceName'] as String? ?? 'Workspace';
    final trialEndsAt = summary['trialEndsAt'] as String?;
    final trialFullAccessEndsAt = summary['trialFullAccessEndsAt'] as String?;
    final messagesToday = (summary['messagesToday'] as num).toInt();
    final messagesDailyCap = summary['messagesDailyCap'] as int?;
    final activeErrandCount = (summary['activeErrandCount'] as num).toInt();
    final errandCap = summary['errandCap'] as int?;
    final messagesThisMonth = (summary['messagesThisMonth'] as num).toInt();
    final errandCallsThisMonth = (summary['errandCallsThisMonth'] as num).toInt();
    final priceKobo = summary['paidPlanMonthlyPriceKobo'] as int? ?? 1000000;
    final isPaid = tier == 'paid';

    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.card};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:18px;padding:20px 22px;display:flex;flex-direction:column;gap:16px',
      },
      [
        div(
          attributes: {'style': 'display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px'},
          [
            div([
              if (component.workspaces.length > 1)
                div(
                  attributes: {'style': 'font-size:13.5px;font-weight:600;margin-bottom:2px'},
                  [Component.text(workspaceName)],
                ),
              div(
                attributes: {'style': 'display:flex;align-items:center;gap:8px'},
                [
                  span(
                    attributes: {'style': "font-family:${KolaDashboardFonts.display};font-size:17px;font-weight:700"},
                    [Component.text('${_planLabel(plan)} plan')],
                  ),
                ],
              ),
            ]),
            div(
              attributes: {
                'style':
                    'display:flex;align-items:center;gap:6px;background:${KolaDashboardColors.pill};'
                    'border:1px solid ${KolaDashboardColors.border};border-radius:100px;padding:5px 12px',
              },
              [
                span(attributes: {'style': 'width:6px;height:6px;border-radius:50%;background:$dotColor'}, []),
                span(attributes: {'style': 'font-size:12px;color:$dotColor;font-weight:600'}, [Component.text(tierLabel)]),
              ],
            ),
          ],
        ),
        if (tier == 'fullTrial' || tier == 'cappedFree') _trialNote(tier, trialFullAccessEndsAt, trialEndsAt),
        div(
          attributes: {'style': 'display:flex;gap:14px;flex-wrap:wrap'},
          [
            _usageStat('Messages today', messagesToday, messagesDailyCap),
            _usageStat('Active Errands', activeErrandCount, errandCap),
          ],
        ),
        if (!isPaid) _upgradeCard(id, priceKobo),
        div(
          attributes: {
            'style': 'font-size:12px;color:${KolaDashboardColors.muted};border-top:1px solid ${KolaDashboardColors.pill};padding-top:12px',
          },
          [Component.text('This month: $messagesThisMonth messages handled, $errandCallsThisMonth Errand calls.')],
        ),
      ],
    );
  }

  Component _trialNote(String tier, String? fullAccessIso, String? endsIso) {
    final daysLeft = _daysUntil(endsIso);
    final hoursLeft = _daysUntil(fullAccessIso);
    final text = tier == 'fullTrial'
        ? 'Full-access trial — steps down to the free-tier limits below in ${hoursLeft ?? '?'} day${hoursLeft == 1 ? '' : 's'}.'
        : 'On the free-tier limits below — trial pauses in ${daysLeft ?? '?'} day${daysLeft == 1 ? '' : 's'} unless upgraded.';
    return div(
      attributes: {
        'style':
            'font-size:12.5px;color:${KolaDashboardColors.mutedSecondary};background:${KolaDashboardColors.pill};'
            'border-radius:10px;padding:9px 12px',
      },
      [Component.text(text)],
    );
  }

  /// TASK #148 — the upgrade card itself: a gateway picker, a submit
  /// button, and (once checkout starts) a real link to Paystack/
  /// Flutterwave's own hosted checkout page. Never auto-redirects — see
  /// _upgrade()'s own doc comment on why.
  Component _upgradeCard(int workspaceId, int priceKobo) {
    final gateway = _selectedGateway[workspaceId] ?? 'paystack';
    final upgrading = _upgrading.contains(workspaceId);
    final error = _upgradeError[workspaceId];
    final checkoutUrl = _checkoutUrl[workspaceId];
    final priceLabel = '₦${(priceKobo / 100).toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    )}';

    return div(
      attributes: {
        'style':
            'background:${KolaDashboardColors.pill};border:1px solid ${KolaDashboardColors.border};'
            'border-radius:12px;padding:14px 16px;display:flex;flex-direction:column;gap:10px',
      },
      [
        div([
          span(attributes: {'style': 'font-size:13.5px;font-weight:600'}, [Component.text('Upgrade to Pro — ')]),
          span(attributes: {'style': 'font-size:13.5px;font-weight:600;color:${KolaDashboardColors.accent}'}, [Component.text('$priceLabel/month')]),
        ]),
        if (checkoutUrl != null)
          a(
            href: checkoutUrl,
            attributes: {
              'target': '_blank',
              'style':
                  'display:inline-block;background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};'
                  'border-radius:100px;padding:8px 16px;font-size:13px;font-weight:600;text-decoration:none;width:fit-content',
            },
            [Component.text('Complete payment →')],
          )
        else
          div(
            attributes: {'style': 'display:flex;align-items:center;gap:10px;flex-wrap:wrap'},
            [
              div(
                attributes: {'style': 'display:flex;gap:6px'},
                [
                  _gatewayOption(workspaceId, 'paystack', 'Paystack', gateway),
                  _gatewayOption(workspaceId, 'flutterwave', 'Flutterwave', gateway),
                ],
              ),
              button(
                [Component.text(upgrading ? 'Starting…' : 'Upgrade')],
                type: ButtonType.button,
                disabled: upgrading,
                onClick: () => _upgrade(workspaceId),
                attributes: {
                  'style':
                      'background:${KolaDashboardColors.accent};color:${KolaDashboardColors.accentText};border:none;'
                      'border-radius:100px;padding:7px 16px;font-size:12.5px;font-weight:600;cursor:pointer;'
                      'opacity:${upgrading ? "0.7" : "1"}',
                },
              ),
            ],
          ),
        if (error != null)
          div(attributes: {'style': 'font-size:12px;color:#E8A8A8'}, [Component.text(error)]),
      ],
    );
  }

  Component _gatewayOption(int workspaceId, String value, String label, String selected) {
    final isSelected = selected == value;
    return div(
      attributes: {
        'style':
            'padding:6px 12px;border-radius:100px;font-size:12px;cursor:pointer;'
            'background:${isSelected ? KolaDashboardColors.accent : "transparent"};'
            'color:${isSelected ? KolaDashboardColors.accentText : KolaDashboardColors.navInactiveText};'
            'border:1px solid ${isSelected ? KolaDashboardColors.accent : KolaDashboardColors.border}',
      },
      events: {'click': (_) => setState(() => _selectedGateway[workspaceId] = value)},
      [Component.text(label)],
    );
  }

  Component _usageStat(String label, int used, int? cap) {
    final ratio = cap != null && cap > 0 ? (used / cap).clamp(0, 1).toDouble() : null;
    return div(
      attributes: {'style': 'flex:1;min-width:160px'},
      [
        div(
          attributes: {'style': 'font-size:12px;color:${KolaDashboardColors.mutedSecondary};margin-bottom:5px'},
          [Component.text(label)],
        ),
        div(
          attributes: {'style': 'font-size:15px;font-weight:600;margin-bottom:6px'},
          [Component.text(cap != null ? '$used / $cap' : '$used')],
        ),
        if (ratio != null)
          div(
            attributes: {
              'style': 'height:5px;border-radius:3px;background:${KolaDashboardColors.pill};overflow:hidden',
            },
            [
              div(
                attributes: {
                  'style':
                      'height:100%;width:${(ratio * 100).toStringAsFixed(0)}%;'
                      'background:${ratio >= 1 ? '#D97D6B' : KolaDashboardColors.accent}',
                },
                [],
              ),
            ],
          ),
      ],
    );
  }
}
