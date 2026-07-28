# Software Requirements Specification (SRS)
## Kola — Bot-as-a-Service Platform

**Status:** Draft v0.1 — Phase 1
**Companion doc:** `PRD.md` (read first — this document assumes its scope and terminology, especially **Errand**, **Bot Mother**, **Workspace**, **Knowledge**)
**Grounded in:** existing `botigo` Serverpod scaffold, and architectural patterns already proven in `degenbot_server` (Serverpod+Supabase DTO pattern, messaging abstraction, feature flags, event bus) and `asami_server` (multi-provider AI tool-calling, subscription/usage metering, product-creation conversational state machine, generative UI, escrow/wallet model, catalog sync).

---

## 1. Purpose & Scope

This SRS defines the technical architecture, data model, and functional/non-functional requirements for Phase 1 (MVP) of the platform described in the PRD, and lays the groundwork so Phase 2/3 features (payments, Facebook catalog, MCP-based Errands, agency multi-tenancy) extend the same architecture without a rewrite.

## 2. Guiding Architectural Decision: why not full Serverpod persistence

`asami_server` used Serverpod's built-in Postgres ORM directly, and the DB coupling this created became a recurring source of friction — model changes required migrations tightly bound to Serverpod's generator, and swapping or federating storage per-tenant later would have meant significant rework.

`degenbot_server` solved this by using **Serverpod Mini** conventions in spirit — Serverpod is kept purely for what it's excellent at (typed model generation from `.spy.yaml`, endpoint codegen, a generated Dart client for the Flutter/Jaspr front ends) — while **Supabase owns the actual schema and persistence**, accessed through a thin **repository + DTO layer**:

```
Serverpod .spy.yaml  →  generated Dart model (shape/source of truth)
                              │
                     BaseDto<T>.fromRow / .toRow
                              │
                    Repository (CoinCandidateRepository, TradeRepository, ...)
                              │
                        Supabase Postgres (schema we own; swappable later)
```

This is the pattern this platform adopts for **all** persisted domain models. Concretely:

- Every domain model is defined once as a `.spy.yaml` (gives us the generated Dart class + a generated client the Jaspr dashboard consumes).
- Every model gets a matching `XyzDto extends BaseDto<Xyz>` implementing `fromRow`/`toRow`.
- Every model gets a `XyzRepository` that is the *only* code allowed to talk to Supabase directly.
- Business logic and endpoints depend on repositories, never on Supabase or Postgres directly — so a business that wants to plug in their own Postgres/Supabase instance later (per PRD §8, "we don't even need storage") is a repository-level swap, not an application rewrite.

**Known constraint accepted:** Serverpod's own migration tooling assumes it owns the schema. Because we don't use it for persistence, schema migrations for our Supabase tables are managed independently (plain SQL migration files, tracked in `docs/migrations/`, mirroring the pattern already started in `degenbot_server/docs/migrations`). This is a deliberate trade — full Serverpod would give us "free" migrations at the cost of the coupling that hurt us on Asami.

## 3. Technology Stack

