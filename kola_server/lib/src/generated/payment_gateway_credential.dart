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

abstract class PaymentGatewayCredential
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  PaymentGatewayCredential._({
    this.id,
    required this.workspaceId,
    required this.gateway,
    required this.encryptedSecretKey,
    this.encryptedWebhookSecret,
    required this.createdAt,
    required this.updatedAt,
    this.syncCursor,
    this.lastSyncedAt,
  });

  factory PaymentGatewayCredential({
    int? id,
    required int workspaceId,
    required String gateway,
    required String encryptedSecretKey,
    String? encryptedWebhookSecret,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? syncCursor,
    DateTime? lastSyncedAt,
  }) = _PaymentGatewayCredentialImpl;

  factory PaymentGatewayCredential.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PaymentGatewayCredential(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      gateway: jsonSerialization['gateway'] as String,
      encryptedSecretKey: jsonSerialization['encryptedSecretKey'] as String,
      encryptedWebhookSecret:
          jsonSerialization['encryptedWebhookSecret'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      syncCursor: jsonSerialization['syncCursor'] as String?,
      lastSyncedAt: jsonSerialization['lastSyncedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSyncedAt'],
            ),
    );
  }

  int? id;

  int workspaceId;

  String gateway;

  String encryptedSecretKey;

  String? encryptedWebhookSecret;

  DateTime createdAt;

  DateTime updatedAt;

  String? syncCursor;

  DateTime? lastSyncedAt;

  /// Returns a shallow copy of this [PaymentGatewayCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PaymentGatewayCredential copyWith({
    int? id,
    int? workspaceId,
    String? gateway,
    String? encryptedSecretKey,
    String? encryptedWebhookSecret,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncCursor,
    DateTime? lastSyncedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PaymentGatewayCredential',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'encryptedSecretKey': encryptedSecretKey,
      if (encryptedWebhookSecret != null)
        'encryptedWebhookSecret': encryptedWebhookSecret,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (syncCursor != null) 'syncCursor': syncCursor,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'PaymentGatewayCredential',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'gateway': gateway,
      'encryptedSecretKey': encryptedSecretKey,
      if (encryptedWebhookSecret != null)
        'encryptedWebhookSecret': encryptedWebhookSecret,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (syncCursor != null) 'syncCursor': syncCursor,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PaymentGatewayCredentialImpl extends PaymentGatewayCredential {
  _PaymentGatewayCredentialImpl({
    int? id,
    required int workspaceId,
    required String gateway,
    required String encryptedSecretKey,
    String? encryptedWebhookSecret,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? syncCursor,
    DateTime? lastSyncedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         gateway: gateway,
         encryptedSecretKey: encryptedSecretKey,
         encryptedWebhookSecret: encryptedWebhookSecret,
         createdAt: createdAt,
         updatedAt: updatedAt,
         syncCursor: syncCursor,
         lastSyncedAt: lastSyncedAt,
       );

  /// Returns a shallow copy of this [PaymentGatewayCredential]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PaymentGatewayCredential copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? gateway,
    String? encryptedSecretKey,
    Object? encryptedWebhookSecret = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? syncCursor = _Undefined,
    Object? lastSyncedAt = _Undefined,
  }) {
    return PaymentGatewayCredential(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      gateway: gateway ?? this.gateway,
      encryptedSecretKey: encryptedSecretKey ?? this.encryptedSecretKey,
      encryptedWebhookSecret: encryptedWebhookSecret is String?
          ? encryptedWebhookSecret
          : this.encryptedWebhookSecret,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncCursor: syncCursor is String? ? syncCursor : this.syncCursor,
      lastSyncedAt: lastSyncedAt is DateTime?
          ? lastSyncedAt
          : this.lastSyncedAt,
    );
  }
}
