// knowledge_endpoint.dart
//
// PHASE 9 (Layer 2 — Business Memory). The authenticated, workspace-
// scoped surface for a business's long-term memory: add a document,
// list what's stored, delete one, and search memory directly.
//
// WHY A NEW ENDPOINT RATHER THAN MORE METHODS ON BotEndpoint:
//   BotEndpoint.setKnowledgeSeed exists because knowledge USED to be a
//   property of one bot. It isn't any more — knowledge_document.spy.yaml
//   is workspace-scoped, shared by every bot and (later) every
//   specialized agent in the workspace. Hanging workspace-scoped memory
//   off a bot-scoped endpoint would encode exactly the wrong ownership
//   model in the API, and every caller would then have to pass a botId
//   that is genuinely irrelevant to the operation.
//
//   BotEndpoint.setKnowledgeSeed is deliberately LEFT ALONE and still
//   works — see bot_knowledge_service.dart's header on why the seed
//   remains a live fallback rather than something to rip out today.
//
// EVERY METHOD CALLS requireWorkspaceAccess FIRST, same as every other
// endpoint in this project (SRS.md §5). The workspaceId a caller passes
// is validated against their token before it reaches any repository —
// it is never trusted as an identifier on its own.

import 'dart:convert';
import 'dart:typed_data';
import 'package:kola_server/src/services/documents/xlsx_extractor.dart';
import 'package:serverpod/serverpod.dart';
import 'package:kola_server/src/generated/protocol.dart';
import 'package:kola_server/src/config/dependency_injection.dart';
import 'package:kola_server/src/services/assistant/workspace_answer_service.dart';
import 'package:kola_server/src/services/auth/workspace_access.dart';
import 'package:kola_server/src/services/billing/plan_limits.dart';
import 'package:kola_server/src/services/billing/trial_state_machine.dart';
import 'package:kola_server/src/services/memory/document_ingestion_service.dart';
import 'package:kola_server/src/services/memory/memory_retrieval_service.dart';
import 'package:kola_server/src/services/repository/knowledge_document_repository.dart';
import 'package:kola_server/src/services/repository/workspace_repository.dart';
import 'package:kola_server/kola_logger.dart';

class KnowledgeEndpoint extends Endpoint {
  DocumentIngestionService get _ingestion => getIt<DocumentIngestionService>();
  MemoryRetrievalService get _retrieval => getIt<MemoryRetrievalService>();
  KnowledgeDocumentRepository get _documents => getIt<KnowledgeDocumentRepository>();
  WorkspaceRepository get _workspaces => getIt<WorkspaceRepository>();
  TrialStateMachine get _trialStateMachine => getIt<TrialStateMachine>();

