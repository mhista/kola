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

abstract class SaleLine
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SaleLine._({
    this.id,
    required this.saleId,
    this.productId,
    required this.name,
    required this.unitPriceMinor,
    required this.quantity,
    required this.lineTotalMinor,
    required this.createdAt,
  });

  factory SaleLine({
    int? id,
    required int saleId,
    int? productId,
    required String name,
    required int unitPriceMinor,
    required int quantity,
    required int lineTotalMinor,
    required DateTime createdAt,
  }) = _SaleLineImpl;

  factory SaleLine.fromJson(Map<String, dynamic> jsonSerialization) {
    return SaleLine(
      id: jsonSerialization['id'] as int?,
      saleId: jsonSerialization['saleId'] as int,
      productId: jsonSerialization['productId'] as int?,
      name: jsonSerialization['name'] as String,
      unitPriceMinor: jsonSerialization['unitPriceMinor'] as int,
      quantity: jsonSerialization['quantity'] as int,
      lineTotalMinor: jsonSerialization['lineTotalMinor'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int saleId;

  int? productId;

  String name;

  int unitPriceMinor;

  int quantity;

  int lineTotalMinor;

  DateTime createdAt;

  /// Returns a shallow copy of this [SaleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SaleLine copyWith({
    int? id,
    int? saleId,
    int? productId,
    String? name,
    int? unitPriceMinor,
    int? quantity,
    int? lineTotalMinor,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SaleLine',
      if (id != null) 'id': id,
      'saleId': saleId,
      if (productId != null) 'productId': productId,
      'name': name,
      'unitPriceMinor': unitPriceMinor,
      'quantity': quantity,
      'lineTotalMinor': lineTotalMinor,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SaleLine',
      if (id != null) 'id': id,
      'saleId': saleId,
      if (productId != null) 'productId': productId,
      'name': name,
      'unitPriceMinor': unitPriceMinor,
      'quantity': quantity,
      'lineTotalMinor': lineTotalMinor,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SaleLineImpl extends SaleLine {
  _SaleLineImpl({
    int? id,
    required int saleId,
    int? productId,
    required String name,
    required int unitPriceMinor,
    required int quantity,
    required int lineTotalMinor,
    required DateTime createdAt,
  }) : super._(
         id: id,
         saleId: saleId,
         productId: productId,
         name: name,
         unitPriceMinor: unitPriceMinor,
         quantity: quantity,
         lineTotalMinor: lineTotalMinor,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [SaleLine]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SaleLine copyWith({
    Object? id = _Undefined,
    int? saleId,
    Object? productId = _Undefined,
    String? name,
    int? unitPriceMinor,
    int? quantity,
    int? lineTotalMinor,
    DateTime? createdAt,
  }) {
    return SaleLine(
      id: id is int? ? id : this.id,
      saleId: saleId ?? this.saleId,
      productId: productId is int? ? productId : this.productId,
      name: name ?? this.name,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      quantity: quantity ?? this.quantity,
      lineTotalMinor: lineTotalMinor ?? this.lineTotalMinor,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
