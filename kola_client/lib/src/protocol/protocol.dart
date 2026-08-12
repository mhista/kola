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
import 'bot.dart' as _i2;
import 'channel.dart' as _i3;
import 'connector_field_spec.dart' as _i4;
import 'connector_status.dart' as _i5;
import 'conversation.dart' as _i6;
import 'customer_profile.dart' as _i7;
import 'errand.dart' as _i8;
import 'errand_credential.dart' as _i9;
import 'errand_execution_log.dart' as _i10;
import 'feature_flag.dart' as _i11;
import 'knowledge_chunk.dart' as _i12;
import 'knowledge_document.dart' as _i13;
import 'knowledge_search_hit.dart' as _i14;
import 'kola_billing_checkout.dart' as _i15;
import 'message.dart' as _i16;
import 'otp_code.dart' as _i17;
import 'owner_notification_send.dart' as _i18;
import 'owner_notification_settings.dart' as _i19;
import 'payment_bank_account.dart' as _i20;
import 'payment_gateway_credential.dart' as _i21;
import 'payment_transaction.dart' as _i22;
import 'subscription.dart' as _i23;
import 'support_ticket.dart' as _i24;
import 'usage_record.dart' as _i25;
import 'waitlist_signup.dart' as _i26;
import 'whatsapp_message_template.dart' as _i27;
import 'workspace.dart' as _i28;
import 'workspace_connector.dart' as _i29;
import 'workspace_feature_override.dart' as _i30;
import 'workspace_member.dart' as _i31;
import 'package:kola_client/src/protocol/bot.dart' as _i32;
import 'package:kola_client/src/protocol/channel.dart' as _i33;
import 'package:kola_client/src/protocol/connector_status.dart' as _i34;
import 'package:kola_client/src/protocol/conversation.dart' as _i35;
import 'package:kola_client/src/protocol/message.dart' as _i36;
import 'package:kola_client/src/protocol/errand.dart' as _i37;
import 'package:kola_client/src/protocol/knowledge_document.dart' as _i38;
import 'package:kola_client/src/protocol/knowledge_search_hit.dart' as _i39;
import 'package:kola_client/src/protocol/payment_gateway_credential.dart'
    as _i40;
import 'package:kola_client/src/protocol/support_ticket.dart' as _i41;
import 'package:kola_client/src/protocol/whatsapp_message_template.dart'
    as _i42;
