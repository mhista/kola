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

abstract class KnowledgeChunk
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  KnowledgeChunk._({
    this.id,
    required this.documentId,
    required this.workspaceId,
    required this.chunkIndex,
    required this.content,
    required this.tokenEstimate,
    required this.embeddingModel,
    required this.createdAt,
  });

  factory KnowledgeChunk({
    int? id,
    required int documentId,
    required int workspaceId,
    required int chunkIndex,
    required String content,
    required int tokenEstimate,
    required String embeddingModel,
    required DateTime createdAt,
  }) = _KnowledgeChunkImpl;

  factory KnowledgeChunk.fromJson(Map<String, dynamic> jsonSerialization) {
    return KnowledgeChunk(
      id: jsonSerialization['id'] as int?,
      documentId: jsonSerialization['documentId'] as int,
      workspaceId: jsonSerialization['workspaceId'] as int,
      chunkIndex: jsonSerialization['chunkIndex'] as int,
      content: jsonSerialization['content'] as String,
      tokenEstimate: jsonSerialization['tokenEstimate'] as int,
      embeddingModel: jsonSerialization['embeddingModel'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  int? id;

  int documentId;

  int workspaceId;

  int chunkIndex;

  String content;

  int tokenEstimate;

  String embeddingModel;

  DateTime createdAt;

  /// Returns a shallow copy of this [KnowledgeChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  KnowledgeChunk copyWith({
    int? id,
    int? documentId,
    int? workspaceId,
    int? chunkIndex,
    String? content,
    int? tokenEstimate,
    String? embeddingModel,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'KnowledgeChunk',
      if (id != null) 'id': id,
      'documentId': documentId,
      'workspaceId': workspaceId,
      'chunkIndex': chunkIndex,
      'content': content,
      'tokenEstimate': tokenEstimate,
      'embeddingModel': embeddingModel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'KnowledgeChunk',
      if (id != null) 'id': id,
      'documentId': documentId,
      'workspaceId': workspaceId,
      'chunkIndex': chunkIndex,
      'content': content,
      'tokenEstimate': tokenEstimate,
      'embeddingModel': embeddingModel,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _KnowledgeChunkImpl extends KnowledgeChunk {
  _KnowledgeChunkImpl({
    int? id,
    required int documentId,
    required int workspaceId,
    required int chunkIndex,
    required String content,
    required int tokenEstimate,
    required String embeddingModel,
    required DateTime createdAt,
  }) : super._(
         id: id,
         documentId: documentId,
         workspaceId: workspaceId,
         chunkIndex: chunkIndex,
         content: content,
         tokenEstimate: tokenEstimate,
         embeddingModel: embeddingModel,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [KnowledgeChunk]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  KnowledgeChunk copyWith({
    Object? id = _Undefined,
    int? documentId,
    int? workspaceId,
    int? chunkIndex,
    String? content,
    int? tokenEstimate,
    String? embeddingModel,
    DateTime? createdAt,
  }) {
    return KnowledgeChunk(
      id: id is int? ? id : this.id,
      documentId: documentId ?? this.documentId,
      workspaceId: workspaceId ?? this.workspaceId,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      content: content ?? this.content,
      tokenEstimate: tokenEstimate ?? this.tokenEstimate,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
