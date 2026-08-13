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

abstract class Message implements _i1.SerializableModel {
  Message._({
    this.id,
    required this.conversationId,
    required this.direction,
    required this.senderType,
    required this.body,
    this.mediaKind,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaImagekitFileId,
    this.mediaMimeType,
    required this.createdAt,
  });

  factory Message({
    int? id,
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
    String? mediaKind,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaImagekitFileId,
    String? mediaMimeType,
    required DateTime createdAt,
  }) = _MessageImpl;

  factory Message.fromJson(Map<String, dynamic> jsonSerialization) {
    return Message(
      id: jsonSerialization['id'] as int?,
      conversationId: jsonSerialization['conversationId'] as int,
      direction: jsonSerialization['direction'] as String,
      senderType: jsonSerialization['senderType'] as String,
      body: jsonSerialization['body'] as String,
      mediaKind: jsonSerialization['mediaKind'] as String?,
      mediaUrl: jsonSerialization['mediaUrl'] as String?,
      mediaThumbnailUrl: jsonSerialization['mediaThumbnailUrl'] as String?,
      mediaImagekitFileId: jsonSerialization['mediaImagekitFileId'] as String?,
      mediaMimeType: jsonSerialization['mediaMimeType'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int conversationId;

  String direction;

  String senderType;

  String body;

  String? mediaKind;

  String? mediaUrl;

  String? mediaThumbnailUrl;

  String? mediaImagekitFileId;

  String? mediaMimeType;

  DateTime createdAt;

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Message copyWith({
    int? id,
    int? conversationId,
    String? direction,
    String? senderType,
    String? body,
    String? mediaKind,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaImagekitFileId,
    String? mediaMimeType,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'conversationId': conversationId,
      'direction': direction,
      'senderType': senderType,
      'body': body,
      if (mediaKind != null) 'mediaKind': mediaKind,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (mediaThumbnailUrl != null) 'mediaThumbnailUrl': mediaThumbnailUrl,
      if (mediaImagekitFileId != null)
        'mediaImagekitFileId': mediaImagekitFileId,
      if (mediaMimeType != null) 'mediaMimeType': mediaMimeType,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageImpl extends Message {
  _MessageImpl({
    int? id,
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
    String? mediaKind,
    String? mediaUrl,
    String? mediaThumbnailUrl,
    String? mediaImagekitFileId,
    String? mediaMimeType,
    required DateTime createdAt,
  }) : super._(
         id: id,
         conversationId: conversationId,
         direction: direction,
         senderType: senderType,
         body: body,
         mediaKind: mediaKind,
         mediaUrl: mediaUrl,
         mediaThumbnailUrl: mediaThumbnailUrl,
         mediaImagekitFileId: mediaImagekitFileId,
         mediaMimeType: mediaMimeType,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Message copyWith({
    Object? id = _Undefined,
    int? conversationId,
    String? direction,
    String? senderType,
    String? body,
    Object? mediaKind = _Undefined,
    Object? mediaUrl = _Undefined,
    Object? mediaThumbnailUrl = _Undefined,
    Object? mediaImagekitFileId = _Undefined,
    Object? mediaMimeType = _Undefined,
    DateTime? createdAt,
  }) {
    return Message(
      id: id is int? ? id : this.id,
      conversationId: conversationId ?? this.conversationId,
      direction: direction ?? this.direction,
      senderType: senderType ?? this.senderType,
      body: body ?? this.body,
      mediaKind: mediaKind is String? ? mediaKind : this.mediaKind,
      mediaUrl: mediaUrl is String? ? mediaUrl : this.mediaUrl,
      mediaThumbnailUrl: mediaThumbnailUrl is String?
          ? mediaThumbnailUrl
          : this.mediaThumbnailUrl,
      mediaImagekitFileId: mediaImagekitFileId is String?
          ? mediaImagekitFileId
          : this.mediaImagekitFileId,
      mediaMimeType: mediaMimeType is String?
          ? mediaMimeType
          : this.mediaMimeType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
