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

abstract class Sale
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Sale._({
    this.id,
    required this.workspaceId,
    this.customerId,
    required this.reference,
    this.clientReference,
    required this.subtotalMinor,
    required this.taxRateBps,
    required this.taxMinor,
    required this.totalMinor,
    required this.currency,
    required this.paymentMethod,
    this.cashReceivedMinor,
    this.changeMinor,
    required this.status,
    required this.soldAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sale({
    int? id,
    required int workspaceId,
    int? customerId,
    required String reference,
    String? clientReference,
    required int subtotalMinor,
    required int taxRateBps,
    required int taxMinor,
    required int totalMinor,
    required String currency,
    required String paymentMethod,
    int? cashReceivedMinor,
    int? changeMinor,
    required String status,
    required DateTime soldAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SaleImpl;

  factory Sale.fromJson(Map<String, dynamic> jsonSerialization) {
    return Sale(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      customerId: jsonSerialization['customerId'] as int?,
      reference: jsonSerialization['reference'] as String,
      clientReference: jsonSerialization['clientReference'] as String?,
      subtotalMinor: jsonSerialization['subtotalMinor'] as int,
      taxRateBps: jsonSerialization['taxRateBps'] as int,
      taxMinor: jsonSerialization['taxMinor'] as int,
      totalMinor: jsonSerialization['totalMinor'] as int,
      currency: jsonSerialization['currency'] as String,
      paymentMethod: jsonSerialization['paymentMethod'] as String,
      cashReceivedMinor: jsonSerialization['cashReceivedMinor'] as int?,
      changeMinor: jsonSerialization['changeMinor'] as int?,
      status: jsonSerialization['status'] as String,
      soldAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['soldAt']),
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

  int? customerId;

  String reference;

  String? clientReference;

  int subtotalMinor;

  int taxRateBps;

  int taxMinor;

  int totalMinor;

  String currency;

  String paymentMethod;

  int? cashReceivedMinor;

  int? changeMinor;

  String status;

  DateTime soldAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Sale]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Sale copyWith({
    int? id,
    int? workspaceId,
    int? customerId,
    String? reference,
    String? clientReference,
    int? subtotalMinor,
    int? taxRateBps,
    int? taxMinor,
    int? totalMinor,
    String? currency,
    String? paymentMethod,
    int? cashReceivedMinor,
    int? changeMinor,
    String? status,
    DateTime? soldAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Sale',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (customerId != null) 'customerId': customerId,
      'reference': reference,
      if (clientReference != null) 'clientReference': clientReference,
      'subtotalMinor': subtotalMinor,
      'taxRateBps': taxRateBps,
      'taxMinor': taxMinor,
      'totalMinor': totalMinor,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (cashReceivedMinor != null) 'cashReceivedMinor': cashReceivedMinor,
      if (changeMinor != null) 'changeMinor': changeMinor,
      'status': status,
      'soldAt': soldAt.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Sale',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (customerId != null) 'customerId': customerId,
      'reference': reference,
      if (clientReference != null) 'clientReference': clientReference,
      'subtotalMinor': subtotalMinor,
      'taxRateBps': taxRateBps,
      'taxMinor': taxMinor,
      'totalMinor': totalMinor,
      'currency': currency,
      'paymentMethod': paymentMethod,
      if (cashReceivedMinor != null) 'cashReceivedMinor': cashReceivedMinor,
      if (changeMinor != null) 'changeMinor': changeMinor,
      'status': status,
      'soldAt': soldAt.toJson(),
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

class _SaleImpl extends Sale {
  _SaleImpl({
    int? id,
    required int workspaceId,
    int? customerId,
    required String reference,
    String? clientReference,
    required int subtotalMinor,
    required int taxRateBps,
    required int taxMinor,
    required int totalMinor,
    required String currency,
    required String paymentMethod,
    int? cashReceivedMinor,
    int? changeMinor,
    required String status,
    required DateTime soldAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         customerId: customerId,
         reference: reference,
         clientReference: clientReference,
         subtotalMinor: subtotalMinor,
         taxRateBps: taxRateBps,
         taxMinor: taxMinor,
         totalMinor: totalMinor,
         currency: currency,
         paymentMethod: paymentMethod,
         cashReceivedMinor: cashReceivedMinor,
         changeMinor: changeMinor,
         status: status,
         soldAt: soldAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Sale]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Sale copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    Object? customerId = _Undefined,
    String? reference,
    Object? clientReference = _Undefined,
    int? subtotalMinor,
    int? taxRateBps,
    int? taxMinor,
    int? totalMinor,
    String? currency,
    String? paymentMethod,
    Object? cashReceivedMinor = _Undefined,
    Object? changeMinor = _Undefined,
    String? status,
    DateTime? soldAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sale(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      customerId: customerId is int? ? customerId : this.customerId,
      reference: reference ?? this.reference,
      clientReference: clientReference is String?
          ? clientReference
          : this.clientReference,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      taxMinor: taxMinor ?? this.taxMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashReceivedMinor: cashReceivedMinor is int?
          ? cashReceivedMinor
          : this.cashReceivedMinor,
      changeMinor: changeMinor is int? ? changeMinor : this.changeMinor,
      status: status ?? this.status,
      soldAt: soldAt ?? this.soldAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
