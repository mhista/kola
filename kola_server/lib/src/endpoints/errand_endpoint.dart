// errand_endpoint.dart
//
// Phase 3b/3c's dashboard/dev-facing surface for the Errand system
// (SRS.md §7). Mirrors BotEndpoint's shape exactly: requireWorkspaceAccess
// on every method, findByIdScoped before any mutation, Log.success on
// writes.
//
// THREE CREATE METHODS, ONE PER FULFILLMENT TYPE THAT HAS SHIPPED:
// createBuiltinErrand (3b), createWebhookErrand and createDbCredentialErrand
// (3c) — kept separate rather than one createErrand(source, ...) with a
// big optional-parameter grab-bag, since each type's required fields are
// genuinely different (a builtinHandlerKey vs. a webhook URL vs. a
// connection string + query template) and Dart has no clean way to make
// "these three params are required together, mutually exclusive with
// those other three" a compile-time guarantee. 'mcp' has no create method
// yet — genuinely unimplemented (see errand.spy.yaml's header), not a
// stub pretending otherwise.
//
// ONE EXECUTE METHOD, executeErrand, DISPATCHING BY errand.source: unlike
// the create side, execution doesn't need type-specific parameters (every
// executor takes the same errand + input shape), so one method that reads
// errand.source and picks the right executor is simpler than three
// near-identical execute methods. executeBuiltinErrand (3b) is kept
// alongside it for backward compatibility with anything already calling
// it directly — both paths log identically via each executor's own
// ErrandExecutionLogRepository call.
//
// TASK #134 — THE DISPATCH-BY-SOURCE SWITCH NOW LIVES IN
// ErrandDispatchService, NOT HERE: extracted (same pattern as task #128's
// PaymentCheckoutService extraction) so the AI tool-calling engine
// (InboundMessageHandler, running without a Session) can dispatch an
// Errand the exact same way this Session-authenticated endpoint does.
// executeErrand still does everything around dispatch itself — access
// check, status check, security filter — dispatch is the one part now
// shared.
//
// deleteErrand — ONLY WHEN DISABLED: an owner asked directly for disabled
// Errands to be deletable. Requires status == 'disabled' first (call
// setErrandStatus), same two-step guard rail as every other destructive
// flow in this codebase.

import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/repository/errand_repository.dart';
import 'package:kola_server/src/services/repository/errand_credential_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/errand/builtin_errand_executor.dart';
import 'package:kola_server/src/services/errand/errand_dispatch_service.dart';
import 'package:kola_server/src/services/errand/webhook_errand_credential.dart';
import 'package:kola_server/src/services/errand/db_credential_errand_credential.dart';
import 'package:kola_server/src/services/security/channel_credential_encryption_service.dart';
import 'package:kola_server/src/services/security/security_filter.dart';
import 'package:kola_server/kola_logger.dart';

const _validCreatedVia = {'naturalLanguage', 'api'};
const _validPermissionScopes = {'readOnly', 'readWrite'};
const _validStatuses = {'active', 'disabled'};

class ErrandEndpoint extends Endpoint {
  ErrandRepository get _errands => getIt<ErrandRepository>();
  ErrandCredentialRepository get _credentials => getIt<ErrandCredentialRepository>();
  BuiltinErrandExecutor get _builtinExecutor => getIt<BuiltinErrandExecutor>();
  // TASK #134 — _webhookExecutor/_dbCredentialExecutor used to live here
  // as getters for executeErrand's own inline dispatch switch; that
  // switch is now ErrandDispatchService (see _dispatch below), so those
  // two getters were removed as dead code rather than left unused.
  ErrandDispatchService get _dispatch => getIt<ErrandDispatchService>();
  SecurityFilter get _security => getIt<SecurityFilter>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  TrialStateMachine get _trialStateMachine => getIt<TrialStateMachine>();

  /// Phase 5 plan limits — a cappedFree or paused workspace may have at
  /// most PlanLimits.cappedFreeErrandCap ACTIVE Errands (confirmed with
  /// the user, not guessed — see plan_limits.dart). Called from every
  /// create* method below, right after requireWorkspaceAccess, so a
  /// workspace over its cap fails fast with a clear message instead of
  /// creating the Errand and only then having nowhere to enforce the cap
  /// retroactively. fullTrial/paid workspaces are never gated here.
  Future<void> _assertErrandCapNotExceeded(int workspaceId) async {
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) return; // caller's own findByIdScoped calls will surface this properly
    final tier = _trialStateMachine.effectiveTier(workspace);
    if (tier != EffectiveTier.cappedFree && tier != EffectiveTier.paused) return;

