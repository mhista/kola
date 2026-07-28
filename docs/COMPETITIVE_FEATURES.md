# Competitive Feature Analysis & Roadmap Addendum

**Companion to:** `PRD.md`, `SRS.md`
**Status:** Draft v0.1 — addendum, triggered by a closer look at broadcast, integrations, verified badges, phone-number provisioning, and social lead capture

---

## 0. Important finding first: the name "Sabi" is not available

Before anything else — while researching the competitive landscape below, a direct, near-identical competitor surfaced already using **"Sabi"**:

> **Sabi: AI WhatsApp Business Bot** (by AppEdge, on Google Play) — "the first WhatsApp AI assistant built specifically for African small business owners," 2-minute setup, no code, priced in Naira, managed entirely from the phone, targeting salons, restaurants, fashion vendors, logistics, tutors, real estate agents, clinics.

That is not a loose naming overlap — it's the same name, the same country, the same customer, and almost the same one-line pitch. There are also several other unrelated "Sabi"-branded Nigerian tech products (Sabi.ai, SabiBoy, Oversabi AI, a Sabi shop-management app) — the word is heavily used across Nigerian tech generally, which makes trademark and app-store search visibility worse even before getting to the direct conflict above.

**Recommendation: drop "Sabi" as the brand.** See §4 for a revised shortlist. **Resolved:** "Kola" is now the confirmed final brand name, and the rename has been carried through PRD.md, SRS.md, DESIGN_PROMPT.md, and the deck design prompts (self-references only — every "AppEdge Sabi" competitor reference in these documents, including in this one, stays as-is since it refers to the actual competing product, not to us).

This also means: **AppEdge's Sabi bot is now a named, direct competitor** and belongs in the competitive table (see §1) — it's the closest thing to "someone already building exactly this" that exists today.

## 1. Updated Competitive Landscape

### 1.1 Direct Nigerian competitors (closest to our exact positioning)

| Product | Positioning | What it has | What it's missing (our opening) |
|---|---|---|---|
| **AppEdge's "Sabi"** (hands-on tested, see `META_CONNECT_FLOW.md`) | "First WhatsApp AI assistant for African SMEs," 2-min setup, no code, Naira pricing (₦6,000 Starter / ₦20,000 Pro), phone-managed | In-app Facebook/WhatsApp connect via Meta's Embedded Signup, website-scrape or paste/upload knowledge ingestion (PDF/Word/Text supported), GPT-4o-mini Q&A restricted to the knowledge base, human hand-off ("Manual Overdrive"), usage dashboard (messages/leads/customers/conversations), a 1-hour full-feature test window with a hard paywall after | No Telegram, no developer/API story, no document-grounded catalog/negotiation commerce flow, no Errand-style custom capabilities or business-database access — and their own Terms of Service explicitly **prohibit bulk broadcast messaging**, so it reads as a closed consumer app with a genuinely slick onboarding flow, not an extensible platform |
| **Botify.ng** | Markets itself as "#1 WhatsApp Chatbot Solution in Nigeria" | Nigeria-focused WhatsApp bot builder | Same category as AppEdge's Sabi — worth a closer look (sign up, read their docs/pricing) before final positioning, flagged here as a research follow-up rather than fully profiled |
| Gupshup / Arkesel / Siteti | Africa-focused WhatsApp Business API infrastructure/BSP layer, Naira billing angle (Siteti specifically markets Naira billing as its edge) | API infrastructure, not an end-user no-code bot builder | These are more likely *infrastructure partners* for us (BSP layer, see §2.3) than head-to-head competitors |

**What this changes:** "Naira pricing" and "no-code, fast setup" — the two things this PRD leaned on hardest as differentiators — are **already being sold in Nigeria today** by at least one real competitor. Our durable edges have to be the things AppEdge's Sabi visibly doesn't do: a genuine **dev-extensible Errand system** (API keys, webhook/DB-backed capabilities), **document-based knowledge** (not just a URL paste), **dual-channel from day one** (WhatsApp *and* Telegram), and the **catalog/negotiation commerce bot** archetype. The PRD's "two doors, one house" principle is more important now than it was before this finding — it's the thing a closed consumer app structurally can't copy quickly.

### 1.2 International competitors (unchanged from PRD §9, extended below with the features you flagged)

