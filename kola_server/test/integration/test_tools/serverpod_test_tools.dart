/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: no_leading_underscores_for_local_identifiers

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_test/serverpod_test.dart' as _i1;
import 'package:serverpod/serverpod.dart' as _i2;
import 'dart:async' as _i3;
import 'package:kola_server/src/generated/conversation.dart' as _i4;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i5;
import 'package:kola_server/src/generated/feature_flag.dart' as _i6;
import 'package:kola_server/src/generated/workspace_feature_override.dart'
    as _i7;
import 'package:kola_server/src/generated/support_ticket.dart' as _i8;
import 'package:kola_server/src/generated/workspace.dart' as _i9;
import 'package:kola_server/src/generated/bot.dart' as _i10;
import 'package:kola_server/src/generated/channel.dart' as _i11;
import 'package:kola_server/src/generated/broadcast.dart' as _i12;
import 'package:kola_server/src/generated/broadcast_progress.dart' as _i13;
import 'package:kola_server/src/generated/message_suppression.dart' as _i14;
import 'package:kola_server/src/generated/connector_status.dart' as _i15;
import 'package:kola_server/src/generated/google_drive_spreadsheet.dart'
    as _i16;
import 'package:kola_server/src/generated/calendar_booking.dart' as _i17;
import 'package:kola_server/src/generated/message.dart' as _i18;
import 'package:kola_server/src/generated/customer.dart' as _i19;
import 'package:kola_server/src/generated/customer_detail.dart' as _i20;
import 'package:kola_server/src/generated/customer_merge_proposal.dart' as _i21;
import 'package:kola_server/src/generated/errand.dart' as _i22;
import 'package:kola_server/src/generated/workspace_finding.dart' as _i23;
import 'package:kola_server/src/generated/invoice.dart' as _i24;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i25;
import 'package:kola_server/src/generated/workspace_answer.dart' as _i26;
import 'package:kola_server/src/generated/owner_notification_settings.dart'
    as _i27;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i28;
import 'package:kola_server/src/generated/payment_transaction.dart' as _i29;
import 'package:kola_server/src/generated/api_key.dart' as _i30;
import 'package:kola_server/src/generated/created_api_key.dart' as _i31;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i32;
import 'package:kola_server/src/generated/product.dart' as _i33;
import 'package:kola_server/src/generated/product_variant.dart' as _i34;
import 'package:kola_server/src/generated/product_media.dart' as _i35;
import 'package:kola_server/src/generated/end_of_day_report.dart' as _i36;
import 'package:kola_server/src/generated/sale.dart' as _i37;
import 'package:kola_server/src/generated/sale_line.dart' as _i38;
import 'package:kola_server/src/generated/waitlist_signup.dart' as _i39;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i40;
import 'package:kola_server/src/generated/kola_billing_checkout.dart' as _i41;
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/generated/endpoints.dart';
export 'package:serverpod_test/serverpod_test_public_exports.dart';

/// Creates a new test group that takes a callback that can be used to write tests.
/// The callback has two parameters: `sessionBuilder` and `endpoints`.
/// `sessionBuilder` is used to build a `Session` object that represents the server state during an endpoint call and is used to set up scenarios.
/// `endpoints` contains all your Serverpod endpoints and lets you call them:
/// ```dart
/// withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
///   test('when calling `hello` then should return greeting', () async {
///     final greeting = await endpoints.example.hello(sessionBuilder, 'Michael');
///     expect(greeting, 'Hello Michael');
///   });
/// });
/// ```
///
/// **Configuration options**
///
/// [enableSessionLogging] Whether session logging should be enabled. Defaults to `false`
///
/// [runMode] The run mode that Serverpod should be running in. Defaults to `test`.
///
/// [serverpodLoggingMode] The logging mode used when creating Serverpod. Defaults to `ServerpodLoggingMode.normal`
///
/// [serverpodStartTimeout] The timeout to use when starting Serverpod, which connects to the database among other things. Defaults to `Duration(seconds: 30)`.
///
/// [testServerOutputMode] Options for controlling test server output during test execution. Defaults to `TestServerOutputMode.normal`.
/// ```dart
/// /// Options for controlling test server output during test execution.
/// enum TestServerOutputMode {
///   /// Default mode - only stderr is printed (stdout suppressed).
///   /// This hides normal startup/shutdown logs while preserving error messages.
///   normal,
///
///   /// All logging - both stdout and stderr are printed.
///   /// Useful for debugging when you need to see all server output.
///   verbose,
///
///   /// No logging - both stdout and stderr are suppressed.
///   /// Completely silent mode, useful when you don't want any server output.
///   silent,
/// }
/// ```
///
/// [configOverride] A function to override the server configuration. This function is called with
/// the default server configuration after it is loaded from the config/ directory
/// and before it is used to start the server. Use this to override particular
/// settings in the server configuration.
///
/// [testGroupTagsOverride] By default Serverpod test tools tags the `withServerpod` test group with `"integration"`.
/// This is to provide a simple way to only run unit or integration tests.
/// This property allows this tag to be overridden to something else. Defaults to `['integration']`.
///
/// [experimentalFeatures] Optionally specify experimental features. See [Serverpod] for more information.
@_i1.isTestGroup
void withServerpod(
  String testGroupName,
  _i1.TestClosure<TestEndpoints> testClosure, {
  _i2.ServerpodConfig Function(_i2.ServerpodConfig)? configOverride,
  bool? enableSessionLogging,
  _i2.ExperimentalFeatures? experimentalFeatures,
  String? runMode,
  _i2.ServerpodLoggingMode? serverpodLoggingMode,
  Duration? serverpodStartTimeout,
  List<String>? testGroupTagsOverride,
  _i1.TestServerOutputMode? testServerOutputMode,
}) {
  _i1.buildWithServerpod<_InternalTestEndpoints>(
    testGroupName,
    _i1.TestServerpod(
      testEndpoints: _InternalTestEndpoints(),
      endpoints: Endpoints(),
      serializationManager: Protocol(),
      runMode: runMode,
      applyMigrations: false,
      isDatabaseEnabled: false,
      serverpodLoggingMode: serverpodLoggingMode,
      testServerOutputMode: testServerOutputMode,
      experimentalFeatures: experimentalFeatures,
      configOverride: configOverride,
    ),
    maybeRollbackDatabase: _i1.RollbackDatabase.disabled,
    maybeEnableSessionLogging: enableSessionLogging,
    maybeTestGroupTagsOverride: testGroupTagsOverride,
    maybeServerpodStartTimeout: serverpodStartTimeout,
    maybeTestServerOutputMode: testServerOutputMode,
  )(testClosure);
}

