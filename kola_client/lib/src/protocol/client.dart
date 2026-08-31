/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:kola_client/src/protocol/conversation.dart' as _i3;
import 'package:kola_client/src/protocol/knowledge_document.dart' as _i4;
import 'package:kola_client/src/protocol/message.dart' as _i5;
import 'package:kola_client/src/protocol/errand.dart' as _i6;
import 'package:kola_client/src/protocol/feature_flag.dart' as _i7;
import 'package:kola_client/src/protocol/workspace_feature_override.dart'
    as _i8;
import 'package:kola_client/src/protocol/support_ticket.dart' as _i9;
import 'package:kola_client/src/protocol/workspace.dart' as _i10;
import 'package:kola_client/src/protocol/bot.dart' as _i11;
import 'package:kola_client/src/protocol/channel.dart' as _i12;
import 'package:kola_client/src/protocol/analytics_summary.dart' as _i13;
import 'package:kola_client/src/protocol/broadcast.dart' as _i14;
import 'package:kola_client/src/protocol/broadcast_progress.dart' as _i15;
import 'package:kola_client/src/protocol/message_suppression.dart' as _i16;
import 'package:kola_client/src/protocol/connector_status.dart' as _i17;
import 'package:kola_client/src/protocol/google_drive_spreadsheet.dart' as _i18;
import 'package:kola_client/src/protocol/calendar_booking.dart' as _i19;
import 'package:kola_client/src/protocol/customer.dart' as _i20;
import 'package:kola_client/src/protocol/customer_summary.dart' as _i21;
import 'package:kola_client/src/protocol/customer_detail.dart' as _i22;
import 'package:kola_client/src/protocol/customer_merge_proposal.dart' as _i23;
import 'package:kola_client/src/protocol/customer_profile.dart' as _i24;
import 'package:kola_client/src/protocol/errand_execution_log.dart' as _i25;
import 'package:kola_client/src/protocol/workspace_finding.dart' as _i26;
import 'package:kola_client/src/protocol/invoice.dart' as _i27;
import 'package:kola_client/src/protocol/knowledge_search_hit.dart' as _i28;
import 'package:kola_client/src/protocol/workspace_answer.dart' as _i29;
import 'package:kola_client/src/protocol/owner_notification_settings.dart'
    as _i30;
import 'package:kola_client/src/protocol/payment_gateway_credential.dart'
    as _i31;
import 'package:kola_client/src/protocol/payment_transaction.dart' as _i32;
import 'package:kola_client/src/protocol/api_key.dart' as _i33;
import 'package:kola_client/src/protocol/created_api_key.dart' as _i34;
import 'package:kola_client/src/protocol/webhook_endpoint.dart' as _i35;
import 'package:kola_client/src/protocol/product.dart' as _i36;
import 'package:kola_client/src/protocol/product_variant.dart' as _i37;
import 'package:kola_client/src/protocol/public_catalog.dart' as _i38;
import 'package:kola_client/src/protocol/product_media.dart' as _i39;
import 'package:kola_client/src/protocol/end_of_day_report.dart' as _i40;
import 'package:kola_client/src/protocol/sale.dart' as _i41;
import 'package:kola_client/src/protocol/sale_line.dart' as _i42;
import 'package:kola_client/src/protocol/task.dart' as _i43;
import 'package:kola_client/src/protocol/till_display_state.dart' as _i44;
import 'package:kola_client/src/protocol/waitlist_signup.dart' as _i45;
import 'package:kola_client/src/protocol/whatsapp_message_template.dart'
    as _i46;
import 'package:kola_client/src/protocol/kola_billing_checkout.dart' as _i47;
import 'protocol.dart' as _i48;