| Layer | Choice | Role in this system |
|---|---|---|
| Language | Dart | One language across server, web dashboard, and (future) mobile — matches existing team expertise across Asami/Degenbot |
| API/codegen | Serverpod 3.4.x | Endpoint definitions, request/response codegen, generated typed client for Jaspr/Flutter front ends. **Not** used for persistence (see §2) |
| Raw web/webhook server | Relic | Lightweight, type-safe request handling for raw webhook ingestion (WhatsApp/Meta webhooks, Paystack/Flutterwave webhooks, public health checks) where Serverpod's endpoint model is heavier than needed, and for anything that must respond in the exact shape a third party (Meta, Paystack) demands |
| Web dashboard + marketing site + docs site | Jaspr | **Confirmed pattern** (`DEVELOPMENT_PLAN.md` §4a), based on every real precedent project reviewed — `degenbot_web`, `kopicat` (root), `kopicat_landing` — all of which use **`jaspr: mode: client`** (static/compiled-JS), none SSR: one Jaspr app per surface (marketing/landing, authenticated dashboard, docs site), each built client-mode, one component per file. **Relic pairs with Jaspr on the server side, not inside Jaspr itself** — confirmed from `kopicat_server`: a standalone `RelicApp()` with chained `.get`/`.post` route registration and a `.fallback`, one `Handler get xHandler => (Request req) async {...}` per file under `lib/routes/`. Applied here: the dashboard is a `jaspr: mode: client` app calling our own Serverpod-generated client for typed endpoints (per "two doors, one house," `PRD.md` §8), with a thin Relic layer used only where Serverpod's endpoint model is heavier than needed (raw webhook ingestion, file upload, anything that must respond in a third party's exact shape — same role Relic already plays per the row above). **Open decision, resolved rather than left silent:** this confirmed client-mode-everywhere pattern is a deliberate departure from an earlier SSR-first assumption for the marketing site (made for SEO). Recommendation: stay client-mode across all three surfaces, matching every real precedent and avoiding a bespoke SSR build with no proven reference — revisit only if SEO performance data after launch says otherwise. |
| Persistence | Supabase (Postgres + Realtime) | Owns the actual schema; accessed only via repository/DTO layer (§2). Realtime channel usable later for live dashboard updates (e.g., "bot is typing," new conversation alerts) |
| Telegram channel | Televerse | Full Bot API 9.x coverage, conversation plugin for multi-turn flows, webhook server, middleware/filter system — same library already proven in Degenbot and Asami |
| WhatsApp channel | `whatsapp` (whatsapp-flutter) | WhatsApp Business API coverage: messages, media, templates, interactive buttons/lists, flows, catalog/product messages — same library already proven in Asami |
| Payments (built, not live at MVP) | Paystack + Flutterwave Dart services | Reuses the service/webhook-handler shape already built in `asami_server/lib/src/services/payment` |
| Image storage/transformation | ImageKit | Reuses `asami_server/lib/src/services/media/imagekit_service.dart` directly — powers the per-MB metered image upload capability in §6a |
| AI orchestration | Multi-provider agent layer (Claude / Gemini / OpenAI / Grok providers behind one interface, à la `asami_server/lib/src/services/ai_services`), or `dartantic_ai` where a lighter single-package option suffices (à la Degenbot) | Powers Bot Mother, in-conversation bot responses, Errand-calling, and document-grounded answers |
| Dependency injection | `get_it` | Consistent with both Degenbot and Asami |
| Config/secrets | `envied` (compile-time obfuscated env vars, `.env`-driven) | Consistent with Degenbot; avoids plaintext secrets in binaries |
| Logging | `talker` (+ a thin platform-specific logger wrapper, as in Degenbot's `degen_logger.dart` / Asami's `asami_logger.dart`) | Structured, environment-aware logging |

**Rule for new dependencies:** before writing a service from scratch, check `pub.dev` for a vetted, maintained package that already does it (per PRD product principle) — the above table is the current best-known set, not a closed list.

## 4. System Overview

```
                        ┌───────────────────────────────────────────┐
                        │        Jaspr Web (client-mode)             │
                        │  Marketing/Landing · Dashboard · Docs site │
                        └───────────────┬─────────────────────────────┘
                                        │ generated Serverpod client
                        ┌───────────────▼─────────────────────────────┐
                        │              Serverpod endpoints             │
                        │  Auth · Workspace · Bot · Errand · Knowledge │
                        │  Billing · ApiKey · Analytics                │
                        └───────────────┬─────────────────────────────┘
                                        │ repositories (DTO-bridged)
                        ┌───────────────▼─────────────────────────────┐
                        │                 Supabase                     │
                        │   Postgres (owned schema) + Realtime         │
                        └───────────────────────────────────────────────┘

  ┌───────────────────┐   ┌───────────────────┐   ┌───────────────────┐
  │   Televerse        │   │  whatsapp-flutter  │   │  Relic webhook     │
  │   (Telegram bot)   │   │  (WhatsApp Cloud   │   │  ingestion (Meta,  │
  │                     │   │   API client)      │   │  Paystack, FW)     │
  └─────────┬───────────┘   └─────────┬───────────┘   └─────────┬───────────┘
            │                          │                          │
            └────────────┬─────────────┴────────────┬────────────┘
                         ▼                            ▼
                  IMessagingService (interface) ── platform-agnostic send/receive
                         │
                         ▼
              Bot Runtime (per-tenant, per-bot conversation loop)
                    │           │              │
             AI Orchestrator  Knowledge      Errand Engine
           (multi-provider)   Retrieval    (built-in / webhook /
                                            DB-credential / MCP)
```

