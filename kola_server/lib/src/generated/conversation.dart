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

abstract class Conversation
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Conversation._({
    this.id,
    required this.workspaceId,
    required this.botId,
    required this.channelId,
    required this.platformType,
    required this.externalUserId,
    this.displayName,
    required this.status,
    this.customerId,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation({
    int? id,
    required int workspaceId,
    required int botId,
    required int channelId,
    required String platformType,
    required String externalUserId,
    String? displayName,
    required String status,
    int? customerId,
    required DateTime lastMessageAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ConversationImpl;

  factory Conversation.fromJson(Map<String, dynamic> jsonSerialization) {
    return Conversation(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      botId: jsonSerialization['botId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      platformType: jsonSerialization['platformType'] as String,
      externalUserId: jsonSerialization['externalUserId'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      status: jsonSerialization['status'] as String,
      customerId: jsonSerialization['customerId'] as int?,
      lastMessageAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastMessageAt'],
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

  int botId;

  int channelId;

  String platformType;

  String externalUserId;

  String? displayName;

  String status;

  int? customerId;

  DateTime lastMessageAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Conversation copyWith({
    int? id,
    int? workspaceId,
    int? botId,
    int? channelId,
    String? platformType,
    String? externalUserId,
    String? displayName,
    String? status,
    int? customerId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Conversation',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'botId': botId,
      'channelId': channelId,
      'platformType': platformType,
      'externalUserId': externalUserId,
      if (displayName != null) 'displayName': displayName,
      'status': status,
      if (customerId != null) 'customerId': customerId,
      'lastMessageAt': lastMessageAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Conversation',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'botId': botId,
      'channelId': channelId,
      'platformType': platformType,
      'externalUserId': externalUserId,
      if (displayName != null) 'displayName': displayName,
      'status': status,
      if (customerId != null) 'customerId': customerId,
      'lastMessageAt': lastMessageAt.toJson(),
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

class _ConversationImpl extends Conversation {
  _ConversationImpl({
    int? id,
    required int workspaceId,
    required int botId,
    required int channelId,
    required String platformType,
    required String externalUserId,
    String? displayName,
    required String status,
    int? customerId,
    required DateTime lastMessageAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         botId: botId,
         channelId: channelId,
         platformType: platformType,
         externalUserId: externalUserId,
         displayName: displayName,
         status: status,
         customerId: customerId,
         lastMessageAt: lastMessageAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Conversation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Conversation copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? botId,
    int? channelId,
    String? platformType,
    String? externalUserId,
    Object? displayName = _Undefined,
    String? status,
    Object? customerId = _Undefined,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      botId: botId ?? this.botId,
      channelId: channelId ?? this.channelId,
      platformType: platformType ?? this.platformType,
      externalUserId: externalUserId ?? this.externalUserId,
      displayName: displayName is String? ? displayName : this.displayName,
      status: status ?? this.status,
      customerId: customerId is int? ? customerId : this.customerId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
