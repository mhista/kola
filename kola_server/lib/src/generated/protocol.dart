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
import 'calendar_booking.dart' as _i5;
import 'channel.dart' as _i6;
import 'connector_field_spec.dart' as _i7;
import 'connector_status.dart' as _i8;
import 'connector_sync_log.dart' as _i9;
import 'conversation.dart' as _i10;
import 'created_api_key.dart' as _i11;
import 'customer.dart' as _i12;
import 'customer_detail.dart' as _i13;
import 'customer_identity_signal.dart' as _i14;
import 'customer_merge_proposal.dart' as _i15;
import 'customer_profile.dart' as _i16;
import 'errand.dart' as _i17;
import 'errand_credential.dart' as _i18;
import 'errand_execution_log.dart' as _i19;
import 'event.dart' as _i20;
import 'feature_flag.dart' as _i21;
import 'google_drive_spreadsheet.dart' as _i22;
import 'knowledge_chunk.dart' as _i23;
import 'knowledge_document.dart' as _i24;
import 'knowledge_search_hit.dart' as _i25;
import 'kola_billing_checkout.dart' as _i26;
import 'kola_exception.dart' as _i27;
import 'message.dart' as _i28;
import 'otp_code.dart' as _i29;
import 'owner_notification_send.dart' as _i30;
import 'owner_notification_settings.dart' as _i31;
import 'payment_bank_account.dart' as _i32;
import 'payment_gateway_credential.dart' as _i33;
import 'payment_transaction.dart' as _i34;
import 'product.dart' as _i35;
import 'product_media.dart' as _i36;
import 'product_variant.dart' as _i37;
import 'sale.dart' as _i38;
import 'sale_line.dart' as _i39;
import 'sale_line_input.dart' as _i40;
import 'subscription.dart' as _i41;
import 'support_ticket.dart' as _i42;
import 'usage_record.dart' as _i43;
import 'waitlist_signup.dart' as _i44;
import 'webhook_endpoint.dart' as _i45;
import 'whatsapp_message_template.dart' as _i46;
import 'workspace.dart' as _i47;
import 'workspace_answer.dart' as _i48;
import 'workspace_answer_action.dart' as _i49;
import 'workspace_answer_turn.dart' as _i50;
import 'workspace_connector.dart' as _i51;
import 'workspace_feature_override.dart' as _i52;
import 'workspace_finding.dart' as _i53;
import 'workspace_member.dart' as _i54;
import 'package:kola_server/src/generated/bot.dart' as _i55;
import 'package:kola_server/src/generated/channel.dart' as _i56;
import 'package:kola_server/src/generated/connector_status.dart' as _i57;
import 'package:kola_server/src/generated/google_drive_spreadsheet.dart'
    as _i58;
