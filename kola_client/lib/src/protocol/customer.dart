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

abstract class Customer implements _i1.SerializableModel {
  Customer._({
    this.id,
    required this.workspaceId,
    this.displayName,
    required this.firstSeenSource,
    required this.firstSeenAt,
    this.mergedIntoId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer({
    int? id,
    required int workspaceId,
    String? displayName,
    required String firstSeenSource,
    required DateTime firstSeenAt,
    int? mergedIntoId,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CustomerImpl;

  factory Customer.fromJson(Map<String, dynamic> jsonSerialization) {
    return Customer(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      displayName: jsonSerialization['displayName'] as String?,
      firstSeenSource: jsonSerialization['firstSeenSource'] as String,
      firstSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstSeenAt'],
      ),
      mergedIntoId: jsonSerialization['mergedIntoId'] as int?,
      notes: jsonSerialization['notes'] as String?,
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

  String? displayName;

  String firstSeenSource;

  DateTime firstSeenAt;

  int? mergedIntoId;

  String? notes;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Customer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Customer copyWith({
    int? id,
    int? workspaceId,
    String? displayName,
    String? firstSeenSource,
    DateTime? firstSeenAt,
    int? mergedIntoId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Customer',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (displayName != null) 'displayName': displayName,
      'firstSeenSource': firstSeenSource,
      'firstSeenAt': firstSeenAt.toJson(),
      if (mergedIntoId != null) 'mergedIntoId': mergedIntoId,
      if (notes != null) 'notes': notes,
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

class _CustomerImpl extends Customer {
  _CustomerImpl({
    int? id,
    required int workspaceId,
    String? displayName,
    required String firstSeenSource,
    required DateTime firstSeenAt,
    int? mergedIntoId,
    String? notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         displayName: displayName,
         firstSeenSource: firstSeenSource,
         firstSeenAt: firstSeenAt,
         mergedIntoId: mergedIntoId,
         notes: notes,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Customer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Customer copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    Object? displayName = _Undefined,
    String? firstSeenSource,
    DateTime? firstSeenAt,
    Object? mergedIntoId = _Undefined,
    Object? notes = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      displayName: displayName is String? ? displayName : this.displayName,
      firstSeenSource: firstSeenSource ?? this.firstSeenSource,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      mergedIntoId: mergedIntoId is int? ? mergedIntoId : this.mergedIntoId,
      notes: notes is String? ? notes : this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
