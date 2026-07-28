# Product Requirements Document (PRD)
## Bot-as-a-Service Platform for SMEs, Startups & Agencies

**Status:** Draft v0.1 — Phase 1 (Discovery & Definition)
**Owner:** Diwe
**Date:** 20 July 2026
**Repo:** `botigo` (working codename — see brand naming below)

---

## 1. Vision

Every SME in Nigeria — the fabric seller in Yaba market, the skincare vendor on Instagram, the logistics startup with three staff — already lives on WhatsApp and Telegram. None of them can afford a software team to build a bot, and the tools that exist today (ManyChat, Wati, Landbot, AiSensy) are either priced in dollars, built for flow-charts instead of conversation, or assume a level of technical setup that a solo founder doesn't have time for.

We are building a **Bot-as-a-Service (BaaS) platform**: a place where anyone — technical or not — describes what they want their WhatsApp or Telegram bot to do, in plain language, and gets a working, trained, business-specific bot in minutes. Developers who want to go deeper get an API key, webhooks, and (later) MCP-style access to the same primitives the no-code dashboard uses internally. Nothing is hidden behind a black box — the no-code path and the code path are two doors into the same house.

We are starting in Nigeria because that's the market we understand best and where the gap is widest, but the architecture is deliberately global-, multi-channel-, and multi-industry-ready from day one.

## 2. Problem Statement

- Nigerian SMEs run their entire customer relationship through WhatsApp/Telegram DMs, manually, one conversation at a time. This doesn't scale past a handful of orders a day.
- Existing chatbot builders are drag-and-drop flow tools designed for marketing broadcast, not for a business owner who wants to just *explain* their business once (upload a price list, a FAQ doc, a return policy) and have the bot handle the rest.
- International platforms bill in USD, price for Western support-team headcount, and don't understand Nigerian SME edge cases: epileptic connectivity, WhatsApp Business API approval friction, Paystack/Flutterwave as the only payment rails that matter, customers who negotiate price in-chat, and a huge share of "catalog" businesses that are really just a phone camera and a price list.
- The people who most need a bot (a 24-year-old selling clothes from a room in Lagos) have zero coding ability. The people who could extend a bot for them (a freelance developer they hired for something else entirely) need an API, not a course in prompt engineering.

## 3. Product Name — Decided: Kola

**Kola is the final, confirmed brand name.** The name traveled through a real decision process worth keeping on record:

