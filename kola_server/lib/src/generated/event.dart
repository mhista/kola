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

abstract class Event
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Event._({
    this.id,
    required this.workspaceId,
    required this.eventType,
    required this.fingerprint,
    required this.payloadJson,
    required this.occurredAt,
    required this.ingestedAt,
  });

  factory Event({
    int? id,
    required int workspaceId,
    required String eventType,
    required String fingerprint,
    required String payloadJson,
    required DateTime occurredAt,
    required DateTime ingestedAt,
  }) = _EventImpl;

  factory Event.fromJson(Map<String, dynamic> jsonSerialization) {
    return Event(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      eventType: jsonSerialization['eventType'] as String,
      fingerprint: jsonSerialization['fingerprint'] as String,
      payloadJson: jsonSerialization['payloadJson'] as String,
      occurredAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['occurredAt'],
      ),
      ingestedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['ingestedAt'],
      ),
    );
  }

  int? id;

  int workspaceId;

  String eventType;

  String fingerprint;

  String payloadJson;

  DateTime occurredAt;

  DateTime ingestedAt;

  /// Returns a shallow copy of this [Event]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Event copyWith({
    int? id,
    int? workspaceId,
    String? eventType,
    String? fingerprint,
    String? payloadJson,
    DateTime? occurredAt,
    DateTime? ingestedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Event',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'eventType': eventType,
      'fingerprint': fingerprint,
      'payloadJson': payloadJson,
      'occurredAt': occurredAt.toJson(),
      'ingestedAt': ingestedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Event',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'eventType': eventType,
      'fingerprint': fingerprint,
      'payloadJson': payloadJson,
      'occurredAt': occurredAt.toJson(),
      'ingestedAt': ingestedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EventImpl extends Event {
  _EventImpl({
    int? id,
    required int workspaceId,
    required String eventType,
    required String fingerprint,
    required String payloadJson,
    required DateTime occurredAt,
    required DateTime ingestedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         eventType: eventType,
         fingerprint: fingerprint,
         payloadJson: payloadJson,
         occurredAt: occurredAt,
         ingestedAt: ingestedAt,
       );

  /// Returns a shallow copy of this [Event]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Event copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? eventType,
    String? fingerprint,
    String? payloadJson,
    DateTime? occurredAt,
    DateTime? ingestedAt,
  }) {
    return Event(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      eventType: eventType ?? this.eventType,
      fingerprint: fingerprint ?? this.fingerprint,
      payloadJson: payloadJson ?? this.payloadJson,
      occurredAt: occurredAt ?? this.occurredAt,
      ingestedAt: ingestedAt ?? this.ingestedAt,
    );
  }
}
