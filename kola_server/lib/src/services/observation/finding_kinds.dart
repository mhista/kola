// finding_kinds.dart — the things kola looks for, and how it says them.
//
// ── TEMPLATES, NOT A MODEL ───────────────────────────────────────────
//
// Every sentence here is written by a rule. No model is involved in
// detecting a finding or in wording one, and that is a deliberate choice
// rather than a stopgap:
//
//   • These are FACTS, not judgements. "Beaded headwrap has been out of
//     stock for 6 days" is either true or it is a bug. There is nothing
//     for a model to add except the possibility of being wrong.
//   • They run for every workspace on every sweep. A model call per
//     finding is a recurring cost for output that never varies.
//   • The Overview is the first screen an owner sees each morning. It is
//     the worst place in the product for a plausible-sounding mistake.
//
// The AI hook belongs one layer up, on the single "Top recommendation"
// line that reasons ACROSS findings. That line is designed and
// deliberately not wired — see workspace_sweep_service.dart.
//
// ── WHY WORDING LIVES HERE AND NOT IN THE DASHBOARD ──────────────────
//
// A finding is stored with its title already rendered, because the
// sentence has to match the moment it describes. That means the wording
// has to exist server-side. Keeping it in one file — rather than inline
// in each detector — is what makes it reviewable as a voice rather than
// as scattered string literals.

abstract class FindingKinds {
  // ── Commerce ──────────────────────────────────────────────────────
  static const productOutOfStock = 'product_out_of_stock';
  static const productLowStock = 'product_low_stock';
  static const productMissingPrice = 'product_missing_price';
  static const productMissingPhoto = 'product_missing_photo';

  // ── Conversations ─────────────────────────────────────────────────
  static const conversationEscalated = 'conversation_escalated';
  static const conversationWaiting = 'conversation_waiting';

  // ── Support ───────────────────────────────────────────────────────
  static const ticketOverdue = 'ticket_overdue';
  static const ticketDueSoon = 'ticket_due_soon';

  // ── Knowledge ─────────────────────────────────────────────────────
  static const documentFailed = 'document_failed';
  static const knowledgeEmpty = 'knowledge_empty';

  // ── Setup ─────────────────────────────────────────────────────────
  static const noChannelConnected = 'no_channel_connected';

  /// Severity, 1 = highest.
  ///
  /// ── THE ORDER IS AN OPINION AND IT SHOULD BE ARGUED WITH ─────────
  ///
  /// 1  Someone is waiting on a human. A person is on the other end,
  ///    right now, and every other item can wait a day.
  /// 2  Money is being lost or refused today: a product a customer can
  ///    ask for and not buy.
  /// 3  kola cannot do its job — no channel, nothing learned, a document
  ///    that failed to index. Urgent to the business but not to any one
  ///    customer.
  /// 4  Quality gaps that cost sales quietly: no price, no photo.
  ///
  /// Out-of-stock outranking "kola has learned nothing" is the debatable
  /// one. It is ranked that way because an empty catalog is a state the
  /// owner already knows about, and one product silently unsellable is
  /// not.
  static int severityFor(String kind) => switch (kind) {
        conversationEscalated => 1,
        conversationWaiting => 1,
        // Past its promised deadline outranks approaching one, and both
        // outrank stock. A missed promise to a named customer is the
        // most expensive thing on this list.
        ticketOverdue => 1,
        ticketDueSoon => 2,
        productOutOfStock => 2,
        documentFailed => 3,
        noChannelConnected => 3,
        knowledgeEmpty => 3,
        productLowStock => 3,
        productMissingPrice => 4,
        productMissingPhoto => 4,
        _ => 5,
      };

  /// "6 days", "3 hours", "just now" — the phrase, not a number.
  ///
  /// Rounded DOWN and never to a fraction. "1 day" is a claim an owner
  /// can check against their own memory; "1.4 days" invites them to
  /// wonder what it is counting from, which is the wrong thing to be
  /// thinking about while reading an alert.
  static String since(DateTime from, DateTime now) {
    final d = now.difference(from);
    if (d.inMinutes < 5) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} minutes';
    if (d.inHours < 24) {
      return d.inHours == 1 ? 'an hour' : '${d.inHours} hours';
    }
    final days = d.inDays;
    if (days == 1) return 'a day';
    if (days < 14) return '$days days';
    final weeks = days ~/ 7;
    return weeks == 1 ? 'a week' : '$weeks weeks';
  }

  /// Pluralises without the "1 products" tell.
  static String count(int n, String singular, [String? plural]) =>
      n == 1 ? '1 $singular' : '$n ${plural ?? '${singular}s'}';
}
