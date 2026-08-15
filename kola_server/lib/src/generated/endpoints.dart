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
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/bot_endpoint.dart' as _i2;
import '../endpoints/channel_endpoint.dart' as _i3;
import '../endpoints/connector_endpoint.dart' as _i4;
import '../endpoints/conversation_endpoint.dart' as _i5;
import '../endpoints/errand_endpoint.dart' as _i6;
import '../endpoints/feature_endpoint.dart' as _i7;
import '../endpoints/finding_endpoint.dart' as _i8;
import '../endpoints/knowledge_endpoint.dart' as _i9;
import '../endpoints/owner_notification_endpoint.dart' as _i10;
import '../endpoints/payment_endpoint.dart' as _i11;
import '../endpoints/platform_endpoint.dart' as _i12;
import '../endpoints/product_endpoint.dart' as _i13;
import '../endpoints/support_ticket_endpoint.dart' as _i14;
import '../endpoints/waitlist_endpoint.dart' as _i15;
import '../endpoints/whatsapp_template_endpoint.dart' as _i16;
import '../endpoints/workspace_endpoint.dart' as _i17;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'bot': _i2.BotEndpoint()
        ..initialize(
          server,
          'bot',
          null,
        ),
      'channel': _i3.ChannelEndpoint()
        ..initialize(
          server,
          'channel',
          null,
        ),
      'connector': _i4.ConnectorEndpoint()
        ..initialize(
          server,
          'connector',
          null,
        ),
      'conversation': _i5.ConversationEndpoint()
        ..initialize(
          server,
          'conversation',
          null,
        ),
      'errand': _i6.ErrandEndpoint()
        ..initialize(
          server,
          'errand',
          null,
        ),
      'feature': _i7.FeatureEndpoint()
        ..initialize(
          server,
          'feature',
          null,
        ),
      'finding': _i8.FindingEndpoint()
        ..initialize(
          server,
          'finding',
          null,
        ),
      'knowledge': _i9.KnowledgeEndpoint()
        ..initialize(
          server,
          'knowledge',
          null,
        ),
      'ownerNotification': _i10.OwnerNotificationEndpoint()
        ..initialize(
          server,
          'ownerNotification',
          null,
        ),
      'payment': _i11.PaymentEndpoint()
        ..initialize(
          server,
          'payment',
          null,
        ),
      'platform': _i12.PlatformEndpoint()
        ..initialize(
          server,
          'platform',
          null,
        ),
      'product': _i13.ProductEndpoint()
        ..initialize(
          server,
          'product',
          null,
        ),
      'supportTicket': _i14.SupportTicketEndpoint()
        ..initialize(
          server,
          'supportTicket',
          null,
        ),
      'waitlist': _i15.WaitlistEndpoint()
        ..initialize(
          server,
          'waitlist',
          null,
        ),
      'whatsAppTemplate': _i16.WhatsAppTemplateEndpoint()
        ..initialize(
          server,
          'whatsAppTemplate',
          null,
        ),
      'workspace': _i17.WorkspaceEndpoint()
        ..initialize(
          server,
          'workspace',
          null,
        ),
    };
    connectors['bot'] = _i1.EndpointConnector(
      name: 'bot',
      endpoint: endpoints['bot']!,
      methodConnectors: {
        'createBot': _i1.MethodConnector(
          name: 'createBot',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'archetype': _i1.ParameterDescription(
              name: 'archetype',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bot'] as _i2.BotEndpoint).createBot(
                session,
                params['accessToken'],
                params['workspaceId'],
                params['name'],
                params['archetype'],
              ),
        ),
        'createBotFromDescription': _i1.MethodConnector(
          name: 'createBotFromDescription',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bot'] as _i2.BotEndpoint)
                  .createBotFromDescription(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['description'],
                  ),
        ),
        'listBotsForWorkspace': _i1.MethodConnector(
          name: 'listBotsForWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['bot'] as _i2.BotEndpoint).listBotsForWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'getBot': _i1.MethodConnector(
          name: 'getBot',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bot'] as _i2.BotEndpoint).getBot(
                session,
                params['accessToken'],
                params['workspaceId'],
                params['botId'],
              ),
        ),
        'updateBot': _i1.MethodConnector(
          name: 'updateBot',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'archetype': _i1.ParameterDescription(
              name: 'archetype',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bot'] as _i2.BotEndpoint).updateBot(
                session,
                params['accessToken'],
                params['workspaceId'],
                params['botId'],
                params['name'],
                params['archetype'],
              ),
        ),
        'setKnowledgeSeed': _i1.MethodConnector(
          name: 'setKnowledgeSeed',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'knowledgeSeed': _i1.ParameterDescription(
              name: 'knowledgeSeed',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['bot'] as _i2.BotEndpoint).setKnowledgeSeed(
                session,
                params['accessToken'],
                params['workspaceId'],
                params['botId'],
                params['knowledgeSeed'],
              ),
        ),
        'setCostSavingContacts': _i1.MethodConnector(
          name: 'setCostSavingContacts',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'telegramLink': _i1.ParameterDescription(
              name: 'telegramLink',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'alternateWhatsapp': _i1.ParameterDescription(
              name: 'alternateWhatsapp',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['bot'] as _i2.BotEndpoint).setCostSavingContacts(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['botId'],
                    params['telegramLink'],
                    params['alternateWhatsapp'],
                  ),
        ),
      },
    );
    connectors['channel'] = _i1.EndpointConnector(
      name: 'channel',
      endpoint: endpoints['channel']!,
      methodConnectors: {
        'connectTelegramChannel': _i1.MethodConnector(
          name: 'connectTelegramChannel',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botToken': _i1.ParameterDescription(
              name: 'botToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['channel'] as _i3.ChannelEndpoint)
                  .connectTelegramChannel(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['botId'],
                    params['botToken'],
                  ),
        ),
        'listChannelsForBot': _i1.MethodConnector(
          name: 'listChannelsForBot',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['channel'] as _i3.ChannelEndpoint)
                  .listChannelsForBot(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['botId'],
                  ),
        ),
        'connectWhatsAppChannelManual': _i1.MethodConnector(
          name: 'connectWhatsAppChannelManual',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'botId': _i1.ParameterDescription(
              name: 'botId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'whatsappAccessToken': _i1.ParameterDescription(
              name: 'whatsappAccessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'phoneNumberId': _i1.ParameterDescription(
              name: 'phoneNumberId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'wabaId': _i1.ParameterDescription(
              name: 'wabaId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'whatsappAppId': _i1.ParameterDescription(
              name: 'whatsappAppId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'whatsappAppSecret': _i1.ParameterDescription(
              name: 'whatsappAppSecret',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['channel'] as _i3.ChannelEndpoint)
                  .connectWhatsAppChannelManual(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['botId'],
                    params['whatsappAccessToken'],
                    params['phoneNumberId'],
                    params['wabaId'],
                    params['whatsappAppId'],
                    params['whatsappAppSecret'],
                  ),
        ),
      },
    );
    connectors['connector'] = _i1.EndpointConnector(
      name: 'connector',
      endpoint: endpoints['connector']!,
      methodConnectors: {
        'listConnectors': _i1.MethodConnector(
          name: 'listConnectors',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['connector'] as _i4.ConnectorEndpoint)
                  .listConnectors(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'connectConnector': _i1.MethodConnector(
          name: 'connectConnector',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'connectorKey': _i1.ParameterDescription(
              name: 'connectorKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'values': _i1.ParameterDescription(
              name: 'values',
              type: _i1.getType<Map<String, String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['connector'] as _i4.ConnectorEndpoint)
                  .connectConnector(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['connectorKey'],
                    params['values'],
                  ),
        ),
        'disconnectConnector': _i1.MethodConnector(
          name: 'disconnectConnector',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'connectorKey': _i1.ParameterDescription(
              name: 'connectorKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['connector'] as _i4.ConnectorEndpoint)
                  .disconnectConnector(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['connectorKey'],
                  ),
        ),
      },
    );
    connectors['conversation'] = _i1.EndpointConnector(
      name: 'conversation',
      endpoint: endpoints['conversation']!,
      methodConnectors: {
        'listEscalated': _i1.MethodConnector(
          name: 'listEscalated',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i5.ConversationEndpoint)
                  .listEscalated(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'listAll': _i1.MethodConnector(
          name: 'listAll',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i5.ConversationEndpoint)
                  .listAll(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'getMessages': _i1.MethodConnector(
          name: 'getMessages',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conversationId': _i1.ParameterDescription(
              name: 'conversationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i5.ConversationEndpoint)
                  .getMessages(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['conversationId'],
                  ),
        ),
        'sendHumanReply': _i1.MethodConnector(
          name: 'sendHumanReply',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conversationId': _i1.ParameterDescription(
              name: 'conversationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'body': _i1.ParameterDescription(
              name: 'body',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i5.ConversationEndpoint)
                  .sendHumanReply(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['conversationId'],
                    params['body'],
                  ),
        ),
        'closeConversation': _i1.MethodConnector(
          name: 'closeConversation',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'conversationId': _i1.ParameterDescription(
              name: 'conversationId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['conversation'] as _i5.ConversationEndpoint)
                  .closeConversation(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['conversationId'],
                  ),
        ),
      },
    );
    connectors['errand'] = _i1.EndpointConnector(
      name: 'errand',
      endpoint: endpoints['errand']!,
      methodConnectors: {
        'createBuiltinErrand': _i1.MethodConnector(
          name: 'createBuiltinErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'descriptionForAi': _i1.ParameterDescription(
              name: 'descriptionForAi',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'builtinHandlerKey': _i1.ParameterDescription(
              name: 'builtinHandlerKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'createdVia': _i1.ParameterDescription(
              name: 'createdVia',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'permissionScope': _i1.ParameterDescription(
              name: 'permissionScope',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'inputSchemaJson': _i1.ParameterDescription(
              name: 'inputSchemaJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sensitiveInputKeysJson': _i1.ParameterDescription(
              name: 'sensitiveInputKeysJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint)
                  .createBuiltinErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['name'],
                    params['descriptionForAi'],
                    params['builtinHandlerKey'],
                    params['createdVia'],
                    permissionScope: params['permissionScope'],
                    inputSchemaJson: params['inputSchemaJson'],
                    sensitiveInputKeysJson: params['sensitiveInputKeysJson'],
                  ),
        ),
        'listErrandsForWorkspace': _i1.MethodConnector(
          name: 'listErrandsForWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint)
                  .listErrandsForWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'getErrand': _i1.MethodConnector(
          name: 'getErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'errandId': _i1.ParameterDescription(
              name: 'errandId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint).getErrand(
                session,
                params['accessToken'],
                params['workspaceId'],
                params['errandId'],
              ),
        ),
        'setErrandStatus': _i1.MethodConnector(
          name: 'setErrandStatus',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'errandId': _i1.ParameterDescription(
              name: 'errandId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['errand'] as _i6.ErrandEndpoint).setErrandStatus(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['errandId'],
                    params['status'],
                  ),
        ),
        'deleteErrand': _i1.MethodConnector(
          name: 'deleteErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'errandId': _i1.ParameterDescription(
              name: 'errandId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['errand'] as _i6.ErrandEndpoint).deleteErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['errandId'],
                  ),
        ),
        'executeBuiltinErrand': _i1.MethodConnector(
          name: 'executeBuiltinErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'errandId': _i1.ParameterDescription(
              name: 'errandId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'inputJson': _i1.ParameterDescription(
              name: 'inputJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint)
                  .executeBuiltinErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['errandId'],
                    params['inputJson'],
                  ),
        ),
        'createWebhookErrand': _i1.MethodConnector(
          name: 'createWebhookErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'descriptionForAi': _i1.ParameterDescription(
              name: 'descriptionForAi',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'createdVia': _i1.ParameterDescription(
              name: 'createdVia',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'webhookUrl': _i1.ParameterDescription(
              name: 'webhookUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'authHeaderName': _i1.ParameterDescription(
              name: 'authHeaderName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'authHeaderValue': _i1.ParameterDescription(
              name: 'authHeaderValue',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'permissionScope': _i1.ParameterDescription(
              name: 'permissionScope',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'inputSchemaJson': _i1.ParameterDescription(
              name: 'inputSchemaJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sensitiveInputKeysJson': _i1.ParameterDescription(
              name: 'sensitiveInputKeysJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint)
                  .createWebhookErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['name'],
                    params['descriptionForAi'],
                    params['createdVia'],
                    params['webhookUrl'],
                    authHeaderName: params['authHeaderName'],
                    authHeaderValue: params['authHeaderValue'],
                    permissionScope: params['permissionScope'],
                    inputSchemaJson: params['inputSchemaJson'],
                    sensitiveInputKeysJson: params['sensitiveInputKeysJson'],
                  ),
        ),
        'createDbCredentialErrand': _i1.MethodConnector(
          name: 'createDbCredentialErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'descriptionForAi': _i1.ParameterDescription(
              name: 'descriptionForAi',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'createdVia': _i1.ParameterDescription(
              name: 'createdVia',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'queryTemplateSql': _i1.ParameterDescription(
              name: 'queryTemplateSql',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'connectionString': _i1.ParameterDescription(
              name: 'connectionString',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'permissionScope': _i1.ParameterDescription(
              name: 'permissionScope',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'inputSchemaJson': _i1.ParameterDescription(
              name: 'inputSchemaJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sensitiveInputKeysJson': _i1.ParameterDescription(
              name: 'sensitiveInputKeysJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['errand'] as _i6.ErrandEndpoint)
                  .createDbCredentialErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['name'],
                    params['descriptionForAi'],
                    params['createdVia'],
                    params['queryTemplateSql'],
                    params['connectionString'],
                    permissionScope: params['permissionScope'],
                    inputSchemaJson: params['inputSchemaJson'],
                    sensitiveInputKeysJson: params['sensitiveInputKeysJson'],
                  ),
        ),
        'executeErrand': _i1.MethodConnector(
          name: 'executeErrand',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'errandId': _i1.ParameterDescription(
              name: 'errandId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'inputJson': _i1.ParameterDescription(
              name: 'inputJson',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['errand'] as _i6.ErrandEndpoint).executeErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['errandId'],
                    params['inputJson'],
                  ),
        ),
      },
    );
    connectors['feature'] = _i1.EndpointConnector(
      name: 'feature',
      endpoint: endpoints['feature']!,
      methodConnectors: {
        'listEnabledFeatures': _i1.MethodConnector(
          name: 'listEnabledFeatures',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['feature'] as _i7.FeatureEndpoint)
                  .listEnabledFeatures(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'isFeatureEnabled': _i1.MethodConnector(
          name: 'isFeatureEnabled',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'featureKey': _i1.ParameterDescription(
              name: 'featureKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['feature'] as _i7.FeatureEndpoint)
                  .isFeatureEnabled(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['featureKey'],
                  ),
        ),
      },
    );
    connectors['finding'] = _i1.EndpointConnector(
      name: 'finding',
      endpoint: endpoints['finding']!,
      methodConnectors: {
        'listFindings': _i1.MethodConnector(
          name: 'listFindings',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['finding'] as _i8.FindingEndpoint).listFindings(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'dismissFinding': _i1.MethodConnector(
          name: 'dismissFinding',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'findingId': _i1.ParameterDescription(
              name: 'findingId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['finding'] as _i8.FindingEndpoint).dismissFinding(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['findingId'],
                  ),
        ),
      },
    );
    connectors['knowledge'] = _i1.EndpointConnector(
      name: 'knowledge',
      endpoint: endpoints['knowledge']!,
      methodConnectors: {
        'listDocuments': _i1.MethodConnector(
          name: 'listDocuments',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .listDocuments(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'addDocument': _i1.MethodConnector(
          name: 'addDocument',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'text': _i1.ParameterDescription(
              name: 'text',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'allowDuplicate': _i1.ParameterDescription(
              name: 'allowDuplicate',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['knowledge'] as _i9.KnowledgeEndpoint).addDocument(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['title'],
                    params['text'],
                    allowDuplicate: params['allowDuplicate'],
                  ),
        ),
        'deleteDocument': _i1.MethodConnector(
          name: 'deleteDocument',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'documentId': _i1.ParameterDescription(
              name: 'documentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .deleteDocument(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['documentId'],
                  ),
        ),
        'updateDocument': _i1.MethodConnector(
          name: 'updateDocument',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'documentId': _i1.ParameterDescription(
              name: 'documentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'text': _i1.ParameterDescription(
              name: 'text',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .updateDocument(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['documentId'],
                    params['title'],
                    params['text'],
                  ),
        ),
        'searchMemory': _i1.MethodConnector(
          name: 'searchMemory',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .searchMemory(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['query'],
                  ),
        ),
        'askWorkspace': _i1.MethodConnector(
          name: 'askWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'question': _i1.ParameterDescription(
              name: 'question',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .askWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['question'],
                  ),
        ),
        'addDocumentFromFile': _i1.MethodConnector(
          name: 'addDocumentFromFile',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'fileName': _i1.ParameterDescription(
              name: 'fileName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'base64Bytes': _i1.ParameterDescription(
              name: 'base64Bytes',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'allowDuplicate': _i1.ParameterDescription(
              name: 'allowDuplicate',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['knowledge'] as _i9.KnowledgeEndpoint)
                  .addDocumentFromFile(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['fileName'],
                    params['base64Bytes'],
                    allowDuplicate: params['allowDuplicate'],
                  ),
        ),
      },
    );
    connectors['ownerNotification'] = _i1.EndpointConnector(
      name: 'ownerNotification',
      endpoint: endpoints['ownerNotification']!,
      methodConnectors: {
        'getSettings': _i1.MethodConnector(
          name: 'getSettings',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ownerNotification']
                          as _i10.OwnerNotificationEndpoint)
                      .getSettings(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                      ),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'ownerEmail': _i1.ParameterDescription(
              name: 'ownerEmail',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'emailEnabled': _i1.ParameterDescription(
              name: 'emailEnabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'ownerWhatsappNumber': _i1.ParameterDescription(
              name: 'ownerWhatsappNumber',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'whatsappEnabled': _i1.ParameterDescription(
              name: 'whatsappEnabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'telegramChatId': _i1.ParameterDescription(
              name: 'telegramChatId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'telegramEnabled': _i1.ParameterDescription(
              name: 'telegramEnabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'ownerSmsNumber': _i1.ParameterDescription(
              name: 'ownerSmsNumber',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'smsEnabled': _i1.ParameterDescription(
              name: 'smsEnabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'slackWebhookUrl': _i1.ParameterDescription(
              name: 'slackWebhookUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'slackEnabled': _i1.ParameterDescription(
              name: 'slackEnabled',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['ownerNotification']
                          as _i10.OwnerNotificationEndpoint)
                      .updateSettings(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        ownerEmail: params['ownerEmail'],
                        emailEnabled: params['emailEnabled'],
                        ownerWhatsappNumber: params['ownerWhatsappNumber'],
                        whatsappEnabled: params['whatsappEnabled'],
                        telegramChatId: params['telegramChatId'],
                        telegramEnabled: params['telegramEnabled'],
                        ownerSmsNumber: params['ownerSmsNumber'],
                        smsEnabled: params['smsEnabled'],
                        slackWebhookUrl: params['slackWebhookUrl'],
                        slackEnabled: params['slackEnabled'],
                      ),
        ),
      },
    );
    connectors['payment'] = _i1.EndpointConnector(
      name: 'payment',
      endpoint: endpoints['payment']!,
      methodConnectors: {
        'connectGateway': _i1.MethodConnector(
          name: 'connectGateway',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'gateway': _i1.ParameterDescription(
              name: 'gateway',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'secretKey': _i1.ParameterDescription(
              name: 'secretKey',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'webhookSecret': _i1.ParameterDescription(
              name: 'webhookSecret',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payment'] as _i11.PaymentEndpoint).connectGateway(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['gateway'],
                    params['secretKey'],
                    webhookSecret: params['webhookSecret'],
                  ),
        ),
        'listConnectedGateways': _i1.MethodConnector(
          name: 'listConnectedGateways',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['payment'] as _i11.PaymentEndpoint)
                  .listConnectedGateways(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'initializeCheckout': _i1.MethodConnector(
          name: 'initializeCheckout',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'gateway': _i1.ParameterDescription(
              name: 'gateway',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'amountKobo': _i1.ParameterDescription(
              name: 'amountKobo',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'customerEmail': _i1.ParameterDescription(
              name: 'customerEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'customerPhone': _i1.ParameterDescription(
              name: 'customerPhone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'holdInEscrow': _i1.ParameterDescription(
              name: 'holdInEscrow',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'conversationId': _i1.ParameterDescription(
              name: 'conversationId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'metadata': _i1.ParameterDescription(
              name: 'metadata',
              type: _i1.getType<Map<String, dynamic>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['payment'] as _i11.PaymentEndpoint)
                  .initializeCheckout(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['gateway'],
                    params['amountKobo'],
                    params['customerEmail'],
                    customerPhone: params['customerPhone'],
                    holdInEscrow: params['holdInEscrow'],
                    conversationId: params['conversationId'],
                    channelId: params['channelId'],
                    metadata: params['metadata'],
                  ),
        ),
        'getTransaction': _i1.MethodConnector(
          name: 'getTransaction',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'transactionId': _i1.ParameterDescription(
              name: 'transactionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payment'] as _i11.PaymentEndpoint).getTransaction(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['transactionId'],
                  ),
        ),
        'releaseHold': _i1.MethodConnector(
          name: 'releaseHold',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'transactionId': _i1.ParameterDescription(
              name: 'transactionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['payment'] as _i11.PaymentEndpoint).releaseHold(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['transactionId'],
                  ),
        ),
      },
    );
    connectors['platform'] = _i1.EndpointConnector(
      name: 'platform',
      endpoint: endpoints['platform']!,
      methodConnectors: {
        'listApiKeys': _i1.MethodConnector(
          name: 'listApiKeys',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['platform'] as _i12.PlatformEndpoint).listApiKeys(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'createApiKey': _i1.MethodConnector(
          name: 'createApiKey',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'scope': _i1.ParameterDescription(
              name: 'scope',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['platform'] as _i12.PlatformEndpoint).createApiKey(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['name'],
                    params['scope'],
                  ),
        ),
        'revokeApiKey': _i1.MethodConnector(
          name: 'revokeApiKey',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'keyId': _i1.ParameterDescription(
              name: 'keyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['platform'] as _i12.PlatformEndpoint).revokeApiKey(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['keyId'],
                  ),
        ),
        'listWebhookEndpoints': _i1.MethodConnector(
          name: 'listWebhookEndpoints',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['platform'] as _i12.PlatformEndpoint)
                  .listWebhookEndpoints(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'saveWebhookEndpoint': _i1.MethodConnector(
          name: 'saveWebhookEndpoint',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'url': _i1.ParameterDescription(
              name: 'url',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'events': _i1.ParameterDescription(
              name: 'events',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['platform'] as _i12.PlatformEndpoint)
                  .saveWebhookEndpoint(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['url'],
                    params['events'],
                  ),
        ),
        'deleteWebhookEndpoint': _i1.MethodConnector(
          name: 'deleteWebhookEndpoint',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'endpointId': _i1.ParameterDescription(
              name: 'endpointId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['platform'] as _i12.PlatformEndpoint)
                  .deleteWebhookEndpoint(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['endpointId'],
                  ),
        ),
      },
    );
    connectors['product'] = _i1.EndpointConnector(
      name: 'product',
      endpoint: endpoints['product']!,
      methodConnectors: {
        'listProducts': _i1.MethodConnector(
          name: 'listProducts',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'includeArchived': _i1.ParameterDescription(
              name: 'includeArchived',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).listProducts(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    includeArchived: params['includeArchived'],
                  ),
        ),
        'getProduct': _i1.MethodConnector(
          name: 'getProduct',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).getProduct(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                  ),
        ),
        'listVariants': _i1.MethodConnector(
          name: 'listVariants',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).listVariants(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                  ),
        ),
        'createProduct': _i1.MethodConnector(
          name: 'createProduct',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'archetype': _i1.ParameterDescription(
              name: 'archetype',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sku': _i1.ParameterDescription(
              name: 'sku',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'priceMinor': _i1.ParameterDescription(
              name: 'priceMinor',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'priceCurrency': _i1.ParameterDescription(
              name: 'priceCurrency',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'priceUnit': _i1.ParameterDescription(
              name: 'priceUnit',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'costMinor': _i1.ParameterDescription(
              name: 'costMinor',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'stock': _i1.ParameterDescription(
              name: 'stock',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'lowStockThreshold': _i1.ParameterDescription(
              name: 'lowStockThreshold',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).createProduct(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['name'],
                    description: params['description'],
                    archetype: params['archetype'],
                    sku: params['sku'],
                    category: params['category'],
                    priceMinor: params['priceMinor'],
                    priceCurrency: params['priceCurrency'],
                    priceUnit: params['priceUnit'],
                    costMinor: params['costMinor'],
                    stock: params['stock'],
                    lowStockThreshold: params['lowStockThreshold'],
                  ),
        ),
        'updateProduct': _i1.MethodConnector(
          name: 'updateProduct',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'description': _i1.ParameterDescription(
              name: 'description',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'archetype': _i1.ParameterDescription(
              name: 'archetype',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'sku': _i1.ParameterDescription(
              name: 'sku',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'priceMinor': _i1.ParameterDescription(
              name: 'priceMinor',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'clearPrice': _i1.ParameterDescription(
              name: 'clearPrice',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'priceCurrency': _i1.ParameterDescription(
              name: 'priceCurrency',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'priceUnit': _i1.ParameterDescription(
              name: 'priceUnit',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'costMinor': _i1.ParameterDescription(
              name: 'costMinor',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'stock': _i1.ParameterDescription(
              name: 'stock',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'clearStock': _i1.ParameterDescription(
              name: 'clearStock',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
            'lowStockThreshold': _i1.ParameterDescription(
              name: 'lowStockThreshold',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).updateProduct(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    name: params['name'],
                    description: params['description'],
                    archetype: params['archetype'],
                    sku: params['sku'],
                    category: params['category'],
                    priceMinor: params['priceMinor'],
                    clearPrice: params['clearPrice'],
                    priceCurrency: params['priceCurrency'],
                    priceUnit: params['priceUnit'],
                    costMinor: params['costMinor'],
                    stock: params['stock'],
                    clearStock: params['clearStock'],
                    lowStockThreshold: params['lowStockThreshold'],
                  ),
        ),
        'archiveProduct': _i1.MethodConnector(
          name: 'archiveProduct',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).archiveProduct(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                  ),
        ),
        'replaceVariants': _i1.MethodConnector(
          name: 'replaceVariants',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'labels': _i1.ParameterDescription(
              name: 'labels',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
            'stocks': _i1.ParameterDescription(
              name: 'stocks',
              type: _i1.getType<List<int?>>(),
              nullable: false,
            ),
            'priceMinors': _i1.ParameterDescription(
              name: 'priceMinors',
              type: _i1.getType<List<int?>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .replaceVariants(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    params['labels'],
                    params['stocks'],
                    params['priceMinors'],
                  ),
        ),
        'getMediaUploadAuth': _i1.MethodConnector(
          name: 'getMediaUploadAuth',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .getMediaUploadAuth(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'listMedia': _i1.MethodConnector(
          name: 'listMedia',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['product'] as _i13.ProductEndpoint).listMedia(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                  ),
        ),
        'listMediaForProducts': _i1.MethodConnector(
          name: 'listMediaForProducts',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productIds': _i1.ParameterDescription(
              name: 'productIds',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .listMediaForProducts(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productIds'],
                  ),
        ),
        'addProductMedia': _i1.MethodConnector(
          name: 'addProductMedia',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'imagekitFileId': _i1.ParameterDescription(
              name: 'imagekitFileId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'url': _i1.ParameterDescription(
              name: 'url',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'kind': _i1.ParameterDescription(
              name: 'kind',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'thumbnailUrl': _i1.ParameterDescription(
              name: 'thumbnailUrl',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'width': _i1.ParameterDescription(
              name: 'width',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'height': _i1.ParameterDescription(
              name: 'height',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .addProductMedia(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    params['imagekitFileId'],
                    params['url'],
                    kind: params['kind'],
                    thumbnailUrl: params['thumbnailUrl'],
                    width: params['width'],
                    height: params['height'],
                  ),
        ),
        'deleteProductMedia': _i1.MethodConnector(
          name: 'deleteProductMedia',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'mediaId': _i1.ParameterDescription(
              name: 'mediaId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .deleteProductMedia(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    params['mediaId'],
                  ),
        ),
        'reorderProductMedia': _i1.MethodConnector(
          name: 'reorderProductMedia',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'mediaIdsInOrder': _i1.ParameterDescription(
              name: 'mediaIdsInOrder',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .reorderProductMedia(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    params['mediaIdsInOrder'],
                  ),
        ),
        'importMediaFromUrl': _i1.MethodConnector(
          name: 'importMediaFromUrl',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'productId': _i1.ParameterDescription(
              name: 'productId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'sourceUrl': _i1.ParameterDescription(
              name: 'sourceUrl',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['product'] as _i13.ProductEndpoint)
                  .importMediaFromUrl(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['productId'],
                    params['sourceUrl'],
                  ),
        ),
      },
    );
    connectors['supportTicket'] = _i1.EndpointConnector(
      name: 'supportTicket',
      endpoint: endpoints['supportTicket']!,
      methodConnectors: {
        'list': _i1.MethodConnector(
          name: 'list',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['supportTicket'] as _i14.SupportTicketEndpoint)
                      .list(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        status: params['status'],
                      ),
        ),
        'setStatus': _i1.MethodConnector(
          name: 'setStatus',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'ticketId': _i1.ParameterDescription(
              name: 'ticketId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'status': _i1.ParameterDescription(
              name: 'status',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['supportTicket'] as _i14.SupportTicketEndpoint)
                      .setStatus(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        params['ticketId'],
                        params['status'],
                      ),
        ),
      },
    );
    connectors['waitlist'] = _i1.EndpointConnector(
      name: 'waitlist',
      endpoint: endpoints['waitlist']!,
      methodConnectors: {
        'joinWaitlist': _i1.MethodConnector(
          name: 'joinWaitlist',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'source': _i1.ParameterDescription(
              name: 'source',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'phone': _i1.ParameterDescription(
              name: 'phone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'businessType': _i1.ParameterDescription(
              name: 'businessType',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['waitlist'] as _i15.WaitlistEndpoint).joinWaitlist(
                    session,
                    params['email'],
                    params['source'],
                    name: params['name'],
                    phone: params['phone'],
                    businessType: params['businessType'],
                  ),
        ),
      },
    );
    connectors['whatsAppTemplate'] = _i1.EndpointConnector(
      name: 'whatsAppTemplate',
      endpoint: endpoints['whatsAppTemplate']!,
      methodConnectors: {
        'createTemplate': _i1.MethodConnector(
          name: 'createTemplate',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'label': _i1.ParameterDescription(
              name: 'label',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'category': _i1.ParameterDescription(
              name: 'category',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bodyText': _i1.ParameterDescription(
              name: 'bodyText',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'bodyExampleValues': _i1.ParameterDescription(
              name: 'bodyExampleValues',
              type: _i1.getType<List<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['whatsAppTemplate']
                          as _i16.WhatsAppTemplateEndpoint)
                      .createTemplate(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        params['channelId'],
                        params['label'],
                        params['category'],
                        params['language'],
                        params['bodyText'],
                        params['bodyExampleValues'],
                      ),
        ),
        'createProductListTemplate': _i1.MethodConnector(
          name: 'createProductListTemplate',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'businessLabel': _i1.ParameterDescription(
              name: 'businessLabel',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'customerNameExample': _i1.ParameterDescription(
              name: 'customerNameExample',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'productListExample': _i1.ParameterDescription(
              name: 'productListExample',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['whatsAppTemplate']
                          as _i16.WhatsAppTemplateEndpoint)
                      .createProductListTemplate(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        params['channelId'],
                        params['businessLabel'],
                        params['customerNameExample'],
                        params['productListExample'],
                      ),
        ),
        'listTemplatesForWorkspace': _i1.MethodConnector(
          name: 'listTemplatesForWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['whatsAppTemplate']
                          as _i16.WhatsAppTemplateEndpoint)
                      .listTemplatesForWorkspace(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                      ),
        ),
        'refreshTemplateStatus': _i1.MethodConnector(
          name: 'refreshTemplateStatus',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'templateId': _i1.ParameterDescription(
              name: 'templateId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['whatsAppTemplate']
                          as _i16.WhatsAppTemplateEndpoint)
                      .refreshTemplateStatus(
                        session,
                        params['accessToken'],
                        params['workspaceId'],
                        params['templateId'],
                      ),
        ),
      },
    );
    connectors['workspace'] = _i1.EndpointConnector(
      name: 'workspace',
      endpoint: endpoints['workspace']!,
      methodConnectors: {
        'createWorkspace': _i1.MethodConnector(
          name: 'createWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'industryTag': _i1.ParameterDescription(
              name: 'industryTag',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'ownerName': _i1.ParameterDescription(
              name: 'ownerName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'ownerPhone': _i1.ParameterDescription(
              name: 'ownerPhone',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .createWorkspace(
                    session,
                    params['accessToken'],
                    params['name'],
                    params['industryTag'],
                    ownerName: params['ownerName'],
                    ownerPhone: params['ownerPhone'],
                  ),
        ),
        'listMyWorkspaces': _i1.MethodConnector(
          name: 'listMyWorkspaces',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .listMyWorkspaces(
                    session,
                    params['accessToken'],
                  ),
        ),
        'getWorkspace': _i1.MethodConnector(
          name: 'getWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .getWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'updateWorkspace': _i1.MethodConnector(
          name: 'updateWorkspace',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'industryTag': _i1.ParameterDescription(
              name: 'industryTag',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'ownerName': _i1.ParameterDescription(
              name: 'ownerName',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .updateWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    name: params['name'],
                    industryTag: params['industryTag'],
                    ownerName: params['ownerName'],
                  ),
        ),
        'getBillingSummary': _i1.MethodConnector(
          name: 'getBillingSummary',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .getBillingSummary(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                  ),
        ),
        'initiateUpgrade': _i1.MethodConnector(
          name: 'initiateUpgrade',
          params: {
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'workspaceId': _i1.ParameterDescription(
              name: 'workspaceId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'gateway': _i1.ParameterDescription(
              name: 'gateway',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'customerEmail': _i1.ParameterDescription(
              name: 'customerEmail',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i17.WorkspaceEndpoint)
                  .initiateUpgrade(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['gateway'],
                    params['customerEmail'],
                  ),
        ),
      },
    );
  }
}
