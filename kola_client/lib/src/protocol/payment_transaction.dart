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

abstract class PaymentTransaction implements _i1.SerializableModel {
  PaymentTransaction._({
    this.id,
    required this.workspaceId,
    required this.gateway,
    required this.reference,
    required this.amountKobo,
    required this.currency,
    required this.customerEmail,
    this.customerPhone,
    required this.status,
    required this.holdStatus,
    this.conversationId,
    this.channelId,
    this.checkoutUrl,
    this.gatewayTransactionId,
    this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  factory PaymentTransaction({
    int? id,
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String currency,
    required String customerEmail,
    String? customerPhone,
    required String status,
    required String holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? paidAt,
  }) = _PaymentTransactionImpl;

  factory PaymentTransaction.fromJson(Map<String, dynamic> jsonSerialization) {
    return PaymentTransaction(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      gateway: jsonSerialization['gateway'] as String,
      reference: jsonSerialization['reference'] as String,
      amountKobo: jsonSerialization['amountKobo'] as int,
      currency: jsonSerialization['currency'] as String,
      customerEmail: jsonSerialization['customerEmail'] as String,
      customerPhone: jsonSerialization['customerPhone'] as String?,
      status: jsonSerialization['status'] as String,
      holdStatus: jsonSerialization['holdStatus'] as String,
      conversationId: jsonSerialization['conversationId'] as int?,
      channelId: jsonSerialization['channelId'] as int?,
      checkoutUrl: jsonSerialization['checkoutUrl'] as String?,
      gatewayTransactionId:
          jsonSerialization['gatewayTransactionId'] as String?,
      metadataJson: jsonSerialization['metadataJson'] as String?,
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

  String currency;

  String customerEmail;

  String? customerPhone;

  String status;

  String holdStatus;

  int? conversationId;

  int? channelId;

  String? checkoutUrl;

  String? gatewayTransactionId;

  String? metadataJson;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? paidAt;

  /// Returns a shallow copy of this [PaymentTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaymentTransaction copyWith({
    int? id,
    int? workspaceId,
    String? gateway,
    String? reference,
    int? amountKobo,
    String? currency,
    String? customerEmail,
    String? customerPhone,
    String? status,
    String? holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaymentTransaction',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'reference': reference,
      'amountKobo': amountKobo,
      'currency': currency,
      'customerEmail': customerEmail,
      if (customerPhone != null) 'customerPhone': customerPhone,
      'status': status,
      'holdStatus': holdStatus,
      if (conversationId != null) 'conversationId': conversationId,
      if (channelId != null) 'channelId': channelId,
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (gatewayTransactionId != null)
        'gatewayTransactionId': gatewayTransactionId,
      if (metadataJson != null) 'metadataJson': metadataJson,
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

class _PaymentTransactionImpl extends PaymentTransaction {
  _PaymentTransactionImpl({
    int? id,
    required int workspaceId,
    required String gateway,
    required String reference,
    required int amountKobo,
    required String currency,
    required String customerEmail,
    String? customerPhone,
    required String status,
    required String holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? paidAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         gateway: gateway,
         reference: reference,
         amountKobo: amountKobo,
         currency: currency,
         customerEmail: customerEmail,
         customerPhone: customerPhone,
         status: status,
         holdStatus: holdStatus,
         conversationId: conversationId,
         channelId: channelId,
         checkoutUrl: checkoutUrl,
         gatewayTransactionId: gatewayTransactionId,
         metadataJson: metadataJson,
         createdAt: createdAt,
         updatedAt: updatedAt,
         paidAt: paidAt,
       );

  /// Returns a shallow copy of this [PaymentTransaction]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaymentTransaction copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? gateway,
    String? reference,
    int? amountKobo,
    String? currency,
    String? customerEmail,
    Object? customerPhone = _Undefined,
    String? status,
    String? holdStatus,
    Object? conversationId = _Undefined,
    Object? channelId = _Undefined,
    Object? checkoutUrl = _Undefined,
    Object? gatewayTransactionId = _Undefined,
    Object? metadataJson = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? paidAt = _Undefined,
  }) {
    return PaymentTransaction(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      gateway: gateway ?? this.gateway,
      reference: reference ?? this.reference,
      amountKobo: amountKobo ?? this.amountKobo,
      currency: currency ?? this.currency,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone is String?
          ? customerPhone
          : this.customerPhone,
      status: status ?? this.status,
      holdStatus: holdStatus ?? this.holdStatus,
      conversationId: conversationId is int?
          ? conversationId
          : this.conversationId,
      channelId: channelId is int? ? channelId : this.channelId,
      checkoutUrl: checkoutUrl is String? ? checkoutUrl : this.checkoutUrl,
      gatewayTransactionId: gatewayTransactionId is String?
          ? gatewayTransactionId
          : this.gatewayTransactionId,
      metadataJson: metadataJson is String? ? metadataJson : this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt is DateTime? ? paidAt : this.paidAt,
    );
  }
}
