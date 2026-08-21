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

abstract class ConnectorSyncLog implements _i1.SerializableModel {
  ConnectorSyncLog._({
    this.id,
    required this.workspaceId,
    required this.connectorKey,
    required this.store,
    required this.kind,
    required this.status,
    this.recordsSeen,
    this.recordsChanged,
    this.errorMessage,
    required this.ranAt,
  });

  factory ConnectorSyncLog({
    int? id,
    required int workspaceId,
    required String connectorKey,
    required String store,
    required String kind,
    required String status,
    int? recordsSeen,
    int? recordsChanged,
    String? errorMessage,
    required DateTime ranAt,
  }) = _ConnectorSyncLogImpl;

  factory ConnectorSyncLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectorSyncLog(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectorKey: jsonSerialization['connectorKey'] as String,
      store: jsonSerialization['store'] as String,
      kind: jsonSerialization['kind'] as String,
      status: jsonSerialization['status'] as String,
      recordsSeen: jsonSerialization['recordsSeen'] as int?,
      recordsChanged: jsonSerialization['recordsChanged'] as int?,
      errorMessage: jsonSerialization['errorMessage'] as String?,
      ranAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['ranAt']),
    );
  }

  int? id;

  int workspaceId;

  String connectorKey;

  String store;

  String kind;

  String status;

  int? recordsSeen;

  int? recordsChanged;

  String? errorMessage;

  DateTime ranAt;

  /// Returns a shallow copy of this [ConnectorSyncLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectorSyncLog copyWith({
    int? id,
    int? workspaceId,
    String? connectorKey,
    String? store,
    String? kind,
    String? status,
    int? recordsSeen,
    int? recordsChanged,
    String? errorMessage,
    DateTime? ranAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectorSyncLog',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'store': store,
      'kind': kind,
      'status': status,
      if (recordsSeen != null) 'recordsSeen': recordsSeen,
      if (recordsChanged != null) 'recordsChanged': recordsChanged,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'ranAt': ranAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectorSyncLogImpl extends ConnectorSyncLog {
  _ConnectorSyncLogImpl({
    int? id,
    required int workspaceId,
    required String connectorKey,
    required String store,
    required String kind,
    required String status,
    int? recordsSeen,
    int? recordsChanged,
    String? errorMessage,
    required DateTime ranAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectorKey: connectorKey,
         store: store,
         kind: kind,
         status: status,
         recordsSeen: recordsSeen,
         recordsChanged: recordsChanged,
         errorMessage: errorMessage,
         ranAt: ranAt,
       );

  /// Returns a shallow copy of this [ConnectorSyncLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectorSyncLog copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectorKey,
    String? store,
    String? kind,
    String? status,
    Object? recordsSeen = _Undefined,
    Object? recordsChanged = _Undefined,
    Object? errorMessage = _Undefined,
    DateTime? ranAt,
  }) {
    return ConnectorSyncLog(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectorKey: connectorKey ?? this.connectorKey,
      store: store ?? this.store,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      recordsSeen: recordsSeen is int? ? recordsSeen : this.recordsSeen,
      recordsChanged: recordsChanged is int?
          ? recordsChanged
          : this.recordsChanged,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      ranAt: ranAt ?? this.ranAt,
    );
  }
}