## 5. Multi-Tenancy & Data Isolation

- Every persisted row that belongs to a business carries a `workspaceId`. There is no cross-workspace query path in the repository layer — repositories accept a `workspaceId` and enforce it in the query, never trust a caller-supplied filter alone.
- API keys, Errands, knowledge documents, conversations, and bots all belong to exactly one workspace.
- A workspace can have multiple **members** (owner, staff, developer role) and, in Phase 2, an agency account can hold multiple workspaces.
- Row-level isolation is enforced at the repository layer *and*, where Supabase RLS is practical, at the database layer as a defense-in-depth measure.

## 6. Core Domain Model (Phase 1)

| Model | Purpose | Notes |
|---|---|---|
| `Workspace` | Tenant root. Name, industry tag, plan, trial dates, status | |
| `WorkspaceMember` | User↔Workspace with role (owner/staff/developer) | |
| `Bot` | A configured bot instance within a workspace | `archetype` enum: `customerCare`, `catalog`, `custom` (Phase 2+) |
| `Channel` | A connected messaging channel for a bot | `platformType`: `telegram` \| `whatsapp`; holds channel credentials (bot token / WABA phone number ID) |
| `Conversation` | A single end-customer thread with a bot | Reused shape from Asami's `Conversation`/`ConversationStatus` |
| `Message` | Individual inbound/outbound message | Reused shape from Asami's `Message`/`MessageType`, extended with a generic platform-agnostic `MediaType`/button/list model already defined in `IMessagingService` |
| `KnowledgeDocument` | An uploaded doc (PDF/DOCX/TXT/CSV/XLSX) plus its parsed/chunked representation | Parsing pipeline detailed in §8 |
| `Errand` | A registered bot capability (see PRD §5) | `source`: `builtin` \| `webhook` \| `dbCredential` \| `mcp` (Phase 2); `createdVia`: `naturalLanguage` \| `api`; permission scope; input schema; description used by the AI orchestrator to decide when to invoke it |
| `ErrandCredential` | Encrypted connection details for a webhook/DB/MCP-backed Errand | Encrypted at rest using the same AES-256-GCM approach already implemented for wallet keys in Degenbot (`wallet_encryption_service.dart`) — same pattern, different secret class |
| `ErrandExecutionLog` | Every Errand invocation: inputs (redacted per scope), result, latency, success/failure | Feeds both debugging and the Phase 3 fraud/abuse engine |
| `ApiKey` | Developer-facing credential, scoped to a workspace, revocable, rate-limited | |
| `CatalogItem` | Product/service entry for `catalog` archetype bots | Modeled on Asami's `Product`/`ProductVariant`, trimmed for MVP (no marketplace-wide category taxonomy needed yet) |
| `NegotiationOutcome` | Result of a catalog-bot price negotiation (agreed price, vendor notified via DM/email) | New for this platform; no live payment attached in MVP |
| `Subscription` / `UsageRecord` | Plan, trial window, metered usage (messages, Errand calls, documents) | Modeled on Asami's `Subscription`/`UsageRecord`/`DailyUsageTracker` |
| `WebhookEvent` | Generic inbound webhook record (Meta, Paystack, Flutterwave) before processing | Modeled on Asami's `WebhookEvent`, reused as-is |

**Phase 2 additions (design now, build then):** `PaymentTransaction`/`Refund`/`OrderEscrow` (already proven shapes in Asami), `FacebookCatalogLink`, `McpServerRegistration`.

### 6a. Image Storage — a built-in, metered Errand (MVP1)

A hunch worth formalizing: a non-technical business with no developer and no database — the cloth seller from `PRD.md`'s catalog example — still needs to get product photos into their bot. Uploading images is itself a capability that needs to exist without requiring any Errand configuration at all; it should just work as part of setting up a catalog item or a knowledge document.

