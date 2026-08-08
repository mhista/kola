// knowledge_chunk_dto.dart
//
// Translates between:
//   Serverpod model  → KnowledgeChunk (generated/knowledge_chunk.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: knowledge_chunks
// Schema: docs/migrations/017_business_memory.sql (Phase 9 / Layer 2).
//
// THE `embedding` COLUMN IS ABSENT FROM BOTH DIRECTIONS, ON PURPOSE.
// knowledge_chunk.spy.yaml's header explains why the vector is not a
// model field; the consequence lands here. [fromRow] never reads it
// (retrieval goes through the match_knowledge_chunks RPC, which returns
// content and similarity, not the raw vector), and [toRow] never writes
// it — KnowledgeChunkRepository.insertChunks merges the vector into the
// row map itself, as a separate argument. If this DTO ever appears to
// "lose" the embedding, that is the design, not a bug.

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class KnowledgeChunkDto extends BaseDto<KnowledgeChunk> {
  const KnowledgeChunkDto();

  @override
  KnowledgeChunk fromRow(Map<String, dynamic> row) {
    return KnowledgeChunk(
      id: row['id'] as int?,
      documentId: row['document_id'] as int,
      workspaceId: row['workspace_id'] as int,
      chunkIndex: row['chunk_index'] as int,
      content: row['content'] as String,
      tokenEstimate: row['token_estimate'] as int,
      embeddingModel: row['embedding_model'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(KnowledgeChunk model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'document_id': model.documentId,
      'workspace_id': model.workspaceId,
      'chunk_index': model.chunkIndex,
      'content': model.content,
      'token_estimate': model.tokenEstimate,
      'embedding_model': model.embeddingModel,
    };
  }
}