| Platform | Broadcast | CRM integrations | Verified badge help | Phone number handling | Social lead capture |
|---|---|---|---|---|---|
| Wati | Yes, WhatsApp template-based | Native: HubSpot, Shopify, Zapier | Assists with Meta verification as part of onboarding | BYO number or BSP-assisted | No |
| ManyChat | Yes (Instagram/FB/SMS/email), less WhatsApp-template-constrained on IG/FB | Zapier, native Shopify/Klaviyo; HubSpot/Salesforce via Zapier | N/A (not WhatsApp-first) | N/A for IG/FB; WhatsApp add-on uses standard Cloud API flow | **Yes — this is a signature ManyChat feature** (see §2.4) |
| AiSensy / Interakt | Yes, WhatsApp template-based, positions itself as the affordable option | Zapier + a growing native app list | Onboarding assistance | BSP-assisted number setup | No |
| Landbot | Limited (flow-based, less broadcast-first) | Zapier, native Slack/HubSpot | N/A | Standard Cloud API flow | No |
| CodeWords | N/A (general agent builder, not messaging-broadcast-first) | Native integrations across 1,000+ tools (its core pitch) | N/A | N/A | No (not its focus) |

## 2. Feature-by-Feature Analysis

### 2.1 Broadcast / bulk messaging

**What it actually is, technically:** on WhatsApp, any business-initiated message outside a 24-hour customer-service window must use a pre-approved **template message** (categorized `marketing`, `utility`, or `authentication`), and every recipient must have given explicit opt-in. Sending limits scale by "tier" (1,000 → 10,000 → 100,000 → unlimited business-initiated conversations/day) based on the number's quality rating. Mis-categorized or non-opted-in blasts risk template rejection or account suspension — this is a compliance-heavy feature, not a simple "send to everyone" button. Telegram has none of these constraints — any bot can message any user who has started a conversation with it, with no template/opt-in system at all.

**Update:** confirmed directly from AppEdge Sabi's own Terms of Service — they contractually **prohibit** their users from sending bulk broadcast messages. Whether that's caution or a real gap, it's a live competitor deliberately not offering this today, which strengthens the case for us building it properly in Phase 2 rather than skipping it.

**Recommendation:**

- **MVP1:** Telegram broadcast (segment by tag, send to all active conversations) — trivial to build on top of the existing channel adapter, no compliance surface.
- **Phase 2:** WhatsApp broadcast built specifically on Meta's **Marketing Messages API ("MM Lite API")** — launched April 2025, purpose-built for outbound marketing/template sends with Meta's own delivery-optimization layer, distinct from the two-way Cloud API used for live conversations. Requires a template library + approval workflow, an opt-in capture/consent record on every contact (tie into `Conversation`/contact model), a send-time audience segmenter, and a quality-rating monitor. This is exactly the kind of feature that turns the platform from "a support bot" into "a marketing channel," which is genuinely important competitively (Wati/AiSensy lead with this, AppEdge Sabi explicitly doesn't) — but it's also the easiest way to get an SME's number banned if we rush it, so it ships once the compliance plumbing (opt-in tracking, template review) is solid, not before.

### 2.2 "Blue tick" — Meta's verified business badge

**Clarifying what it actually is:** Meta unified WhatsApp's green check into the same blue verification badge used on Instagram/Facebook after a 2024 rebrand — so "blue tick" and the old "green tick" are now the same thing. There are two paths: (1) a **free "Official Business Account"** badge, granted only to businesses Meta judges "notable" (typically needs 3–6 organic press mentions in real outlets in the last 24 months — paid press releases don't count, and only ~38% of first submissions are approved, 2–8 week review), or (2) a **paid "Meta Verified for Business" subscription**, faster and open to smaller businesses, but availability is still rolling out region by region.

**What we can actually offer:** we cannot grant the badge — only Meta can — but we can remove the friction of applying for it: a guided "Get verified" flow in the Integrations page that walks a business through Meta Business Manager verification (the prerequisite gray-check legal-entity step everyone needs regardless), tracks status (Not started → Business verified → Badge applied → Approved/Rejected), and — once Meta Verified for Business is available in Nigeria — offers to bundle/facilitate that paid subscription. This is a trust-and-credibility upsell, not a core product mechanic.

**Recommendation:** Phase 2 (bundle with the WhatsApp number-provisioning work in §2.3, since both live in the same "get properly set up with Meta" onboarding moment).

### 2.3 Phone numbers — can we get businesses a number?

**This section is now superseded by hands-on findings — see `META_CONNECT_FLOW.md` for the full detail.** Short version: you downloaded and walked through AppEdge's Sabi app yourself, which answered this more precisely than the desk research below originally could.

What we confirmed directly: the "connect your Facebook, we handle WhatsApp" experience you saw is **Meta's own standard Embedded Signup flow**, not something Sabi built themselves — and Sabi integrates with it **directly as a registered Meta Tech Provider**, with no BSP (360dialog/Gupshup/Twilio) in between. That changes the recommendation:

