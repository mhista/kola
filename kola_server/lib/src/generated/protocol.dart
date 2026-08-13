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
import 'package:serverpod/protocol.dart' as _i2;
import 'api_key.dart' as _i3;
import 'bot.dart' as _i4;
import 'channel.dart' as _i5;
import 'connector_field_spec.dart' as _i6;
import 'connector_status.dart' as _i7;
import 'conversation.dart' as _i8;
import 'created_api_key.dart' as _i9;
import 'customer_profile.dart' as _i10;
import 'errand.dart' as _i11;
import 'errand_credential.dart' as _i12;
import 'errand_execution_log.dart' as _i13;
import 'feature_flag.dart' as _i14;
import 'knowledge_chunk.dart' as _i15;
import 'knowledge_document.dart' as _i16;
import 'knowledge_search_hit.dart' as _i17;
import 'kola_billing_checkout.dart' as _i18;
import 'message.dart' as _i19;
import 'otp_code.dart' as _i20;
import 'owner_notification_send.dart' as _i21;
import 'owner_notification_settings.dart' as _i22;
import 'payment_bank_account.dart' as _i23;
import 'payment_gateway_credential.dart' as _i24;
import 'payment_transaction.dart' as _i25;
import 'subscription.dart' as _i26;
import 'support_ticket.dart' as _i27;
import 'usage_record.dart' as _i28;
import 'waitlist_signup.dart' as _i29;
import 'webhook_endpoint.dart' as _i30;
import 'whatsapp_message_template.dart' as _i31;
import 'workspace.dart' as _i32;
import 'workspace_connector.dart' as _i33;
import 'workspace_feature_override.dart' as _i34;
import 'workspace_member.dart' as _i35;
import 'package:kola_server/src/generated/bot.dart' as _i36;
import 'package:kola_server/src/generated/channel.dart' as _i37;
import 'package:kola_server/src/generated/connector_status.dart' as _i38;
import 'package:kola_server/src/generated/conversation.dart' as _i39;
import 'package:kola_server/src/generated/message.dart' as _i40;
import 'package:kola_server/src/generated/errand.dart' as _i41;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i42;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i43;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i44;
import 'package:kola_server/src/generated/api_key.dart' as _i45;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i46;
import 'package:kola_server/src/generated/support_ticket.dart' as _i47;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i48;
import 'package:kola_server/src/generated/workspace.dart' as _i49;
export 'api_key.dart';
export 'bot.dart';
export 'channel.dart';
export 'connector_field_spec.dart';
export 'connector_status.dart';
export 'conversation.dart';
export 'created_api_key.dart';
export 'customer_profile.dart';
export 'errand.dart';
export 'errand_credential.dart';
export 'errand_execution_log.dart';
export 'feature_flag.dart';
export 'knowledge_chunk.dart';
export 'knowledge_document.dart';
export 'knowledge_search_hit.dart';
export 'kola_billing_checkout.dart';
export 'message.dart';
export 'otp_code.dart';
export 'owner_notification_send.dart';
export 'owner_notification_settings.dart';
export 'payment_bank_account.dart';
export 'payment_gateway_credential.dart';
export 'payment_transaction.dart';
export 'subscription.dart';
export 'support_ticket.dart';
export 'usage_record.dart';
export 'waitlist_signup.dart';
export 'webhook_endpoint.dart';
export 'whatsapp_message_template.dart';
export 'workspace.dart';
export 'workspace_connector.dart';
export 'workspace_feature_override.dart';
export 'workspace_member.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3.ApiKey) {
      return _i3.ApiKey.fromJson(data) as T;
    }
    if (t == _i4.Bot) {
      return _i4.Bot.fromJson(data) as T;
    }
    if (t == _i5.Channel) {
      return _i5.Channel.fromJson(data) as T;
    }
    if (t == _i6.ConnectorFieldSpec) {
      return _i6.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i7.ConnectorStatus) {
      return _i7.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i8.Conversation) {
      return _i8.Conversation.fromJson(data) as T;
    }
    if (t == _i9.CreatedApiKey) {
      return _i9.CreatedApiKey.fromJson(data) as T;
    }
    if (t == _i10.CustomerProfile) {
      return _i10.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i11.Errand) {
      return _i11.Errand.fromJson(data) as T;
    }
    if (t == _i12.ErrandCredential) {
      return _i12.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i13.ErrandExecutionLog) {
      return _i13.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i14.FeatureFlag) {
      return _i14.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i15.KnowledgeChunk) {
      return _i15.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i16.KnowledgeDocument) {
      return _i16.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i17.KnowledgeSearchHit) {
      return _i17.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i18.KolaBillingCheckout) {
      return _i18.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i19.Message) {
      return _i19.Message.fromJson(data) as T;
    }
    if (t == _i20.OtpCode) {
      return _i20.OtpCode.fromJson(data) as T;
    }
    if (t == _i21.OwnerNotificationSend) {
      return _i21.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i22.OwnerNotificationSettings) {
      return _i22.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i23.PaymentBankAccount) {
      return _i23.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i24.PaymentGatewayCredential) {
      return _i24.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i25.PaymentTransaction) {
      return _i25.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i26.Subscription) {
      return _i26.Subscription.fromJson(data) as T;
    }
    if (t == _i27.SupportTicket) {
      return _i27.SupportTicket.fromJson(data) as T;
    }
    if (t == _i28.UsageRecord) {
      return _i28.UsageRecord.fromJson(data) as T;
    }
    if (t == _i29.WaitlistSignup) {
      return _i29.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i30.WebhookEndpoint) {
      return _i30.WebhookEndpoint.fromJson(data) as T;
    }
    if (t == _i31.WhatsAppMessageTemplate) {
      return _i31.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i32.Workspace) {
      return _i32.Workspace.fromJson(data) as T;
    }
    if (t == _i33.WorkspaceConnector) {
      return _i33.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i34.WorkspaceFeatureOverride) {
      return _i34.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i35.WorkspaceMember) {
      return _i35.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.ApiKey?>()) {
      return (data != null ? _i3.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Bot?>()) {
      return (data != null ? _i4.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Channel?>()) {
      return (data != null ? _i5.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ConnectorFieldSpec?>()) {
      return (data != null ? _i6.ConnectorFieldSpec.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ConnectorStatus?>()) {
      return (data != null ? _i7.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Conversation?>()) {
      return (data != null ? _i8.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.CreatedApiKey?>()) {
      return (data != null ? _i9.CreatedApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.CustomerProfile?>()) {
      return (data != null ? _i10.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Errand?>()) {
      return (data != null ? _i11.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ErrandCredential?>()) {
      return (data != null ? _i12.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ErrandExecutionLog?>()) {
      return (data != null ? _i13.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.FeatureFlag?>()) {
      return (data != null ? _i14.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.KnowledgeChunk?>()) {
      return (data != null ? _i15.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.KnowledgeDocument?>()) {
      return (data != null ? _i16.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.KnowledgeSearchHit?>()) {
      return (data != null ? _i17.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.KolaBillingCheckout?>()) {
      return (data != null ? _i18.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.Message?>()) {
      return (data != null ? _i19.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.OtpCode?>()) {
      return (data != null ? _i20.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.OwnerNotificationSend?>()) {
      return (data != null ? _i21.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i22.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i23.PaymentBankAccount?>()) {
      return (data != null ? _i23.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i24.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i25.PaymentTransaction?>()) {
      return (data != null ? _i25.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.Subscription?>()) {
      return (data != null ? _i26.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.SupportTicket?>()) {
      return (data != null ? _i27.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.UsageRecord?>()) {
      return (data != null ? _i28.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.WaitlistSignup?>()) {
      return (data != null ? _i29.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.WebhookEndpoint?>()) {
      return (data != null ? _i30.WebhookEndpoint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i31.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.Workspace?>()) {
      return (data != null ? _i32.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.WorkspaceConnector?>()) {
      return (data != null ? _i33.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i34.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i34.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i35.WorkspaceMember?>()) {
      return (data != null ? _i35.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i6.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i6.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i36.Bot>) {
      return (data as List).map((e) => deserialize<_i36.Bot>(e)).toList() as T;
    }
    if (t == List<_i37.Channel>) {
      return (data as List).map((e) => deserialize<_i37.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i38.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i38.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i39.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i39.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.Message>) {
      return (data as List).map((e) => deserialize<_i40.Message>(e)).toList()
          as T;
    }
    if (t == List<_i41.Errand>) {
      return (data as List).map((e) => deserialize<_i41.Errand>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i42.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i42.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i43.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i44.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i44.PaymentGatewayCredential>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == _i1.getType<Map<String, dynamic>?>()) {
      return (data != null
              ? (data as Map).map(
                  (k, v) =>
                      MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
                )
              : null)
          as T;
    }
    if (t == List<_i45.ApiKey>) {
      return (data as List).map((e) => deserialize<_i45.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i46.WebhookEndpoint>) {
      return (data as List)
              .map((e) => deserialize<_i46.WebhookEndpoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i47.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i47.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i48.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i48.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i49.Workspace>) {
      return (data as List).map((e) => deserialize<_i49.Workspace>(e)).toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.ApiKey => 'ApiKey',
      _i4.Bot => 'Bot',
      _i5.Channel => 'Channel',
      _i6.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i7.ConnectorStatus => 'ConnectorStatus',
      _i8.Conversation => 'Conversation',
      _i9.CreatedApiKey => 'CreatedApiKey',
      _i10.CustomerProfile => 'CustomerProfile',
      _i11.Errand => 'Errand',
      _i12.ErrandCredential => 'ErrandCredential',
      _i13.ErrandExecutionLog => 'ErrandExecutionLog',
      _i14.FeatureFlag => 'FeatureFlag',
      _i15.KnowledgeChunk => 'KnowledgeChunk',
      _i16.KnowledgeDocument => 'KnowledgeDocument',
      _i17.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i18.KolaBillingCheckout => 'KolaBillingCheckout',
      _i19.Message => 'Message',
      _i20.OtpCode => 'OtpCode',
      _i21.OwnerNotificationSend => 'OwnerNotificationSend',
      _i22.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i23.PaymentBankAccount => 'PaymentBankAccount',
      _i24.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i25.PaymentTransaction => 'PaymentTransaction',
      _i26.Subscription => 'Subscription',
      _i27.SupportTicket => 'SupportTicket',
      _i28.UsageRecord => 'UsageRecord',
      _i29.WaitlistSignup => 'WaitlistSignup',
      _i30.WebhookEndpoint => 'WebhookEndpoint',
      _i31.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i32.Workspace => 'Workspace',
      _i33.WorkspaceConnector => 'WorkspaceConnector',
      _i34.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i35.WorkspaceMember => 'WorkspaceMember',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('kola.', '');
    }

    switch (data) {
      case _i3.ApiKey():
        return 'ApiKey';
      case _i4.Bot():
        return 'Bot';
      case _i5.Channel():
        return 'Channel';
      case _i6.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i7.ConnectorStatus():
        return 'ConnectorStatus';
      case _i8.Conversation():
        return 'Conversation';
      case _i9.CreatedApiKey():
        return 'CreatedApiKey';
      case _i10.CustomerProfile():
        return 'CustomerProfile';
      case _i11.Errand():
        return 'Errand';
      case _i12.ErrandCredential():
        return 'ErrandCredential';
      case _i13.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i14.FeatureFlag():
        return 'FeatureFlag';
      case _i15.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i16.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i17.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i18.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i19.Message():
        return 'Message';
      case _i20.OtpCode():
        return 'OtpCode';
      case _i21.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i22.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i23.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i24.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i25.PaymentTransaction():
        return 'PaymentTransaction';
      case _i26.Subscription():
        return 'Subscription';
      case _i27.SupportTicket():
        return 'SupportTicket';
      case _i28.UsageRecord():
        return 'UsageRecord';
      case _i29.WaitlistSignup():
        return 'WaitlistSignup';
      case _i30.WebhookEndpoint():
        return 'WebhookEndpoint';
      case _i31.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i32.Workspace():
        return 'Workspace';
      case _i33.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i34.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i35.WorkspaceMember():
        return 'WorkspaceMember';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ApiKey') {
      return deserialize<_i3.ApiKey>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i4.Bot>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i5.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i6.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i7.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i8.Conversation>(data['data']);
    }
    if (dataClassName == 'CreatedApiKey') {
      return deserialize<_i9.CreatedApiKey>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i10.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i11.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i12.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i13.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i14.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i15.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i16.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i17.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i18.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i19.Message>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i20.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i21.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i22.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i23.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i24.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i25.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i26.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i27.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i28.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i29.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WebhookEndpoint') {
      return deserialize<_i30.WebhookEndpoint>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i31.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i32.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i33.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i34.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i35.WorkspaceMember>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'kola';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
