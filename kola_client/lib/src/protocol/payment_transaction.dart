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
    this.customerId,
    required this.status,
    this.saleId,
    required this.holdStatus,
    this.conversationId,
    this.channelId,
    this.checkoutUrl,
    this.gatewayTransactionId,
    this.metadataJson,
    required this.confirmationMethod,
    this.confirmedBy,
    this.confirmedAt,
    this.proofReference,
    this.proofUrl,
    this.expectedBy,
    required this.reminderCount,
    this.lastReminderAt,
    this.assignedTo,
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
    int? customerId,
    required String status,
    int? saleId,
    required String holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    required String confirmationMethod,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? proofReference,
    String? proofUrl,
    DateTime? expectedBy,
    required int reminderCount,
    DateTime? lastReminderAt,
    String? assignedTo,
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
      customerId: jsonSerialization['customerId'] as int?,
      status: jsonSerialization['status'] as String,
      saleId: jsonSerialization['saleId'] as int?,
      holdStatus: jsonSerialization['holdStatus'] as String,
      conversationId: jsonSerialization['conversationId'] as int?,
      channelId: jsonSerialization['channelId'] as int?,
      checkoutUrl: jsonSerialization['checkoutUrl'] as String?,
      gatewayTransactionId:
          jsonSerialization['gatewayTransactionId'] as String?,
      metadataJson: jsonSerialization['metadataJson'] as String?,
      confirmationMethod: jsonSerialization['confirmationMethod'] as String,
      confirmedBy: jsonSerialization['confirmedBy'] as String?,
      confirmedAt: jsonSerialization['confirmedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['confirmedAt'],
            ),
      proofReference: jsonSerialization['proofReference'] as String?,
      proofUrl: jsonSerialization['proofUrl'] as String?,
      expectedBy: jsonSerialization['expectedBy'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['expectedBy']),
      reminderCount: jsonSerialization['reminderCount'] as int,
      lastReminderAt: jsonSerialization['lastReminderAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastReminderAt'],
            ),
      assignedTo: jsonSerialization['assignedTo'] as String?,
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

  int? customerId;

  String status;

  int? saleId;

  String holdStatus;

  int? conversationId;

  int? channelId;

  String? checkoutUrl;

  String? gatewayTransactionId;

  String? metadataJson;

  String confirmationMethod;

  String? confirmedBy;

  DateTime? confirmedAt;

  String? proofReference;

  String? proofUrl;

  DateTime? expectedBy;

  int reminderCount;

  DateTime? lastReminderAt;

  String? assignedTo;

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
    int? customerId,
    String? status,
    int? saleId,
    String? holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    String? confirmationMethod,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? proofReference,
    String? proofUrl,
    DateTime? expectedBy,
    int? reminderCount,
    DateTime? lastReminderAt,
    String? assignedTo,
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
      if (customerId != null) 'customerId': customerId,
      'status': status,
      if (saleId != null) 'saleId': saleId,
      'holdStatus': holdStatus,
      if (conversationId != null) 'conversationId': conversationId,
      if (channelId != null) 'channelId': channelId,
      if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
      if (gatewayTransactionId != null)
        'gatewayTransactionId': gatewayTransactionId,
      if (metadataJson != null) 'metadataJson': metadataJson,
      'confirmationMethod': confirmationMethod,
      if (confirmedBy != null) 'confirmedBy': confirmedBy,
      if (confirmedAt != null) 'confirmedAt': confirmedAt?.toJson(),
      if (proofReference != null) 'proofReference': proofReference,
      if (proofUrl != null) 'proofUrl': proofUrl,
      if (expectedBy != null) 'expectedBy': expectedBy?.toJson(),
      'reminderCount': reminderCount,
      if (lastReminderAt != null) 'lastReminderAt': lastReminderAt?.toJson(),
      if (assignedTo != null) 'assignedTo': assignedTo,
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
    int? customerId,
    required String status,
    int? saleId,
    required String holdStatus,
    int? conversationId,
    int? channelId,
    String? checkoutUrl,
    String? gatewayTransactionId,
    String? metadataJson,
    required String confirmationMethod,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? proofReference,
    String? proofUrl,
    DateTime? expectedBy,
    required int reminderCount,
    DateTime? lastReminderAt,
    String? assignedTo,
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
         customerId: customerId,
         status: status,
         saleId: saleId,
         holdStatus: holdStatus,
         conversationId: conversationId,
         channelId: channelId,
         checkoutUrl: checkoutUrl,
         gatewayTransactionId: gatewayTransactionId,
         metadataJson: metadataJson,
         confirmationMethod: confirmationMethod,
         confirmedBy: confirmedBy,
         confirmedAt: confirmedAt,
         proofReference: proofReference,
         proofUrl: proofUrl,
         expectedBy: expectedBy,
         reminderCount: reminderCount,
         lastReminderAt: lastReminderAt,
         assignedTo: assignedTo,
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
    Object? customerId = _Undefined,
    String? status,
    Object? saleId = _Undefined,
    String? holdStatus,
    Object? conversationId = _Undefined,
    Object? channelId = _Undefined,
    Object? checkoutUrl = _Undefined,
    Object? gatewayTransactionId = _Undefined,
    Object? metadataJson = _Undefined,
    String? confirmationMethod,
    Object? confirmedBy = _Undefined,
    Object? confirmedAt = _Undefined,
    Object? proofReference = _Undefined,
    Object? proofUrl = _Undefined,
    Object? expectedBy = _Undefined,
    int? reminderCount,
    Object? lastReminderAt = _Undefined,
    Object? assignedTo = _Undefined,
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
      customerId: customerId is int? ? customerId : this.customerId,
      status: status ?? this.status,
      saleId: saleId is int? ? saleId : this.saleId,
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
      confirmationMethod: confirmationMethod ?? this.confirmationMethod,
      confirmedBy: confirmedBy is String? ? confirmedBy : this.confirmedBy,
      confirmedAt: confirmedAt is DateTime? ? confirmedAt : this.confirmedAt,
      proofReference: proofReference is String?
          ? proofReference
          : this.proofReference,
      proofUrl: proofUrl is String? ? proofUrl : this.proofUrl,
      expectedBy: expectedBy is DateTime? ? expectedBy : this.expectedBy,
      reminderCount: reminderCount ?? this.reminderCount,
      lastReminderAt: lastReminderAt is DateTime?
          ? lastReminderAt
          : this.lastReminderAt,
      assignedTo: assignedTo is String? ? assignedTo : this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt is DateTime? ? paidAt : this.paidAt,
    );
  }
}
