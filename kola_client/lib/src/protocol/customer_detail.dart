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
import 'customer_identity_signal.dart' as _i3;
import 'conversation.dart' as _i4;
import 'payment_transaction.dart' as _i5;
import 'sale.dart' as _i6;
import 'package:kola_client/src/protocol/protocol.dart' as _i7;

abstract class CustomerDetail implements _i1.SerializableModel {
  CustomerDetail._({
    required this.customer,
    required this.signals,
    required this.conversations,
    required this.payments,
    required this.sales,
  });

  factory CustomerDetail({
    required _i2.Customer customer,
    required List<_i3.CustomerIdentitySignal> signals,
    required List<_i4.Conversation> conversations,
    required List<_i5.PaymentTransaction> payments,
    required List<_i6.Sale> sales,
  }) = _CustomerDetailImpl;

  factory CustomerDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return CustomerDetail(
      customer: _i7.Protocol().deserialize<_i2.Customer>(
        jsonSerialization['customer'],
      ),
      signals: _i7.Protocol().deserialize<List<_i3.CustomerIdentitySignal>>(
        jsonSerialization['signals'],
      ),
      conversations: _i7.Protocol().deserialize<List<_i4.Conversation>>(
        jsonSerialization['conversations'],
      ),
      payments: _i7.Protocol().deserialize<List<_i5.PaymentTransaction>>(
        jsonSerialization['payments'],
      ),
      sales: _i7.Protocol().deserialize<List<_i6.Sale>>(
        jsonSerialization['sales'],
      ),
    );
  }

  _i2.Customer customer;

  List<_i3.CustomerIdentitySignal> signals;

  List<_i4.Conversation> conversations;

  List<_i5.PaymentTransaction> payments;

  List<_i6.Sale> sales;

  /// Returns a shallow copy of this [CustomerDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CustomerDetail copyWith({
    _i2.Customer? customer,
    List<_i3.CustomerIdentitySignal>? signals,
    List<_i4.Conversation>? conversations,
    List<_i5.PaymentTransaction>? payments,
    List<_i6.Sale>? sales,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomerDetail',
      'customer': customer.toJson(),
      'signals': signals.toJson(valueToJson: (v) => v.toJson()),
      'conversations': conversations.toJson(valueToJson: (v) => v.toJson()),
      'payments': payments.toJson(valueToJson: (v) => v.toJson()),
      'sales': sales.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _CustomerDetailImpl extends CustomerDetail {
  _CustomerDetailImpl({
    required _i2.Customer customer,
    required List<_i3.CustomerIdentitySignal> signals,
    required List<_i4.Conversation> conversations,
    required List<_i5.PaymentTransaction> payments,
    required List<_i6.Sale> sales,
  }) : super._(
         customer: customer,
         signals: signals,
         conversations: conversations,
         payments: payments,
         sales: sales,
       );

  /// Returns a shallow copy of this [CustomerDetail]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CustomerDetail copyWith({
    _i2.Customer? customer,
    List<_i3.CustomerIdentitySignal>? signals,
    List<_i4.Conversation>? conversations,
    List<_i5.PaymentTransaction>? payments,
    List<_i6.Sale>? sales,
  }) {
    return CustomerDetail(
      customer: customer ?? this.customer.copyWith(),
      signals: signals ?? this.signals.map((e0) => e0.copyWith()).toList(),
      conversations:
          conversations ??
          this.conversations.map((e0) => e0.copyWith()).toList(),
      payments: payments ?? this.payments.map((e0) => e0.copyWith()).toList(),
      sales: sales ?? this.sales.map((e0) => e0.copyWith()).toList(),
    );
  }
}
