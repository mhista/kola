// faq_item.dart
//
// Plain data holder for one FAQ entry. Copy matches Kola Landing.dc.html's
// faqDefs, addressing the Nigeria-specific concerns DESIGN_PROMPT.md §1
// called out (developer requirement, own-database support, trial
// behavior, dual-channel support).

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
