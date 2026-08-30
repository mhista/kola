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

abstract class MessageSuppression implements _i1.SerializableModel {
  MessageSuppression._({
    this.id,
    required this.workspaceId,
    required this.platform,
    required this.addressNormalized,
    required this.reason,
    required this.createdAt,
  });

  factory MessageSuppression({
    int? id,
    required int workspaceId,
    required String platform,
    required String addressNormalized,
    required String reason,
    required DateTime createdAt,
  }) = _MessageSuppressionImpl;

  factory MessageSuppression.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessageSuppression(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      platform: jsonSerialization['platform'] as String,
      addressNormalized: jsonSerialization['addressNormalized'] as String,
      reason: jsonSerialization['reason'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  String platform;

  String addressNormalized;

  String reason;

  DateTime createdAt;

  /// Returns a shallow copy of this [MessageSuppression]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessageSuppression copyWith({
    int? id,
    int? workspaceId,
    String? platform,
    String? addressNormalized,
    String? reason,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessageSuppression',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'platform': platform,
      'addressNormalized': addressNormalized,
      'reason': reason,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageSuppressionImpl extends MessageSuppression {
  _MessageSuppressionImpl({
    int? id,
    required int workspaceId,
    required String platform,
    required String addressNormalized,
    required String reason,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         platform: platform,
         addressNormalized: addressNormalized,
         reason: reason,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessageSuppression]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessageSuppression copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? platform,
    String? addressNormalized,
    String? reason,
    DateTime? createdAt,
  }) {
    return MessageSuppression(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      platform: platform ?? this.platform,
      addressNormalized: addressNormalized ?? this.addressNormalized,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
