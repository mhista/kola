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

abstract class Broadcast
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  Broadcast._({
    this.id,
    required this.workspaceId,
    required this.platform,
    required this.text,
    required this.status,
    required this.throughputPerMinute,
    required this.totalRecipients,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    required this.escalatedReplyCount,
    this.lastDigestSentAt,
  });

  factory Broadcast({
    int? id,
    required int workspaceId,
    required String platform,
    required String text,
    required String status,
    required int throughputPerMinute,
    required int totalRecipients,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    required int escalatedReplyCount,
    DateTime? lastDigestSentAt,
  }) = _BroadcastImpl;

  factory Broadcast.fromJson(Map<String, dynamic> jsonSerialization) {
    return Broadcast(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      platform: jsonSerialization['platform'] as String,
      text: jsonSerialization['text'] as String,
      status: jsonSerialization['status'] as String,
      throughputPerMinute: jsonSerialization['throughputPerMinute'] as int,
      totalRecipients: jsonSerialization['totalRecipients'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
      escalatedReplyCount: jsonSerialization['escalatedReplyCount'] as int,
      lastDigestSentAt: jsonSerialization['lastDigestSentAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastDigestSentAt'],
            ),
    );
  }

  int? id;

  int workspaceId;

  String platform;

  String text;

  String status;

  int throughputPerMinute;

  int totalRecipients;

  DateTime createdAt;

  DateTime updatedAt;

  DateTime? startedAt;

  DateTime? completedAt;

  int escalatedReplyCount;

  DateTime? lastDigestSentAt;

  /// Returns a shallow copy of this [Broadcast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Broadcast copyWith({
    int? id,
    int? workspaceId,
    String? platform,
    String? text,
    String? status,
    int? throughputPerMinute,
    int? totalRecipients,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? escalatedReplyCount,
    DateTime? lastDigestSentAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Broadcast',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'platform': platform,
      'text': text,
      'status': status,
      'throughputPerMinute': throughputPerMinute,
      'totalRecipients': totalRecipients,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'escalatedReplyCount': escalatedReplyCount,
      if (lastDigestSentAt != null)
        'lastDigestSentAt': lastDigestSentAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Broadcast',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'platform': platform,
      'text': text,
      'status': status,
      'throughputPerMinute': throughputPerMinute,
      'totalRecipients': totalRecipients,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
      'escalatedReplyCount': escalatedReplyCount,
      if (lastDigestSentAt != null)
        'lastDigestSentAt': lastDigestSentAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BroadcastImpl extends Broadcast {
  _BroadcastImpl({
    int? id,
    required int workspaceId,
    required String platform,
    required String text,
    required String status,
    required int throughputPerMinute,
    required int totalRecipients,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    required int escalatedReplyCount,
    DateTime? lastDigestSentAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         platform: platform,
         text: text,
         status: status,
         throughputPerMinute: throughputPerMinute,
         totalRecipients: totalRecipients,
         createdAt: createdAt,
         updatedAt: updatedAt,
         startedAt: startedAt,
         completedAt: completedAt,
         escalatedReplyCount: escalatedReplyCount,
         lastDigestSentAt: lastDigestSentAt,
       );

  /// Returns a shallow copy of this [Broadcast]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Broadcast copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? platform,
    String? text,
    String? status,
    int? throughputPerMinute,
    int? totalRecipients,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? startedAt = _Undefined,
    Object? completedAt = _Undefined,
    int? escalatedReplyCount,
    Object? lastDigestSentAt = _Undefined,
  }) {
    return Broadcast(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      platform: platform ?? this.platform,
      text: text ?? this.text,
      status: status ?? this.status,
      throughputPerMinute: throughputPerMinute ?? this.throughputPerMinute,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
      escalatedReplyCount: escalatedReplyCount ?? this.escalatedReplyCount,
      lastDigestSentAt: lastDigestSentAt is DateTime?
          ? lastDigestSentAt
          : this.lastDigestSentAt,
    );
  }
}
