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

abstract class OtpCode
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  OtpCode._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.recipientEmail,
    required this.code,
    required this.expiresAt,
    required this.attempts,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OtpCode({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String recipientEmail,
    required String code,
    required DateTime expiresAt,
    required int attempts,
    DateTime? verifiedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _OtpCodeImpl;

  factory OtpCode.fromJson(Map<String, dynamic> jsonSerialization) {
    return OtpCode(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      recipientEmail: jsonSerialization['recipientEmail'] as String,
      code: jsonSerialization['code'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      attempts: jsonSerialization['attempts'] as int,
      verifiedAt: jsonSerialization['verifiedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['verifiedAt']),
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

  int conversationId;

  String recipientEmail;

  String code;

  DateTime expiresAt;

  int attempts;

  DateTime? verifiedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [OtpCode]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  OtpCode copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? recipientEmail,
    String? code,
    DateTime? expiresAt,
    int? attempts,
    DateTime? verifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OtpCode',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'recipientEmail': recipientEmail,
      'code': code,
      'expiresAt': expiresAt.toJson(),
      'attempts': attempts,
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OtpCode',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'recipientEmail': recipientEmail,
      'code': code,
      'expiresAt': expiresAt.toJson(),
      'attempts': attempts,
      if (verifiedAt != null) 'verifiedAt': verifiedAt?.toJson(),
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

class _OtpCodeImpl extends OtpCode {
  _OtpCodeImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String recipientEmail,
    required String code,
    required DateTime expiresAt,
    required int attempts,
    DateTime? verifiedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         recipientEmail: recipientEmail,
         code: code,
         expiresAt: expiresAt,
         attempts: attempts,
         verifiedAt: verifiedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [OtpCode]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  OtpCode copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? recipientEmail,
    String? code,
    DateTime? expiresAt,
    int? attempts,
    Object? verifiedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OtpCode(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      attempts: attempts ?? this.attempts,
      verifiedAt: verifiedAt is DateTime? ? verifiedAt : this.verifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
