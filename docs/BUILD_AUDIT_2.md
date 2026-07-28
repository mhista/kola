# Kola — Build Audit 2

**Date:** July 23, 2026
**Picks up from:** `BUILD_AUDIT.md` (dated July 22, 2026), which covered Phase 0–2 (product docs, server foundation, Telegram + WhatsApp manual connect). Everything in that document still stands — this one covers **everything built since**: Phase 3 (Errand engine, AI orchestrator, security filter, escalation), Phase 4 (dashboard, continued through 4e), Phase 5 (billing/trial/metering), Phase 6 (docs site), and the standalone debt items tracked as tasks #82, #86, #87, #88, #106, #107, #114, #121. Same rules as before: nothing here is guessed, every claim traces to a real file, and anything fixable without your local machine or a decision only you can make has already been fixed, not left as a note.

---

## 1. What's built since Build Audit 1

### Phase 3 — Errand Engine & AI Orchestration (done)

**Multi-provider AI orchestrator** — `kola_server/lib/src/services/ai/ai_orchestrator.dart`, behind an `AiProvider` interface. Cascades Groq → Gemini → OpenRouter, falling through to the next provider on any failure (bad key, quota, network error). All three are real working implementations, ported from `copycat`/`kopicat_server`'s existing cascade, not stubs.

**Errand system** — three models (`models/errand.spy.yaml`, `errand_credential.spy.yaml`, `errand_execution_log.spy.yaml`), workspace-scoped (not bot-scoped). Three fulfillment types, one dispatch point (`ErrandEndpoint.executeErrand`, keyed by `errand.source`):

| Type | File | What it does |
|---|---|---|
| Built-in | `services/errand/builtin_errand_executor.dart` | One real handler today: `escalateToHuman` |
| Webhook | `services/errand/webhook_errand_executor.dart` | POSTs input as JSON to a business URL, expects a 2xx + JSON object body back — no retry on failure |
| DB-credential | `services/errand/db_credential_errand_executor.dart` | A business's own Postgres connection string + exactly one pre-approved named-parameter query template (`package:postgres`'s `Sql.named`) — never open SQL. Read-only enforced twice: at registration and again at execution |

Every execution — success or failure — is logged via `ErrandExecutionLogRepository.logExecution`, which redacts sensitive input keys first.

**Grounded Q&A** — deliberately minimal, not `SRS.md` §8's full Document Parsing Engine: `Bot.knowledgeSeed` (plain text field) is injected into the AI orchestrator's system prompt by `BotKnowledgeService.answerGrounded`.

**Security filter** — `services/security/security_filter.dart`, ported from `asami_server`'s prototype, trimmed of Asami-specific role permissions. Pattern-based detection (prompt injection, SQLi, XSS, credential leakage, phishing, spam/rate limiting) at three checkpoints: inbound message, Errand input, and the AI's own outbound draft before it's sent. This is the MVP guardrail, not the eventual fraud engine — it's the seam that plugs into later.

**Escalation feature** — introduced mid-Phase-3, built as a full loop in one pass:

