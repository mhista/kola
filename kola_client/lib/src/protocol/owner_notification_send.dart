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

abstract class OwnerNotificationSend implements _i1.SerializableModel {
  OwnerNotificationSend._({
    this.id,
    required this.workspaceId,
    required this.channel,
    required this.sentAt,
  });

  factory OwnerNotificationSend({
    int? id,
    required int workspaceId,
    required String channel,
    required DateTime sentAt,
  }) = _OwnerNotificationSendImpl;

  factory OwnerNotificationSend.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return OwnerNotificationSend(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      channel: jsonSerialization['channel'] as String,
      sentAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['sentAt']),
    );
  }

  int? id;

  int workspaceId;

  String channel;

  DateTime sentAt;

  /// Returns a shallow copy of this [OwnerNotificationSend]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OwnerNotificationSend copyWith({
    int? id,
    int? workspaceId,
    String? channel,
    DateTime? sentAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OwnerNotificationSend',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'channel': channel,
      'sentAt': sentAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OwnerNotificationSendImpl extends OwnerNotificationSend {
  _OwnerNotificationSendImpl({
    int? id,
    required int workspaceId,
    required String channel,
    required DateTime sentAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         channel: channel,
         sentAt: sentAt,
       );

  /// Returns a shallow copy of this [OwnerNotificationSend]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OwnerNotificationSend copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? channel,
    DateTime? sentAt,
  }) {
    return OwnerNotificationSend(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      channel: channel ?? this.channel,
      sentAt: sentAt ?? this.sentAt,
    );
  }
}
