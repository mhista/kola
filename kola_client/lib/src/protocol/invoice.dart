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

abstract class Invoice implements _i1.SerializableModel {
  Invoice._({
    this.id,
    required this.workspaceId,
    this.customerId,
    this.saleId,
    required this.reference,
    required this.status,
    required this.billToName,
    this.billToAddress,
    this.billToPhone,
    required this.linesJson,
    required this.subtotalMinor,
    required this.taxRateBps,
    required this.taxMinor,
    required this.totalMinor,
    required this.paidMinor,
    required this.currency,
    this.paymentInstructions,
    required this.issuedAt,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice({
    int? id,
    required int workspaceId,
    int? customerId,
    int? saleId,
    required String reference,
    required String status,
    required String billToName,
    String? billToAddress,
    String? billToPhone,
    required String linesJson,
    required int subtotalMinor,
    required int taxRateBps,
    required int taxMinor,
    required int totalMinor,
    required int paidMinor,
    required String currency,
    String? paymentInstructions,
    required DateTime issuedAt,
    DateTime? dueAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _InvoiceImpl;

  factory Invoice.fromJson(Map<String, dynamic> jsonSerialization) {
    return Invoice(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      customerId: jsonSerialization['customerId'] as int?,
      saleId: jsonSerialization['saleId'] as int?,
      reference: jsonSerialization['reference'] as String,
      status: jsonSerialization['status'] as String,
      billToName: jsonSerialization['billToName'] as String,
      billToAddress: jsonSerialization['billToAddress'] as String?,
      billToPhone: jsonSerialization['billToPhone'] as String?,
      linesJson: jsonSerialization['linesJson'] as String,
      subtotalMinor: jsonSerialization['subtotalMinor'] as int,
      taxRateBps: jsonSerialization['taxRateBps'] as int,
      taxMinor: jsonSerialization['taxMinor'] as int,
      totalMinor: jsonSerialization['totalMinor'] as int,
      paidMinor: jsonSerialization['paidMinor'] as int,
      currency: jsonSerialization['currency'] as String,
      paymentInstructions: jsonSerialization['paymentInstructions'] as String?,
      issuedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['issuedAt'],
      ),
      dueAt: jsonSerialization['dueAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['dueAt']),
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

  int? saleId;

  String reference;

  String status;

  String billToName;

  String? billToAddress;

  String? billToPhone;

  String linesJson;

  int subtotalMinor;

  int taxRateBps;

  int taxMinor;

  int totalMinor;

  int paidMinor;

  String currency;

  String? paymentInstructions;

  DateTime issuedAt;

  DateTime? dueAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Invoice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Invoice copyWith({
    int? id,
    int? workspaceId,
    int? customerId,
    int? saleId,
    String? reference,
    String? status,
    String? billToName,
    String? billToAddress,
    String? billToPhone,
    String? linesJson,
    int? subtotalMinor,
    int? taxRateBps,
    int? taxMinor,
    int? totalMinor,
    int? paidMinor,
    String? currency,
    String? paymentInstructions,
    DateTime? issuedAt,
    DateTime? dueAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Invoice',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (customerId != null) 'customerId': customerId,
      if (saleId != null) 'saleId': saleId,
      'reference': reference,
      'status': status,
      'billToName': billToName,
      if (billToAddress != null) 'billToAddress': billToAddress,
      if (billToPhone != null) 'billToPhone': billToPhone,
      'linesJson': linesJson,
      'subtotalMinor': subtotalMinor,
      'taxRateBps': taxRateBps,
      'taxMinor': taxMinor,
      'totalMinor': totalMinor,
      'paidMinor': paidMinor,
      'currency': currency,
      if (paymentInstructions != null)
        'paymentInstructions': paymentInstructions,
      'issuedAt': issuedAt.toJson(),
      if (dueAt != null) 'dueAt': dueAt?.toJson(),
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

class _InvoiceImpl extends Invoice {
  _InvoiceImpl({
    int? id,
    required int workspaceId,
    int? customerId,
    int? saleId,
    required String reference,
    required String status,
    required String billToName,
    String? billToAddress,
    String? billToPhone,
    required String linesJson,
    required int subtotalMinor,
    required int taxRateBps,
    required int taxMinor,
    required int totalMinor,
    required int paidMinor,
    required String currency,
    String? paymentInstructions,
    required DateTime issuedAt,
    DateTime? dueAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         customerId: customerId,
         saleId: saleId,
         reference: reference,
         status: status,
         billToName: billToName,
         billToAddress: billToAddress,
         billToPhone: billToPhone,
         linesJson: linesJson,
         subtotalMinor: subtotalMinor,
         taxRateBps: taxRateBps,
         taxMinor: taxMinor,
         totalMinor: totalMinor,
         paidMinor: paidMinor,
         currency: currency,
         paymentInstructions: paymentInstructions,
         issuedAt: issuedAt,
         dueAt: dueAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Invoice]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Invoice copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    Object? customerId = _Undefined,
    Object? saleId = _Undefined,
    String? reference,
    String? status,
    String? billToName,
    Object? billToAddress = _Undefined,
    Object? billToPhone = _Undefined,
    String? linesJson,
    int? subtotalMinor,
    int? taxRateBps,
    int? taxMinor,
    int? totalMinor,
    int? paidMinor,
    String? currency,
    Object? paymentInstructions = _Undefined,
    DateTime? issuedAt,
    Object? dueAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      customerId: customerId is int? ? customerId : this.customerId,
      saleId: saleId is int? ? saleId : this.saleId,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      billToName: billToName ?? this.billToName,
      billToAddress: billToAddress is String?
          ? billToAddress
          : this.billToAddress,
      billToPhone: billToPhone is String? ? billToPhone : this.billToPhone,
      linesJson: linesJson ?? this.linesJson,
      subtotalMinor: subtotalMinor ?? this.subtotalMinor,
      taxRateBps: taxRateBps ?? this.taxRateBps,
      taxMinor: taxMinor ?? this.taxMinor,
      totalMinor: totalMinor ?? this.totalMinor,
      paidMinor: paidMinor ?? this.paidMinor,
      currency: currency ?? this.currency,
      paymentInstructions: paymentInstructions is String?
          ? paymentInstructions
          : this.paymentInstructions,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt is DateTime? ? dueAt : this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
