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
import 'api_key.dart' as _i2;
import 'bot.dart' as _i3;
import 'channel.dart' as _i4;
import 'connector_field_spec.dart' as _i5;
import 'connector_status.dart' as _i6;
import 'conversation.dart' as _i7;
import 'created_api_key.dart' as _i8;
import 'customer_profile.dart' as _i9;
import 'errand.dart' as _i10;
import 'errand_credential.dart' as _i11;
import 'errand_execution_log.dart' as _i12;
import 'feature_flag.dart' as _i13;
import 'knowledge_chunk.dart' as _i14;
import 'knowledge_document.dart' as _i15;
import 'knowledge_search_hit.dart' as _i16;
import 'kola_billing_checkout.dart' as _i17;
import 'message.dart' as _i18;
import 'otp_code.dart' as _i19;
import 'owner_notification_send.dart' as _i20;
import 'owner_notification_settings.dart' as _i21;
import 'payment_bank_account.dart' as _i22;
import 'payment_gateway_credential.dart' as _i23;
import 'payment_transaction.dart' as _i24;
import 'subscription.dart' as _i25;
import 'support_ticket.dart' as _i26;
import 'usage_record.dart' as _i27;
import 'waitlist_signup.dart' as _i28;
import 'webhook_endpoint.dart' as _i29;
import 'whatsapp_message_template.dart' as _i30;
import 'workspace.dart' as _i31;
import 'workspace_connector.dart' as _i32;
import 'workspace_feature_override.dart' as _i33;
import 'workspace_member.dart' as _i34;
import 'package:kola_client/src/protocol/bot.dart' as _i35;
import 'package:kola_client/src/protocol/channel.dart' as _i36;
import 'package:kola_client/src/protocol/connector_status.dart' as _i37;
import 'package:kola_client/src/protocol/conversation.dart' as _i38;
import 'package:kola_client/src/protocol/message.dart' as _i39;
import 'package:kola_client/src/protocol/errand.dart' as _i40;
import 'package:kola_client/src/protocol/knowledge_document.dart' as _i41;
import 'package:kola_client/src/protocol/knowledge_search_hit.dart' as _i42;
import 'package:kola_client/src/protocol/payment_gateway_credential.dart'
    as _i43;
import 'package:kola_client/src/protocol/api_key.dart' as _i44;
import 'package:kola_client/src/protocol/webhook_endpoint.dart' as _i45;
import 'package:kola_client/src/protocol/support_ticket.dart' as _i46;
import 'package:kola_client/src/protocol/whatsapp_message_template.dart'
    as _i47;
