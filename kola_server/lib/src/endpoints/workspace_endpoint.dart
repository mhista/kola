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
import 'package:kola_server/src/services/repository/owner_notification_settings_repository.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/usage_record_repository.dart';
import 'package:kola_server/src/services/features/feature_keys.dart';
import 'package:kola_server/src/services/features/feature_flag_service.dart';
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
  FeatureFlagService get _features => getIt<FeatureFlagService>();

  /// Seeded at creation from the wizard's phone field — see
  /// createWorkspace on why the number lives here and not on the
  /// workspace row.
  OwnerNotificationSettingsRepository get _notificationSettings =>
      getIt<OwnerNotificationSettingsRepository>();
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
  ///
  /// [ownerName] and [ownerPhone] come from step 2 of
  /// Kola Create Workspace.dc.html. They were previously not accepted at
  /// all — the wizard asked for both and the server discarded them, which
  /// is worse than not asking.
  ///
  /// Both are optional so the endpoint stays callable from anywhere that
  /// only has a business name, and so an owner who skips step 2 still
  /// gets a workspace.
  /// [industryTag] STAYS POSITIONAL. It was tempting to move it into the
  /// named group with the two new fields, and doing so broke
  /// kymaa_dashboard — the frozen competition entry, which is a pub
  /// workspace member resolving this same generated client and calls
  /// this with three positional arguments.
  ///
  /// A frozen package is frozen: it does not get edited to accommodate a
  /// signature change that had no reason to be breaking. Adding the new
  /// fields as NAMED and optional keeps every existing call valid.
  Future<Workspace> createWorkspace(
    Session session,
    String accessToken,
    String name,
    String? industryTag, {
    String? ownerName,
    String? ownerPhone,
  }) async {
    final verified = await _sessionVerifier.verify(accessToken);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Give your business a name to continue.');
    }

    final workspace = await _workspaces.create(
      name: trimmedName,
      industryTag: industryTag,
      ownerName: ownerName?.trim().isEmpty ?? true ? null : ownerName!.trim(),
    );

    await _members.addMember(
      workspaceId: workspace.id!,
      userId: verified.userId,
      role: 'owner',
    );

    // THE PHONE NUMBER DOES SOMETHING, IMMEDIATELY.
    //
    // Seeded straight into owner_notification_settings rather than stored
    // on the workspace, so escalation alerts reach the owner from the
    // moment the workspace exists — instead of after a settings visit
    // they do not know to make.
    //
    // It is also why there is no workspaces.owner_phone column: a second
    // copy of this fact would drift the first time the owner changed
    // their number here, leaving kola messaging a stale one.
    //
    // whatsappEnabled follows the number: a phone captured in the wizard
    // is consent to be messaged on it — that is what the field is asking
    // for — but an EMPTY number must not enable a channel with nowhere to
    // send.
    final phone = ownerPhone?.trim();
    if (phone != null && phone.isNotEmpty) {
      // Never fails the creation. A workspace that exists without
      // notification settings is recoverable; a wizard that dies on the
      // last step and leaves the owner unsure whether their business was
      // created is not.
      try {
        await _notificationSettings.upsert(
          workspaceId: workspace.id!,
          ownerWhatsappNumber: phone,
          whatsappEnabled: true,
          ownerEmail: verified.email,
          emailEnabled: verified.email != null,
        );
      } catch (e) {
        Log.warning(
          'Workspace created but notification settings could not be seeded',
          data: {'workspaceId': workspace.id, 'error': '$e'},
          session: session,
        );
      }
    }

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
      throw KolaException(message: 'Workspace $workspaceId not found');
    }
    return workspace;
  }

  /// Edits the three fields the create-workspace wizard collected.
  ///
  /// ── WHY THIS EXISTS ──────────────────────────────────────────────
  ///
  /// The wizard asked for a business name, what the business sells, and
  /// the owner's name — and there was no way to change any of them
  /// afterwards. Kola Settings.dc.html has a Workspaces section that
  /// edits them; without this endpoint that section could only display.
  ///
  /// It also unblocks the Overview's day-one card, whose completed
  /// "Create your workspace" step is supposed to offer Edit.
  ///
  /// ── WHAT IT DELIBERATELY WILL NOT TOUCH ──────────────────────────
  ///
  /// plan, status, trial dates, region, isInternal. Those are decided by
  /// billing, by the trial state machine, and by admin — never by the
  /// owner editing a form. WorkspaceRepository.update writes whatever
  /// model it is handed, so this reads the CURRENT row and copies only
  /// the permitted fields onto it (name, industryTag, ownerName, and —
  /// Gate 7 — sellsCatalogItems). Passing a client-supplied Workspace
  /// straight through would let anyone with a session set their own plan
  /// to enterprise.
  ///
  /// ── NULL MEANS "LEAVE IT" ────────────────────────────────────────
  ///
  /// Every parameter is optional and null means unchanged, so the
  /// dashboard can save one field without having to send the others
  /// back correctly. To CLEAR industryTag, send an empty string — that
  /// is distinguishable from null and is normalised to null below.
  Future<Workspace> updateWorkspace(
    Session session,
    String accessToken,
    int workspaceId, {
    String? name,
    String? industryTag,
    String? ownerName,
    // Gate 7 (migration 045). A real bool, not the text fields' "empty
    // string clears it" convention — there is no product need to reset
    // this back to "never asked" once an owner has answered, so null
    // simply means "leave it," same as every other optional param here.
    bool? sellsCatalogItems,
    // Phase 11 (migration 057). Same "real bool, null means leave it"
    // shape as sellsCatalogItems above. Turning it ON is checked against
    // FeatureKeys.commercePublicCatalog below — turning it OFF never
    // needs the flag, an owner can always take their own catalog back
    // down regardless of release state.
    bool? publicCatalogEnabled,
    // Phase 11 (migration 058). Same "real bool, gated on ON, never on
    // OFF" shape as publicCatalogEnabled just above.
    bool? customerDisplayEnabled,
  }) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final current = await _workspaces.findById(workspaceId);
    if (current == null) {
      throw KolaException(message: 'Workspace $workspaceId not found');
    }

    if (name != null) {
      final trimmed = name.trim();
      // A workspace with a blank name renders as an empty sidebar and an
      // avatar with no initial. Refused rather than silently kept,
      // because the owner needs to know the save did not take.
      if (trimmed.isEmpty) {
        throw KolaException(message: 'Your business needs a name.');
      }
      current.name = trimmed;
    }
    if (industryTag != null) {
      final trimmed = industryTag.trim();
      current.industryTag = trimmed.isEmpty ? null : trimmed;
    }
    if (ownerName != null) {
      final trimmed = ownerName.trim();
      current.ownerName = trimmed.isEmpty ? null : trimmed;
    }
    if (sellsCatalogItems != null) {
      current.sellsCatalogItems = sellsCatalogItems;
    }
    if (publicCatalogEnabled != null) {
      if (publicCatalogEnabled &&
          !await _features.isEnabled(FeatureKeys.commercePublicCatalog, current)) {
        throw KolaException(
          message:           'The public catalog page is not available on this workspace yet.',
        );
      }
      current.publicCatalogEnabled = publicCatalogEnabled;
    }
    if (customerDisplayEnabled != null) {
      if (customerDisplayEnabled &&
          !await _features.isEnabled(FeatureKeys.commerceCustomerDisplay, current)) {
        throw KolaException(
          message:           'The in-store customer display is not available on this workspace yet.',
        );
      }
      current.customerDisplayEnabled = customerDisplayEnabled;
    }

    return _workspaces.update(current);
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
      throw KolaException(message: 'Workspace $workspaceId not found');
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
      throw KolaException(message: 'An email address is required to start checkout.');
    }

    // The workspace's own region decides the price, currency and
    // collecting gateway — the client never supplies an amount, and the
    // region is read from the record rather than accepted as input.
    // See plan_pricing.dart.
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw KolaException(message: 'Workspace $workspaceId not found.');
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
