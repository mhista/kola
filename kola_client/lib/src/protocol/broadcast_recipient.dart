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

abstract class BroadcastRecipient implements _i1.SerializableModel {
  BroadcastRecipient._({
    this.id,
    required this.broadcastId,
    required this.workspaceId,
    required this.to,
    this.customerId,
    this.variablesJson,
    required this.state,
    required this.attemptCount,
    this.lastError,
    this.messageId,
    this.lastAttemptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BroadcastRecipient({
    int? id,
    required int broadcastId,
    required int workspaceId,
    required String to,
    int? customerId,
    String? variablesJson,
    required String state,
    required int attemptCount,
    String? lastError,
    int? messageId,
    DateTime? lastAttemptedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _BroadcastRecipientImpl;

  factory BroadcastRecipient.fromJson(Map<String, dynamic> jsonSerialization) {
    return BroadcastRecipient(
      id: jsonSerialization['id'] as int?,
      broadcastId: jsonSerialization['broadcastId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      to: jsonSerialization['to'] as String,
      customerId: jsonSerialization['customerId'] as int?,
      variablesJson: jsonSerialization['variablesJson'] as String?,
      state: jsonSerialization['state'] as String,
      attemptCount: jsonSerialization['attemptCount'] as int,
      lastError: jsonSerialization['lastError'] as String?,
      messageId: jsonSerialization['messageId'] as int?,
      lastAttemptedAt: jsonSerialization['lastAttemptedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastAttemptedAt'],
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

  int broadcastId;

  int workspaceId;

  String to;

  int? customerId;

  String? variablesJson;

  String state;

  int attemptCount;

  String? lastError;

  int? messageId;

  DateTime? lastAttemptedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [BroadcastRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BroadcastRecipient copyWith({
    int? id,
    int? broadcastId,
    int? workspaceId,
    String? to,
    int? customerId,
    String? variablesJson,
    String? state,
    int? attemptCount,
    String? lastError,
    int? messageId,
    DateTime? lastAttemptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BroadcastRecipient',
      if (id != null) 'id': id,
      'broadcastId': broadcastId,
      'workspaceId': workspaceId,
      'to': to,
      if (customerId != null) 'customerId': customerId,
      if (variablesJson != null) 'variablesJson': variablesJson,
      'state': state,
      'attemptCount': attemptCount,
      if (lastError != null) 'lastError': lastError,
      if (messageId != null) 'messageId': messageId,
      if (lastAttemptedAt != null) 'lastAttemptedAt': lastAttemptedAt?.toJson(),
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

class _BroadcastRecipientImpl extends BroadcastRecipient {
  _BroadcastRecipientImpl({
    int? id,
    required int broadcastId,
    required int workspaceId,
    required String to,
    int? customerId,
    String? variablesJson,
    required String state,
    required int attemptCount,
    String? lastError,
    int? messageId,
    DateTime? lastAttemptedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         broadcastId: broadcastId,
         workspaceId: workspaceId,
         to: to,
         customerId: customerId,
         variablesJson: variablesJson,
         state: state,
         attemptCount: attemptCount,
         lastError: lastError,
         messageId: messageId,
         lastAttemptedAt: lastAttemptedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [BroadcastRecipient]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BroadcastRecipient copyWith({
    Object? id = _Undefined,
    int? broadcastId,
    int? workspaceId,
    String? to,
    Object? customerId = _Undefined,
    Object? variablesJson = _Undefined,
    String? state,
    int? attemptCount,
    Object? lastError = _Undefined,
    Object? messageId = _Undefined,
    Object? lastAttemptedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BroadcastRecipient(
      id: id is int? ? id : this.id,
      broadcastId: broadcastId ?? this.broadcastId,
      workspaceId: workspaceId ?? this.workspaceId,
      to: to ?? this.to,
      customerId: customerId is int? ? customerId : this.customerId,
      variablesJson: variablesJson is String?
          ? variablesJson
          : this.variablesJson,
      state: state ?? this.state,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError is String? ? lastError : this.lastError,
      messageId: messageId is int? ? messageId : this.messageId,
      lastAttemptedAt: lastAttemptedAt is DateTime?
          ? lastAttemptedAt
          : this.lastAttemptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
