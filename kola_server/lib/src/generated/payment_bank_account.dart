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

abstract class PaymentBankAccount
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PaymentBankAccount._({
    this.id,
    required this.workspaceId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.currency,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentBankAccount({
    int? id,
    required int workspaceId,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String currency,
    required bool isVerified,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PaymentBankAccountImpl;

  factory PaymentBankAccount.fromJson(Map<String, dynamic> jsonSerialization) {
    return PaymentBankAccount(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      bankName: jsonSerialization['bankName'] as String,
      accountNumber: jsonSerialization['accountNumber'] as String,
      accountName: jsonSerialization['accountName'] as String,
      currency: jsonSerialization['currency'] as String,
      isVerified: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isVerified'],
      ),
      isActive: _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
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

  String bankName;

  String accountNumber;

  String accountName;

  String currency;

  bool isVerified;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [PaymentBankAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaymentBankAccount copyWith({
    int? id,
    int? workspaceId,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? currency,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaymentBankAccount',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'currency': currency,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PaymentBankAccount',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'currency': currency,
      'isVerified': isVerified,
      'isActive': isActive,
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

class _PaymentBankAccountImpl extends PaymentBankAccount {
  _PaymentBankAccountImpl({
    int? id,
    required int workspaceId,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required String currency,
    required bool isVerified,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         bankName: bankName,
         accountNumber: accountNumber,
         accountName: accountName,
         currency: currency,
         isVerified: isVerified,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PaymentBankAccount]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaymentBankAccount copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? currency,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentBankAccount(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      currency: currency ?? this.currency,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
