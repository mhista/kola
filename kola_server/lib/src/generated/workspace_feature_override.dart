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

abstract class WorkspaceFeatureOverride
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceFeatureOverride._({
    this.id,
    required this.workspaceId,
    required this.featureKey,
    required this.enabled,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceFeatureOverride({
    int? id,
    required int workspaceId,
    required String featureKey,
    required bool enabled,
    required String note,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkspaceFeatureOverrideImpl;

  factory WorkspaceFeatureOverride.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WorkspaceFeatureOverride(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      featureKey: jsonSerialization['featureKey'] as String,
      enabled: _i1.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      note: jsonSerialization['note'] as String,
      createdBy: jsonSerialization['createdBy'] as String,
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

  String featureKey;

  bool enabled;

  String note;

  String createdBy;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WorkspaceFeatureOverride]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceFeatureOverride copyWith({
    int? id,
    int? workspaceId,
    String? featureKey,
    bool? enabled,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceFeatureOverride',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
      'enabled': enabled,
      'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceFeatureOverride',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'featureKey': featureKey,
      'enabled': enabled,
      'note': note,
      'createdBy': createdBy,
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

class _WorkspaceFeatureOverrideImpl extends WorkspaceFeatureOverride {
  _WorkspaceFeatureOverrideImpl({
    int? id,
    required int workspaceId,
    required String featureKey,
    required bool enabled,
    required String note,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         featureKey: featureKey,
         enabled: enabled,
         note: note,
         createdBy: createdBy,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceFeatureOverride]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceFeatureOverride copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? featureKey,
    bool? enabled,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceFeatureOverride(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      featureKey: featureKey ?? this.featureKey,
      enabled: enabled ?? this.enabled,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
