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

abstract class UsageRecord
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  UsageRecord._({
    this.id,
    required this.workspaceId,
    required this.usageClass,
    required this.periodDate,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UsageRecord({
    int? id,
    required int workspaceId,
    required String usageClass,
    required DateTime periodDate,
    required double quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UsageRecordImpl;

  factory UsageRecord.fromJson(Map<String, dynamic> jsonSerialization) {
    return UsageRecord(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      usageClass: jsonSerialization['usageClass'] as String,
      periodDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['periodDate'],
      ),
      quantity: (jsonSerialization['quantity'] as num).toDouble(),
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

  String usageClass;

  DateTime periodDate;

  double quantity;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [UsageRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UsageRecord copyWith({
    int? id,
    int? workspaceId,
    String? usageClass,
    DateTime? periodDate,
    double? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UsageRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'usageClass': usageClass,
      'periodDate': periodDate.toJson(),
      'quantity': quantity,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UsageRecord',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'usageClass': usageClass,
      'periodDate': periodDate.toJson(),
      'quantity': quantity,
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

class _UsageRecordImpl extends UsageRecord {
  _UsageRecordImpl({
    int? id,
    required int workspaceId,
    required String usageClass,
    required DateTime periodDate,
    required double quantity,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         usageClass: usageClass,
         periodDate: periodDate,
         quantity: quantity,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [UsageRecord]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UsageRecord copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? usageClass,
    DateTime? periodDate,
    double? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsageRecord(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      usageClass: usageClass ?? this.usageClass,
      periodDate: periodDate ?? this.periodDate,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
