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

abstract class TillDisplayItem implements _i1.SerializableModel {
  TillDisplayItem._({
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
  });

  factory TillDisplayItem({
    required String name,
    required int quantity,
    required int unitPriceMinor,
    required int lineTotalMinor,
  }) = _TillDisplayItemImpl;

  factory TillDisplayItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return TillDisplayItem(
      name: jsonSerialization['name'] as String,
      quantity: jsonSerialization['quantity'] as int,
      unitPriceMinor: jsonSerialization['unitPriceMinor'] as int,
      lineTotalMinor: jsonSerialization['lineTotalMinor'] as int,
    );
  }

  String name;

  int quantity;

  int unitPriceMinor;

  int lineTotalMinor;

  /// Returns a shallow copy of this [TillDisplayItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TillDisplayItem copyWith({
    String? name,
    int? quantity,
    int? unitPriceMinor,
    int? lineTotalMinor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TillDisplayItem',
      'name': name,
      'quantity': quantity,
      'unitPriceMinor': unitPriceMinor,
      'lineTotalMinor': lineTotalMinor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TillDisplayItemImpl extends TillDisplayItem {
  _TillDisplayItemImpl({
    required String name,
    required int quantity,
    required int unitPriceMinor,
    required int lineTotalMinor,
  }) : super._(
         name: name,
         quantity: quantity,
         unitPriceMinor: unitPriceMinor,
         lineTotalMinor: lineTotalMinor,
       );

  /// Returns a shallow copy of this [TillDisplayItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TillDisplayItem copyWith({
    String? name,
    int? quantity,
    int? unitPriceMinor,
    int? lineTotalMinor,
  }) {
    return TillDisplayItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPriceMinor: unitPriceMinor ?? this.unitPriceMinor,
      lineTotalMinor: lineTotalMinor ?? this.lineTotalMinor,
    );
  }
}
