// chat_message.dart — one bubble in the Chat Mode transcript, matching
// Kola Bot Detail Chat.dc.html's three message variants (plain text,
// a checklist of proposed Errands, an image-upload prompt card).
// Avatar/bubble colors aren't stored per-message — they're always one
// of exactly two fixed styles (bot vs. user), so ChatTranscript derives
// them from [fromUser] directly against KolaDashboardColors rather than
// duplicating the same two color pairs on every message instance.

enum ChatMessageVariant { plain, checklist, imageCard }

class ChatMessage {
  const ChatMessage.bot({
    required this.text,
    this.variant = ChatMessageVariant.plain,
    this.items = const [],
    this.imageLabel,
  }) : fromUser = false;

  const ChatMessage.user({required this.text})
    : fromUser = true,
      variant = ChatMessageVariant.plain,
      items = const [],
      imageLabel = null;

  final bool fromUser;
  final ChatMessageVariant variant;
  final String text;

  /// Only meaningful when [variant] is [ChatMessageVariant.checklist].
  final List<String> items;

  /// Only meaningful when [variant] is [ChatMessageVariant.imageCard].
  final String? imageLabel;
}
