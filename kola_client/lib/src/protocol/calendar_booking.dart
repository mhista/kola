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

abstract class CalendarBooking implements _i1.SerializableModel {
  CalendarBooking._({
    this.id,
    required this.workspaceId,
    this.conversationId,
    required this.title,
    this.description,
    required this.startsAt,
    required this.endsAt,
    this.attendeeName,
    this.attendeeEmail,
    this.attendeePhone,
    required this.status,
    this.googleEventId,
    this.resolvedByEmail,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarBooking({
    int? id,
    required int workspaceId,
    int? conversationId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    required String status,
    String? googleEventId,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CalendarBookingImpl;

  factory CalendarBooking.fromJson(Map<String, dynamic> jsonSerialization) {
    return CalendarBooking(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      conversationId: jsonSerialization['conversationId'] as int?,
      title: jsonSerialization['title'] as String,
      description: jsonSerialization['description'] as String?,
      startsAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['startsAt'],
      ),
      endsAt: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['endsAt']),
      attendeeName: jsonSerialization['attendeeName'] as String?,
      attendeeEmail: jsonSerialization['attendeeEmail'] as String?,
      attendeePhone: jsonSerialization['attendeePhone'] as String?,
      status: jsonSerialization['status'] as String,
      googleEventId: jsonSerialization['googleEventId'] as String?,
      resolvedByEmail: jsonSerialization['resolvedByEmail'] as String?,
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
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

  int? conversationId;

  String title;

  String? description;

  DateTime startsAt;

  DateTime endsAt;

  String? attendeeName;

  String? attendeeEmail;

  String? attendeePhone;

  String status;

  String? googleEventId;

  String? resolvedByEmail;

  DateTime? resolvedAt;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [CalendarBooking]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  CalendarBooking copyWith({
    int? id,
    int? workspaceId,
    int? conversationId,
    String? title,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    String? status,
    String? googleEventId,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CalendarBooking',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      if (conversationId != null) 'conversationId': conversationId,
      'title': title,
      if (description != null) 'description': description,
      'startsAt': startsAt.toJson(),
      'endsAt': endsAt.toJson(),
      if (attendeeName != null) 'attendeeName': attendeeName,
      if (attendeeEmail != null) 'attendeeEmail': attendeeEmail,
      if (attendeePhone != null) 'attendeePhone': attendeePhone,
      'status': status,
      if (googleEventId != null) 'googleEventId': googleEventId,
      if (resolvedByEmail != null) 'resolvedByEmail': resolvedByEmail,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
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

class _CalendarBookingImpl extends CalendarBooking {
  _CalendarBookingImpl({
    int? id,
    required int workspaceId,
    int? conversationId,
    required String title,
    String? description,
    required DateTime startsAt,
    required DateTime endsAt,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    required String status,
    String? googleEventId,
    String? resolvedByEmail,
    DateTime? resolvedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         conversationId: conversationId,
         title: title,
         description: description,
         startsAt: startsAt,
         endsAt: endsAt,
         attendeeName: attendeeName,
         attendeeEmail: attendeeEmail,
         attendeePhone: attendeePhone,
         status: status,
         googleEventId: googleEventId,
         resolvedByEmail: resolvedByEmail,
         resolvedAt: resolvedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [CalendarBooking]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  CalendarBooking copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    Object? conversationId = _Undefined,
    String? title,
    Object? description = _Undefined,
    DateTime? startsAt,
    DateTime? endsAt,
    Object? attendeeName = _Undefined,
    Object? attendeeEmail = _Undefined,
    Object? attendeePhone = _Undefined,
    String? status,
    Object? googleEventId = _Undefined,
    Object? resolvedByEmail = _Undefined,
    Object? resolvedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarBooking(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      conversationId: conversationId is int?
          ? conversationId
          : this.conversationId,
      title: title ?? this.title,
      description: description is String? ? description : this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      attendeeName: attendeeName is String? ? attendeeName : this.attendeeName,
      attendeeEmail: attendeeEmail is String?
          ? attendeeEmail
          : this.attendeeEmail,
      attendeePhone: attendeePhone is String?
          ? attendeePhone
          : this.attendeePhone,
      status: status ?? this.status,
      googleEventId: googleEventId is String?
          ? googleEventId
          : this.googleEventId,
      resolvedByEmail: resolvedByEmail is String?
          ? resolvedByEmail
          : this.resolvedByEmail,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
