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
import '../endpoints/conversation_endpoint.dart' as _i4;
import '../endpoints/errand_endpoint.dart' as _i5;
import '../endpoints/owner_notification_endpoint.dart' as _i6;
import '../endpoints/payment_endpoint.dart' as _i7;
import '../endpoints/support_ticket_endpoint.dart' as _i8;
import '../endpoints/waitlist_endpoint.dart' as _i9;
import '../endpoints/whatsapp_template_endpoint.dart' as _i10;
import '../endpoints/workspace_endpoint.dart' as _i11;

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
      'conversation': _i4.ConversationEndpoint()
        ..initialize(
          server,
          'conversation',
          null,
        ),
      'errand': _i5.ErrandEndpoint()
        ..initialize(
          server,
          'errand',
          null,
        ),
      'ownerNotification': _i6.OwnerNotificationEndpoint()
        ..initialize(
          server,
          'ownerNotification',
          null,
        ),
      'payment': _i7.PaymentEndpoint()
        ..initialize(
          server,
          'payment',
          null,
        ),
      'supportTicket': _i8.SupportTicketEndpoint()
        ..initialize(
          server,
          'supportTicket',
          null,
        ),
      'waitlist': _i9.WaitlistEndpoint()
        ..initialize(
          server,
          'waitlist',
          null,
        ),
      'whatsAppTemplate': _i10.WhatsAppTemplateEndpoint()
        ..initialize(
          server,
          'whatsAppTemplate',
          null,
        ),
      'workspace': _i11.WorkspaceEndpoint()
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
              ) async => (endpoints['conversation'] as _i4.ConversationEndpoint)
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
              ) async => (endpoints['conversation'] as _i4.ConversationEndpoint)
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
              ) async => (endpoints['conversation'] as _i4.ConversationEndpoint)
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
              ) async => (endpoints['conversation'] as _i4.ConversationEndpoint)
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
              ) async => (endpoints['conversation'] as _i4.ConversationEndpoint)
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint)
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint)
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint).getErrand(
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
                  (endpoints['errand'] as _i5.ErrandEndpoint).setErrandStatus(
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
                  (endpoints['errand'] as _i5.ErrandEndpoint).deleteErrand(
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint)
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint)
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
              ) async => (endpoints['errand'] as _i5.ErrandEndpoint)
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
                  (endpoints['errand'] as _i5.ErrandEndpoint).executeErrand(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['errandId'],
                    params['inputJson'],
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
                          as _i6.OwnerNotificationEndpoint)
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
                          as _i6.OwnerNotificationEndpoint)
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
                  (endpoints['payment'] as _i7.PaymentEndpoint).connectGateway(
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
              ) async => (endpoints['payment'] as _i7.PaymentEndpoint)
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
              ) async => (endpoints['payment'] as _i7.PaymentEndpoint)
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
                  (endpoints['payment'] as _i7.PaymentEndpoint).getTransaction(
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
                  (endpoints['payment'] as _i7.PaymentEndpoint).releaseHold(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
                    params['transactionId'],
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
                  (endpoints['supportTicket'] as _i8.SupportTicketEndpoint)
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
                  (endpoints['supportTicket'] as _i8.SupportTicketEndpoint)
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
                  (endpoints['waitlist'] as _i9.WaitlistEndpoint).joinWaitlist(
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
                          as _i10.WhatsAppTemplateEndpoint)
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
                          as _i10.WhatsAppTemplateEndpoint)
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
                          as _i10.WhatsAppTemplateEndpoint)
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
                          as _i10.WhatsAppTemplateEndpoint)
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
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['workspace'] as _i11.WorkspaceEndpoint)
                  .createWorkspace(
                    session,
                    params['accessToken'],
                    params['name'],
                    params['industryTag'],
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
              ) async => (endpoints['workspace'] as _i11.WorkspaceEndpoint)
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
              ) async => (endpoints['workspace'] as _i11.WorkspaceEndpoint)
                  .getWorkspace(
                    session,
                    params['accessToken'],
                    params['workspaceId'],
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
              ) async => (endpoints['workspace'] as _i11.WorkspaceEndpoint)
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
              ) async => (endpoints['workspace'] as _i11.WorkspaceEndpoint)
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
