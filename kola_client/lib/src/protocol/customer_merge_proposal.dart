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

abstract class CustomerMergeProposal implements _i1.SerializableModel {
  CustomerMergeProposal._({
    this.id,
    required this.workspaceId,
    required this.customerAId,
    required this.customerBId,
    required this.matchedOn,
    required this.evidenceJson,
    required this.status,
    this.resolvedByEmail,
    this.resolvedAt,
    required this.createdAt,
  });

  factory CustomerMergeProposal({
    int? id,
    required int workspaceId,
    required int customerAId,
    required int customerBId,
    required String matchedOn,
    required String evidenceJson,
    required String status,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    required DateTime createdAt,
  }) = _CustomerMergeProposalImpl;

  factory CustomerMergeProposal.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CustomerMergeProposal(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      customerAId: jsonSerialization['customerAId'] as int,
      customerBId: jsonSerialization['customerBId'] as int,
      matchedOn: jsonSerialization['matchedOn'] as String,
      evidenceJson: jsonSerialization['evidenceJson'] as String,
      status: jsonSerialization['status'] as String,
      resolvedByEmail: jsonSerialization['resolvedByEmail'] as String?,
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  int customerAId;

  int customerBId;

  String matchedOn;

  String evidenceJson;

  String status;

  String? resolvedByEmail;

  DateTime? resolvedAt;

  DateTime createdAt;

  /// Returns a shallow copy of this [CustomerMergeProposal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CustomerMergeProposal copyWith({
    int? id,
    int? workspaceId,
    int? customerAId,
    int? customerBId,
    String? matchedOn,
    String? evidenceJson,
    String? status,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomerMergeProposal',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'customerAId': customerAId,
      'customerBId': customerBId,
      'matchedOn': matchedOn,
      'evidenceJson': evidenceJson,
      'status': status,
      if (resolvedByEmail != null) 'resolvedByEmail': resolvedByEmail,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CustomerMergeProposalImpl extends CustomerMergeProposal {
  _CustomerMergeProposalImpl({
    int? id,
    required int workspaceId,
    required int customerAId,
    required int customerBId,
    required String matchedOn,
    required String evidenceJson,
    required String status,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    required DateTime createdAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         customerAId: customerAId,
         customerBId: customerBId,
         matchedOn: matchedOn,
         evidenceJson: evidenceJson,
         status: status,
         resolvedByEmail: resolvedByEmail,
         resolvedAt: resolvedAt,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [CustomerMergeProposal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CustomerMergeProposal copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? customerAId,
    int? customerBId,
    String? matchedOn,
    String? evidenceJson,
    String? status,
    Object? resolvedByEmail = _Undefined,
    Object? resolvedAt = _Undefined,
    DateTime? createdAt,
  }) {
    return CustomerMergeProposal(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      customerAId: customerAId ?? this.customerAId,
      customerBId: customerBId ?? this.customerBId,
      matchedOn: matchedOn ?? this.matchedOn,
      evidenceJson: evidenceJson ?? this.evidenceJson,
      status: status ?? this.status,
      resolvedByEmail: resolvedByEmail is String?
          ? resolvedByEmail
          : this.resolvedByEmail,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
