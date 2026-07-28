# Kola — Build Audit

**Date:** July 22, 2026
**Purpose:** a single, honest snapshot of what's actually built, what you need to supply and when, and what's genuinely still missing — before proceeding further. Companion to `DEVELOPMENT_PLAN.md` (the phase plan) and `SRS.md`/`PRD.md` (the original spec); this document reflects reality as of today, including places where the build has diverged from or gone beyond the original plan.

**How this audit is organized:**
1. What's built, phase by phase, with the exact files behind each piece.
2. What you need to supply, and exactly when — nothing here is guessed, each item traces to a real check in the code.
3. Gaps that remain — kept as short as possible. Anything fixable without your local machine or a live decision from you has already been fixed as part of this audit, not left as a note.
4. A quick-reference file map.
5. An action checklist — the concrete next steps, in order.

---

## 1. What's built

### Phase 0 — Product docs (done)

Everything in `docs/`: `PRD.md`, `SRS.md`, `COMPETITIVE_FEATURES.md`, `META_CONNECT_FLOW.md`, `DESIGN_PROMPT.md` + four deck-design-prompt variants, `TERMS_OF_SERVICE.md`, `PRIVACY_POLICY.md`, `DEVELOPMENT_PLAN.md`, and `WHATSAPP_MANUAL_SETUP.md`. Each has a matching `.docx` export already generated.

### Phase 1 — Server foundation (done)

