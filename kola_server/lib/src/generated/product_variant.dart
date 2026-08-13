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

abstract class ProductVariant
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ProductVariant._({
    this.id,
    required this.productId,
    required this.label,
    this.sku,
    this.priceMinor,
    this.stock,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariant({
    int? id,
    required int productId,
    required String label,
    String? sku,
    int? priceMinor,
    int? stock,
    required int position,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductVariantImpl;

  factory ProductVariant.fromJson(Map<String, dynamic> jsonSerialization) {
    return ProductVariant(
      id: jsonSerialization['id'] as int?,
      productId: jsonSerialization['productId'] as int,
      label: jsonSerialization['label'] as String,
      sku: jsonSerialization['sku'] as String?,
      priceMinor: jsonSerialization['priceMinor'] as int?,
      stock: jsonSerialization['stock'] as int?,
      position: jsonSerialization['position'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  int? id;

  int productId;

  String label;

  String? sku;

  int? priceMinor;

  int? stock;

  int position;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [ProductVariant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductVariant copyWith({
    int? id,
    int? productId,
    String? label,
    String? sku,
    int? priceMinor,
    int? stock,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductVariant',
      if (id != null) 'id': id,
      'productId': productId,
      'label': label,
      if (sku != null) 'sku': sku,
      if (priceMinor != null) 'priceMinor': priceMinor,
      if (stock != null) 'stock': stock,
      'position': position,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ProductVariant',
      if (id != null) 'id': id,
      'productId': productId,
      'label': label,
      if (sku != null) 'sku': sku,
      if (priceMinor != null) 'priceMinor': priceMinor,
      if (stock != null) 'stock': stock,
      'position': position,
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

class _ProductVariantImpl extends ProductVariant {
  _ProductVariantImpl({
    int? id,
    required int productId,
    required String label,
    String? sku,
    int? priceMinor,
    int? stock,
    required int position,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         productId: productId,
         label: label,
         sku: sku,
         priceMinor: priceMinor,
         stock: stock,
         position: position,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [ProductVariant]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductVariant copyWith({
    Object? id = _Undefined,
    int? productId,
    String? label,
    Object? sku = _Undefined,
    Object? priceMinor = _Undefined,
    Object? stock = _Undefined,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id is int? ? id : this.id,
      productId: productId ?? this.productId,
      label: label ?? this.label,
      sku: sku is String? ? sku : this.sku,
      priceMinor: priceMinor is int? ? priceMinor : this.priceMinor,
      stock: stock is int? ? stock : this.stock,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
