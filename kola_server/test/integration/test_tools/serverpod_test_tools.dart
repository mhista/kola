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
import 'package:kola_server/src/generated/conversation.dart' as _i6;
import 'package:kola_server/src/generated/message.dart' as _i7;
import 'package:kola_server/src/generated/errand.dart' as _i8;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i9;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i10;
import 'package:kola_server/src/generated/owner_notification_settings.dart'
    as _i11;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i12;
import 'package:kola_server/src/generated/payment_transaction.dart' as _i13;
import 'package:kola_server/src/generated/support_ticket.dart' as _i14;
import 'package:kola_server/src/generated/waitlist_signup.dart' as _i15;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i16;
import 'package:kola_server/src/generated/workspace.dart' as _i17;
import 'package:kola_server/src/generated/kola_billing_checkout.dart' as _i18;
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

  late final _ConversationEndpoint conversation;

  late final _ErrandEndpoint errand;

  late final _FeatureEndpoint feature;

  late final _KnowledgeEndpoint knowledge;

  late final _OwnerNotificationEndpoint ownerNotification;

  late final _PaymentEndpoint payment;

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
    conversation = _ConversationEndpoint(
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

class _ConversationEndpoint {
  _ConversationEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i6.Conversation>> listEscalated(
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
                as _i3.Future<List<_i6.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i6.Conversation>> listAll(
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
                as _i3.Future<List<_i6.Conversation>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i7.Message>> getMessages(
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
                as _i3.Future<List<_i7.Message>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i7.Message> sendHumanReply(
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
                as _i3.Future<_i7.Message>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i6.Conversation> closeConversation(
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
                as _i3.Future<_i6.Conversation>);
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

  _i3.Future<_i8.Errand> createBuiltinErrand(
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
                as _i3.Future<_i8.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i8.Errand>> listErrandsForWorkspace(
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
                as _i3.Future<List<_i8.Errand>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.Errand> getErrand(
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
                as _i3.Future<_i8.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.Errand> setErrandStatus(
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
                as _i3.Future<_i8.Errand>);
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

  _i3.Future<_i8.Errand> createWebhookErrand(
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
                as _i3.Future<_i8.Errand>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i8.Errand> createDbCredentialErrand(
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
                as _i3.Future<_i8.Errand>);
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

class _KnowledgeEndpoint {
  _KnowledgeEndpoint(
    this._endpointDispatch,
    this._serializationManager,
  );

  final _i2.EndpointDispatch _endpointDispatch;

  final _i2.SerializationManager _serializationManager;

  _i3.Future<List<_i9.KnowledgeDocument>> listDocuments(
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
                as _i3.Future<List<_i9.KnowledgeDocument>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i9.KnowledgeDocument> addDocument(
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
                as _i3.Future<_i9.KnowledgeDocument>);
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

  _i3.Future<_i9.KnowledgeDocument> updateDocument(
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
                as _i3.Future<_i9.KnowledgeDocument>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i10.KnowledgeSearchHit>> searchMemory(
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
                as _i3.Future<List<_i10.KnowledgeSearchHit>>);
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

  _i3.Future<_i11.OwnerNotificationSettings?> getSettings(
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
                as _i3.Future<_i11.OwnerNotificationSettings?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i11.OwnerNotificationSettings> updateSettings(
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
                as _i3.Future<_i11.OwnerNotificationSettings>);
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

  _i3.Future<_i12.PaymentGatewayCredential> connectGateway(
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
                as _i3.Future<_i12.PaymentGatewayCredential>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i12.PaymentGatewayCredential>> listConnectedGateways(
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
                as _i3.Future<List<_i12.PaymentGatewayCredential>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i13.PaymentTransaction> initializeCheckout(
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
                as _i3.Future<_i13.PaymentTransaction>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i13.PaymentTransaction?> getTransaction(
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
                as _i3.Future<_i13.PaymentTransaction?>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i13.PaymentTransaction> releaseHold(
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
                as _i3.Future<_i13.PaymentTransaction>);
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

  _i3.Future<List<_i14.SupportTicket>> list(
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
                as _i3.Future<List<_i14.SupportTicket>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i14.SupportTicket> setStatus(
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
                as _i3.Future<_i14.SupportTicket>);
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

  _i3.Future<_i15.WaitlistSignup> joinWaitlist(
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
                as _i3.Future<_i15.WaitlistSignup>);
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

  _i3.Future<_i16.WhatsAppMessageTemplate> createTemplate(
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
                as _i3.Future<_i16.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i16.WhatsAppMessageTemplate> createProductListTemplate(
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
                as _i3.Future<_i16.WhatsAppMessageTemplate>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i16.WhatsAppMessageTemplate>> listTemplatesForWorkspace(
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
                as _i3.Future<List<_i16.WhatsAppMessageTemplate>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i16.WhatsAppMessageTemplate> refreshTemplateStatus(
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
                as _i3.Future<_i16.WhatsAppMessageTemplate>);
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

  _i3.Future<_i17.Workspace> createWorkspace(
    _i1.TestSessionBuilder sessionBuilder,
    String accessToken,
    String name,
    String? industryTag,
  ) async {
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
          }),
          serializationManager: _serializationManager,
        );
        var _localReturnValue =
            await (_localCallContext.method.call(
                  _localUniqueSession,
                  _localCallContext.arguments,
                )
                as _i3.Future<_i17.Workspace>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<List<_i17.Workspace>> listMyWorkspaces(
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
                as _i3.Future<List<_i17.Workspace>>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }

  _i3.Future<_i17.Workspace> getWorkspace(
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
                as _i3.Future<_i17.Workspace>);
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

  _i3.Future<_i18.KolaBillingCheckout> initiateUpgrade(
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
                as _i3.Future<_i18.KolaBillingCheckout>);
        return _localReturnValue;
      } finally {
        await _localUniqueSession.close();
      }
    });
  }
}
