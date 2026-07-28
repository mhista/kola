# Internal Alignment Deck Design Prompt — For Team & Advisors

**Audience:** you, a future co-founder/hire, or an advisor — anyone who needs to get aligned on where this actually stands, not be sold on it. This deck should read as candid working material, closer to a strategy memo turned into slides than a pitch. It's fine, even preferable, for this deck to show open questions and unresolved risk rather than a polished, confident story — that's the point of an internal deck.

**Brand & visual direction:** far lighter design investment than the other three decks — this can be built quickly, close to a plain slide template with the brand's color/type applied for consistency, but without the illustration/mockup polish the customer and investor decks need. Content clarity matters far more than visual craft here.

## Slide-by-Slide Structure (10–12 slides)

### Slide 1 — Where We Are, Honestly
One slide, plain text: pre-launch, no users, no funding secured, working technical foundation (Asami, Degenbot), a completed PRD/SRS/competitive analysis, MVP1 not yet started in code. State it flatly — this deck exists to align on reality, not to perform confidence.

### Slide 2 — The Bet We're Making
The core thesis in a few sentences: Nigerian SMEs are already living on WhatsApp/Telegram with no tooling built for how they actually operate (conversational, not flow-chart-based; Naira-priced; dev-extensible without requiring dev skill to start). Pulled from `PRD.md` §1–2, but said more plainly, as a bet, not a pitch.

### Slide 3 — What's Actually Built vs. Not
A simple two-column list: built (Asami, Degenbot, botigo scaffold, all planning docs) vs. not built (any MVP1 code, the actual bot runtime, the dashboard, Meta Tech Provider registration). This is the slide that keeps everyone honest about where real work starts.

### Slide 4 — The Competitive Reality Check
The AppEdge Sabi finding, stated candidly, not softened for outside eyes: a small, real competitor already ships a very close version of the MVP1 experience, including the in-app Meta connect flow. What that changes about urgency and what it doesn't change about the actual differentiation (Errand system, dual interface, Telegram support, catalog/negotiation bot) — pulled from `COMPETITIVE_FEATURES.md` §0–1, but framed for internal decision-making rather than persuasion.

### Slide 5 — Key Open Decisions (the actual point of this deck)
A punch list, not prose: whether/how much friends & family funding to take, numbers-provisioning strategy (deferred, revenue-gated per `META_CONNECT_FLOW.md` §3a/§6), and anything else genuinely undecided at the time this deck is built. This slide should change every time it's presented — it's a living list, not a fixed artifact.

### Slide 6 — Risks We're Carrying
Pulled from `PRD.md` §12, but said more bluntly for an internal audience: WhatsApp approval/verification timeline risk, Meta fee margin pressure, the risk of a non-technical user creating an unsafe or malformed Errand, scope creep before MVP1 ships. Naming these plainly to a co-founder/advisor is more useful than a sanitized risk slide.

### Slide 7 — Architecture, One Slide
A simplified version of the `SRS.md` §4 system diagram — enough for a technical advisor or future hire to orient quickly, not the full spec.

### Slide 8 — Roadmap & Phase Gates
The Phase 1/2/3 structure from `PRD.md` §7, with the revenue-gated items (`COMPETITIVE_FEATURES.md` §3, numbers-provisioning) marked distinctly from calendar-scheduled items — this distinction matters more internally than externally, since it's the difference between "we're behind schedule" and "we're correctly waiting for a precondition."

### Slide 9 — What We Need Help With
Specific, not generic: e.g. a second engineer, a Nigerian legal/regulatory contact for the NCC and Terms of Service review flagged in `TERMS_OF_SERVICE.md`/`PRIVACY_POLICY.md`, an intro to a first pilot SME. Whatever's actually true and current when this is presented.

### Slide 10 — Timeline / Near-Term Milestones
The next 3–4 concrete milestones (e.g. Meta App Review submitted, first Errand type working end-to-end, first pilot business live, waitlist live per `LANDING_PAGE_WAITLIST_PROMPT.md`) with realistic, not aspirational, dates.

### Slide 11 — Discussion Topics
End on questions, not conclusions — whatever genuinely needs a decision in the room (e.g. "do we commit to a brand name this week or wait for a trademark check?").
