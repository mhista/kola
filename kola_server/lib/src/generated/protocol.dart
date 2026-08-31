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
import 'analytics_daily_point.dart' as _i3;
import 'analytics_segment.dart' as _i4;
import 'analytics_summary.dart' as _i5;
import 'api_key.dart' as _i6;
import 'bot.dart' as _i7;
import 'broadcast.dart' as _i8;
import 'broadcast_progress.dart' as _i9;
import 'broadcast_recipient.dart' as _i10;
import 'calendar_booking.dart' as _i11;
import 'channel.dart' as _i12;
import 'connector_field_spec.dart' as _i13;
import 'connector_status.dart' as _i14;
import 'connector_sync_log.dart' as _i15;
import 'conversation.dart' as _i16;
import 'created_api_key.dart' as _i17;
import 'customer.dart' as _i18;
import 'customer_detail.dart' as _i19;
import 'customer_identity_signal.dart' as _i20;
import 'customer_merge_proposal.dart' as _i21;
import 'customer_profile.dart' as _i22;
import 'customer_summary.dart' as _i23;
import 'end_of_day_report.dart' as _i24;
import 'errand.dart' as _i25;
import 'errand_credential.dart' as _i26;
import 'errand_execution_log.dart' as _i27;
import 'event.dart' as _i28;
import 'feature_flag.dart' as _i29;
import 'google_drive_spreadsheet.dart' as _i30;
import 'invoice.dart' as _i31;
import 'knowledge_chunk.dart' as _i32;
import 'knowledge_document.dart' as _i33;
import 'knowledge_search_hit.dart' as _i34;
import 'kola_billing_checkout.dart' as _i35;
import 'kola_exception.dart' as _i36;
import 'message.dart' as _i37;
import 'message_suppression.dart' as _i38;
import 'otp_code.dart' as _i39;
import 'owner_notification_send.dart' as _i40;
import 'owner_notification_settings.dart' as _i41;
import 'payment_bank_account.dart' as _i42;
import 'payment_gateway_credential.dart' as _i43;
import 'payment_transaction.dart' as _i44;
import 'product.dart' as _i45;
import 'product_media.dart' as _i46;
import 'product_variant.dart' as _i47;
import 'public_catalog.dart' as _i48;
import 'public_catalog_item.dart' as _i49;
import 'sale.dart' as _i50;
import 'sale_line.dart' as _i51;
import 'sale_line_input.dart' as _i52;
import 'subscription.dart' as _i53;
import 'support_ticket.dart' as _i54;
import 'task.dart' as _i55;
import 'till_display_item.dart' as _i56;
import 'till_display_state.dart' as _i57;
import 'usage_record.dart' as _i58;
import 'waitlist_signup.dart' as _i59;
import 'webhook_endpoint.dart' as _i60;
import 'whatsapp_message_template.dart' as _i61;
import 'workspace.dart' as _i62;
import 'workspace_answer.dart' as _i63;
import 'workspace_answer_action.dart' as _i64;
import 'workspace_answer_turn.dart' as _i65;
import 'workspace_connector.dart' as _i66;
import 'workspace_feature_override.dart' as _i67;
import 'workspace_finding.dart' as _i68;
import 'workspace_member.dart' as _i69;
import 'package:kola_server/src/generated/conversation.dart' as _i70;
import 'package:kola_server/src/generated/knowledge_document.dart' as _i71;
import 'package:kola_server/src/generated/message.dart' as _i72;
import 'package:kola_server/src/generated/errand.dart' as _i73;
import 'package:kola_server/src/generated/feature_flag.dart' as _i74;
import 'package:kola_server/src/generated/workspace_feature_override.dart'
    as _i75;
import 'package:kola_server/src/generated/support_ticket.dart' as _i76;
import 'package:kola_server/src/generated/workspace.dart' as _i77;
import 'package:kola_server/src/generated/bot.dart' as _i78;
import 'package:kola_server/src/generated/channel.dart' as _i79;
import 'package:kola_server/src/generated/broadcast.dart' as _i80;
import 'package:kola_server/src/generated/message_suppression.dart' as _i81;
import 'package:kola_server/src/generated/connector_status.dart' as _i82;
import 'package:kola_server/src/generated/google_drive_spreadsheet.dart'
    as _i83;
import 'package:kola_server/src/generated/calendar_booking.dart' as _i84;
import 'package:kola_server/src/generated/customer.dart' as _i85;
import 'package:kola_server/src/generated/customer_summary.dart' as _i86;
import 'package:kola_server/src/generated/customer_merge_proposal.dart' as _i87;
import 'package:kola_server/src/generated/errand_execution_log.dart' as _i88;
import 'package:kola_server/src/generated/workspace_finding.dart' as _i89;
import 'package:kola_server/src/generated/invoice.dart' as _i90;
import 'package:kola_server/src/generated/knowledge_search_hit.dart' as _i91;
import 'package:kola_server/src/generated/payment_gateway_credential.dart'
    as _i92;
