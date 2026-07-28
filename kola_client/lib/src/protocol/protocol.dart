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
import 'conversation.dart' as _i4;
import 'customer_profile.dart' as _i5;
import 'errand.dart' as _i6;
import 'errand_credential.dart' as _i7;
import 'errand_execution_log.dart' as _i8;
import 'kola_billing_checkout.dart' as _i9;
import 'message.dart' as _i10;
import 'otp_code.dart' as _i11;
import 'owner_notification_send.dart' as _i12;
import 'owner_notification_settings.dart' as _i13;
import 'payment_gateway_credential.dart' as _i14;
import 'payment_transaction.dart' as _i15;
import 'subscription.dart' as _i16;
import 'support_ticket.dart' as _i17;
import 'usage_record.dart' as _i18;
import 'waitlist_signup.dart' as _i19;
import 'whatsapp_message_template.dart' as _i20;
import 'workspace.dart' as _i21;
import 'workspace_member.dart' as _i22;
import 'package:kola_client/src/protocol/bot.dart' as _i23;
import 'package:kola_client/src/protocol/channel.dart' as _i24;
import 'package:kola_client/src/protocol/conversation.dart' as _i25;
import 'package:kola_client/src/protocol/message.dart' as _i26;
import 'package:kola_client/src/protocol/errand.dart' as _i27;
import 'package:kola_client/src/protocol/payment_gateway_credential.dart'
    as _i28;
import 'package:kola_client/src/protocol/support_ticket.dart' as _i29;
import 'package:kola_client/src/protocol/whatsapp_message_template.dart'
    as _i30;
