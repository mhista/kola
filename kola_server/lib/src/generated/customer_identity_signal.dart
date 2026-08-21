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

abstract class CustomerIdentitySignal
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  CustomerIdentitySignal._({
    this.id,
    required this.workspaceId,
    required this.customerId,
    required this.signalType,
    required this.normalizedValue,
    required this.source,
    this.sourceRef,
    required this.firstSeenAt,
  });

  factory CustomerIdentitySignal({
    int? id,
    required int workspaceId,
    required int customerId,
    required String signalType,
    required String normalizedValue,
    required String source,
    String? sourceRef,
    required DateTime firstSeenAt,
  }) = _CustomerIdentitySignalImpl;

  factory CustomerIdentitySignal.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return CustomerIdentitySignal(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      customerId: jsonSerialization['customerId'] as int,
      signalType: jsonSerialization['signalType'] as String,
      normalizedValue: jsonSerialization['normalizedValue'] as String,
      source: jsonSerialization['source'] as String,
      sourceRef: jsonSerialization['sourceRef'] as String?,
      firstSeenAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstSeenAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  int customerId;

  String signalType;

  String normalizedValue;

  String source;

  String? sourceRef;

  DateTime firstSeenAt;

  /// Returns a shallow copy of this [CustomerIdentitySignal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CustomerIdentitySignal copyWith({
    int? id,
    int? workspaceId,
    int? customerId,
    String? signalType,
    String? normalizedValue,
    String? source,
    String? sourceRef,
    DateTime? firstSeenAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CustomerIdentitySignal',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'customerId': customerId,
      'signalType': signalType,
      'normalizedValue': normalizedValue,
      'source': source,
      if (sourceRef != null) 'sourceRef': sourceRef,
      'firstSeenAt': firstSeenAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CustomerIdentitySignal',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'customerId': customerId,
      'signalType': signalType,
      'normalizedValue': normalizedValue,
      'source': source,
      if (sourceRef != null) 'sourceRef': sourceRef,
      'firstSeenAt': firstSeenAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _CustomerIdentitySignalImpl extends CustomerIdentitySignal {
  _CustomerIdentitySignalImpl({
    int? id,
    required int workspaceId,
    required int customerId,
    required String signalType,
    required String normalizedValue,
    required String source,
    String? sourceRef,
    required DateTime firstSeenAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         customerId: customerId,
         signalType: signalType,
         normalizedValue: normalizedValue,
         source: source,
         sourceRef: sourceRef,
         firstSeenAt: firstSeenAt,
       );

  /// Returns a shallow copy of this [CustomerIdentitySignal]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CustomerIdentitySignal copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    int? customerId,
    String? signalType,
    String? normalizedValue,
    String? source,
    Object? sourceRef = _Undefined,
    DateTime? firstSeenAt,
  }) {
    return CustomerIdentitySignal(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      customerId: customerId ?? this.customerId,
      signalType: signalType ?? this.signalType,
      normalizedValue: normalizedValue ?? this.normalizedValue,
      source: source ?? this.source,
      sourceRef: sourceRef is String? ? sourceRef : this.sourceRef,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    );
  }
}
