// errand_status.dart — the three status pill colors shared by both the
// Chat Mode plan panel and the Structured Mode errands table, matching
// Kola Bot Detail Chat.dc.html / Kola Bot Detail Dev.dc.html's
// identical bg/color pairs for each status (confirmed the same hex
// pairs appear in both design files' inline data, not independently
// re-derived here). Display label text is kept separate per call site
// (see ErrandChatSummary/ErrandRow) since the two designs use slightly
// different copy for the same status ("Needs your input" vs. "Needs
// input") — the color is the shared part, the wording isn't.

enum ErrandStatus { live, draft, needsInput }

extension ErrandStatusColors on ErrandStatus {
  String get bg => switch (this) {
    ErrandStatus.live => '#12261F',
    ErrandStatus.draft => '#2A2622',
    ErrandStatus.needsInput => '#2A1F16',
  };

  String get color => switch (this) {
    ErrandStatus.live => '#7ED8B0',
    ErrandStatus.draft => '#B9B3AC',
    ErrandStatus.needsInput => '#F0B08C',
  };
}