import 'package:kola_client/src/protocol/workspace.dart' as _i48;
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
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

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

    if (t == _i2.ApiKey) {
      return _i2.ApiKey.fromJson(data) as T;
    }
    if (t == _i3.Bot) {
      return _i3.Bot.fromJson(data) as T;
    }
    if (t == _i4.Channel) {
      return _i4.Channel.fromJson(data) as T;
    }
    if (t == _i5.ConnectorFieldSpec) {
      return _i5.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i6.ConnectorStatus) {
      return _i6.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i7.Conversation) {
      return _i7.Conversation.fromJson(data) as T;
    }
    if (t == _i8.CreatedApiKey) {
      return _i8.CreatedApiKey.fromJson(data) as T;
    }
    if (t == _i9.CustomerProfile) {
      return _i9.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i10.Errand) {
      return _i10.Errand.fromJson(data) as T;
    }
    if (t == _i11.ErrandCredential) {
      return _i11.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i12.ErrandExecutionLog) {
      return _i12.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i13.FeatureFlag) {
      return _i13.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i14.KnowledgeChunk) {
      return _i14.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i15.KnowledgeDocument) {
      return _i15.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i16.KnowledgeSearchHit) {
      return _i16.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i17.KolaBillingCheckout) {
      return _i17.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i18.Message) {
      return _i18.Message.fromJson(data) as T;
    }
    if (t == _i19.OtpCode) {
      return _i19.OtpCode.fromJson(data) as T;
    }
    if (t == _i20.OwnerNotificationSend) {
      return _i20.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i21.OwnerNotificationSettings) {
      return _i21.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i22.PaymentBankAccount) {
      return _i22.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i23.PaymentGatewayCredential) {
      return _i23.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i24.PaymentTransaction) {
      return _i24.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i25.Subscription) {
      return _i25.Subscription.fromJson(data) as T;
    }
    if (t == _i26.SupportTicket) {
      return _i26.SupportTicket.fromJson(data) as T;
    }
    if (t == _i27.UsageRecord) {
      return _i27.UsageRecord.fromJson(data) as T;
    }
    if (t == _i28.WaitlistSignup) {
      return _i28.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i29.WebhookEndpoint) {
      return _i29.WebhookEndpoint.fromJson(data) as T;
    }
    if (t == _i30.WhatsAppMessageTemplate) {
      return _i30.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i31.Workspace) {
      return _i31.Workspace.fromJson(data) as T;
    }
    if (t == _i32.WorkspaceConnector) {
      return _i32.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i33.WorkspaceFeatureOverride) {
      return _i33.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i34.WorkspaceMember) {
      return _i34.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.ApiKey?>()) {
      return (data != null ? _i2.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Bot?>()) {
      return (data != null ? _i3.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Channel?>()) {
      return (data != null ? _i4.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ConnectorFieldSpec?>()) {
      return (data != null ? _i5.ConnectorFieldSpec.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ConnectorStatus?>()) {
      return (data != null ? _i6.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Conversation?>()) {
      return (data != null ? _i7.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.CreatedApiKey?>()) {
      return (data != null ? _i8.CreatedApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.CustomerProfile?>()) {
      return (data != null ? _i9.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Errand?>()) {
      return (data != null ? _i10.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.ErrandCredential?>()) {
      return (data != null ? _i11.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ErrandExecutionLog?>()) {
      return (data != null ? _i12.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.FeatureFlag?>()) {
      return (data != null ? _i13.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.KnowledgeChunk?>()) {
      return (data != null ? _i14.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.KnowledgeDocument?>()) {
      return (data != null ? _i15.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.KnowledgeSearchHit?>()) {
      return (data != null ? _i16.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i17.KolaBillingCheckout?>()) {
      return (data != null ? _i17.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.Message?>()) {
      return (data != null ? _i18.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.OtpCode?>()) {
      return (data != null ? _i19.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.OwnerNotificationSend?>()) {
      return (data != null ? _i20.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i21.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i22.PaymentBankAccount?>()) {
      return (data != null ? _i22.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i23.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i24.PaymentTransaction?>()) {
      return (data != null ? _i24.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.Subscription?>()) {
      return (data != null ? _i25.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.SupportTicket?>()) {
      return (data != null ? _i26.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.UsageRecord?>()) {
      return (data != null ? _i27.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.WaitlistSignup?>()) {
      return (data != null ? _i28.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.WebhookEndpoint?>()) {
      return (data != null ? _i29.WebhookEndpoint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i30.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.Workspace?>()) {
      return (data != null ? _i31.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.WorkspaceConnector?>()) {
      return (data != null ? _i32.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i33.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i34.WorkspaceMember?>()) {
      return (data != null ? _i34.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i5.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i5.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i35.Bot>) {
      return (data as List).map((e) => deserialize<_i35.Bot>(e)).toList() as T;
    }
    if (t == List<_i36.Channel>) {
      return (data as List).map((e) => deserialize<_i36.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i37.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i37.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i38.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i38.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.Message>) {
      return (data as List).map((e) => deserialize<_i39.Message>(e)).toList()
          as T;
    }
    if (t == List<_i40.Errand>) {
      return (data as List).map((e) => deserialize<_i40.Errand>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i41.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i41.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i42.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i42.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i43.PaymentGatewayCredential>(e))
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
    if (t == List<_i44.ApiKey>) {
      return (data as List).map((e) => deserialize<_i44.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i45.WebhookEndpoint>) {
      return (data as List)
              .map((e) => deserialize<_i45.WebhookEndpoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i46.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i46.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i47.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i47.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i48.Workspace>) {
      return (data as List).map((e) => deserialize<_i48.Workspace>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ApiKey => 'ApiKey',
      _i3.Bot => 'Bot',
      _i4.Channel => 'Channel',
      _i5.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i6.ConnectorStatus => 'ConnectorStatus',
      _i7.Conversation => 'Conversation',
      _i8.CreatedApiKey => 'CreatedApiKey',
      _i9.CustomerProfile => 'CustomerProfile',
      _i10.Errand => 'Errand',
      _i11.ErrandCredential => 'ErrandCredential',
      _i12.ErrandExecutionLog => 'ErrandExecutionLog',
      _i13.FeatureFlag => 'FeatureFlag',
      _i14.KnowledgeChunk => 'KnowledgeChunk',
      _i15.KnowledgeDocument => 'KnowledgeDocument',
      _i16.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i17.KolaBillingCheckout => 'KolaBillingCheckout',
      _i18.Message => 'Message',
      _i19.OtpCode => 'OtpCode',
      _i20.OwnerNotificationSend => 'OwnerNotificationSend',
      _i21.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i22.PaymentBankAccount => 'PaymentBankAccount',
      _i23.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i24.PaymentTransaction => 'PaymentTransaction',
      _i25.Subscription => 'Subscription',
      _i26.SupportTicket => 'SupportTicket',
      _i27.UsageRecord => 'UsageRecord',
      _i28.WaitlistSignup => 'WaitlistSignup',
      _i29.WebhookEndpoint => 'WebhookEndpoint',
      _i30.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i31.Workspace => 'Workspace',
      _i32.WorkspaceConnector => 'WorkspaceConnector',
      _i33.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i34.WorkspaceMember => 'WorkspaceMember',
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
      case _i2.ApiKey():
        return 'ApiKey';
      case _i3.Bot():
        return 'Bot';
      case _i4.Channel():
        return 'Channel';
      case _i5.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i6.ConnectorStatus():
        return 'ConnectorStatus';
      case _i7.Conversation():
        return 'Conversation';
      case _i8.CreatedApiKey():
        return 'CreatedApiKey';
      case _i9.CustomerProfile():
        return 'CustomerProfile';
      case _i10.Errand():
        return 'Errand';
      case _i11.ErrandCredential():
        return 'ErrandCredential';
      case _i12.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i13.FeatureFlag():
        return 'FeatureFlag';
      case _i14.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i15.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i16.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i17.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i18.Message():
        return 'Message';
      case _i19.OtpCode():
        return 'OtpCode';
      case _i20.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i21.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i22.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i23.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i24.PaymentTransaction():
        return 'PaymentTransaction';
      case _i25.Subscription():
        return 'Subscription';
      case _i26.SupportTicket():
        return 'SupportTicket';
      case _i27.UsageRecord():
        return 'UsageRecord';
      case _i28.WaitlistSignup():
        return 'WaitlistSignup';
      case _i29.WebhookEndpoint():
        return 'WebhookEndpoint';
      case _i30.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i31.Workspace():
        return 'Workspace';
      case _i32.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i33.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i34.WorkspaceMember():
        return 'WorkspaceMember';
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
      return deserialize<_i2.ApiKey>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i3.Bot>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i4.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i5.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i6.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i7.Conversation>(data['data']);
    }
    if (dataClassName == 'CreatedApiKey') {
      return deserialize<_i8.CreatedApiKey>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i9.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i10.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i11.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i12.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i13.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i14.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i15.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i16.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i17.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i18.Message>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i19.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i20.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i21.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i22.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i23.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i24.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i25.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i26.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i27.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i28.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WebhookEndpoint') {
      return deserialize<_i29.WebhookEndpoint>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i30.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i31.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i32.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i33.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i34.WorkspaceMember>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
