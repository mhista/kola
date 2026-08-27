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
import 'broadcast.dart' as _i5;
import 'broadcast_progress.dart' as _i6;
import 'broadcast_recipient.dart' as _i7;
import 'calendar_booking.dart' as _i8;
import 'channel.dart' as _i9;
import 'connector_field_spec.dart' as _i10;
import 'connector_status.dart' as _i11;
import 'connector_sync_log.dart' as _i12;
import 'conversation.dart' as _i13;
import 'created_api_key.dart' as _i14;
import 'customer.dart' as _i15;
import 'customer_detail.dart' as _i16;
import 'customer_identity_signal.dart' as _i17;
import 'customer_merge_proposal.dart' as _i18;
import 'customer_profile.dart' as _i19;
import 'end_of_day_report.dart' as _i20;
import 'errand.dart' as _i21;
import 'errand_credential.dart' as _i22;
import 'errand_execution_log.dart' as _i23;
import 'event.dart' as _i24;
import 'feature_flag.dart' as _i25;
import 'google_drive_spreadsheet.dart' as _i26;
import 'invoice.dart' as _i27;
import 'knowledge_chunk.dart' as _i28;
import 'knowledge_document.dart' as _i29;
import 'knowledge_search_hit.dart' as _i30;
import 'kola_billing_checkout.dart' as _i31;
import 'kola_exception.dart' as _i32;
import 'message.dart' as _i33;
import 'message_suppression.dart' as _i34;
import 'otp_code.dart' as _i35;
import 'owner_notification_send.dart' as _i36;
import 'owner_notification_settings.dart' as _i37;
import 'payment_bank_account.dart' as _i38;
import 'payment_gateway_credential.dart' as _i39;
import 'payment_transaction.dart' as _i40;
import 'product.dart' as _i41;
import 'product_media.dart' as _i42;
import 'product_variant.dart' as _i43;
import 'sale.dart' as _i44;
import 'sale_line.dart' as _i45;
import 'sale_line_input.dart' as _i46;
import 'subscription.dart' as _i47;
import 'support_ticket.dart' as _i48;
import 'usage_record.dart' as _i49;
import 'waitlist_signup.dart' as _i50;
import 'webhook_endpoint.dart' as _i51;
import 'whatsapp_message_template.dart' as _i52;
import 'workspace.dart' as _i53;
import 'workspace_answer.dart' as _i54;
import 'workspace_answer_action.dart' as _i55;
import 'workspace_answer_turn.dart' as _i56;
import 'workspace_connector.dart' as _i57;
import 'workspace_feature_override.dart' as _i58;
import 'workspace_finding.dart' as _i59;
import 'workspace_member.dart' as _i60;
import 'package:kola_server/src/generated/bot.dart' as _i61;
import 'package:kola_server/src/generated/broadcast.dart' as _i62;
import 'package:kola_server/src/generated/message_suppression.dart' as _i63;
import 'package:kola_server/src/generated/channel.dart' as _i64;
import 'package:kola_server/src/generated/connector_status.dart' as _i65;
import 'package:kola_server/src/generated/google_drive_spreadsheet.dart'
    as _i66;
