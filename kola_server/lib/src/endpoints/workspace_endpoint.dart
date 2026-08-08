// workspace_endpoint.dart
//
// The first real endpoint in the project — deliberately kept to exactly
// the three operations Phase 1 needs to prove the whole stack end to end:
// create a workspace, list the workspaces a signed-in user belongs to,
// and fetch one specific workspace (access-checked). Everything else
// (renaming a workspace, changing plan, member management UI) is real
// Phase 1c/1d follow-on work, not blocking proof that auth + persistence
// + multi-tenancy are wired correctly together.
//
// NOTE ON accessToken PARAMETERS: see workspace_access.dart's header
// comment for why the Supabase access token is a plain method parameter
// rather than an implicit header.

import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/session_verifier.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/repository/workspace_member_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/usage_record_repository.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/billing/stripe_service.dart';
import 'package:kola_server/src/services/billing/plan_pricing.dart';
import 'package:kola_server/src/services/billing/kola_billing_service.dart';
import 'package:kola_server/kola_logger.dart';

class WorkspaceEndpoint extends Endpoint {
  static const _sessionVerifier = SessionVerifier();
  static const _trialStateMachine = TrialStateMachine();

  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  WorkspaceMemberRepository get _members => getIt<WorkspaceMemberRepository>();
  ErrandRepository get _errands => getIt<ErrandRepository>();
  UsageRecordRepository get _usageRecords => getIt<UsageRecordRepository>();
  KolaBillingService get _billing => getIt<KolaBillingService>();

  /// Creates a new workspace and makes the caller its 'owner'. This is the
  /// very first authenticated write path in the product — the moment
  /// signup actually becomes "a business now has a home on Kola."
  ///
  /// Deliberately does NOT go through requireWorkspaceAccess — there's no
  /// workspace to check membership against yet. Only session verification
  /// (proving accessToken is a genuine, current Supabase session) applies.
  Future<Workspace> createWorkspace(
    Session session,
    String accessToken,
    String name,
    String? industryTag,
  ) async {
    final verified = await _sessionVerifier.verify(accessToken);

    final workspace = await _workspaces.create(
      name: name,
      industryTag: industryTag,
    );

    await _members.addMember(
      workspaceId: workspace.id!,
      userId: verified.userId,
      role: 'owner',
    );

    Log.success(
      'Workspace created',
      data: {'workspaceId': workspace.id, 'ownerUserId': verified.userId},
      session: session,
    );

    return workspace;
  }

  /// Every workspace the caller belongs to, for the dashboard's workspace
  /// switcher (relevant now for a user with zero or one workspace, and
  /// unchanged when the agency/multi-workspace tier adds more).
  Future<List<Workspace>> listMyWorkspaces(
    Session session,
    String accessToken,
  ) async {
    final verified = await _sessionVerifier.verify(accessToken);
    final memberships = await _members.listByUser(verified.userId);

    // N+1-shaped on purpose for Phase 1 — a business owner has one or two
    // workspaces at most; a batched "get workspaces by id list" repository
    // method is a straightforward follow-up once the agency tier makes
    // this list routinely longer.
    final workspaces = <Workspace>[];
    for (final membership in memberships) {
      final workspace = await _workspaces.findById(membership.workspaceId);
      if (workspace != null) workspaces.add(workspace);
    }
    return workspaces;
  }

