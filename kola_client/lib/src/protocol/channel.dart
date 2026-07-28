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

abstract class Channel implements _i1.SerializableModel {
  Channel._({
    this.id,
    required this.botId,
    required this.platformType,
    this.displayName,
    this.encryptedCredential,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Channel({
    int? id,
    required int botId,
    required String platformType,
    String? displayName,
    String? encryptedCredential,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChannelImpl;

  factory Channel.fromJson(Map<String, dynamic> jsonSerialization) {
    return Channel(
      id: jsonSerialization['id'] as int?,
      botId: jsonSerialization['botId'] as int,
      platformType: jsonSerialization['platformType'] as String,
      displayName: jsonSerialization['displayName'] as String?,
      encryptedCredential: jsonSerialization['encryptedCredential'] as String?,
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

  int botId;

  String platformType;

  String? displayName;

  String? encryptedCredential;

  String status;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Channel copyWith({
    int? id,
    int? botId,
    String? platformType,
    String? displayName,
    String? encryptedCredential,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'botId': botId,
      'platformType': platformType,
      if (displayName != null) 'displayName': displayName,
      if (encryptedCredential != null)
        'encryptedCredential': encryptedCredential,
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

class _ChannelImpl extends Channel {
  _ChannelImpl({
    int? id,
    required int botId,
    required String platformType,
    String? displayName,
    String? encryptedCredential,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         botId: botId,
         platformType: platformType,
         displayName: displayName,
         encryptedCredential: encryptedCredential,
         status: status,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Channel copyWith({
    Object? id = _Undefined,
    int? botId,
    String? platformType,
    Object? displayName = _Undefined,
    Object? encryptedCredential = _Undefined,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Channel(
      id: id is int? ? id : this.id,
      botId: botId ?? this.botId,
      platformType: platformType ?? this.platformType,
      displayName: displayName is String? ? displayName : this.displayName,
      encryptedCredential: encryptedCredential is String?
          ? encryptedCredential
          : this.encryptedCredential,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
