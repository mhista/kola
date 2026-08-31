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
import 'connector_field_spec.dart' as _i2;
import 'package:kola_client/src/protocol/protocol.dart' as _i3;

abstract class ConnectorStatus implements _i1.SerializableModel {
  ConnectorStatus._({
    required this.key,
    required this.name,
    required this.category,
    required this.isChannel,
    required this.isPaymentGateway,
    required this.description,
    required this.status,
    required this.authType,
    this.manageRoute,
    required this.helpText,
    required this.fields,
    this.displayDetail,
    this.lastSyncedAt,
    this.lastError,
    this.channelId,
  });

  factory ConnectorStatus({
    required String key,
    required String name,
    required String category,
    required bool isChannel,
    required bool isPaymentGateway,
    required String description,
    required String status,
    required String authType,
    String? manageRoute,
    required String helpText,
    required List<_i2.ConnectorFieldSpec> fields,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    int? channelId,
  }) = _ConnectorStatusImpl;

  factory ConnectorStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return ConnectorStatus(
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      category: jsonSerialization['category'] as String,
      isChannel: _i1.BoolJsonExtension.fromJson(jsonSerialization['isChannel']),
      isPaymentGateway: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['isPaymentGateway'],
      ),
      description: jsonSerialization['description'] as String,
      status: jsonSerialization['status'] as String,
      authType: jsonSerialization['authType'] as String,
      manageRoute: jsonSerialization['manageRoute'] as String?,
      helpText: jsonSerialization['helpText'] as String,
      fields: _i3.Protocol().deserialize<List<_i2.ConnectorFieldSpec>>(
        jsonSerialization['fields'],
      ),
      displayDetail: jsonSerialization['displayDetail'] as String?,
      lastSyncedAt: jsonSerialization['lastSyncedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastSyncedAt'],
            ),
      lastError: jsonSerialization['lastError'] as String?,
      channelId: jsonSerialization['channelId'] as int?,
    );
  }

  String key;

  String name;

  String category;

  bool isChannel;

  bool isPaymentGateway;

  String description;

  String status;

  String authType;

  String? manageRoute;

  String helpText;

  List<_i2.ConnectorFieldSpec> fields;

  String? displayDetail;

  DateTime? lastSyncedAt;

  String? lastError;

  int? channelId;

  /// Returns a shallow copy of this [ConnectorStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ConnectorStatus copyWith({
    String? key,
    String? name,
    String? category,
    bool? isChannel,
    bool? isPaymentGateway,
    String? description,
    String? status,
    String? authType,
    String? manageRoute,
    String? helpText,
    List<_i2.ConnectorFieldSpec>? fields,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    int? channelId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ConnectorStatus',
      'key': key,
      'name': name,
      'category': category,
      'isChannel': isChannel,
      'isPaymentGateway': isPaymentGateway,
      'description': description,
      'status': status,
      'authType': authType,
      if (manageRoute != null) 'manageRoute': manageRoute,
      'helpText': helpText,
      'fields': fields.toJson(valueToJson: (v) => v.toJson()),
      if (displayDetail != null) 'displayDetail': displayDetail,
      if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt?.toJson(),
      if (lastError != null) 'lastError': lastError,
      if (channelId != null) 'channelId': channelId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ConnectorStatusImpl extends ConnectorStatus {
  _ConnectorStatusImpl({
    required String key,
    required String name,
    required String category,
    required bool isChannel,
    required bool isPaymentGateway,
    required String description,
    required String status,
    required String authType,
    String? manageRoute,
    required String helpText,
    required List<_i2.ConnectorFieldSpec> fields,
    String? displayDetail,
    DateTime? lastSyncedAt,
    String? lastError,
    int? channelId,
  }) : super._(
         key: key,
         name: name,
         category: category,
         isChannel: isChannel,
         isPaymentGateway: isPaymentGateway,
         description: description,
         status: status,
         authType: authType,
         manageRoute: manageRoute,
         helpText: helpText,
         fields: fields,
         displayDetail: displayDetail,
         lastSyncedAt: lastSyncedAt,
         lastError: lastError,
         channelId: channelId,
       );

  /// Returns a shallow copy of this [ConnectorStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ConnectorStatus copyWith({
    String? key,
    String? name,
    String? category,
    bool? isChannel,
    bool? isPaymentGateway,
    String? description,
    String? status,
    String? authType,
    Object? manageRoute = _Undefined,
    String? helpText,
    List<_i2.ConnectorFieldSpec>? fields,
    Object? displayDetail = _Undefined,
    Object? lastSyncedAt = _Undefined,
    Object? lastError = _Undefined,
    Object? channelId = _Undefined,
  }) {
    return ConnectorStatus(
      key: key ?? this.key,
      name: name ?? this.name,
      category: category ?? this.category,
      isChannel: isChannel ?? this.isChannel,
      isPaymentGateway: isPaymentGateway ?? this.isPaymentGateway,
      description: description ?? this.description,
      status: status ?? this.status,
      authType: authType ?? this.authType,
      manageRoute: manageRoute is String? ? manageRoute : this.manageRoute,
      helpText: helpText ?? this.helpText,
      fields: fields ?? this.fields.map((e0) => e0.copyWith()).toList(),
      displayDetail: displayDetail is String?
          ? displayDetail
          : this.displayDetail,
      lastSyncedAt: lastSyncedAt is DateTime?
          ? lastSyncedAt
          : this.lastSyncedAt,
      lastError: lastError is String? ? lastError : this.lastError,
      channelId: channelId is int? ? channelId : this.channelId,
    );
  }
}
