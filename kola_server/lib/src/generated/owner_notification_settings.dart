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

abstract class OwnerNotificationSettings
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OwnerNotificationSettings._({
    this.id,
    required this.workspaceId,
    this.ownerEmail,
    required this.emailEnabled,
    this.ownerWhatsappNumber,
    required this.whatsappEnabled,
    this.telegramChatId,
    required this.telegramEnabled,
    this.ownerSmsNumber,
    required this.smsEnabled,
    this.encryptedSlackWebhookUrl,
    required this.slackEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OwnerNotificationSettings({
    int? id,
    required int workspaceId,
    String? ownerEmail,
    required bool emailEnabled,
    String? ownerWhatsappNumber,
    required bool whatsappEnabled,
    String? telegramChatId,
    required bool telegramEnabled,
    String? ownerSmsNumber,
    required bool smsEnabled,
    String? encryptedSlackWebhookUrl,
    required bool slackEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _OwnerNotificationSettingsImpl;

  factory OwnerNotificationSettings.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OwnerNotificationSettings(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      ownerEmail: jsonSerialization['ownerEmail'] as String?,
      emailEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['emailEnabled'],
      ),
      ownerWhatsappNumber: jsonSerialization['ownerWhatsappNumber'] as String?,
      whatsappEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['whatsappEnabled'],
      ),
      telegramChatId: jsonSerialization['telegramChatId'] as String?,
      telegramEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['telegramEnabled'],
      ),
      ownerSmsNumber: jsonSerialization['ownerSmsNumber'] as String?,
      smsEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['smsEnabled'],
      ),
      encryptedSlackWebhookUrl:
          jsonSerialization['encryptedSlackWebhookUrl'] as String?,
      slackEnabled: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['slackEnabled'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  String? ownerEmail;

  bool emailEnabled;

  String? ownerWhatsappNumber;

  bool whatsappEnabled;

  String? telegramChatId;

  bool telegramEnabled;

  String? ownerSmsNumber;

  bool smsEnabled;

  String? encryptedSlackWebhookUrl;

  bool slackEnabled;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [OwnerNotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnerNotificationSettings copyWith({
    int? id,
    int? workspaceId,
    String? ownerEmail,
    bool? emailEnabled,
    String? ownerWhatsappNumber,
    bool? whatsappEnabled,
    String? telegramChatId,
    bool? telegramEnabled,
    String? ownerSmsNumber,
    bool? smsEnabled,
    String? encryptedSlackWebhookUrl,
    bool? slackEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnerNotificationSettings',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      'emailEnabled': emailEnabled,
      if (ownerWhatsappNumber != null)
        'ownerWhatsappNumber': ownerWhatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      if (telegramChatId != null) 'telegramChatId': telegramChatId,
      'telegramEnabled': telegramEnabled,
      if (ownerSmsNumber != null) 'ownerSmsNumber': ownerSmsNumber,
      'smsEnabled': smsEnabled,
      if (encryptedSlackWebhookUrl != null)
        'encryptedSlackWebhookUrl': encryptedSlackWebhookUrl,
      'slackEnabled': slackEnabled,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OwnerNotificationSettings',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      'emailEnabled': emailEnabled,
      if (ownerWhatsappNumber != null)
        'ownerWhatsappNumber': ownerWhatsappNumber,
      'whatsappEnabled': whatsappEnabled,
      if (telegramChatId != null) 'telegramChatId': telegramChatId,
      'telegramEnabled': telegramEnabled,
      if (ownerSmsNumber != null) 'ownerSmsNumber': ownerSmsNumber,
      'smsEnabled': smsEnabled,
      if (encryptedSlackWebhookUrl != null)
        'encryptedSlackWebhookUrl': encryptedSlackWebhookUrl,
      'slackEnabled': slackEnabled,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnerNotificationSettingsImpl extends OwnerNotificationSettings {
  _OwnerNotificationSettingsImpl({
    int? id,
    required int workspaceId,
    String? ownerEmail,
    required bool emailEnabled,
    String? ownerWhatsappNumber,
    required bool whatsappEnabled,
    String? telegramChatId,
    required bool telegramEnabled,
    String? ownerSmsNumber,
    required bool smsEnabled,
    String? encryptedSlackWebhookUrl,
    required bool slackEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         ownerEmail: ownerEmail,
         emailEnabled: emailEnabled,
         ownerWhatsappNumber: ownerWhatsappNumber,
         whatsappEnabled: whatsappEnabled,
         telegramChatId: telegramChatId,
         telegramEnabled: telegramEnabled,
         ownerSmsNumber: ownerSmsNumber,
         smsEnabled: smsEnabled,
         encryptedSlackWebhookUrl: encryptedSlackWebhookUrl,
         slackEnabled: slackEnabled,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [OwnerNotificationSettings]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnerNotificationSettings copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    Object? ownerEmail = _Undefined,
    bool? emailEnabled,
    Object? ownerWhatsappNumber = _Undefined,
    bool? whatsappEnabled,
    Object? telegramChatId = _Undefined,
    bool? telegramEnabled,
    Object? ownerSmsNumber = _Undefined,
    bool? smsEnabled,
    Object? encryptedSlackWebhookUrl = _Undefined,
    bool? slackEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OwnerNotificationSettings(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      ownerEmail: ownerEmail is String? ? ownerEmail : this.ownerEmail,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      ownerWhatsappNumber: ownerWhatsappNumber is String?
          ? ownerWhatsappNumber
          : this.ownerWhatsappNumber,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      telegramChatId: telegramChatId is String?
          ? telegramChatId
          : this.telegramChatId,
      telegramEnabled: telegramEnabled ?? this.telegramEnabled,
      ownerSmsNumber: ownerSmsNumber is String?
          ? ownerSmsNumber
          : this.ownerSmsNumber,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      encryptedSlackWebhookUrl: encryptedSlackWebhookUrl is String?
          ? encryptedSlackWebhookUrl
          : this.encryptedSlackWebhookUrl,
      slackEnabled: slackEnabled ?? this.slackEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
