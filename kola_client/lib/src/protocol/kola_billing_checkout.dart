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

abstract class KolaBillingCheckout implements _i1.SerializableModel {
  KolaBillingCheckout._({
    this.id,
    required this.workspaceId,
    required this.gateway,
    required this.reference,
    required this.amountKobo,
    required this.plan,
    required this.status,
    this.checkoutUrl,
    this.gatewayTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  factory KolaBillingCheckout({
    int? id,
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String plan,
    required String status,
    String? checkoutUrl,
    String? gatewayTransactionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? paidAt,
  }) = _KolaBillingCheckoutImpl;

  factory KolaBillingCheckout.fromJson(Map<String, dynamic> jsonSerialization) {
    return KolaBillingCheckout(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      gateway: jsonSerialization['gateway'] as String,
      reference: jsonSerialization['reference'] as String,
      amountKobo: jsonSerialization['amountKobo'] as int,
      plan: jsonSerialization['plan'] as String,
      status: jsonSerialization['status'] as String,
      checkoutUrl: jsonSerialization['checkoutUrl'] as String?,
      gatewayTransactionId:
          jsonSerialization['gatewayTransactionId'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      paidAt: jsonSerialization['paidAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['paidAt']),
    );
  }

  int? id;

  int workspaceId;

  String gateway;

  String reference;

  int amountKobo;

  String plan;

  String status;

  String? checkoutUrl;

  String? gatewayTransactionId;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? paidAt;

  /// Returns a shallow copy of this [KolaBillingCheckout]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  KolaBillingCheckout copyWith({
    int? id,
    int? workspaceId,
    String? gateway,
    String? reference,
    int? amountKobo,
    String? plan,
    String? status,
    String? checkoutUrl,
    String? gatewayTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'KolaBillingCheckout',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'reference': reference,
      'amountKobo': amountKobo,
      'plan': plan,
      'status': status,
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (gatewayTransactionId != null)
        'gatewayTransactionId': gatewayTransactionId,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (paidAt != null) 'paidAt': paidAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _KolaBillingCheckoutImpl extends KolaBillingCheckout {
  _KolaBillingCheckoutImpl({
    int? id,
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String plan,
    required String status,
    String? checkoutUrl,
    String? gatewayTransactionId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? paidAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         gateway: gateway,
         reference: reference,
         amountKobo: amountKobo,
         plan: plan,
         status: status,
         checkoutUrl: checkoutUrl,
         gatewayTransactionId: gatewayTransactionId,
         createdAt: createdAt,
         updatedAt: updatedAt,
         paidAt: paidAt,
       );

  /// Returns a shallow copy of this [KolaBillingCheckout]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  KolaBillingCheckout copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? gateway,
    String? reference,
    int? amountKobo,
    String? plan,
    String? status,
    Object? checkoutUrl = _Undefined,
    Object? gatewayTransactionId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? paidAt = _Undefined,
  }) {
    return KolaBillingCheckout(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      gateway: gateway ?? this.gateway,
      reference: reference ?? this.reference,
      amountKobo: amountKobo ?? this.amountKobo,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      checkoutUrl: checkoutUrl is String? ? checkoutUrl : this.checkoutUrl,
      gatewayTransactionId: gatewayTransactionId is String?
          ? gatewayTransactionId
          : this.gatewayTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt is DateTime? ? paidAt : this.paidAt,
    );
  }
}
