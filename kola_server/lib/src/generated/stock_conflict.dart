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

abstract class StockConflict
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  StockConflict._({
    this.id,
    required this.workspaceId,
    required this.productId,
    this.saleId,
    required this.oversoldBy,
    required this.detectedAt,
    required this.status,
    this.resolvedAt,
    this.resolvedByEmail,
  });

  factory StockConflict({
    int? id,
    required int workspaceId,
    required int productId,
    int? saleId,
    required int oversoldBy,
    required DateTime detectedAt,
    required String status,
    DateTime? resolvedAt,
    String? resolvedByEmail,
  }) = _StockConflictImpl;

  factory StockConflict.fromJson(Map<String, dynamic> jsonSerialization) {
    return StockConflict(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      productId: jsonSerialization['productId'] as int,
      saleId: jsonSerialization['saleId'] as int?,
      oversoldBy: jsonSerialization['oversoldBy'] as int,
      detectedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['detectedAt'],
      ),
      status: jsonSerialization['status'] as String,
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
      resolvedByEmail: jsonSerialization['resolvedByEmail'] as String?,
    );
  }

  int? id;

  int workspaceId;

  int productId;

  int? saleId;

  int oversoldBy;

  DateTime detectedAt;

  String status;

  DateTime? resolvedAt;

  String? resolvedByEmail;

  /// Returns a shallow copy of this [StockConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  StockConflict copyWith({
    int? id,
    int? workspaceId,
    int? productId,
    int? saleId,
    int? oversoldBy,
    DateTime? detectedAt,
    String? status,
    DateTime? resolvedAt,
    String? resolvedByEmail,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'StockConflict',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'productId': productId,
      if (saleId != null) 'saleId': saleId,
      'oversoldBy': oversoldBy,
      'detectedAt': detectedAt.toJson(),
      'status': status,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolvedByEmail != null) 'resolvedByEmail': resolvedByEmail,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'StockConflict',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'productId': productId,
      if (saleId != null) 'saleId': saleId,
      'oversoldBy': oversoldBy,
      'detectedAt': detectedAt.toJson(),
      'status': status,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
      if (resolvedByEmail != null) 'resolvedByEmail': resolvedByEmail,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StockConflictImpl extends StockConflict {
  _StockConflictImpl({
    int? id,
    required int workspaceId,
    required int productId,
    int? saleId,
    required int oversoldBy,
    required DateTime detectedAt,
    required String status,
    DateTime? resolvedAt,
    String? resolvedByEmail,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         productId: productId,
         saleId: saleId,
         oversoldBy: oversoldBy,
         detectedAt: detectedAt,
         status: status,
         resolvedAt: resolvedAt,
         resolvedByEmail: resolvedByEmail,
       );

  /// Returns a shallow copy of this [StockConflict]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  StockConflict copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? productId,
    Object? saleId = _Undefined,
    int? oversoldBy,
    DateTime? detectedAt,
    String? status,
    Object? resolvedAt = _Undefined,
    Object? resolvedByEmail = _Undefined,
  }) {
    return StockConflict(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      productId: productId ?? this.productId,
      saleId: saleId is int? ? saleId : this.saleId,
      oversoldBy: oversoldBy ?? this.oversoldBy,
      detectedAt: detectedAt ?? this.detectedAt,
      status: status ?? this.status,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      resolvedByEmail: resolvedByEmail is String?
          ? resolvedByEmail
          : this.resolvedByEmail,
    );
  }
}