  /// Fetch one workspace by id — access-checked, so a user can never read
  /// a workspace they're not a member of by guessing an id.
  Future<Workspace> getWorkspace(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found');
    }
    return workspace;
  }

  /// Task #139/#8d — a workspace's plan/trial standing plus its current
  /// usage against PlanLimits, as one JSON string. Fills two gaps at
  /// once: the dashboard's "Billing" nav item had nothing real to show
  /// (Subscription — subscription.spy.yaml — stays null until Phase 5c's
  /// gateway integration is actually switched on for a real charge, so
  /// it's the wrong source for "what can this workspace do right now";
  /// Workspace.plan/.status/.trial* + TrialStateMachine.effectiveTier
  /// already ARE that source, same as every enforcement check reads),
  /// and Phase 8d's still-flagged "cross-workspace billing/summary view"
  /// (DEVELOPMENT_PLAN.md §8d) — kola_dashboard's BillingPage calls this
  /// once per workspace the caller belongs to and renders one row each
  /// when there's more than one, the same "only show switcher chrome
  /// when it's earned" posture as SidebarNav's workspace switcher
  /// (task #131).
  ///
  /// JSON STRING, NOT A NEW MODEL: same "flexible shape lives in a JSON
  /// string" pattern already used for Errand.inputSchemaJson and
  /// executeErrandNow's result — avoids a new .spy.yaml + a Serverpod
  /// codegen run just to shuttle a handful of numbers to the dashboard.
  /// Shape:
  ///   { plan, status, effectiveTier,
  ///     trialFullAccessEndsAt, trialEndsAt (null unless 'trialing'),
  ///     messagesToday, messagesDailyCap (null unless capped),
  ///     activeErrandCount, errandCap (null unless capped),
  ///     messagesThisMonth, errandCallsThisMonth }
  Future<String> getBillingSummary(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found');
    }

    final tier = _trialStateMachine.effectiveTier(workspace);
    final isCapped = tier == EffectiveTier.cappedFree || tier == EffectiveTier.paused;

    final now = DateTime.now().toUtc();
    final firstOfMonth = DateTime.utc(now.year, now.month, 1);

    final messagesToday = await _usageRecords.sumUsageInRange(
      workspaceId: workspaceId,
      usageClass: 'message',
      from: now,
      to: now,
    );
    final messagesThisMonth = await _usageRecords.sumUsageInRange(
      workspaceId: workspaceId,
      usageClass: 'message',
      from: firstOfMonth,
      to: now,
    );
    final errandCallsThisMonth = await _usageRecords.sumUsageInRange(
      workspaceId: workspaceId,
      usageClass: 'errandCall',
      from: firstOfMonth,
      to: now,
    );
    final activeErrandCount = (await _errands.listActiveByWorkspace(workspaceId)).length;

    // Price, currency and collecting gateway all come from the
    // workspace's own region — see plan_pricing.dart.
    final regionalPrice = PlanPricing.forRegion(workspace.region);

    return jsonEncode({
      'workspaceId': workspaceId,
      'workspaceName': workspace.name,
      'plan': workspace.plan,
      'status': workspace.status,
      'effectiveTier': tier.name,
      'trialFullAccessEndsAt': workspace.status == 'trialing' ? workspace.trialFullAccessEndsAt.toIso8601String() : null,
      'trialEndsAt': workspace.status == 'trialing' ? workspace.trialEndsAt.toIso8601String() : null,
      'messagesToday': messagesToday,
      'messagesDailyCap': isCapped ? PlanLimits.cappedFreeDailyMessageCap : null,
      'activeErrandCount': activeErrandCount,
      'errandCap': isCapped ? PlanLimits.cappedFreeErrandCap : null,
      'messagesThisMonth': messagesThisMonth,
      'errandCallsThisMonth': errandCallsThisMonth,
      // The dashboard's "Upgrade" card renders from these — it never
      // hardcodes a price, and never assumes a currency.
      //
      // REGIONAL, not the old flat naira figure. Returning that to a
      // workspace outside Nigeria would show one number and charge
      // another, which reads as deception rather than a bug. The amount
      // is in the currency's SMALLEST unit; `priceCurrency` is what makes
      // it interpretable, and `priceMinorUnitDigits` is what stops the
      // dashboard dividing by 100 for a currency that has no minor unit
      // (JPY, KRW, XOF — see StripeService.zeroDecimalCurrencies).
      'paidPlanPriceMinor': regionalPrice.amountMinor,
      'priceCurrency': regionalPrice.currency,
      'priceMinorUnitDigits':
          StripeService.isZeroDecimal(regionalPrice.currency) ? 0 : 2,
      'billingGateway': regionalPrice.gateway,
      // Retained for older dashboard builds that still read it. Correct
      // only for Nigeria; new code must use the fields above.
      'paidPlanMonthlyPriceKobo': PlanLimits.paidPlanMonthlyPriceKobo,
    });
  }

  /// Task #148 — starts a checkout for [workspaceId] to upgrade to
  /// Kola's paid ('pro') plan, using KOLA'S OWN Paystack/Flutterwave
  /// account (see KolaBillingService's header for why this is a
  /// separate flow from PaymentEndpoint.initializeCheckout, which is a
  /// workspace collecting from ITS OWN customers). [customerEmail] is
  /// the signed-in dashboard user's email — the gateway needs an email
  /// on file for the checkout page/receipt regardless of who's paying.
  Future<KolaBillingCheckout> initiateUpgrade(
    Session session,
    String accessToken,
    int workspaceId,
    String gateway,
    String customerEmail,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final trimmedEmail = customerEmail.trim();
    if (trimmedEmail.isEmpty) {
      throw Exception('An email address is required to start checkout.');
    }

    // The workspace's own region decides the price, currency and
    // collecting gateway — the client never supplies an amount, and the
    // region is read from the record rather than accepted as input.
    // See plan_pricing.dart.
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw Exception('Workspace $workspaceId not found.');
    }

    final checkout = await _billing.initiateUpgrade(
      workspaceId: workspaceId,
      gateway: gateway,
      customerEmail: trimmedEmail,
      region: workspace.region,
    );

    Log.success('Kola subscription checkout initiated', data: {
      'workspaceId': workspaceId,
      'gateway': gateway,
    }, session: session);

    return checkout;
  }
}
