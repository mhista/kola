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

abstract class PublicCatalogItem implements _i1.SerializableModel {
  PublicCatalogItem._({
    required this.productId,
    required this.name,
    this.description,
    this.category,
    this.priceMinor,
    required this.priceCurrency,
    this.priceUnit,
    required this.stockStatus,
    this.imageUrl,
  });

  factory PublicCatalogItem({
    required int productId,
    required String name,
    String? description,
    String? category,
    int? priceMinor,
    required String priceCurrency,
    String? priceUnit,
    required String stockStatus,
    String? imageUrl,
  }) = _PublicCatalogItemImpl;

  factory PublicCatalogItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return PublicCatalogItem(
      productId: jsonSerialization['productId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      category: jsonSerialization['category'] as String?,
      priceMinor: jsonSerialization['priceMinor'] as int?,
      priceCurrency: jsonSerialization['priceCurrency'] as String,
      priceUnit: jsonSerialization['priceUnit'] as String?,
      stockStatus: jsonSerialization['stockStatus'] as String,
      imageUrl: jsonSerialization['imageUrl'] as String?,
    );
  }

  int productId;

  String name;

  String? description;

  String? category;

  int? priceMinor;

  String priceCurrency;

  String? priceUnit;

  String stockStatus;

  String? imageUrl;

  /// Returns a shallow copy of this [PublicCatalogItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PublicCatalogItem copyWith({
    int? productId,
    String? name,
    String? description,
    String? category,
    int? priceMinor,
    String? priceCurrency,
    String? priceUnit,
    String? stockStatus,
    String? imageUrl,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PublicCatalogItem',
      'productId': productId,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (priceMinor != null) 'priceMinor': priceMinor,
      'priceCurrency': priceCurrency,
      if (priceUnit != null) 'priceUnit': priceUnit,
      'stockStatus': stockStatus,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PublicCatalogItemImpl extends PublicCatalogItem {
  _PublicCatalogItemImpl({
    required int productId,
    required String name,
    String? description,
    String? category,
    int? priceMinor,
    required String priceCurrency,
    String? priceUnit,
    required String stockStatus,
    String? imageUrl,
  }) : super._(
         productId: productId,
         name: name,
         description: description,
         category: category,
         priceMinor: priceMinor,
         priceCurrency: priceCurrency,
         priceUnit: priceUnit,
         stockStatus: stockStatus,
         imageUrl: imageUrl,
       );

  /// Returns a shallow copy of this [PublicCatalogItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PublicCatalogItem copyWith({
    int? productId,
    String? name,
    Object? description = _Undefined,
    Object? category = _Undefined,
    Object? priceMinor = _Undefined,
    String? priceCurrency,
    Object? priceUnit = _Undefined,
    String? stockStatus,
    Object? imageUrl = _Undefined,
  }) {
    return PublicCatalogItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      category: category is String? ? category : this.category,
      priceMinor: priceMinor is int? ? priceMinor : this.priceMinor,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      priceUnit: priceUnit is String? ? priceUnit : this.priceUnit,
      stockStatus: stockStatus ?? this.stockStatus,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
    );
  }
}
