# Pitch Deck Design Prompt

**Assumption stated up front:** I've built this as an **investor pitch deck** (~15 slides, first-meeting length) since that's the highest-leverage version given the PRD/market/competitive research already done, and it's the version that needs the most deliberate narrative structure to get right. If you actually meant a sales deck for SME customers, a partner/BSP deck, or an internal alignment deck instead, tell me and I'll restructure — the content skeleton in §2 would shift meaningfully (less market-sizing/financials, more feature-benefit and pricing, for instance).

Copy everything below into your design tool as a single brief, the same way `DESIGN_PROMPT.md` works for the product itself. It assumes no prior context, so it restates brand direction before getting into slides.

---

## 1. Brand & Visual Direction (consistent with the product, not a separate identity)

Same brand as the product docs — **Kola** (placeholder, pending final trademark/domain check per `PRD.md` §3/`COMPETITIVE_FEATURES.md` §4; swap throughout once finalized). The deck should feel like it was made by the same team that made the product, not outsourced to a generic pitch-deck template studio.

- **Palette:** deep near-black background (`#0E0E10`–`#141416`) as the default slide background, one warm confident accent (terracotta/amber or deep emerald — same direction as `DESIGN_PROMPT.md`) used sparingly for headlines, key numbers, and chart highlights. Avoid the generic "startup deck" gradient-mesh-and-purple look — that's the exact aesthetic we're positioning against in the product itself, so the deck shouldn't undercut that story.
- **Typography:** the same editorial serif/display face used for the landing page headline, paired with a clean grotesque/sans for body copy and data labels. One big, confident statement per slide in the serif; supporting detail in the sans, kept short.
- **Data visualization:** where charts appear (market size, pricing comparison, roadmap timeline), use flat, high-contrast, minimal-gridline charts in the same near-black/accent palette — no default PowerPoint chart styling, no drop shadows or 3D bar effects.
- **Imagery:** prefer real product screenshots (once available) and simple custom iconography over stock photography. Where a phone mockup is used (e.g. showing the WhatsApp conversation), match the style already established for the landing page's phone-mockup section in `DESIGN_PROMPT.md`.
- **Density:** one idea per slide, generous whitespace, large type. If a slide needs a paragraph to explain itself, split it into two slides instead.
- **Format:** design for 16:9 widescreen, both a dark-mode version (primary, for live pitching on a screen) and confirm it still reads well printed/exported to PDF in grayscale (investors forward decks as PDFs constantly — don't rely on the dark background alone to carry contrast).

## 2. Slide-by-Slide Structure

### Slide 1 — Cover
Wordmark/logo centered or lower-third, one-line positioning statement beneath it (not a full tagline paragraph) — something in the spirit of *"The easiest way for African SMEs to run a business on WhatsApp and Telegram."* Founder name/title and date, small, bottom corner.

### Slide 2 — The Problem
Three short, concrete pain points, not abstract statements — lean on the specifics already in `PRD.md` §2: SMEs running their entire customer relationship through manual WhatsApp/Telegram DMs with no scale ceiling; existing tools priced in USD and built for flow-charts, not conversation; the people who most need a bot have zero coding ability, and the people who could extend one for them need an API, not a course in prompt engineering. Visual: a simple 3-icon row, or a single striking stat if one is sourced (e.g. WhatsApp penetration among Nigerian SMEs) — cite the source in small type if used.

### Slide 3 — The Solution
One sentence: describe your business in plain language, get a working bot in minutes — no code, but with a real path to depth for developers. A simple before/after visual: a business owner manually typing WhatsApp replies (left) vs. the same owner glancing at a dashboard while the bot handles it (right).

### Slide 4 — How It Works (Product)
Three-to-four step visual walkthrough mirroring the "how it works" section already designed for the landing page in `DESIGN_PROMPT.md`: describe your business → bot drafts itself → connect WhatsApp/Telegram → live. Use an actual or mocked phone screenshot of a conversation, styled per the landing-page phone-mockup direction.

### Slide 5 — What Makes This Different (the Errand system)
This is the slide that needs the most care — it's the technical moat. Explain **Errand** in one plain sentence (a business capability the bot can call — a database lookup, a webhook, a custom action) and show the dual creation path visually: a business owner typing a plain-language request on one side, a developer's API call/schema on the other, both feeding the *same* underlying capability. This is the "two doors, one house" principle from `PRD.md` §8 — make that structural idea, not just a feature list, the visual centerpiece of the slide.

### Slide 6 — Market Opportunity
Sourced TAM/SAM/SOM, presented as three nested circles or a simple funnel, each with its citation in small type underneath (investors check this — cite properly, don't round away the source):

- **TAM — ~39–41 million MSMEs in Nigeria**, contributing roughly half of national GDP and about 80% of employment (SMEDAN/National Bureau of Statistics MSME Survey). This is the total addressable universe of businesses the product is built for.
- **SAM — Nigerian MSMEs already behaviorally on WhatsApp for customer contact.** Nigeria leads Africa with **52.47 million WhatsApp Business app downloads**, and over 95% of Nigeria's digital population uses WhatsApp — meaning the overwhelming majority of the TAM above is already doing business-critical conversation on the exact channel this product automates; they've just never had an easy way to make it scale past manual replies. State this as a behavioral-adoption signal, not a precise business count (the download figure includes multiple/personal downloads, so don't present it as "52 million paying customers" — the honest claim is "the channel is already universal, the tooling gap is the opportunity").
- **SOM — bottom-up, 3-year target.** Model this transparently on slide as a simple multiplication, not a top-down percentage: e.g. *"Reaching just 0.1% of Nigeria's MSMEs (~40,000 businesses) at a blended ₦10,000/month average (in line with published competitor pricing of ₦6,000–₦20,000/month) is roughly ₦4.8B (~$3M) in annual recurring revenue."* Label it explicitly as an illustrative bottom-up model, not an audited forecast — that's more credible to an investor than a confident-sounding number with no visible math.

Sources to cite on-slide in small type: SMEDAN & National Bureau of Statistics MSME Survey; WhatsApp Business download/usage data as reported via Meta/industry trackers (e.g. DataReportal/Statista-sourced figures) — re-verify both against the latest published survey before this goes in front of anyone, MSME survey cycles run multi-year and the most recent full cycle may predate this deck.

### Slide 7 — Why Now
2–3 tailwinds: WhatsApp Business Platform maturing and increasingly the default customer-service channel in Nigeria; AI making natural-language bot creation viable in a way it wasn't 2–3 years ago; Naira-billing/local-payment rails (Paystack/Flutterwave) now mature enough to build on. Keep this tight — three bullets max, each with a one-line "so what."

### Slide 8 — Competitive Landscape
A 2x2 or simple quadrant/table, not a dense feature-matrix — pull the sharpest comparison points from `COMPETITIVE_FEATURES.md` §1: international tools (Wati, ManyChat, AiSensy) are USD-priced and flow-chart-built, not conversation-first; the closest direct competitor (AppEdge's Sabi) has the Naira pricing and no-code setup but is a closed consumer app with no developer path, no Telegram, and a Terms of Service that explicitly bans bulk broadcast. Position Kola in the open quadrant: Nigeria-first pricing *and* genuine dev-extensibility, which nothing else in the market combines today.

### Slide 9 — Business Model
The two-stage trial (48-hour full access → capped free tier to day 14 → paywall) and the tiered Naira pricing structure from `PRD.md` §10, presented as a simple pricing-card visual, not a wall of numbers. One line on the Meta conversation-fee pass-through model (transparent, at-cost, no markup) since that's a trust signal, not just a mechanic.

### Slide 10 — Go-to-Market
How the first 100 businesses get found — likely candidates given the product: direct outreach to SME clusters (markets, Instagram-first sellers), agency/reseller partnerships (`PRD.md` §7 Phase 2 — agencies managing multiple client bots), and the product's own bot-mother-guided setup as a low-friction self-serve funnel. Keep this grounded in what's actually planned, not aspirational marketing-channel name-dropping.

### Slide 11 — Roadmap
A clean horizontal timeline showing Phase 1 (MVP: dual dashboard, customer-care + catalog bots, Errand engine, WhatsApp+Telegram) → Phase 2 (payments live, broadcast, Facebook catalog, verified badge, CRM/Slack/Zapier) → Phase 3 (Instagram lead capture, native CRM apps, i18n, white-label) — condensed from `PRD.md` §7. This slide should visually communicate discipline (a tightly scoped MVP) as much as ambition.

### Slide 12 — "What We've Built" (traction reframe — confirmed, no fabricated metrics)
No waitlist or user numbers exist yet, so this slide does not pretend otherwise — it substitutes proof of execution capability for traction, which is the honest and, done well, more credible version at this stage:

- **Two prior shipped products, not concepts:** Asami (a full ecommerce/WhatsApp bot with a multi-provider AI tool-calling engine, subscription billing, wallet/escrow, and Facebook catalog sync already built and working) and Degenbot (a Telegram trading bot with a live intelligence pipeline across five data layers). Show real screenshots or architecture snippets, not stock icons — this is the single strongest credibility asset available pre-launch: a team that has already shipped complex, working software in this exact problem space.
- **A working technical foundation for this product specifically:** the Serverpod/Supabase architecture pattern already proven across both prior products, reused deliberately here to avoid the database-coupling mistakes made and fixed once already (a good, honest "we've learned this lesson already" line for a technical investor).
- **Depth of planning most pre-launch teams skip:** a full PRD, technical spec, and competitive analysis already completed — including hands-on testing of the closest direct competitor (AppEdge's Sabi) down to their actual onboarding flow and Terms of Service, not just a desk-research summary. This is a good place for a one-line callout: *"We didn't just read about our competitor — we used their product and mapped exactly where it's extensible and where it isn't."*
- A note in speaker notes (not on the slide itself) flagging that once a waitlist exists (see the separate landing-page waitlist prompt) or the first pilot businesses are live, this slide gets replaced with real numbers — this version is explicitly a placeholder for "pre-launch, but not pre-execution."

### Slide 13 — Team
Founder photo/name, relevant build history (Asami, Degenbot — real, shipped, technically substantial prior work is a genuine credibility signal here, lean into it), and any advisors. Keep it to the people actually involved, not an aspirational org chart.

### Slide 14 — "What We Need to Launch" (ask reframe — confirmed, no institutional raise right now)
No formal institutional round is being pursued at this stage; a small friends & family/angel check is possible but the amount isn't finalized, so this slide does **not** open with a dollar figure — that would misstate where things actually stand, and a specific number will be communicated separately once decided. Instead:

- Frame it as **what unlocks at each stage**, not a single ask: what's achievable bootstrapped/self-funded (the MVP1 build itself — genuinely low external cost, since Meta App Review, Business Verification, and the core Embedded Signup integration are all free to build per `META_CONNECT_FLOW.md`), versus what a small friends & family check would specifically accelerate (e.g. compressing build time by bringing on a second engineer sooner, or covering a few months of runway so the founder isn't building this alongside unrelated paid work).
- Use of funds, if a check does come in, in categories tied to real known costs from the planning already done — engineering time/contractor support, basic operating runway, and modest go-to-market costs for the first pilot businesses — **without a specific total**, since that number isn't set yet.
- Close with a direct, low-pressure ask appropriate to friends & family: *"If you'd like to be part of funding the first build sprint, let's talk numbers directly"* rather than a formal termsheet-style ask slide aimed at institutional investors who aren't in the room yet.

### Slide 15 — Closing
Return to the one-line positioning statement from Slide 1, contact details, and a single strong closing visual — no new information, just a clean landing point.

## 3. Status of the Three Previously-Flagged Slides

All three now resolved, not open:

- **Slide 6 (Market):** filled in with sourced SMEDAN/NBS and WhatsApp-adoption figures above — re-verify against the latest published survey cycle before the deck goes out, since MSME survey data updates infrequently.
- **Slide 12 (Traction):** confirmed no waitlist or user numbers exist yet; reframed honestly around what's actually been built (Asami, Degenbot, this planning depth) rather than inventing metrics.
- **Slide 14 (Ask):** confirmed no institutional raise is being pursued right now; reframed as "what unlocks at each stage" with no fixed dollar figure, since the friends & family amount isn't finalized — update this slide the moment that number is set.

Everything else in this structure is already grounded in the PRD/SRS/competitive research done in this project.
