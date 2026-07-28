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

abstract class ErrandCredential
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ErrandCredential._({
    this.id,
    required this.errandId,
    required this.encryptedCredential,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ErrandCredential({
    int? id,
    required int errandId,
    required String encryptedCredential,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ErrandCredentialImpl;

  factory ErrandCredential.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrandCredential(
      id: jsonSerialization['id'] as int?,
      errandId: jsonSerialization['errandId'] as int,
      encryptedCredential: jsonSerialization['encryptedCredential'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int? id;

  int errandId;

  String encryptedCredential;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ErrandCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrandCredential copyWith({
    int? id,
    int? errandId,
    String? encryptedCredential,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrandCredential',
      if (id != null) 'id': id,
      'errandId': errandId,
      'encryptedCredential': encryptedCredential,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ErrandCredential',
      if (id != null) 'id': id,
      'errandId': errandId,
      'encryptedCredential': encryptedCredential,
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

class _ErrandCredentialImpl extends ErrandCredential {
  _ErrandCredentialImpl({
    int? id,
    required int errandId,
    required String encryptedCredential,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         errandId: errandId,
         encryptedCredential: encryptedCredential,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ErrandCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrandCredential copyWith({
    Object? id = _Undefined,
    int? errandId,
    String? encryptedCredential,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ErrandCredential(
      id: id is int? ? id : this.id,
      errandId: errandId ?? this.errandId,
      encryptedCredential: encryptedCredential ?? this.encryptedCredential,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
