// errand_chat_summary.dart — one row in Chat Mode's plan panel errand
// list (name + status pill only — no schema/fulfillment detail, that's
// Structured Mode's job via ErrandRow). [statusLabel] is kept separate
// from [status] because Chat Mode's own design copy for the
// needs-input case ("Needs your input") differs from Structured Mode's
// ("Needs input") for the identical status color — see
// models/errand_status.dart's header for why the color is shared but
// the wording isn't.

import 'errand_status.dart';

class ErrandChatSummary {
  const ErrandChatSummary({
    required this.name,
    required this.statusLabel,
    required this.status,
  });

  final String name;
  final String statusLabel;
  final ErrandStatus status;
}
