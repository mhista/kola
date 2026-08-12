// business_memory_page.dart — '/business-memory'.
//
// PHASE 9. Documents the memory layer that replaced Bot.knowledgeSeed.
//
// Numbers here are sourced from the code, not restated from memory:
// PlanLimits.cappedFreeKnowledgeDocumentCap (5),
// PlanLimits.maxDocumentCharacters (200,000),
// MemoryRetrievalService.defaultMaxChunks (6) and
// .defaultMinSimilarity (0.35).
//
// DELIBERATELY AVOIDS the words embedding, vector, chunk, semantic and
// retrieval-augmented — same voice rule the product itself follows. A
// stored passage is a "section", which is the agreed user-facing term
// and matches what the dashboard shows in a citation.
//
// The file-upload limitation is stated plainly rather than omitted:
// the old Knowledge Base design promised PDF/DOCX/XLSX upload, so
// people will arrive expecting it, and saying nothing would read as a
// bug rather than a deliberate scope decision.

import 'package:jaspr/jaspr.dart';
import 'package:jaspr/dom.dart';
import '../components/doc_page_kit.dart';

class BusinessMemoryPage extends StatelessComponent {
  const BusinessMemoryPage();

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      docH1('Business memory'),
      docLede(
        'What your bots know, where it came from, and how to check what they would actually say. '
        'Every answer a bot gives can be traced back to the exact document and section it came '
        'from.',
      ),

      docH2('How it works'),
      docP(
        'You save documents — a return policy, a price list, an FAQ, delivery terms. Kola splits '
        'each one into sections and, when a customer asks something, finds the few sections most '
        'likely to answer it and gives those to the bot. The bot answers from those sections and '
        'nothing else.',
      ),
      docP(
        'That last part is the important one. A bot will say it does not know and offer to fetch '
        'a person rather than invent an answer that is not supported by what you saved.',
      ),

      docH2('What a bot sees for one question'),
      docList([
        'At most 6 sections, chosen by how well they match the question.',
        'Sections that do not match well enough are left out entirely, rather than padding the '
            'answer with something loosely related.',
        'Every section carries its source, so the answer can be traced back to a document you '
            'recognise.',
      ]),
      docNote(
        'This is why the Memory inspector matters: you can type a question a customer actually '
        'asked and see precisely which sections the bot would answer from, with a match score '
        'for each. If an answer was wrong, you can see why rather than guess.',
      ),

      docH2('Limits'),
      docList([
        'Free plan: 5 documents. Paid plans: unlimited.',
        'Any single document: up to 200,000 characters — roughly 60 to 80 pages.',
        'A document must finish processing before a bot can answer from it. This is usually '
            'quick.',
      ]),
      docP(
        'If a document is too large, split it. That is not only a workaround — several focused '
        'documents produce better answers than one large one, because Kola can point at the '
        'right one instead of searching a single enormous file.',
      ),

      docH2('Document states'),
      docList([
        'Ready — searchable, and your bots are using it.',
        'Processing — saved, not yet searchable. Usually brief.',
        'Failed — saved, but your bots cannot see it. The reason is shown on the document, and '
            'this is worth acting on: the document exists in your list, so it is easy to assume '
            'the bot knows something it does not.',
      ]),
      docWarning(
        'A failed document is the one state worth checking for. Everything looks normal — the '
        'document is in your list — but no bot can answer from it.',
      ),

      docH2('Duplicates'),
      docP(
        'If you save text identical to something already stored, Kola says so and names the '
        'existing document rather than quietly creating a second copy. You can save it anyway if '
        'that is what you meant — occasionally the same policy genuinely applies to two product '
        'lines and it makes sense to have both.',
      ),

      docH2('File upload'),
      docP(
        'Kola currently accepts text you paste in, not uploaded files. This is deliberate rather '
        'than unfinished: pulling text out of a PDF reliably is harder than it looks, and a '
        'scanned or image-based PDF produces nothing usable at all. Saving that would mean your '
        'bot confidently answering from nonsense, which is worse than not accepting the file.',
      ),
      docP(
        'For now, open the document, copy the text, and paste it in. File support is planned.',
      ),

      docH2('If memory is unavailable'),
      docP(
        'If the service that processes knowledge cannot be reached, bots fall back to the older, '
        'simpler knowledge attached to each bot. They keep answering — they just know less until '
        'it recovers. Nothing you saved is lost.',
      ),
    ]);
  }
}