import 'package:kola_client/src/protocol/workspace.dart' as _i43;
export 'bot.dart';
export 'channel.dart';
export 'connector_field_spec.dart';
export 'connector_status.dart';
export 'conversation.dart';
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

    if (t == _i2.Bot) {
      return _i2.Bot.fromJson(data) as T;
    }
    if (t == _i3.Channel) {
      return _i3.Channel.fromJson(data) as T;
    }
    if (t == _i4.ConnectorFieldSpec) {
      return _i4.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i5.ConnectorStatus) {
      return _i5.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i6.Conversation) {
      return _i6.Conversation.fromJson(data) as T;
    }
    if (t == _i7.CustomerProfile) {
      return _i7.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i8.Errand) {
      return _i8.Errand.fromJson(data) as T;
    }
    if (t == _i9.ErrandCredential) {
      return _i9.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i10.ErrandExecutionLog) {
      return _i10.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i11.FeatureFlag) {
      return _i11.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i12.KnowledgeChunk) {
      return _i12.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i13.KnowledgeDocument) {
      return _i13.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i14.KnowledgeSearchHit) {
      return _i14.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i15.KolaBillingCheckout) {
      return _i15.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i16.Message) {
      return _i16.Message.fromJson(data) as T;
    }
    if (t == _i17.OtpCode) {
      return _i17.OtpCode.fromJson(data) as T;
    }
    if (t == _i18.OwnerNotificationSend) {
      return _i18.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i19.OwnerNotificationSettings) {
      return _i19.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i20.PaymentBankAccount) {
      return _i20.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i21.PaymentGatewayCredential) {
      return _i21.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i22.PaymentTransaction) {
      return _i22.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i23.Subscription) {
      return _i23.Subscription.fromJson(data) as T;
    }
    if (t == _i24.SupportTicket) {
      return _i24.SupportTicket.fromJson(data) as T;
    }
    if (t == _i25.UsageRecord) {
      return _i25.UsageRecord.fromJson(data) as T;
    }
    if (t == _i26.WaitlistSignup) {
      return _i26.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i27.WhatsAppMessageTemplate) {
      return _i27.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i28.Workspace) {
      return _i28.Workspace.fromJson(data) as T;
    }
    if (t == _i29.WorkspaceConnector) {
      return _i29.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i30.WorkspaceFeatureOverride) {
      return _i30.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i31.WorkspaceMember) {
      return _i31.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Bot?>()) {
      return (data != null ? _i2.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Channel?>()) {
      return (data != null ? _i3.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ConnectorFieldSpec?>()) {
      return (data != null ? _i4.ConnectorFieldSpec.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ConnectorStatus?>()) {
      return (data != null ? _i5.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Conversation?>()) {
      return (data != null ? _i6.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.CustomerProfile?>()) {
      return (data != null ? _i7.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Errand?>()) {
      return (data != null ? _i8.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ErrandCredential?>()) {
      return (data != null ? _i9.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ErrandExecutionLog?>()) {
      return (data != null ? _i10.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.FeatureFlag?>()) {
      return (data != null ? _i11.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.KnowledgeChunk?>()) {
      return (data != null ? _i12.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.KnowledgeDocument?>()) {
      return (data != null ? _i13.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.KnowledgeSearchHit?>()) {
      return (data != null ? _i14.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.KolaBillingCheckout?>()) {
      return (data != null ? _i15.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.Message?>()) {
      return (data != null ? _i16.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.OtpCode?>()) {
      return (data != null ? _i17.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.OwnerNotificationSend?>()) {
      return (data != null ? _i18.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i19.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.PaymentBankAccount?>()) {
      return (data != null ? _i20.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i21.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i22.PaymentTransaction?>()) {
      return (data != null ? _i22.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.Subscription?>()) {
      return (data != null ? _i23.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.SupportTicket?>()) {
      return (data != null ? _i24.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.UsageRecord?>()) {
      return (data != null ? _i25.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.WaitlistSignup?>()) {
      return (data != null ? _i26.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i27.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.Workspace?>()) {
      return (data != null ? _i28.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.WorkspaceConnector?>()) {
      return (data != null ? _i29.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i30.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i30.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i31.WorkspaceMember?>()) {
      return (data != null ? _i31.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i4.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i4.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.Bot>) {
      return (data as List).map((e) => deserialize<_i32.Bot>(e)).toList() as T;
    }
    if (t == List<_i33.Channel>) {
      return (data as List).map((e) => deserialize<_i33.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i34.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i34.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i35.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i35.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i36.Message>) {
      return (data as List).map((e) => deserialize<_i36.Message>(e)).toList()
          as T;
    }
    if (t == List<_i37.Errand>) {
      return (data as List).map((e) => deserialize<_i37.Errand>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i38.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i38.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i39.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i40.PaymentGatewayCredential>(e))
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
    if (t == List<_i41.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i41.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i42.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i42.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i43.Workspace>) {
      return (data as List).map((e) => deserialize<_i43.Workspace>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Bot => 'Bot',
      _i3.Channel => 'Channel',
      _i4.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i5.ConnectorStatus => 'ConnectorStatus',
      _i6.Conversation => 'Conversation',
      _i7.CustomerProfile => 'CustomerProfile',
      _i8.Errand => 'Errand',
      _i9.ErrandCredential => 'ErrandCredential',
      _i10.ErrandExecutionLog => 'ErrandExecutionLog',
      _i11.FeatureFlag => 'FeatureFlag',
      _i12.KnowledgeChunk => 'KnowledgeChunk',
      _i13.KnowledgeDocument => 'KnowledgeDocument',
      _i14.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i15.KolaBillingCheckout => 'KolaBillingCheckout',
      _i16.Message => 'Message',
      _i17.OtpCode => 'OtpCode',
      _i18.OwnerNotificationSend => 'OwnerNotificationSend',
      _i19.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i20.PaymentBankAccount => 'PaymentBankAccount',
      _i21.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i22.PaymentTransaction => 'PaymentTransaction',
      _i23.Subscription => 'Subscription',
      _i24.SupportTicket => 'SupportTicket',
      _i25.UsageRecord => 'UsageRecord',
      _i26.WaitlistSignup => 'WaitlistSignup',
      _i27.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i28.Workspace => 'Workspace',
      _i29.WorkspaceConnector => 'WorkspaceConnector',
      _i30.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i31.WorkspaceMember => 'WorkspaceMember',
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
      case _i2.Bot():
        return 'Bot';
      case _i3.Channel():
        return 'Channel';
      case _i4.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i5.ConnectorStatus():
        return 'ConnectorStatus';
      case _i6.Conversation():
        return 'Conversation';
      case _i7.CustomerProfile():
        return 'CustomerProfile';
      case _i8.Errand():
        return 'Errand';
      case _i9.ErrandCredential():
        return 'ErrandCredential';
      case _i10.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i11.FeatureFlag():
        return 'FeatureFlag';
      case _i12.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i13.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i14.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i15.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i16.Message():
        return 'Message';
      case _i17.OtpCode():
        return 'OtpCode';
      case _i18.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i19.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i20.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i21.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i22.PaymentTransaction():
        return 'PaymentTransaction';
      case _i23.Subscription():
        return 'Subscription';
      case _i24.SupportTicket():
        return 'SupportTicket';
      case _i25.UsageRecord():
        return 'UsageRecord';
      case _i26.WaitlistSignup():
        return 'WaitlistSignup';
      case _i27.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i28.Workspace():
        return 'Workspace';
      case _i29.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i30.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i31.WorkspaceMember():
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
    if (dataClassName == 'Bot') {
      return deserialize<_i2.Bot>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i3.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i4.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i5.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i6.Conversation>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i7.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i8.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i9.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i10.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i11.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i12.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i13.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i14.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i15.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i16.Message>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i17.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i18.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i19.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i20.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i21.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i22.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i23.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i24.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i25.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i26.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i27.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i28.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i29.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i30.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i31.WorkspaceMember>(data['data']);
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