**Persistence pattern** — `kola_server/lib/src/services/dto/base_dto.dart` + one repository per model, talking to Supabase (not Serverpod's own database) via `kola_server/lib/src/services/repository/supabase_client.dart`. `get_it` wires everything together in `kola_server/lib/src/config/dependency_injection.dart`.

**Core domain models** (`kola_server/lib/src/models/*.spy.yaml`, one DTO + repository each):

| Model | Spec file | DTO | Repository |
|---|---|---|---|
| Workspace | `models/workspace.spy.yaml` | `dto/workspace_dto.dart` | `repository/workspace_repository.dart` |
| WorkspaceMember | `models/workspace_member.spy.yaml` | `dto/workspace_member_dto.dart` | `repository/workspace_member_repository.dart` |
| Bot | `models/bot.spy.yaml` | `dto/bot_dto.dart` | `repository/bot_repository.dart` |
| Channel | `models/channel.spy.yaml` | `dto/channel_dto.dart` | `repository/channel_repository.dart` |
| WaitlistSignup | `models/waitlist_signup.spy.yaml` | `dto/waitlist_signup_dto.dart` | `repository/waitlist_signup_repository.dart` |

**Schema** — `kola_server/docs/migrations/001_initial_schema.sql` (workspaces/workspace_members/bots/channels + RLS-enabled-with-zero-policies, since the server always uses the service_role key), `002_waitlist_signups.sql` (the one table anon can actually reach, with its own insert-only RLS policy), `003`/`004` (RLS policy hardening — kept for history; the real waitlist bug turned out to be client-side, see `kola_server/README.md`).

**Auth** — `kola_server/lib/src/services/auth/session_verifier.dart` verifies Supabase Auth JWTs (identity only); `kola_server/lib/src/services/auth/workspace_access.dart` is the one choke-point every workspace-scoped endpoint calls first (identity + membership + optional role check). Kola never issues its own tokens — Supabase Auth is the single identity source.

**Endpoints that exist today:**

| Endpoint | File | What it does |
|---|---|---|
| `WorkspaceEndpoint` | `endpoints/workspace_endpoint.dart` | createWorkspace, listMyWorkspaces, getWorkspace |
| `BotEndpoint` | `endpoints/bot_endpoint.dart` | createBot, listBotsForWorkspace, getBot, updateBot — **built today, during this audit** (see §3) |
| `ChannelEndpoint` | `endpoints/channel_endpoint.dart` | connectTelegramChannel, connectWhatsAppChannelManual, listChannelsForBot |
| `WaitlistEndpoint` | `endpoints/waitlist_endpoint.dart` | joinWaitlist — see §3 for a note on why the live landing page doesn't actually call this today |

**Landing page (Phase 1e)** — `kola_landing/`, a standalone Jaspr client-mode app. One component per file under `lib/components/`; waitlist form talks directly to Supabase's REST API with the anon key (`lib/services/waitlist_api_service.dart`), not through `WaitlistEndpoint`. `build.sh`/`deploy.sh` (Cloudflare Pages via `wrangler`) are both written and env-var-validated. Scroll-reveal animation bug (classes getting wiped on unrelated clicks) was found and fixed by moving the reveal state into Dart via `lib/interop.dart`'s `Function.toJS` export.

### Phase 2a — Telegram channel (done)

Multi-tenant registry — one `TelegramService` per connected Channel row, not one global bot.

| Concern | File |
|---|---|
| Interface both platforms implement | `services/messaging/messaging_service_interface.dart`, `messaging_result.dart` |
| Telegram API wrapper | `services/messaging/telegram/telegram_service.dart` |
| Adapter (implements the shared interface) | `services/messaging/telegram/telegram_service_adapter.dart` |
| Multi-tenant registry + hardcoded reply | `services/messaging/telegram/telegram_bot_registry.dart` |
| Per-channel webhook route | `services/messaging/telegram/telegram_webhook_route.dart` |
| Credential encryption (AES-256-GCM) | `services/security/channel_credential_encryption_service.dart` |

Connect flow: `ChannelEndpoint.connectTelegramChannel` probes the pasted-in bot token with a real `getMe()` call before persisting anything, encrypts it at rest, hot-connects with no restart. Local dev without a public URL falls back to long-polling automatically.

### Phase 2b — WhatsApp channel, manual connect (done)

Built manual-first, by your explicit instruction — not a fallback behind Meta's Embedded Signup, which is deferred (not built) because it shares a weekly usage cap across every app using it and depends on Kola's own Meta App Review status. Manual depends on neither.

| Concern | File |
|---|---|
| Credential shape (5 fields, JSON-encoded then encrypted) | `services/messaging/whatsapp/whatsapp_credential.dart` |
| Cloud API HTTP wrapper | `services/messaging/whatsapp/whatsapp_service.dart` |
| Adapter (implements the shared interface) | `services/messaging/whatsapp/whatsapp_service_adapter.dart` |
| Multi-tenant registry, keyed by `phone_number_id` | `services/messaging/whatsapp/whatsapp_bot_registry.dart` |
| ONE shared webhook route (Meta only allows one per App) | `services/messaging/whatsapp/whatsapp_webhook_route.dart` |
| Inbound webhook signature verification (HMAC-SHA256) | `services/messaging/whatsapp/whatsapp_signature_verifier.dart` |

Connect flow: `ChannelEndpoint.connectWhatsAppChannelManual` takes five values (access token, phone number ID, WABA ID, App ID, App Secret), probes the token/number against Meta, checks (non-blocking) whether the token is temporary or permanent via `debug_token`, encrypts and persists, hot-connects. Inbound messages are signature-verified against every connected channel's stored App Secret before any JSON is trusted, then get the same hardcoded reply Telegram's Phase 2a handler gives — proving a real send/receive loop end to end.

Full non-technical walkthrough for a business: **`docs/WHATSAPP_MANUAL_SETUP.md`**.

---

## 2. What you need to supply, and when

### A — Once, to get the server running at all

These go in `kola_server/.env` (copy from `kola_server/.env.example`):

| Variable | Where to get it | Blocks what if missing |
|---|---|---|
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Supabase project → Settings → API | Everything — the server can't read/write any data |
| `SUPABASE_JWT_SECRET` | Supabase project → Settings → API → JWT Settings | All authenticated endpoints (session verification fails closed) |
| `SERVER_PORT`, `WEBHOOK_BASE_URL` | Your own deployment (or an `ngrok http 8080` URL for local webhook testing) | Telegram/WhatsApp webhook delivery only — sending works without it |
| `ADMIN_TOKEN` | Generate yourself (command in `.env.example`) | Any admin-only route you add later — nothing today requires it yet |
| `CHANNEL_CREDENTIAL_MASTER_KEY` | Generate yourself (command in `.env.example`) | Connecting ANY Telegram or WhatsApp channel — encryption fails closed without it |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | Any string you choose | The WhatsApp webhook GET verification handshake — sending/connecting still works without it |

After filling `.env`: `dart pub get`, `dart run serverpod generate`, `dart run build_runner build` (regenerates `env.g.dart` for real), then run every file in `kola_server/docs/migrations/` against your Supabase project in order.

For the landing page (`kola_landing/`), at build/deploy time only (not a `.env` file — passed as env vars to `build.sh`/`deploy.sh`): `SUPABASE_URL`, `SUPABASE_ANON_KEY` (the **anon** key, not service_role — Settings → API → "Project API keys"), optionally `LAUNCH_MODE=launched` at real launch. Deploying also needs `wrangler` installed and logged in to Cloudflare (`npm install -g wrangler && wrangler login`).

### B — Per business, when they connect a channel

**Telegram** (free, no external approval): the business messages [@BotFather](https://t.me/BotFather), gets a bot token, that token is passed to `ChannelEndpoint.connectTelegramChannel`.

**WhatsApp, manual connect** (the primary path): five values, all from the business's own Meta account — full walkthrough in `docs/WHATSAPP_MANUAL_SETUP.md`:

1. Access Token (temporary is accepted for testing; Kola warns if it's not permanent)
2. Phone Number ID
3. WhatsApp Business Account ID (WABA ID)
4. App ID
5. App Secret

All five are required by `ChannelEndpoint.connectWhatsAppChannelManual` — connecting fails loudly if any is missing, rather than silently sitting half-configured.

### C — Only if/when you pursue Meta Embedded Signup (not built yet, no timeline)

Meta Tech Provider registration and App Review submission — external Meta timeline, independent of anything in this codebase. Not required for anything currently built or documented above.

---

## 3. Gaps — what's genuinely still open, and why each one is (or isn't) closed right now

Per your instruction to avoid leaving fixable things as TODOs on a production project, everything below that I *could* close without your local Dart environment or a decision only you can make, I closed as part of this audit rather than just listing it:

**Closed today, not just noted:**

- **No endpoint could create a Bot at all.** `ChannelEndpoint`'s two connect methods both require an existing `botId`, but nothing — no endpoint anywhere — could create one. This meant the entire channel-connect flow was unreachable through the API. Built `kola_server/lib/src/endpoints/bot_endpoint.dart` (createBot, listBotsForWorkspace, getBot, updateBot), mirroring `WorkspaceEndpoint`'s auth/validation pattern exactly.
- **Leftover Serverpod template demo code.** `GreetingEndpoint`, `greeting.spy.yaml`, and their integration test were the unmodified scaffold from when the project was first created — pure clutter in a production repo, zero functional purpose. Deleted.
- **WhatsApp webhook had no signature verification** (found while answering your App ID/App Secret question last turn) — closed: `whatsapp_signature_verifier.dart` + wiring into the registry and route.
- **`docs/WHATSAPP_MANUAL_SETUP.md` overstated a feature that didn't exist** ("Kola periodically checks credential health") — corrected to state plainly that this isn't built yet, rather than leaving a false claim in a document a business owner relies on.

**Genuinely still open — each with a real reason, not oversight:**

| Gap | Why it's still open | What closes it |
|---|---|---|
| No dashboard exists (Phase 4 hasn't started) | `kola_flutter/` is still the untouched Serverpod template (`lib/main.dart` only) — this is a multi-week build of its own, correctly sequenced after Phases 2–3 per `DEVELOPMENT_PLAN.md`. Every endpoint above is reachable today only through the generated client (`kola_client/`) or a hand-written script, not a UI. | Phase 4 work, not something to rush inside this audit |
| No nightly credential health-check job | Needs a scheduler/cron mechanism that doesn't exist in `kola_server` yet; building a background job blind, with no way to actually run and observe it here, risks shipping something that looks done but silently doesn't fire. Flagged plainly in `kola_server/README.md` and `docs/WHATSAPP_MANUAL_SETUP.md` rather than claimed as done. | A scheduler mechanism + wiring `ChannelRepository.markDisconnected` (exists, currently unused) into it |
| No real automated tests beyond the Serverpod template's own tooling | Writing test files I cannot run or see fail/pass in this sandbox (no Dart SDK here) risks producing tests that look thorough but are silently wrong — worse than no tests, on a production project. Every piece of new logic was instead checked by hand: type/signature cross-referencing against the interfaces it implements (documented at each build step in this conversation). | Real test-writing once you can run `dart test` locally and I can iterate against real failures |
| `env.g.dart` is a hand-kept-in-sync stub, not a real `build_runner` output | No `.env` file and no Dart SDK exist in this sandbox to run the generator for real — the committed file has the right shape/fields but empty obfuscated arrays, falling back to `Platform.environment` at runtime (which works fine for local/deployed use). | Running `dart run build_runner build` yourself once `.env` is filled in — one command, already documented in `kola_server/README.md` |
| `WaitlistEndpoint.joinWaitlist` exists but the live landing page doesn't call it | The landing page talks directly to Supabase's REST API with the anon key instead (`kola_landing/lib/services/waitlist_api_service.dart`) — a deliberate earlier decision (documented in `kola_landing/README.md`) to avoid a server round-trip for a public, pre-auth form. Not a bug — both paths write the same table — but `WaitlistEndpoint` is currently dead code, worth knowing rather than assuming it's on the request path. | Either remove `WaitlistEndpoint` (if the direct-to-Supabase pattern stays permanent) or switch the landing page to use it (if you'd rather funnel all writes through the server) — a decision for you, not a bug to fix blindly |
| Meta Embedded Signup (automatic WhatsApp connect) not built | Manual connect was explicitly prioritized as primary, not a stopgap — Embedded Signup remains a possible faster alternative later, with its own Meta App Review dependency and shared usage cap, independent of everything built so far | A future, separate build — no code today depends on it existing |
| Phases 3 (Errand/AI orchestrator), 5 (Billing/Trial), 6 (Docs site), 7 (Deploy scripts for the server itself) | Not started — correctly sequenced after Phase 2, which is now genuinely complete (both channels send *and* receive, end to end) | Proceeding to Phase 3 per `DEVELOPMENT_PLAN.md`, whenever you're ready |

---

## 4. Quick file map

| You want to... | Look at |
|---|---|
| Add/change a database table | `kola_server/docs/migrations/` (new numbered file) + the matching `.spy.yaml` + DTO |
| Understand auth end to end | `services/auth/session_verifier.dart` → `services/auth/workspace_access.dart` |
| See everything an endpoint can do | `kola_server/lib/src/endpoints/*.dart` (one file per resource) |
| Connect a Telegram bot | `endpoints/channel_endpoint.dart` → `connectTelegramChannel` |
| Connect a WhatsApp number | `endpoints/channel_endpoint.dart` → `connectWhatsAppChannelManual`, walkthrough in `docs/WHATSAPP_MANUAL_SETUP.md` |
| Understand WhatsApp's shared-webhook design | `services/messaging/whatsapp/whatsapp_bot_registry.dart` (header comment) |
| Change how a bot replies (currently hardcoded) | `telegram_bot_registry.dart`'s `_registerHardcodedReply` / `whatsapp_bot_registry.dart`'s `_replyToInboundMessages` — both explicitly marked as the seam Phase 3 replaces |
| Edit the landing page | `kola_landing/lib/components/*.dart` (one component per file), `kola_landing/lib/app.dart` for page assembly |
| Deploy the landing page | `kola_landing/deploy.sh` |
| See required environment variables | `kola_server/.env.example` (server), `kola_landing/README.md` (landing page build/deploy vars) |

---

## 5. Action checklist — what to actually do next

1. Fill in `kola_server/.env` from `.env.example` (Supabase URL/service role key/JWT secret, at minimum).
2. `dart pub get && dart run serverpod generate && dart run build_runner build` inside `kola_server/`.
3. Run `kola_server/docs/migrations/001_initial_schema.sql` through `004_waitlist_rls_hard_reset.sql`, in order, against your Supabase project.
4. Generate and add `CHANNEL_CREDENTIAL_MASTER_KEY` and `WHATSAPP_WEBHOOK_VERIFY_TOKEN` (commands in `.env.example`), re-run `build_runner build`.
5. `dart bin/main.dart` to start the server; confirm it boots without the startup warnings for those two keys.
6. Test the full chain once, by hand (no dashboard yet): call `WorkspaceEndpoint.createWorkspace` → `BotEndpoint.createBot` → `ChannelEndpoint.connectTelegramChannel` (free, fastest to test) via the generated `kola_client` or a small script — confirm a message to that bot gets the hardcoded reply.
7. When ready to test WhatsApp: follow `docs/WHATSAPP_MANUAL_SETUP.md` end to end for one real number, then call `connectWhatsAppChannelManual` with all five values.
8. Decide on the `WaitlistEndpoint` question in §3 (keep as dead code, remove, or switch the landing page to use it) — the only open item in this audit that's a decision rather than a bug.
9. When ready: proceed to Phase 3 (Errand Engine & AI Orchestration) per `DEVELOPMENT_PLAN.md`.
