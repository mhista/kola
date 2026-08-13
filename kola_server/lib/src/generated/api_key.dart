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

abstract class ApiKey
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ApiKey._({
    this.id,
    required this.workspaceId,
    required this.name,
    required this.keyPrefix,
    required this.keyHash,
    required this.lastFour,
    required this.scope,
    this.lastUsedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiKey({
    int? id,
    required int workspaceId,
    required String name,
    required String keyPrefix,
    required String keyHash,
    required String lastFour,
    required String scope,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ApiKeyImpl;

  factory ApiKey.fromJson(Map<String, dynamic> jsonSerialization) {
    return ApiKey(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      keyPrefix: jsonSerialization['keyPrefix'] as String,
      keyHash: jsonSerialization['keyHash'] as String,
      lastFour: jsonSerialization['lastFour'] as String,
      scope: jsonSerialization['scope'] as String,
      lastUsedAt: jsonSerialization['lastUsedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastUsedAt']),
      revokedAt: jsonSerialization['revokedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['revokedAt']),
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

  String name;

  String keyPrefix;

  String keyHash;

  String lastFour;

  String scope;

  DateTime? lastUsedAt;

  DateTime? revokedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ApiKey copyWith({
    int? id,
    int? workspaceId,
    String? name,
    String? keyPrefix,
    String? keyHash,
    String? lastFour,
    String? scope,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ApiKey',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'keyPrefix': keyPrefix,
      'keyHash': keyHash,
      'lastFour': lastFour,
      'scope': scope,
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ApiKey',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'keyPrefix': keyPrefix,
      'keyHash': keyHash,
      'lastFour': lastFour,
      'scope': scope,
      if (lastUsedAt != null) 'lastUsedAt': lastUsedAt?.toJson(),
      if (revokedAt != null) 'revokedAt': revokedAt?.toJson(),
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

class _ApiKeyImpl extends ApiKey {
  _ApiKeyImpl({
    int? id,
    required int workspaceId,
    required String name,
    required String keyPrefix,
    required String keyHash,
    required String lastFour,
    required String scope,
    DateTime? lastUsedAt,
    DateTime? revokedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         keyPrefix: keyPrefix,
         keyHash: keyHash,
         lastFour: lastFour,
         scope: scope,
         lastUsedAt: lastUsedAt,
         revokedAt: revokedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ApiKey]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ApiKey copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    String? keyPrefix,
    String? keyHash,
    String? lastFour,
    String? scope,
    Object? lastUsedAt = _Undefined,
    Object? revokedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiKey(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      keyPrefix: keyPrefix ?? this.keyPrefix,
      keyHash: keyHash ?? this.keyHash,
      lastFour: lastFour ?? this.lastFour,
      scope: scope ?? this.scope,
      lastUsedAt: lastUsedAt is DateTime? ? lastUsedAt : this.lastUsedAt,
      revokedAt: revokedAt is DateTime? ? revokedAt : this.revokedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
