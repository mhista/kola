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

abstract class IntelligenceProduct
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  IntelligenceProduct._({
    this.productId,
    required this.name,
    required this.unitsSold,
    required this.revenueMinor,
    this.marginMinor,
    this.marginPct,
  });

  factory IntelligenceProduct({
    int? productId,
    required String name,
    required int unitsSold,
    required int revenueMinor,
    int? marginMinor,
    double? marginPct,
  }) = _IntelligenceProductImpl;

  factory IntelligenceProduct.fromJson(Map<String, dynamic> jsonSerialization) {
    return IntelligenceProduct(
      productId: jsonSerialization['productId'] as int?,
      name: jsonSerialization['name'] as String,
      unitsSold: jsonSerialization['unitsSold'] as int,
      revenueMinor: jsonSerialization['revenueMinor'] as int,
      marginMinor: jsonSerialization['marginMinor'] as int?,
      marginPct: (jsonSerialization['marginPct'] as num?)?.toDouble(),
    );
  }

  int? productId;

  String name;

  int unitsSold;

  int revenueMinor;

  int? marginMinor;

  double? marginPct;

  /// Returns a shallow copy of this [IntelligenceProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  IntelligenceProduct copyWith({
    int? productId,
    String? name,
    int? unitsSold,
    int? revenueMinor,
    int? marginMinor,
    double? marginPct,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'IntelligenceProduct',
      if (productId != null) 'productId': productId,
      'name': name,
      'unitsSold': unitsSold,
      'revenueMinor': revenueMinor,
      if (marginMinor != null) 'marginMinor': marginMinor,
      if (marginPct != null) 'marginPct': marginPct,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'IntelligenceProduct',
      if (productId != null) 'productId': productId,
      'name': name,
      'unitsSold': unitsSold,
      'revenueMinor': revenueMinor,
      if (marginMinor != null) 'marginMinor': marginMinor,
      if (marginPct != null) 'marginPct': marginPct,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _IntelligenceProductImpl extends IntelligenceProduct {
  _IntelligenceProductImpl({
    int? productId,
    required String name,
    required int unitsSold,
    required int revenueMinor,
    int? marginMinor,
    double? marginPct,
  }) : super._(
         productId: productId,
         name: name,
         unitsSold: unitsSold,
         revenueMinor: revenueMinor,
         marginMinor: marginMinor,
         marginPct: marginPct,
       );

  /// Returns a shallow copy of this [IntelligenceProduct]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  IntelligenceProduct copyWith({
    Object? productId = _Undefined,
    String? name,
    int? unitsSold,
    int? revenueMinor,
    Object? marginMinor = _Undefined,
    Object? marginPct = _Undefined,
  }) {
    return IntelligenceProduct(
      productId: productId is int? ? productId : this.productId,
      name: name ?? this.name,
      unitsSold: unitsSold ?? this.unitsSold,
      revenueMinor: revenueMinor ?? this.revenueMinor,
      marginMinor: marginMinor is int? ? marginMinor : this.marginMinor,
      marginPct: marginPct is double? ? marginPct : this.marginPct,
    );
  }
}
