// preview_message.dart — one bubble in the WhatsApp-style live preview
// mockup on Chat Mode's plan panel, matching Kola Bot Detail Chat.dc.html's
// previewMsgs. This is a visual mockup only — not the real Conversation/
// Message models from Phase 3's escalation feature (kola_server/lib/src/
// models/conversation.spy.yaml) — those get wired in once this preview
// needs to show a bot's *actual* recent conversation instead of a fixed
// illustrative example.

class PreviewMessage {
  const PreviewMessage({required this.text, required this.mine, required this.time});

  final String text;

  /// true = sent by the business (bot/owner side, right-aligned, green
  /// bubble); false = the customer (left-aligned, dark grey bubble).
  final bool mine;
  final String time;
}