1. **Go direct to Meta as our own Tech Provider (revised recommendation, MVP1, not Phase 2).** Register our own Meta App, pass App Review for the WhatsApp Business permissions, and implement Embedded Signup ourselves. This is the leaner path and it's proven achievable at exactly our scale — AppEdge is not a large company.
2. **The number itself still has to come from the business.** Embedded Signup offers two paths: "Add a new number" (the business's own dedicated SIM — permanently converted to API-only, can never go back to consumer WhatsApp) or "Use a display name only" (a Meta-issued **shared placeholder/test number** — this is a trial/demo mechanism, not a real production number for every business). **Meta removes the dashboard friction, not the need for a real number.** Our onboarding has to say this plainly, the same way Meta's own flow does, rather than let it surprise someone mid-signup.
3. **A BSP partnership is now a fallback, not a blocker.** Worth keeping on the roadmap for Phase 2+ (faster multi-country rollout, offloading some Meta compliance overhead), but it no longer gates shipping the core in-app connect experience.
4. **Reselling/provisioning our own virtual numbers directly** remains the most operationally heavy option (numbering compliance + cost) and stays a Phase 3 evaluation.

**Revised recommendation:** ship the full in-app Embedded Signup experience at **MVP1** — it's table stakes now that we've confirmed a direct competitor already has it, not a Phase 2 differentiator, and it costs nothing to build (Meta doesn't charge for Tech Provider registration or App Review). **MVP1 is bring-your-own-number only** — we hold no numbers inventory and have no budget to buy any right now, so that cost stays with the business. What we owe them instead is a plain, unmissable disclosure before they connect (see `META_CONNECT_FLOW.md` §3a) and a real off-ramp: Telegram, which needs no number and no Meta approval at all. Buying/provisioning numbers ourselves is **revenue-gated** — see `META_CONNECT_FLOW.md` §6 for the provider comparison and NCC requirements, kept as reference material for once there's a business case to fund it, not a task on any current roadmap phase.

### 2.4 ManyChat's "pull leads from posts" — how it works, and can we do it

This is Instagram/Facebook **comment-to-DM automation**: a business sets a trigger (a specific post/reel, or any post; a specific keyword in the comment, or any comment), and when a user's comment matches, the platform publicly replies to the comment *and* sends them a private DM (lead magnet, price list, link) — all through Meta's **official Instagram Graph API**, which requires the platform to be an approved **Meta Business Partner**. ManyChat is one; that partner status plus the reviewed API permissions is what makes it possible and compliant (as opposed to scraping, which isn't).

**Is it something we can do?** Yes, technically — but it requires two things we haven't scoped yet: (1) Instagram as a supported channel (currently a Phase 3 line item, "Additional channels"), and (2) going through Meta's Business Partner / app review process for the relevant Instagram permissions, which has its own timeline independent of our engineering schedule.

**Recommendation:** keep this bundled into **Phase 3** ("Additional channels: Instagram DM") by default, since it's not just a feature, it's a new channel plus a partner-approval dependency — but flag it as the top candidate to **pull forward into late Phase 2** if early customer conversations show Nigerian SMEs care more about Instagram-comment lead capture than, say, Facebook catalog sync (which currently sits in Phase 2). Worth a direct question to your first design-partner SMEs: "Instagram comment leads" vs. "Facebook catalog" — which do they actually want first?

### 2.5 CRM & tool integrations (HubSpot, Salesforce, Slack, etc.)

There's a real cost gradient here worth being deliberate about:

- **Native marketplace apps** (a listed HubSpot or Salesforce app) take real engineering time and go through each vendor's app-review process — worth doing once we have paying customers actively asking for it, not speculatively at MVP.
- **Slack specifically is the cheap win:** Slack's incoming-webhook mechanism is trivial to build against (post a formatted message to a channel on any event — new conversation, Errand fired, escalation) — this can ship early and cheaply.
- **Becoming a Zapier/Make.com "app"** is the highest-leverage move available: it's one integration-partner relationship that transitively unlocks HubSpot, Salesforce, and effectively any of the 1,000+ tools those platforms already connect to, without us building and maintaining a native connector for each one. This is functionally how we get CodeWords-style "1,000+ integrations" breadth without CodeWords' integration-building headcount.
- Our own generic **outbound webhook system is already in the Phase 1 architecture** (SRS §12) as part of the Errand/dev-experience story — Zapier/Make support is really "the same webhook capability, packaged for a no-code audience," which is a relatively small additional step once outbound webhooks exist.

**Recommendation:**

- **Phase 1:** generic outbound webhooks (already planned).
- **Phase 2:** native Slack notification connector (cheap, high visual impact for the "built for the whole team" pitch) + list on Zapier and/or Make.com (unlocks HubSpot/Salesforce/CRM breadth indirectly).
- **Phase 3:** native HubSpot and/or Salesforce marketplace apps, prioritized by which one real customers actually ask for — don't build both speculatively.

## 3. Revised Feature Placement Summary

| Feature | Phase | Why here, not earlier/later |
|---|---|---|
| Telegram broadcast | **MVP1** | No compliance surface — trivial extension of the existing channel adapter |
| Generic outbound webhooks | **MVP1** | Already the backbone of the Errand/dev story |
| **In-app WhatsApp connect via Meta Embedded Signup (direct Tech Provider, no BSP)** | **MVP1 (moved up from Phase 2)** | Confirmed achievable at our scale via hands-on testing of AppEdge's Sabi — anything less at MVP1 is a step down from the current market bar, not a differentiator. See `META_CONNECT_FLOW.md`. |
| WhatsApp broadcast via Marketing Messages (MM Lite) API | **Phase 2** | Needs opt-in tracking, template review workflow, quality-rating monitoring first; confirmed as a real gap in AppEdge Sabi (their ToS bans it) |
| Guided "get verified" (Meta badge) flow | **Phase 2** | Independent of the connect flow now that connect itself is MVP1 |
| BSP partnership (360dialog/Gupshup/Twilio) | **Revenue-gated (fallback, not a blocker)** | Worth having for multi-country speed or offloading Meta compliance later; no longer required for MVP1's connect experience |
| Buying/provisioning numbers on a business's behalf | **Revenue-gated, not phase-scheduled** | Requires funding a numbers inventory plus NCC business-registration paperwork on our side (`META_CONNECT_FLOW.md` §6); revisit once paying customers ask for it |
| Slack native connector | **Phase 2** | Cheap, high-visibility, strengthens the "built for the whole team" story |
| Zapier / Make.com listing | **Phase 2** | Indirect route to HubSpot/Salesforce breadth without native build cost per CRM |
| Facebook catalog sync | **Phase 2** *(unchanged from PRD)* | Already scoped; re-confirm priority against §2.4's Instagram question with real customers |
| Instagram comment-to-DM lead capture | **Phase 3** *(pull-forward candidate)* | New channel + Meta Business Partner approval dependency, not engineering-only |
| Native HubSpot/Salesforce marketplace apps | **Phase 3** | Build once real customer demand and volume justify the review/support overhead |
| Reselling/provisioning our own virtual numbers | **Phase 3 (evaluate)** | Numbering compliance + cost stack on top of the BSP option; revisit after Phase 2 traction |

## 4. Revised Brand Name Shortlist (post-"Sabi" conflict)

Same brief as before — short, easy to pronounce anywhere, distinctive, ideally ~4 letters, warm/local without being a dictionary-generic word. Checked against obvious direct conflicts via search (not a substitute for a formal trademark/CAC/domain search before you commit):

| Name | Why it works | Conflict check |
|---|---|---|
| **Kola** *(recommended)* | Kola nut is a real, deeply-rooted West African symbol of welcome/hospitality — "bring the kola" is a literal welcoming ritual. Reads warm, short, easy to say globally, and ties naturally to a customer-service/greeting product without being a literal description of what it does (same category of brand move as "Slack" or "Zoom"). | No direct competing app/bot found using this exact name in search; still do a formal trademark/domain/CAC check — moderate phonetic overlap with "Coca-Cola" is worth a gut-check with a few people before committing. |
| **Fiya** | Pidgin spelling of "fire" — "that's fiya" = that's excellent/impressive. Energetic, short, distinct spelling stands out visually. | No direct competing chatbot/SaaS use found in search. |
| **Waka** | Pidgin for "go/walk" — "waka come," directly evokes the Errand concept ("send it on a waka"). Globally recognizable syllable (helped, oddly, by the Shakira "Waka Waka" association, which is more asset than liability for memorability). | Minor: an AI project called "Waka AI" exists for a small Niger-Congo language (Waka), different-enough space (linguistics tooling, not chatbots) that it's a low-severity flag, not a blocker — worth a second look before final commit. |
| ~~Yarn~~ | Pidgin/English slang for "chat/story," nice metaphor for conversation | **Dropped** — direct conflict: YarnGPT (Nigerian voice AI startup, recently acquired) and Yarn.so (an unrelated GTM-video SaaS) both actively use this name in adjacent tech spaces. |
| ~~Jara~~ | Pidgin for "a little extra/bonus," nice fit for negotiation flows | **Dropped** — direct conflict: "Jara App" is an existing Nigerian fintech/rewards app (airtime/data cashback), same country, same target user. |

**Recommendation:** lead with **Kola**, keep **Fiya** as the backup. **Confirmed as final** — Kola is now the brand used throughout every project document and the finished design system. Still outstanding: an actual trademark/CAC name-availability search and a domain check — the research above is web-search-level due diligence, not legal clearance.
