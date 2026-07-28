# Partner Deck Design Prompt — For Agencies, BSPs & Distribution Partners

**Audience:** two related but distinct groups, worth naming which one before building this — (a) **digital agencies** who already manage WhatsApp/social presence for multiple SME clients and could resell or bundle Kola into their service, or (b) **infrastructure partners** (a BSP like 360dialog/Gupshup/Twilio, or a Nigerian numbers/messaging provider like Termii/Sendchamp per `META_CONNECT_FLOW.md` §6) who'd integrate with or provide services to Kola. The structure below is written primarily for **(a) agencies**, since that's the nearer-term, self-serve partnership (`PRD.md` §7 Phase 2 — agency/reseller multi-workspace management); flag if you actually need the infrastructure-partner version instead, since the pitch is meaningfully different (less "resell this to your clients," more "let's integrate our platforms").

**Brand & visual direction:** same brand base as the other decks, but pitched more like a B2B platform deck than either the investor or customer deck — more comfortable showing real architecture/dashboard detail (Errand system, dual dev/non-dev interface) since agency technical staff are a plausible audience. Slightly more restrained/professional than the customer deck, slightly warmer and less financial than the investor deck.

## Slide-by-Slide Structure (10–12 slides)

### Slide 1 — Cover
Positioning line aimed at the partner, not the end customer: *"The WhatsApp/Telegram bot platform built for the agencies managing SME clients, not around them."*

### Slide 2 — The Opportunity For You
Name the pain an agency already has: they're manually managing WhatsApp presence, content, and customer replies across multiple clients today, with no leverage — every client is linear headcount. Position Kola as the leverage layer: one platform, many client workspaces, each isolated and billable.

### Slide 3 — What Kola Actually Is
A tighter version of `PRD.md` §5's core concept — Bot Mother, Errand, Workspace — pitched as infrastructure the agency operates on behalf of clients, not a tool their clients use directly (though it can be either, worth stating explicitly that both models are supported).

### Slide 4 — Multi-Workspace Management
The agency/reseller tier from `PRD.md` §7 Phase 2: one agency account, many isolated client workspaces, a workspace-switcher, usage/billing visibility per client. This is the single most important slide for this audience — it's the concrete "why us over doing this manually" answer.

### Slide 5 — The Dual Interface (why this matters for an agency specifically)
An agency likely has both non-technical account managers and at least one developer on staff. Show how the same Errand/bot can be set up conversationally by an account manager and extended via API by a developer — this directly maps to how an agency team is actually structured, more so than it maps to a single SME owner.

### Slide 6 — White-Label (roadmap, not current — say so plainly)
The Phase 3 white-labeling item from `PRD.md` §7 — present honestly as "on the roadmap, not available today," since overpromising this to a partner evaluating a commitment is the fastest way to lose credibility with exactly the audience that will ask hard follow-up questions.

### Slide 7 — Revenue Model For Partners
However this is actually decided (revenue share, wholesale/resell margin, or flat referral fee) — if not yet decided, this slide should say *"Partner economics — to be finalized together"* rather than inventing a split. Leave it as a discussion slide, not a fabricated number, matching the same honesty standard applied to the investor deck's ask slide.

### Slide 8 — Example Scenario
A concrete walkthrough: an agency managing 12 client bots, showing the workspace-switcher, aggregated usage view, and what changes for their day-to-day operations. If a real pilot doesn't exist yet, frame this as "how this would work," clearly hypothetical, not a case study.

### Slide 9 — Roadmap (shared credibility)
The same phase structure from `PRD.md`/`COMPETITIVE_FEATURES.md`, condensed — shows the partner this is a planned, disciplined build, not an idea that showed up yesterday.

### Slide 10 — What We're Looking For From Partners
Be specific: pilot clients to test with, feedback on the agency workflow before it's finalized, and/or co-marketing — whichever is actually true. Vague "let's partner" asks read as unserious to agencies who get pitched constantly.

### Slide 11 — Why Now / Why Us
One slide pulling from the competitive positioning in `COMPETITIVE_FEATURES.md` §1 — but pitched as "why partnering with us specifically, now, beats waiting" rather than a full competitor takedown.

### Slide 12 — Next Steps
Concrete: a pilot period, a call, a specific client to test with together — not just contact info.
