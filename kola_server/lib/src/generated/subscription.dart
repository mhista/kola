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

abstract class Subscription
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Subscription._({
    this.id,
    required this.workspaceId,
    required this.plan,
    this.gatewayProvider,
    this.gatewayCustomerId,
    this.gatewaySubscriptionId,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription({
    int? id,
    required int workspaceId,
    required String plan,
    String? gatewayProvider,
    String? gatewayCustomerId,
    String? gatewaySubscriptionId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SubscriptionImpl;

  factory Subscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return Subscription(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      plan: jsonSerialization['plan'] as String,
      gatewayProvider: jsonSerialization['gatewayProvider'] as String?,
      gatewayCustomerId: jsonSerialization['gatewayCustomerId'] as String?,
      gatewaySubscriptionId:
          jsonSerialization['gatewaySubscriptionId'] as String?,
      currentPeriodStart: jsonSerialization['currentPeriodStart'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['currentPeriodStart'],
            ),
      currentPeriodEnd: jsonSerialization['currentPeriodEnd'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['currentPeriodEnd'],
            ),
      status: jsonSerialization['status'] as String,
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

  String plan;

  String? gatewayProvider;

  String? gatewayCustomerId;

  String? gatewaySubscriptionId;

  DateTime? currentPeriodStart;

  DateTime? currentPeriodEnd;

  String status;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Subscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Subscription copyWith({
    int? id,
    int? workspaceId,
    String? plan,
    String? gatewayProvider,
    String? gatewayCustomerId,
    String? gatewaySubscriptionId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Subscription',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'plan': plan,
      if (gatewayProvider != null) 'gatewayProvider': gatewayProvider,
      if (gatewayCustomerId != null) 'gatewayCustomerId': gatewayCustomerId,
      if (gatewaySubscriptionId != null)
        'gatewaySubscriptionId': gatewaySubscriptionId,
      if (currentPeriodStart != null)
        'currentPeriodStart': currentPeriodStart?.toJson(),
      if (currentPeriodEnd != null)
        'currentPeriodEnd': currentPeriodEnd?.toJson(),
      'status': status,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Subscription',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'plan': plan,
      if (gatewayProvider != null) 'gatewayProvider': gatewayProvider,
      if (gatewayCustomerId != null) 'gatewayCustomerId': gatewayCustomerId,
      if (gatewaySubscriptionId != null)
        'gatewaySubscriptionId': gatewaySubscriptionId,
      if (currentPeriodStart != null)
        'currentPeriodStart': currentPeriodStart?.toJson(),
      if (currentPeriodEnd != null)
        'currentPeriodEnd': currentPeriodEnd?.toJson(),
      'status': status,
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

class _SubscriptionImpl extends Subscription {
  _SubscriptionImpl({
    int? id,
    required int workspaceId,
    required String plan,
    String? gatewayProvider,
    String? gatewayCustomerId,
    String? gatewaySubscriptionId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         plan: plan,
         gatewayProvider: gatewayProvider,
         gatewayCustomerId: gatewayCustomerId,
         gatewaySubscriptionId: gatewaySubscriptionId,
         currentPeriodStart: currentPeriodStart,
         currentPeriodEnd: currentPeriodEnd,
         status: status,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Subscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Subscription copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? plan,
    Object? gatewayProvider = _Undefined,
    Object? gatewayCustomerId = _Undefined,
    Object? gatewaySubscriptionId = _Undefined,
    Object? currentPeriodStart = _Undefined,
    Object? currentPeriodEnd = _Undefined,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      plan: plan ?? this.plan,
      gatewayProvider: gatewayProvider is String?
          ? gatewayProvider
          : this.gatewayProvider,
      gatewayCustomerId: gatewayCustomerId is String?
          ? gatewayCustomerId
          : this.gatewayCustomerId,
      gatewaySubscriptionId: gatewaySubscriptionId is String?
          ? gatewaySubscriptionId
          : this.gatewaySubscriptionId,
      currentPeriodStart: currentPeriodStart is DateTime?
          ? currentPeriodStart
          : this.currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd is DateTime?
          ? currentPeriodEnd
          : this.currentPeriodEnd,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