/// {@category Endpoint}
class EndpointAdminAccounts extends _i1.EndpointRef {
  EndpointAdminAccounts(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminAccounts';

  /// "id|email|level|active|mustResetPassword|lastSeenAt" lines — see file
  /// header on why this is a formatted list rather than a new wire type;
  /// AdminUser itself is a plain internal class here too (not generated
  /// for RPC, same posture as AdminAuditLogEntry).
  _i2.Future<List<String>> listAdmins(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminAccounts',
        'listAdmins',
        {'adminToken': adminToken},
      );

  _i2.Future<String> setActive(
    String adminToken,
    int accountId,
    bool active,
    String note,
  ) => caller.callServerEndpoint<String>(
    'adminAccounts',
    'setActive',
    {
      'adminToken': adminToken,
      'accountId': accountId,
      'active': active,
      'note': note,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminAnnouncement extends _i1.EndpointRef {
  EndpointAdminAnnouncement(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminAnnouncement';

  /// Resolves the audience and returns "id|name|plan" lines — the
  /// preview step the spec asks for, shown before send is enabled in the
  /// UI. Support level: read-only, no message goes out.
  _i2.Future<List<String>> previewAudience(
    String adminToken,
    String audience,
    String audienceValue,
  ) => caller.callServerEndpoint<List<String>>(
    'adminAnnouncement',
    'previewAudience',
    {
      'adminToken': adminToken,
      'audience': audience,
      'audienceValue': audienceValue,
    },
  );

  /// Sends [subject]/[body] to every workspace in the resolved audience
  /// via OwnerNotificationDispatcher.notify — same fan-out, same
  /// per-channel rate limiting, as any other owner notification. Returns
  /// "sentCount|totalCount". Operator level (see file header).
  _i2.Future<String> sendAnnouncement(
    String adminToken,
    String audience,
    String audienceValue,
    String subject,
    String body,
    String note,
  ) => caller.callServerEndpoint<String>(
    'adminAnnouncement',
    'sendAnnouncement',
    {
      'adminToken': adminToken,
      'audience': audience,
      'audienceValue': audienceValue,
      'subject': subject,
      'body': body,
      'note': note,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminAuditLog extends _i1.EndpointRef {
  EndpointAdminAuditLog(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminAuditLog';

  _i2.Future<List<String>> listRecent(
    String adminToken, {
    required int limit,
  }) => caller.callServerEndpoint<List<String>>(
    'adminAuditLog',
    'listRecent',
    {
      'adminToken': adminToken,
      'limit': limit,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminAuth extends _i1.EndpointRef {
  EndpointAdminAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminAuth';

  /// Verifies [email]/[password] and returns a signed admin session
  /// token (4-hour lifetime — see AdminAuthService's header) for use as
  /// the `adminToken` parameter on every other admin endpoint method.
  ///
  /// [totpCode] is only needed for an account with MFA enrolled — first
  /// call with it omitted; if the account requires MFA, this throws
  /// [KolaException] with code 'admin_mfa_required' rather than
  /// 'admin_login_failed', and kola_admin's login page prompts for a
  /// code and calls this again with the same email/password plus
  /// [totpCode] filled in. See AdminAuthService.login's header for the
  /// full two-step reasoning.
  ///
  /// Throws [KolaException] with code 'admin_login_failed' on any other
  /// failure — deliberately one generic message regardless of whether
  /// the email doesn't exist, the password is wrong, the account is
  /// deactivated, or (once past the MFA gate) the code was wrong.
  _i2.Future<String> login(
    String email,
    String password, {
    String? totpCode,
  }) => caller.callServerEndpoint<String>(
    'adminAuth',
    'login',
    {
      'email': email,
      'password': password,
      'totpCode': totpCode,
    },
  );

  /// Step 1 of MFA enrollment — generates a fresh TOTP secret and its
  /// otpauth:// URI, returned as "secretBase32|otpauthUri" (see this
  /// project's "avoid a new wire type when a formatted String is
  /// enough" precedent). Nothing is persisted by this call; see
  /// [confirmMfaEnrollment].
  _i2.Future<String> beginMfaEnrollment(String adminToken) =>
      caller.callServerEndpoint<String>(
        'adminAuth',
        'beginMfaEnrollment',
        {'adminToken': adminToken},
      );

  /// Step 2 — proves the admin's authenticator app actually produced a
  /// valid code for [secretBase32] before it becomes the account's real
  /// MFA secret. Throws [KolaException] with code 'admin_mfa_confirm_failed'
  /// if the code doesn't match.
  _i2.Future<void> confirmMfaEnrollment(
    String adminToken,
    String secretBase32,
    String code,
  ) => caller.callServerEndpoint<void>(
    'adminAuth',
    'confirmMfaEnrollment',
    {
      'adminToken': adminToken,
      'secretBase32': secretBase32,
      'code': code,
    },
  );

  /// Disables MFA on the caller's own account — requires the current
  /// password, same posture as [changePassword]. Throws [KolaException]
  /// with code 'admin_mfa_disable_failed' on a wrong password.
  _i2.Future<void> disableMfa(
    String adminToken,
    String currentPassword,
  ) => caller.callServerEndpoint<void>(
    'adminAuth',
    'disableMfa',
    {
      'adminToken': adminToken,
      'currentPassword': currentPassword,
    },
  );

  /// Whether the caller must change their password before doing anything
  /// else — kola_admin calls this immediately after login and, if true,
  /// blocks every other route behind the forced reset screen. Backed by
  /// AdminSession.mustResetPassword, which is read live off the account
  /// row on every call — see admin_auth_service.dart's verify().
  _i2.Future<bool> mustResetPassword(String adminToken) =>
      caller.callServerEndpoint<bool>(
        'adminAuth',
        'mustResetPassword',
        {'adminToken': adminToken},
      );

  /// Whether the caller's account currently has MFA enrolled — read
  /// live, same staleness posture as [mustResetPassword]. kola_admin's
  /// security page uses this to show "enable" vs. "disable" MFA.
  _i2.Future<bool> mfaEnabled(String adminToken) =>
      caller.callServerEndpoint<bool>(
        'adminAuth',
        'mfaEnabled',
        {'adminToken': adminToken},
      );

  /// Changes the caller's own password. Requires the CURRENT password —
  /// see AdminAuthService.changePassword's header for why that holds
  /// even during a forced first-login reset. This is the only method
  /// that ever clears must_reset_password.
  ///
  /// Throws [KolaException] with code 'admin_password_change_failed' on
  /// any validation failure (wrong current password, new password too
  /// short, new password same as current, or an inactive account).
  _i2.Future<void> changePassword(
    String adminToken,
    String currentPassword,
    String newPassword,
  ) => caller.callServerEndpoint<void>(
    'adminAuth',
    'changePassword',
    {
      'adminToken': adminToken,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminDiagnostics extends _i1.EndpointRef {
  EndpointAdminDiagnostics(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminDiagnostics';

  /// One "CHECK|STATUS|detail" line per diagnostic — see this file's
  /// header for exactly what each STATUS (OK/FAIL/WARN/UNKNOWN) means
  /// per check. Support level: read-only.
  _i2.Future<List<String>> diagnoseWorkspace(
    String adminToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<String>>(
    'adminDiagnostics',
    'diagnoseWorkspace',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
    },
  );

  /// Most recent conversations for a workspace — the spec's "conversation
  /// lookup," audited because conversation content is customer data.
  _i2.Future<List<_i3.Conversation>> listRecentConversations(
    String adminToken,
    int workspaceId, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i3.Conversation>>(
    'adminDiagnostics',
    'listRecentConversations',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'limit': limit,
    },
  );

  /// The spec's "recent errors" surface, deliberately narrowed to what's
  /// actually queryable: failed knowledge documents (a real, persisted
  /// error with a stored message). There is no general per-workspace
  /// error log to draw from — see this file's header.
  _i2.Future<List<_i4.KnowledgeDocument>> listFailedKnowledgeDocuments(
    String adminToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i4.KnowledgeDocument>>(
    'adminDiagnostics',
    'listFailedKnowledgeDocuments',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
    },
  );

  /// Re-runs ingestion for a failed document's original stored text.
  /// NOTE: this creates a NEW document row rather than mutating the
  /// failed one in place (IngestionResult/ingestText's contract doesn't
  /// support an in-place retry) — the failed row is left as-is, a
  /// historical record of the earlier failure. Operator level: this
  /// re-runs a real embedding call, a cost/quota-consuming action, not a
  /// read.
  _i2.Future<String> reindexDocument(
    String adminToken,
    int workspaceId,
    int documentId,
    String note,
  ) => caller.callServerEndpoint<String>(
    'adminDiagnostics',
    'reindexDocument',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'documentId': documentId,
      'note': note,
    },
  );

  /// Resends a generic owner notification through the existing
  /// OwnerNotificationDispatcher fan-out (the spec's "resend a failed
  /// notification") — every enabled+configured+rate-limit-cleared
  /// channel gets the attempt again, same as any other notify() call.
  /// Operator level: this sends a real message to a real customer-facing
  /// owner, not a read.
  _i2.Future<String> resendNotification(
    String adminToken,
    int workspaceId,
    String subject,
    String body,
    String note,
  ) => caller.callServerEndpoint<String>(
    'adminDiagnostics',
    'resendNotification',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'subject': subject,
      'body': body,
      'note': note,
    },
  );

  /// Full message thread for one conversation — the "workspace
  /// inspection" substitute for literal customer-session impersonation
  /// (see docs/ADMIN_CONTROL_PLANE_STATUS.md's "Workspace inspection"
  /// section for why real session-forging was deliberately not built
  /// here: it's an account-takeover-shaped capability that needs its
  /// own dedicated session-issuance design, audit shape, and time-limit
  /// mechanism, the same reasoning already stated on
  /// AdminWorkspaceEndpoint — not something to improvise as a rider on
  /// this endpoint). This gives an admin the actual diagnostic value
  /// the spec wanted ("why isn't my bot replying") — reading exactly
  /// what the customer and the bot said to each other — without ever
  /// issuing a customer-facing credential.
  ///
  /// [conversationId] is scoped to [workspaceId] via
  /// ConversationRepository.findByIdScoped so an admin operating on one
  /// workspace's page can't be handed another workspace's messages by
  /// guessing an id. Read-only; audited because message content is
  /// customer data (same discipline as [listRecentConversations]).
  _i2.Future<List<_i5.Message>> getConversationMessages(
    String adminToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<List<_i5.Message>>(
    'adminDiagnostics',
    'getConversationMessages',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );

  /// The other half of workspace inspection: what is this bot actually
  /// configured to do. Read-only reference (name, source, handler key,
  /// permission scope, status) — not customer conversation content, so
  /// no audit log entry, same reasoning as [listFailedKnowledgeDocuments]
  /// staying unaudited.
  _i2.Future<List<_i6.Errand>> listErrandsForWorkspace(
    String adminToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i6.Errand>>(
    'adminDiagnostics',
    'listErrandsForWorkspace',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminFeature extends _i1.EndpointRef {
  EndpointAdminFeature(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminFeature';

  /// Every flag, raw platform state — NOT resolved per-workspace (that's
  /// FeatureFlagService.isEnabled's job, for the customer-facing side).
  /// Support level and above: read-only, safe for anyone with admin
  /// access at all.
  _i2.Future<List<_i7.FeatureFlag>> listFlags(String adminToken) =>
      caller.callServerEndpoint<List<_i7.FeatureFlag>>(
        'adminFeature',
        'listFlags',
        {'adminToken': adminToken},
      );

  /// The reconciliation banner's two halves — see FeatureFlagService
  /// .reconcile()'s own doc comment on why drift in either direction
  /// matters. Split into two methods rather than one record-returning
  /// method: Serverpod's RPC layer serializes declared model types and
  /// primitives cleanly; a bare Dart record is neither, so this avoids
  /// needing a new wire type for a two-list result.
  _i2.Future<List<String>> listMissingFeatureKeys(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminFeature',
        'listMissingFeatureKeys',
        {'adminToken': adminToken},
      );

  _i2.Future<List<String>> listOrphanedFeatureKeys(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminFeature',
        'listOrphanedFeatureKeys',
        {'adminToken': adminToken},
      );

  /// Moves one feature between states. `released` requires Owner; every
  /// other transition — including the kill switch, any state → `locked`
  /// — requires only Operator, per ADMIN_APP_SPEC.md §2/§3.1: "the
  /// ability to stop something breaking must never be gated behind
  /// finding a specific person at 2am."
  ///
  /// [note] is required for the audit trail, same "no unexplained
  /// change" posture WorkspaceFeatureOverride.note already enforces at
  /// the schema level for overrides — this table has no such column, so
  /// the check is here instead.
  _i2.Future<_i7.FeatureFlag> setFeatureState(
    String adminToken,
    String key,
    String newState,
    String note,
  ) => caller.callServerEndpoint<_i7.FeatureFlag>(
    'adminFeature',
    'setFeatureState',
    {
      'adminToken': adminToken,
      'key': key,
      'newState': newState,
      'note': note,
    },
  );

  /// Flips every not-yet-released, not-externally-gated flag in [wave]
  /// (e.g. 'R2') to `released`, in one audited action — "with a
  /// confirmation listing every feature it contains" is the dashboard's
  /// job (§3.1); this method is what it calls after that confirmation.
  /// Owner-only, same as any individual `released` transition, since a
  /// wave release affects every customer at once same as one flag does
  /// — just more of them in one motion.
  _i2.Future<List<_i7.FeatureFlag>> releaseWave(
    String adminToken,
    String wave,
    String note,
  ) => caller.callServerEndpoint<List<_i7.FeatureFlag>>(
    'adminFeature',
    'releaseWave',
    {
      'adminToken': adminToken,
      'wave': wave,
      'note': note,
    },
  );

  /// Grants (enabled=true, the beta/design-partner mechanism) or revokes
  /// access (enabled=false, the per-workspace kill switch) for one
  /// workspace on one feature. Operator level — this is exactly the
  /// "grant/revoke beta overrides" capability ADMIN_APP_SPEC.md §2's
  /// table lists for Operator, not Owner.
  _i2.Future<_i8.WorkspaceFeatureOverride> setOverride(
    String adminToken,
    int workspaceId,
    String featureKey,
    bool enabled,
    String note,
  ) => caller.callServerEndpoint<_i8.WorkspaceFeatureOverride>(
    'adminFeature',
    'setOverride',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
      'enabled': enabled,
      'note': note,
    },
  );

  /// Removes an override entirely, returning the workspace to whatever
  /// the platform-wide state says — distinct from setOverride(enabled:
  /// false), which is an active decision to keep a feature off for this
  /// workspace even after general release. See
  /// WorkspaceFeatureOverrideRepository.remove's own doc comment.
  _i2.Future<void> removeOverride(
    String adminToken,
    int workspaceId,
    String featureKey,
  ) => caller.callServerEndpoint<void>(
    'adminFeature',
    'removeOverride',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
    },
  );

  /// "Who is in this beta?" — every workspace with an override for one
  /// feature. Support level: read-only.
  _i2.Future<List<_i8.WorkspaceFeatureOverride>> listOverridesForFeature(
    String adminToken,
    String featureKey,
  ) => caller.callServerEndpoint<List<_i8.WorkspaceFeatureOverride>>(
    'adminFeature',
    'listOverridesForFeature',
    {
      'adminToken': adminToken,
      'featureKey': featureKey,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminOverview extends _i1.EndpointRef {
  EndpointAdminOverview(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminOverview';

  /// "key|value" lines: workspace counts by status, open ticket count,
  /// sweep job pass/fail counts since last restart, AI providers
  /// configured, embedding availability. One call, everything the
  /// landing page needs.
  _i2.Future<List<String>> getSummary(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminOverview',
        'getSummary',
        {'adminToken': adminToken},
      );

  /// The 5 most recent audit log entries, same formatted-line shape as
  /// AdminAuditLogEndpoint.listRecent, just pre-limited for a compact
  /// landing-page widget rather than the full log page.
  _i2.Future<List<String>> getRecentActivity(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminOverview',
        'getRecentActivity',
        {'adminToken': adminToken},
      );
}

/// {@category Endpoint}
class EndpointAdminPlatform extends _i1.EndpointRef {
  EndpointAdminPlatform(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminPlatform';

  /// One formatted "jobName|lastRunAtIso|ok|summary" line per sweep job
  /// that has run at least once since this process started. A job
  /// missing from the list means it hasn't ticked yet since boot (or the
  /// process just restarted) — not that it's broken; kola_admin's page
  /// shows that distinction in its own copy.
  _i2.Future<List<String>> listSweepJobStatuses(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminPlatform',
        'listSweepJobStatuses',
        {'adminToken': adminToken},
      );

  /// One "providerName|configured" line per AI provider in cascade
  /// order. See [AiOrchestrator.providerConfigStatus]'s header on why
  /// this is a key-presence check, not a live ping.
  _i2.Future<List<String>> listAiProviderStatus(String adminToken) =>
      caller.callServerEndpoint<List<String>>(
        'adminPlatform',
        'listAiProviderStatus',
        {'adminToken': adminToken},
      );

  /// Embedding subsystem status. The daily-cap figure (1500) is Gemini's
  /// own published free-tier limit for the embedding model this project
  /// uses — a real, documented number — NOT a live "requests used today"
  /// counter, because no such counter is tracked anywhere in
  /// EmbeddingOrchestrator or its providers today. Stated as a static
  /// cap alongside "usage not tracked" rather than showing a progress
  /// bar against a number that doesn't exist.
  _i2.Future<String> embeddingQuotaInfo(String adminToken) =>
      caller.callServerEndpoint<String>(
        'adminPlatform',
        'embeddingQuotaInfo',
        {'adminToken': adminToken},
      );
}

/// {@category Endpoint}
class EndpointAdminSupport extends _i1.EndpointRef {
  EndpointAdminSupport(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminSupport';

  _i2.Future<List<_i9.SupportTicket>> listOpenTickets(
    String adminToken, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i9.SupportTicket>>(
    'adminSupport',
    'listOpenTickets',
    {
      'adminToken': adminToken,
      'limit': limit,
    },
  );
}

/// {@category Endpoint}
class EndpointAdminWorkspace extends _i1.EndpointRef {
  EndpointAdminWorkspace(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminWorkspace';

  /// Search by name substring or exact numeric id — see
  /// WorkspaceRepository.search's header for what's NOT covered yet
  /// (owner email, phone number). Empty [query] returns the most
  /// recently created workspaces. Support level: read-only.
  _i2.Future<List<_i10.Workspace>> listWorkspaces(
    String adminToken, {
    String? query,
  }) => caller.callServerEndpoint<List<_i10.Workspace>>(
    'adminWorkspace',
    'listWorkspaces',
    {
      'adminToken': adminToken,
      'query': query,
    },
  );

  /// A single workspace's core record — plan, status, trial dates,
  /// isInternal. Support level: read-only.
  _i2.Future<_i10.Workspace?> getWorkspace(
    String adminToken,
    int workspaceId,
  ) => caller.callServerEndpoint<_i10.Workspace?>(
    'adminWorkspace',
    'getWorkspace',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
    },
  );

  /// Every bot in this workspace — part of §3.2's "per workspace: bots
  /// and their status." Support level: read-only.
  _i2.Future<List<_i11.Bot>> listBotsForWorkspace(
    String adminToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i11.Bot>>(
    'adminWorkspace',
    'listBotsForWorkspace',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
    },
  );

  /// Every channel connected to one bot — part of §3.2's "connected
  /// channels and health." Support level: read-only. Takes a bot id
  /// (not workspaceId) because Channel is scoped to Bot, not directly to
  /// Workspace — same shape ChannelRepository already uses everywhere
  /// else in this codebase.
  _i2.Future<List<_i12.Channel>> listChannelsForBot(
    String adminToken,
    int botId,
  ) => caller.callServerEndpoint<List<_i12.Channel>>(
    'adminWorkspace',
    'listChannelsForBot',
    {
      'adminToken': adminToken,
      'botId': botId,
    },
  );

  /// Changes plan only — see WorkspaceRepository.setPlan's header on why
  /// this is deliberately separate from setPlanAndStatus. Operator level
  /// ("change plans" per the spec's table).
  _i2.Future<_i10.Workspace> setPlan(
    String adminToken,
    int workspaceId,
    String plan,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'setPlan',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'plan': plan,
      'note': note,
    },
  );

  /// Pushes the trial window forward by [days] without changing status
  /// — see WorkspaceRepository.extendTrial's header. Support level
  /// ("extend a trial" per the spec's table — the one mutating action
  /// this table grants below Operator).
  _i2.Future<_i10.Workspace> extendTrial(
    String adminToken,
    int workspaceId,
    int days,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'extendTrial',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'days': days,
      'note': note,
    },
  );

  /// Full trial restart — see WorkspaceRepository.resetTrial's header on
  /// why this is a separate, more consequential action than extendTrial.
  /// Operator level.
  _i2.Future<_i10.Workspace> resetTrial(
    String adminToken,
    int workspaceId,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'resetTrial',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'note': note,
    },
  );

  /// Sets status to `paused` — §3.2's "suspend." Data is retained, the
  /// bot goes silent (WorkspaceRepository/status semantics unchanged
  /// from the existing trial-pause meaning of `paused`; this endpoint is
  /// just a second, admin-triggered path to the same status value).
  /// Operator level ("suspend a workspace" per the spec's table).
  _i2.Future<_i10.Workspace> suspend(
    String adminToken,
    int workspaceId,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'suspend',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'note': note,
    },
  );

  /// Reverses [suspend]. The target status is inferred rather than
  /// always forced to 'active': a workspace on the free plan goes back
  /// to 'trialing' (it was never paying — restoring it to 'active' would
  /// misrepresent it as a paid account), anything else goes to 'active'.
  /// Operator level, symmetric with suspend.
  _i2.Future<_i10.Workspace> reinstate(
    String adminToken,
    int workspaceId,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'reinstate',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'note': note,
    },
  );

  /// The ONLY admin-reachable path to `workspaces.is_internal` — see
  /// workspace.spy.yaml's field comment: no customer-facing endpoint can
  /// ever set this. Owner level — see this file's header for why this
  /// is held to the same bar as flipping a feature to `released`.
  _i2.Future<_i10.Workspace> setInternal(
    String adminToken,
    int workspaceId,
    bool isInternal,
    String note,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'adminWorkspace',
    'setInternal',
    {
      'adminToken': adminToken,
      'workspaceId': workspaceId,
      'isInternal': isInternal,
      'note': note,
    },
  );
}

/// {@category Endpoint}
class EndpointAnalytics extends _i1.EndpointRef {
  EndpointAnalytics(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'analytics';

  _i2.Future<_i13.AnalyticsSummary> getSummary(
    String accessToken,
    int workspaceId, {
    required int periodDays,
  }) => caller.callServerEndpoint<_i13.AnalyticsSummary>(
    'analytics',
    'getSummary',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'periodDays': periodDays,
    },
  );
}

/// {@category Endpoint}
class EndpointBot extends _i1.EndpointRef {
  EndpointBot(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'bot';

  /// Creates a new Bot inside a workspace, starting life as 'draft' (see
  /// bot_repository.dart's create() for the full lifecycle note). This is
  /// the step Bot Mother/the onboarding wizard calls right after
  /// WorkspaceEndpoint.createWorkspace — the resulting Bot.id is what
  /// every ChannelEndpoint method needs to connect a Telegram or
  /// WhatsApp channel to it.
  _i2.Future<_i11.Bot> createBot(
    String accessToken,
    int workspaceId,
    String name,
    String archetype,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'createBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'archetype': archetype,
    },
  );

  /// TASK #139 — the dashboard home page's composer ("What do you want
  /// kola to help with today?") calls this instead of [createBot] when
  /// a business just describes what they want in plain language rather
  /// than filling in CreateBotPage's name/archetype form directly. Uses
  /// [BotMotherService] to turn [description] into that same
  /// {name, archetype, knowledgeSeed} shape, then persists it through
  /// the EXACT SAME rules [createBot] already enforces (name can't be
  /// empty after drafting — can't happen given BotMotherService's own
  /// fallback naming, but checked anyway rather than trusting an AI
  /// service's output blindly) and the same starting 'draft' status.
  /// This is a drafting step layered on top of [createBot]'s existing
  /// contract, not a parallel bot-creation path with different rules.
  ///
  /// A REAL, BUT DELIBERATELY NARROW, SLICE OF "BOT MOTHER": full Bot
  /// Mother (DEVELOPMENT_PLAN.md §8c) means a whole WhatsApp/Telegram-
  /// native onboarding conversation — genuinely unscoped product work,
  /// still not started. This is the specific, concretely-scoped gap the
  /// composer already implied by sitting right above a "Create a new
  /// bot" quick action: describe it once here, get a real Bot back.
  _i2.Future<_i11.Bot> createBotFromDescription(
    String accessToken,
    int workspaceId,
    String description,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'createBotFromDescription',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'description': description,
    },
  );

  /// Every bot belonging to a workspace — the dashboard's bot list/
  /// switcher, and the prerequisite lookup before a Channels page can
  /// call ChannelEndpoint.listChannelsForBot for any one of them.
  _i2.Future<List<_i11.Bot>> listBotsForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i11.Bot>>(
    'bot',
    'listBotsForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Fetch one bot by id — access-checked via its workspace, same
  /// "never leak existence to a non-member" posture as
  /// WorkspaceEndpoint.getWorkspace and BotRepository.findByIdScoped.
  _i2.Future<_i11.Bot> getBot(
    String accessToken,
    int workspaceId,
    int botId,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'getBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
    },
  );

  /// Renames a bot and/or changes its archetype. Deliberately does NOT
  /// allow changing status through this method — status is a lifecycle
  /// transition driven by real events (a channel connecting via
  /// ChannelEndpoint, a workspace pausing on trial expiry), not a
  /// free-form field an owner edits directly. See
  /// bot_repository.dart's setStatus for where that actually happens.
  _i2.Future<_i11.Bot> updateBot(
    String accessToken,
    int workspaceId,
    int botId,
    String name,
    String archetype,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'updateBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'name': name,
      'archetype': archetype,
    },
  );

  /// Sets (or clears, by passing an empty string) the bot's minimal
  /// knowledge seed — see bot.spy.yaml's header on why this is a plain
  /// pasted-in text field, not real KnowledgeDocument retrieval. Kept as
  /// its own method rather than folded into updateBot for the same
  /// reason status has its own setStatus: this is a distinct, purposeful
  /// action ("teach the bot this"), not a generic field edit.
  ///
  /// Phase 5 plan limits: a cappedFree/paused workspace's knowledge seed
  /// is capped at PlanLimits.cappedFreeKnowledgeSeedCharCap characters —
  /// see that constant's own comment on why, unlike the message/Errand
  /// caps, this particular number is a placeholder, not a confirmed
  /// product decision.
  _i2.Future<_i11.Bot> setKnowledgeSeed(
    String accessToken,
    int workspaceId,
    int botId,
    String knowledgeSeed,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'setKnowledgeSeed',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'knowledgeSeed': knowledgeSeed,
    },
  );

  /// Sets (or clears, by passing an empty string) either or both of the
  /// cost-saving handoff fields — see bot.spy.yaml's header on why these
  /// exist and why a bot only ever mentions what's actually filled in
  /// here. Kept as its own method for the same reason [setKnowledgeSeed]
  /// is: a distinct, purposeful action, not a generic field edit folded
  /// into [updateBot].
  _i2.Future<_i11.Bot> setCostSavingContacts(
    String accessToken,
    int workspaceId,
    int botId,
    String telegramLink,
    String alternateWhatsapp,
  ) => caller.callServerEndpoint<_i11.Bot>(
    'bot',
    'setCostSavingContacts',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'telegramLink': telegramLink,
      'alternateWhatsapp': alternateWhatsapp,
    },
  );
}

/// {@category Endpoint}
class EndpointBroadcast extends _i1.EndpointRef {
  EndpointBroadcast(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'broadcast';

  /// Creates a broadcast in 'draft' status with every recipient row
  /// pre-loaded — nothing sends until [startBroadcast] flips it to
  /// 'running'. Recipients already suppressed for this workspace/
  /// platform are dropped here rather than being loaded and skipped
  /// later, so totalRecipients reflects who could actually be reached —
  /// live suppression added AFTER this call is still re-checked at send
  /// time by broadcast_sweep_service.dart, per spec.
  _i2.Future<_i14.Broadcast> createBroadcast(
    String accessToken,
    int workspaceId,
    String platform,
    String text,
    String recipientsJson,
    int? throughputPerMinute,
  ) => caller.callServerEndpoint<_i14.Broadcast>(
    'broadcast',
    'createBroadcast',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'platform': platform,
      'text': text,
      'recipientsJson': recipientsJson,
      'throughputPerMinute': throughputPerMinute,
    },
  );

  /// draft -> running. broadcast_sweep_service.dart's next tick (every
  /// [BroadcastSweepService.tickInterval]) picks it up from here — this
  /// method does not send anything itself.
  _i2.Future<_i14.Broadcast> startBroadcast(
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) => caller.callServerEndpoint<_i14.Broadcast>(
    'broadcast',
    'startBroadcast',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'broadcastId': broadcastId,
    },
  );

  /// Stops future sends. "There is no recall" — whatever already sent,
  /// sent; only 'queued' rows are affected, and they simply never get
  /// attempted (broadcast_sweep_service.dart only ever works
  /// 'running' broadcasts).
  _i2.Future<_i14.Broadcast> cancelBroadcast(
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) => caller.callServerEndpoint<_i14.Broadcast>(
    'broadcast',
    'cancelBroadcast',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'broadcastId': broadcastId,
    },
  );

  _i2.Future<List<_i14.Broadcast>> listBroadcasts(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i14.Broadcast>>(
    'broadcast',
    'listBroadcasts',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// "Live progress — sent, delivered, failed, remaining" (spec, minus
  /// delivered/read — see broadcast.spy.yaml's header on why those
  /// aren't tracked yet).
  _i2.Future<_i15.BroadcastProgress> getBroadcastProgress(
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) => caller.callServerEndpoint<_i15.BroadcastProgress>(
    'broadcast',
    'getBroadcastProgress',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'broadcastId': broadcastId,
    },
  );

  _i2.Future<List<_i16.MessageSuppression>> listSuppressions(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i16.MessageSuppression>>(
    'broadcast',
    'listSuppressions',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  _i2.Future<_i16.MessageSuppression> addSuppression(
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) => caller.callServerEndpoint<_i16.MessageSuppression>(
    'broadcast',
    'addSuppression',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'platform': platform,
      'address': address,
    },
  );

  _i2.Future<void> removeSuppression(
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) => caller.callServerEndpoint<void>(
    'broadcast',
    'removeSuppression',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'platform': platform,
      'address': address,
    },
  );
}

/// {@category Endpoint}
class EndpointChannel extends _i1.EndpointRef {
  EndpointChannel(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'channel';

  /// Connects [botToken] (a token from @BotFather) as the Telegram
  /// channel for [botId] inside [workspaceId]. Returns the resulting
  /// Channel row, now in 'connected' status with a real, encrypted
  /// credential and a live webhook already registered with Telegram.
  ///
  /// NOTE ON ROLE SCOPING: deliberately open to any workspace member for
  /// now (like WorkspaceEndpoint.getWorkspace), not owner-only — connecting
  /// the one bot a small business runs isn't a sensitive-enough action to
  /// gate by role at this phase. Revisit once the 'staff'/'developer'
  /// role split actually needs enforcing here (SRS.md §5).
  _i2.Future<_i12.Channel> connectTelegramChannel(
    String accessToken,
    int workspaceId,
    int botId,
    String botToken,
  ) => caller.callServerEndpoint<_i12.Channel>(
    'channel',
    'connectTelegramChannel',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'botToken': botToken,
    },
  );

  /// Every channel connected to one of the caller's own bots — for the
  /// dashboard's "Channels" page. Deliberately takes botId (not
  /// workspaceId alone) since Channel.botId is the actual foreign key;
  /// findByIdScoped on the bot is what proves workspace ownership.
  _i2.Future<List<_i12.Channel>> listChannelsForBot(
    String accessToken,
    int workspaceId,
    int botId,
  ) => caller.callServerEndpoint<List<_i12.Channel>>(
    'channel',
    'listChannelsForBot',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
    },
  );

  /// Connects a WhatsApp number the MANUAL way — the business has
  /// already gone through Meta's App Dashboard themselves (per
  /// docs/WHATSAPP_MANUAL_SETUP.md) and generated their own access
  /// token, phone_number_id, and WABA id from their own small Meta App.
  ///
  /// WHY THIS NEEDS ZERO APP REVIEW ON KOLA'S SIDE: a WhatsApp Cloud API
  /// bearer token's validity is checked by Meta against the token's own
  /// grants (which app issued it, what assets that app's System User has
  /// Standard Access to) — never against which server makes the HTTP
  /// call. The business's token was issued by THEIR app, over THEIR own
  /// number, so it works from Kola's servers exactly as it would from
  /// theirs — see whatsapp_service.dart's header for the same reasoning
  /// from the calling-code side. This is deliberately built as the
  /// primary path (not a fallback) per the product decision to lead
  /// with manual connect and treat Embedded Signup as an automatic
  /// alternative layered in later, not a dependency this path needs.
  ///
  /// WHY PROBE BEFORE PERSISTING: identical reasoning to
  /// connectTelegramChannel's getMe() call — a pasted-in token/ID
  /// combination is easy to get wrong (copying the App's access token
  /// instead of the System User's, mismatching phone_number_id and
  /// waba_id from different numbers). probe() calls Meta for real before
  /// anything touches the DB, so a bad paste fails with a clear message
  /// instead of sitting as a 'connected' channel that can never send.
  ///
  /// WHY appId/appSecret ARE NOW REQUIRED TOO (added after the initial
  /// build): appSecret is what lets WhatsAppBotRegistry verify the
  /// X-Hub-Signature-256 header on inbound webhooks — without it, this
  /// channel could send messages fine but couldn't safely trust anything
  /// arriving at the shared /webhooks/whatsapp route as really being from
  /// Meta (see whatsapp_signature_verifier.dart's header for the full
  /// reasoning). appId is stored alongside it mainly so debugToken()
  /// below has what it needs without asking the business to dig it up
  /// twice. Both live in the same App Dashboard → Settings → Basic page
  /// docs/WHATSAPP_MANUAL_SETUP.md's Step 5a walks through.
  _i2.Future<_i12.Channel> connectWhatsAppChannelManual(
    String accessToken,
    int workspaceId,
    int botId,
    String whatsappAccessToken,
    String phoneNumberId,
    String wabaId,
    String whatsappAppId,
    String whatsappAppSecret,
  ) => caller.callServerEndpoint<_i12.Channel>(
    'channel',
    'connectWhatsAppChannelManual',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'whatsappAccessToken': whatsappAccessToken,
      'phoneNumberId': phoneNumberId,
      'wabaId': wabaId,
      'whatsappAppId': whatsappAppId,
      'whatsappAppSecret': whatsappAppSecret,
    },
  );

  /// Connects an Instagram professional account — the final channel of
  /// the Connections Backbone build (Rev 5/6's Gate 11 explicitly
  /// deferred this one, scoped separately from that gate's sync()-shaped
  /// connectors since Instagram DMs are push-driven like WhatsApp/
  /// Telegram — see instagram_bot_registry.dart's header).
  ///
  /// Same manual-connect shape as connectWhatsAppChannelManual: the
  /// business has already created a Meta App, generated an Instagram
  /// User access token with instagram_business_basic +
  /// instagram_business_manage_messages permissions, and knows their own
  /// Instagram professional account's ID and that App's App Secret.
  /// Probed against Meta's real API (InstagramService.probe()) before
  /// anything touches the DB — same "a bad paste fails loudly, not as a
  /// silently-broken 'connected' row" reasoning as every other manual
  /// connect flow in this file.
  ///
  /// enableSubscription() is attempted right after probing succeeds —
  /// per Meta's docs, an App-level webhook subscription alone isn't
  /// enough; each individual Instagram account must separately opt in
  /// via POST /<IG_ID>/subscribed_apps. A failure there does NOT block
  /// the connection (sending still works; see instagram_service.dart's
  /// own doc on that method) — only logged, same soft-fail posture as
  /// WhatsApp's debug_token check above.
  _i2.Future<_i12.Channel> connectInstagramChannelManual(
    String accessToken,
    int workspaceId,
    int botId,
    String instagramAccessToken,
    String igUserId,
    String instagramAppSecret,
  ) => caller.callServerEndpoint<_i12.Channel>(
    'channel',
    'connectInstagramChannelManual',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'instagramAccessToken': instagramAccessToken,
      'igUserId': igUserId,
      'instagramAppSecret': instagramAppSecret,
    },
  );

  /// Connects a Facebook Page as a Messenger channel — same probe-
  /// before-persist shape as connectInstagramChannelManual, the exact
  /// template this method was built from (31 Aug 2026).
  _i2.Future<_i12.Channel> connectMessengerChannelManual(
    String accessToken,
    int workspaceId,
    int botId,
    String pageAccessToken,
    String pageId,
    String messengerAppSecret,
  ) => caller.callServerEndpoint<_i12.Channel>(
    'channel',
    'connectMessengerChannelManual',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'botId': botId,
      'pageAccessToken': pageAccessToken,
      'pageId': pageId,
      'messengerAppSecret': messengerAppSecret,
    },
  );

  /// Owner-initiated disconnect (2026-08-31) — the endpoint layer over
  /// ChannelRepository.disconnect + the owning registry's own
  /// disconnectChannel. Deliberately takes [channelId] directly rather
  /// than (workspaceId, botId, platformType): ConnectorStatus.channelId
  /// (connector_status.spy.yaml) is exactly this row's id, already
  /// resolved server-side for the dashboard's Disconnect button, so
  /// there is no reason to make the caller re-derive it.
  ///
  /// OWNERSHIP CHECK, NOT JUST AUTH: requireWorkspaceAccess alone would
  /// let any member of workspace A disconnect a channel belonging to
  /// workspace B, as long as they could guess or enumerate its id —
  /// [channel.botId] is looked up and re-checked against [workspaceId]
  /// via BotRepository.findByIdScoped, the same scoping every other
  /// endpoint in this file already applies before touching a Channel row.
  _i2.Future<_i12.Channel> disconnectChannel(
    String accessToken,
    int workspaceId,
    int channelId,
  ) => caller.callServerEndpoint<_i12.Channel>(
    'channel',
    'disconnectChannel',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'channelId': channelId,
    },
  );
}

/// {@category Endpoint}
class EndpointConnector extends _i1.EndpointRef {
  EndpointConnector(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'connector';

  /// Every connector in the catalog with this workspace's state resolved
  /// onto it — all 16, always. A connector the workspace cannot use yet
  /// comes back as `soon` rather than being omitted, because the
  /// marketplace draws it either way.
  ///
  /// Unlike FeatureEndpoint.listEnabledFeatures, this DOES disclose the
  /// existence of unreleased capabilities — that is the design's
  /// coming-soon tile, and it is a deliberate exception to the
  /// absence-not-false rule rather than an oversight. The exception is
  /// narrow: connector names only. No flag key, no state, nothing about
  /// the rest of the roadmap.
  _i2.Future<List<_i17.ConnectorStatus>> listConnectors(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i17.ConnectorStatus>>(
    'connector',
    'listConnectors',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Connects a generic-store connector by storing the values from its
  /// catalog-defined form.
  ///
  /// [values] is keyed by ConnectorField.key. Anything not declared on
  /// the connector's own definition is DROPPED rather than stored —
  /// a caller cannot invent fields, so the encrypted blob's shape stays
  /// the one the catalog describes.
  _i2.Future<_i17.ConnectorStatus> connectConnector(
    String accessToken,
    int workspaceId,
    String connectorKey,
    Map<String, String> values,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'connectConnector',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'values': values,
    },
  );

  /// Gate 4 — the URL to redirect the owner's browser to, for a
  /// connector whose auth type is 'oauth'. The dashboard opens this
  /// directly (a real browser redirect, not an API call the client can
  /// inspect); GoogleOAuthCallbackRoute is where the flow lands back.
  _i2.Future<String> startGoogleOAuth(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<String>(
    'connector',
    'startGoogleOAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Connect Gate, subphase 4d — every Google Sheets spreadsheet the
  /// CONNECTED account can see, for the dashboard's picker. This is what
  /// [setGoogleSheetTarget]'s old doc comment said didn't exist yet ("the
  /// heavier Picker API, deliberately not built for this pass") — it's
  /// simpler than Google's own Picker widget: a plain Drive files.list
  /// call under drive.metadata.readonly (see google_drive_service.dart),
  /// requested alongside the Sheets scope specifically so this becomes
  /// possible. [alreadyConnected] is computed against this workspace's
  /// current selection so the dashboard can pre-check rows without a
  /// second round trip.
  ///
  /// Throws [GoogleSheetsReconnectRequiredException]-shaped KolaException
  /// for a workspace that connected BEFORE this scope existed — their
  /// stored refresh token has no Drive grant, so Google will 403 this
  /// call until they reconnect. See this file's header on why that's
  /// surfaced as a clear "reconnect" message, not a raw API error.
  _i2.Future<List<_i18.GoogleDriveSpreadsheet>> listGoogleSheets(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<List<_i18.GoogleDriveSpreadsheet>>(
    'connector',
    'listGoogleSheets',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Connect Gate, subphase 4d — REPLACES the full set of spreadsheets a
  /// CONNECTED Google Sheets integration reads, in one call — what the
  /// picker's "Save" button calls after an owner checks/unchecks rows
  /// from [listGoogleSheets]. An empty list is valid: it means "sync
  /// nothing", not an error — same as never having picked a sheet at all
  /// under the old single-target flow.
  _i2.Future<_i17.ConnectorStatus> setGoogleSheetTargets(
    String accessToken,
    int workspaceId,
    String connectorKey,
    List<String> spreadsheetIds,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'setGoogleSheetTargets',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'spreadsheetIds': spreadsheetIds,
    },
  );

  /// Kept for any caller still on the old single-sheet flow (a paste box
  /// as a fallback next to the picker, or an older dashboard build) —
  /// ADDS [sheetUrl] to whatever's already selected rather than
  /// replacing it, since a paste box has no way to express "and keep the
  /// others too" the way the picker's checkbox list does.
  _i2.Future<_i17.ConnectorStatus> setGoogleSheetTarget(
    String accessToken,
    int workspaceId,
    String connectorKey,
    String sheetUrl,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'setGoogleSheetTarget',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'sheetUrl': sheetUrl,
    },
  );

  /// Gate 4 — the Microsoft-provider twin of [startGoogleOAuth]. Same
  /// state-signing contract, one real difference: [scopes] is embedded
  /// in the encrypted state too, because
  /// MicrosoftOAuthCallbackRoute.handleCall needs to restate the exact
  /// same scope string on the token exchange (Microsoft's token endpoint
  /// requires it; Google's does not — see microsoft_oauth_service.dart's
  /// header).
  _i2.Future<String> startMicrosoftOAuth(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<String>(
    'connector',
    'startMicrosoftOAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Fix-properly pass — the Dropbox twin of [startGoogleOAuth]. Same
  /// state-signing contract, no scope list: Dropbox's OAuth app
  /// permissions are configured once on the App Console (a fixed
  /// "scope" per app, not requested per-authorize-call the way Google/
  /// Meta scopes are), so there is no per-connector scope lookup to
  /// fail on the way [_googleScopesFor]/[_microsoftScopesFor] can.
  _i2.Future<String> startDropboxOAuth(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<String>(
    'connector',
    'startDropboxOAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Fix-properly pass — the HubSpot twin of [startGoogleOAuth].
  _i2.Future<String> startHubSpotOAuth(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<String>(
    'connector',
    'startHubSpotOAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Fix-properly pass — the Meta twin of [startGoogleOAuth], shared by
  /// BOTH instagram_shop and facebook_catalog (one Meta App — see
  /// meta_oauth_service.dart's header). [_metaScopesFor] is what tells
  /// the two connectors apart.
  _i2.Future<String> startMetaOAuth(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<String>(
    'connector',
    'startMetaOAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );

  /// Gate 4 — the OneDrive/SharePoint twin of [setGoogleSheetTarget].
  /// UNLIKE that method, this one makes a real Graph call: a sharing URL
  /// carries no stable id the way a Google Sheets URL does, so the
  /// pasted link has to be resolved into a (driveId, itemId) pair via
  /// MicrosoftGraphExcelService.resolveShareUrl BEFORE anything is
  /// stored — see that method's header. Doing this here rather than at
  /// sync time means a bad link fails LOUD, in front of the owner who
  /// just pasted it, not silently on the next unattended sweep run.
  _i2.Future<_i17.ConnectorStatus> setExcelFileTarget(
    String accessToken,
    int workspaceId,
    String connectorKey,
    String fileUrl,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'setExcelFileTarget',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'fileUrl': fileUrl,
    },
  );

  /// Gate 4 — sets whether a bot-proposed calendar booking is created on
  /// Google immediately, or held as a pending row an owner must approve
  /// first. See calendar_booking.spy.yaml's header on why this exists:
  /// Calendar is the first write-capable connector, and this is the
  /// owner's own guardrail on it, not a fixed platform decision.
  /// [bookingMode] must be 'draft' or 'immediate'. Read back by
  /// bookCalendarEvent (builtin_errand_executor.dart), which treats an
  /// UNSET value (a connection made before this setting existed, or one
  /// never touched) as 'draft' — the safer default, never 'immediate'
  /// by omission.
  _i2.Future<_i17.ConnectorStatus> setCalendarBookingMode(
    String accessToken,
    int workspaceId,
    String bookingMode,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'setCalendarBookingMode',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'bookingMode': bookingMode,
    },
  );

  /// Gate 4 — every booking this workspace's bot(s) have proposed that
  /// still needs an owner's yes/no. Draft-mode bookings only — a
  /// workspace running in immediate mode never accumulates any of these,
  /// since bookCalendarEvent skips straight to Google for them.
  _i2.Future<List<_i19.CalendarBooking>> listPendingBookings(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i19.CalendarBooking>>(
    'connector',
    'listPendingBookings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Approves a pending booking: marks it 'approved', creates the real
  /// Google Calendar event, then marks it 'booked' with the real event
  /// id. If the Google call itself fails (token revoked, etc.), the
  /// booking is left sitting at 'approved' rather than silently reverted
  /// — visibly stuck, matching migration 042's own reasoning for why
  /// 'approved' and 'booked' are distinct states, not one.
  _i2.Future<_i19.CalendarBooking> approveBooking(
    String accessToken,
    int workspaceId,
    int bookingId,
  ) => caller.callServerEndpoint<_i19.CalendarBooking>(
    'connector',
    'approveBooking',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'bookingId': bookingId,
    },
  );

  _i2.Future<_i19.CalendarBooking> rejectBooking(
    String accessToken,
    int workspaceId,
    int bookingId,
  ) => caller.callServerEndpoint<_i19.CalendarBooking>(
    'connector',
    'rejectBooking',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'bookingId': bookingId,
    },
  );

  /// Disconnects, clearing the stored credential but keeping the row —
  /// 'disconnected' and "never connected" are different states, and the
  /// row is the only record that this business ever had it working.
  _i2.Future<_i17.ConnectorStatus> disconnectConnector(
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) => caller.callServerEndpoint<_i17.ConnectorStatus>(
    'connector',
    'disconnectConnector',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
    },
  );
}

/// {@category Endpoint}
class EndpointConversation extends _i1.EndpointRef {
  EndpointConversation(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'conversation';

  /// Every escalated conversation for a workspace, most recently active
  /// first — the inbox's main queue.
  _i2.Future<List<_i3.Conversation>> listEscalated(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i3.Conversation>>(
    'conversation',
    'listEscalated',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Every conversation for a workspace regardless of status — for a
  /// future "all conversations" view beyond just the escalated queue.
  _i2.Future<List<_i3.Conversation>> listAll(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i3.Conversation>>(
    'conversation',
    'listAll',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// The full message thread for one conversation, oldest first.
  _i2.Future<List<_i5.Message>> getMessages(
    String accessToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<List<_i5.Message>>(
    'conversation',
    'getMessages',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );

  /// The human's reply — persisted as a Message (senderType 'human')
  /// and actually sent back to the customer over whichever platform
  /// (Telegram/WhatsApp) the conversation is on, via that platform's
  /// registry (same messagingFor(channelId) adapters the bot itself
  /// uses to send). Does NOT change the conversation's status — it
  /// stays 'escalated' until the human explicitly closes it (see
  /// [closeConversation]), since one reply doesn't necessarily resolve
  /// things.
  _i2.Future<_i5.Message> sendHumanReply(
    String accessToken,
    int workspaceId,
    int conversationId,
    String body,
  ) => caller.callServerEndpoint<_i5.Message>(
    'conversation',
    'sendHumanReply',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'body': body,
    },
  );

  /// Marks a conversation resolved — status flips to 'closed', so the
  /// bot resumes auto-replying if the customer messages again (see
  /// ConversationRepository.findOrCreate's reopen-on-new-message logic).
  _i2.Future<_i3.Conversation> closeConversation(
    String accessToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<_i3.Conversation>(
    'conversation',
    'closeConversation',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );
}

/// {@category Endpoint}
class EndpointCustomer extends _i1.EndpointRef {
  EndpointCustomer(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'customer';

  _i2.Future<List<_i20.Customer>> listCustomers(
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i20.Customer>>(
    'customer',
    'listCustomers',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'limit': limit,
      'offset': offset,
    },
  );

  /// Phase 13f — the Customers page's list, with lifetime value and
  /// order count already computed per customer, so the page doesn't
  /// have to call getCustomerDetail once per row (an N+1 this endpoint
  /// avoids by fetching Sales/Payments/Conversations ONCE for the whole
  /// workspace and grouping in memory — same shape as
  /// AnalyticsEndpoint.getSummary, Phase 13e).
  ///
  /// De-duplicated the same way: a completed PaymentTransaction already
  /// matched to a Sale via saleId is not counted twice. `from`/`to` span
  /// effectively "all time" — there's no natural period boundary for a
  /// customer's own lifetime value the way Analytics has one for a
  /// revenue trend.
  _i2.Future<List<_i21.CustomerSummary>> listCustomersWithSummary(
    String accessToken,
    int workspaceId, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i21.CustomerSummary>>(
    'customer',
    'listCustomersWithSummary',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'limit': limit,
    },
  );

  /// The Gate 3b proof surface: everything this customer has ever done,
  /// across every source, in one place — see CustomerDetail's header.
  _i2.Future<_i22.CustomerDetail> getCustomerDetail(
    String accessToken,
    int workspaceId,
    int customerId,
  ) => caller.callServerEndpoint<_i22.CustomerDetail>(
    'customer',
    'getCustomerDetail',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'customerId': customerId,
    },
  );

  /// The merge-review queue — PART V: "Merges are proposals, not
  /// facts... the owner confirms."
  _i2.Future<List<_i23.CustomerMergeProposal>> listMergeProposals(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i23.CustomerMergeProposal>>(
    'customer',
    'listMergeProposals',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// [approve] true confirms the merge (loser folds into survivor via
  /// mergedIntoId — see customer_repository.dart's header on why
  /// nothing else is ever rewritten); false rejects it outright, and
  /// the two customers stay independent. The LOWER-id customer
  /// (customerAId) is always treated as the survivor — arbitrary but
  /// consistent, and it means "the older record wins" in practice,
  /// since ids are assigned in creation order.
  _i2.Future<void> resolveMergeProposal(
    String accessToken,
    int workspaceId,
    int proposalId,
    bool approve,
  ) => caller.callServerEndpoint<void>(
    'customer',
    'resolveMergeProposal',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'proposalId': proposalId,
      'approve': approve,
    },
  );
}

/// {@category Endpoint}
class EndpointCustomerProfile extends _i1.EndpointRef {
  EndpointCustomerProfile(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'customerProfile';

  /// Null when nothing has been saved for this conversation — a
  /// perfectly normal state, not an error.
  _i2.Future<_i24.CustomerProfile?> getForConversation(
    String accessToken,
    int workspaceId,
    int conversationId,
  ) => caller.callServerEndpoint<_i24.CustomerProfile?>(
    'customerProfile',
    'getForConversation',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
    },
  );
}

/// {@category Endpoint}
class EndpointErrand extends _i1.EndpointRef {
  EndpointErrand(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'errand';

  /// Registers a new built-in Errand — see file header on why only
  /// 'builtin' is accepted today. [builtinHandlerKey] must match one of
  /// BuiltinErrandExecutor's registered handlers (currently just
  /// 'escalateToHuman') — validated against Meta... no, against that
  /// registry directly, so a typo'd key fails here with a clear message
  /// instead of at first invocation.
  _i2.Future<_i6.Errand> createBuiltinErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String builtinHandlerKey,
    String createdVia, {
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i6.Errand>(
    'errand',
    'createBuiltinErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'builtinHandlerKey': builtinHandlerKey,
      'createdVia': createdVia,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Every Errand belonging to a workspace, regardless of status.
  _i2.Future<List<_i6.Errand>> listErrandsForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i6.Errand>>(
    'errand',
    'listErrandsForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Fetch one Errand by id — access-checked via its workspace, same
  /// posture as BotEndpoint.getBot.
  _i2.Future<_i6.Errand> getErrand(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<_i6.Errand>(
    'errand',
    'getErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Phase 13d — the run history behind `Kola Automation Builder.dc.html`.
  ///
  /// A DELIBERATELY SMALL SLICE of that export, not the whole thing —
  /// see automation_runs_page.dart's own header for the full reasoning.
  /// Short version: the export shows an ordered chain of steps with
  /// per-step approval gates ("stopped at step 3, awaiting your
  /// approval"). Nothing in this codebase models a multi-step chain —
  /// Errand is one action, ErrandExecutionLog is one execution record of
  /// one Errand, with no step concept and no approval/hold state. That
  /// is real, separate future work (a new "Automation" entity above
  /// Errand). What ships here is what already exists made visible: one
  /// Errand's own execution history, newest first.
  _i2.Future<List<_i25.ErrandExecutionLog>> listExecutions(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<List<_i25.ErrandExecutionLog>>(
    'errand',
    'listExecutions',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Toggle an Errand active/disabled without deleting its history/logs.
  _i2.Future<_i6.Errand> setErrandStatus(
    String accessToken,
    int workspaceId,
    int errandId,
    String status,
  ) => caller.callServerEndpoint<_i6.Errand>(
    'errand',
    'setErrandStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'status': status,
    },
  );

  /// Permanently deletes an Errand — ONLY when it's already 'disabled'.
  /// An owner asked for this directly: "errands that are disabled should
  /// be deletable." A live/active Errand is not deletable through this
  /// method — disable it first (setErrandStatus), same two-step guard
  /// rail every other "destroy something" flow in this codebase already
  /// requires, so nothing mid-conversation ever loses the Errand it's
  /// about to call out from under it. Deletes the Errand's own row AND
  /// its credential row (if any) — see errand_credential_repository.dart
  /// — but deliberately leaves its ErrandExecutionLog history alone
  /// (SRS.md §7.3's execution log is an audit trail; deleting the Errand
  /// that generated an entry shouldn't erase that it happened).
  _i2.Future<void> deleteErrand(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<void>(
    'errand',
    'deleteErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Runs a 'builtin' Errand right now, synchronously, and returns its
  /// result as a JSON string — same "flexible shape lives in a JSON
  /// string" pattern as inputSchemaJson, since a raw `Map<String,dynamic>`
  /// isn't a type Serverpod's codegen can safely serialize. [inputJson]
  /// is a JSON-encoded Map matching the Errand's inputSchemaJson shape.
  /// Every invocation is logged (success or failure) by
  /// BuiltinErrandExecutor before this method returns/throws — see its
  /// file header.
  _i2.Future<String> executeBuiltinErrand(
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'executeBuiltinErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'inputJson': inputJson,
    },
  );

  /// Registers a new webhook-backed Errand AND collects/encrypts its
  /// credential in one call — a business connecting a webhook Errand
  /// shouldn't be left with a half-registered Errand that has nowhere
  /// to send its calls. [webhookUrl] must be a valid absolute URL (any
  /// scheme — https strongly recommended, but not enforced here, since
  /// local dev/testing against plain http is a real, legitimate case).
  /// [authHeaderName]/[authHeaderValue] are optional and sent together
  /// or not at all — see webhook_errand_credential.dart.
  _i2.Future<_i6.Errand> createWebhookErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String webhookUrl, {
    String? authHeaderName,
    String? authHeaderValue,
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i6.Errand>(
    'errand',
    'createWebhookErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'createdVia': createdVia,
      'webhookUrl': webhookUrl,
      'authHeaderName': authHeaderName,
      'authHeaderValue': authHeaderValue,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Registers a new database-credential Errand AND collects/encrypts
  /// its connection string in one call — same "never half-registered"
  /// reasoning as createWebhookErrand. [queryTemplateSql] is the ONE
  /// pre-approved named-parameter query this Errand will ever run (see
  /// errand.spy.yaml's queryTemplateSql header) — if [permissionScope]
  /// is 'readOnly' (the default), it must start with SELECT, checked
  /// here at registration time AND again at execution time by
  /// DbCredentialErrandExecutor (defense in depth against the template
  /// being edited later without a matching permission upgrade).
  _i2.Future<_i6.Errand> createDbCredentialErrand(
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String queryTemplateSql,
    String connectionString, {
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) => caller.callServerEndpoint<_i6.Errand>(
    'errand',
    'createDbCredentialErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'createdVia': createdVia,
      'queryTemplateSql': queryTemplateSql,
      'connectionString': connectionString,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
    },
  );

  /// Runs ANY Errand right now, synchronously, dispatching to the right
  /// executor by errand.source — see file header on why this is one
  /// method rather than three. Same JSON-string-in/JSON-string-out
  /// contract as executeBuiltinErrand.
  _i2.Future<String> executeErrand(
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'executeErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'inputJson': inputJson,
    },
  );

  /// Connects to [connectionString] and returns its 'public' schema's
  /// tables and columns as a JSON string ({'tables': [...]}) — read-only,
  /// never touches the business's own row data (see
  /// DbSchemaDiscoveryService's header). Called BEFORE an Errand exists,
  /// which is why this takes a raw connection string rather than an
  /// errandId — see [discoverDbSchemaForErrand] for the already-saved
  /// case.
  _i2.Future<String> discoverDbSchema(
    String accessToken,
    int workspaceId,
    String connectionString,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'discoverDbSchema',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'connectionString': connectionString,
    },
  );

  /// Same as [discoverDbSchema], but re-reads an ALREADY-SAVED
  /// dbCredential Errand's own database — lets an owner re-check what
  /// their schema looks like today without pasting the connection
  /// string in a second time. Decrypts the stored credential the same
  /// way DbCredentialErrandExecutor does.
  _i2.Future<String> discoverDbSchemaForErrand(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'discoverDbSchemaForErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Fires one real, UNSAVED, UNLOGGED test request at [webhookUrl] —
  /// the webhook-fulfillment equivalent of [discoverDbSchema]: a
  /// connectivity/shape check before the owner commits to saving a
  /// webhook Errand, not a substitute for ErrandExecutionLog once one
  /// exists. [sampleInputJson] is a JSON-encoded Map, same shape a real
  /// invocation's input would eventually be.
  _i2.Future<String> testWebhookErrand(
    String accessToken,
    int workspaceId,
    String webhookUrl,
    String sampleInputJson, {
    String? authHeaderName,
    String? authHeaderValue,
  }) => caller.callServerEndpoint<String>(
    'errand',
    'testWebhookErrand',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'webhookUrl': webhookUrl,
      'sampleInputJson': sampleInputJson,
      'authHeaderName': authHeaderName,
      'authHeaderValue': authHeaderValue,
    },
  );

  /// The saved mapping for [errandId], as a JSON string
  /// ({'enabled', 'phoneColumn', 'emailColumn', 'nameColumn'}) — or
  /// '{"enabled": false}' if none has been saved yet, so the dashboard
  /// has one shape to render regardless.
  _i2.Future<String> getEntityMapping(
    String accessToken,
    int workspaceId,
    int errandId,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'getEntityMapping',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
    },
  );

  /// Saves [mappingJson] as [errandId]'s entity mapping — only valid for
  /// a 'dbCredential' Errand (see header). Validated here, not just
  /// trusted: when 'enabled' is true, at least one of phoneColumn/
  /// emailColumn must be a non-empty string, since
  /// CustomerIdentityResolver has nothing to match on otherwise (see
  /// ErrandRowCustomerMapper, which re-checks this same condition rather
  /// than trusting a stored value alone).
  _i2.Future<String> setEntityMapping(
    String accessToken,
    int workspaceId,
    int errandId,
    String mappingJson,
  ) => caller.callServerEndpoint<String>(
    'errand',
    'setEntityMapping',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'errandId': errandId,
      'mappingJson': mappingJson,
    },
  );
}

/// {@category Endpoint}
class EndpointFeature extends _i1.EndpointRef {
  EndpointFeature(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feature';

  /// Every feature key currently available to this workspace.
  ///
  /// The dashboard calls this once on load and renders navigation and
  /// routes from the result. Keys absent from the list do not exist as
  /// far as that session is concerned — see this file's header on why
  /// absence rather than `false`.
  _i2.Future<List<String>> listEnabledFeatures(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<String>>(
    'feature',
    'listEnabledFeatures',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Whether one specific feature is available. Exists for the case
  /// where a page needs to re-check after a plan upgrade without
  /// reloading the whole set — not as the general mechanism.
  ///
  /// Returns false for an unknown key rather than throwing, matching
  /// FeatureFlagService's fail-closed posture: a dashboard built against
  /// a newer server should degrade to hiding a feature, never to an
  /// error screen.
  _i2.Future<bool> isFeatureEnabled(
    String accessToken,
    int workspaceId,
    String featureKey,
  ) => caller.callServerEndpoint<bool>(
    'feature',
    'isFeatureEnabled',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
    },
  );
}

/// {@category Endpoint}
class EndpointFinding extends _i1.EndpointRef {
  EndpointFinding(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'finding';

  /// What needs the owner's attention, worst first.
  ///
  /// Never throws for a workspace with nothing wrong — an empty list is
  /// the correct and common answer, and the dashboard renders it as
  /// "all clear" rather than as a failure.
  _i2.Future<List<_i26.WorkspaceFinding>> listFindings(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i26.WorkspaceFinding>>(
    'finding',
    'listFindings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// "I know about this one." Permanent — see migration 034.
  ///
  /// Scoped by workspace inside the repository as well as here. The
  /// access check proves the caller belongs to THIS workspace; it does
  /// not prove the finding does, and a crafted id would otherwise let
  /// one workspace dismiss another's.
  _i2.Future<void> dismissFinding(
    String accessToken,
    int workspaceId,
    int findingId,
  ) => caller.callServerEndpoint<void>(
    'finding',
    'dismissFinding',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'findingId': findingId,
    },
  );
}

/// {@category Endpoint}
class EndpointInvoice extends _i1.EndpointRef {
  EndpointInvoice(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'invoice';

  /// Creates a new invoice. [linesJson] is a JSON array of
  /// `{"name": String, "quantity": int, "unitPriceMinor": int}` objects —
  /// a String parameter, deliberately, not `List<InvoiceLineInput>` or
  /// even a parallel `List<int>`/`List<String>` split. See
  /// sale_endpoint.dart's ringUpSale header for the full trace of why
  /// this app's Serverpod install cannot deserialize ANY `List<...>` as a
  /// direct endpoint parameter — that finding governs this endpoint's
  /// shape too, not just the till's.
  ///
  /// Totals are recomputed from [linesJson] here, server-side — never
  /// trusted from the caller, same discipline ringUpSale already applies
  /// to a sale's subtotal/tax/total.
  _i2.Future<_i27.Invoice> createInvoice(
    String accessToken,
    int workspaceId,
    String billToName,
    String linesJson, {
    int? customerId,
    int? saleId,
    String? billToAddress,
    String? billToPhone,
    required int taxRateBps,
    required String currency,
    String? paymentInstructions,
    DateTime? dueAt,
  }) => caller.callServerEndpoint<_i27.Invoice>(
    'invoice',
    'createInvoice',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'billToName': billToName,
      'linesJson': linesJson,
      'customerId': customerId,
      'saleId': saleId,
      'billToAddress': billToAddress,
      'billToPhone': billToPhone,
      'taxRateBps': taxRateBps,
      'currency': currency,
      'paymentInstructions': paymentInstructions,
      'dueAt': dueAt,
    },
  );

  _i2.Future<List<_i27.Invoice>> listInvoices(
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i27.Invoice>>(
    'invoice',
    'listInvoices',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'limit': limit,
      'offset': offset,
    },
  );

  _i2.Future<_i27.Invoice?> getInvoice(
    String accessToken,
    int workspaceId,
    int invoiceId,
  ) => caller.callServerEndpoint<_i27.Invoice?>(
    'invoice',
    'getInvoice',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'invoiceId': invoiceId,
    },
  );

  /// The most recently issued invoice for a given sale, or null. Lets
  /// Documents' A4 tab reuse an existing invoice instead of creating a
  /// new one every time an owner opens the tab for the same sale.
  _i2.Future<_i27.Invoice?> getInvoiceForSale(
    String accessToken,
    int workspaceId,
    int saleId,
  ) => caller.callServerEndpoint<_i27.Invoice?>(
    'invoice',
    'getInvoiceForSale',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'saleId': saleId,
    },
  );

  /// Owner-driven status transitions (draft -> sent -> viewed), and the
  /// only way to move backward too (e.g. correcting a mistaken "sent").
  /// No validation on the transition graph — same trust level Sale's own
  /// status already gets, and simpler than encoding a state machine for
  /// four values an owner is the sole judge of.
  _i2.Future<_i27.Invoice> updateInvoiceStatus(
    String accessToken,
    int workspaceId,
    int invoiceId,
    String status,
  ) => caller.callServerEndpoint<_i27.Invoice>(
    'invoice',
    'updateInvoiceStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'invoiceId': invoiceId,
      'status': status,
    },
  );

  /// Manual "mark as paid" — see this file's header on why this is not
  /// an automatic webhook credit yet.
  _i2.Future<_i27.Invoice> recordPayment(
    String accessToken,
    int workspaceId,
    int invoiceId,
    int amountMinor,
  ) => caller.callServerEndpoint<_i27.Invoice>(
    'invoice',
    'recordPayment',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'invoiceId': invoiceId,
      'amountMinor': amountMinor,
    },
  );
}

/// {@category Endpoint}
class EndpointKnowledge extends _i1.EndpointRef {
  EndpointKnowledge(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'knowledge';

  /// Every document in the workspace, newest first.
  _i2.Future<List<_i4.KnowledgeDocument>> listDocuments(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i4.KnowledgeDocument>>(
    'knowledge',
    'listDocuments',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Ingests [text] as a new document: dedupe, chunk, embed, index.
  ///
  /// THROWS with an owner-readable message on every non-success path
  /// (duplicate, empty, quota exhausted, embeddings unconfigured) rather
  /// than returning a status object. That's the convention every other
  /// endpoint in this codebase already follows, and it keeps the
  /// generated client's return type honest — a KnowledgeDocument here
  /// always means a document that is actually searchable.
  ///
  /// The one place that's a slightly awkward fit is 'duplicate', which
  /// isn't really an error. The message says so plainly and names the
  /// existing document, so the dashboard can offer "save it anyway"
  /// (which calls this again with [allowDuplicate] true) rather than
  /// presenting a dead end.
  _i2.Future<_i4.KnowledgeDocument> addDocument(
    String accessToken,
    int workspaceId,
    String title,
    String text, {
    required bool allowDuplicate,
  }) => caller.callServerEndpoint<_i4.KnowledgeDocument>(
    'knowledge',
    'addDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'title': title,
      'text': text,
      'allowDuplicate': allowDuplicate,
    },
  );

  /// Removes a document from memory. Its chunks go with it via ON DELETE
  /// CASCADE (migration 017), so the bot genuinely stops knowing this —
  /// there is no path that leaves retrievable chunks behind.
  _i2.Future<void> deleteDocument(
    String accessToken,
    int workspaceId,
    int documentId,
  ) => caller.callServerEndpoint<void>(
    'knowledge',
    'deleteDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'documentId': documentId,
    },
  );

  /// Replaces an existing document's content in place, keeping its id.
  _i2.Future<_i4.KnowledgeDocument> updateDocument(
    String accessToken,
    int workspaceId,
    int documentId,
    String title,
    String text,
  ) => caller.callServerEndpoint<_i4.KnowledgeDocument>(
    'knowledge',
    'updateDocument',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'documentId': documentId,
      'title': title,
      'text': text,
    },
  );

  /// Runs a real memory search and returns what the bot WOULD retrieve
  /// for [query], scores included.
  ///
  /// This is an inspection tool, and it is the reason
  /// knowledge_search_hit.spy.yaml exists — see that file's header. An
  /// owner can type a question a customer actually asked and see exactly
  /// which passages ground the answer, rather than having to trust the
  /// bot or argue with it.
  _i2.Future<List<_i28.KnowledgeSearchHit>> searchMemory(
    String accessToken,
    int workspaceId,
    String query,
  ) => caller.callServerEndpoint<List<_i28.KnowledgeSearchHit>>(
    'knowledge',
    'searchMemory',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'query': query,
    },
  );

  /// Answers a question the OWNER typed, in prose, with the products it
  /// refers to and what they might do next.
  ///
  /// ── HOW THIS DIFFERS FROM searchMemory ABOVE ───────────────────────
  ///
  /// searchMemory is an INSPECTION tool: it returns passages and scores
  /// so an owner can audit what the bot would ground an answer on. It
  /// was also, until now, what the Overview's "Ask kola" box called —
  /// which meant that box printed raw document text and no answer at
  /// all. Two different jobs were being done by one method, and the
  /// wrong one won.
  ///
  /// Both are kept. The Memory Inspector still wants searchMemory
  /// exactly as it is; this is the one that answers.
  ///
  /// Never throws for an unanswerable question — see
  /// WorkspaceAnswerService. A question during a provider outage returns
  /// `generated: false` and an honest sentence, because an owner asking
  /// their own dashboard a question should not be shown a stack trace.
  _i2.Future<_i29.WorkspaceAnswer> askWorkspace(
    String accessToken,
    int workspaceId,
    String question,
  ) => caller.callServerEndpoint<_i29.WorkspaceAnswer>(
    'knowledge',
    'askWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'question': question,
    },
  );

  /// Adds a document from an uploaded FILE rather than pasted text.
  ///
  /// ── WHY THE BYTES COME THROUGH THE SERVER, UNLIKE PHOTOS ───────────
  ///
  /// Product photos deliberately bypass this server: they are megabytes,
  /// they need a progress bar, and base64 through a Serverpod parameter
  /// would send them twice (see imagekit_service.dart).
  ///
  /// A spreadsheet is the opposite case on every count. A price list is
  /// tens of kilobytes, it needs no progress bar, and the extraction it
  /// requires — unzipping and parsing OOXML — belongs on a server rather
  /// than in every browser's bundle. So this one proxies, and that is
  /// the right call for this shape of file specifically.
  ///
  /// [base64Bytes] is the raw file. Serverpod parameters are JSON, so
  /// binary has to be encoded; at this size the ~33% overhead is not
  /// worth engineering around.
  _i2.Future<_i4.KnowledgeDocument> addDocumentFromFile(
    String accessToken,
    int workspaceId,
    String fileName,
    String base64Bytes, {
    required bool allowDuplicate,
  }) => caller.callServerEndpoint<_i4.KnowledgeDocument>(
    'knowledge',
    'addDocumentFromFile',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'fileName': fileName,
      'base64Bytes': base64Bytes,
      'allowDuplicate': allowDuplicate,
    },
  );
}

/// {@category Endpoint}
class EndpointOwnerNotification extends _i1.EndpointRef {
  EndpointOwnerNotification(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'ownerNotification';

  /// Returns null if the workspace has never configured notification
  /// settings yet — callers should treat that as "every channel
  /// disabled," not an error.
  _i2.Future<_i30.OwnerNotificationSettings?> getSettings(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<_i30.OwnerNotificationSettings?>(
    'ownerNotification',
    'getSettings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Create-or-replace — see OwnerNotificationSettingsRepository.upsert.
  /// Any field left null/false simply disables that channel; there's no
  /// partial-update semantics here on purpose, since a settings form
  /// naturally submits the whole shape at once.
  _i2.Future<_i30.OwnerNotificationSettings> updateSettings(
    String accessToken,
    int workspaceId, {
    String? ownerEmail,
    required bool emailEnabled,
    String? ownerWhatsappNumber,
    required bool whatsappEnabled,
    String? telegramChatId,
    required bool telegramEnabled,
    String? ownerSmsNumber,
    required bool smsEnabled,
    String? slackWebhookUrl,
    required bool slackEnabled,
  }) => caller.callServerEndpoint<_i30.OwnerNotificationSettings>(
    'ownerNotification',
    'updateSettings',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'ownerEmail': ownerEmail,
      'emailEnabled': emailEnabled,
      'ownerWhatsappNumber': ownerWhatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      'telegramChatId': telegramChatId,
      'telegramEnabled': telegramEnabled,
      'ownerSmsNumber': ownerSmsNumber,
      'smsEnabled': smsEnabled,
      'slackWebhookUrl': slackWebhookUrl,
      'slackEnabled': slackEnabled,
    },
  );
}

/// {@category Endpoint}
class EndpointPayment extends _i1.EndpointRef {
  EndpointPayment(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'payment';

  /// Connects (or rotates) a workspace's OWN Paystack/Flutterwave/Stripe/
  /// Monnify credential. Probes it against the real gateway before
  /// persisting anything.
  ///
  /// [apiKey] is MONNIFY ONLY — see payment_gateway_credential.spy.yaml's
  /// encryptedApiKey field doc on why Monnify needs a second required
  /// credential none of the other three gateways do. Ignored for every
  /// other gateway.
  _i2.Future<_i31.PaymentGatewayCredential> connectGateway(
    String accessToken,
    int workspaceId,
    String gateway,
    String secretKey, {
    String? webhookSecret,
    String? apiKey,
  }) => caller.callServerEndpoint<_i31.PaymentGatewayCredential>(
    'payment',
    'connectGateway',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'secretKey': secretKey,
      'webhookSecret': webhookSecret,
      'apiKey': apiKey,
    },
  );

  /// Every gateway this workspace has connected (never returns the
  /// decrypted key — this exists so a dashboard can show "Paystack:
  /// connected" without exposing the secret back to any client).
  _i2.Future<List<_i31.PaymentGatewayCredential>> listConnectedGateways(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i31.PaymentGatewayCredential>>(
    'payment',
    'listConnectedGateways',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Starts a checkout against the workspace's OWN connected [gateway]
  /// account. See payment_checkout_service.dart for what actually
  /// happens — this method's only job is the auth check.
  _i2.Future<_i32.PaymentTransaction> initializeCheckout(
    String accessToken,
    int workspaceId,
    String gateway,
    int amountKobo,
    String customerEmail, {
    String? customerPhone,
    required bool holdInEscrow,
    int? conversationId,
    int? channelId,
    Map<String, dynamic>? metadata,
  }) => caller.callServerEndpoint<_i32.PaymentTransaction>(
    'payment',
    'initializeCheckout',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'amountKobo': amountKobo,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'holdInEscrow': holdInEscrow,
      'conversationId': conversationId,
      'channelId': channelId,
      'metadata': metadata,
    },
  );

  _i2.Future<_i32.PaymentTransaction?> getTransaction(
    String accessToken,
    int workspaceId,
    int transactionId,
  ) => caller.callServerEndpoint<_i32.PaymentTransaction?>(
    'payment',
    'getTransaction',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'transactionId': transactionId,
    },
  );

  /// Flips a held transaction's bookkeeping status to released — see
  /// payment_transaction.spy.yaml's header on why this is NOT a real
  /// fund-movement call. Only valid once the payment itself is
  /// 'completed'; re-checked here even though a caller "should" already
  /// know that, per this codebase's usual "never trust a caller-supplied
  /// precondition" rule (same reasoning as db_credential_errand_executor's
  /// double read-only check).
  _i2.Future<_i32.PaymentTransaction> releaseHold(
    String accessToken,
    int workspaceId,
    int transactionId,
  ) => caller.callServerEndpoint<_i32.PaymentTransaction>(
    'payment',
    'releaseHold',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'transactionId': transactionId,
    },
  );
}

/// {@category Endpoint}
class EndpointPlatform extends _i1.EndpointRef {
  EndpointPlatform(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'platform';

  /// Every key for the workspace, revoked ones included — the design
  /// shows them so an owner can see what they turned off.
  _i2.Future<List<_i33.ApiKey>> listApiKeys(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i33.ApiKey>>(
    'platform',
    'listApiKeys',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Creates a key. The response carries the ONLY copy of the plaintext.
  _i2.Future<_i34.CreatedApiKey> createApiKey(
    String accessToken,
    int workspaceId,
    String name,
    String scope,
  ) => caller.callServerEndpoint<_i34.CreatedApiKey>(
    'platform',
    'createApiKey',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'scope': scope,
    },
  );

  /// Revokes immediately. Idempotent — revoking twice keeps the original
  /// timestamp, because when it stopped working is the fact that matters.
  _i2.Future<void> revokeApiKey(
    String accessToken,
    int workspaceId,
    int keyId,
  ) => caller.callServerEndpoint<void>(
    'platform',
    'revokeApiKey',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'keyId': keyId,
    },
  );

  _i2.Future<List<_i35.WebhookEndpoint>> listWebhookEndpoints(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i35.WebhookEndpoint>>(
    'platform',
    'listWebhookEndpoints',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Registers an endpoint, or updates the one already on this URL.
  ///
  /// The signing secret is generated here and encrypted before storage —
  /// unlike an API key, kola must recover this one to sign each delivery.
  _i2.Future<_i35.WebhookEndpoint> saveWebhookEndpoint(
    String accessToken,
    int workspaceId,
    String url,
    List<String> events,
  ) => caller.callServerEndpoint<_i35.WebhookEndpoint>(
    'platform',
    'saveWebhookEndpoint',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'url': url,
      'events': events,
    },
  );

  _i2.Future<void> deleteWebhookEndpoint(
    String accessToken,
    int workspaceId,
    int endpointId,
  ) => caller.callServerEndpoint<void>(
    'platform',
    'deleteWebhookEndpoint',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'endpointId': endpointId,
    },
  );
}

/// {@category Endpoint}
class EndpointProduct extends _i1.EndpointRef {
  EndpointProduct(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'product';

  _i2.Future<List<_i36.Product>> listProducts(
    String accessToken,
    int workspaceId, {
    required bool includeArchived,
  }) => caller.callServerEndpoint<List<_i36.Product>>(
    'product',
    'listProducts',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'includeArchived': includeArchived,
    },
  );

  _i2.Future<_i36.Product?> getProduct(
    String accessToken,
    int workspaceId,
    int productId,
  ) => caller.callServerEndpoint<_i36.Product?>(
    'product',
    'getProduct',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
    },
  );

  /// Variants for one product.
  ///
  /// Scoped through the product rather than queried directly: resolving
  /// the parent first is what proves the caller is entitled to it.
  _i2.Future<List<_i37.ProductVariant>> listVariants(
    String accessToken,
    int workspaceId,
    int productId,
  ) => caller.callServerEndpoint<List<_i37.ProductVariant>>(
    'product',
    'listVariants',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
    },
  );

  /// Creates a product.
  ///
  /// Note what is NOT a parameter: workspaceId comes from the argument
  /// and is checked, and status is not settable — a product is created
  /// active, and archiving is its own method with its own meaning.
  _i2.Future<_i36.Product> createProduct(
    String accessToken,
    int workspaceId,
    String name, {
    String? description,
    required String archetype,
    String? sku,
    String? category,
    int? priceMinor,
    String? priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    required int lowStockThreshold,
  }) => caller.callServerEndpoint<_i36.Product>(
    'product',
    'createProduct',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'description': description,
      'archetype': archetype,
      'sku': sku,
      'category': category,
      'priceMinor': priceMinor,
      'priceCurrency': priceCurrency,
      'priceUnit': priceUnit,
      'costMinor': costMinor,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
    },
  );

  /// Edits a product. Null means "leave it alone".
  ///
  /// Clearing a price or a stock count therefore needs its own signal,
  /// because null already means unchanged — [clearPrice] and
  /// [clearStock] exist for that. Without them there would be no way to
  /// turn a priced product into an on-request one, which is exactly what
  /// happens when a shop stops publishing a price.
  _i2.Future<_i36.Product> updateProduct(
    String accessToken,
    int workspaceId,
    int productId, {
    String? name,
    String? description,
    String? archetype,
    String? sku,
    String? category,
    int? priceMinor,
    required bool clearPrice,
    String? priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    required bool clearStock,
    int? lowStockThreshold,
  }) => caller.callServerEndpoint<_i36.Product>(
    'product',
    'updateProduct',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'name': name,
      'description': description,
      'archetype': archetype,
      'sku': sku,
      'category': category,
      'priceMinor': priceMinor,
      'clearPrice': clearPrice,
      'priceCurrency': priceCurrency,
      'priceUnit': priceUnit,
      'costMinor': costMinor,
      'stock': stock,
      'clearStock': clearStock,
      'lowStockThreshold': lowStockThreshold,
    },
  );

  /// Archives. Does NOT delete — see product.spy.yaml.
  _i2.Future<void> archiveProduct(
    String accessToken,
    int workspaceId,
    int productId,
  ) => caller.callServerEndpoint<void>(
    'product',
    'archiveProduct',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
    },
  );

  /// Replaces a product's variant set with exactly what is submitted.
  ///
  /// [labels], [stocks] and [priceMinors] are parallel lists rather than
  /// a list of a variant model, because Serverpod cannot take a list of
  /// a custom model as an endpoint parameter. Their lengths must match;
  /// a mismatch is a client bug and is refused rather than zipped to the
  /// shortest, which would silently drop a variant the owner entered.
  _i2.Future<List<_i37.ProductVariant>> replaceVariants(
    String accessToken,
    int workspaceId,
    int productId,
    List<String> labels,
    List<int?> stocks,
    List<int?> priceMinors,
  ) => caller.callServerEndpoint<List<_i37.ProductVariant>>(
    'product',
    'replaceVariants',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'labels': labels,
      'stocks': stocks,
      'priceMinors': priceMinors,
    },
  );

  /// GET-equivalent for /catalog/<workspaceId> — deliberately NO
  /// accessToken parameter. This is the one ProductEndpoint method a
  /// customer with no Kola account and no session can call, so it is
  /// gated on its own terms rather than reusing [_require]:
  ///
  ///   1. commerce.core + commerce.catalog (the capability exists at
  ///      all — same two flags every other method here checks)
  ///   2. commerce.public_catalog (this specific surface is released)
  ///   3. Workspace.publicCatalogEnabled (this specific business chose
  ///      to publish one — see migration 057's header on why this is a
  ///      separate, explicit opt-in from the flag above)
  ///
  /// All three fail the same way — a generic "not available" — rather
  /// than distinguishing which one failed, so a probe against a random
  /// workspaceId cannot learn anything about that workspace's flags or
  /// settings from the error alone.
  ///
  /// Returns [PublicCatalogItem] rows, never [Product] — see that
  /// model's own header on why costMinor and exact stock counts cannot
  /// simply be "not read" by a careful caller; they must not be on the
  /// wire at all.
  _i2.Future<_i38.PublicCatalog> getPublicCatalog(int workspaceId) =>
      caller.callServerEndpoint<_i38.PublicCatalog>(
        'product',
        'getPublicCatalog',
        {'workspaceId': workspaceId},
      );

  /// One-shot credentials so the BROWSER can upload straight to
  /// ImageKit.
  ///
  /// The file never passes through kola. See imagekit_service.dart for
  /// why: a Serverpod parameter is JSON, so proxying a 5MB photo would
  /// mean ~6.7MB of base64 crossing the wire twice with no way to report
  /// progress. The private key stays here and signs; the bytes go
  /// direct.
  ///
  /// Returned as a JSON string rather than a new model, the same shape
  /// getBillingSummary already uses — four short-lived strings do not
  /// earn a .spy.yaml and a codegen round.
  ///
  /// The folder is decided HERE, not by the client. A browser that could
  /// name its own folder could write into another workspace's.
  _i2.Future<String> getMediaUploadAuth(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<String>(
    'product',
    'getMediaUploadAuth',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  _i2.Future<List<_i39.ProductMedia>> listMedia(
    String accessToken,
    int workspaceId,
    int productId,
  ) => caller.callServerEndpoint<List<_i39.ProductMedia>>(
    'product',
    'listMedia',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
    },
  );

  /// Media for MANY products in one call.
  ///
  /// The catalog list shows a thumbnail per row and the design puts it
  /// first in the row — it is how an owner recognises a product at a
  /// glance, far faster than reading the name. Fetching per product
  /// would be a round trip per row: forty products, forty calls, on a
  /// connection where each costs 400ms.
  ///
  /// Returns a flat list; the caller groups by productId. Serverpod
  /// cannot return Map<int, List<Model>> across the wire, and inventing
  /// a wrapper model for a shape the client regroups in three lines
  /// would be a .spy.yaml and a codegen run for nothing.
  /// ── WHY A COMMA-SEPARATED STRING AND NOT List<int> ────────────────
  ///
  /// This took `List<int> productIds` and every call 500'd before the
  /// method body ran:
  ///
  ///   ERROR: No deserialization found for type List<int>
  ///   #2 parseParameters (endpoint_parameter_helper.dart:21)
  ///
  /// The generated protocol registers a deserializer per generic type,
  /// and whether `List<int>` is present has DRIFTED with unrelated
  /// edits. Counting `t == List<int>` in the generated protocol, by
  /// commit:
  ///
  ///   f7450bc  0   ← the commit that added this endpoint
  ///   f833f05  1
  ///   9b5c175  1
  ///   HEAD     2
  ///
  /// `List<String>` has been 2 throughout, which is why the sibling
  /// endpoints taking string lists always worked and this one silently
  /// did not.
  ///
  /// So this shipped with no deserializer at all, and thumbnails have
  /// NEVER loaded in the catalog list or in an answer's product cards —
  /// while the detail page, which calls listMedia(int), always worked.
  /// That split is what sent me chasing ImageKit transformations twice.
  /// The URLs were fine. The request never reached the method.
  ///
  /// I am deliberately NOT relying on the count being 2 today. Whatever
  /// pushed it from 0 to 1 was not this endpoint, and a type whose
  /// availability moves when unrelated files change is not a dependency
  /// worth having under a screen's main image.
  ///
  /// So the wire type is a String this endpoint parses itself. Uglier,
  /// and it cannot regress on someone else's edit.
  _i2.Future<List<_i39.ProductMedia>> listMediaForProducts(
    String accessToken,
    int workspaceId,
    String productIds,
  ) => caller.callServerEndpoint<List<_i39.ProductMedia>>(
    'product',
    'listMediaForProducts',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productIds': productIds,
    },
  );

  /// Records a file the browser has already put on ImageKit.
  ///
  /// Validated even though the values came from ImageKit rather than
  /// being typed by a person: this endpoint is reachable by anyone with
  /// a session, so a crafted call could otherwise point a product's
  /// "photo" at any URL on the internet — including one that changes
  /// after review. The url must sit under the configured ImageKit
  /// endpoint, and nothing else is accepted.
  _i2.Future<_i39.ProductMedia> addProductMedia(
    String accessToken,
    int workspaceId,
    int productId,
    String imagekitFileId,
    String url, {
    required String kind,
    String? thumbnailUrl,
    int? width,
    int? height,
  }) => caller.callServerEndpoint<_i39.ProductMedia>(
    'product',
    'addProductMedia',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'imagekitFileId': imagekitFileId,
      'url': url,
      'kind': kind,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
    },
  );

  /// Removes a photo from the product AND from ImageKit.
  ///
  /// The CDN delete is attempted first but is NOT allowed to block the
  /// row delete — see ImageKitService.deleteFile. An unreachable CDN
  /// must not stop an owner taking a photo off their own product; an
  /// orphaned file is a cost to reconcile, not a reason to refuse.
  _i2.Future<void> deleteProductMedia(
    String accessToken,
    int workspaceId,
    int productId,
    int mediaId,
  ) => caller.callServerEndpoint<void>(
    'product',
    'deleteProductMedia',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'mediaId': mediaId,
    },
  );

  /// Sets the display order. Index 0 becomes the main image.
  ///
  /// Comma-separated for the same reason as listMediaForProducts above:
  /// a `List<int>` parameter is only deserializable if something else in
  /// the project happens to register that type. This one has no caller
  /// yet, so it has never failed in production — which is exactly why it
  /// is worth fixing now rather than discovering it the first time an
  /// owner drags a photo.
  _i2.Future<void> reorderProductMedia(
    String accessToken,
    int workspaceId,
    int productId,
    String mediaIdsInOrder,
  ) => caller.callServerEndpoint<void>(
    'product',
    'reorderProductMedia',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'mediaIdsInOrder': mediaIdsInOrder,
    },
  );

  /// Imports a photo from a PUBLIC url and stores it on ImageKit.
  ///
  /// ── WHY THIS IS SEPARATE FROM addProductMedia ────────────────────
  ///
  /// addProductMedia records a file the BROWSER already uploaded, and
  /// refuses any url outside our own ImageKit endpoint — otherwise a
  /// crafted call could point a product's photo at any address on the
  /// internet, including one that changes after review.
  ///
  /// A CSV import has the opposite shape: the owner supplies a url they
  /// control (their old store, a shared drive, a stock library) and asks
  /// kola to take a copy. So the url is deliberately NOT ours, and the
  /// server fetches it — which also means the image stops depending on
  /// the source staying online.
  ///
  /// ── WHAT IT WILL NOT FETCH ───────────────────────────────────────
  ///
  /// http and https only, and nothing that resolves to a private
  /// address. Without that check this endpoint is a server-side request
  /// forgery tool: a caller could aim it at http://169.254.169.254 (the
  /// cloud metadata service) or at localhost and read whatever came
  /// back through the resulting image. The scheme and host checks below
  /// are the whole defence and are not optional.
  _i2.Future<_i39.ProductMedia?> importMediaFromUrl(
    String accessToken,
    int workspaceId,
    int productId,
    String sourceUrl,
  ) => caller.callServerEndpoint<_i39.ProductMedia?>(
    'product',
    'importMediaFromUrl',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'productId': productId,
      'sourceUrl': sourceUrl,
    },
  );
}

/// {@category Endpoint}
class EndpointReport extends _i1.EndpointRef {
  EndpointReport(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'report';

  /// [date] is any moment inside the day to report on — only its
  /// UTC calendar date is used (start-of-day to start-of-next-day).
  /// Defaults to today (server UTC) when omitted, which is the only
  /// case documents_page.dart currently calls with — a date picker for
  /// past days is a natural follow-up, not built here.
  _i2.Future<_i40.EndOfDayReport> getEndOfDayReport(
    String accessToken,
    int workspaceId, {
    DateTime? date,
  }) => caller.callServerEndpoint<_i40.EndOfDayReport>(
    'report',
    'getEndOfDayReport',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'date': date,
    },
  );
}

/// {@category Endpoint}
class EndpointSale extends _i1.EndpointRef {
  EndpointSale(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sale';

  /// Rings up one sale. [customerPhone]/[customerName] are optional —
  /// a walk-in cash sale with neither is a complete, normal sale (see
  /// sale.spy.yaml's header); when present they resolve or create a
  /// Customer through the same deterministic matcher every other intake
  /// path uses, so the till participates in the graph rather than
  /// sitting beside it.
  _i2.Future<_i41.Sale> ringUpSale(
    String accessToken,
    int workspaceId, {
    required String linesJson,
    required String paymentMethod,
    int? cashReceivedMinor,
    String? clientReference,
    String? customerPhone,
    String? customerName,
  }) => caller.callServerEndpoint<_i41.Sale>(
    'sale',
    'ringUpSale',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'linesJson': linesJson,
      'paymentMethod': paymentMethod,
      'cashReceivedMinor': cashReceivedMinor,
      'clientReference': clientReference,
      'customerPhone': customerPhone,
      'customerName': customerName,
    },
  );

  _i2.Future<List<_i41.Sale>> listSales(
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) => caller.callServerEndpoint<List<_i41.Sale>>(
    'sale',
    'listSales',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'limit': limit,
      'offset': offset,
    },
  );

  _i2.Future<List<_i42.SaleLine>> getSaleLines(
    String accessToken,
    int workspaceId,
    int saleId,
  ) => caller.callServerEndpoint<List<_i42.SaleLine>>(
    'sale',
    'getSaleLines',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'saleId': saleId,
    },
  );
}

/// {@category Endpoint}
class EndpointSupportTicket extends _i1.EndpointRef {
  EndpointSupportTicket(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'supportTicket';

  /// Every ticket for a workspace, newest first. [status] optionally
  /// narrows to one status (e.g. just the open queue).
  _i2.Future<List<_i9.SupportTicket>> list(
    String accessToken,
    int workspaceId, {
    String? status,
  }) => caller.callServerEndpoint<List<_i9.SupportTicket>>(
    'supportTicket',
    'list',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'status': status,
    },
  );

  /// Transitions a ticket's status — 'open' | 'inProgress' | 'resolved' |
  /// 'closed'. Setting to 'resolved'/'closed' stamps resolvedAt
  /// automatically (see SupportTicketRepository.setStatus); reopening
  /// back to 'open'/'inProgress' clears it.
  _i2.Future<_i9.SupportTicket> setStatus(
    String accessToken,
    int workspaceId,
    int ticketId,
    String status,
  ) => caller.callServerEndpoint<_i9.SupportTicket>(
    'supportTicket',
    'setStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'ticketId': ticketId,
      'status': status,
    },
  );
}

/// {@category Endpoint}
class EndpointTask extends _i1.EndpointRef {
  EndpointTask(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'task';

  /// Every task for a workspace — tasks_page.dart buckets these into
  /// the three kanban columns client-side by status.
  _i2.Future<List<_i43.Task>> list(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i43.Task>>(
    'task',
    'list',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Creates a task by hand — see file header on why this exists even
  /// though the design export itself only shows pre-populated cards.
  _i2.Future<_i43.Task> create(
    String accessToken,
    int workspaceId,
    String title, {
    required String priority,
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
  }) => caller.callServerEndpoint<_i43.Task>(
    'task',
    'create',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'title': title,
      'priority': priority,
      'sourceType': sourceType,
      'sourceFindingId': sourceFindingId,
      'assignee': assignee,
      'dueAt': dueAt,
    },
  );

  /// Moves a task between columns — 'todo' | 'in_progress' | 'done'.
  _i2.Future<_i43.Task> setStatus(
    String accessToken,
    int workspaceId,
    int taskId,
    String status,
  ) => caller.callServerEndpoint<_i43.Task>(
    'task',
    'setStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'taskId': taskId,
      'status': status,
    },
  );

  _i2.Future<void> delete(
    String accessToken,
    int workspaceId,
    int taskId,
  ) => caller.callServerEndpoint<void>(
    'task',
    'delete',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'taskId': taskId,
    },
  );
}

/// {@category Endpoint}
class EndpointTillDisplay extends _i1.EndpointRef {
  EndpointTillDisplay(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'tillDisplay';

  /// Called by till_page.dart on every cart mutation and screen
  /// transition — fire-and-forget from the dashboard's side (a failed
  /// push must never block a real sale; see that page's own comment on
  /// its call site). Authenticated: only staff signed into this
  /// workspace can write its display state.
  ///
  /// Deliberately NOT gated on FeatureKeys.commerceCustomerDisplay or
  /// Workspace.customerDisplayEnabled — writing a value nobody is
  /// reading yet is harmless, and gating the WRITE would mean flipping
  /// the toggle on needs the till's next cart change before the display
  /// shows anything, instead of showing already-current state
  /// immediately. getState below is where the real gate lives, same
  /// split ProductEndpoint.getPublicCatalog/its write path already use.
  _i2.Future<void> pushState(
    String accessToken,
    int workspaceId,
    String itemsJson,
    int subtotalMinor,
    String currency,
    String status,
  ) => caller.callServerEndpoint<void>(
    'tillDisplay',
    'pushState',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'itemsJson': itemsJson,
      'subtotalMinor': subtotalMinor,
      'currency': currency,
      'status': status,
    },
  );

  /// GET-equivalent for /display/<workspaceId>'s page — deliberately NO
  /// accessToken, same "the one method with no session" shape as
  /// ProductEndpoint.getPublicCatalog. Gated on both
  /// FeatureKeys.commerceCustomerDisplay AND Workspace
  /// .customerDisplayEnabled, both failures collapsed into the same
  /// generic error a probe against a random workspaceId cannot use to
  /// learn anything — see getPublicCatalog's own doc comment, same
  /// reasoning applied here.
  ///
  /// A workspace whose till has never pushed a single state (no row in
  /// till_display_state yet) reads as the same honest empty/idle state
  /// a fresh row would represent, rather than an error — the display is
  /// meant to be left open on a screen well before the first sale of
  /// the day, not opened only once a sale is already in progress.
  _i2.Future<_i44.TillDisplayState> getState(int workspaceId) =>
      caller.callServerEndpoint<_i44.TillDisplayState>(
        'tillDisplay',
        'getState',
        {'workspaceId': workspaceId},
      );
}

/// {@category Endpoint}
class EndpointWaitlist extends _i1.EndpointRef {
  EndpointWaitlist(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'waitlist';

  /// Records a waitlist signup from the landing page. [source] identifies
  /// which on-page form submitted it ('hero' | 'waitlist_section' |
  /// 'footer') — see kola_landing's components for the three call sites.
  ///
  /// A basic shape check on [email] happens here rather than trusting the
  /// browser's <input type="email"> alone, since this endpoint is public
  /// and reachable by anything, not just our own landing page.
  _i2.Future<_i45.WaitlistSignup> joinWaitlist(
    String email,
    String source, {
    String? name,
    String? phone,
    String? businessType,
  }) => caller.callServerEndpoint<_i45.WaitlistSignup>(
    'waitlist',
    'joinWaitlist',
    {
      'email': email,
      'source': source,
      'name': name,
      'phone': phone,
      'businessType': businessType,
    },
  );
}

/// {@category Endpoint}
class EndpointWhatsAppTemplate extends _i1.EndpointRef {
  EndpointWhatsAppTemplate(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'whatsAppTemplate';

  /// The general-purpose submission path — [category] must be one of
  /// 'utility' | 'marketing' | 'authentication'. Most callers (the
  /// dashboard's "Create a template" flow) should be able to use this
  /// directly; [createProductListTemplate] below is a thin convenience
  /// wrapper for the one shape the owner specifically asked for.
  /// Auth-checked here, then delegated to WhatsAppTemplateCreationService
  /// — see this file's header.
  _i2.Future<_i46.WhatsAppMessageTemplate> createTemplate(
    String accessToken,
    int workspaceId,
    int channelId,
    String label,
    String category,
    String language,
    String bodyText,
    List<String> bodyExampleValues,
  ) => caller.callServerEndpoint<_i46.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'createTemplate',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'channelId': channelId,
      'label': label,
      'category': category,
      'language': language,
      'bodyText': bodyText,
      'bodyExampleValues': bodyExampleValues,
    },
  );

  /// Convenience wrapper for the specific case the owner asked about:
  /// "a business wants to send a list of products without it costing
  /// them a lot." Frames the body as an explicit reply to a customer
  /// request (the honest 'utility' use case — see this file's header)
  /// rather than a cold pitch, which both fits 'utility' review
  /// criteria better AND is what most product-list sends actually are
  /// in practice: a customer asked, the business is following up.
  ///
  /// [customerNameExample]/[productListExample] are just the example
  /// values Meta's review requires for the two placeholders — not sent
  /// to any real customer, only shown to Meta's reviewer alongside the
  /// template.
  _i2.Future<_i46.WhatsAppMessageTemplate> createProductListTemplate(
    String accessToken,
    int workspaceId,
    int channelId,
    String businessLabel,
    String customerNameExample,
    String productListExample,
  ) => caller.callServerEndpoint<_i46.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'createProductListTemplate',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'channelId': channelId,
      'businessLabel': businessLabel,
      'customerNameExample': customerNameExample,
      'productListExample': productListExample,
    },
  );

  /// Every template submitted for this workspace, newest first — the
  /// dashboard's template status list.
  _i2.Future<List<_i46.WhatsAppMessageTemplate>> listTemplatesForWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<List<_i46.WhatsAppMessageTemplate>>(
    'whatsAppTemplate',
    'listTemplatesForWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Polls Meta for [templateId]'s current review outcome and persists
  /// any change — see whatsapp_template_service.dart's header on why
  /// this is polling, not a webhook, for now.
  _i2.Future<_i46.WhatsAppMessageTemplate> refreshTemplateStatus(
    String accessToken,
    int workspaceId,
    int templateId,
  ) => caller.callServerEndpoint<_i46.WhatsAppMessageTemplate>(
    'whatsAppTemplate',
    'refreshTemplateStatus',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'templateId': templateId,
    },
  );
}

/// {@category Endpoint}
class EndpointWorkspace extends _i1.EndpointRef {
  EndpointWorkspace(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'workspace';

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
  _i2.Future<_i10.Workspace> createWorkspace(
    String accessToken,
    String name,
    String? industryTag, {
    String? ownerName,
    String? ownerPhone,
  }) => caller.callServerEndpoint<_i10.Workspace>(
    'workspace',
    'createWorkspace',
    {
      'accessToken': accessToken,
      'name': name,
      'industryTag': industryTag,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
    },
  );

  /// Every workspace the caller belongs to, for the dashboard's workspace
  /// switcher (relevant now for a user with zero or one workspace, and
  /// unchanged when the agency/multi-workspace tier adds more).
  _i2.Future<List<_i10.Workspace>> listMyWorkspaces(String accessToken) =>
      caller.callServerEndpoint<List<_i10.Workspace>>(
        'workspace',
        'listMyWorkspaces',
        {'accessToken': accessToken},
      );

  /// Fetch one workspace by id — access-checked, so a user can never read
  /// a workspace they're not a member of by guessing an id.
  _i2.Future<_i10.Workspace> getWorkspace(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<_i10.Workspace>(
    'workspace',
    'getWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

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
  _i2.Future<_i10.Workspace> updateWorkspace(
    String accessToken,
    int workspaceId, {
    String? name,
    String? industryTag,
    String? ownerName,
    bool? sellsCatalogItems,
    bool? publicCatalogEnabled,
    bool? customerDisplayEnabled,
  }) => caller.callServerEndpoint<_i10.Workspace>(
    'workspace',
    'updateWorkspace',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'name': name,
      'industryTag': industryTag,
      'ownerName': ownerName,
      'sellsCatalogItems': sellsCatalogItems,
      'publicCatalogEnabled': publicCatalogEnabled,
      'customerDisplayEnabled': customerDisplayEnabled,
    },
  );

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
  _i2.Future<String> getBillingSummary(
    String accessToken,
    int workspaceId,
  ) => caller.callServerEndpoint<String>(
    'workspace',
    'getBillingSummary',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
    },
  );

  /// Task #148 — starts a checkout for [workspaceId] to upgrade to
  /// Kola's paid ('pro') plan, using KOLA'S OWN Paystack/Flutterwave
  /// account (see KolaBillingService's header for why this is a
  /// separate flow from PaymentEndpoint.initializeCheckout, which is a
  /// workspace collecting from ITS OWN customers). [customerEmail] is
  /// the signed-in dashboard user's email — the gateway needs an email
  /// on file for the checkout page/receipt regardless of who's paying.
  _i2.Future<_i47.KolaBillingCheckout> initiateUpgrade(
    String accessToken,
    int workspaceId,
    String gateway,
    String customerEmail,
  ) => caller.callServerEndpoint<_i47.KolaBillingCheckout>(
    'workspace',
    'initiateUpgrade',
    {
      'accessToken': accessToken,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'customerEmail': customerEmail,
    },
  );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i48.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    adminAccounts = EndpointAdminAccounts(this);
    adminAnnouncement = EndpointAdminAnnouncement(this);
    adminAuditLog = EndpointAdminAuditLog(this);
    adminAuth = EndpointAdminAuth(this);
    adminDiagnostics = EndpointAdminDiagnostics(this);
    adminFeature = EndpointAdminFeature(this);
    adminOverview = EndpointAdminOverview(this);
    adminPlatform = EndpointAdminPlatform(this);
    adminSupport = EndpointAdminSupport(this);
    adminWorkspace = EndpointAdminWorkspace(this);
    analytics = EndpointAnalytics(this);
    bot = EndpointBot(this);
    broadcast = EndpointBroadcast(this);
    channel = EndpointChannel(this);
    connector = EndpointConnector(this);
    conversation = EndpointConversation(this);
    customer = EndpointCustomer(this);
    customerProfile = EndpointCustomerProfile(this);
    errand = EndpointErrand(this);
    feature = EndpointFeature(this);
    finding = EndpointFinding(this);
    invoice = EndpointInvoice(this);
    knowledge = EndpointKnowledge(this);
    ownerNotification = EndpointOwnerNotification(this);
    payment = EndpointPayment(this);
    platform = EndpointPlatform(this);
    product = EndpointProduct(this);
    report = EndpointReport(this);
    sale = EndpointSale(this);
    supportTicket = EndpointSupportTicket(this);
    task = EndpointTask(this);
    tillDisplay = EndpointTillDisplay(this);
    waitlist = EndpointWaitlist(this);
    whatsAppTemplate = EndpointWhatsAppTemplate(this);
    workspace = EndpointWorkspace(this);
  }

  late final EndpointAdminAccounts adminAccounts;

  late final EndpointAdminAnnouncement adminAnnouncement;

  late final EndpointAdminAuditLog adminAuditLog;

  late final EndpointAdminAuth adminAuth;

  late final EndpointAdminDiagnostics adminDiagnostics;

  late final EndpointAdminFeature adminFeature;

  late final EndpointAdminOverview adminOverview;

  late final EndpointAdminPlatform adminPlatform;

  late final EndpointAdminSupport adminSupport;

  late final EndpointAdminWorkspace adminWorkspace;

  late final EndpointAnalytics analytics;

  late final EndpointBot bot;

  late final EndpointBroadcast broadcast;

  late final EndpointChannel channel;

  late final EndpointConnector connector;

  late final EndpointConversation conversation;

  late final EndpointCustomer customer;

  late final EndpointCustomerProfile customerProfile;

  late final EndpointErrand errand;

  late final EndpointFeature feature;

  late final EndpointFinding finding;

  late final EndpointInvoice invoice;

  late final EndpointKnowledge knowledge;

  late final EndpointOwnerNotification ownerNotification;

  late final EndpointPayment payment;

  late final EndpointPlatform platform;

  late final EndpointProduct product;

  late final EndpointReport report;

  late final EndpointSale sale;

  late final EndpointSupportTicket supportTicket;

  late final EndpointTask task;

  late final EndpointTillDisplay tillDisplay;

  late final EndpointWaitlist waitlist;

  late final EndpointWhatsAppTemplate whatsAppTemplate;

  late final EndpointWorkspace workspace;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'adminAccounts': adminAccounts,
    'adminAnnouncement': adminAnnouncement,
    'adminAuditLog': adminAuditLog,
    'adminAuth': adminAuth,
    'adminDiagnostics': adminDiagnostics,
    'adminFeature': adminFeature,
    'adminOverview': adminOverview,
    'adminPlatform': adminPlatform,
    'adminSupport': adminSupport,
    'adminWorkspace': adminWorkspace,
    'analytics': analytics,
    'bot': bot,
    'broadcast': broadcast,
    'channel': channel,
    'connector': connector,
    'conversation': conversation,
    'customer': customer,
    'customerProfile': customerProfile,
    'errand': errand,
    'feature': feature,
    'finding': finding,
    'invoice': invoice,
    'knowledge': knowledge,
    'ownerNotification': ownerNotification,
    'payment': payment,
    'platform': platform,
    'product': product,
    'report': report,
    'sale': sale,
    'supportTicket': supportTicket,
    'task': task,
    'tillDisplay': tillDisplay,
    'waitlist': waitlist,
    'whatsAppTemplate': whatsAppTemplate,
    'workspace': workspace,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