- **Storage/transformation provider:** ImageKit — already proven in Asami's `media_service.dart`/`imagekit_service.dart`, so this is a direct reuse, not a new integration to design from scratch.
- **New model:** `MediaAsset` — workspace-scoped, stores the ImageKit file ID/URL, size in bytes, associated object (a `CatalogItem`, a `KnowledgeDocument`, or a conversation attachment), and upload timestamp.
- **Billing mechanic:** metered **per MB**, tracked via a `UsageRecord` entry (reusing the same usage-metering model as message/Errand-call usage, per Asami's `usage_class`/`usage_record` pattern) rather than a flat "storage add-on" — this keeps pricing proportional and simple to explain ("images are billed by size, like everything else you upload") rather than introducing a separate storage-tier concept.
- **Where it lives in the product:** the catalog item creation flow and the Knowledge upload flow (`SRS.md` §8) both use the same underlying upload primitive — one component, two entry points, consistent with the "don't build the same thing twice" principle already applied to Knowledge parsing.
- **Phase placement:** MVP1 — product photos are core to the catalog/negotiation bot archetype, which is already in MVP1 scope; this isn't a new feature so much as making an already-assumed capability explicit and correctly metered from day one, before usage-based billing habits are harder to introduce later.

## 7. The Errand System

This is the core technical differentiator and deserves its own section.

### 7.1 Two creation paths, one registry

- **Natural-language path (non-dev):** the business owner, talking to **Bot Mother**, says something like *"when a customer asks about their order, check my database and tell them the status."* Bot Mother:
  1. Detects intent to create a new Errand.
  2. Asks clarifying questions only where required (what should trigger it, what does it need to know, where does the answer come from).
  3. If the answer requires a data source the platform doesn't have yet (the business's own database), Bot Mother walks the owner through providing connection details in plain terms ("what's your database's web address / connection string — if you don't know, forward this message to whoever set up your database") and stores them as an `ErrandCredential`.
  4. Bot Mother (or the owner, reviewing a generated summary) confirms the Errand's description, inputs, and scope before it goes live.
- **API/developer path:** a developer with an API key calls the Errand-registration endpoint directly, or (Phase 1 fast-follow) points it at an OpenAPI spec to auto-derive input schema and description. Same underlying `Errand` row, same execution engine, same logs — **there is no second, parallel "dev version" of the Errand system.**

### 7.2 Execution model

Conceptually equivalent to a cloud function registry: an Errand is registered once (name, description, input schema, fulfillment target, permission scope) and then *called* by the AI orchestrator at conversation time, the same way `asami_server`'s `tool_registry.dart` + `tool_definition.dart` let the AI pick from `admin_tools` / `customer_tools` / `payment_tools` / `vendor_tools` based on who's asking and what they're asking for. We generalize that exact pattern: instead of four hardcoded tool files, Errands are **data-defined and tenant-scoped**, loaded into the AI's available-tools list per conversation based on the bot and the caller's role.

Fulfillment targets, in increasing order of platform trust required:

1. **Built-in** — Errands we ship (send a message, escalate to human, look up a knowledge answer).
2. **Webhook** — the business's own HTTP endpoint; we POST the inputs, they return a JSON result. Lowest setup friction for a business with any existing backend.
3. **Database credential** — read-only (default) or read/write connection to a business-supplied Postgres/MySQL/Supabase instance, used to answer specific, pre-approved query shapes only (never an open SQL console) — this is the "worst case, non-dev customer just wants their DB read" scenario from the brief, handled by Bot Mother collecting the credential and generating the specific query template the Errand needs, not by exposing raw database access.
4. **MCP** *(Phase 2)* — the business runs or has access to an MCP server; we register it as a live tool source rather than a single fixed Errand.

### 7.3 Safety

- Every Errand is scoped to a single workspace at creation and cannot be invoked outside that workspace's conversations.
- Every Errand execution is logged (`ErrandExecutionLog`) with inputs redacted according to the Errand's declared sensitivity.
- Rate limits apply per-Errand and per-workspace to prevent a compromised or runaway conversation from hammering a business's own systems.
- Database-credential Errands are read-only by default; write access is an explicit, separately-confirmed upgrade.

## 8. Document Parsing Engine ("Knowledge")

