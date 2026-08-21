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

abstract class SaleLineInput
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SaleLineInput._({
    this.productId,
    required this.name,
    required this.unitPriceMinor,
    required this.quantity,
  });

  factory SaleLineInput({
    int? productId,
    required String name,
    required int unitPriceMinor,
    required int quantity,
  }) = _SaleLineInputImpl;

  factory SaleLineInput.fromJson(Map<String, dynamic> jsonSerialization) {
    return SaleLineInput(
      productId: jsonSerialization['productId'] as int?,
      name: jsonSerialization['name'] as String,
      unitPriceMinor: jsonSerialization['unitPriceMinor'] as int,
      quantity: jsonSerialization['quantity'] as int,
    );
  }

  int? productId;

  String name;

  int unitPriceMinor;

  int quantity;

  /// Returns a shallow copy of this [SaleLineInput]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SaleLineInput copyWith({
    int? productId,
    String? name,
    int? unitPriceMinor,
    int? quantity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SaleLineInput',
      if (productId != null) 'productId': productId,
      'name': name,
      'unitPriceMinor': unitPriceMinor,
      'quantity': quantity,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SaleLineInput',
      if (productId != null) 'productId': productId,
      'name': name,
      'unitPriceMinor': unitPriceMinor,
      'quantity': quantity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SaleLineInputImpl extends SaleLineInput {
  _SaleLineInputImpl({
    int? productId,
    required String name,
    required int unitPriceMinor,
    required int quantity,
  }) : super._(
         productId: productId,
         name: name,
         unitPriceMinor: unitPriceMinor,
         quantity: quantity,
       );

  /// Returns a shallow copy of this [SaleLineInput]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SaleLineInput copyWith({
    Object? productId = _Undefined,
    String? name,
    int? unitPriceMinor,
    int? quantity,
  }) {
    return SaleLineInput(
      productId: productId is int? ? productId : this.productId,
      name: name ?? this.name,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      quantity: quantity ?? this.quantity,
    );
  }
}