import 'package:kola_server/src/generated/api_key.dart' as _i93;
import 'package:kola_server/src/generated/webhook_endpoint.dart' as _i94;
import 'package:kola_server/src/generated/product.dart' as _i95;
import 'package:kola_server/src/generated/product_variant.dart' as _i96;
import 'package:kola_server/src/generated/product_media.dart' as _i97;
import 'package:kola_server/src/generated/sale.dart' as _i98;
import 'package:kola_server/src/generated/sale_line.dart' as _i99;
import 'package:kola_server/src/generated/task.dart' as _i100;
import 'package:kola_server/src/generated/whatsapp_message_template.dart'
    as _i101;
export 'analytics_daily_point.dart';
export 'analytics_segment.dart';
export 'analytics_summary.dart';
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
export 'customer_summary.dart';
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
export 'public_catalog.dart';
export 'public_catalog_item.dart';
export 'sale.dart';
export 'sale_line.dart';
export 'sale_line_input.dart';
export 'subscription.dart';
export 'support_ticket.dart';
export 'task.dart';
export 'till_display_item.dart';
export 'till_display_state.dart';
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

    if (t == _i3.AnalyticsDailyPoint) {
      return _i3.AnalyticsDailyPoint.fromJson(data) as T;
    }
    if (t == _i4.AnalyticsSegment) {
      return _i4.AnalyticsSegment.fromJson(data) as T;
    }
    if (t == _i5.AnalyticsSummary) {
      return _i5.AnalyticsSummary.fromJson(data) as T;
    }
    if (t == _i6.ApiKey) {
      return _i6.ApiKey.fromJson(data) as T;
    }
    if (t == _i7.Bot) {
      return _i7.Bot.fromJson(data) as T;
    }
    if (t == _i8.Broadcast) {
      return _i8.Broadcast.fromJson(data) as T;
    }
    if (t == _i9.BroadcastProgress) {
      return _i9.BroadcastProgress.fromJson(data) as T;
    }
    if (t == _i10.BroadcastRecipient) {
      return _i10.BroadcastRecipient.fromJson(data) as T;
    }
    if (t == _i11.CalendarBooking) {
      return _i11.CalendarBooking.fromJson(data) as T;
    }
    if (t == _i12.Channel) {
      return _i12.Channel.fromJson(data) as T;
    }
    if (t == _i13.ConnectorFieldSpec) {
      return _i13.ConnectorFieldSpec.fromJson(data) as T;
    }
    if (t == _i14.ConnectorStatus) {
      return _i14.ConnectorStatus.fromJson(data) as T;
    }
    if (t == _i15.ConnectorSyncLog) {
      return _i15.ConnectorSyncLog.fromJson(data) as T;
    }
    if (t == _i16.Conversation) {
      return _i16.Conversation.fromJson(data) as T;
    }
    if (t == _i17.CreatedApiKey) {
      return _i17.CreatedApiKey.fromJson(data) as T;
    }
    if (t == _i18.Customer) {
      return _i18.Customer.fromJson(data) as T;
    }
    if (t == _i19.CustomerDetail) {
      return _i19.CustomerDetail.fromJson(data) as T;
    }
    if (t == _i20.CustomerIdentitySignal) {
      return _i20.CustomerIdentitySignal.fromJson(data) as T;
    }
    if (t == _i21.CustomerMergeProposal) {
      return _i21.CustomerMergeProposal.fromJson(data) as T;
    }
    if (t == _i22.CustomerProfile) {
      return _i22.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i23.CustomerSummary) {
      return _i23.CustomerSummary.fromJson(data) as T;
    }
    if (t == _i24.EndOfDayReport) {
      return _i24.EndOfDayReport.fromJson(data) as T;
    }
    if (t == _i25.Errand) {
      return _i25.Errand.fromJson(data) as T;
    }
    if (t == _i26.ErrandCredential) {
      return _i26.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i27.ErrandExecutionLog) {
      return _i27.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i28.Event) {
      return _i28.Event.fromJson(data) as T;
    }
    if (t == _i29.FeatureFlag) {
      return _i29.FeatureFlag.fromJson(data) as T;
    }
    if (t == _i30.GoogleDriveSpreadsheet) {
      return _i30.GoogleDriveSpreadsheet.fromJson(data) as T;
    }
    if (t == _i31.Invoice) {
      return _i31.Invoice.fromJson(data) as T;
    }
    if (t == _i32.KnowledgeChunk) {
      return _i32.KnowledgeChunk.fromJson(data) as T;
    }
    if (t == _i33.KnowledgeDocument) {
      return _i33.KnowledgeDocument.fromJson(data) as T;
    }
    if (t == _i34.KnowledgeSearchHit) {
      return _i34.KnowledgeSearchHit.fromJson(data) as T;
    }
    if (t == _i35.KolaBillingCheckout) {
      return _i35.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i36.KolaException) {
      return _i36.KolaException.fromJson(data) as T;
    }
    if (t == _i37.Message) {
      return _i37.Message.fromJson(data) as T;
    }
    if (t == _i38.MessageSuppression) {
      return _i38.MessageSuppression.fromJson(data) as T;
    }
    if (t == _i39.OtpCode) {
      return _i39.OtpCode.fromJson(data) as T;
    }
    if (t == _i40.OwnerNotificationSend) {
      return _i40.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i41.OwnerNotificationSettings) {
      return _i41.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i42.PaymentBankAccount) {
      return _i42.PaymentBankAccount.fromJson(data) as T;
    }
    if (t == _i43.PaymentGatewayCredential) {
      return _i43.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i44.PaymentTransaction) {
      return _i44.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i45.Product) {
      return _i45.Product.fromJson(data) as T;
    }
    if (t == _i46.ProductMedia) {
      return _i46.ProductMedia.fromJson(data) as T;
    }
    if (t == _i47.ProductVariant) {
      return _i47.ProductVariant.fromJson(data) as T;
    }
    if (t == _i48.PublicCatalog) {
      return _i48.PublicCatalog.fromJson(data) as T;
    }
    if (t == _i49.PublicCatalogItem) {
      return _i49.PublicCatalogItem.fromJson(data) as T;
    }
    if (t == _i50.Sale) {
      return _i50.Sale.fromJson(data) as T;
    }
    if (t == _i51.SaleLine) {
      return _i51.SaleLine.fromJson(data) as T;
    }
    if (t == _i52.SaleLineInput) {
      return _i52.SaleLineInput.fromJson(data) as T;
    }
    if (t == _i53.Subscription) {
      return _i53.Subscription.fromJson(data) as T;
    }
    if (t == _i54.SupportTicket) {
      return _i54.SupportTicket.fromJson(data) as T;
    }
    if (t == _i55.Task) {
      return _i55.Task.fromJson(data) as T;
    }
    if (t == _i56.TillDisplayItem) {
      return _i56.TillDisplayItem.fromJson(data) as T;
    }
    if (t == _i57.TillDisplayState) {
      return _i57.TillDisplayState.fromJson(data) as T;
    }
    if (t == _i58.UsageRecord) {
      return _i58.UsageRecord.fromJson(data) as T;
    }
    if (t == _i59.WaitlistSignup) {
      return _i59.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i60.WebhookEndpoint) {
      return _i60.WebhookEndpoint.fromJson(data) as T;
    }
    if (t == _i61.WhatsAppMessageTemplate) {
      return _i61.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i62.Workspace) {
      return _i62.Workspace.fromJson(data) as T;
    }
    if (t == _i63.WorkspaceAnswer) {
      return _i63.WorkspaceAnswer.fromJson(data) as T;
    }
    if (t == _i64.WorkspaceAnswerAction) {
      return _i64.WorkspaceAnswerAction.fromJson(data) as T;
    }
    if (t == _i65.WorkspaceAnswerTurn) {
      return _i65.WorkspaceAnswerTurn.fromJson(data) as T;
    }
    if (t == _i66.WorkspaceConnector) {
      return _i66.WorkspaceConnector.fromJson(data) as T;
    }
    if (t == _i67.WorkspaceFeatureOverride) {
      return _i67.WorkspaceFeatureOverride.fromJson(data) as T;
    }
    if (t == _i68.WorkspaceFinding) {
      return _i68.WorkspaceFinding.fromJson(data) as T;
    }
    if (t == _i69.WorkspaceMember) {
      return _i69.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AnalyticsDailyPoint?>()) {
      return (data != null ? _i3.AnalyticsDailyPoint.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.AnalyticsSegment?>()) {
      return (data != null ? _i4.AnalyticsSegment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AnalyticsSummary?>()) {
      return (data != null ? _i5.AnalyticsSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ApiKey?>()) {
      return (data != null ? _i6.ApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Bot?>()) {
      return (data != null ? _i7.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Broadcast?>()) {
      return (data != null ? _i8.Broadcast.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.BroadcastProgress?>()) {
      return (data != null ? _i9.BroadcastProgress.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.BroadcastRecipient?>()) {
      return (data != null ? _i10.BroadcastRecipient.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i11.CalendarBooking?>()) {
      return (data != null ? _i11.CalendarBooking.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Channel?>()) {
      return (data != null ? _i12.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ConnectorFieldSpec?>()) {
      return (data != null ? _i13.ConnectorFieldSpec.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i14.ConnectorStatus?>()) {
      return (data != null ? _i14.ConnectorStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ConnectorSyncLog?>()) {
      return (data != null ? _i15.ConnectorSyncLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Conversation?>()) {
      return (data != null ? _i16.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.CreatedApiKey?>()) {
      return (data != null ? _i17.CreatedApiKey.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Customer?>()) {
      return (data != null ? _i18.Customer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.CustomerDetail?>()) {
      return (data != null ? _i19.CustomerDetail.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.CustomerIdentitySignal?>()) {
      return (data != null ? _i20.CustomerIdentitySignal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.CustomerMergeProposal?>()) {
      return (data != null ? _i21.CustomerMergeProposal.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.CustomerProfile?>()) {
      return (data != null ? _i22.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.CustomerSummary?>()) {
      return (data != null ? _i23.CustomerSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.EndOfDayReport?>()) {
      return (data != null ? _i24.EndOfDayReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.Errand?>()) {
      return (data != null ? _i25.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.ErrandCredential?>()) {
      return (data != null ? _i26.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.ErrandExecutionLog?>()) {
      return (data != null ? _i27.ErrandExecutionLog.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.Event?>()) {
      return (data != null ? _i28.Event.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.FeatureFlag?>()) {
      return (data != null ? _i29.FeatureFlag.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.GoogleDriveSpreadsheet?>()) {
      return (data != null ? _i30.GoogleDriveSpreadsheet.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i31.Invoice?>()) {
      return (data != null ? _i31.Invoice.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.KnowledgeChunk?>()) {
      return (data != null ? _i32.KnowledgeChunk.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.KnowledgeDocument?>()) {
      return (data != null ? _i33.KnowledgeDocument.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.KnowledgeSearchHit?>()) {
      return (data != null ? _i34.KnowledgeSearchHit.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i35.KolaBillingCheckout?>()) {
      return (data != null ? _i35.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i36.KolaException?>()) {
      return (data != null ? _i36.KolaException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.Message?>()) {
      return (data != null ? _i37.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.MessageSuppression?>()) {
      return (data != null ? _i38.MessageSuppression.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i39.OtpCode?>()) {
      return (data != null ? _i39.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.OwnerNotificationSend?>()) {
      return (data != null ? _i40.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i41.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i41.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i42.PaymentBankAccount?>()) {
      return (data != null ? _i42.PaymentBankAccount.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i43.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i43.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i44.PaymentTransaction?>()) {
      return (data != null ? _i44.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i45.Product?>()) {
      return (data != null ? _i45.Product.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.ProductMedia?>()) {
      return (data != null ? _i46.ProductMedia.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.ProductVariant?>()) {
      return (data != null ? _i47.ProductVariant.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.PublicCatalog?>()) {
      return (data != null ? _i48.PublicCatalog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i49.PublicCatalogItem?>()) {
      return (data != null ? _i49.PublicCatalogItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i50.Sale?>()) {
      return (data != null ? _i50.Sale.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i51.SaleLine?>()) {
      return (data != null ? _i51.SaleLine.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i52.SaleLineInput?>()) {
      return (data != null ? _i52.SaleLineInput.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i53.Subscription?>()) {
      return (data != null ? _i53.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i54.SupportTicket?>()) {
      return (data != null ? _i54.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i55.Task?>()) {
      return (data != null ? _i55.Task.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i56.TillDisplayItem?>()) {
      return (data != null ? _i56.TillDisplayItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i57.TillDisplayState?>()) {
      return (data != null ? _i57.TillDisplayState.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i58.UsageRecord?>()) {
      return (data != null ? _i58.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i59.WaitlistSignup?>()) {
      return (data != null ? _i59.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i60.WebhookEndpoint?>()) {
      return (data != null ? _i60.WebhookEndpoint.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i61.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i61.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i62.Workspace?>()) {
      return (data != null ? _i62.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i63.WorkspaceAnswer?>()) {
      return (data != null ? _i63.WorkspaceAnswer.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i64.WorkspaceAnswerAction?>()) {
      return (data != null ? _i64.WorkspaceAnswerAction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i65.WorkspaceAnswerTurn?>()) {
      return (data != null ? _i65.WorkspaceAnswerTurn.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i66.WorkspaceConnector?>()) {
      return (data != null ? _i66.WorkspaceConnector.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i67.WorkspaceFeatureOverride?>()) {
      return (data != null
              ? _i67.WorkspaceFeatureOverride.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i68.WorkspaceFinding?>()) {
      return (data != null ? _i68.WorkspaceFinding.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i69.WorkspaceMember?>()) {
      return (data != null ? _i69.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i3.AnalyticsDailyPoint>) {
      return (data as List)
              .map((e) => deserialize<_i3.AnalyticsDailyPoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i4.AnalyticsSegment>) {
      return (data as List)
              .map((e) => deserialize<_i4.AnalyticsSegment>(e))
              .toList()
          as T;
    }
    if (t == List<_i13.ConnectorFieldSpec>) {
      return (data as List)
              .map((e) => deserialize<_i13.ConnectorFieldSpec>(e))
              .toList()
          as T;
    }
    if (t == List<_i20.CustomerIdentitySignal>) {
      return (data as List)
              .map((e) => deserialize<_i20.CustomerIdentitySignal>(e))
              .toList()
          as T;
    }
    if (t == List<_i16.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i16.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i44.PaymentTransaction>) {
      return (data as List)
              .map((e) => deserialize<_i44.PaymentTransaction>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.Sale>) {
      return (data as List).map((e) => deserialize<_i50.Sale>(e)).toList() as T;
    }
    if (t == List<_i49.PublicCatalogItem>) {
      return (data as List)
              .map((e) => deserialize<_i49.PublicCatalogItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i56.TillDisplayItem>) {
      return (data as List)
              .map((e) => deserialize<_i56.TillDisplayItem>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i64.WorkspaceAnswerAction>) {
      return (data as List)
              .map((e) => deserialize<_i64.WorkspaceAnswerAction>(e))
              .toList()
          as T;
    }
    if (t == List<_i34.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i34.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i70.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i70.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i71.KnowledgeDocument>) {
      return (data as List)
              .map((e) => deserialize<_i71.KnowledgeDocument>(e))
              .toList()
          as T;
    }
    if (t == List<_i72.Message>) {
      return (data as List).map((e) => deserialize<_i72.Message>(e)).toList()
          as T;
    }
    if (t == List<_i73.Errand>) {
      return (data as List).map((e) => deserialize<_i73.Errand>(e)).toList()
          as T;
    }
    if (t == List<_i74.FeatureFlag>) {
      return (data as List)
              .map((e) => deserialize<_i74.FeatureFlag>(e))
              .toList()
          as T;
    }
    if (t == List<_i75.WorkspaceFeatureOverride>) {
      return (data as List)
              .map((e) => deserialize<_i75.WorkspaceFeatureOverride>(e))
              .toList()
          as T;
    }
    if (t == List<_i76.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i76.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<_i77.Workspace>) {
      return (data as List).map((e) => deserialize<_i77.Workspace>(e)).toList()
          as T;
    }
    if (t == List<_i78.Bot>) {
      return (data as List).map((e) => deserialize<_i78.Bot>(e)).toList() as T;
    }
    if (t == List<_i79.Channel>) {
      return (data as List).map((e) => deserialize<_i79.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i80.Broadcast>) {
      return (data as List).map((e) => deserialize<_i80.Broadcast>(e)).toList()
          as T;
    }
    if (t == List<_i81.MessageSuppression>) {
      return (data as List)
              .map((e) => deserialize<_i81.MessageSuppression>(e))
              .toList()
          as T;
    }
    if (t == List<_i82.ConnectorStatus>) {
      return (data as List)
              .map((e) => deserialize<_i82.ConnectorStatus>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    if (t == List<_i83.GoogleDriveSpreadsheet>) {
      return (data as List)
              .map((e) => deserialize<_i83.GoogleDriveSpreadsheet>(e))
              .toList()
          as T;
    }
    if (t == List<_i84.CalendarBooking>) {
      return (data as List)
              .map((e) => deserialize<_i84.CalendarBooking>(e))
              .toList()
          as T;
    }
    if (t == List<_i85.Customer>) {
      return (data as List).map((e) => deserialize<_i85.Customer>(e)).toList()
          as T;
    }
    if (t == List<_i86.CustomerSummary>) {
      return (data as List)
              .map((e) => deserialize<_i86.CustomerSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i87.CustomerMergeProposal>) {
      return (data as List)
              .map((e) => deserialize<_i87.CustomerMergeProposal>(e))
              .toList()
          as T;
    }
    if (t == List<_i88.ErrandExecutionLog>) {
      return (data as List)
              .map((e) => deserialize<_i88.ErrandExecutionLog>(e))
              .toList()
          as T;
    }
    if (t == List<_i89.WorkspaceFinding>) {
      return (data as List)
              .map((e) => deserialize<_i89.WorkspaceFinding>(e))
              .toList()
          as T;
    }
    if (t == List<_i90.Invoice>) {
      return (data as List).map((e) => deserialize<_i90.Invoice>(e)).toList()
          as T;
    }
    if (t == List<_i91.KnowledgeSearchHit>) {
      return (data as List)
              .map((e) => deserialize<_i91.KnowledgeSearchHit>(e))
              .toList()
          as T;
    }
    if (t == List<_i92.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i92.PaymentGatewayCredential>(e))
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
    if (t == List<_i93.ApiKey>) {
      return (data as List).map((e) => deserialize<_i93.ApiKey>(e)).toList()
          as T;
    }
    if (t == List<_i94.WebhookEndpoint>) {
      return (data as List)
              .map((e) => deserialize<_i94.WebhookEndpoint>(e))
              .toList()
          as T;
    }
    if (t == List<_i95.Product>) {
      return (data as List).map((e) => deserialize<_i95.Product>(e)).toList()
          as T;
    }
    if (t == List<_i96.ProductVariant>) {
      return (data as List)
              .map((e) => deserialize<_i96.ProductVariant>(e))
              .toList()
          as T;
    }
    if (t == List<int?>) {
      return (data as List).map((e) => deserialize<int?>(e)).toList() as T;
    }
    if (t == List<_i97.ProductMedia>) {
      return (data as List)
              .map((e) => deserialize<_i97.ProductMedia>(e))
              .toList()
          as T;
    }
    if (t == List<_i98.Sale>) {
      return (data as List).map((e) => deserialize<_i98.Sale>(e)).toList() as T;
    }
    if (t == List<_i99.SaleLine>) {
      return (data as List).map((e) => deserialize<_i99.SaleLine>(e)).toList()
          as T;
    }
    if (t == List<_i100.Task>) {
      return (data as List).map((e) => deserialize<_i100.Task>(e)).toList()
          as T;
    }
    if (t == List<_i101.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i101.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.AnalyticsDailyPoint => 'AnalyticsDailyPoint',
      _i4.AnalyticsSegment => 'AnalyticsSegment',
      _i5.AnalyticsSummary => 'AnalyticsSummary',
      _i6.ApiKey => 'ApiKey',
      _i7.Bot => 'Bot',
      _i8.Broadcast => 'Broadcast',
      _i9.BroadcastProgress => 'BroadcastProgress',
      _i10.BroadcastRecipient => 'BroadcastRecipient',
      _i11.CalendarBooking => 'CalendarBooking',
      _i12.Channel => 'Channel',
      _i13.ConnectorFieldSpec => 'ConnectorFieldSpec',
      _i14.ConnectorStatus => 'ConnectorStatus',
      _i15.ConnectorSyncLog => 'ConnectorSyncLog',
      _i16.Conversation => 'Conversation',
      _i17.CreatedApiKey => 'CreatedApiKey',
      _i18.Customer => 'Customer',
      _i19.CustomerDetail => 'CustomerDetail',
      _i20.CustomerIdentitySignal => 'CustomerIdentitySignal',
      _i21.CustomerMergeProposal => 'CustomerMergeProposal',
      _i22.CustomerProfile => 'CustomerProfile',
      _i23.CustomerSummary => 'CustomerSummary',
      _i24.EndOfDayReport => 'EndOfDayReport',
      _i25.Errand => 'Errand',
      _i26.ErrandCredential => 'ErrandCredential',
      _i27.ErrandExecutionLog => 'ErrandExecutionLog',
      _i28.Event => 'Event',
      _i29.FeatureFlag => 'FeatureFlag',
      _i30.GoogleDriveSpreadsheet => 'GoogleDriveSpreadsheet',
      _i31.Invoice => 'Invoice',
      _i32.KnowledgeChunk => 'KnowledgeChunk',
      _i33.KnowledgeDocument => 'KnowledgeDocument',
      _i34.KnowledgeSearchHit => 'KnowledgeSearchHit',
      _i35.KolaBillingCheckout => 'KolaBillingCheckout',
      _i36.KolaException => 'KolaException',
      _i37.Message => 'Message',
      _i38.MessageSuppression => 'MessageSuppression',
      _i39.OtpCode => 'OtpCode',
      _i40.OwnerNotificationSend => 'OwnerNotificationSend',
      _i41.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i42.PaymentBankAccount => 'PaymentBankAccount',
      _i43.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i44.PaymentTransaction => 'PaymentTransaction',
      _i45.Product => 'Product',
      _i46.ProductMedia => 'ProductMedia',
      _i47.ProductVariant => 'ProductVariant',
      _i48.PublicCatalog => 'PublicCatalog',
      _i49.PublicCatalogItem => 'PublicCatalogItem',
      _i50.Sale => 'Sale',
      _i51.SaleLine => 'SaleLine',
      _i52.SaleLineInput => 'SaleLineInput',
      _i53.Subscription => 'Subscription',
      _i54.SupportTicket => 'SupportTicket',
      _i55.Task => 'Task',
      _i56.TillDisplayItem => 'TillDisplayItem',
      _i57.TillDisplayState => 'TillDisplayState',
      _i58.UsageRecord => 'UsageRecord',
      _i59.WaitlistSignup => 'WaitlistSignup',
      _i60.WebhookEndpoint => 'WebhookEndpoint',
      _i61.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i62.Workspace => 'Workspace',
      _i63.WorkspaceAnswer => 'WorkspaceAnswer',
      _i64.WorkspaceAnswerAction => 'WorkspaceAnswerAction',
      _i65.WorkspaceAnswerTurn => 'WorkspaceAnswerTurn',
      _i66.WorkspaceConnector => 'WorkspaceConnector',
      _i67.WorkspaceFeatureOverride => 'WorkspaceFeatureOverride',
      _i68.WorkspaceFinding => 'WorkspaceFinding',
      _i69.WorkspaceMember => 'WorkspaceMember',
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
      case _i3.AnalyticsDailyPoint():
        return 'AnalyticsDailyPoint';
      case _i4.AnalyticsSegment():
        return 'AnalyticsSegment';
      case _i5.AnalyticsSummary():
        return 'AnalyticsSummary';
      case _i6.ApiKey():
        return 'ApiKey';
      case _i7.Bot():
        return 'Bot';
      case _i8.Broadcast():
        return 'Broadcast';
      case _i9.BroadcastProgress():
        return 'BroadcastProgress';
      case _i10.BroadcastRecipient():
        return 'BroadcastRecipient';
      case _i11.CalendarBooking():
        return 'CalendarBooking';
      case _i12.Channel():
        return 'Channel';
      case _i13.ConnectorFieldSpec():
        return 'ConnectorFieldSpec';
      case _i14.ConnectorStatus():
        return 'ConnectorStatus';
      case _i15.ConnectorSyncLog():
        return 'ConnectorSyncLog';
      case _i16.Conversation():
        return 'Conversation';
      case _i17.CreatedApiKey():
        return 'CreatedApiKey';
      case _i18.Customer():
        return 'Customer';
      case _i19.CustomerDetail():
        return 'CustomerDetail';
      case _i20.CustomerIdentitySignal():
        return 'CustomerIdentitySignal';
      case _i21.CustomerMergeProposal():
        return 'CustomerMergeProposal';
      case _i22.CustomerProfile():
        return 'CustomerProfile';
      case _i23.CustomerSummary():
        return 'CustomerSummary';
      case _i24.EndOfDayReport():
        return 'EndOfDayReport';
      case _i25.Errand():
        return 'Errand';
      case _i26.ErrandCredential():
        return 'ErrandCredential';
      case _i27.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i28.Event():
        return 'Event';
      case _i29.FeatureFlag():
        return 'FeatureFlag';
      case _i30.GoogleDriveSpreadsheet():
        return 'GoogleDriveSpreadsheet';
      case _i31.Invoice():
        return 'Invoice';
      case _i32.KnowledgeChunk():
        return 'KnowledgeChunk';
      case _i33.KnowledgeDocument():
        return 'KnowledgeDocument';
      case _i34.KnowledgeSearchHit():
        return 'KnowledgeSearchHit';
      case _i35.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i36.KolaException():
        return 'KolaException';
      case _i37.Message():
        return 'Message';
      case _i38.MessageSuppression():
        return 'MessageSuppression';
      case _i39.OtpCode():
        return 'OtpCode';
      case _i40.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i41.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i42.PaymentBankAccount():
        return 'PaymentBankAccount';
      case _i43.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i44.PaymentTransaction():
        return 'PaymentTransaction';
      case _i45.Product():
        return 'Product';
      case _i46.ProductMedia():
        return 'ProductMedia';
      case _i47.ProductVariant():
        return 'ProductVariant';
      case _i48.PublicCatalog():
        return 'PublicCatalog';
      case _i49.PublicCatalogItem():
        return 'PublicCatalogItem';
      case _i50.Sale():
        return 'Sale';
      case _i51.SaleLine():
        return 'SaleLine';
      case _i52.SaleLineInput():
        return 'SaleLineInput';
      case _i53.Subscription():
        return 'Subscription';
      case _i54.SupportTicket():
        return 'SupportTicket';
      case _i55.Task():
        return 'Task';
      case _i56.TillDisplayItem():
        return 'TillDisplayItem';
      case _i57.TillDisplayState():
        return 'TillDisplayState';
      case _i58.UsageRecord():
        return 'UsageRecord';
      case _i59.WaitlistSignup():
        return 'WaitlistSignup';
      case _i60.WebhookEndpoint():
        return 'WebhookEndpoint';
      case _i61.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i62.Workspace():
        return 'Workspace';
      case _i63.WorkspaceAnswer():
        return 'WorkspaceAnswer';
      case _i64.WorkspaceAnswerAction():
        return 'WorkspaceAnswerAction';
      case _i65.WorkspaceAnswerTurn():
        return 'WorkspaceAnswerTurn';
      case _i66.WorkspaceConnector():
        return 'WorkspaceConnector';
      case _i67.WorkspaceFeatureOverride():
        return 'WorkspaceFeatureOverride';
      case _i68.WorkspaceFinding():
        return 'WorkspaceFinding';
      case _i69.WorkspaceMember():
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
    if (dataClassName == 'AnalyticsDailyPoint') {
      return deserialize<_i3.AnalyticsDailyPoint>(data['data']);
    }
    if (dataClassName == 'AnalyticsSegment') {
      return deserialize<_i4.AnalyticsSegment>(data['data']);
    }
    if (dataClassName == 'AnalyticsSummary') {
      return deserialize<_i5.AnalyticsSummary>(data['data']);
    }
    if (dataClassName == 'ApiKey') {
      return deserialize<_i6.ApiKey>(data['data']);
    }
    if (dataClassName == 'Bot') {
      return deserialize<_i7.Bot>(data['data']);
    }
    if (dataClassName == 'Broadcast') {
      return deserialize<_i8.Broadcast>(data['data']);
    }
    if (dataClassName == 'BroadcastProgress') {
      return deserialize<_i9.BroadcastProgress>(data['data']);
    }
    if (dataClassName == 'BroadcastRecipient') {
      return deserialize<_i10.BroadcastRecipient>(data['data']);
    }
    if (dataClassName == 'CalendarBooking') {
      return deserialize<_i11.CalendarBooking>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i12.Channel>(data['data']);
    }
    if (dataClassName == 'ConnectorFieldSpec') {
      return deserialize<_i13.ConnectorFieldSpec>(data['data']);
    }
    if (dataClassName == 'ConnectorStatus') {
      return deserialize<_i14.ConnectorStatus>(data['data']);
    }
    if (dataClassName == 'ConnectorSyncLog') {
      return deserialize<_i15.ConnectorSyncLog>(data['data']);
    }
    if (dataClassName == 'Conversation') {
      return deserialize<_i16.Conversation>(data['data']);
    }
    if (dataClassName == 'CreatedApiKey') {
      return deserialize<_i17.CreatedApiKey>(data['data']);
    }
    if (dataClassName == 'Customer') {
      return deserialize<_i18.Customer>(data['data']);
    }
    if (dataClassName == 'CustomerDetail') {
      return deserialize<_i19.CustomerDetail>(data['data']);
    }
    if (dataClassName == 'CustomerIdentitySignal') {
      return deserialize<_i20.CustomerIdentitySignal>(data['data']);
    }
    if (dataClassName == 'CustomerMergeProposal') {
      return deserialize<_i21.CustomerMergeProposal>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i22.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'CustomerSummary') {
      return deserialize<_i23.CustomerSummary>(data['data']);
    }
    if (dataClassName == 'EndOfDayReport') {
      return deserialize<_i24.EndOfDayReport>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i25.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i26.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i27.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'Event') {
      return deserialize<_i28.Event>(data['data']);
    }
    if (dataClassName == 'FeatureFlag') {
      return deserialize<_i29.FeatureFlag>(data['data']);
    }
    if (dataClassName == 'GoogleDriveSpreadsheet') {
      return deserialize<_i30.GoogleDriveSpreadsheet>(data['data']);
    }
    if (dataClassName == 'Invoice') {
      return deserialize<_i31.Invoice>(data['data']);
    }
    if (dataClassName == 'KnowledgeChunk') {
      return deserialize<_i32.KnowledgeChunk>(data['data']);
    }
    if (dataClassName == 'KnowledgeDocument') {
      return deserialize<_i33.KnowledgeDocument>(data['data']);
    }
    if (dataClassName == 'KnowledgeSearchHit') {
      return deserialize<_i34.KnowledgeSearchHit>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i35.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'KolaException') {
      return deserialize<_i36.KolaException>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i37.Message>(data['data']);
    }
    if (dataClassName == 'MessageSuppression') {
      return deserialize<_i38.MessageSuppression>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i39.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i40.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i41.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentBankAccount') {
      return deserialize<_i42.PaymentBankAccount>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i43.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i44.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Product') {
      return deserialize<_i45.Product>(data['data']);
    }
    if (dataClassName == 'ProductMedia') {
      return deserialize<_i46.ProductMedia>(data['data']);
    }
    if (dataClassName == 'ProductVariant') {
      return deserialize<_i47.ProductVariant>(data['data']);
    }
    if (dataClassName == 'PublicCatalog') {
      return deserialize<_i48.PublicCatalog>(data['data']);
    }
    if (dataClassName == 'PublicCatalogItem') {
      return deserialize<_i49.PublicCatalogItem>(data['data']);
    }
    if (dataClassName == 'Sale') {
      return deserialize<_i50.Sale>(data['data']);
    }
    if (dataClassName == 'SaleLine') {
      return deserialize<_i51.SaleLine>(data['data']);
    }
    if (dataClassName == 'SaleLineInput') {
      return deserialize<_i52.SaleLineInput>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i53.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i54.SupportTicket>(data['data']);
    }
    if (dataClassName == 'Task') {
      return deserialize<_i55.Task>(data['data']);
    }
    if (dataClassName == 'TillDisplayItem') {
      return deserialize<_i56.TillDisplayItem>(data['data']);
    }
    if (dataClassName == 'TillDisplayState') {
      return deserialize<_i57.TillDisplayState>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i58.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i59.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WebhookEndpoint') {
      return deserialize<_i60.WebhookEndpoint>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i61.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i62.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswer') {
      return deserialize<_i63.WorkspaceAnswer>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerAction') {
      return deserialize<_i64.WorkspaceAnswerAction>(data['data']);
    }
    if (dataClassName == 'WorkspaceAnswerTurn') {
      return deserialize<_i65.WorkspaceAnswerTurn>(data['data']);
    }
    if (dataClassName == 'WorkspaceConnector') {
      return deserialize<_i66.WorkspaceConnector>(data['data']);
    }
    if (dataClassName == 'WorkspaceFeatureOverride') {
      return deserialize<_i67.WorkspaceFeatureOverride>(data['data']);
    }
    if (dataClassName == 'WorkspaceFinding') {
      return deserialize<_i68.WorkspaceFinding>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i69.WorkspaceMember>(data['data']);
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
