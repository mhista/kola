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

abstract class Workspace implements _i1.SerializableModel {
  Workspace._({
    this.id,
    required this.name,
    this.industryTag,
    this.ownerName,
    required this.plan,
    required this.status,
    required this.trialStartedAt,
    required this.trialFullAccessEndsAt,
    required this.trialEndsAt,
    required this.region,
    required this.isInternal,
    required this.taxRateBps,
    this.sellsCatalogItems,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workspace({
    int? id,
    required String name,
    String? industryTag,
    String? ownerName,
    required String plan,
    required String status,
    required DateTime trialStartedAt,
    required DateTime trialFullAccessEndsAt,
    required DateTime trialEndsAt,
    required String region,
    required bool isInternal,
    required int taxRateBps,
    bool? sellsCatalogItems,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkspaceImpl;

  factory Workspace.fromJson(Map<String, dynamic> jsonSerialization) {
    return Workspace(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      industryTag: jsonSerialization['industryTag'] as String?,
      ownerName: jsonSerialization['ownerName'] as String?,
      plan: jsonSerialization['plan'] as String,
      status: jsonSerialization['status'] as String,
      trialStartedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['trialStartedAt'],
      ),
      trialFullAccessEndsAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['trialFullAccessEndsAt'],
      ),
      trialEndsAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['trialEndsAt'],
      ),
      region: jsonSerialization['region'] as String,
      isInternal: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isInternal'],
      ),
      taxRateBps: jsonSerialization['taxRateBps'] as int,
      sellsCatalogItems: jsonSerialization['sellsCatalogItems'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['sellsCatalogItems'],
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

  String name;

  String? industryTag;

  String? ownerName;

  String plan;

  String status;

  DateTime trialStartedAt;

  DateTime trialFullAccessEndsAt;

  DateTime trialEndsAt;

  String region;

  bool isInternal;

  int taxRateBps;

  bool? sellsCatalogItems;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Workspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Workspace copyWith({
    int? id,
    String? name,
    String? industryTag,
    String? ownerName,
    String? plan,
    String? status,
    DateTime? trialStartedAt,
    DateTime? trialFullAccessEndsAt,
    DateTime? trialEndsAt,
    String? region,
    bool? isInternal,
    int? taxRateBps,
    bool? sellsCatalogItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Workspace',
      if (id != null) 'id': id,
      'name': name,
      if (industryTag != null) 'industryTag': industryTag,
      if (ownerName != null) 'ownerName': ownerName,
      'plan': plan,
      'status': status,
      'trialStartedAt': trialStartedAt.toJson(),
      'trialFullAccessEndsAt': trialFullAccessEndsAt.toJson(),
      'trialEndsAt': trialEndsAt.toJson(),
      'region': region,
      'isInternal': isInternal,
      'taxRateBps': taxRateBps,
      if (sellsCatalogItems != null) 'sellsCatalogItems': sellsCatalogItems,
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

class _WorkspaceImpl extends Workspace {
  _WorkspaceImpl({
    int? id,
    required String name,
    String? industryTag,
    String? ownerName,
    required String plan,
    required String status,
    required DateTime trialStartedAt,
    required DateTime trialFullAccessEndsAt,
    required DateTime trialEndsAt,
    required String region,
    required bool isInternal,
    required int taxRateBps,
    bool? sellsCatalogItems,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         industryTag: industryTag,
         ownerName: ownerName,
         plan: plan,
         status: status,
         trialStartedAt: trialStartedAt,
         trialFullAccessEndsAt: trialFullAccessEndsAt,
         trialEndsAt: trialEndsAt,
         region: region,
         isInternal: isInternal,
         taxRateBps: taxRateBps,
         sellsCatalogItems: sellsCatalogItems,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Workspace]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Workspace copyWith({
    Object? id = _Undefined,
    String? name,
    Object? industryTag = _Undefined,
    Object? ownerName = _Undefined,
    String? plan,
    String? status,
    DateTime? trialStartedAt,
    DateTime? trialFullAccessEndsAt,
    DateTime? trialEndsAt,
    String? region,
    bool? isInternal,
    int? taxRateBps,
    Object? sellsCatalogItems = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workspace(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      industryTag: industryTag is String? ? industryTag : this.industryTag,
      ownerName: ownerName is String? ? ownerName : this.ownerName,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      trialFullAccessEndsAt:
          trialFullAccessEndsAt ?? this.trialFullAccessEndsAt,
      trialEndsAt: trialEndsAt ?? this.trialEndsAt,
      region: region ?? this.region,
      isInternal: isInternal ?? this.isInternal,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      sellsCatalogItems: sellsCatalogItems is bool?
          ? sellsCatalogItems
          : this.sellsCatalogItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