- `Conversation`/`Message` models (`bot` → `escalated` → `closed` state machine)
- `InboundMessageHandler` (`services/conversations/inbound_message_handler.dart`), shared by both `TelegramBotRegistry` and `WhatsAppBotRegistry`, replacing Phase 2's hardcoded canned replies — every inbound message now persists to a real Conversation/Message trail and gets a grounded answer
- Escalation trigger is a sentinel-token stand-in for real tool-calling, parsed by `BotKnowledgeService` into a `needsEscalation` flag
- `OwnerNotificationDispatcher` (`services/notifications/`) fans out to WhatsApp (from the workspace's own connected channel), a separate Kola-owned Telegram bot (`kola_notifier_bot.dart`), and email (`package:mailer`) — WhatsApp/email rate-limited per plan tier (`NotificationRateLimiter`), Telegram uncapped, SMS an explicit architecture-only placeholder (`sms_owner_notifier.dart` — no provider wired in)
- `ConversationEndpoint` — bare-bones inbox surface (`listEscalated`, `getMessages`, `sendHumanReply`, `closeConversation`)
- `OwnerNotificationEndpoint` — the two methods (`getSettings`/`updateSettings`) that make the whole notification system actually configurable from outside the server; without it `OwnerNotificationSettingsRepository.upsert` was unreachable

Migration `006_conversations_and_notifications.sql` covers all four new tables; `007_webhook_and_dbcredential_errands.sql` covers the webhook/DB-credential Errand fields.

### Phase 4 — Dashboard, continued (4d–4e done; Conversations/Integrations done; bot creation done)

Building on the Phase 4c static shell already covered in Audit 1:

**Real routing** via `jaspr_router` — `kola_dashboard/lib/app.dart` is a `StatefulComponent` holding a live Supabase session, `kola_client` `Client`, and selected `Workspace`. A single `redirect` callback gates access: no session → `/login`; session but no workspace → `/create-workspace`.

**Real auth** — `services/auth_service.dart` talks directly to Supabase Auth's REST API (signup/token/refresh) via plain `http`, not the `supabase` package. Sessions persist across reloads via `window.localStorage`. `kola_server` has no login endpoint of its own — it only verifies the resulting JWT.

**Real pages, now wired to `kola_client`:**

| Route | File | Backed by |
|---|---|---|
| `/login` | `pages/login_page.dart` | Supabase Auth REST |
| `/create-workspace` | `pages/create_workspace_page.dart` | `WorkspaceEndpoint.createWorkspace` |
| `/errands` | `pages/errand_builder_page.dart` | `ErrandEndpoint` (built-in Errands only — no UI for webhook/DB-credential types, which need a form promising a backend flow that isn't ready to expose yet) |
| `/knowledge` | `pages/knowledge_page.dart` | `BotEndpoint.setKnowledgeSeed` (bot picker + textarea, no file upload) |
| `/bots/new` | `pages/create_bot_page.dart` (task #114) | `BotEndpoint.createBot` — the flow that makes the rest of the dashboard actually reachable; before this, nothing in the UI could create the first Bot a workspace needs |
| conversations inbox | `pages/conversations_page.dart` | `ConversationEndpoint` |
| integrations | `pages/integrations_page.dart` | `OwnerNotificationEndpoint` |

**Correction to `DEVELOPMENT_PLAN.md`'s own Phase 4e note** (which says these three "deliberately stay on mock data" — that text is now stale): `DashboardHomePage`, `BotDetailChatPage`, and `BotDetailDevPage` have since all been wired to real `kola_client` calls (tasks #109–111) — real bots, channels, Errands, and conversation threads replace every one of Phase 4c/4d's hardcoded mock entries. Verified directly against the current source for this audit, not assumed from the plan doc's wording.

### Phase 5 — Billing, Trial, Metering (done)

**Usage metering** — `Subscription`, `UsageRecord` (daily rollup) models (`008_subscriptions_and_usage_records.sql`).

**Trial state machine** — `TrialStateMachine`/`EffectiveTier`, the 48-hour/14-day mechanic from `PRD.md` §10, swept hourly by `TrialSweepService` (runs once at server startup, then every hour via a plain `Timer.periodic` — no Serverpod FutureCall needed).

**Payment gateways, built but not switched on** — `PaystackService`/`FlutterwaveService` (`services/billing/`) wrap each provider's real documented API: initialize/verify transaction, webhook signature checks (Paystack: HMAC-SHA512 via `pointycastle`; Flutterwave: plain string comparison against a configured hash). Neither has been tested against a live sandbox — no real API keys or execution environment available here. **No checkout endpoint and no webhook route exist yet** — these are wrappers ready for an Errand/endpoint to call, not a live payment path.

**Plan limits, now numbered** — `services/billing/plan_limits.dart`. The two business-decision numbers were confirmed with you directly rather than invented: **50** capped-free daily messages (`InboundMessageHandler`), **3** capped-free active Errands (`ErrandEndpoint`'s three create methods). The third number, a 2,000-character knowledge-seed cap (`BotEndpoint.setKnowledgeSeed`), is flagged in the file itself as an engineering placeholder, **not** confirmed with you — worth a real decision later, not a bug.

### Phase 6 — Developer docs site (done)

`kola_docs` — new standalone Jaspr client-mode package, same scaffolding as `kola_landing`. Pages: Quickstart, Authentication, Errands, Webhooks, Channels (with a dedicated Connect-WhatsApp walkthrough), Rate limits & plans, SDKs. Two deliberate, on-page-flagged deviations from the original spec: no version switcher (only one API version has ever existed) and no fabricated JS SDK tab (only Dart/`kola_client` and raw cURL examples are real, since no JS/Python SDK exists). The Connect-WhatsApp page carries over `WHATSAPP_MANUAL_SETUP.md`'s real screenshot placeholders rather than faking images — still blocked on task #88, same as the source doc.

### Cross-cutting debt items closed since Audit 1

| Task | What it was | What closed it |
|---|---|---|
| **#86** | WhatsApp used one shared webhook route across every business, dispatching by reading `metadata.phone_number_id` out of the payload | Migrated to per-channel routes (`/webhooks/whatsapp/<channelId>`), matching Telegram's shape. The old shared route + dispatch-by-payload logic is kept alive **on purpose**, not an oversight — see #87 below |
| **#106** | `SessionVerifier` only supported Supabase's legacy shared-secret (HS256) JWT verification | Rewritten to try JWKS-based ES256/RS256 verification first (fetches `<supabase_url>/auth/v1/.well-known/jwks.json`, 10-min cache), falling back to the legacy HS256 secret if no matching key is found. New `jwk_to_pem.dart` hand-builds the DER/PEM conversion `dart_jsonwebtoken` needs, since it has no native JWK support. **Not yet verified against a real migrated Supabase project** — no Dart toolchain or live migrated project available here. This is architecturally permanent (Supabase never publishes shared secrets via JWKS), not a temporary shim — it self-upgrades once you complete the one-time "Migrate JWT secret" step in the Supabase dashboard, with zero further code changes |
| **#107** | `kola_dashboard` is a client-routed SPA (`jaspr_router`) — a direct load of e.g. `/errands` needs to serve `index.html`, not 404 | Added `deploy.sh`. Turned out **no code fix was needed** — Cloudflare Pages (the deploy target) already does this automatically. The seemingly-obvious fix (a `web/_redirects` file with `/* /index.html 200`) was researched and confirmed to actually **break** the deployment — Cloudflare's build system detects that exact rule as an infinite loop and ignores it. Documented in `deploy.sh`'s header instead of added as a file |
| **#114** | No dashboard page could create a Bot — `ChannelEndpoint`'s connect methods both require an existing `botId`, but nothing in the UI could produce one | Built `pages/create_bot_page.dart` (`/bots/new`), wired from the sidebar's "+ New Bot" and a new dashboard-home quick action |
| **#121** | Plan limits existed as a state machine with no actual numbers | Confirmed the two business-decision caps with you directly (see Phase 5d above) rather than inventing them |
| **#82** | No nightly credential health check existed — a dead WhatsApp/Telegram token would silently go dark until a customer complained | **Built today.** New `services/messaging/channel_health_check_service.dart`: reuses each registry's already-decrypted, already-registered in-memory service (`TelegramBotRegistry.checkHealth`/`WhatsAppBotRegistry.checkHealth`, each making one real, cheap API probe — `getMe()`/`probe()`) rather than re-decrypting credentials from the DB. A failed or unregistered channel is marked disconnected (`ChannelRepository.markDisconnected`, which already existed, built for exactly this) and the workspace owner is notified via the existing `OwnerNotificationDispatcher.notify()` — no new notification machinery. Wired into `dependency_injection.dart` and `server.dart`: runs once at startup, then every 24 hours, positioned after both registries finish connecting so a channel that just hasn't bootstrapped yet isn't wrongly flagged. **Not yet verified via `dart analyze` or execution** — same standing caveat as everything else in this sandbox |

---

## 2. What you need to supply, and when

Everything in Audit 1's §2 (Supabase URL/service role key/JWT secret, admin token, channel credential master key, WhatsApp webhook verify token) still applies unchanged. New since then, all in `kola_server/.env.example`:

| Variable | Where to get it | Blocks what if missing |
|---|---|---|
| `GROQ_API_KEY` / `GEMINI_API_KEY` / `OPENROUTER_API_KEY` | Groq Console / Google AI Studio / OpenRouter — set at least one | Grounded Q&A and any AI-backed Errand logic. `AiOrchestrator` just skips any provider with an empty key, but with all three empty, nothing answers |
| `KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN` | A **separate** @BotFather bot, Kola's own (not a business's) | Telegram owner-escalation pings only — WhatsApp/email notification channels still work without it |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` / `SMTP_FROM_EMAIL` / `SMTP_FROM_NAME` | Any real SMTP provider (Gmail App Password, SendGrid, Postmark, Mailgun) | Email owner-escalation notifications only |
| `PAYSTACK_SECRET_KEY` / `FLUTTERWAVE_SECRET_KEY` | Paystack/Flutterwave dashboards | Nothing yet — no checkout endpoint calls either service |
| `FLUTTERWAVE_WEBHOOK_SECRET_HASH` | A string you set in Flutterwave's own dashboard | Nothing yet — no webhook route exists to check it against |

After adding any of these: re-run `dart run build_runner build` inside `kola_server/` (same step Audit 1 already asked for).

**Migrations to run, in order** (Audit 1 covered through `004`; run these four in addition, against the same Supabase project):

```
005_errands_and_knowledge_seed.sql
006_conversations_and_notifications.sql
007_webhook_and_dbcredential_errands.sql
008_subscriptions_and_usage_records.sql
```

**A live decision, when you're ready — not urgent:** Supabase's JWT Signing Keys migration ("Migrate JWT secret" then "Rotate keys" in your Supabase dashboard). Not required — the legacy HS256 path still works exactly as before — but once you do it, `SessionVerifier` automatically starts verifying against the new asymmetric keys with zero code changes on this end. You already told me this hasn't been done yet for the WhatsApp callback URL question (task #87, see below) — this is a **separate**, unrelated migration, purely about how dashboard login tokens are verified, not about WhatsApp at all.

**For `kola_dashboard` and `kola_docs`**, at build/deploy time only (same pattern as `kola_landing` in Audit 1): `SUPABASE_URL`, `SUPABASE_ANON_KEY` for the dashboard; `KOLA_SERVER_URL` for both, pointed at wherever `kola_server` is actually deployed. `wrangler` installed and logged in to Cloudflare, same as before.

---

## 3. Gaps — what's genuinely still open, and why

**Blocked on you specifically — cannot be closed from this side:**

- **Task #87 — remove the legacy shared WhatsApp webhook route.** You told me directly this has **not** been done yet: Meta's dashboard Callback URL for the first-connected WhatsApp channel has not been repointed to its new per-channel URL. Removing the legacy route or its dispatch code now would silently break that channel's live inbound messages. Left completely untouched until you confirm the repoint is done.
- **Task #88 — real screenshots for `WHATSAPP_MANUAL_SETUP.md`** (and the matching placeholders in `kola_docs`'s Connect-WhatsApp page). Needs your own live Meta/WhatsApp setup and physical screen captures — not something buildable from here.

**Genuinely still open, each with a real reason:**

| Gap | Why it's still open | What closes it |
|---|---|---|
| No checkout endpoint or payment webhook route | `PaystackService`/`FlutterwaveService` are real, tested-against-docs wrappers with nothing calling them yet — building a live money-collection path without a way to test it against a real sandbox key here felt riskier than leaving it as a ready-to-wire seam | A `PaymentEndpoint` (or a `collectPayment`-type Errand) + one webhook route per provider, once you're ready to test against real sandbox keys |
| SessionVerifier's JWKS/ES256 path is unverified against a real key | No Dart toolchain and no live migrated Supabase project available in this sandbox — the DER/PEM conversion code (`jwk_to_pem.dart`) is especially sensitive (security-critical) to leave unverified | Testing against a real migrated Supabase project once you're ready to do the migration — flagged again above in §2 |
| Knowledge-seed 2,000-char cap is an engineering placeholder, not a confirmed number | Unlike the message/Errand caps, this felt like an implementation detail rather than a business decision at the time it was written — but it directly affects what a capped-free business can store | A quick decision from you, same as the other two caps already got |
| No real automated tests beyond `dart run tool/test_*.dart` scripts | No Dart SDK in this sandbox to write and actually run `dart test` against — a test suite I can't execute risks looking thorough while being silently wrong, worse than none on a production project. Every piece of new logic was instead checked by hand: signature/type cross-referencing against the interface it implements | Real test-writing once you can run `dart test` locally and iterate against real failures |
| SMS owner-notification channel is architecture-only | `sms_owner_notifier.dart` has every interface/model slot but no provider wired in, by explicit instruction to "bake in the architecture" without building it yet | Picking an SMS provider (Termii, Africa's Talking, Twilio) and wiring one method |
| Meta Embedded Signup (automatic WhatsApp connect) still not built | Unchanged from Audit 1 — manual connect remains the primary, intentional path | A future, separate build; still no code depends on it existing |
| Phase 7 (deploy scripts for the server itself, Meta Business Verification, soft launch) not started | Correctly sequenced last — Phases 3–6 needed to be real before a launch checklist means anything | Proceeding to Phase 7 whenever you're ready |

---

## 4. Quick file map — new since Audit 1

| You want to... | Look at |
|---|---|
| See how a bot decides to escalate vs. answer | `services/knowledge/bot_knowledge_service.dart` → `services/conversations/inbound_message_handler.dart` |
| Change how owners get notified | `services/notifications/owner_notification_dispatcher.dart` (fan-out) → `whatsapp_owner_notifier.dart` / `kola_notifier_bot.dart` / `email_owner_notifier.dart` |
| Add a new built-in Errand handler | `services/errand/builtin_errand_executor.dart` |
| See the security guardrail patterns | `services/security/security_filter.dart` |
| Change the AI provider order/cascade | `services/ai/ai_orchestrator.dart` |
| Change plan-limit numbers | `services/billing/plan_limits.dart` |
| See the trial-to-paused sweep | `services/billing/trial_state_machine.dart` → `trial_sweep_service.dart` |
| See the nightly channel health check | `services/messaging/channel_health_check_service.dart` |
| See why the legacy WhatsApp route is still alive | `services/messaging/whatsapp/whatsapp_bot_registry.dart` header comment (search "LEGACY SHARED ROUTE") |
| See the JWKS/legacy-secret dual verification path | `services/auth/session_verifier.dart` header comment |
| Edit the dashboard's pages (all real now) | `kola_dashboard/lib/pages/*.dart` — every page in this package is wired to a real `kola_client` call; none render mock data anymore |
| Edit the docs site | `kola_docs/lib/pages/*.dart`, deploy via `kola_docs/deploy.sh` |
| Deploy the dashboard | `kola_dashboard/deploy.sh` (Cloudflare Pages SPA fallback — see header) |

---

## 5. Action checklist — what to actually do next

1. Run migrations `005` through `008` against your Supabase project (in order, after Audit 1's `001`–`004`).
2. Add at least one AI provider key (`GROQ_API_KEY` recommended) to `kola_server/.env` — nothing answers a customer question without one.
3. If you want owner escalation notifications working: add `KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN` and/or SMTP vars. Neither blocks the server from starting.
4. Re-run `dart run build_runner build` after any `.env` changes.
5. Test the new loop end to end by hand: create a workspace → create a bot (`/bots/new` in the dashboard, or `BotEndpoint.createBot` directly) → connect a Telegram channel → message it → confirm you get a grounded (not hardcoded) reply, and that an unanswerable question actually escalates and pings you.
6. Decide on the knowledge-seed character cap (currently an unconfirmed placeholder at 2,000) — same kind of quick call you already made for the message/Errand caps.
7. When you're ready to test payments: supply real Paystack/Flutterwave sandbox keys and tell me — building the checkout endpoint + webhook route is the next real gap to close, and it's better built against a real key than guessed at.
8. When you're ready: confirm whether Meta's dashboard Callback URL for the first WhatsApp channel has been repointed to its per-channel URL — that single confirmation unblocks task #87.
9. When you have your own Meta/WhatsApp setup open: capture the real screenshots task #88 needs.
10. When you're ready to migrate Supabase's JWT signing keys (optional, not urgent): let me know once it's done so I can verify `SessionVerifier`'s JWKS path against the real result.
11. When ready: proceed to Phase 7 (deploy scripts + Meta Business Verification + soft launch) per `DEVELOPMENT_PLAN.md`.
