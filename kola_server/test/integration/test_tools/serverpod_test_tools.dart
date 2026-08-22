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
import 'package:kola_server/src/generated/bot.dart' as _i4;
import 'package:kola_server/src/generated/channel.dart' as _i5;
import 'package:kola_server/src/generated/connector_status.dart' as _i6;
import 'package:kola_server/src/generated/google_drive_spreadsheet.dart' as _i7;
import 'package:kola_server/src/generated/calendar_booking.dart' as _i8;
import 'package:kola_server/src/generated/conversation.dart' as _i9;
import 'package:kola_server/src/generated/message.dart' as _i10;
import 'package:kola_server/src/generated/customer.dart' as _i11;
import 'package:kola_server/src/generated/customer_detail.dart' as _i12;
import 'package:kola_server/src/generated/customer_merge_proposal.dart' as _i13;
import 'package:kola_server/src/generated/errand.dart' as _i14;
import 'package:kola_server/src/generated/workspace_finding.dart' as _i15;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i16;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i17;
import 'package:kola_server/src/generated/workspace_answer.dart' as _i18;
import 'package:kola_server/src/generated/owner_notification_settings.dart'
    as _i19;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i20;
import 'package:kola_server/src/generated/payment_transaction.dart' as _i21;
import 'package:kola_server/src/generated/api_key.dart' as _i22;
import 'package:kola_server/src/generated/created_api_key.dart' as _i23;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i24;
import 'package:kola_server/src/generated/product.dart' as _i25;
import 'package:kola_server/src/generated/product_variant.dart' as _i26;
import 'package:kola_server/src/generated/product_media.dart' as _i27;
import 'package:kola_server/src/generated/sale.dart' as _i28;
import 'package:kola_server/src/generated/sale_line_input.dart' as _i29;
import 'package:kola_server/src/generated/sale_line.dart' as _i30;
import 'package:kola_server/src/generated/support_ticket.dart' as _i31;
import 'package:kola_server/src/generated/waitlist_signup.dart' as _i32;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i33;
import 'package:kola_server/src/generated/workspace.dart' as _i34;
import 'package:kola_server/src/generated/kola_billing_checkout.dart' as _i35;
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
  late final _BotEndpoint bot;

  late final _ChannelEndpoint channel;

  late final _ConnectorEndpoint connector;

  late final _ConversationEndpoint conversation;

  late final _CustomerEndpoint customer;

  late final _ErrandEndpoint errand;

  late final _FeatureEndpoint feature;

  late final _FindingEndpoint finding;

  late final _KnowledgeEndpoint knowledge;

  late final _OwnerNotificationEndpoint ownerNotification;

  late final _PaymentEndpoint payment;

  late final _PlatformEndpoint platform;

  late final _ProductEndpoint product;

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
    bot = _BotEndpoint(
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

class _BotEndpoint {
  _BotEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<_i4.Bot> createBot(
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
                as _i3.Future<_i4.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Bot> createBotFromDescription(
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
                as _i3.Future<_i4.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i4.Bot>> listBotsForWorkspace(
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
                as _i3.Future<List<_i4.Bot>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Bot> getBot(
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
                as _i3.Future<_i4.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Bot> updateBot(
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
                as _i3.Future<_i4.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Bot> setKnowledgeSeed(
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
                as _i3.Future<_i4.Bot>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i4.Bot> setCostSavingContacts(
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
                as _i3.Future<_i4.Bot>);
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

  _i3.Future<_i5.Channel> connectTelegramChannel(
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
                as _i3.Future<_i5.Channel>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i5.Channel>> listChannelsForBot(
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
                as _i3.Future<List<_i5.Channel>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i5.Channel> connectWhatsAppChannelManual(
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
                as _i3.Future<_i5.Channel>);
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

  _i3.Future<List<_i6.ConnectorStatus>> listConnectors(
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
                as _i3.Future<List<_i6.ConnectorStatus>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.ConnectorStatus> connectConnector(
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
                as _i3.Future<_i6.ConnectorStatus>);
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

  _i3.Future<List<_i7.GoogleDriveSpreadsheet>> listGoogleSheets(
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
                as _i3.Future<List<_i7.GoogleDriveSpreadsheet>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.ConnectorStatus> setGoogleSheetTargets(
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
                as _i3.Future<_i6.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.ConnectorStatus> setGoogleSheetTarget(
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
                as _i3.Future<_i6.ConnectorStatus>);
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

  _i3.Future<_i6.ConnectorStatus> setExcelFileTarget(
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
                as _i3.Future<_i6.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.ConnectorStatus> setCalendarBookingMode(
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
                as _i3.Future<_i6.ConnectorStatus>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i8.CalendarBooking>> listPendingBookings(
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
                as _i3.Future<List<_i8.CalendarBooking>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.CalendarBooking> approveBooking(
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
                as _i3.Future<_i8.CalendarBooking>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.CalendarBooking> rejectBooking(
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
                as _i3.Future<_i8.CalendarBooking>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.ConnectorStatus> disconnectConnector(
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
                as _i3.Future<_i6.ConnectorStatus>);
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

  _i3.Future<List<_i9.Conversation>> listEscalated(
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
                as _i3.Future<List<_i9.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i9.Conversation>> listAll(
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
                as _i3.Future<List<_i9.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i10.Message>> getMessages(
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
                as _i3.Future<List<_i10.Message>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i10.Message> sendHumanReply(
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
                as _i3.Future<_i10.Message>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.Conversation> closeConversation(
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
                as _i3.Future<_i9.Conversation>);
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

  _i3.Future<List<_i11.Customer>> listCustomers(
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
                as _i3.Future<List<_i11.Customer>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i12.CustomerDetail> getCustomerDetail(
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
                as _i3.Future<_i12.CustomerDetail>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i13.CustomerMergeProposal>> listMergeProposals(
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
                as _i3.Future<List<_i13.CustomerMergeProposal>>);
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

  _i3.Future<_i14.Errand> createBuiltinErrand(
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
                as _i3.Future<_i14.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i14.Errand>> listErrandsForWorkspace(
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
                as _i3.Future<List<_i14.Errand>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i14.Errand> getErrand(
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
                as _i3.Future<_i14.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i14.Errand> setErrandStatus(
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
                as _i3.Future<_i14.Errand>);
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

  _i3.Future<_i14.Errand> createWebhookErrand(
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
                as _i3.Future<_i14.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i14.Errand> createDbCredentialErrand(
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
                as _i3.Future<_i14.Errand>);
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

  _i3.Future<List<_i15.WorkspaceFinding>> listFindings(
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
                as _i3.Future<List<_i15.WorkspaceFinding>>);
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

class _KnowledgeEndpoint {
  _KnowledgeEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i16.KnowledgeDocument>> listDocuments(
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
                as _i3.Future<List<_i16.KnowledgeDocument>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i16.KnowledgeDocument> addDocument(
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
                as _i3.Future<_i16.KnowledgeDocument>);
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

  _i3.Future<_i16.KnowledgeDocument> updateDocument(
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
                as _i3.Future<_i16.KnowledgeDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i17.KnowledgeSearchHit>> searchMemory(
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
                as _i3.Future<List<_i17.KnowledgeSearchHit>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i18.WorkspaceAnswer> askWorkspace(
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
                as _i3.Future<_i18.WorkspaceAnswer>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i16.KnowledgeDocument> addDocumentFromFile(
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
                as _i3.Future<_i16.KnowledgeDocument>);
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

  _i3.Future<_i19.OwnerNotificationSettings?> getSettings(
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
                as _i3.Future<_i19.OwnerNotificationSettings?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i19.OwnerNotificationSettings> updateSettings(
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
                as _i3.Future<_i19.OwnerNotificationSettings>);
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

  _i3.Future<_i20.PaymentGatewayCredential> connectGateway(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId,
    String gateway,
    String secretKey, {
    String? webhookSecret,
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i20.PaymentGatewayCredential>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i20.PaymentGatewayCredential>> listConnectedGateways(
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
                as _i3.Future<List<_i20.PaymentGatewayCredential>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i21.PaymentTransaction> initializeCheckout(
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
                as _i3.Future<_i21.PaymentTransaction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i21.PaymentTransaction?> getTransaction(
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
                as _i3.Future<_i21.PaymentTransaction?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i21.PaymentTransaction> releaseHold(
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
                as _i3.Future<_i21.PaymentTransaction>);
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

  _i3.Future<List<_i22.ApiKey>> listApiKeys(
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
                as _i3.Future<List<_i22.ApiKey>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i23.CreatedApiKey> createApiKey(
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
                as _i3.Future<_i23.CreatedApiKey>);
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

  _i3.Future<List<_i24.WebhookEndpoint>> listWebhookEndpoints(
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
                as _i3.Future<List<_i24.WebhookEndpoint>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i24.WebhookEndpoint> saveWebhookEndpoint(
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
                as _i3.Future<_i24.WebhookEndpoint>);
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

  _i3.Future<List<_i25.Product>> listProducts(
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
                as _i3.Future<List<_i25.Product>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i25.Product?> getProduct(
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
                as _i3.Future<_i25.Product?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i26.ProductVariant>> listVariants(
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
                as _i3.Future<List<_i26.ProductVariant>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i25.Product> createProduct(
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
                as _i3.Future<_i25.Product>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i25.Product> updateProduct(
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
                as _i3.Future<_i25.Product>);
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

  _i3.Future<List<_i26.ProductVariant>> replaceVariants(
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
                as _i3.Future<List<_i26.ProductVariant>>);
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

  _i3.Future<List<_i27.ProductMedia>> listMedia(
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
                as _i3.Future<List<_i27.ProductMedia>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i27.ProductMedia>> listMediaForProducts(
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
                as _i3.Future<List<_i27.ProductMedia>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i27.ProductMedia> addProductMedia(
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
                as _i3.Future<_i27.ProductMedia>);
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

  _i3.Future<_i27.ProductMedia?> importMediaFromUrl(
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
                as _i3.Future<_i27.ProductMedia?>);
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

  _i3.Future<_i28.Sale> ringUpSale(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    required List<_i29.SaleLineInput> lines,
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
            'lines': lines,
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
                as _i3.Future<_i28.Sale>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i28.Sale>> listSales(
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
                as _i3.Future<List<_i28.Sale>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i30.SaleLine>> getSaleLines(
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
                as _i3.Future<List<_i30.SaleLine>>);
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

  _i3.Future<List<_i31.SupportTicket>> list(
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
                as _i3.Future<List<_i31.SupportTicket>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i31.SupportTicket> setStatus(
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
                as _i3.Future<_i31.SupportTicket>);
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

  _i3.Future<_i32.WaitlistSignup> joinWaitlist(
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
                as _i3.Future<_i32.WaitlistSignup>);
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

  _i3.Future<_i33.WhatsAppMessageTemplate> createTemplate(
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
                as _i3.Future<_i33.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i33.WhatsAppMessageTemplate> createProductListTemplate(
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
                as _i3.Future<_i33.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i33.WhatsAppMessageTemplate>> listTemplatesForWorkspace(
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
                as _i3.Future<List<_i33.WhatsAppMessageTemplate>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i33.WhatsAppMessageTemplate> refreshTemplateStatus(
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
                as _i3.Future<_i33.WhatsAppMessageTemplate>);
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

  _i3.Future<_i34.Workspace> createWorkspace(
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
                as _i3.Future<_i34.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i34.Workspace>> listMyWorkspaces(
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
                as _i3.Future<List<_i34.Workspace>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i34.Workspace> getWorkspace(
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
                as _i3.Future<_i34.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i34.Workspace> updateWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    int workspaceId, {
    String? name,
    String? industryTag,
    String? ownerName,
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i34.Workspace>);
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

  _i3.Future<_i35.KolaBillingCheckout> initiateUpgrade(
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
                as _i3.Future<_i35.KolaBillingCheckout>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