import 'package:kola_server/src/generated/calendar_booking.dart' as _i67;
import 'package:kola_server/src/generated/conversation.dart' as _i68;
import 'package:kola_server/src/generated/message.dart' as _i69;
import 'package:kola_server/src/generated/customer.dart' as _i70;
import 'package:kola_server/src/generated/customer_merge_proposal.dart' as _i71;
import 'package:kola_server/src/generated/errand.dart' as _i72;
import 'package:kola_server/src/generated/workspace_finding.dart' as _i73;
import 'package:kola_server/src/generated/invoice.dart' as _i74;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i75;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i76;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i77;
import 'package:kola_server/src/generated/api_key.dart' as _i78;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i79;
import 'package:kola_server/src/generated/product.dart' as _i80;
import 'package:kola_server/src/generated/product_variant.dart' as _i81;
import 'package:kola_server/src/generated/product_media.dart' as _i82;
import 'package:kola_server/src/generated/sale.dart' as _i83;
import 'package:kola_server/src/generated/sale_line.dart' as _i84;
import 'package:kola_server/src/generated/support_ticket.dart' as _i85;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i86;
import 'package:kola_server/src/generated/workspace.dart' as _i87;
export 'api_key.dart';
export 'bot.dart';
export 'broadcast.dart';
export 'broadcast_progress.dart';
export 'broadcast_recipient.dart';
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
export 'end_of_day_report.dart';
export 'errand.dart';
export 'errand_credential.dart';
export 'errand_execution_log.dart';
export 'event.dart';
export 'feature_flag.dart';
export 'google_drive_spreadsheet.dart';
export 'invoice.dart';
export 'knowledge_chunk.dart';
export 'knowledge_document.dart';
export 'knowledge_search_hit.dart';
export 'kola_billing_checkout.dart';
export 'kola_exception.dart';
export 'message.dart';
export 'message_suppression.dart';
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
    if (t == _i5.Broadcast) {
      return _i5.Broadcast.fromJson(data) as T;
    }
    if (t == _i6.BroadcastProgress) {
      return _i6.BroadcastProgress.fromJson(data) as T;
    }
    if (t == _i7.BroadcastRecipient) {
      return _i7.BroadcastRecipient.fromJson(data) as T;
    }
    if (t == _i8.CalendarBooking) {
      return _i8.CalendarBooking.fromJson(data) as T;
    }
    if (t == _i9.Channel) {
      return _i9.Channel.fromJson(data) as T;
    }
    if (t == _i10.ConnectorFieldSpec) {
      return _i10.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i11.ConnectorStatus) {
      return _i11.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i12.ConnectorSyncLog) {
      return _i12.ConnectorSyncLog.fromJson(data) as T;
    }
    if (t == _i13.Conversation) {
      return _i13.Conversation.fromJson(data) as T;
    }
    if (t == _i14.CreatedApiKey) {
      return _i14.CreatedApiKey.fromJson(data) as T;
    }
    if (t == _i15.Customer) {
      return _i15.Customer.fromJson(data) as T;
    }
    if (t == _i16.CustomerDetail) {
      return _i16.CustomerDetail.fromJson(data) as T;
    }
    if (t == _i17.CustomerIdentitySignal) {
      return _i17.CustomerIdentitySignal.fromJson(data) as T;
    }
    if (t == _i18.CustomerMergeProposal) {
      return _i18.CustomerMergeProposal.fromJson(data) as T;
    }
    if (t == _i19.CustomerProfile) {
      return _i19.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i20.EndOfDayReport) {
      return _i20.EndOfDayReport.fromJson(data) as T;
    }
    if (t == _i21.Errand) {
      return _i21.Errand.fromJson(data) as T;
    }
    if (t == _i22.ErrandCredential) {
      return _i22.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i23.ErrandExecutionLog) {
      return _i23.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i24.Event) {
      return _i24.Event.fromJson(data) as T;
    }
    if (t == _i25.FeatureFlag) {
      return _i25.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i26.GoogleDriveSpreadsheet) {
      return _i26.GoogleDriveSpreadsheet.fromJson(data) as T;
    }
    if (t == _i27.Invoice) {
      return _i27.Invoice.fromJson(data) as T;
    }
    if (t == _i28.KnowledgeChunk) {
      return _i28.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i29.KnowledgeDocument) {
      return _i29.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i30.KnowledgeSearchHit) {
      return _i30.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i31.KolaBillingCheckout) {
      return _i31.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i32.KolaException) {
      return _i32.KolaException.fromJson(data) as T;
    }
    if (t == _i33.Message) {
      return _i33.Message.fromJson(data) as T;
    }
    if (t == _i34.MessageSuppression) {
      return _i34.MessageSuppression.fromJson(data) as T;
    }
    if (t == _i35.OtpCode) {
      return _i35.OtpCode.fromJson(data) as T;
    }
    if (t == _i36.OwnerNotificationSend) {
      return _i36.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i37.OwnerNotificationSettings) {
      return _i37.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i38.PaymentBankAccount) {
      return _i38.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i39.PaymentGatewayCredential) {
      return _i39.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i40.PaymentTransaction) {
      return _i40.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i41.Product) {
      return _i41.Product.fromJson(data) as T;
    }
    if (t == _i42.ProductMedia) {
      return _i42.ProductMedia.fromJson(data) as T;
    }
    if (t == _i43.ProductVariant) {
      return _i43.ProductVariant.fromJson(data) as T;
    }
    if (t == _i44.Sale) {
      return _i44.Sale.fromJson(data) as T;
    }
    if (t == _i45.SaleLine) {
      return _i45.SaleLine.fromJson(data) as T;
    }
    if (t == _i46.SaleLineInput) {
      return _i46.SaleLineInput.fromJson(data) as T;
    }
    if (t == _i47.Subscription) {
      return _i47.Subscription.fromJson(data) as T;
    }
    if (t == _i48.SupportTicket) {
      return _i48.SupportTicket.fromJson(data) as T;
    }
    if (t == _i49.UsageRecord) {
      return _i49.UsageRecord.fromJson(data) as T;
    }
    if (t == _i50.WaitlistSignup) {
      return _i50.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i51.WebhookEndpoint) {
      return _i51.WebhookEndpoint.fromJson(data) as T;
    }
    if (t == _i52.WhatsAppMessageTemplate) {
      return _i52.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i53.Workspace) {
      return _i53.Workspace.fromJson(data) as T;
    }
    if (t == _i54.WorkspaceAnswer) {
      return _i54.WorkspaceAnswer.fromJson(data) as T;
    }
    if (t == _i55.WorkspaceAnswerAction) {
      return _i55.WorkspaceAnswerAction.fromJson(data) as T;
    }
    if (t == _i56.WorkspaceAnswerTurn) {
      return _i56.WorkspaceAnswerTurn.fromJson(data) as T;
    }
    if (t == _i57.WorkspaceConnector) {
      return _i57.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i58.WorkspaceFeatureOverride) {
      return _i58.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i59.WorkspaceFinding) {
      return _i59.WorkspaceFinding.fromJson(data) as T;
    }
    if (t == _i60.WorkspaceMember) {
      return _i60.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.ApiKey?>()) {
      return (data != null ? _i3.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Bot?>()) {
      return (data != null ? _i4.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Broadcast?>()) {
      return (data != null ? _i5.Broadcast.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.BroadcastProgress?>()) {
      return (data != null ? _i6.BroadcastProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.BroadcastRecipient?>()) {
      return (data != null ? _i7.BroadcastRecipient.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.CalendarBooking?>()) {
      return (data != null ? _i8.CalendarBooking.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Channel?>()) {
      return (data != null ? _i9.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.ConnectorFieldSpec?>()) {
      return (data != null ? _i10.ConnectorFieldSpec.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.ConnectorStatus?>()) {
      return (data != null ? _i11.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.ConnectorSyncLog?>()) {
      return (data != null ? _i12.ConnectorSyncLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Conversation?>()) {
      return (data != null ? _i13.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CreatedApiKey?>()) {
      return (data != null ? _i14.CreatedApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Customer?>()) {
      return (data != null ? _i15.Customer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.CustomerDetail?>()) {
      return (data != null ? _i16.CustomerDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.CustomerIdentitySignal?>()) {
      return (data != null ? _i17.CustomerIdentitySignal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.CustomerMergeProposal?>()) {
      return (data != null ? _i18.CustomerMergeProposal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.CustomerProfile?>()) {
      return (data != null ? _i19.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.EndOfDayReport?>()) {
      return (data != null ? _i20.EndOfDayReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.Errand?>()) {
      return (data != null ? _i21.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.ErrandCredential?>()) {
      return (data != null ? _i22.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.ErrandExecutionLog?>()) {
      return (data != null ? _i23.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i24.Event?>()) {
      return (data != null ? _i24.Event.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.FeatureFlag?>()) {
      return (data != null ? _i25.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.GoogleDriveSpreadsheet?>()) {
      return (data != null ? _i26.GoogleDriveSpreadsheet.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.Invoice?>()) {
      return (data != null ? _i27.Invoice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.KnowledgeChunk?>()) {
      return (data != null ? _i28.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.KnowledgeDocument?>()) {
      return (data != null ? _i29.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.KnowledgeSearchHit?>()) {
      return (data != null ? _i30.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.KolaBillingCheckout?>()) {
      return (data != null ? _i31.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i32.KolaException?>()) {
      return (data != null ? _i32.KolaException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.Message?>()) {
      return (data != null ? _i33.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.MessageSuppression?>()) {
      return (data != null ? _i34.MessageSuppression.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i35.OtpCode?>()) {
      return (data != null ? _i35.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.OwnerNotificationSend?>()) {
      return (data != null ? _i36.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i37.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i37.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i38.PaymentBankAccount?>()) {
      return (data != null ? _i38.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i39.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i39.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i40.PaymentTransaction?>()) {
      return (data != null ? _i40.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i41.Product?>()) {
      return (data != null ? _i41.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.ProductMedia?>()) {
      return (data != null ? _i42.ProductMedia.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.ProductVariant?>()) {
      return (data != null ? _i43.ProductVariant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.Sale?>()) {
      return (data != null ? _i44.Sale.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i45.SaleLine?>()) {
      return (data != null ? _i45.SaleLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.SaleLineInput?>()) {
      return (data != null ? _i46.SaleLineInput.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.Subscription?>()) {
      return (data != null ? _i47.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.SupportTicket?>()) {
      return (data != null ? _i48.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.UsageRecord?>()) {
      return (data != null ? _i49.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.WaitlistSignup?>()) {
      return (data != null ? _i50.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.WebhookEndpoint?>()) {
      return (data != null ? _i51.WebhookEndpoint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i52.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i53.Workspace?>()) {
      return (data != null ? _i53.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.WorkspaceAnswer?>()) {
      return (data != null ? _i54.WorkspaceAnswer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i55.WorkspaceAnswerAction?>()) {
      return (data != null ? _i55.WorkspaceAnswerAction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i56.WorkspaceAnswerTurn?>()) {
      return (data != null ? _i56.WorkspaceAnswerTurn.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i57.WorkspaceConnector?>()) {
      return (data != null ? _i57.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i58.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i58.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i59.WorkspaceFinding?>()) {
      return (data != null ? _i59.WorkspaceFinding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i60.WorkspaceMember?>()) {
      return (data != null ? _i60.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i10.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i10.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<_i17.CustomerIdentitySignal>) {
      return (data as List)
              .map((e) => deserialize<_i17.CustomerIdentitySignal>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i13.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i40.PaymentTransaction>) {
      return (data as List)
              .map((e) => deserialize<_i40.PaymentTransaction>(e))
              .toList()
          as T;
    }
    if (t == List<_i44.Sale>) {
      return (data as List).map((e) => deserialize<_i44.Sale>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i55.WorkspaceAnswerAction>) {
      return (data as List)
              .map((e) => deserialize<_i55.WorkspaceAnswerAction>(e))
              .toList()
          as T;
    }
    if (t == List<_i30.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i30.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i61.Bot>) {
      return (data as List).map((e) => deserialize<_i61.Bot>(e)).toList() as T;
    }
    if (t == List<_i62.Broadcast>) {
      return (data as List).map((e) => deserialize<_i62.Broadcast>(e)).toList()
          as T;
    }
    if (t == List<_i63.MessageSuppression>) {
      return (data as List)
              .map((e) => deserialize<_i63.MessageSuppression>(e))
              .toList()
          as T;
    }
    if (t == List<_i64.Channel>) {
      return (data as List).map((e) => deserialize<_i64.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i65.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i65.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i66.GoogleDriveSpreadsheet>) {
      return (data as List)
              .map((e) => deserialize<_i66.GoogleDriveSpreadsheet>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i67.CalendarBooking>) {
      return (data as List)
              .map((e) => deserialize<_i67.CalendarBooking>(e))
              .toList()
          as T;
    }
    if (t == List<_i68.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i68.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i69.Message>) {
      return (data as List).map((e) => deserialize<_i69.Message>(e)).toList()
          as T;
    }
    if (t == List<_i70.Customer>) {
      return (data as List).map((e) => deserialize<_i70.Customer>(e)).toList()
          as T;
    }
    if (t == List<_i71.CustomerMergeProposal>) {
      return (data as List)
              .map((e) => deserialize<_i71.CustomerMergeProposal>(e))
              .toList()
          as T;
    }
    if (t == List<_i72.Errand>) {
      return (data as List).map((e) => deserialize<_i72.Errand>(e)).toList()
          as T;
    }
    if (t == List<_i73.WorkspaceFinding>) {
      return (data as List)
              .map((e) => deserialize<_i73.WorkspaceFinding>(e))
              .toList()
          as T;
    }
    if (t == List<_i74.Invoice>) {
      return (data as List).map((e) => deserialize<_i74.Invoice>(e)).toList()
          as T;
    }
    if (t == List<_i75.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i75.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i76.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i76.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i77.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i77.PaymentGatewayCredential>(e))
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
    if (t == List<_i78.ApiKey>) {
      return (data as List).map((e) => deserialize<_i78.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i79.WebhookEndpoint>) {
      return (data as List)
              .map((e) => deserialize<_i79.WebhookEndpoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i80.Product>) {
      return (data as List).map((e) => deserialize<_i80.Product>(e)).toList()
          as T;
    }
    if (t == List<_i81.ProductVariant>) {
      return (data as List)
              .map((e) => deserialize<_i81.ProductVariant>(e))
              .toList()
          as T;
    }
    if (t == List<int?>) {
      return (data as List).map((e) => deserialize<int?>(e)).toList() as T;
    }
    if (t == List<_i82.ProductMedia>) {
      return (data as List)
              .map((e) => deserialize<_i82.ProductMedia>(e))
              .toList()
          as T;
    }
    if (t == List<_i83.Sale>) {
      return (data as List).map((e) => deserialize<_i83.Sale>(e)).toList() as T;
    }
    if (t == List<_i84.SaleLine>) {
      return (data as List).map((e) => deserialize<_i84.SaleLine>(e)).toList()
          as T;
    }
    if (t == List<_i85.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i85.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i86.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i86.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i87.Workspace>) {
      return (data as List).map((e) => deserialize<_i87.Workspace>(e)).toList()
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
      _i5.Broadcast => 'Broadcast',
      _i6.BroadcastProgress => 'BroadcastProgress',
      _i7.BroadcastRecipient => 'BroadcastRecipient',
      _i8.CalendarBooking => 'CalendarBooking',
      _i9.Channel => 'Channel',
      _i10.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i11.ConnectorStatus => 'ConnectorStatus',
      _i12.ConnectorSyncLog => 'ConnectorSyncLog',
      _i13.Conversation => 'Conversation',
      _i14.CreatedApiKey => 'CreatedApiKey',
      _i15.Customer => 'Customer',
      _i16.CustomerDetail => 'CustomerDetail',
      _i17.CustomerIdentitySignal => 'CustomerIdentitySignal',
      _i18.CustomerMergeProposal => 'CustomerMergeProposal',
      _i19.CustomerProfile => 'CustomerProfile',
      _i20.EndOfDayReport => 'EndOfDayReport',
      _i21.Errand => 'Errand',
      _i22.ErrandCredential => 'ErrandCredential',
      _i23.ErrandExecutionLog => 'ErrandExecutionLog',
      _i24.Event => 'Event',
      _i25.FeatureFlag => 'FeatureFlag',
      _i26.GoogleDriveSpreadsheet => 'GoogleDriveSpreadsheet',
      _i27.Invoice => 'Invoice',
      _i28.KnowledgeChunk => 'KnowledgeChunk',
      _i29.KnowledgeDocument => 'KnowledgeDocument',
      _i30.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i31.KolaBillingCheckout => 'KolaBillingCheckout',
      _i32.KolaException => 'KolaException',
      _i33.Message => 'Message',
      _i34.MessageSuppression => 'MessageSuppression',
      _i35.OtpCode => 'OtpCode',
      _i36.OwnerNotificationSend => 'OwnerNotificationSend',
      _i37.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i38.PaymentBankAccount => 'PaymentBankAccount',
      _i39.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i40.PaymentTransaction => 'PaymentTransaction',
      _i41.Product => 'Product',
      _i42.ProductMedia => 'ProductMedia',
      _i43.ProductVariant => 'ProductVariant',
      _i44.Sale => 'Sale',
      _i45.SaleLine => 'SaleLine',
      _i46.SaleLineInput => 'SaleLineInput',
      _i47.Subscription => 'Subscription',
      _i48.SupportTicket => 'SupportTicket',
      _i49.UsageRecord => 'UsageRecord',
      _i50.WaitlistSignup => 'WaitlistSignup',
      _i51.WebhookEndpoint => 'WebhookEndpoint',
      _i52.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i53.Workspace => 'Workspace',
      _i54.WorkspaceAnswer => 'WorkspaceAnswer',
      _i55.WorkspaceAnswerAction => 'WorkspaceAnswerAction',
      _i56.WorkspaceAnswerTurn => 'WorkspaceAnswerTurn',
      _i57.WorkspaceConnector => 'WorkspaceConnector',
      _i58.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i59.WorkspaceFinding => 'WorkspaceFinding',
      _i60.WorkspaceMember => 'WorkspaceMember',
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
      case _i5.Broadcast():
        return 'Broadcast';
      case _i6.BroadcastProgress():
        return 'BroadcastProgress';
      case _i7.BroadcastRecipient():
        return 'BroadcastRecipient';
      case _i8.CalendarBooking():
        return 'CalendarBooking';
      case _i9.Channel():
        return 'Channel';
      case _i10.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i11.ConnectorStatus():
        return 'ConnectorStatus';
      case _i12.ConnectorSyncLog():
        return 'ConnectorSyncLog';
      case _i13.Conversation():
        return 'Conversation';
      case _i14.CreatedApiKey():
        return 'CreatedApiKey';
      case _i15.Customer():
        return 'Customer';
      case _i16.CustomerDetail():
        return 'CustomerDetail';
      case _i17.CustomerIdentitySignal():
        return 'CustomerIdentitySignal';
      case _i18.CustomerMergeProposal():
        return 'CustomerMergeProposal';
      case _i19.CustomerProfile():
        return 'CustomerProfile';
      case _i20.EndOfDayReport():
        return 'EndOfDayReport';
      case _i21.Errand():
        return 'Errand';
      case _i22.ErrandCredential():
        return 'ErrandCredential';
      case _i23.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i24.Event():
        return 'Event';
      case _i25.FeatureFlag():
        return 'FeatureFlag';
      case _i26.GoogleDriveSpreadsheet():
        return 'GoogleDriveSpreadsheet';
      case _i27.Invoice():
        return 'Invoice';
      case _i28.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i29.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i30.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i31.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i32.KolaException():
        return 'KolaException';
      case _i33.Message():
        return 'Message';
      case _i34.MessageSuppression():
        return 'MessageSuppression';
      case _i35.OtpCode():
        return 'OtpCode';
      case _i36.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i37.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i38.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i39.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i40.PaymentTransaction():
        return 'PaymentTransaction';
      case _i41.Product():
        return 'Product';
      case _i42.ProductMedia():
        return 'ProductMedia';
      case _i43.ProductVariant():
        return 'ProductVariant';
      case _i44.Sale():
        return 'Sale';
      case _i45.SaleLine():
        return 'SaleLine';
      case _i46.SaleLineInput():
        return 'SaleLineInput';
      case _i47.Subscription():
        return 'Subscription';
      case _i48.SupportTicket():
        return 'SupportTicket';
      case _i49.UsageRecord():
        return 'UsageRecord';
      case _i50.WaitlistSignup():
        return 'WaitlistSignup';
      case _i51.WebhookEndpoint():
        return 'WebhookEndpoint';
      case _i52.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i53.Workspace():
        return 'Workspace';
      case _i54.WorkspaceAnswer():
        return 'WorkspaceAnswer';
      case _i55.WorkspaceAnswerAction():
        return 'WorkspaceAnswerAction';
      case _i56.WorkspaceAnswerTurn():
        return 'WorkspaceAnswerTurn';
      case _i57.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i58.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i59.WorkspaceFinding():
        return 'WorkspaceFinding';
      case _i60.WorkspaceMember():
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
    if (dataClassName == 'Broadcast') {
      return deserialize<_i5.Broadcast>(data['data']);
    }
    if (dataClassName == 'BroadcastProgress') {
      return deserialize<_i6.BroadcastProgress>(data['data']);
    }
    if (dataClassName == 'BroadcastRecipient') {
      return deserialize<_i7.BroadcastRecipient>(data['data']);
    }
    if (dataClassName == 'CalendarBooking') {
      return deserialize<_i8.CalendarBooking>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i9.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i10.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i11.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'ConnectorSyncLog') {
      return deserialize<_i12.ConnectorSyncLog>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i13.Conversation>(data['data']);
    }
    if (dataClassName == 'CreatedApiKey') {
      return deserialize<_i14.CreatedApiKey>(data['data']);
    }
    if (dataClassName == 'Customer') {
      return deserialize<_i15.Customer>(data['data']);
    }
    if (dataClassName == 'CustomerDetail') {
      return deserialize<_i16.CustomerDetail>(data['data']);
    }
    if (dataClassName == 'CustomerIdentitySignal') {
      return deserialize<_i17.CustomerIdentitySignal>(data['data']);
    }
    if (dataClassName == 'CustomerMergeProposal') {
      return deserialize<_i18.CustomerMergeProposal>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i19.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'EndOfDayReport') {
      return deserialize<_i20.EndOfDayReport>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i21.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i22.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i23.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'Event') {
      return deserialize<_i24.Event>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i25.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'GoogleDriveSpreadsheet') {
      return deserialize<_i26.GoogleDriveSpreadsheet>(data['data']);
    }
    if (dataClassName == 'Invoice') {
      return deserialize<_i27.Invoice>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i28.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i29.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i30.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i31.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'KolaException') {
      return deserialize<_i32.KolaException>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i33.Message>(data['data']);
    }
    if (dataClassName == 'MessageSuppression') {
      return deserialize<_i34.MessageSuppression>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i35.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i36.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i37.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i38.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i39.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i40.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i41.Product>(data['data']);
    }
    if (dataClassName == 'ProductMedia') {
      return deserialize<_i42.ProductMedia>(data['data']);
    }
    if (dataClassName == 'ProductVariant') {
      return deserialize<_i43.ProductVariant>(data['data']);
    }
    if (dataClassName == 'Sale') {
      return deserialize<_i44.Sale>(data['data']);
    }
    if (dataClassName == 'SaleLine') {
      return deserialize<_i45.SaleLine>(data['data']);
    }
    if (dataClassName == 'SaleLineInput') {
      return deserialize<_i46.SaleLineInput>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i47.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i48.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i49.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i50.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WebhookEndpoint') {
      return deserialize<_i51.WebhookEndpoint>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i52.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i53.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswer') {
      return deserialize<_i54.WorkspaceAnswer>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerAction') {
      return deserialize<_i55.WorkspaceAnswerAction>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerTurn') {
      return deserialize<_i56.WorkspaceAnswerTurn>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i57.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i58.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceFinding') {
      return deserialize<_i59.WorkspaceFinding>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i60.WorkspaceMember>(data['data']);
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
