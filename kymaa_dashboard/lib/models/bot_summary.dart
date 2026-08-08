// bot_summary.dart — the bot identity shown in both Bot Detail headers
// (Chat Mode's icon/name/archetype badge, Structured Mode's icon/name/
// mono-font id). One mock instance exists in this shell pass (see
// pages/bot_detail_chat_page.dart's header comment) — [id] is still a
// real field, not hardcoded away, since it's what the route parameter
// (/bots/:id) actually carries; a real per-id lookup against
// kola_client is Phase 4e+'s job.

class BotSummary {
  const BotSummary({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconBg,
    required this.archetypeLabel,
    required this.channelsLabel,
  });

  final String id;
  final String name;
  final String icon;
  final String iconBg;
  final String archetypeLabel;
  final String channelsLabel;
}