    final activeCount = (await _errands.listActiveByWorkspace(workspaceId)).length;
    if (activeCount >= PlanLimits.cappedFreeErrandCap) {
      throw KolaException(
        message:         'This workspace is on the free plan, which allows up to '
        '${PlanLimits.cappedFreeErrandCap} active Errands. Disable an existing '
        'Errand or upgrade to add more.',
      );
    }
  }

  /// Registers a new built-in Errand — see file header on why only
  /// 'builtin' is accepted today. [builtinHandlerKey] must match one of
  /// BuiltinErrandExecutor's registered handlers (currently just
  /// 'escalateToHuman') — validated against Meta... no, against that
  /// registry directly, so a typo'd key fails here with a clear message
  /// instead of at first invocation.
  Future<Errand> createBuiltinErrand(
    Session session,
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String builtinHandlerKey,
    String createdVia, {
    String permissionScope = 'readOnly',
    String inputSchemaJson = '{}',
    String sensitiveInputKeysJson = '[]',
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _assertErrandCapNotExceeded(workspaceId);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Errand name cannot be empty.');
    }
    if (descriptionForAi.trim().isEmpty) {
      throw KolaException(
        message:         'descriptionForAi cannot be empty — this is what the AI orchestrator '
        'reads to decide when to invoke this Errand.',
      );
    }
    if (!BuiltinErrandExecutor.handlerKeys.contains(builtinHandlerKey)) {
      throw KolaException(
        message:         'Unknown builtinHandlerKey "$builtinHandlerKey" — must be one of: '
        '${BuiltinErrandExecutor.handlerKeys.join(", ")}',
      );
    }
    if (!_validCreatedVia.contains(createdVia)) {
      throw KolaException(message: 'Invalid createdVia "$createdVia" — must be one of: naturalLanguage, api');
    }
    if (!_validPermissionScopes.contains(permissionScope)) {
      throw KolaException(
        message:         'Invalid permissionScope "$permissionScope" — must be one of: readOnly, readWrite',
      );
    }
    _assertValidJson(inputSchemaJson, 'inputSchemaJson');
    _assertValidJson(sensitiveInputKeysJson, 'sensitiveInputKeysJson');

    final errand = await _errands.create(
      workspaceId: workspaceId,
      name: trimmedName,
      descriptionForAi: descriptionForAi.trim(),
      source: 'builtin',
      builtinHandlerKey: builtinHandlerKey,
      createdVia: createdVia,
      permissionScope: permissionScope,
      inputSchemaJson: inputSchemaJson,
      sensitiveInputKeysJson: sensitiveInputKeysJson,
    );

    Log.success(
      'Errand created',
      data: {'workspaceId': workspaceId, 'errandId': errand.id, 'builtinHandlerKey': builtinHandlerKey},
      session: session,
    );

    return errand;
  }

  /// Every Errand belonging to a workspace, regardless of status.
  Future<List<Errand>> listErrandsForWorkspace(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    return _errands.listByWorkspace(workspaceId);
  }

  /// Fetch one Errand by id — access-checked via its workspace, same
  /// posture as BotEndpoint.getBot.
  Future<Errand> getErrand(
    Session session,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    final errand = await _errands.findByIdScoped(errandId, workspaceId);
    if (errand == null) {
      throw KolaException(message: 'Errand $errandId not found in workspace $workspaceId');
    }
    return errand;
  }

  /// Toggle an Errand active/disabled without deleting its history/logs.
  Future<Errand> setErrandStatus(
    Session session,
    String accessToken,
    int workspaceId,
    int errandId,
    String status,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    if (!_validStatuses.contains(status)) {
      throw KolaException(message: 'Invalid status "$status" — must be one of: active, disabled');
    }

    final existing = await _errands.findByIdScoped(errandId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Errand $errandId not found in workspace $workspaceId');
    }

    final updated = await _errands.setStatus(errandId, status);

    Log.success(
      'Errand status updated',
      data: {'workspaceId': workspaceId, 'errandId': errandId, 'status': status},
      session: session,
    );

    return updated;
  }

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
  Future<void> deleteErrand(
    Session session,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final existing = await _errands.findByIdScoped(errandId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'Errand $errandId not found in workspace $workspaceId');
    }
    if (existing.status != 'disabled') {
      throw KolaException(
        message:         'Errand $errandId is still active — disable it first (setErrandStatus) before deleting it.',
      );
    }

    await _credentials.deleteForErrand(errandId);
    await _errands.delete(errandId);

    Log.success(
      'Errand deleted',
      data: {'workspaceId': workspaceId, 'errandId': errandId},
      session: session,
    );
  }

  /// Runs a 'builtin' Errand right now, synchronously, and returns its
  /// result as a JSON string — same "flexible shape lives in a JSON
  /// string" pattern as inputSchemaJson, since a raw `Map<String,dynamic>`
  /// isn't a type Serverpod's codegen can safely serialize. [inputJson]
  /// is a JSON-encoded Map matching the Errand's inputSchemaJson shape.
  /// Every invocation is logged (success or failure) by
  /// BuiltinErrandExecutor before this method returns/throws — see its
  /// file header.
  Future<String> executeBuiltinErrand(
    Session session,
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final errand = await _errands.findByIdScoped(errandId, workspaceId);
    if (errand == null) {
      throw KolaException(message: 'Errand $errandId not found in workspace $workspaceId');
    }
    if (errand.status != 'active') {
      throw KolaException(message: 'Errand $errandId is disabled — cannot execute.');
    }

    Map<String, dynamic> input;
    try {
      input = jsonDecode(inputJson) as Map<String, dynamic>;
    } catch (e) {
      throw KolaException(message: 'inputJson is not valid JSON: $e');
    }

    // Phase 3d (SRS.md §10): security filter runs before ANY Errand
    // call — see security_filter.dart's header.
    final securityCheck = _security.checkErrandInput(input);
    if (!securityCheck.allowed) {
      throw KolaException(
        message:         'Errand input rejected by security filter (${securityCheck.violationType}): '
        '${securityCheck.warningMessage}',
      );
    }

    final result = await _builtinExecutor.execute(errand: errand, input: input);

    Log.success(
      'Errand executed',
      data: {'workspaceId': workspaceId, 'errandId': errandId},
      session: session,
    );

    return jsonEncode(result);
  }

  /// Registers a new webhook-backed Errand AND collects/encrypts its
  /// credential in one call — a business connecting a webhook Errand
  /// shouldn't be left with a half-registered Errand that has nowhere
  /// to send its calls. [webhookUrl] must be a valid absolute URL (any
  /// scheme — https strongly recommended, but not enforced here, since
  /// local dev/testing against plain http is a real, legitimate case).
  /// [authHeaderName]/[authHeaderValue] are optional and sent together
  /// or not at all — see webhook_errand_credential.dart.
  Future<Errand> createWebhookErrand(
    Session session,
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String webhookUrl, {
    String? authHeaderName,
    String? authHeaderValue,
    String permissionScope = 'readOnly',
    String inputSchemaJson = '{}',
    String sensitiveInputKeysJson = '[]',
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _assertErrandCapNotExceeded(workspaceId);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Errand name cannot be empty.');
    }
    if (descriptionForAi.trim().isEmpty) {
      throw KolaException(
        message:         'descriptionForAi cannot be empty — this is what the AI orchestrator '
        'reads to decide when to invoke this Errand.',
      );
    }
    final parsedUrl = Uri.tryParse(webhookUrl);
    if (parsedUrl == null || !parsedUrl.isAbsolute) {
      throw KolaException(message: 'webhookUrl "$webhookUrl" is not a valid absolute URL.');
    }
    if (!_validCreatedVia.contains(createdVia)) {
      throw KolaException(message: 'Invalid createdVia "$createdVia" — must be one of: naturalLanguage, api');
    }
    if (!_validPermissionScopes.contains(permissionScope)) {
      throw KolaException(
        message:         'Invalid permissionScope "$permissionScope" — must be one of: readOnly, readWrite',
      );
    }
    _assertValidJson(inputSchemaJson, 'inputSchemaJson');
    _assertValidJson(sensitiveInputKeysJson, 'sensitiveInputKeysJson');

    final errand = await _errands.create(
      workspaceId: workspaceId,
      name: trimmedName,
      descriptionForAi: descriptionForAi.trim(),
      source: 'webhook',
      createdVia: createdVia,
      permissionScope: permissionScope,
      inputSchemaJson: inputSchemaJson,
      sensitiveInputKeysJson: sensitiveInputKeysJson,
    );

    final credential = WebhookErrandCredential(
      url: webhookUrl,
      authHeaderName: authHeaderName,
      authHeaderValue: authHeaderValue,
    );
    final encrypted = ChannelCredentialEncryptionService.encrypt(credential.encode());
    await _credentials.upsert(errandId: errand.id!, encryptedCredential: encrypted);

    Log.success(
      'Webhook errand created',
      data: {'workspaceId': workspaceId, 'errandId': errand.id},
      session: session,
    );

    return errand;
  }

  /// Registers a new database-credential Errand AND collects/encrypts
  /// its connection string in one call — same "never half-registered"
  /// reasoning as createWebhookErrand. [queryTemplateSql] is the ONE
  /// pre-approved named-parameter query this Errand will ever run (see
  /// errand.spy.yaml's queryTemplateSql header) — if [permissionScope]
  /// is 'readOnly' (the default), it must start with SELECT, checked
  /// here at registration time AND again at execution time by
  /// DbCredentialErrandExecutor (defense in depth against the template
  /// being edited later without a matching permission upgrade).
  Future<Errand> createDbCredentialErrand(
    Session session,
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String createdVia,
    String queryTemplateSql,
    String connectionString, {
    String permissionScope = 'readOnly',
    String inputSchemaJson = '{}',
    String sensitiveInputKeysJson = '[]',
  }) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);
    await _assertErrandCapNotExceeded(workspaceId);

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw KolaException(message: 'Errand name cannot be empty.');
    }
    if (descriptionForAi.trim().isEmpty) {
      throw KolaException(
        message:         'descriptionForAi cannot be empty — this is what the AI orchestrator '
        'reads to decide when to invoke this Errand.',
      );
    }
    if (queryTemplateSql.trim().isEmpty) {
      throw KolaException(message: 'queryTemplateSql cannot be empty.');
    }
    if (connectionString.trim().isEmpty) {
      throw KolaException(message: 'connectionString cannot be empty.');
    }
    if (!_validCreatedVia.contains(createdVia)) {
      throw KolaException(message: 'Invalid createdVia "$createdVia" — must be one of: naturalLanguage, api');
    }
    if (!_validPermissionScopes.contains(permissionScope)) {
      throw KolaException(
        message:         'Invalid permissionScope "$permissionScope" — must be one of: readOnly, readWrite',
      );
    }
    if (permissionScope == 'readOnly' && !queryTemplateSql.trim().toLowerCase().startsWith('select')) {
      throw KolaException(
        message:         'queryTemplateSql must start with SELECT when permissionScope is readOnly. '
        'Set permissionScope to readWrite if this query is intentional.',
      );
    }
    _assertValidJson(inputSchemaJson, 'inputSchemaJson');
    _assertValidJson(sensitiveInputKeysJson, 'sensitiveInputKeysJson');

    final errand = await _errands.create(
      workspaceId: workspaceId,
      name: trimmedName,
      descriptionForAi: descriptionForAi.trim(),
      source: 'dbCredential',
      createdVia: createdVia,
      permissionScope: permissionScope,
      inputSchemaJson: inputSchemaJson,
      sensitiveInputKeysJson: sensitiveInputKeysJson,
      queryTemplateSql: queryTemplateSql,
    );

    final credential = DbCredentialErrandCredential(connectionString: connectionString);
    final encrypted = ChannelCredentialEncryptionService.encrypt(credential.encode());
    await _credentials.upsert(errandId: errand.id!, encryptedCredential: encrypted);

    Log.success(
      'DB-credential errand created',
      data: {'workspaceId': workspaceId, 'errandId': errand.id},
      session: session,
    );

    return errand;
  }

  /// Runs ANY Errand right now, synchronously, dispatching to the right
  /// executor by errand.source — see file header on why this is one
  /// method rather than three. Same JSON-string-in/JSON-string-out
  /// contract as executeBuiltinErrand.
  Future<String> executeErrand(
    Session session,
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) async {
    await requireWorkspaceAccess(accessToken: accessToken, workspaceId: workspaceId);

    final errand = await _errands.findByIdScoped(errandId, workspaceId);
    if (errand == null) {
      throw KolaException(message: 'Errand $errandId not found in workspace $workspaceId');
    }
    if (errand.status != 'active') {
      throw KolaException(message: 'Errand $errandId is disabled — cannot execute.');
    }

    Map<String, dynamic> input;
    try {
      input = jsonDecode(inputJson) as Map<String, dynamic>;
    } catch (e) {
      throw KolaException(message: 'inputJson is not valid JSON: $e');
    }

    // Phase 3d (SRS.md §10): security filter runs before ANY Errand
    // call, regardless of fulfillment type — see security_filter.dart's
    // header.
    final securityCheck = _security.checkErrandInput(input);
    if (!securityCheck.allowed) {
      throw KolaException(
        message:         'Errand input rejected by security filter (${securityCheck.violationType}): '
        '${securityCheck.warningMessage}',
      );
    }

    // TASK #134 — this used to be an inline switch over
    // _builtinExecutor/_webhookExecutor/_dbCredentialExecutor; extracted
    // into ErrandDispatchService so the new AI tool-calling engine
    // (InboundMessageHandler) can run the exact same dispatch logic
    // without a Session — see that file's header.
    final result = await _dispatch.dispatch(errand: errand, input: input);

    Log.success(
      'Errand executed',
      data: {'workspaceId': workspaceId, 'errandId': errandId, 'source': errand.source},
      session: session,
    );

    return jsonEncode(result);
  }

  void _assertValidJson(String value, String fieldName) {
    try {
      jsonDecode(value);
    } catch (e) {
      throw KolaException(message: '$fieldName is not valid JSON: $e');
    }
  }
}