class TestEndpoints {
  late final _AdminAccountsEndpoint adminAccounts;

  late final _AdminAnnouncementEndpoint adminAnnouncement;

  late final _AdminAuditLogEndpoint adminAuditLog;

  late final _AdminAuthEndpoint adminAuth;

  late final _AdminDiagnosticsEndpoint adminDiagnostics;

  late final _AdminFeatureEndpoint adminFeature;

  late final _AdminOverviewEndpoint adminOverview;

  late final _AdminPlatformEndpoint adminPlatform;

  late final _AdminSupportEndpoint adminSupport;

  late final _AdminWorkspaceEndpoint adminWorkspace;

  late final _BotEndpoint bot;

  late final _BroadcastEndpoint broadcast;

  late final _ChannelEndpoint channel;

  late final _ConnectorEndpoint connector;

  late final _ConversationEndpoint conversation;

  late final _CustomerEndpoint customer;

  late final _ErrandEndpoint errand;

  late final _FeatureEndpoint feature;

  late final _FindingEndpoint finding;

  late final _InvoiceEndpoint invoice;

  late final _KnowledgeEndpoint knowledge;

  late final _OwnerNotificationEndpoint ownerNotification;

  late final _PaymentEndpoint payment;

  late final _PlatformEndpoint platform;

  late final _ProductEndpoint product;

  late final _ReportEndpoint report;

  late final _SaleEndpoint sale;

  late final _SupportTicketEndpoint supportTicket;

  late final _WaitlistEndpoint waitlist;

  late final _WhatsAppTemplateEndpoint whatsAppTemplate;

  late final _WorkspaceEndpoint workspace;
}

class _InternalTestEndpoints extends TestEndpoints
    implements _i1.InternalTestEndpoints {
  @override
  void initialize(
    _i2.SerializationManager serializationManager,
    _i2.EndpointDispatch endpoints,
  ) {
    adminAccounts = _AdminAccountsEndpoint(
      endpoints,
      serializationManager,
    );
    adminAnnouncement = _AdminAnnouncementEndpoint(
      endpoints,
      serializationManager,
    );
    adminAuditLog = _AdminAuditLogEndpoint(
      endpoints,
      serializationManager,
    );
    adminAuth = _AdminAuthEndpoint(
      endpoints,
      serializationManager,
    );
    adminDiagnostics = _AdminDiagnosticsEndpoint(
      endpoints,
      serializationManager,
    );
    adminFeature = _AdminFeatureEndpoint(
      endpoints,
      serializationManager,
    );
    adminOverview = _AdminOverviewEndpoint(
      endpoints,
      serializationManager,
    );
    adminPlatform = _AdminPlatformEndpoint(
      endpoints,
      serializationManager,
    );
    adminSupport = _AdminSupportEndpoint(
      endpoints,
      serializationManager,
    );
    adminWorkspace = _AdminWorkspaceEndpoint(
      endpoints,
      serializationManager,
    );
    bot = _BotEndpoint(
      endpoints,
      serializationManager,
    );
    broadcast = _BroadcastEndpoint(
      endpoints,
      serializationManager,
    );
    channel = _ChannelEndpoint(
      endpoints,
      serializationManager,
    );
    connector = _ConnectorEndpoint(
      endpoints,
      serializationManager,
    );
    conversation = _ConversationEndpoint(
      endpoints,
      serializationManager,
    );
    customer = _CustomerEndpoint(
      endpoints,
      serializationManager,
    );
    errand = _ErrandEndpoint(
      endpoints,
      serializationManager,
    );
    feature = _FeatureEndpoint(
      endpoints,
      serializationManager,
    );
    finding = _FindingEndpoint(
      endpoints,
      serializationManager,
    );
    invoice = _InvoiceEndpoint(
      endpoints,
      serializationManager,
    );
    knowledge = _KnowledgeEndpoint(
      endpoints,
      serializationManager,
    );
    ownerNotification = _OwnerNotificationEndpoint(
      endpoints,
      serializationManager,
    );
    payment = _PaymentEndpoint(
      endpoints,
      serializationManager,
    );
    platform = _PlatformEndpoint(
      endpoints,
      serializationManager,
    );
    product = _ProductEndpoint(
      endpoints,
      serializationManager,
    );
    report = _ReportEndpoint(
      endpoints,
      serializationManager,
    );
    sale = _SaleEndpoint(
      endpoints,
      serializationManager,
    );
    supportTicket = _SupportTicketEndpoint(
      endpoints,
      serializationManager,
    );
    waitlist = _WaitlistEndpoint(
      endpoints,
      serializationManager,
    );
    whatsAppTemplate = _WhatsAppTemplateEndpoint(
      endpoints,
      serializationManager,
    );
    workspace = _WorkspaceEndpoint(
      endpoints,
      serializationManager,
    );
  }
}

