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

abstract class ErrandExecutionLog
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ErrandExecutionLog._({
    this.id,
    required this.errandId,
    required this.workspaceId,
    required this.inputJson,
    this.resultJson,
    required this.success,
    this.errorMessage,
    required this.latencyMs,
    required this.executedAt,
  });

  factory ErrandExecutionLog({
    int? id,
    required int errandId,
    required int workspaceId,
    required String inputJson,
    String? resultJson,
    required bool success,
    String? errorMessage,
    required int latencyMs,
    required DateTime executedAt,
  }) = _ErrandExecutionLogImpl;

  factory ErrandExecutionLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return ErrandExecutionLog(
      id: jsonSerialization['id'] as int?,
      errandId: jsonSerialization['errandId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      inputJson: jsonSerialization['inputJson'] as String,
      resultJson: jsonSerialization['resultJson'] as String?,
      success: _i1.BoolJsonExtension.fromJson(jsonSerialization['success']),
      errorMessage: jsonSerialization['errorMessage'] as String?,
      latencyMs: jsonSerialization['latencyMs'] as int,
      executedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['executedAt'],
      ),
    );
  }

  int? id;

  int errandId;

  int workspaceId;

  String inputJson;

  String? resultJson;

  bool success;

  String? errorMessage;

  int latencyMs;

  DateTime executedAt;

  /// Returns a shallow copy of this [ErrandExecutionLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ErrandExecutionLog copyWith({
    int? id,
    int? errandId,
    int? workspaceId,
    String? inputJson,
    String? resultJson,
    bool? success,
    String? errorMessage,
    int? latencyMs,
    DateTime? executedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ErrandExecutionLog',
      if (id != null) 'id': id,
      'errandId': errandId,
      'workspaceId': workspaceId,
      'inputJson': inputJson,
      if (resultJson != null) 'resultJson': resultJson,
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'latencyMs': latencyMs,
      'executedAt': executedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ErrandExecutionLog',
      if (id != null) 'id': id,
      'errandId': errandId,
      'workspaceId': workspaceId,
      'inputJson': inputJson,
      if (resultJson != null) 'resultJson': resultJson,
      'success': success,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'latencyMs': latencyMs,
      'executedAt': executedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ErrandExecutionLogImpl extends ErrandExecutionLog {
  _ErrandExecutionLogImpl({
    int? id,
    required int errandId,
    required int workspaceId,
    required String inputJson,
    String? resultJson,
    required bool success,
    String? errorMessage,
    required int latencyMs,
    required DateTime executedAt,
  }) : super._(
         id: id,
         errandId: errandId,
         workspaceId: workspaceId,
         inputJson: inputJson,
         resultJson: resultJson,
         success: success,
         errorMessage: errorMessage,
         latencyMs: latencyMs,
         executedAt: executedAt,
       );

  /// Returns a shallow copy of this [ErrandExecutionLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ErrandExecutionLog copyWith({
    Object? id = _Undefined,
    int? errandId,
    int? workspaceId,
    String? inputJson,
    Object? resultJson = _Undefined,
    bool? success,
    Object? errorMessage = _Undefined,
    int? latencyMs,
    DateTime? executedAt,
  }) {
    return ErrandExecutionLog(
      id: id is int? ? id : this.id,
      errandId: errandId ?? this.errandId,
      workspaceId: workspaceId ?? this.workspaceId,
      inputJson: inputJson ?? this.inputJson,
      resultJson: resultJson is String? ? resultJson : this.resultJson,
      success: success ?? this.success,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      latencyMs: latencyMs ?? this.latencyMs,
      executedAt: executedAt ?? this.executedAt,
    );
  }
}