- Accepts PDF, DOCX, plain text, CSV/XLSX at MVP.
- Pipeline: extract text/tabular structure → chunk → store chunks with lightweight metadata (source doc, page/section) → index for retrieval.
- Retrieval is used by the AI orchestrator as grounding context before answering, and to detect when a question falls outside what the business has told the bot (triggering a human hand-off rather than a hallucinated answer).
- Same engine backs both bot archetypes: a customer-care bot's policy/FAQ doc and a catalog bot's price list/description sheet are both just Knowledge.

## 9. Messaging Abstraction Layer

Directly reuses the `IMessagingService` contract already implemented (and battle-tested for feature parity gaps between platforms) in both Degenbot and Asami:

- One interface (`sendText`, `sendMedia`, `sendButtons`, `sendList`, `sendLocation`, `markAsRead`, `replyToMessage`, `sendTypingIndicator`, `dispose`) that all bot logic depends on.
- Platform-specific extensions (`IWhatsAppMessagingService` for templates/flows/catalog/product messages, `ITelegramMessagingService` for polls/dice/contacts/media groups/message editing) for capabilities that don't have a cross-platform equivalent.
- A `PlatformFeatures` capability table (already written, verbatim reusable) so the AI orchestrator and dashboard UI can tell, per platform, what's actually possible (e.g., don't offer to build a WhatsApp "list" Errand response with 15 items — WhatsApp caps at 10 sections).
- This is exactly the seam that makes adding Instagram DM or SMS in Phase 3 an additive change, not a rewrite.

## 10. AI Orchestration & Security Filter

- Multi-provider by design (Claude, Gemini, OpenAI, Grok, or whichever future provider) behind one internal interface — never hard-coded to a single vendor, consistent with the product principle in the PRD and the pattern already built in Asami's `ai_services/providers`.
- A `security_filter` pass (already prototyped in Asami) runs before any AI-suggested Errand call or any AI-drafted outbound message that touches money, personal data, or an external system — this is the seam Phase 3's full fraud-prevention engine plugs into, so MVP guardrails and the eventual fraud engine share one integration point rather than being bolted on separately later.
- Conversation state (e.g., mid-negotiation on a catalog bot, mid-Errand-creation with Bot Mother) is modeled as an explicit state machine per conversation, following the proven shape of Asami's `ProductCreationStateManager` / `ProductCreationState` — multi-turn flows are resumable, time out safely, and don't rely on the AI "remembering" state implicitly.

## 11. Dual Dashboard Interface (Dev ↔ Non-Dev)

Both surfaces are views over the same underlying data — a business's Errands, bots, and knowledge are identical regardless of which surface created or is viewing them.

- **Conversational surface:** a chat-first interface (visually and interactionally close to a Claude-style assistant conversation) where the owner talks to Bot Mother to create/edit bots, Errands, and knowledge, with the AI proposing structured summaries the owner confirms.
- **Structured/dev surface:** a table/form/JSON-schema view of the exact same objects — bots, Errands (with their input schema, fulfillment target, and execution logs), API keys, webhooks — for a developer who'd rather see and edit structure directly than converse.
- A visible toggle switches between the two without losing context (switching mid-task keeps the object you were editing selected). This mirrors the two-pane "conversation + live structured plan" pattern seen in modern AI coding tools and agent builders, adapted to our object model rather than to code.
- Detailed page-by-page layout and visual direction is specified separately in `docs/DESIGN_PROMPT.md`, written for direct use with an HTML/CSS design-generation tool.

## 11a. WhatsApp/Meta Connection Flow

Full research and step-by-step detail: `META_CONNECT_FLOW.md`. Summary of what it means for this SRS:

