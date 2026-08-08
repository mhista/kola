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

abstract class KnowledgeSearchHit
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  KnowledgeSearchHit._({
    required this.chunkId,
    required this.documentId,
    required this.documentTitle,
    required this.chunkIndex,
    required this.content,
    required this.similarity,
  });

  factory KnowledgeSearchHit({
    required int chunkId,
    required int documentId,
    required String documentTitle,
    required int chunkIndex,
    required String content,
    required double similarity,
  }) = _KnowledgeSearchHitImpl;

  factory KnowledgeSearchHit.fromJson(Map<String, dynamic> jsonSerialization) {
    return KnowledgeSearchHit(
      chunkId: jsonSerialization['chunkId'] as int,
      documentId: jsonSerialization['documentId'] as int,
      documentTitle: jsonSerialization['documentTitle'] as String,
      chunkIndex: jsonSerialization['chunkIndex'] as int,
      content: jsonSerialization['content'] as String,
      similarity: (jsonSerialization['similarity'] as num).toDouble(),
    );
  }

  int chunkId;

  int documentId;

  String documentTitle;

  int chunkIndex;

  String content;

  double similarity;

  /// Returns a shallow copy of this [KnowledgeSearchHit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  KnowledgeSearchHit copyWith({
    int? chunkId,
    int? documentId,
    String? documentTitle,
    int? chunkIndex,
    String? content,
    double? similarity,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'KnowledgeSearchHit',
      'chunkId': chunkId,
      'documentId': documentId,
      'documentTitle': documentTitle,
      'chunkIndex': chunkIndex,
      'content': content,
      'similarity': similarity,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'KnowledgeSearchHit',
      'chunkId': chunkId,
      'documentId': documentId,
      'documentTitle': documentTitle,
      'chunkIndex': chunkIndex,
      'content': content,
      'similarity': similarity,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _KnowledgeSearchHitImpl extends KnowledgeSearchHit {
  _KnowledgeSearchHitImpl({
    required int chunkId,
    required int documentId,
    required String documentTitle,
    required int chunkIndex,
    required String content,
    required double similarity,
  }) : super._(
         chunkId: chunkId,
         documentId: documentId,
         documentTitle: documentTitle,
         chunkIndex: chunkIndex,
         content: content,
         similarity: similarity,
       );

  /// Returns a shallow copy of this [KnowledgeSearchHit]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  KnowledgeSearchHit copyWith({
    int? chunkId,
    int? documentId,
    String? documentTitle,
    int? chunkIndex,
    String? content,
    double? similarity,
  }) {
    return KnowledgeSearchHit(
      chunkId: chunkId ?? this.chunkId,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      content: content ?? this.content,
      similarity: similarity ?? this.similarity,
    );
  }
}
