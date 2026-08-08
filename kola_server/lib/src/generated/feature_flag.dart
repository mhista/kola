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

abstract class FeatureFlag
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  FeatureFlag._({
    this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.state,
    this.minimumPlan,
    required this.releasePhase,
    required this.externallyGated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeatureFlag({
    int? id,
    required String key,
    required String name,
    required String description,
    required String state,
    String? minimumPlan,
    required String releasePhase,
    required bool externallyGated,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FeatureFlagImpl;

  factory FeatureFlag.fromJson(Map<String, dynamic> jsonSerialization) {
    return FeatureFlag(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      state: jsonSerialization['state'] as String,
      minimumPlan: jsonSerialization['minimumPlan'] as String?,
      releasePhase: jsonSerialization['releasePhase'] as String,
      externallyGated: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['externallyGated'],
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

  String key;

  String name;

  String description;

  String state;

  String? minimumPlan;

  String releasePhase;

  bool externallyGated;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [FeatureFlag]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FeatureFlag copyWith({
    int? id,
    String? key,
    String? name,
    String? description,
    String? state,
    String? minimumPlan,
    String? releasePhase,
    bool? externallyGated,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FeatureFlag',
      if (id != null) 'id': id,
      'key': key,
      'name': name,
      'description': description,
      'state': state,
      if (minimumPlan != null) 'minimumPlan': minimumPlan,
      'releasePhase': releasePhase,
      'externallyGated': externallyGated,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FeatureFlag',
      if (id != null) 'id': id,
      'key': key,
      'name': name,
      'description': description,
      'state': state,
      if (minimumPlan != null) 'minimumPlan': minimumPlan,
      'releasePhase': releasePhase,
      'externallyGated': externallyGated,
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

class _FeatureFlagImpl extends FeatureFlag {
  _FeatureFlagImpl({
    int? id,
    required String key,
    required String name,
    required String description,
    required String state,
    String? minimumPlan,
    required String releasePhase,
    required bool externallyGated,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         key: key,
         name: name,
         description: description,
         state: state,
         minimumPlan: minimumPlan,
         releasePhase: releasePhase,
         externallyGated: externallyGated,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [FeatureFlag]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FeatureFlag copyWith({
    Object? id = _Undefined,
    String? key,
    String? name,
    String? description,
    String? state,
    Object? minimumPlan = _Undefined,
    String? releasePhase,
    bool? externallyGated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeatureFlag(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      state: state ?? this.state,
      minimumPlan: minimumPlan is String? ? minimumPlan : this.minimumPlan,
      releasePhase: releasePhase ?? this.releasePhase,
      externallyGated: externallyGated ?? this.externallyGated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
