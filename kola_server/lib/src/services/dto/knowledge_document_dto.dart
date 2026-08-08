// knowledge_document_dto.dart
//
// Translates between:
//   Serverpod model  → KnowledgeDocument (generated/knowledge_document.dart)
//   Supabase row     → Map<String, dynamic>
//
// Supabase table: knowledge_documents
// Schema: docs/migrations/017_business_memory.sql (Phase 9 / Layer 2).

import 'package:kola_server/src/generated/protocol.dart';
import 'base_dto.dart';

class KnowledgeDocumentDto extends BaseDto<KnowledgeDocument> {
  const KnowledgeDocumentDto();

  @override
  KnowledgeDocument fromRow(Map<String, dynamic> row) {
    return KnowledgeDocument(
      id: row['id'] as int?,
      workspaceId: row['workspace_id'] as int,
      title: row['title'] as String,
      sourceType: row['source_type'] as String,
      sourceRef: row['source_ref'] as String?,
      contentHash: row['content_hash'] as String,
      rawText: row['raw_text'] as String,
      status: row['status'] as String,
      chunkCount: row['chunk_count'] as int,
      errorMessage: row['error_message'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toRow(KnowledgeDocument model, {bool includeId = false}) {
    return {
      if (includeId && model.id != null) 'id': model.id,
      'workspace_id': model.workspaceId,
      'title': model.title,
      'source_type': model.sourceType,
      'source_ref': model.sourceRef,
      'content_hash': model.contentHash,
      'raw_text': model.rawText,
      'status': model.status,
      'chunk_count': model.chunkCount,
      'error_message': model.errorMessage,
      'updated_at': model.updatedAt.toIso8601String(),
    };
  }
}