  /// Every document in the workspace, newest first.
  Future<List<KnowledgeDocument>> listDocuments(
    Session session,
    String accessToken,
    int workspaceId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );
    return _documents.listByWorkspace(workspaceId);
  }

  /// Ingests [text] as a new document: dedupe, chunk, embed, index.
  ///
  /// THROWS with an owner-readable message on every non-success path
  /// (duplicate, empty, quota exhausted, embeddings unconfigured) rather
  /// than returning a status object. That's the convention every other
  /// endpoint in this codebase already follows, and it keeps the
  /// generated client's return type honest — a KnowledgeDocument here
  /// always means a document that is actually searchable.
  ///
  /// The one place that's a slightly awkward fit is 'duplicate', which
  /// isn't really an error. The message says so plainly and names the
  /// existing document, so the dashboard can offer "save it anyway"
  /// (which calls this again with [allowDuplicate] true) rather than
  /// presenting a dead end.
  Future<KnowledgeDocument> addDocument(
    Session session,
    String accessToken,
    int workspaceId,
    String title,
    String text, {
    bool allowDuplicate = false,
  }) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    if (text.trim().isEmpty) {
      throw KolaException(message: 'There\'s no text to save.');
    }

    // Sanity bound before anything expensive happens — see
    // PlanLimits.maxDocumentCharacters on why this isn't a plan limit.
    if (text.length > PlanLimits.maxDocumentCharacters) {
      throw KolaException(
        message:         'That document is too large (${text.length} characters). The limit '
        'is ${PlanLimits.maxDocumentCharacters}. Split it into a few '
        'smaller documents — that also makes the bot\'s answers more '
        'accurate, since it can point at the right one.',
      );
    }

    // Plan cap, checked BEFORE ingestion so a rejected document never
    // burns embedding quota.
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace != null) {
      final tier = _trialStateMachine.effectiveTier(workspace);
      if (tier == EffectiveTier.cappedFree || tier == EffectiveTier.paused) {
        final existing = await _documents.countByWorkspace(workspaceId);
        if (existing >= PlanLimits.cappedFreeKnowledgeDocumentCap) {
          throw KolaException(
        message:             'This workspace is on the free plan, which stores up to '
            '${PlanLimits.cappedFreeKnowledgeDocumentCap} knowledge documents. '
            'Delete one, or upgrade to add more.',
          );
        }
      }
    }

    final result = await _ingestion.ingestText(
      workspaceId: workspaceId,
      title: title,
      text: text,
      sourceType: 'paste',
      allowDuplicate: allowDuplicate,
    );

    if (result.isSuccess) {
      Log.success(
        'Indexed knowledge document "${result.document?.title}" '
        '(${result.chunkCount} chunks) for workspace $workspaceId',
        session: session,
      );
      return result.document!;
    }

    throw KolaException(message: result.message ?? 'Could not save that document.');
  }

  /// Removes a document from memory. Its chunks go with it via ON DELETE
  /// CASCADE (migration 017), so the bot genuinely stops knowing this —
  /// there is no path that leaves retrievable chunks behind.
  Future<void> deleteDocument(
    Session session,
    String accessToken,
    int workspaceId,
    int documentId,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _documents.findByIdScoped(documentId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'That document doesn\'t exist in this workspace.');
    }

    await _documents.deleteScoped(documentId, workspaceId);
    Log.success(
      'Deleted knowledge document $documentId '
      '("${existing.title}") from workspace $workspaceId',
      session: session,
    );
  }

  /// Replaces an existing document's content in place, keeping its id.
  Future<KnowledgeDocument> updateDocument(
    Session session,
    String accessToken,
    int workspaceId,
    int documentId,
    String title,
    String text,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    if (text.length > PlanLimits.maxDocumentCharacters) {
      throw KolaException(
        message:         'That document is too large. The limit is '
        '${PlanLimits.maxDocumentCharacters} characters.',
      );
    }

    final result = await _ingestion.reindex(
      workspaceId: workspaceId,
      documentId: documentId,
      title: title,
      text: text,
    );

    if (result.isSuccess) return result.document!;
    throw KolaException(message: result.message ?? 'Could not update that document.');
  }

  /// Toggles whether this document feeds the bot's answers, without
  /// deleting it — see knowledge_document.spy.yaml's feedingEnabled
  /// comment and migration 061's header for why this exists as a
  /// separate switch from status/supersededBy.
  ///
  /// Both retrieval RPCs (migration 061) filter on the column this
  /// writes, so disabling here genuinely stops kola answering from the
  /// document — this is not a dashboard-only label.
  Future<KnowledgeDocument> setFeedingEnabled(
    Session session,
    String accessToken,
    int workspaceId,
    int documentId,
    bool enabled,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final existing = await _documents.findByIdScoped(documentId, workspaceId);
    if (existing == null) {
      throw KolaException(message: 'That document doesn\'t exist in this workspace.');
    }

    final updated = await _documents.setFeedingEnabled(
      id: documentId,
      workspaceId: workspaceId,
      enabled: enabled,
    );

    Log.success(
      'Set feedingEnabled=$enabled for knowledge document $documentId '
      '("${existing.title}") in workspace $workspaceId',
      session: session,
    );

    return updated;
  }

  /// Runs a real memory search and returns what the bot WOULD retrieve
  /// for [query], scores included.
  ///
  /// This is an inspection tool, and it is the reason
  /// knowledge_search_hit.spy.yaml exists — see that file's header. An
  /// owner can type a question a customer actually asked and see exactly
  /// which passages ground the answer, rather than having to trust the
  /// bot or argue with it.
  Future<List<KnowledgeSearchHit>> searchMemory(
    Session session,
    String accessToken,
    int workspaceId,
    String query,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final context = await _retrieval.retrieve(
      workspaceId: workspaceId,
      query: query,
    );

    return [
      for (final match in context.matches)
        KnowledgeSearchHit(
          chunkId: match.chunkId,
          documentId: match.documentId,
          documentTitle: match.documentTitle,
          chunkIndex: match.chunkIndex,
          content: match.content,
          similarity: match.similarity,
        ),
    ];
  }

  /// Answers a question the OWNER typed, in prose, with the products it
  /// refers to and what they might do next.
  ///
  /// ── HOW THIS DIFFERS FROM searchMemory ABOVE ───────────────────────
  ///
  /// searchMemory is an INSPECTION tool: it returns passages and scores
  /// so an owner can audit what the bot would ground an answer on. It
  /// was also, until now, what the Overview's "Ask kola" box called —
  /// which meant that box printed raw document text and no answer at
  /// all. Two different jobs were being done by one method, and the
  /// wrong one won.
  ///
  /// Both are kept. The Memory Inspector still wants searchMemory
  /// exactly as it is; this is the one that answers.
  ///
  /// Never throws for an unanswerable question — see
  /// WorkspaceAnswerService. A question during a provider outage returns
  /// `generated: false` and an honest sentence, because an owner asking
  /// their own dashboard a question should not be shown a stack trace.
  Future<WorkspaceAnswer> askWorkspace(
    Session session,
    String accessToken,
    int workspaceId,
    String question,
  ) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    return getIt<WorkspaceAnswerService>().ask(
      workspaceId: workspaceId,
      question: question,
    );
  }

  /// Adds a document from an uploaded FILE rather than pasted text.
  ///
  /// ── WHY THE BYTES COME THROUGH THE SERVER, UNLIKE PHOTOS ───────────
  ///
  /// Product photos deliberately bypass this server: they are megabytes,
  /// they need a progress bar, and base64 through a Serverpod parameter
  /// would send them twice (see imagekit_service.dart).
  ///
  /// A spreadsheet is the opposite case on every count. A price list is
  /// tens of kilobytes, it needs no progress bar, and the extraction it
  /// requires — unzipping and parsing OOXML — belongs on a server rather
  /// than in every browser's bundle. So this one proxies, and that is
  /// the right call for this shape of file specifically.
  ///
  /// [base64Bytes] is the raw file. Serverpod parameters are JSON, so
  /// binary has to be encoded; at this size the ~33% overhead is not
  /// worth engineering around.
  Future<KnowledgeDocument> addDocumentFromFile(
    Session session,
    String accessToken,
    int workspaceId,
    String fileName,
    String base64Bytes, {
    bool allowDuplicate = false,
  }) async {
    await requireWorkspaceAccess(
      accessToken: accessToken,
      workspaceId: workspaceId,
    );

    final Uint8List bytes;
    try {
      bytes = base64Decode(base64Bytes);
    } catch (_) {
      throw KolaException(
        message: 'That file did not arrive intact. Please try again.',
      );
    }

    // A hard ceiling here as well as in the browser. The browser check
    // is a courtesy; this one is the actual limit, because an endpoint
    // is reachable without going through the browser at all.
    if (bytes.length > 20 * 1024 * 1024) {
      throw KolaException(
        message: 'That file is too large. Split it into a few smaller ones — '
            'that also makes kola\'s answers more accurate, since it can '
            'point at the right part.',
      );
    }

    final lower = fileName.toLowerCase();
    final String text;

    if (lower.endsWith('.xlsx') || lower.endsWith('.xlsm')) {
      final extracted = XlsxExtractor.extract(bytes);
      if (extracted == null || extracted.trim().isEmpty) {
        throw KolaException(
          message: 'kola could not read anything out of that spreadsheet. If '
              'it opens correctly in Excel, save it again as .xlsx and try '
              'once more.',
        );
      }
      text = extracted;
    } else if (lower.endsWith('.xls')) {
      // The OLD binary format, which is a completely different thing
      // from .xlsx and needs a different reader entirely. Named
      // explicitly so the owner knows the fix is one Save As away.
      throw KolaException(
        message: 'That is the older Excel format. Open it and use Save As → '
            'Excel Workbook (.xlsx), then upload it again.',
      );
    } else if (lower.endsWith('.pdf')) {
      throw KolaException(
        message: 'kola cannot read PDFs yet. If the same information is in a '
            'spreadsheet or a document you can copy from, that works today.',
      );
    } else if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
      throw KolaException(
        message: 'kola cannot read Word files yet. Copy the text and paste it '
            'in — it will be learned the same way.',
      );
    } else if (lower.endsWith('.csv') || lower.endsWith('.tsv')) {
      // Gate 6 (Kolaa Rev 5, Part VIII, "Level 1b proven"). A CSV/TSV
      // already reached this method before this branch existed — the
      // plain-text ELSE below decoded it fine, and it ingested. What was
      // missing is the same fix GoogleSheetsAdapter.
      // _ingestIntoKnowledgeBase (google_sheets_adapter.dart) already
      // needed for the identical reason: hybrid_match_knowledge_chunks'
      // keyword side matches on chunk CONTENT, and raw delimited rows
      // carry no natural-language words — "Blue Ankara,3500,12" cannot
      // be found by a query like "price of the blue ankara" without
      // "price" (or a column name near it) appearing somewhere in the
      // chunk. Prepending one sentence naming the columns fixes that.
      // See _withCsvPreamble's own header on why this does not attempt
      // to reformat every row.
      final decoded = utf8.decode(bytes, allowMalformed: true);
      text = _withCsvPreamble(decoded, title: _titleFrom(fileName));
    } else {
      // Plain text of some kind. Decoded permissively: a price list
      // saved from a Windows machine is often not valid UTF-8, and
      // refusing it over one bad byte would be absurd.
      text = utf8.decode(bytes, allowMalformed: true);
    }

    // Straight into the normal path, so a spreadsheet is chunked,
    // embedded, cited and editable exactly like pasted text. No second
    // kind of document, and nothing special-cased at answer time.
    return addDocument(
      session,
      accessToken,
      workspaceId,
      _titleFrom(fileName),
      text,
      allowDuplicate: allowDuplicate,
    );
  }

  /// A readable title from a filename: "price-list-2026.xlsx" becomes
  /// "price list 2026". The extension and separators are noise to the
  /// person reading a citation later.
  String _titleFrom(String fileName) {
    // '\\' and NOT r'\' — a raw string cannot END in a backslash, so
    // r'\' is a compile error rather than a one-character string. The
    // split handles Windows paths, which is where an uploaded file name
    // usually comes from.
    var name = fileName.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    return name.isEmpty ? 'Uploaded document' : name;
  }

  /// Prepends one natural-language sentence naming [rawText]'s columns —
  /// see the Gate 6 comment at this method's only call site
  /// (addDocumentFromFile) for why. Reads only the first line, and only
  /// well enough to guess a delimiter (tab if the first line has a tab
  /// and no comma, comma otherwise) and split it into column names.
  ///
  /// DELIBERATELY NOT A REAL CSV PARSER: a naive split breaks on a
  /// quoted field that itself contains the delimiter ("Smith, John" as
  /// one cell, say) — this project has no `csv` package dependency to
  /// parse that correctly yet, and this method only touches the header
  /// line to build one descriptive sentence, never the data rows
  /// themselves, so a mis-split header degrades to a slightly odd
  /// preamble, not corrupted data. Best-effort: any header that can't
  /// be read this way returns [rawText] completely unchanged rather
  /// than blocking the upload over a cosmetic improvement.
  static String _withCsvPreamble(String rawText, {required String title}) {
    final firstLineEnd = rawText.indexOf('\n');
    final firstLine = (firstLineEnd == -1 ? rawText : rawText.substring(0, firstLineEnd)).trim();
    if (firstLine.isEmpty) return rawText;

    final delimiter = firstLine.contains('\t') && !firstLine.contains(',') ? '\t' : ',';
    final columns = firstLine
        .split(delimiter)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (columns.isEmpty) return rawText;

    final preamble = 'This is data from the file "$title". Columns: ${columns.join(', ')}.\n\n';
    return '$preamble$rawText';
  }
}
