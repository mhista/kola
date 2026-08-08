// channel_card_summary.dart — one card in Structured Mode's Channels
// tab, matching Kola Bot Detail Dev.dc.html's channelCards.
//
// One deliberate small deviation from the design file: its markup
// hardcodes the same green (#7ED8B0) for the status text on BOTH cards
// — "● Connected — +234..." and "Not connected" render in the same
// green, which reads as a design-tool mock-data oversight rather than
// an intentional choice (a disconnected channel showing green reads
// wrong). [statusColor] is a real per-card field here so "Not
// connected" can render muted instead — everything else matches the
// design verbatim.

class ChannelCardSummary {
  const ChannelCardSummary({
    required this.icon,
    required this.name,
    required this.status,
    required this.statusColor,
  });

  final String icon;
  final String name;
  final String status;
  final String statusColor;
}