class _AdminAccountsEndpoint {
  _AdminAccountsEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> listAdmins(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAccounts',
            method: 'listAdmins',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAccounts',
          methodName: 'listAdmins',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> setActive(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int accountId,
    bool active,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAccounts',
            method: 'setActive',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAccounts',
          methodName: 'setActive',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'accountId': accountId,
            'active': active,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminAnnouncementEndpoint {
  _AdminAnnouncementEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> previewAudience(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String audience,
    String audienceValue,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAnnouncement',
            method: 'previewAudience',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAnnouncement',
          methodName: 'previewAudience',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'audience': audience,
            'audienceValue': audienceValue,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> sendAnnouncement(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String audience,
    String audienceValue,
    String subject,
    String body,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAnnouncement',
            method: 'sendAnnouncement',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAnnouncement',
          methodName: 'sendAnnouncement',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'audience': audience,
            'audienceValue': audienceValue,
            'subject': subject,
            'body': body,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminAuditLogEndpoint {
  _AdminAuditLogEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> listRecent(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken, {
    required int limit,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAuditLog',
            method: 'listRecent',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAuditLog',
          methodName: 'listRecent',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminAuthEndpoint {
  _AdminAuthEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<String> login(
    _i1.TestSessionBuilder sessionBuilder,
    String email,
    String password,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAuth',
            method: 'login',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAuth',
          methodName: 'login',
          parameters: _i1.testObjectToJson({
            'email': email,
            'password': password,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> mustResetPassword(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAuth',
            method: 'mustResetPassword',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAuth',
          methodName: 'mustResetPassword',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> changePassword(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String currentPassword,
    String newPassword,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminAuth',
            method: 'changePassword',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminAuth',
          methodName: 'changePassword',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminDiagnosticsEndpoint {
  _AdminDiagnosticsEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> diagnoseWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminDiagnostics',
            method: 'diagnoseWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminDiagnostics',
          methodName: 'diagnoseWorkspace',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i4.Conversation>> listRecentConversations(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId, {
    required int limit,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminDiagnostics',
            method: 'listRecentConversations',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminDiagnostics',
          methodName: 'listRecentConversations',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i4.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i5.KnowledgeDocument>> listFailedKnowledgeDocuments(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminDiagnostics',
            method: 'listFailedKnowledgeDocuments',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminDiagnostics',
          methodName: 'listFailedKnowledgeDocuments',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i5.KnowledgeDocument>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> reindexDocument(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    int documentId,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminDiagnostics',
            method: 'reindexDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminDiagnostics',
          methodName: 'reindexDocument',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'documentId': documentId,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> resendNotification(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String subject,
    String body,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminDiagnostics',
            method: 'resendNotification',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminDiagnostics',
          methodName: 'resendNotification',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'subject': subject,
            'body': body,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminFeatureEndpoint {
  _AdminFeatureEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i6.FeatureFlag>> listFlags(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'listFlags',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'listFlags',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i6.FeatureFlag>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<String>> listMissingFeatureKeys(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'listMissingFeatureKeys',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'listMissingFeatureKeys',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<String>> listOrphanedFeatureKeys(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'listOrphanedFeatureKeys',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'listOrphanedFeatureKeys',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.FeatureFlag> setFeatureState(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String key,
    String newState,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'setFeatureState',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'setFeatureState',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'key': key,
            'newState': newState,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i6.FeatureFlag>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i6.FeatureFlag>> releaseWave(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String wave,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'releaseWave',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'releaseWave',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'wave': wave,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i6.FeatureFlag>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i7.WorkspaceFeatureOverride> setOverride(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String featureKey,
    bool enabled,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'setOverride',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'setOverride',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'featureKey': featureKey,
            'enabled': enabled,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i7.WorkspaceFeatureOverride>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> removeOverride(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String featureKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'removeOverride',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'removeOverride',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'featureKey': featureKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i7.WorkspaceFeatureOverride>> listOverridesForFeature(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    String featureKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminFeature',
            method: 'listOverridesForFeature',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminFeature',
          methodName: 'listOverridesForFeature',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'featureKey': featureKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i7.WorkspaceFeatureOverride>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminOverviewEndpoint {
  _AdminOverviewEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> getSummary(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminOverview',
            method: 'getSummary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminOverview',
          methodName: 'getSummary',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<String>> getRecentActivity(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminOverview',
            method: 'getRecentActivity',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminOverview',
          methodName: 'getRecentActivity',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminPlatformEndpoint {
  _AdminPlatformEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> listSweepJobStatuses(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminPlatform',
            method: 'listSweepJobStatuses',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminPlatform',
          methodName: 'listSweepJobStatuses',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<String>> listAiProviderStatus(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminPlatform',
            method: 'listAiProviderStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminPlatform',
          methodName: 'listAiProviderStatus',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> embeddingQuotaInfo(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminPlatform',
            method: 'embeddingQuotaInfo',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminPlatform',
          methodName: 'embeddingQuotaInfo',
          parameters: _i1.testObjectToJson({'adminToken': adminToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminSupportEndpoint {
  _AdminSupportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i8.SupportTicket>> listOpenTickets(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken, {
    required int limit,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminSupport',
            method: 'listOpenTickets',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminSupport',
          methodName: 'listOpenTickets',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'limit': limit,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i8.SupportTicket>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _AdminWorkspaceEndpoint {
  _AdminWorkspaceEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i9.Workspace>> listWorkspaces(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken, {
    String? query,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'listWorkspaces',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'listWorkspaces',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'query': query,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i9.Workspace>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace?> getWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'getWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'getWorkspace',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i10.Bot>> listBotsForWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'listBotsForWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'listBotsForWorkspace',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i10.Bot>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i11.Channel>> listChannelsForBot(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int botId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'listChannelsForBot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'listChannelsForBot',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'botId': botId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i11.Channel>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> setPlan(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String plan,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'setPlan',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'setPlan',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'plan': plan,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> extendTrial(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    int days,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'extendTrial',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'extendTrial',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'days': days,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> resetTrial(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'resetTrial',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'resetTrial',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> suspend(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'suspend',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'suspend',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> reinstate(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'reinstate',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'reinstate',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> setInternal(
    _i1.TestSessionBuilder sessionBuilder,
    String adminToken,
    int workspaceId,
    bool isInternal,
    String note,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'adminWorkspace',
            method: 'setInternal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'adminWorkspace',
          methodName: 'setInternal',
          parameters: _i1.testObjectToJson({
            'adminToken': adminToken,
            'workspaceId': workspaceId,
            'isInternal': isInternal,
            'note': note,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _BotEndpoint {
  _BotEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i10.Bot> createBot(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String name,
    String archetype,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'createBot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'createBot',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'name': name,
            'archetype': archetype,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Bot> createBotFromDescription(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String description,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'createBotFromDescription',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'createBotFromDescription',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'description': description,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i10.Bot>> listBotsForWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'listBotsForWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'listBotsForWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i10.Bot>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Bot> getBot(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'getBot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'getBot',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Bot> updateBot(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String name,
    String archetype,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'updateBot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'updateBot',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'name': name,
            'archetype': archetype,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Bot> setKnowledgeSeed(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String knowledgeSeed,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'setKnowledgeSeed',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'setKnowledgeSeed',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'knowledgeSeed': knowledgeSeed,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Bot> setCostSavingContacts(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String telegramLink,
    String alternateWhatsapp,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'bot',
            method: 'setCostSavingContacts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'bot',
          methodName: 'setCostSavingContacts',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'telegramLink': telegramLink,
            'alternateWhatsapp': alternateWhatsapp,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i10.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _BroadcastEndpoint {
  _BroadcastEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i12.Broadcast> createBroadcast(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String platform,
    String text,
    String recipientsJson,
    int? throughputPerMinute,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'createBroadcast',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'createBroadcast',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'platform': platform,
            'text': text,
            'recipientsJson': recipientsJson,
            'throughputPerMinute': throughputPerMinute,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i12.Broadcast>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i12.Broadcast> startBroadcast(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'startBroadcast',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'startBroadcast',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'broadcastId': broadcastId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i12.Broadcast>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i12.Broadcast> cancelBroadcast(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'cancelBroadcast',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'cancelBroadcast',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'broadcastId': broadcastId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i12.Broadcast>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i12.Broadcast>> listBroadcasts(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'listBroadcasts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'listBroadcasts',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i12.Broadcast>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i13.BroadcastProgress> getBroadcastProgress(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int broadcastId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'getBroadcastProgress',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'getBroadcastProgress',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'broadcastId': broadcastId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i13.BroadcastProgress>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i14.MessageSuppression>> listSuppressions(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'listSuppressions',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'listSuppressions',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i14.MessageSuppression>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i14.MessageSuppression> addSuppression(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'addSuppression',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'addSuppression',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'platform': platform,
            'address': address,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i14.MessageSuppression>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> removeSuppression(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String platform,
    String address,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'broadcast',
            method: 'removeSuppression',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'broadcast',
          methodName: 'removeSuppression',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'platform': platform,
            'address': address,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ChannelEndpoint {
  _ChannelEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i11.Channel> connectTelegramChannel(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String botToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'channel',
            method: 'connectTelegramChannel',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'channel',
          methodName: 'connectTelegramChannel',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'botToken': botToken,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i11.Channel>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i11.Channel>> listChannelsForBot(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'channel',
            method: 'listChannelsForBot',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'channel',
          methodName: 'listChannelsForBot',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i11.Channel>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i11.Channel> connectWhatsAppChannelManual(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String whatsappAccessToken,
    String phoneNumberId,
    String wabaId,
    String whatsappAppId,
    String whatsappAppSecret,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'channel',
            method: 'connectWhatsAppChannelManual',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'channel',
          methodName: 'connectWhatsAppChannelManual',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'whatsappAccessToken': whatsappAccessToken,
            'phoneNumberId': phoneNumberId,
            'wabaId': wabaId,
            'whatsappAppId': whatsappAppId,
            'whatsappAppSecret': whatsappAppSecret,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i11.Channel>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i11.Channel> connectInstagramChannelManual(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int botId,
    String instagramAccessToken,
    String igUserId,
    String instagramAppSecret,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'channel',
            method: 'connectInstagramChannelManual',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'channel',
          methodName: 'connectInstagramChannelManual',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'botId': botId,
            'instagramAccessToken': instagramAccessToken,
            'igUserId': igUserId,
            'instagramAppSecret': instagramAppSecret,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i11.Channel>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ConnectorEndpoint {
  _ConnectorEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i15.ConnectorStatus>> listConnectors(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'listConnectors',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'listConnectors',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i15.ConnectorStatus>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> connectConnector(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
    Map<String, String> values,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'connectConnector',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'connectConnector',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
            'values': values,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> startGoogleOAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'startGoogleOAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'startGoogleOAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i16.GoogleDriveSpreadsheet>> listGoogleSheets(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'listGoogleSheets',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'listGoogleSheets',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i16.GoogleDriveSpreadsheet>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> setGoogleSheetTargets(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
    List<String> spreadsheetIds,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'setGoogleSheetTargets',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'setGoogleSheetTargets',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
            'spreadsheetIds': spreadsheetIds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> setGoogleSheetTarget(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
    String sheetUrl,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'setGoogleSheetTarget',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'setGoogleSheetTarget',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
            'sheetUrl': sheetUrl,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> startMicrosoftOAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'startMicrosoftOAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'startMicrosoftOAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> startDropboxOAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'startDropboxOAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'startDropboxOAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> startHubSpotOAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'startHubSpotOAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'startHubSpotOAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> startMetaOAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'startMetaOAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'startMetaOAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> setExcelFileTarget(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
    String fileUrl,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'setExcelFileTarget',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'setExcelFileTarget',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
            'fileUrl': fileUrl,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> setCalendarBookingMode(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String bookingMode,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'setCalendarBookingMode',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'setCalendarBookingMode',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'bookingMode': bookingMode,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i17.CalendarBooking>> listPendingBookings(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'listPendingBookings',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'listPendingBookings',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i17.CalendarBooking>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i17.CalendarBooking> approveBooking(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int bookingId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'approveBooking',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'approveBooking',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'bookingId': bookingId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i17.CalendarBooking>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i17.CalendarBooking> rejectBooking(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int bookingId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'rejectBooking',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'rejectBooking',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'bookingId': bookingId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i17.CalendarBooking>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i15.ConnectorStatus> disconnectConnector(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectorKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'connector',
            method: 'disconnectConnector',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'connector',
          methodName: 'disconnectConnector',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectorKey': connectorKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i15.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ConversationEndpoint {
  _ConversationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i4.Conversation>> listEscalated(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'conversation',
            method: 'listEscalated',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'conversation',
          methodName: 'listEscalated',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i4.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i4.Conversation>> listAll(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'conversation',
            method: 'listAll',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'conversation',
          methodName: 'listAll',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i4.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i18.Message>> getMessages(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int conversationId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'conversation',
            method: 'getMessages',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'conversation',
          methodName: 'getMessages',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'conversationId': conversationId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i18.Message>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i18.Message> sendHumanReply(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int conversationId,
    String body,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'conversation',
            method: 'sendHumanReply',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'conversation',
          methodName: 'sendHumanReply',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'conversationId': conversationId,
            'body': body,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i18.Message>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Conversation> closeConversation(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int conversationId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'conversation',
            method: 'closeConversation',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'conversation',
          methodName: 'closeConversation',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'conversationId': conversationId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i4.Conversation>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _CustomerEndpoint {
  _CustomerEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i19.Customer>> listCustomers(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'customer',
            method: 'listCustomers',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'customer',
          methodName: 'listCustomers',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'limit': limit,
            'offset': offset,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i19.Customer>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i20.CustomerDetail> getCustomerDetail(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int customerId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'customer',
            method: 'getCustomerDetail',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'customer',
          methodName: 'getCustomerDetail',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'customerId': customerId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i20.CustomerDetail>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i21.CustomerMergeProposal>> listMergeProposals(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'customer',
            method: 'listMergeProposals',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'customer',
          methodName: 'listMergeProposals',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i21.CustomerMergeProposal>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> resolveMergeProposal(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int proposalId,
    bool approve,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'customer',
            method: 'resolveMergeProposal',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'customer',
          methodName: 'resolveMergeProposal',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'proposalId': proposalId,
            'approve': approve,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ErrandEndpoint {
  _ErrandEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i22.Errand> createBuiltinErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String name,
    String descriptionForAi,
    String builtinHandlerKey,
    String createdVia, {
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'createBuiltinErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'createBuiltinErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'name': name,
            'descriptionForAi': descriptionForAi,
            'builtinHandlerKey': builtinHandlerKey,
            'createdVia': createdVia,
            'permissionScope': permissionScope,
            'inputSchemaJson': inputSchemaJson,
            'sensitiveInputKeysJson': sensitiveInputKeysJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i22.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i22.Errand>> listErrandsForWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'listErrandsForWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'listErrandsForWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i22.Errand>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i22.Errand> getErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'getErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'getErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i22.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i22.Errand> setErrandStatus(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
    String status,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'setErrandStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'setErrandStatus',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
            'status': status,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i22.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> deleteErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'deleteErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'deleteErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> executeBuiltinErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'executeBuiltinErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'executeBuiltinErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
            'inputJson': inputJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i22.Errand> createWebhookErrand(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'createWebhookErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'createWebhookErrand',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i22.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i22.Errand> createDbCredentialErrand(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'createDbCredentialErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'createDbCredentialErrand',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i22.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> executeErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
    String inputJson,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'executeErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'executeErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
            'inputJson': inputJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> discoverDbSchema(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String connectionString,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'discoverDbSchema',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'discoverDbSchema',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'connectionString': connectionString,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> discoverDbSchemaForErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'discoverDbSchemaForErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'discoverDbSchemaForErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> testWebhookErrand(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String webhookUrl,
    String sampleInputJson, {
    String? authHeaderName,
    String? authHeaderValue,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'testWebhookErrand',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'testWebhookErrand',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'webhookUrl': webhookUrl,
            'sampleInputJson': sampleInputJson,
            'authHeaderName': authHeaderName,
            'authHeaderValue': authHeaderValue,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> getEntityMapping(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'getEntityMapping',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'getEntityMapping',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> setEntityMapping(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int errandId,
    String mappingJson,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'errand',
            method: 'setEntityMapping',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'errand',
          methodName: 'setEntityMapping',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'errandId': errandId,
            'mappingJson': mappingJson,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _FeatureEndpoint {
  _FeatureEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<String>> listEnabledFeatures(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'feature',
            method: 'listEnabledFeatures',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'feature',
          methodName: 'listEnabledFeatures',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<String>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<bool> isFeatureEnabled(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String featureKey,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'feature',
            method: 'isFeatureEnabled',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'feature',
          methodName: 'isFeatureEnabled',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'featureKey': featureKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<bool>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _FindingEndpoint {
  _FindingEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i23.WorkspaceFinding>> listFindings(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'finding',
            method: 'listFindings',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'finding',
          methodName: 'listFindings',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i23.WorkspaceFinding>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> dismissFinding(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int findingId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'finding',
            method: 'dismissFinding',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'finding',
          methodName: 'dismissFinding',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'findingId': findingId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _InvoiceEndpoint {
  _InvoiceEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i24.Invoice> createInvoice(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'createInvoice',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'createInvoice',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i24.Invoice>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i24.Invoice>> listInvoices(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'listInvoices',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'listInvoices',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'limit': limit,
            'offset': offset,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i24.Invoice>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i24.Invoice?> getInvoice(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int invoiceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'getInvoice',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'getInvoice',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'invoiceId': invoiceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i24.Invoice?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i24.Invoice?> getInvoiceForSale(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int saleId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'getInvoiceForSale',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'getInvoiceForSale',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'saleId': saleId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i24.Invoice?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i24.Invoice> updateInvoiceStatus(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int invoiceId,
    String status,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'updateInvoiceStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'updateInvoiceStatus',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'invoiceId': invoiceId,
            'status': status,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i24.Invoice>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i24.Invoice> recordPayment(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int invoiceId,
    int amountMinor,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'invoice',
            method: 'recordPayment',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'invoice',
          methodName: 'recordPayment',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'invoiceId': invoiceId,
            'amountMinor': amountMinor,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i24.Invoice>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _KnowledgeEndpoint {
  _KnowledgeEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i5.KnowledgeDocument>> listDocuments(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'listDocuments',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'listDocuments',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i5.KnowledgeDocument>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i5.KnowledgeDocument> addDocument(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String title,
    String text, {
    required bool allowDuplicate,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'addDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'addDocument',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'title': title,
            'text': text,
            'allowDuplicate': allowDuplicate,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i5.KnowledgeDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> deleteDocument(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int documentId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'deleteDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'deleteDocument',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'documentId': documentId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i5.KnowledgeDocument> updateDocument(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int documentId,
    String title,
    String text,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'updateDocument',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'updateDocument',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'documentId': documentId,
            'title': title,
            'text': text,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i5.KnowledgeDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i25.KnowledgeSearchHit>> searchMemory(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String query,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'searchMemory',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'searchMemory',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'query': query,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i25.KnowledgeSearchHit>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i26.WorkspaceAnswer> askWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String question,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'askWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'askWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'question': question,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i26.WorkspaceAnswer>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i5.KnowledgeDocument> addDocumentFromFile(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String fileName,
    String base64Bytes, {
    required bool allowDuplicate,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'knowledge',
            method: 'addDocumentFromFile',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'knowledge',
          methodName: 'addDocumentFromFile',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'fileName': fileName,
            'base64Bytes': base64Bytes,
            'allowDuplicate': allowDuplicate,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i5.KnowledgeDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _OwnerNotificationEndpoint {
  _OwnerNotificationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i27.OwnerNotificationSettings?> getSettings(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ownerNotification',
            method: 'getSettings',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ownerNotification',
          methodName: 'getSettings',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i27.OwnerNotificationSettings?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i27.OwnerNotificationSettings> updateSettings(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'ownerNotification',
            method: 'updateSettings',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'ownerNotification',
          methodName: 'updateSettings',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i27.OwnerNotificationSettings>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _PaymentEndpoint {
  _PaymentEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i28.PaymentGatewayCredential> connectGateway(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String gateway,
    String secretKey, {
    String? webhookSecret,
    String? apiKey,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payment',
            method: 'connectGateway',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payment',
          methodName: 'connectGateway',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'gateway': gateway,
            'secretKey': secretKey,
            'webhookSecret': webhookSecret,
            'apiKey': apiKey,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i28.PaymentGatewayCredential>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i28.PaymentGatewayCredential>> listConnectedGateways(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payment',
            method: 'listConnectedGateways',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payment',
          methodName: 'listConnectedGateways',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i28.PaymentGatewayCredential>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i29.PaymentTransaction> initializeCheckout(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payment',
            method: 'initializeCheckout',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payment',
          methodName: 'initializeCheckout',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i29.PaymentTransaction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i29.PaymentTransaction?> getTransaction(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int transactionId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payment',
            method: 'getTransaction',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payment',
          methodName: 'getTransaction',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'transactionId': transactionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i29.PaymentTransaction?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i29.PaymentTransaction> releaseHold(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int transactionId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'payment',
            method: 'releaseHold',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'payment',
          methodName: 'releaseHold',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'transactionId': transactionId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i29.PaymentTransaction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _PlatformEndpoint {
  _PlatformEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i30.ApiKey>> listApiKeys(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'listApiKeys',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'listApiKeys',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i30.ApiKey>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i31.CreatedApiKey> createApiKey(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String name,
    String scope,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'createApiKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'createApiKey',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'name': name,
            'scope': scope,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i31.CreatedApiKey>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> revokeApiKey(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int keyId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'revokeApiKey',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'revokeApiKey',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'keyId': keyId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i32.WebhookEndpoint>> listWebhookEndpoints(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'listWebhookEndpoints',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'listWebhookEndpoints',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i32.WebhookEndpoint>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i32.WebhookEndpoint> saveWebhookEndpoint(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String url,
    List<String> events,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'saveWebhookEndpoint',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'saveWebhookEndpoint',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'url': url,
            'events': events,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i32.WebhookEndpoint>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> deleteWebhookEndpoint(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int endpointId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'platform',
            method: 'deleteWebhookEndpoint',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'platform',
          methodName: 'deleteWebhookEndpoint',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'endpointId': endpointId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ProductEndpoint {
  _ProductEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i33.Product>> listProducts(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required bool includeArchived,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'listProducts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'listProducts',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'includeArchived': includeArchived,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i33.Product>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i33.Product?> getProduct(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'getProduct',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'getProduct',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i33.Product?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i34.ProductVariant>> listVariants(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'listVariants',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'listVariants',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i34.ProductVariant>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i33.Product> createProduct(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'createProduct',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'createProduct',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i33.Product>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i33.Product> updateProduct(
    _i1.TestSessionBuilder sessionBuilder,
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
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'updateProduct',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'updateProduct',
          parameters: _i1.testObjectToJson({
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i33.Product>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> archiveProduct(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'archiveProduct',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'archiveProduct',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i34.ProductVariant>> replaceVariants(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
    List<String> labels,
    List<int?> stocks,
    List<int?> priceMinors,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'replaceVariants',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'replaceVariants',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
            'labels': labels,
            'stocks': stocks,
            'priceMinors': priceMinors,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i34.ProductVariant>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> getMediaUploadAuth(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'getMediaUploadAuth',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'getMediaUploadAuth',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i35.ProductMedia>> listMedia(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'listMedia',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'listMedia',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i35.ProductMedia>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i35.ProductMedia>> listMediaForProducts(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String productIds,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'listMediaForProducts',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'listMediaForProducts',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productIds': productIds,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i35.ProductMedia>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i35.ProductMedia> addProductMedia(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
    String imagekitFileId,
    String url, {
    required String kind,
    String? thumbnailUrl,
    int? width,
    int? height,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'addProductMedia',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'addProductMedia',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
            'imagekitFileId': imagekitFileId,
            'url': url,
            'kind': kind,
            'thumbnailUrl': thumbnailUrl,
            'width': width,
            'height': height,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i35.ProductMedia>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> deleteProductMedia(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
    int mediaId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'deleteProductMedia',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'deleteProductMedia',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
            'mediaId': mediaId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<void> reorderProductMedia(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
    String mediaIdsInOrder,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'reorderProductMedia',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'reorderProductMedia',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
            'mediaIdsInOrder': mediaIdsInOrder,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<void>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i35.ProductMedia?> importMediaFromUrl(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int productId,
    String sourceUrl,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'product',
            method: 'importMediaFromUrl',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'product',
          methodName: 'importMediaFromUrl',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'productId': productId,
            'sourceUrl': sourceUrl,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i35.ProductMedia?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _ReportEndpoint {
  _ReportEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i36.EndOfDayReport> getEndOfDayReport(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    DateTime? date,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'report',
            method: 'getEndOfDayReport',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'report',
          methodName: 'getEndOfDayReport',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'date': date,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i36.EndOfDayReport>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SaleEndpoint {
  _SaleEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i37.Sale> ringUpSale(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required String linesJson,
    required String paymentMethod,
    int? cashReceivedMinor,
    String? clientReference,
    String? customerPhone,
    String? customerName,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sale',
            method: 'ringUpSale',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sale',
          methodName: 'ringUpSale',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'linesJson': linesJson,
            'paymentMethod': paymentMethod,
            'cashReceivedMinor': cashReceivedMinor,
            'clientReference': clientReference,
            'customerPhone': customerPhone,
            'customerName': customerName,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i37.Sale>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i37.Sale>> listSales(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required int limit,
    required int offset,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sale',
            method: 'listSales',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sale',
          methodName: 'listSales',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'limit': limit,
            'offset': offset,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i37.Sale>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i38.SaleLine>> getSaleLines(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int saleId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'sale',
            method: 'getSaleLines',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'sale',
          methodName: 'getSaleLines',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'saleId': saleId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i38.SaleLine>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _SupportTicketEndpoint {
  _SupportTicketEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i8.SupportTicket>> list(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    String? status,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'supportTicket',
            method: 'list',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'supportTicket',
          methodName: 'list',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'status': status,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i8.SupportTicket>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.SupportTicket> setStatus(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int ticketId,
    String status,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'supportTicket',
            method: 'setStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'supportTicket',
          methodName: 'setStatus',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'ticketId': ticketId,
            'status': status,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i8.SupportTicket>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WaitlistEndpoint {
  _WaitlistEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i39.WaitlistSignup> joinWaitlist(
    _i1.TestSessionBuilder sessionBuilder,
    String email,
    String source, {
    String? name,
    String? phone,
    String? businessType,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'waitlist',
            method: 'joinWaitlist',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'waitlist',
          methodName: 'joinWaitlist',
          parameters: _i1.testObjectToJson({
            'email': email,
            'source': source,
            'name': name,
            'phone': phone,
            'businessType': businessType,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i39.WaitlistSignup>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WhatsAppTemplateEndpoint {
  _WhatsAppTemplateEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i40.WhatsAppMessageTemplate> createTemplate(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int channelId,
    String label,
    String category,
    String language,
    String bodyText,
    List<String> bodyExampleValues,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'whatsAppTemplate',
            method: 'createTemplate',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'whatsAppTemplate',
          methodName: 'createTemplate',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'channelId': channelId,
            'label': label,
            'category': category,
            'language': language,
            'bodyText': bodyText,
            'bodyExampleValues': bodyExampleValues,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i40.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i40.WhatsAppMessageTemplate> createProductListTemplate(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int channelId,
    String businessLabel,
    String customerNameExample,
    String productListExample,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'whatsAppTemplate',
            method: 'createProductListTemplate',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'whatsAppTemplate',
          methodName: 'createProductListTemplate',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'channelId': channelId,
            'businessLabel': businessLabel,
            'customerNameExample': customerNameExample,
            'productListExample': productListExample,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i40.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i40.WhatsAppMessageTemplate>> listTemplatesForWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'whatsAppTemplate',
            method: 'listTemplatesForWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'whatsAppTemplate',
          methodName: 'listTemplatesForWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i40.WhatsAppMessageTemplate>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i40.WhatsAppMessageTemplate> refreshTemplateStatus(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    int templateId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'whatsAppTemplate',
            method: 'refreshTemplateStatus',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'whatsAppTemplate',
          methodName: 'refreshTemplateStatus',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'templateId': templateId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i40.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}

class _WorkspaceEndpoint {
  _WorkspaceEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i9.Workspace> createWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    String name,
    String? industryTag, {
    String? ownerName,
    String? ownerPhone,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'createWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'createWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'name': name,
            'industryTag': industryTag,
            'ownerName': ownerName,
            'ownerPhone': ownerPhone,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i9.Workspace>> listMyWorkspaces(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'listMyWorkspaces',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'listMyWorkspaces',
          parameters: _i1.testObjectToJson({'accessToken': accessToken}),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<List<_i9.Workspace>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> getWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'getWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'getWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Workspace> updateWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    String? name,
    String? industryTag,
    String? ownerName,
    bool? sellsCatalogItems,
  }) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'updateWorkspace',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'updateWorkspace',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'name': name,
            'industryTag': industryTag,
            'ownerName': ownerName,
            'sellsCatalogItems': sellsCatalogItems,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i9.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<String> getBillingSummary(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'getBillingSummary',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'getBillingSummary',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<String>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i41.KolaBillingCheckout> initiateUpgrade(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String gateway,
    String customerEmail,
  ) async {
    return _i1.callAwaitableFunctionAndHandleExceptions(() async {
      var _localUniqueSession =
          (sessionBuilder as _i1.InternalTestSessionBuilder).internalBuild(
            endpoint: 'workspace',
            method: 'initiateUpgrade',
          );
      try {
        var _localCallContext = await _endpointDispatch.getMethodCallContext(
          createSessionCallback: (_) => _localUniqueSession,
          endpointPath: 'workspace',
          methodName: 'initiateUpgrade',
          parameters: _i1.testObjectToJson({
            'accessToken': accessToken,
            'workspaceId': workspaceId,
            'gateway': gateway,
            'customerEmail': customerEmail,
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i41.KolaBillingCheckout>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
