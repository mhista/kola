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

abstract class Errand implements _i1.SerializableModel {
  Errand._({
    this.id,
    required this.workspaceId,
    required this.name,
    required this.descriptionForAi,
    required this.source,
    this.builtinHandlerKey,
    required this.createdVia,
    required this.permissionScope,
    required this.inputSchemaJson,
    required this.sensitiveInputKeysJson,
    required this.status,
    this.queryTemplateSql,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Errand({
    int? id,
    required int workspaceId,
    required String name,
    required String descriptionForAi,
    required String source,
    String? builtinHandlerKey,
    required String createdVia,
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
    required String status,
    String? queryTemplateSql,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ErrandImpl;

  factory Errand.fromJson(Map<String, dynamic> jsonSerialization) {
    return Errand(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      descriptionForAi: jsonSerialization['descriptionForAi'] as String,
      source: jsonSerialization['source'] as String,
      builtinHandlerKey: jsonSerialization['builtinHandlerKey'] as String?,
      createdVia: jsonSerialization['createdVia'] as String,
      permissionScope: jsonSerialization['permissionScope'] as String,
      inputSchemaJson: jsonSerialization['inputSchemaJson'] as String,
      sensitiveInputKeysJson:
          jsonSerialization['sensitiveInputKeysJson'] as String,
      status: jsonSerialization['status'] as String,
      queryTemplateSql: jsonSerialization['queryTemplateSql'] as String?,
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

  String descriptionForAi;

  String source;

  String? builtinHandlerKey;

  String createdVia;

  String permissionScope;

  String inputSchemaJson;

  String sensitiveInputKeysJson;

  String status;

  String? queryTemplateSql;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Errand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Errand copyWith({
    int? id,
    int? workspaceId,
    String? name,
    String? descriptionForAi,
    String? source,
    String? builtinHandlerKey,
    String? createdVia,
    String? permissionScope,
    String? inputSchemaJson,
    String? sensitiveInputKeysJson,
    String? status,
    String? queryTemplateSql,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Errand',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      'descriptionForAi': descriptionForAi,
      'source': source,
      if (builtinHandlerKey != null) 'builtinHandlerKey': builtinHandlerKey,
      'createdVia': createdVia,
      'permissionScope': permissionScope,
      'inputSchemaJson': inputSchemaJson,
      'sensitiveInputKeysJson': sensitiveInputKeysJson,
      'status': status,
      if (queryTemplateSql != null) 'queryTemplateSql': queryTemplateSql,
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

class _ErrandImpl extends Errand {
  _ErrandImpl({
    int? id,
    required int workspaceId,
    required String name,
    required String descriptionForAi,
    required String source,
    String? builtinHandlerKey,
    required String createdVia,
    required String permissionScope,
    required String inputSchemaJson,
    required String sensitiveInputKeysJson,
    required String status,
    String? queryTemplateSql,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         descriptionForAi: descriptionForAi,
         source: source,
         builtinHandlerKey: builtinHandlerKey,
         createdVia: createdVia,
         permissionScope: permissionScope,
         inputSchemaJson: inputSchemaJson,
         sensitiveInputKeysJson: sensitiveInputKeysJson,
         status: status,
         queryTemplateSql: queryTemplateSql,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Errand]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Errand copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    String? descriptionForAi,
    String? source,
    Object? builtinHandlerKey = _Undefined,
    String? createdVia,
    String? permissionScope,
    String? inputSchemaJson,
    String? sensitiveInputKeysJson,
    String? status,
    Object? queryTemplateSql = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Errand(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      descriptionForAi: descriptionForAi ?? this.descriptionForAi,
      source: source ?? this.source,
      builtinHandlerKey: builtinHandlerKey is String?
          ? builtinHandlerKey
          : this.builtinHandlerKey,
      createdVia: createdVia ?? this.createdVia,
      permissionScope: permissionScope ?? this.permissionScope,
      inputSchemaJson: inputSchemaJson ?? this.inputSchemaJson,
      sensitiveInputKeysJson:
          sensitiveInputKeysJson ?? this.sensitiveInputKeysJson,
      status: status ?? this.status,
      queryTemplateSql: queryTemplateSql is String?
          ? queryTemplateSql
          : this.queryTemplateSql,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
