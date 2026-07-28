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

abstract class SupportTicket implements _i1.SerializableModel {
  SupportTicket._({
    this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.slaDeadline,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String subject,
    required String description,
    required String priority,
    required String status,
    required DateTime slaDeadline,
    DateTime? resolvedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SupportTicketImpl;

  factory SupportTicket.fromJson(Map<String, dynamic> jsonSerialization) {
    return SupportTicket(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int,
      subject: jsonSerialization['subject'] as String,
      description: jsonSerialization['description'] as String,
      priority: jsonSerialization['priority'] as String,
      status: jsonSerialization['status'] as String,
      slaDeadline: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['slaDeadline'],
      ),
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
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

  int conversationId;

  String subject;

  String description;

  String priority;

  String status;

  DateTime slaDeadline;

  DateTime? resolvedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SupportTicket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTicket copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? subject,
    String? description,
    String? priority,
    String? status,
    DateTime? slaDeadline,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTicket',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'conversationId': conversationId,
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': status,
      'slaDeadline': slaDeadline.toJson(),
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
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

class _SupportTicketImpl extends SupportTicket {
  _SupportTicketImpl({
    int? id,
    required int workspaceId,
    required int conversationId,
    required String subject,
    required String description,
    required String priority,
    required String status,
    required DateTime slaDeadline,
    DateTime? resolvedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         subject: subject,
         description: description,
         priority: priority,
         status: status,
         slaDeadline: slaDeadline,
         resolvedAt: resolvedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SupportTicket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTicket copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? conversationId,
    String? subject,
    String? description,
    String? priority,
    String? status,
    DateTime? slaDeadline,
    Object? resolvedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId ?? this.conversationId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      slaDeadline: slaDeadline ?? this.slaDeadline,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
