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

abstract class WorkspaceAnswerTurn
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceAnswerTurn._({
    this.id,
    required this.workspaceId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory WorkspaceAnswerTurn({
    int? id,
    required int workspaceId,
    required String role,
    required String content,
    required DateTime createdAt,
  }) = _WorkspaceAnswerTurnImpl;

  factory WorkspaceAnswerTurn.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceAnswerTurn(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      role: jsonSerialization['role'] as String,
      content: jsonSerialization['content'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  String role;

  String content;

  DateTime createdAt;

  /// Returns a shallow copy of this [WorkspaceAnswerTurn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceAnswerTurn copyWith({
    int? id,
    int? workspaceId,
    String? role,
    String? content,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceAnswerTurn',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceAnswerTurn',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceAnswerTurnImpl extends WorkspaceAnswerTurn {
  _WorkspaceAnswerTurnImpl({
    int? id,
    required int workspaceId,
    required String role,
    required String content,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         role: role,
         content: content,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WorkspaceAnswerTurn]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceAnswerTurn copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return WorkspaceAnswerTurn(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
