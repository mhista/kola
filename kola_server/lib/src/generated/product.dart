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

abstract class Product
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Product._({
    this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.archetype,
    this.sku,
    this.category,
    this.priceMinor,
    required this.priceCurrency,
    this.priceUnit,
    this.costMinor,
    this.stock,
    required this.lowStockThreshold,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product({
    int? id,
    required int workspaceId,
    required String name,
    String? description,
    required String archetype,
    String? sku,
    String? category,
    int? priceMinor,
    required String priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    required int lowStockThreshold,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ProductImpl;

  factory Product.fromJson(Map<String, dynamic> jsonSerialization) {
    return Product(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      archetype: jsonSerialization['archetype'] as String,
      sku: jsonSerialization['sku'] as String?,
      category: jsonSerialization['category'] as String?,
      priceMinor: jsonSerialization['priceMinor'] as int?,
      priceCurrency: jsonSerialization['priceCurrency'] as String,
      priceUnit: jsonSerialization['priceUnit'] as String?,
      costMinor: jsonSerialization['costMinor'] as int?,
      stock: jsonSerialization['stock'] as int?,
      lowStockThreshold: jsonSerialization['lowStockThreshold'] as int,
      status: jsonSerialization['status'] as String,
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

  String name;

  String? description;

  String archetype;

  String? sku;

  String? category;

  int? priceMinor;

  String priceCurrency;

  String? priceUnit;

  int? costMinor;

  int? stock;

  int lowStockThreshold;

  String status;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Product copyWith({
    int? id,
    int? workspaceId,
    String? name,
    String? description,
    String? archetype,
    String? sku,
    String? category,
    int? priceMinor,
    String? priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    int? lowStockThreshold,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Product',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      if (description != null) 'description': description,
      'archetype': archetype,
      if (sku != null) 'sku': sku,
      if (category != null) 'category': category,
      if (priceMinor != null) 'priceMinor': priceMinor,
      'priceCurrency': priceCurrency,
      if (priceUnit != null) 'priceUnit': priceUnit,
      if (costMinor != null) 'costMinor': costMinor,
      if (stock != null) 'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'status': status,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Product',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'name': name,
      if (description != null) 'description': description,
      'archetype': archetype,
      if (sku != null) 'sku': sku,
      if (category != null) 'category': category,
      if (priceMinor != null) 'priceMinor': priceMinor,
      'priceCurrency': priceCurrency,
      if (priceUnit != null) 'priceUnit': priceUnit,
      if (costMinor != null) 'costMinor': costMinor,
      if (stock != null) 'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'status': status,
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

class _ProductImpl extends Product {
  _ProductImpl({
    int? id,
    required int workspaceId,
    required String name,
    String? description,
    required String archetype,
    String? sku,
    String? category,
    int? priceMinor,
    required String priceCurrency,
    String? priceUnit,
    int? costMinor,
    int? stock,
    required int lowStockThreshold,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         name: name,
         description: description,
         archetype: archetype,
         sku: sku,
         category: category,
         priceMinor: priceMinor,
         priceCurrency: priceCurrency,
         priceUnit: priceUnit,
         costMinor: costMinor,
         stock: stock,
         lowStockThreshold: lowStockThreshold,
         status: status,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Product]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Product copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? name,
    Object? description = _Undefined,
    String? archetype,
    Object? sku = _Undefined,
    Object? category = _Undefined,
    Object? priceMinor = _Undefined,
    String? priceCurrency,
    Object? priceUnit = _Undefined,
    Object? costMinor = _Undefined,
    Object? stock = _Undefined,
    int? lowStockThreshold,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      archetype: archetype ?? this.archetype,
      sku: sku is String? ? sku : this.sku,
      category: category is String? ? category : this.category,
      priceMinor: priceMinor is int? ? priceMinor : this.priceMinor,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      priceUnit: priceUnit is String? ? priceUnit : this.priceUnit,
      costMinor: costMinor is int? ? costMinor : this.costMinor,
      stock: stock is int? ? stock : this.stock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
