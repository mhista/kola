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
import 'package:kola_client/src/protocol/protocol.dart' as _i2;

abstract class WebhookEndpoint implements _i1.SerializableModel {
  WebhookEndpoint._({
    this.id,
    required this.workspaceId,
    required this.url,
    required this.events,
    required this.status,
    this.encryptedSecret,
    this.lastDeliveryAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebhookEndpoint({
    int? id,
    required int workspaceId,
    required String url,
    required List<String> events,
    required String status,
    String? encryptedSecret,
    DateTime? lastDeliveryAt,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _WebhookEndpointImpl;

  factory WebhookEndpoint.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookEndpoint(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      url: jsonSerialization['url'] as String,
      events: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['events'],
      ),
      status: jsonSerialization['status'] as String,
      encryptedSecret: jsonSerialization['encryptedSecret'] as String?,
      lastDeliveryAt: jsonSerialization['lastDeliveryAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastDeliveryAt'],
            ),
      lastError: jsonSerialization['lastError'] as String?,
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

  String url;

  List<String> events;

  String status;

  String? encryptedSecret;

  DateTime? lastDeliveryAt;

  String? lastError;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [WebhookEndpoint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookEndpoint copyWith({
    int? id,
    int? workspaceId,
    String? url,
    List<String>? events,
    String? status,
    String? encryptedSecret,
    DateTime? lastDeliveryAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookEndpoint',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'url': url,
      'events': events.toJson(),
      'status': status,
      if (encryptedSecret != null) 'encryptedSecret': encryptedSecret,
      if (lastDeliveryAt != null) 'lastDeliveryAt': lastDeliveryAt?.toJson(),
      if (lastError != null) 'lastError': lastError,
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

class _WebhookEndpointImpl extends WebhookEndpoint {
  _WebhookEndpointImpl({
    int? id,
    required int workspaceId,
    required String url,
    required List<String> events,
    required String status,
    String? encryptedSecret,
    DateTime? lastDeliveryAt,
    String? lastError,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         url: url,
         events: events,
         status: status,
         encryptedSecret: encryptedSecret,
         lastDeliveryAt: lastDeliveryAt,
         lastError: lastError,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [WebhookEndpoint]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookEndpoint copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? url,
    List<String>? events,
    String? status,
    Object? encryptedSecret = _Undefined,
    Object? lastDeliveryAt = _Undefined,
    Object? lastError = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WebhookEndpoint(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      url: url ?? this.url,
      events: events ?? this.events.map((e0) => e0).toList(),
      status: status ?? this.status,
      encryptedSecret: encryptedSecret is String?
          ? encryptedSecret
          : this.encryptedSecret,
      lastDeliveryAt: lastDeliveryAt is DateTime?
          ? lastDeliveryAt
          : this.lastDeliveryAt,
      lastError: lastError is String? ? lastError : this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
