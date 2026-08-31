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
import 'customer.dart' as _i2;
import 'package:kola_client/src/protocol/protocol.dart' as _i3;

abstract class CustomerSummary implements _i1.SerializableModel {
  CustomerSummary._({
    required this.customer,
    required this.ltvMinor,
    required this.orderCount,
    required this.currency,
    this.lastActivityAt,
  });

  factory CustomerSummary({
    required _i2.Customer customer,
    required int ltvMinor,
    required int orderCount,
    required String currency,
    DateTime? lastActivityAt,
  }) = _CustomerSummaryImpl;

  factory CustomerSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return CustomerSummary(
      customer: _i3.Protocol().deserialize<_i2.Customer>(
        jsonSerialization['customer'],
      ),
      ltvMinor: jsonSerialization['ltvMinor'] as int,
      orderCount: jsonSerialization['orderCount'] as int,
      currency: jsonSerialization['currency'] as String,
      lastActivityAt: jsonSerialization['lastActivityAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActivityAt'],
            ),
    );
  }

  _i2.Customer customer;

  int ltvMinor;

  int orderCount;

  String currency;

  DateTime? lastActivityAt;

  /// Returns a shallow copy of this [CustomerSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CustomerSummary copyWith({
    _i2.Customer? customer,
    int? ltvMinor,
    int? orderCount,
    String? currency,
    DateTime? lastActivityAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomerSummary',
      'customer': customer.toJson(),
      'ltvMinor': ltvMinor,
      'orderCount': orderCount,
      'currency': currency,
      if (lastActivityAt != null) 'lastActivityAt': lastActivityAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CustomerSummaryImpl extends CustomerSummary {
  _CustomerSummaryImpl({
    required _i2.Customer customer,
    required int ltvMinor,
    required int orderCount,
    required String currency,
    DateTime? lastActivityAt,
  }) : super._(
         customer: customer,
         ltvMinor: ltvMinor,
         orderCount: orderCount,
         currency: currency,
         lastActivityAt: lastActivityAt,
       );

  /// Returns a shallow copy of this [CustomerSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CustomerSummary copyWith({
    _i2.Customer? customer,
    int? ltvMinor,
    int? orderCount,
    String? currency,
    Object? lastActivityAt = _Undefined,
  }) {
    return CustomerSummary(
      customer: customer ?? this.customer.copyWith(),
      ltvMinor: ltvMinor ?? this.ltvMinor,
      orderCount: orderCount ?? this.orderCount,
      currency: currency ?? this.currency,
      lastActivityAt: lastActivityAt is DateTime?
          ? lastActivityAt
          : this.lastActivityAt,
    );
  }
}
