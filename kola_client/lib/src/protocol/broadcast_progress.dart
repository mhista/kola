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

abstract class BroadcastProgress implements _i1.SerializableModel {
  BroadcastProgress._({
    required this.broadcastId,
    required this.status,
    required this.totalRecipients,
    required this.queued,
    required this.sending,
    required this.sent,
    required this.failed,
    required this.skipped,
  });

  factory BroadcastProgress({
    required int broadcastId,
    required String status,
    required int totalRecipients,
    required int queued,
    required int sending,
    required int sent,
    required int failed,
    required int skipped,
  }) = _BroadcastProgressImpl;

  factory BroadcastProgress.fromJson(Map<String, dynamic> jsonSerialization) {
    return BroadcastProgress(
      broadcastId: jsonSerialization['broadcastId'] as int,
      status: jsonSerialization['status'] as String,
      totalRecipients: jsonSerialization['totalRecipients'] as int,
      queued: jsonSerialization['queued'] as int,
      sending: jsonSerialization['sending'] as int,
      sent: jsonSerialization['sent'] as int,
      failed: jsonSerialization['failed'] as int,
      skipped: jsonSerialization['skipped'] as int,
    );
  }

  int broadcastId;

  String status;

  int totalRecipients;

  int queued;

  int sending;

  int sent;

  int failed;

  int skipped;

  /// Returns a shallow copy of this [BroadcastProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  BroadcastProgress copyWith({
    int? broadcastId,
    String? status,
    int? totalRecipients,
    int? queued,
    int? sending,
    int? sent,
    int? failed,
    int? skipped,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BroadcastProgress',
      'broadcastId': broadcastId,
      'status': status,
      'totalRecipients': totalRecipients,
      'queued': queued,
      'sending': sending,
      'sent': sent,
      'failed': failed,
      'skipped': skipped,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _BroadcastProgressImpl extends BroadcastProgress {
  _BroadcastProgressImpl({
    required int broadcastId,
    required String status,
    required int totalRecipients,
    required int queued,
    required int sending,
    required int sent,
    required int failed,
    required int skipped,
  }) : super._(
         broadcastId: broadcastId,
         status: status,
         totalRecipients: totalRecipients,
         queued: queued,
         sending: sending,
         sent: sent,
         failed: failed,
         skipped: skipped,
       );

  /// Returns a shallow copy of this [BroadcastProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  BroadcastProgress copyWith({
    int? broadcastId,
    String? status,
    int? totalRecipients,
    int? queued,
    int? sending,
    int? sent,
    int? failed,
    int? skipped,
  }) {
    return BroadcastProgress(
      broadcastId: broadcastId ?? this.broadcastId,
      status: status ?? this.status,
      totalRecipients: totalRecipients ?? this.totalRecipients,
      queued: queued ?? this.queued,
      sending: sending ?? this.sending,
      sent: sent ?? this.sent,
      failed: failed ?? this.failed,
      skipped: skipped ?? this.skipped,
    );
  }
}