1. **Sabi** was the original recommendation — Pidgin for "know/skilled," short and warm — until hands-on competitive research (`COMPETITIVE_FEATURES.md` §0) found a direct, near-identical Nigerian competitor already trading under that exact name (AppEdge's WhatsApp AI bot for African SMEs — same country, same customer, same pitch). Dropped for that reason, not on merit.
2. A revised shortlist (`COMPETITIVE_FEATURES.md` §4) proposed **Kola** — the kola nut, a real, deeply-rooted West African symbol of welcome/hospitality ("bring the kola" is a literal welcoming ritual) — alongside **Fiya** as backup. No direct competing product found using the name in search.
3. **Kola is now confirmed as final** and is reflected throughout every project document (this PRD, the SRS, the design prompts, the Terms of Service/Privacy Policy drafts) and in the actual design system already produced (`Kola design system specs/`) — the design work independently landed on a palette (warm cream `#FAF6EF` background, terracotta `#C1552E` accent, near-black `#1C1815` text, Newsreader serif + Instrument Sans + IBM Plex Mono) that reads as a natural extension of the kola-nut brand rationale.

"Botigo" remains the working repo/folder name only — a rename to something Kola-aligned is a Phase 1 housekeeping item (`DEVELOPMENT_PLAN.md` §1a), not a blocker to writing code under the current name.

**Still outstanding:** a formal trademark/domain/CAC name-availability search for "Kola" — flagged in `COMPETITIVE_FEATURES.md` §4 as web-search-level due diligence, not legal clearance. Worth closing out before any public launch, even though the name is otherwise locked for all planning and design purposes.

## 4. Target Users & Personas

1. **Non-technical SME owner ("Chioma, the vendor").** Sells clothes/skincare/food on WhatsApp/Instagram. No developer, no budget for one. Needs: upload a document or just talk to a setup wizard, get a working bot same day, pay in Naira, cancel any time.
2. **SME owner with a developer ("Tunde, the founder with one contractor").** Wants the dashboard for day-to-day content changes, but wants his developer to wire the bot into his existing inventory system or database via an API key.
3. **The developer/freelancer ("the contractor").** Gets an API key and (later) an MCP endpoint. Wants clean docs, a sandbox, versioned endpoints, and the ability to register custom Errands programmatically instead of through the UI.
4. **Agency / reseller ("digital agency managing 12 client bots").** Manages many tenants under one account, needs a workspace-switcher, white-label options (later phase), and usage/billing visibility per client.
5. **Kola admin (internal).** Needs visibility into fraud signals, abuse, platform health, and per-tenant usage for billing and support.

## 5. Core Concept & Terminology

We are deliberately not reusing "skills," "functions," "actions," or "plugins" — every one of those is already the vocabulary of a dozen other AI platforms (including the very AI assistants used to build this). Instead:

- **Errand** — the atomic unit of bot capability. An Errand is "a thing the bot has been taught to go and do": fetch a customer's order status from a database, calculate a shipping quote, check a price list, send a birthday message, escalate a complaint to a human. Every Errand has a name, a description (used by the AI to decide when to use it), a set of inputs, a way of being fulfilled (internal built-in, business-supplied API/webhook, or business-supplied database/MCP credential), and a permission scope. Non-technical users create Errands by describing them in plain language during a conversation with **Bot Mother** (below); developers register them via API/SDK or by pointing Kola at an OpenAPI spec or MCP server.
- **Bot Mother** — the meta-bot / setup wizard (the platform's own agent, in the spirit of Telegram's BotFather) that a business owner talks to — on the dashboard, or eventually directly on WhatsApp/Telegram — to create a new bot, upload knowledge, and register new Errands conversationally. Bot Mother is what turns "I want my bot to also handle refund requests" into a working Errand without the owner ever seeing a form.
- **Knowledge** — any document (PDF, Word, image of a price list, plain text, spreadsheet) a business uploads. Parsed by our ingestion/parsing engine into retrievable context the bot uses to answer questions and stay in character/policy.
- **Workspace** — a business/tenant's isolated environment: its bots, Errands, knowledge, channels, API keys, and usage — never visible to or reachable by any other tenant.

## 6. MVP Definition (Phase 1)

**In scope for MVP:**

- Create a bot via Bot Mother (dashboard-based conversational setup first; WhatsApp/Telegram-native setup is Phase 2).
- Two first-class bot archetypes, ship-ready at launch:
  1. **Customer care bot** — upload any document, bot answers from it, escalates what it can't answer.
  2. **Catalog/ecommerce bot** (built on learnings from Asami) — store items with photos/descriptions/price, buy/negotiate/inquire buttons, bot converses, agrees a price within configured bounds, and on close either DMs the vendor or emails them the lead — no live payment collection yet.
- Errand creation via natural language on the dashboard (non-dev path) and via API key (dev path). MVP dev path supports simple webhook/REST-based Errands; direct DB/MCP credential hookup is scoped but flagged for fast-follow within the MVP window, not a later phase, given how central it is to the "give us your DB" scenario.
- Document parsing engine covering PDF, DOCX, plain text, and CSV/XLSX price lists at minimum.
- WhatsApp + Telegram as the two supported channels.
- Multi-tenant isolation: one business's bot, data, and Errands are never visible to another.
- Usage metering and a **two-stage 14-day trial**: full premium-tier feature access for the first 48 hours (enough to actually see the product work — a deliberately more generous hook than the 1-hour hard cutoff we found competitor AppEdge's Sabi uses), then automatic step-down to a capped/free-tier feature set for the remainder of the 14-day window so the workspace keeps working at a reduced level rather than going dark, then the workspace is paused (not deleted) pending a paid plan once day 14 ends. See §10 and `META_CONNECT_FLOW.md` §5 for the full reasoning.
- **In-app WhatsApp connection via Meta's Embedded Signup** (Facebook Login for Business) — the owner connects their Facebook account and WhatsApp number entirely inside our product, the same pattern AppEdge's Sabi already ships; no manual Meta Business Manager visit required. Full technical walkthrough in `META_CONNECT_FLOW.md`. Requires us to register as a Meta Tech Provider and pass Meta's App Review for the relevant WhatsApp Business permissions before MVP1 can ship — this is now a critical-path dependency, not a nice-to-have. **This is free to build** (Meta doesn't charge for Tech Provider registration, App Review, or Business Verification) — only the phone number itself costs money, and at MVP1 that cost stays with the business (bring-your-own-number), not us. We are not buying or stocking numbers at launch; see below and `META_CONNECT_FLOW.md` §3a/§6.
- **Clear, upfront disclosure that connecting a number is permanent** — before a business taps "Connect via Meta," the onboarding wizard must plainly state that the number will stop working in consumer WhatsApp once connected, and offer Telegram as a genuine zero-cost, no-number-required alternative for anyone not ready to commit a number yet. This is an MVP1 requirement, not a nice-to-have, precisely because we have no budget to soften this any other way.
- Payment **infrastructure** built (Paystack + Flutterwave services wired, tested against sandbox) but **not exposed** as a live "collect payment" Errand to end customers yet — this ships switched-on in MVP2.
- Basic fraud/abuse guardrails (rate limiting, spam detection on inbound messages, a security-filter pass on AI tool calls) — not the full fraud-scoring engine from day one, but the seams for it are in place.
- Developer-facing API docs site (Jaspr-built, see SRS) covering authentication, Errand registration, and webhook contracts.

**Explicitly out of scope for MVP (Phase 2+):**

- Live payment collection through the bot.
- Facebook/Instagram catalog sync.
- WhatsApp/Telegram-native Bot Mother (create/manage a bot without visiting the dashboard).
- White-labeling for agencies.
- Voice notes / OTP delivery / birthday-campaign scheduling as first-class templated Errand types (they're natural Errand examples and should work generically, but we're not building bespoke UI for each one at launch).
- MCP server exposure for a business's own tools (dev path uses plain API keys + webhooks first).
- Multi-language UI (English + Nigerian Pidgin copy tone is enough for MVP; full i18n is a Phase 3 concern once we expand beyond Nigeria).

## 7. Feature List by Phase

### Phase 1 — MVP
- Bot Mother dashboard-based setup wizard
- Customer care bot archetype with document-based knowledge
- Catalog/ecommerce bot archetype (negotiate → notify vendor)
- Errand builder (natural language, dashboard) + Errand registration API (dev)
- Document parsing engine (PDF/DOCX/TXT/CSV/XLSX)
- Image upload/storage via ImageKit, metered per MB as usage (not a flat storage tier) — the catalog bot's product photos and any image attached to a knowledge document both flow through this, no Errand configuration required (`SRS.md` §6a)
- WhatsApp + Telegram channel adapters
- Multi-tenant workspace model, API keys, usage metering
- 14-day freemium trial → paid tiers
- Payment infra built, not live
- Basic abuse/fraud guardrails
- Dual dashboard UI: natural-chat mode + dev/structured mode (see §8 and design prompt)
- Developer documentation site
- Telegram broadcast messaging (no compliance surface, trivial extension of the channel adapter)
- Generic outbound webhooks (doubles as the foundation for Phase 2 CRM/Zapier connectivity)

### Phase 2 — Commerce, Reach & Trust
- Live payment collection Errand (Paystack/Flutterwave) with escrow-style hold option (informed by Asami's `order_escrow` pattern)
- Facebook/Instagram catalog connect and sync
- Business-supplied database/MCP credential Errands, fully self-serve
- WhatsApp/Telegram-native Bot Mother (manage your bot without opening a browser)
- Templated Errand library: OTP delivery, birthday/anniversary campaigns, complaint ticketing with SLA tracking
- Agency/reseller multi-workspace management
- **WhatsApp template-based broadcast** built on Meta's Marketing Messages (MM Lite) API, with opt-in tracking, template review workflow, and quality-rating monitoring (see `META_CONNECT_FLOW.md` §3)
- **Guided "get verified" flow** for Meta's business verification / verified badge
- **BSP partnership evaluation** (360dialog/Gupshup/Twilio) as a fallback path for businesses who'd rather not go through Meta's own Tech-Provider-managed flow, and as groundwork for faster multi-country rollout later — no longer a blocker for the core connect experience, which ships direct-to-Meta at MVP1 (see above)
- **Buying/provisioning numbers on a business's behalf** ("give me a number too") is explicitly **revenue-gated, not tied to this or any specific phase** — it requires funding a numbers inventory and, on our side, NCC business-registration paperwork (`META_CONNECT_FLOW.md` §6). Revisit once paying customers are actually asking for it, not before.
- **Native Slack notification connector** + **Zapier/Make.com listing** (indirect route to HubSpot/Salesforce breadth without native per-CRM build cost)

### Phase 3 — Scale & Expansion
- Additional channels (Instagram DM, SMS, voice)
- **Instagram comment-to-DM lead capture** (ManyChat-style; requires Instagram as a channel plus Meta Business Partner approval — pull-forward candidate into late Phase 2 if early customers prioritize it over Facebook catalog sync)
- **Native HubSpot and/or Salesforce marketplace apps** (build whichever real customers actually ask for first, not both speculatively)
- Reselling/provisioning our own virtual numbers directly (evaluate after Phase 2 BSP-based provisioning proves out)
- Additional countries/currencies, full i18n
- White-label option for agencies
- Full AI fraud-prevention engine (scoring, anomaly detection across tenants) as a platform-wide layer, not just per-tenant guardrails
- Plug-in marketplace for third-party Errand packs (vetted `pub.dev`-style ecosystem)

*(Full rationale for every placement above: `COMPETITIVE_FEATURES.md` §2–3.)*

## 8. Product Principles

- **Two doors, one house.** Every capability reachable from the no-code dashboard must also be reachable from the API — the dashboard is a client of our own public API, not a special back-door.
- **Never force a rebuild.** A business that starts non-technical and later hires a developer should not have to redo anything; the developer extends what's already there.
- **We store the least we can.** Businesses can point Kola at their own database/storage; we hold onto identity, billing, and the minimum operational data needed to run the bot — not a full copy of their business data by default.
- **Silence over noise.** Internal service failures (a knowledge parse hiccup, a downstream API timeout) degrade gracefully and are logged for us, never dumped on the end customer as an error message (this mirrors the error-handling policy already proven in the Degenbot codebase).
- **Composable from day one.** Messaging channel, persistence, and AI provider are all swappable behind interfaces — never hard-wired — because we are going to add channels, move infra, and swap AI vendors more than once.

## 9. Competitive Landscape (summary)

| Platform | Model | Nigeria fit | Gap we exploit |
|---|---|---|---|
| Wati | WhatsApp-first, shared inbox, flow builder | Weak — USD pricing, ~$39–199/mo | No natural-language business setup; no dev+non-dev dual path |
| ManyChat | Broadcast/marketing automation, visual flow builder | Weak — built for global D2C marketing, not conversational commerce | Not conversation-first; no document-driven knowledge |
| AiSensy / Interakt | WhatsApp API gateway, lower-cost | Moderate — closest on price | Still template/flow based, not agentic; no Errand/API extensibility model |
| Landbot | No-code visual flows, branded chat UI | Weak — €160–200/mo entry | Flow-chart mental model, not "describe your business once" |
| CodeWords | General-purpose agent builder (any channel), natural-language agent creation, 1,000+ integrations, $20–100+/mo | Not Nigeria-specific, not WhatsApp/Telegram-native as primary focus, no dev-vs-non-dev dual-surface for the same agent | We are narrower (bot-first, Nigeria-first) but deeper on messaging-platform nuance, local payments, and a genuine dual dev/non-dev interface over the *same* underlying Errand registry |
| **AppEdge "Sabi"** *(direct Nigerian competitor — hands-on tested)* | "First WhatsApp AI assistant for African SMEs," 2-min setup, no code, Naira pricing (₦6,000 Starter / ₦20,000 Pro per month), phone-managed | In-app Facebook/WhatsApp connect via Meta's Embedded Signup (no Business Manager dashboard visit), website-scrape or paste/upload knowledge ingestion, GPT-4o-mini-powered Q&A restricted to the knowledge base, human hand-off ("Manual Overdrive"), usage dashboard, a 1-hour full-feature test window before a hard paywall | No Telegram, no developer/API path, no document-grounded catalog/negotiation commerce flow, no custom Errand-style capabilities, and their own Terms of Service explicitly **prohibit bulk broadcast messaging** — see `COMPETITIVE_FEATURES.md` §1.1 and `META_CONNECT_FLOW.md` for the full breakdown, including exactly how their Meta connect flow works (we're adopting the same pattern — see §7) |
| Botify.ng | Markets as "#1 WhatsApp Chatbot Solution in Nigeria" | Nigeria-focused WhatsApp bot builder | Not yet fully profiled — flagged as a research follow-up in `COMPETITIVE_FEATURES.md` §1.1 |

We are not trying to out-integrate CodeWords (1,000+ integrations) on day one — we are trying to be the obvious, affordable, locally-billed, WhatsApp/Telegram-native choice for a Nigerian SME, with a credible path for a developer to go deep when the business needs it. **Naira pricing and "no-code, fast setup" are no longer differentiators on their own** — AppEdge's Sabi already sells exactly that. Our durable edges are the dev-extensible Errand system, document-grounded knowledge, dual-channel support, and the catalog/negotiation archetype — see `COMPETITIVE_FEATURES.md` §1.1.

## 10. Business Model

- **Trial mechanics (two-stage, 14 days total):**
  1. **Hours 0–48:** full Pro-tier feature access — every Errand type, unlimited-within-reason AI replies, full knowledge base limits — so the owner sees the real product, not a stripped demo. This is a deliberate contrast to AppEdge's Sabi, whose test window is a hard 1-hour cutoff with no continued access until payment (`META_CONNECT_FLOW.md` §5) — that's abrupt enough to feel like a bait-and-switch to a first-time user, and we don't want that reputation.
  2. **Hours 48 – Day 14:** automatic step-down to capped Free-tier limits (message volume, Errand count, knowledge size) — the bot keeps working, just at a visibly reduced ceiling, so the owner feels the difference between free and paid without losing the bot entirely mid-evaluation.
  3. **Day 14+:** the workspace is paused (bot stops responding on live channels) but **data is retained, not deleted** — paying at any point after this reactivates immediately with everything intact.
- Abuse guardrails apply throughout (rate limits, one trial per verified business/phone number) — the 48-hour full-access window is exactly the kind of thing that invites throwaway signups without them.
- **Paid tiers (illustrative, subject to change):** priced in Naira, tiered by monthly conversation volume + number of Errands + number of connected channels, roughly bracketed to undercut Wati/AiSensy's Nigeria-accessible pricing while remaining sustainable against Meta's per-conversation WhatsApp fees.
- **Agency tier:** per-workspace pricing with volume discount, once Phase 2 multi-workspace management ships.
- Pricing numbers are explicitly not final — to be modeled against Meta conversation-fee pass-through costs and real trial-to-paid conversion data before Phase 1 launch.

## 11. Success Metrics

- Time from signup to first working bot reply (target: under 10 minutes for the customer-care archetype, document upload included).
- % of created Errands that are non-dev, natural-language created vs. API-registered (tracks whether the no-code promise is actually landing).
- 14-day trial → paid conversion rate.
- Bot resolution rate without human hand-off (customer care archetype).
- Negotiated-sale completion rate (catalog archetype) — did the conversation end in a vendor notification with a price agreed.

## 12. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| WhatsApp Business API approval friction/delays for new business numbers | Telegram ships first and fully; WhatsApp onboarding wizard sets expectations up front; consider a shared/pooled sender number option for trial users |
| Serverpod's database ORM doesn't fit our multi-tenant, swappable-storage model (learned the hard way on Asami) | Adopt the Degenbot pattern: Serverpod for endpoint/model codegen only, Supabase (or business-supplied Postgres later) for actual persistence, bridged by a DTO + repository layer — see SRS §3 |
| Non-technical users create malformed or abusive Errands (e.g., an Errand that leaks data across tenants) | Errand permission scoping is mandatory and tenant-bound at the framework level, not opt-in; every Errand execution is logged and rate-limited |
| Fraud/abuse (fake vendors, negotiation-bot exploited for spam or scraping) | Ship basic guardrails at MVP (rate limits, spam heuristics, security-filter pass on tool calls); design the schema now so the full scoring engine (Phase 3) can be added without a rewrite |
| Meta per-conversation fees erode margin at low price points | Model pricing tiers against real fee schedules before launch; keep Telegram (fee-free) as a viable full-featured alternative for price-sensitive SMEs |
| Scope creep before MVP ships | This PRD's Phase 1 boundary is intentionally strict — payments, FB catalog, and native WhatsApp Bot Mother are explicitly deferred |

## 13. Open Questions for you to settle before Phase 1 build starts

- Final brand name and domain (see §3).
- Illustrative pricing numbers to validate against Meta's Nigeria conversation-fee schedule.
- Whether the pooled/shared WhatsApp sender number for trial users is feasible given Meta's policies, or whether every business must complete their own WABA setup from day one.
- How much of the Asami escrow/wallet model should inform the *design* of Phase 2 payments now, even though it isn't switched on in MVP.