import 'package:kola_server/src/generated/calendar_booking.dart' as _i59;
import 'package:kola_server/src/generated/conversation.dart' as _i60;
import 'package:kola_server/src/generated/message.dart' as _i61;
import 'package:kola_server/src/generated/customer.dart' as _i62;
import 'package:kola_server/src/generated/customer_merge_proposal.dart' as _i63;
import 'package:kola_server/src/generated/errand.dart' as _i64;
import 'package:kola_server/src/generated/workspace_finding.dart' as _i65;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i66;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i67;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i68;
import 'package:kola_server/src/generated/api_key.dart' as _i69;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i70;
import 'package:kola_server/src/generated/product.dart' as _i71;
import 'package:kola_server/src/generated/product_variant.dart' as _i72;
import 'package:kola_server/src/generated/product_media.dart' as _i73;
import 'package:kola_server/src/generated/sale_line_input.dart' as _i74;
import 'package:kola_server/src/generated/sale.dart' as _i75;
import 'package:kola_server/src/generated/sale_line.dart' as _i76;
import 'package:kola_server/src/generated/support_ticket.dart' as _i77;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i78;
import 'package:kola_server/src/generated/workspace.dart' as _i79;
export 'api_key.dart';
export 'bot.dart';
export 'calendar_booking.dart';
export 'channel.dart';
export 'connector_field_spec.dart';
export 'connector_status.dart';
export 'connector_sync_log.dart';
export 'conversation.dart';
export 'created_api_key.dart';
export 'customer.dart';
export 'customer_detail.dart';
export 'customer_identity_signal.dart';
export 'customer_merge_proposal.dart';
export 'customer_profile.dart';
export 'errand.dart';
export 'errand_credential.dart';
export 'errand_execution_log.dart';
export 'event.dart';
export 'feature_flag.dart';
export 'google_drive_spreadsheet.dart';
export 'knowledge_chunk.dart';
export 'knowledge_document.dart';
export 'knowledge_search_hit.dart';
export 'kola_billing_checkout.dart';
export 'kola_exception.dart';
export 'message.dart';
export 'otp_code.dart';
export 'owner_notification_send.dart';
export 'owner_notification_settings.dart';
export 'payment_bank_account.dart';
export 'payment_gateway_credential.dart';
export 'payment_transaction.dart';
export 'product.dart';
export 'product_media.dart';
export 'product_variant.dart';
export 'sale.dart';
export 'sale_line.dart';
export 'sale_line_input.dart';
export 'subscription.dart';
export 'support_ticket.dart';
export 'usage_record.dart';
export 'waitlist_signup.dart';
export 'webhook_endpoint.dart';
export 'whatsapp_message_template.dart';
export 'workspace.dart';
export 'workspace_answer.dart';
export 'workspace_answer_action.dart';
export 'workspace_answer_turn.dart';
export 'workspace_connector.dart';
export 'workspace_feature_override.dart';
export 'workspace_finding.dart';
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
    if (t == _i5.CalendarBooking) {
      return _i5.CalendarBooking.fromJson(data) as T;
    }
    if (t == _i6.Channel) {
      return _i6.Channel.fromJson(data) as T;
    }
    if (t == _i7.ConnectorFieldSpec) {
      return _i7.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i8.ConnectorStatus) {
      return _i8.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i9.ConnectorSyncLog) {
      return _i9.ConnectorSyncLog.fromJson(data) as T;
    }
    if (t == _i10.Conversation) {
      return _i10.Conversation.fromJson(data) as T;
    }
    if (t == _i11.CreatedApiKey) {
      return _i11.CreatedApiKey.fromJson(data) as T;
    }
    if (t == _i12.Customer) {
      return _i12.Customer.fromJson(data) as T;
    }
    if (t == _i13.CustomerDetail) {
      return _i13.CustomerDetail.fromJson(data) as T;
    }
    if (t == _i14.CustomerIdentitySignal) {
      return _i14.CustomerIdentitySignal.fromJson(data) as T;
    }
    if (t == _i15.CustomerMergeProposal) {
      return _i15.CustomerMergeProposal.fromJson(data) as T;
    }
    if (t == _i16.CustomerProfile) {
      return _i16.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i17.Errand) {
      return _i17.Errand.fromJson(data) as T;
    }
    if (t == _i18.ErrandCredential) {
      return _i18.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i19.ErrandExecutionLog) {
      return _i19.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i20.Event) {
      return _i20.Event.fromJson(data) as T;
    }
    if (t == _i21.FeatureFlag) {
      return _i21.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i22.GoogleDriveSpreadsheet) {
      return _i22.GoogleDriveSpreadsheet.fromJson(data) as T;
    }
    if (t == _i23.KnowledgeChunk) {
      return _i23.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i24.KnowledgeDocument) {
      return _i24.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i25.KnowledgeSearchHit) {
      return _i25.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i26.KolaBillingCheckout) {
      return _i26.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i27.KolaException) {
      return _i27.KolaException.fromJson(data) as T;
    }
    if (t == _i28.Message) {
      return _i28.Message.fromJson(data) as T;
    }
    if (t == _i29.OtpCode) {
      return _i29.OtpCode.fromJson(data) as T;
    }
    if (t == _i30.OwnerNotificationSend) {
      return _i30.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i31.OwnerNotificationSettings) {
      return _i31.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i32.PaymentBankAccount) {
      return _i32.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i33.PaymentGatewayCredential) {
      return _i33.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i34.PaymentTransaction) {
      return _i34.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i35.Product) {
      return _i35.Product.fromJson(data) as T;
    }
    if (t == _i36.ProductMedia) {
      return _i36.ProductMedia.fromJson(data) as T;
    }
    if (t == _i37.ProductVariant) {
      return _i37.ProductVariant.fromJson(data) as T;
    }
    if (t == _i38.Sale) {
      return _i38.Sale.fromJson(data) as T;
    }
    if (t == _i39.SaleLine) {
      return _i39.SaleLine.fromJson(data) as T;
    }
    if (t == _i40.SaleLineInput) {
      return _i40.SaleLineInput.fromJson(data) as T;
    }
    if (t == _i41.Subscription) {
      return _i41.Subscription.fromJson(data) as T;
    }
    if (t == _i42.SupportTicket) {
      return _i42.SupportTicket.fromJson(data) as T;
    }
    if (t == _i43.UsageRecord) {
      return _i43.UsageRecord.fromJson(data) as T;
    }
    if (t == _i44.WaitlistSignup) {
      return _i44.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i45.WebhookEndpoint) {
      return _i45.WebhookEndpoint.fromJson(data) as T;
    }
    if (t == _i46.WhatsAppMessageTemplate) {
      return _i46.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i47.Workspace) {
      return _i47.Workspace.fromJson(data) as T;
    }
    if (t == _i48.WorkspaceAnswer) {
      return _i48.WorkspaceAnswer.fromJson(data) as T;
    }
    if (t == _i49.WorkspaceAnswerAction) {
      return _i49.WorkspaceAnswerAction.fromJson(data) as T;
    }
    if (t == _i50.WorkspaceAnswerTurn) {
      return _i50.WorkspaceAnswerTurn.fromJson(data) as T;
    }
    if (t == _i51.WorkspaceConnector) {
      return _i51.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i52.WorkspaceFeatureOverride) {
      return _i52.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i53.WorkspaceFinding) {
      return _i53.WorkspaceFinding.fromJson(data) as T;
    }
    if (t == _i54.WorkspaceMember) {
      return _i54.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.ApiKey?>()) {
      return (data != null ? _i3.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Bot?>()) {
      return (data != null ? _i4.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.CalendarBooking?>()) {
      return (data != null ? _i5.CalendarBooking.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Channel?>()) {
      return (data != null ? _i6.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ConnectorFieldSpec?>()) {
      return (data != null ? _i7.ConnectorFieldSpec.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ConnectorStatus?>()) {
      return (data != null ? _i8.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ConnectorSyncLog?>()) {
      return (data != null ? _i9.ConnectorSyncLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Conversation?>()) {
      return (data != null ? _i10.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.CreatedApiKey?>()) {
      return (data != null ? _i11.CreatedApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Customer?>()) {
      return (data != null ? _i12.Customer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.CustomerDetail?>()) {
      return (data != null ? _i13.CustomerDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CustomerIdentitySignal?>()) {
      return (data != null ? _i14.CustomerIdentitySignal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.CustomerMergeProposal?>()) {
      return (data != null ? _i15.CustomerMergeProposal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.CustomerProfile?>()) {
      return (data != null ? _i16.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Errand?>()) {
      return (data != null ? _i17.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ErrandCredential?>()) {
      return (data != null ? _i18.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.ErrandExecutionLog?>()) {
      return (data != null ? _i19.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.Event?>()) {
      return (data != null ? _i20.Event.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.FeatureFlag?>()) {
      return (data != null ? _i21.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.GoogleDriveSpreadsheet?>()) {
      return (data != null ? _i22.GoogleDriveSpreadsheet.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.KnowledgeChunk?>()) {
      return (data != null ? _i23.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.KnowledgeDocument?>()) {
      return (data != null ? _i24.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.KnowledgeSearchHit?>()) {
      return (data != null ? _i25.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i26.KolaBillingCheckout?>()) {
      return (data != null ? _i26.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.KolaException?>()) {
      return (data != null ? _i27.KolaException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.Message?>()) {
      return (data != null ? _i28.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.OtpCode?>()) {
      return (data != null ? _i29.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.OwnerNotificationSend?>()) {
      return (data != null ? _i30.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i31.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i32.PaymentBankAccount?>()) {
      return (data != null ? _i32.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i33.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i33.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i34.PaymentTransaction?>()) {
      return (data != null ? _i34.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i35.Product?>()) {
      return (data != null ? _i35.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.ProductMedia?>()) {
      return (data != null ? _i36.ProductMedia.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.ProductVariant?>()) {
      return (data != null ? _i37.ProductVariant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.Sale?>()) {
      return (data != null ? _i38.Sale.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.SaleLine?>()) {
      return (data != null ? _i39.SaleLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.SaleLineInput?>()) {
      return (data != null ? _i40.SaleLineInput.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.Subscription?>()) {
      return (data != null ? _i41.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.SupportTicket?>()) {
      return (data != null ? _i42.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.UsageRecord?>()) {
      return (data != null ? _i43.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.WaitlistSignup?>()) {
      return (data != null ? _i44.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.WebhookEndpoint?>()) {
      return (data != null ? _i45.WebhookEndpoint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i46.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i47.Workspace?>()) {
      return (data != null ? _i47.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.WorkspaceAnswer?>()) {
      return (data != null ? _i48.WorkspaceAnswer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.WorkspaceAnswerAction?>()) {
      return (data != null ? _i49.WorkspaceAnswerAction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i50.WorkspaceAnswerTurn?>()) {
      return (data != null ? _i50.WorkspaceAnswerTurn.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i51.WorkspaceConnector?>()) {
      return (data != null ? _i51.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i52.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i52.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i53.WorkspaceFinding?>()) {
      return (data != null ? _i53.WorkspaceFinding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.WorkspaceMember?>()) {
      return (data != null ? _i54.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i7.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i7.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.CustomerIdentitySignal>) {
      return (data as List)
              .map((e) => deserialize<_i14.CustomerIdentitySignal>(e))
              .toList()
          as T;
    }
    if (t == List<_i10.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i10.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.PaymentTransaction>) {
      return (data as List)
              .map((e) => deserialize<_i34.PaymentTransaction>(e))
              .toList()
          as T;
    }
    if (t == List<_i38.Sale>) {
      return (data as List).map((e) => deserialize<_i38.Sale>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i49.WorkspaceAnswerAction>) {
      return (data as List)
              .map((e) => deserialize<_i49.WorkspaceAnswerAction>(e))
              .toList()
          as T;
    }
    if (t == List<_i25.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i25.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i55.Bot>) {
      return (data as List).map((e) => deserialize<_i55.Bot>(e)).toList() as T;
    }
    if (t == List<_i56.Channel>) {
      return (data as List).map((e) => deserialize<_i56.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i57.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i57.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i58.GoogleDriveSpreadsheet>) {
      return (data as List)
              .map((e) => deserialize<_i58.GoogleDriveSpreadsheet>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i59.CalendarBooking>) {
      return (data as List)
              .map((e) => deserialize<_i59.CalendarBooking>(e))
              .toList()
          as T;
    }
    if (t == List<_i60.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i60.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i61.Message>) {
      return (data as List).map((e) => deserialize<_i61.Message>(e)).toList()
          as T;
    }
    if (t == List<_i62.Customer>) {
      return (data as List).map((e) => deserialize<_i62.Customer>(e)).toList()
          as T;
    }
    if (t == List<_i63.CustomerMergeProposal>) {
      return (data as List)
              .map((e) => deserialize<_i63.CustomerMergeProposal>(e))
              .toList()
          as T;
    }
    if (t == List<_i64.Errand>) {
      return (data as List).map((e) => deserialize<_i64.Errand>(e)).toList()
          as T;
    }
    if (t == List<_i65.WorkspaceFinding>) {
      return (data as List)
              .map((e) => deserialize<_i65.WorkspaceFinding>(e))
              .toList()
          as T;
    }
    if (t == List<_i66.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i66.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i67.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i67.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i68.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i68.PaymentGatewayCredential>(e))
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
    if (t == List<_i69.ApiKey>) {
      return (data as List).map((e) => deserialize<_i69.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i70.WebhookEndpoint>) {
      return (data as List)
              .map((e) => deserialize<_i70.WebhookEndpoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i71.Product>) {
      return (data as List).map((e) => deserialize<_i71.Product>(e)).toList()
          as T;
    }
    if (t == List<_i72.ProductVariant>) {
      return (data as List)
              .map((e) => deserialize<_i72.ProductVariant>(e))
              .toList()
          as T;
    }
    if (t == List<int?>) {
      return (data as List).map((e) => deserialize<int?>(e)).toList() as T;
    }
    if (t == List<_i73.ProductMedia>) {
      return (data as List)
              .map((e) => deserialize<_i73.ProductMedia>(e))
              .toList()
          as T;
    }
    if (t == List<_i74.SaleLineInput>) {
      return (data as List)
              .map((e) => deserialize<_i74.SaleLineInput>(e))
              .toList()
          as T;
    }
    if (t == List<_i75.Sale>) {
      return (data as List).map((e) => deserialize<_i75.Sale>(e)).toList() as T;
    }
    if (t == List<_i76.SaleLine>) {
      return (data as List).map((e) => deserialize<_i76.SaleLine>(e)).toList()
          as T;
    }
    if (t == List<_i77.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i77.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i78.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i78.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i79.Workspace>) {
      return (data as List).map((e) => deserialize<_i79.Workspace>(e)).toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    // DIAGNOSTIC — temporary, added while tracking down the "No
    // deserialization found for type List<SaleLineInput>" 500 on
    // /sale/ringUpSale. Every branch above (including the
    // List<SaleLineInput> one) is a plain `if (t == SomeType)` — if
    // none matched, execution falls all the way through to here, one
    // line before the framework throws its generic "No deserialization
    // found" error with no further detail. This print runs right
    // before that, so the container log shows exactly what `t` (and
    // its runtime identity) was AT THE MOMENT deserialization failed —
    // safe to delete once the SaleLineInput issue is confirmed fixed,
    // and harmless (stdout only) if left in.
    // ignore: avoid_print
    print(
      '[Protocol.deserialize] no branch matched — t=$t (${t.runtimeType}), '
      'data.runtimeType=${data.runtimeType}, '
      'List<_i74.SaleLineInput> == t? ${t == List<_i74.SaleLineInput>}',
    );
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.ApiKey => 'ApiKey',
      _i4.Bot => 'Bot',
      _i5.CalendarBooking => 'CalendarBooking',
      _i6.Channel => 'Channel',
      _i7.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i8.ConnectorStatus => 'ConnectorStatus',
      _i9.ConnectorSyncLog => 'ConnectorSyncLog',
      _i10.Conversation => 'Conversation',
      _i11.CreatedApiKey => 'CreatedApiKey',
      _i12.Customer => 'Customer',
      _i13.CustomerDetail => 'CustomerDetail',
      _i14.CustomerIdentitySignal => 'CustomerIdentitySignal',
      _i15.CustomerMergeProposal => 'CustomerMergeProposal',
      _i16.CustomerProfile => 'CustomerProfile',
      _i17.Errand => 'Errand',
      _i18.ErrandCredential => 'ErrandCredential',
      _i19.ErrandExecutionLog => 'ErrandExecutionLog',
      _i20.Event => 'Event',
      _i21.FeatureFlag => 'FeatureFlag',
      _i22.GoogleDriveSpreadsheet => 'GoogleDriveSpreadsheet',
      _i23.KnowledgeChunk => 'KnowledgeChunk',
      _i24.KnowledgeDocument => 'KnowledgeDocument',
      _i25.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i26.KolaBillingCheckout => 'KolaBillingCheckout',
      _i27.KolaException => 'KolaException',
      _i28.Message => 'Message',
      _i29.OtpCode => 'OtpCode',
      _i30.OwnerNotificationSend => 'OwnerNotificationSend',
      _i31.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i32.PaymentBankAccount => 'PaymentBankAccount',
      _i33.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i34.PaymentTransaction => 'PaymentTransaction',
      _i35.Product => 'Product',
      _i36.ProductMedia => 'ProductMedia',
      _i37.ProductVariant => 'ProductVariant',
      _i38.Sale => 'Sale',
      _i39.SaleLine => 'SaleLine',
      _i40.SaleLineInput => 'SaleLineInput',
      _i41.Subscription => 'Subscription',
      _i42.SupportTicket => 'SupportTicket',
      _i43.UsageRecord => 'UsageRecord',
      _i44.WaitlistSignup => 'WaitlistSignup',
      _i45.WebhookEndpoint => 'WebhookEndpoint',
      _i46.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i47.Workspace => 'Workspace',
      _i48.WorkspaceAnswer => 'WorkspaceAnswer',
      _i49.WorkspaceAnswerAction => 'WorkspaceAnswerAction',
      _i50.WorkspaceAnswerTurn => 'WorkspaceAnswerTurn',
      _i51.WorkspaceConnector => 'WorkspaceConnector',
      _i52.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i53.WorkspaceFinding => 'WorkspaceFinding',
      _i54.WorkspaceMember => 'WorkspaceMember',
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
      case _i5.CalendarBooking():
        return 'CalendarBooking';
      case _i6.Channel():
        return 'Channel';
      case _i7.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i8.ConnectorStatus():
        return 'ConnectorStatus';
      case _i9.ConnectorSyncLog():
        return 'ConnectorSyncLog';
      case _i10.Conversation():
        return 'Conversation';
      case _i11.CreatedApiKey():
        return 'CreatedApiKey';
      case _i12.Customer():
        return 'Customer';
      case _i13.CustomerDetail():
        return 'CustomerDetail';
      case _i14.CustomerIdentitySignal():
        return 'CustomerIdentitySignal';
      case _i15.CustomerMergeProposal():
        return 'CustomerMergeProposal';
      case _i16.CustomerProfile():
        return 'CustomerProfile';
      case _i17.Errand():
        return 'Errand';
      case _i18.ErrandCredential():
        return 'ErrandCredential';
      case _i19.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i20.Event():
        return 'Event';
      case _i21.FeatureFlag():
        return 'FeatureFlag';
      case _i22.GoogleDriveSpreadsheet():
        return 'GoogleDriveSpreadsheet';
      case _i23.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i24.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i25.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i26.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i27.KolaException():
        return 'KolaException';
      case _i28.Message():
        return 'Message';
      case _i29.OtpCode():
        return 'OtpCode';
      case _i30.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i31.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i32.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i33.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i34.PaymentTransaction():
        return 'PaymentTransaction';
      case _i35.Product():
        return 'Product';
      case _i36.ProductMedia():
        return 'ProductMedia';
      case _i37.ProductVariant():
        return 'ProductVariant';
      case _i38.Sale():
        return 'Sale';
      case _i39.SaleLine():
        return 'SaleLine';
      case _i40.SaleLineInput():
        return 'SaleLineInput';
      case _i41.Subscription():
        return 'Subscription';
      case _i42.SupportTicket():
        return 'SupportTicket';
      case _i43.UsageRecord():
        return 'UsageRecord';
      case _i44.WaitlistSignup():
        return 'WaitlistSignup';
      case _i45.WebhookEndpoint():
        return 'WebhookEndpoint';
      case _i46.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i47.Workspace():
        return 'Workspace';
      case _i48.WorkspaceAnswer():
        return 'WorkspaceAnswer';
      case _i49.WorkspaceAnswerAction():
        return 'WorkspaceAnswerAction';
      case _i50.WorkspaceAnswerTurn():
        return 'WorkspaceAnswerTurn';
      case _i51.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i52.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i53.WorkspaceFinding():
        return 'WorkspaceFinding';
      case _i54.WorkspaceMember():
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
    if (dataClassName == 'CalendarBooking') {
      return deserialize<_i5.CalendarBooking>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i6.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i7.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i8.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'ConnectorSyncLog') {
      return deserialize<_i9.ConnectorSyncLog>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i10.Conversation>(data['data']);
    }
    if (dataClassName == 'CreatedApiKey') {
      return deserialize<_i11.CreatedApiKey>(data['data']);
    }
    if (dataClassName == 'Customer') {
      return deserialize<_i12.Customer>(data['data']);
    }
    if (dataClassName == 'CustomerDetail') {
      return deserialize<_i13.CustomerDetail>(data['data']);
    }
    if (dataClassName == 'CustomerIdentitySignal') {
      return deserialize<_i14.CustomerIdentitySignal>(data['data']);
    }
    if (dataClassName == 'CustomerMergeProposal') {
      return deserialize<_i15.CustomerMergeProposal>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i16.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i17.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i18.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i19.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'Event') {
      return deserialize<_i20.Event>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i21.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'GoogleDriveSpreadsheet') {
      return deserialize<_i22.GoogleDriveSpreadsheet>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i23.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i24.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i25.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i26.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'KolaException') {
      return deserialize<_i27.KolaException>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i28.Message>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i29.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i30.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i31.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i32.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i33.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i34.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i35.Product>(data['data']);
    }
    if (dataClassName == 'ProductMedia') {
      return deserialize<_i36.ProductMedia>(data['data']);
    }
    if (dataClassName == 'ProductVariant') {
      return deserialize<_i37.ProductVariant>(data['data']);
    }
    if (dataClassName == 'Sale') {
      return deserialize<_i38.Sale>(data['data']);
    }
    if (dataClassName == 'SaleLine') {
      return deserialize<_i39.SaleLine>(data['data']);
    }
    if (dataClassName == 'SaleLineInput') {
      return deserialize<_i40.SaleLineInput>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i41.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i42.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i43.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i44.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WebhookEndpoint') {
      return deserialize<_i45.WebhookEndpoint>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i46.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i47.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswer') {
      return deserialize<_i48.WorkspaceAnswer>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerAction') {
      return deserialize<_i49.WorkspaceAnswerAction>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerTurn') {
      return deserialize<_i50.WorkspaceAnswerTurn>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i51.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i52.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceFinding') {
      return deserialize<_i53.WorkspaceFinding>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i54.WorkspaceMember>(data['data']);
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
