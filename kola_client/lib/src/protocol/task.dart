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

abstract class Task implements _i1.SerializableModel {
  Task._({
    this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.priority,
    this.sourceType,
    this.sourceFindingId,
    this.assignee,
    this.dueAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task({
    int? id,
    required int workspaceId,
    required String title,
    required String status,
    required String priority,
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskImpl;

  factory Task.fromJson(Map<String, dynamic> jsonSerialization) {
    return Task(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      title: jsonSerialization['title'] as String,
      status: jsonSerialization['status'] as String,
      priority: jsonSerialization['priority'] as String,
      sourceType: jsonSerialization['sourceType'] as String?,
      sourceFindingId: jsonSerialization['sourceFindingId'] as int?,
      assignee: jsonSerialization['assignee'] as String?,
      dueAt: jsonSerialization['dueAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dueAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
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

  String title;

  String status;

  String priority;

  String? sourceType;

  int? sourceFindingId;

  String? assignee;

  DateTime? dueAt;

  DateTime? completedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Task copyWith({
    int? id,
    int? workspaceId,
    String? title,
    String? status,
    String? priority,
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Task',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'title': title,
      'status': status,
      'priority': priority,
      if (sourceType != null) 'sourceType': sourceType,
      if (sourceFindingId != null) 'sourceFindingId': sourceFindingId,
      if (assignee != null) 'assignee': assignee,
      if (dueAt != null) 'dueAt': dueAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
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

class _TaskImpl extends Task {
  _TaskImpl({
    int? id,
    required int workspaceId,
    required String title,
    required String status,
    required String priority,
    String? sourceType,
    int? sourceFindingId,
    String? assignee,
    DateTime? dueAt,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         title: title,
         status: status,
         priority: priority,
         sourceType: sourceType,
         sourceFindingId: sourceFindingId,
         assignee: assignee,
         dueAt: dueAt,
         completedAt: completedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Task]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Task copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? title,
    String? status,
    String? priority,
    Object? sourceType = _Undefined,
    Object? sourceFindingId = _Undefined,
    Object? assignee = _Undefined,
    Object? dueAt = _Undefined,
    Object? completedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      sourceType: sourceType is String? ? sourceType : this.sourceType,
      sourceFindingId: sourceFindingId is int?
          ? sourceFindingId
          : this.sourceFindingId,
      assignee: assignee is String? ? assignee : this.assignee,
      dueAt: dueAt is DateTime? ? dueAt : this.dueAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
