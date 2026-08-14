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

abstract class WorkspaceFinding
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  WorkspaceFinding._({
    this.id,
    required this.workspaceId,
    required this.kind,
    required this.fingerprint,
    required this.severity,
    required this.title,
    this.detail,
    this.subjectType,
    this.subjectId,
    required this.confidence,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.resolvedAt,
    this.dismissedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkspaceFinding({
    int? id,
    required int workspaceId,
    required String kind,
    required String fingerprint,
    required int severity,
    required String title,
    String? detail,
    String? subjectType,
    int? subjectId,
    required double confidence,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    DateTime? resolvedAt,
    DateTime? dismissedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WorkspaceFindingImpl;

  factory WorkspaceFinding.fromJson(Map<String, dynamic> jsonSerialization) {
    return WorkspaceFinding(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      kind: jsonSerialization['kind'] as String,
      fingerprint: jsonSerialization['fingerprint'] as String,
      severity: jsonSerialization['severity'] as int,
      title: jsonSerialization['title'] as String,
      detail: jsonSerialization['detail'] as String?,
      subjectType: jsonSerialization['subjectType'] as String?,
      subjectId: jsonSerialization['subjectId'] as int?,
      confidence: (jsonSerialization['confidence'] as num).toDouble(),
      firstSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstSeenAt'],
      ),
      lastSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      dismissedAt: jsonSerialization['dismissedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['dismissedAt'],
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

  int workspaceId;

  String kind;

  String fingerprint;

  int severity;

  String title;

  String? detail;

  String? subjectType;

  int? subjectId;

  double confidence;

  DateTime firstSeenAt;

  DateTime lastSeenAt;

  DateTime? resolvedAt;

  DateTime? dismissedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WorkspaceFinding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WorkspaceFinding copyWith({
    int? id,
    int? workspaceId,
    String? kind,
    String? fingerprint,
    int? severity,
    String? title,
    String? detail,
    String? subjectType,
    int? subjectId,
    double? confidence,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    DateTime? resolvedAt,
    DateTime? dismissedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WorkspaceFinding',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'kind': kind,
      'fingerprint': fingerprint,
      'severity': severity,
      'title': title,
      if (detail != null) 'detail': detail,
      if (subjectType != null) 'subjectType': subjectType,
      if (subjectId != null) 'subjectId': subjectId,
      'confidence': confidence,
      'firstSeenAt': firstSeenAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (dismissedAt != null) 'dismissedAt': dismissedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WorkspaceFinding',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'kind': kind,
      'fingerprint': fingerprint,
      'severity': severity,
      'title': title,
      if (detail != null) 'detail': detail,
      if (subjectType != null) 'subjectType': subjectType,
      if (subjectId != null) 'subjectId': subjectId,
      'confidence': confidence,
      'firstSeenAt': firstSeenAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (dismissedAt != null) 'dismissedAt': dismissedAt?.toJson(),
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

class _WorkspaceFindingImpl extends WorkspaceFinding {
  _WorkspaceFindingImpl({
    int? id,
    required int workspaceId,
    required String kind,
    required String fingerprint,
    required int severity,
    required String title,
    String? detail,
    String? subjectType,
    int? subjectId,
    required double confidence,
    required DateTime firstSeenAt,
    required DateTime lastSeenAt,
    DateTime? resolvedAt,
    DateTime? dismissedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         kind: kind,
         fingerprint: fingerprint,
         severity: severity,
         title: title,
         detail: detail,
         subjectType: subjectType,
         subjectId: subjectId,
         confidence: confidence,
         firstSeenAt: firstSeenAt,
         lastSeenAt: lastSeenAt,
         resolvedAt: resolvedAt,
         dismissedAt: dismissedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WorkspaceFinding]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WorkspaceFinding copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? kind,
    String? fingerprint,
    int? severity,
    String? title,
    Object? detail = _Undefined,
    Object? subjectType = _Undefined,
    Object? subjectId = _Undefined,
    double? confidence,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    Object? resolvedAt = _Undefined,
    Object? dismissedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkspaceFinding(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      kind: kind ?? this.kind,
      fingerprint: fingerprint ?? this.fingerprint,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      detail: detail is String? ? detail : this.detail,
      subjectType: subjectType is String? ? subjectType : this.subjectType,
      subjectId: subjectId is int? ? subjectId : this.subjectId,
      confidence: confidence ?? this.confidence,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      dismissedAt: dismissedAt is DateTime? ? dismissedAt : this.dismissedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
