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

abstract class KnowledgeDocument
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  KnowledgeDocument._({
    this.id,
    required this.workspaceId,
    required this.title,
    required this.sourceType,
    this.sourceRef,
    required this.contentHash,
    required this.rawText,
    required this.status,
    required this.chunkCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KnowledgeDocument({
    int? id,
    required int workspaceId,
    required String title,
    required String sourceType,
    String? sourceRef,
    required String contentHash,
    required String rawText,
    required String status,
    required int chunkCount,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _KnowledgeDocumentImpl;

  factory KnowledgeDocument.fromJson(Map<String, dynamic> jsonSerialization) {
    return KnowledgeDocument(
      id: jsonSerialization['id'] as int?,
      workspaceId: jsonSerialization['workspaceId'] as int,
      title: jsonSerialization['title'] as String,
      sourceType: jsonSerialization['sourceType'] as String,
      sourceRef: jsonSerialization['sourceRef'] as String?,
      contentHash: jsonSerialization['contentHash'] as String,
      rawText: jsonSerialization['rawText'] as String,
      status: jsonSerialization['status'] as String,
      chunkCount: jsonSerialization['chunkCount'] as int,
      errorMessage: jsonSerialization['errorMessage'] as String?,
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

  String title;

  String sourceType;

  String? sourceRef;

  String contentHash;

  String rawText;

  String status;

  int chunkCount;

  String? errorMessage;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [KnowledgeDocument]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  KnowledgeDocument copyWith({
    int? id,
    int? workspaceId,
    String? title,
    String? sourceType,
    String? sourceRef,
    String? contentHash,
    String? rawText,
    String? status,
    int? chunkCount,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'KnowledgeDocument',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'title': title,
      'sourceType': sourceType,
      if (sourceRef != null) 'sourceRef': sourceRef,
      'contentHash': contentHash,
      'rawText': rawText,
      'status': status,
      'chunkCount': chunkCount,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'KnowledgeDocument',
      if (id != null) 'id': id,
      'workspaceId': workspaceId,
      'title': title,
      'sourceType': sourceType,
      if (sourceRef != null) 'sourceRef': sourceRef,
      'contentHash': contentHash,
      'rawText': rawText,
      'status': status,
      'chunkCount': chunkCount,
      if (errorMessage != null) 'errorMessage': errorMessage,
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

class _KnowledgeDocumentImpl extends KnowledgeDocument {
  _KnowledgeDocumentImpl({
    int? id,
    required int workspaceId,
    required String title,
    required String sourceType,
    String? sourceRef,
    required String contentHash,
    required String rawText,
    required String status,
    required int chunkCount,
    String? errorMessage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         workspaceId: workspaceId,
         title: title,
         sourceType: sourceType,
         sourceRef: sourceRef,
         contentHash: contentHash,
         rawText: rawText,
         status: status,
         chunkCount: chunkCount,
         errorMessage: errorMessage,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [KnowledgeDocument]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  KnowledgeDocument copyWith({
    Object? id = _Undefined,
    int? workspaceId,
    String? title,
    String? sourceType,
    Object? sourceRef = _Undefined,
    String? contentHash,
    String? rawText,
    String? status,
    int? chunkCount,
    Object? errorMessage = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KnowledgeDocument(
      id: id is int? ? id : this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      sourceRef: sourceRef is String? ? sourceRef : this.sourceRef,
      contentHash: contentHash ?? this.contentHash,
      rawText: rawText ?? this.rawText,
      status: status ?? this.status,
      chunkCount: chunkCount ?? this.chunkCount,
      errorMessage: errorMessage is String? ? errorMessage : this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
