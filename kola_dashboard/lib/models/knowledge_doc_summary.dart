// knowledge_doc_summary.dart — one card in Structured Mode's Knowledge
// tab, matching Kola Bot Detail Dev.dc.html's knowledgeDocs. Mock data
// in this shell pass — real data (a bot's actual uploaded documents,
// parsed via Phase 3's Document Parsing Engine per SRS.md §8) is
// Phase 4e's Knowledge Base page job; this tab just links out to it.

class KnowledgeDocSummary {
  const KnowledgeDocSummary({required this.icon, required this.name, required this.status});

  final String icon;
  final String name;
  final String status;
}
