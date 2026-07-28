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

abstract class WhatsAppMessageTemplate implements _i1.SerializableModel {
  WhatsAppMessageTemplate._({
    this.id,
    required this.workspaceId,
    required this.channelId,
    required this.metaTemplateName,
    required this.requestedCategory,
    this.metaCategory,
    required this.language,
    required this.bodyText,
    this.metaTemplateId,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WhatsAppMessageTemplate({
    int? id,
    required int workspaceId,
    required int channelId,
    required String metaTemplateName,
    required String requestedCategory,
    String? metaCategory,
    required String language,
    required String bodyText,
    String? metaTemplateId,
    required String status,
    String? rejectionReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WhatsAppMessageTemplateImpl;

  factory WhatsAppMessageTemplate.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WhatsAppMessageTemplate(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      metaTemplateName: jsonSerialization['metaTemplateName'] as String,
      requestedCategory: jsonSerialization['requestedCategory'] as String,
      metaCategory: jsonSerialization['metaCategory'] as String?,
      language: jsonSerialization['language'] as String,
      bodyText: jsonSerialization['bodyText'] as String,
      metaTemplateId: jsonSerialization['metaTemplateId'] as String?,
      status: jsonSerialization['status'] as String,
      rejectionReason: jsonSerialization['rejectionReason'] as String?,
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

  int channelId;

  String metaTemplateName;

  String requestedCategory;

  String? metaCategory;

  String language;

  String bodyText;

  String? metaTemplateId;

  String status;

  String? rejectionReason;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WhatsAppMessageTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WhatsAppMessageTemplate copyWith({
    int? id,
    int? workspaceId,
    int? channelId,
    String? metaTemplateName,
    String? requestedCategory,
    String? metaCategory,
    String? language,
    String? bodyText,
    String? metaTemplateId,
    String? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WhatsAppMessageTemplate',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'channelId': channelId,
      'metaTemplateName': metaTemplateName,
      'requestedCategory': requestedCategory,
      if (metaCategory != null) 'metaCategory': metaCategory,
      'language': language,
      'bodyText': bodyText,
      if (metaTemplateId != null) 'metaTemplateId': metaTemplateId,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
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

class _WhatsAppMessageTemplateImpl extends WhatsAppMessageTemplate {
  _WhatsAppMessageTemplateImpl({
    int? id,
    required int workspaceId,
    required int channelId,
    required String metaTemplateName,
    required String requestedCategory,
    String? metaCategory,
    required String language,
    required String bodyText,
    String? metaTemplateId,
    required String status,
    String? rejectionReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         channelId: channelId,
         metaTemplateName: metaTemplateName,
         requestedCategory: requestedCategory,
         metaCategory: metaCategory,
         language: language,
         bodyText: bodyText,
         metaTemplateId: metaTemplateId,
         status: status,
         rejectionReason: rejectionReason,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WhatsAppMessageTemplate]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WhatsAppMessageTemplate copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? channelId,
    String? metaTemplateName,
    String? requestedCategory,
    Object? metaCategory = _Undefined,
    String? language,
    String? bodyText,
    Object? metaTemplateId = _Undefined,
    String? status,
    Object? rejectionReason = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WhatsAppMessageTemplate(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      channelId: channelId ?? this.channelId,
      metaTemplateName: metaTemplateName ?? this.metaTemplateName,
      requestedCategory: requestedCategory ?? this.requestedCategory,
      metaCategory: metaCategory is String? ? metaCategory : this.metaCategory,
      language: language ?? this.language,
      bodyText: bodyText ?? this.bodyText,
      metaTemplateId: metaTemplateId is String?
          ? metaTemplateId
          : this.metaTemplateId,
      status: status ?? this.status,
      rejectionReason: rejectionReason is String?
          ? rejectionReason
          : this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