- We integrate directly with Meta's Cloud API as a registered **Meta Tech Provider**, implementing **Embedded Signup** (Facebook Login for Business) so a business connects Facebook + WhatsApp entirely inside our product — no manual Meta Business Manager visit. This is now an MVP1 requirement (a real, small competitor already ships it, confirmed by hands-on testing), not a Phase 2 enhancement.
- Prerequisite work, ideally started in parallel with early engineering, not after: register a Meta App, request `whatsapp_business_management`, `whatsapp_business_messaging`, and `business_management` permissions, and pass Meta's App Review — this has its own external timeline independent of our sprint schedule and should be tracked as a critical-path item.
- The business still needs one real, dedicated phone number for production use — Embedded Signup removes the *dashboard friction*, not the *need for a number*. Onboarding copy must say this plainly, before the connect step, not after (Meta's own flow does this too, but easy to skim past — ours should be unmissable).
- **MVP1 is bring-your-own-number only.** We hold no numbers inventory and have no BSP relationship at launch — both are free to defer since the Embedded Signup integration itself costs nothing to build; only the number costs money, and that cost sits with the business, not us.
- A BSP partnership (360dialog/Gupshup/Twilio), or provisioning numbers ourselves, remains **revenue-gated** — worth revisiting once paying customers are asking for it, not a hard dependency or a scheduled phase.
- Phase 2's WhatsApp broadcast feature builds on Meta's **Marketing Messages (MM Lite) API** specifically — a delivery-optimized channel purpose-built for outbound template/marketing sends, distinct from the two-way Cloud API used for conversations.

## 12. API & Developer Experience

- Every dashboard action has a corresponding Serverpod endpoint; the dashboard is a client of the public API, not a privileged internal surface.
- Authentication: workspace-scoped API keys for programmatic access; session auth for the dashboard.
- Errand registration endpoint accepts either a manual schema or (fast-follow) an OpenAPI spec URL.
- Webhooks: outbound (we call the business's endpoint for webhook-backed Errands) and inbound (Meta/Paystack/Flutterwave call us) both flow through Relic-based routes for maximum control over response shape and latency.
- Developer documentation site built in Jaspr (`mode: client`, per §3's confirmed pattern — code-block components, versioned API reference) — content plan: Quickstart, Authentication, Errands (creating/registering/testing), Webhooks, Channels, Rate limits & plans, SDKs.

## 13. Non-Functional Requirements

- **Pluggability:** messaging channel, AI provider, and persistence backend are each behind an interface; no business logic imports a vendor SDK directly.
- **Multi-tenancy:** enforced at repository level and, where practical, at the database level (Supabase RLS).
- **Observability:** structured logging (`talker`) with workspace/bot/conversation correlation IDs; internal failures never surface as user-facing errors (per PRD principle), but are always logged with full context server-side. Include a **nightly channel-credential health check** (inspired directly by a pattern found in AppEdge Sabi's own privacy policy, `META_CONNECT_FLOW.md` §3): proactively validate every stored WhatsApp/Telegram access token and push a notification to the workspace owner if one is invalid or expiring, rather than letting a bot silently go dark and having the owner discover it days later from a customer complaint.
- **Security:** secrets via `envied` (obfuscated, never committed); Errand credentials encrypted at rest (AES-256-GCM, same primitive as Degenbot's wallet key encryption); API keys hashed at rest, shown once on creation.
- **Scalability:** stateless endpoint layer (Serverpod) behind a load balancer; bot runtime designed to be horizontally scalable per-conversation (no in-memory-only state that can't be rehydrated — lesson taken directly from Degenbot's `REFACTOR_NOTES.md` flag that in-memory position tracking doesn't survive a restart).
- **Internationalization readiness:** all user-facing copy routed through a single string/localization layer from day one, even though only English (Nigerian-inflected tone) ships at MVP — so Phase 3 language expansion doesn't require hunting down hardcoded strings.

## 14. Phase Mapping

| SRS component | PRD phase |
|---|---|
| Core domain model, Errand engine (builtin/webhook/DB-credential), Knowledge parsing, Telegram+WhatsApp channels, dual dashboard, dev docs site | Phase 1 |
| Live payment Errand, Facebook catalog, MCP Errand source, native WhatsApp/Telegram Bot Mother, agency multi-workspace | Phase 2 |
| Additional channels, full i18n, white-label, platform-wide fraud engine, Errand marketplace | Phase 3 |

## 15. Open Technical Questions

- Exact Supabase RLS policy design per table — needs a pass once the full Phase 1 schema is finalized.
- Whether Errand execution should run in-process or in an isolated worker/sandbox once webhook/DB-credential Errands are business-supplied (security boundary worth revisiting before Phase 1 code-complete, not before design).
- Final call on `dartantic_ai` vs. a bespoke multi-provider layer (Asami's approach) — recommend prototyping both against one real Errand-calling scenario before committing.
