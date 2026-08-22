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

abstract class WorkspaceConnector implements _i1.SerializableModel {
  WorkspaceConnector._({
    this.id,
    required this.workspaceId,
    required this.connectorKey,
    required this.status,
    this.encryptedConfig,
    this.displayDetail,
    this.lastSyncedAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncRecordsSeen,
    this.lastSyncRecordsChanged,
    this.lastSyncErrorCount,
    this.retentionPolicy,
    this.syncCursor,
  });

  factory WorkspaceConnector({
    int? id,
    required int workspaceId,
    required String connectorKey,
    required String status,
    String? encryptedConfig,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? lastSyncRecordsSeen,
    int? lastSyncRecordsChanged,
    int? lastSyncErrorCount,
    String? retentionPolicy,
    String? syncCursor,
  }) = _WorkspaceConnectorImpl;

  factory WorkspaceConnector.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceConnector(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      connectorKey: jsonSerialization['connectorKey'] as String,
      status: jsonSerialization['status'] as String,
      encryptedConfig: jsonSerialization['encryptedConfig'] as String?,
      displayDetail: jsonSerialization['displayDetail'] as String?,
      lastSyncedAt: jsonSerialization['lastSyncedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSyncedAt'],
            ),
      lastError: jsonSerialization['lastError'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      lastSyncRecordsSeen: jsonSerialization['lastSyncRecordsSeen'] as int?,
      lastSyncRecordsChanged:
          jsonSerialization['lastSyncRecordsChanged'] as int?,
      lastSyncErrorCount: jsonSerialization['lastSyncErrorCount'] as int?,
      retentionPolicy: jsonSerialization['retentionPolicy'] as String?,
      syncCursor: jsonSerialization['syncCursor'] as String?,
    );
  }

  int? id;

  int workspaceId;

  String connectorKey;

  String status;

  String? encryptedConfig;

  String? displayDetail;

  DateTime? lastSyncedAt;

  String? lastError;

  DateTime createdAt;

  DateTime updatedAt;

  int? lastSyncRecordsSeen;

  int? lastSyncRecordsChanged;

  int? lastSyncErrorCount;

  String? retentionPolicy;

  String? syncCursor;

  /// Returns a shallow copy of this [WorkspaceConnector]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceConnector copyWith({
    int? id,
    int? workspaceId,
    String? connectorKey,
    String? status,
    String? encryptedConfig,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? lastSyncRecordsSeen,
    int? lastSyncRecordsChanged,
    int? lastSyncErrorCount,
    String? retentionPolicy,
    String? syncCursor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceConnector',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'connectorKey': connectorKey,
      'status': status,
      if (encryptedConfig != null) 'encryptedConfig': encryptedConfig,
      if (displayDetail != null) 'displayDetail': displayDetail,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt?.toJson(),
      if (lastError != null) 'lastError': lastError,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (lastSyncRecordsSeen != null)
        'lastSyncRecordsSeen': lastSyncRecordsSeen,
      if (lastSyncRecordsChanged != null)
        'lastSyncRecordsChanged': lastSyncRecordsChanged,
      if (lastSyncErrorCount != null) 'lastSyncErrorCount': lastSyncErrorCount,
      if (retentionPolicy != null) 'retentionPolicy': retentionPolicy,
      if (syncCursor != null) 'syncCursor': syncCursor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WorkspaceConnectorImpl extends WorkspaceConnector {
  _WorkspaceConnectorImpl({
    int? id,
    required int workspaceId,
    required String connectorKey,
    required String status,
    String? encryptedConfig,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
    int? lastSyncRecordsSeen,
    int? lastSyncRecordsChanged,
    int? lastSyncErrorCount,
    String? retentionPolicy,
    String? syncCursor,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         connectorKey: connectorKey,
         status: status,
         encryptedConfig: encryptedConfig,
         displayDetail: displayDetail,
         lastSyncedAt: lastSyncedAt,
         lastError: lastError,
         createdAt: createdAt,
         updatedAt: updatedAt,
         lastSyncRecordsSeen: lastSyncRecordsSeen,
         lastSyncRecordsChanged: lastSyncRecordsChanged,
         lastSyncErrorCount: lastSyncErrorCount,
         retentionPolicy: retentionPolicy,
         syncCursor: syncCursor,
       );

  /// Returns a shallow copy of this [WorkspaceConnector]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceConnector copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? connectorKey,
    String? status,
    Object? encryptedConfig = _Undefined,
    Object? displayDetail = _Undefined,
    Object? lastSyncedAt = _Undefined,
    Object? lastError = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastSyncRecordsSeen = _Undefined,
    Object? lastSyncRecordsChanged = _Undefined,
    Object? lastSyncErrorCount = _Undefined,
    Object? retentionPolicy = _Undefined,
    Object? syncCursor = _Undefined,
  }) {
    return WorkspaceConnector(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      connectorKey: connectorKey ?? this.connectorKey,
      status: status ?? this.status,
      encryptedConfig: encryptedConfig is String?
          ? encryptedConfig
          : this.encryptedConfig,
      displayDetail: displayDetail is String?
          ? displayDetail
          : this.displayDetail,
      lastSyncedAt: lastSyncedAt is DateTime?
          ? lastSyncedAt
          : this.lastSyncedAt,
      lastError: lastError is String? ? lastError : this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncRecordsSeen: lastSyncRecordsSeen is int?
          ? lastSyncRecordsSeen
          : this.lastSyncRecordsSeen,
      lastSyncRecordsChanged: lastSyncRecordsChanged is int?
          ? lastSyncRecordsChanged
          : this.lastSyncRecordsChanged,
      lastSyncErrorCount: lastSyncErrorCount is int?
          ? lastSyncErrorCount
          : this.lastSyncErrorCount,
      retentionPolicy: retentionPolicy is String?
          ? retentionPolicy
          : this.retentionPolicy,
      syncCursor: syncCursor is String? ? syncCursor : this.syncCursor,
    );
  }
}