import 'package:kola_client/src/protocol/workspace.dart' as _i31;
export 'bot.dart';
export 'channel.dart';
export 'conversation.dart';
export 'customer_profile.dart';
export 'errand.dart';
export 'errand_credential.dart';
export 'errand_execution_log.dart';
export 'kola_billing_checkout.dart';
export 'message.dart';
export 'otp_code.dart';
export 'owner_notification_send.dart';
export 'owner_notification_settings.dart';
export 'payment_gateway_credential.dart';
export 'payment_transaction.dart';
export 'subscription.dart';
export 'support_ticket.dart';
export 'usage_record.dart';
export 'waitlist_signup.dart';
export 'whatsapp_message_template.dart';
export 'workspace.dart';
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
    if (t == _i4.Conversation) {
      return _i4.Conversation.fromJson(data) as T;
    }
    if (t == _i5.CustomerProfile) {
      return _i5.CustomerProfile.fromJson(data) as T;
    }
    if (t == _i6.Errand) {
      return _i6.Errand.fromJson(data) as T;
    }
    if (t == _i7.ErrandCredential) {
      return _i7.ErrandCredential.fromJson(data) as T;
    }
    if (t == _i8.ErrandExecutionLog) {
      return _i8.ErrandExecutionLog.fromJson(data) as T;
    }
    if (t == _i9.KolaBillingCheckout) {
      return _i9.KolaBillingCheckout.fromJson(data) as T;
    }
    if (t == _i10.Message) {
      return _i10.Message.fromJson(data) as T;
    }
    if (t == _i11.OtpCode) {
      return _i11.OtpCode.fromJson(data) as T;
    }
    if (t == _i12.OwnerNotificationSend) {
      return _i12.OwnerNotificationSend.fromJson(data) as T;
    }
    if (t == _i13.OwnerNotificationSettings) {
      return _i13.OwnerNotificationSettings.fromJson(data) as T;
    }
    if (t == _i14.PaymentGatewayCredential) {
      return _i14.PaymentGatewayCredential.fromJson(data) as T;
    }
    if (t == _i15.PaymentTransaction) {
      return _i15.PaymentTransaction.fromJson(data) as T;
    }
    if (t == _i16.Subscription) {
      return _i16.Subscription.fromJson(data) as T;
    }
    if (t == _i17.SupportTicket) {
      return _i17.SupportTicket.fromJson(data) as T;
    }
    if (t == _i18.UsageRecord) {
      return _i18.UsageRecord.fromJson(data) as T;
    }
    if (t == _i19.WaitlistSignup) {
      return _i19.WaitlistSignup.fromJson(data) as T;
    }
    if (t == _i20.WhatsAppMessageTemplate) {
      return _i20.WhatsAppMessageTemplate.fromJson(data) as T;
    }
    if (t == _i21.Workspace) {
      return _i21.Workspace.fromJson(data) as T;
    }
    if (t == _i22.WorkspaceMember) {
      return _i22.WorkspaceMember.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Bot?>()) {
      return (data != null ? _i2.Bot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Channel?>()) {
      return (data != null ? _i3.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Conversation?>()) {
      return (data != null ? _i4.Conversation.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.CustomerProfile?>()) {
      return (data != null ? _i5.CustomerProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Errand?>()) {
      return (data != null ? _i6.Errand.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.ErrandCredential?>()) {
      return (data != null ? _i7.ErrandCredential.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ErrandExecutionLog?>()) {
      return (data != null ? _i8.ErrandExecutionLog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.KolaBillingCheckout?>()) {
      return (data != null ? _i9.KolaBillingCheckout.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i10.Message?>()) {
      return (data != null ? _i10.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.OtpCode?>()) {
      return (data != null ? _i11.OtpCode.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.OwnerNotificationSend?>()) {
      return (data != null ? _i12.OwnerNotificationSend.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i13.OwnerNotificationSettings?>()) {
      return (data != null
              ? _i13.OwnerNotificationSettings.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i14.PaymentGatewayCredential?>()) {
      return (data != null
              ? _i14.PaymentGatewayCredential.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i15.PaymentTransaction?>()) {
      return (data != null ? _i15.PaymentTransaction.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.Subscription?>()) {
      return (data != null ? _i16.Subscription.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.SupportTicket?>()) {
      return (data != null ? _i17.SupportTicket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.UsageRecord?>()) {
      return (data != null ? _i18.UsageRecord.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.WaitlistSignup?>()) {
      return (data != null ? _i19.WaitlistSignup.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.WhatsAppMessageTemplate?>()) {
      return (data != null ? _i20.WhatsAppMessageTemplate.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i21.Workspace?>()) {
      return (data != null ? _i21.Workspace.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.WorkspaceMember?>()) {
      return (data != null ? _i22.WorkspaceMember.fromJson(data) : null) as T;
    }
    if (t == List<_i23.Bot>) {
      return (data as List).map((e) => deserialize<_i23.Bot>(e)).toList() as T;
    }
    if (t == List<_i24.Channel>) {
      return (data as List).map((e) => deserialize<_i24.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i25.Conversation>) {
      return (data as List)
              .map((e) => deserialize<_i25.Conversation>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.Message>) {
      return (data as List).map((e) => deserialize<_i26.Message>(e)).toList()
          as T;
    }
    if (t == List<_i27.Errand>) {
      return (data as List).map((e) => deserialize<_i27.Errand>(e)).toList()
          as T;
    }
    if (t == List<_i28.PaymentGatewayCredential>) {
      return (data as List)
              .map((e) => deserialize<_i28.PaymentGatewayCredential>(e))
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
    if (t == List<_i29.SupportTicket>) {
      return (data as List)
              .map((e) => deserialize<_i29.SupportTicket>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i30.WhatsAppMessageTemplate>) {
      return (data as List)
              .map((e) => deserialize<_i30.WhatsAppMessageTemplate>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.Workspace>) {
      return (data as List).map((e) => deserialize<_i31.Workspace>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Bot => 'Bot',
      _i3.Channel => 'Channel',
      _i4.Conversation => 'Conversation',
      _i5.CustomerProfile => 'CustomerProfile',
      _i6.Errand => 'Errand',
      _i7.ErrandCredential => 'ErrandCredential',
      _i8.ErrandExecutionLog => 'ErrandExecutionLog',
      _i9.KolaBillingCheckout => 'KolaBillingCheckout',
      _i10.Message => 'Message',
      _i11.OtpCode => 'OtpCode',
      _i12.OwnerNotificationSend => 'OwnerNotificationSend',
      _i13.OwnerNotificationSettings => 'OwnerNotificationSettings',
      _i14.PaymentGatewayCredential => 'PaymentGatewayCredential',
      _i15.PaymentTransaction => 'PaymentTransaction',
      _i16.Subscription => 'Subscription',
      _i17.SupportTicket => 'SupportTicket',
      _i18.UsageRecord => 'UsageRecord',
      _i19.WaitlistSignup => 'WaitlistSignup',
      _i20.WhatsAppMessageTemplate => 'WhatsAppMessageTemplate',
      _i21.Workspace => 'Workspace',
      _i22.WorkspaceMember => 'WorkspaceMember',
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
      case _i4.Conversation():
        return 'Conversation';
      case _i5.CustomerProfile():
        return 'CustomerProfile';
      case _i6.Errand():
        return 'Errand';
      case _i7.ErrandCredential():
        return 'ErrandCredential';
      case _i8.ErrandExecutionLog():
        return 'ErrandExecutionLog';
      case _i9.KolaBillingCheckout():
        return 'KolaBillingCheckout';
      case _i10.Message():
        return 'Message';
      case _i11.OtpCode():
        return 'OtpCode';
      case _i12.OwnerNotificationSend():
        return 'OwnerNotificationSend';
      case _i13.OwnerNotificationSettings():
        return 'OwnerNotificationSettings';
      case _i14.PaymentGatewayCredential():
        return 'PaymentGatewayCredential';
      case _i15.PaymentTransaction():
        return 'PaymentTransaction';
      case _i16.Subscription():
        return 'Subscription';
      case _i17.SupportTicket():
        return 'SupportTicket';
      case _i18.UsageRecord():
        return 'UsageRecord';
      case _i19.WaitlistSignup():
        return 'WaitlistSignup';
      case _i20.WhatsAppMessageTemplate():
        return 'WhatsAppMessageTemplate';
      case _i21.Workspace():
        return 'Workspace';
      case _i22.WorkspaceMember():
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
    if (dataClassName == 'Conversation') {
      return deserialize<_i4.Conversation>(data['data']);
    }
    if (dataClassName == 'CustomerProfile') {
      return deserialize<_i5.CustomerProfile>(data['data']);
    }
    if (dataClassName == 'Errand') {
      return deserialize<_i6.Errand>(data['data']);
    }
    if (dataClassName == 'ErrandCredential') {
      return deserialize<_i7.ErrandCredential>(data['data']);
    }
    if (dataClassName == 'ErrandExecutionLog') {
      return deserialize<_i8.ErrandExecutionLog>(data['data']);
    }
    if (dataClassName == 'KolaBillingCheckout') {
      return deserialize<_i9.KolaBillingCheckout>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i10.Message>(data['data']);
    }
    if (dataClassName == 'OtpCode') {
      return deserialize<_i11.OtpCode>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSend') {
      return deserialize<_i12.OwnerNotificationSend>(data['data']);
    }
    if (dataClassName == 'OwnerNotificationSettings') {
      return deserialize<_i13.OwnerNotificationSettings>(data['data']);
    }
    if (dataClassName == 'PaymentGatewayCredential') {
      return deserialize<_i14.PaymentGatewayCredential>(data['data']);
    }
    if (dataClassName == 'PaymentTransaction') {
      return deserialize<_i15.PaymentTransaction>(data['data']);
    }
    if (dataClassName == 'Subscription') {
      return deserialize<_i16.Subscription>(data['data']);
    }
    if (dataClassName == 'SupportTicket') {
      return deserialize<_i17.SupportTicket>(data['data']);
    }
    if (dataClassName == 'UsageRecord') {
      return deserialize<_i18.UsageRecord>(data['data']);
    }
    if (dataClassName == 'WaitlistSignup') {
      return deserialize<_i19.WaitlistSignup>(data['data']);
    }
    if (dataClassName == 'WhatsAppMessageTemplate') {
      return deserialize<_i20.WhatsAppMessageTemplate>(data['data']);
    }
    if (dataClassName == 'Workspace') {
      return deserialize<_i21.Workspace>(data['data']);
    }
    if (dataClassName == 'WorkspaceMember') {
      return deserialize<_i22.WorkspaceMember>(data['data']);
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
