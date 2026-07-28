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

abstract class Message
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Message._({
    this.id,
    required this.conversationId,
    required this.direction,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  factory Message({
    int? id,
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
    required DateTime createdAt,
  }) = _MessageImpl;

  factory Message.fromJson(Map<String, dynamic> jsonSerialization) {
    return Message(
      id: jsonSerialization['id'] as int?,
      conversationId: jsonSerialization['conversationId'] as int,
      direction: jsonSerialization['direction'] as String,
      senderType: jsonSerialization['senderType'] as String,
      body: jsonSerialization['body'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int conversationId;

  String direction;

  String senderType;

  String body;

  DateTime createdAt;

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Message copyWith({
    int? id,
    int? conversationId,
    String? direction,
    String? senderType,
    String? body,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'conversationId': conversationId,
      'direction': direction,
      'senderType': senderType,
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Message',
      if (id != null) 'id': id,
      'conversationId': conversationId,
      'direction': direction,
      'senderType': senderType,
      'body': body,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessageImpl extends Message {
  _MessageImpl({
    int? id,
    required int conversationId,
    required String direction,
    required String senderType,
    required String body,
    required DateTime createdAt,
  }) : super._(
         id: id,
         conversationId: conversationId,
         direction: direction,
         senderType: senderType,
         body: body,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Message]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Message copyWith({
    Object? id = _Undefined,
    int? conversationId,
    String? direction,
    String? senderType,
    String? body,
    DateTime? createdAt,
  }) {
    return Message(
      id: id is int? ? id : this.id,
      conversationId: conversationId ?? this.conversationId,
      direction: direction ?? this.direction,
      senderType: senderType ?? this.senderType,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
