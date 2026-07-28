# kola_server

Kola's Serverpod Mini server — used for endpoint/model codegen and the generated Dart client only. Supabase owns persistence; see `lib/src/services/repository/` and `docs/DEVELOPMENT_PLAN.md` in the project root for the full architecture rationale.

**No Postgres/Redis needed** — this project doesn't use Serverpod's own database, only Supabase (a hosted Postgres). The `docker compose` step from the default Serverpod template doesn't apply here.

## Security note (found and fixed during a production audit)

`.env.example` — the file meant to be safely committed as a placeholder-only template — had somehow ended up holding real, live Supabase credentials (a service_role key and JWT secret), and `.gitignore` had **no `.env` entry at all**, so nothing was stopping a real `.env` from being committed either. Both are fixed: the real values now live in a real (untracked) `.env`, `.env.example` is placeholder-only again, and `.gitignore` excludes `.env`/`.env.local`/`.env.*.local` going forward.

No `.git` directory exists in this project as of this fix, which is the most likely reason nothing has leaked yet — but that couldn't be confirmed with certainty. **If this repo has ever been pushed to any remote with real values in `.env.example`, rotate the Supabase service_role key and JWT secret from the Supabase dashboard regardless of whether you can confirm exposure.** Rotating costs a few minutes; guessing wrong about whether something leaked doesn't.

## Getting started (Phase 1 — first run)

1. `cp .env.example .env` and fill in your Supabase project URL, service role key, and JWT secret (Project Settings > API) — skip this if you already have a real `.env` from the fix above.
2. **Run codegen — required before this compiles.** `Workspace`, `WorkspaceMember`, `Bot`, `Channel`, `Errand`, `ErrandCredential`, `ErrandExecutionLog`, `Conversation`, `Message`, `OwnerNotificationSettings`, `OwnerNotificationSend` (models) and `WorkspaceEndpoint`, `BotEndpoint`, `ChannelEndpoint`, `ErrandEndpoint`, `ConversationEndpoint`, `OwnerNotificationEndpoint`, `WaitlistEndpoint` (endpoints) were all added by hand-authoring their `.spy.yaml`/Dart source, but the *generated* files (`lib/src/generated/protocol.dart`, `endpoints.dart`, and one file per model) haven't been regenerated since some of these were added:
   ```
   dart pub get
   dart run serverpod generate
   dart run build_runner build --delete-conflicting-outputs   # generates env.g.dart from env.dart
   ```
3. Run every file in `docs/migrations/` against your Supabase project, in order, via the SQL Editor (Dashboard → your project → SQL Editor → New query) — currently `001_initial_schema.sql` (workspaces/workspace_members/bots/channels), `002_waitlist_signups.sql` (waitlist_signups + its anon-insert RLS policy), `003_fix_waitlist_rls.sql` and `004_waitlist_rls_hard_reset.sql` (re-applying/hardening that same policy), `005_errands_and_knowledge_seed.sql` (errands/errand_credentials/errand_execution_logs + `bots.knowledge_seed`), `006_conversations_and_notifications.sql` (conversations/messages/owner_notification_settings/owner_notification_sends), `007_webhook_and_dbcredential_errands.sql` (`errands.query_template_sql`).

   **If you were chasing a persistent 42501 "violates row-level security policy" error on waitlist inserts and 003/004 didn't fix it: the real bug wasn't in the database at all.** `kola_landing`'s `waitlist_api_service.dart` used to call PostgREST with `on_conflict=email` + `Prefer: resolution=merge-duplicates` (an upsert) to mirror `WaitlistSignupRepository.upsertByEmail`'s server-side behavior. Postgres requires UPDATE privilege for *any* `INSERT ... ON CONFLICT DO UPDATE` statement to be planned at all — not just when a conflict actually happens — and anon deliberately has no UPDATE policy on this table (visitors should never be able to modify an existing row). That made every anon-key submission fail this way, fresh email or repeat. Fixed by dropping the upsert entirely: the landing page now does a plain INSERT and treats a 409 (duplicate email) as a successful "already on the list" outcome. No further SQL changes needed beyond 002 — 003/004 were correct and harmless, just not the actual fix.
4. Then run the server:
   ```
   dart bin/main.dart
   ```

(These three steps couldn't be run from the environment that authored this code — no Dart SDK was available there — so treat this as the first real verification pass on this Phase 1 work.)

## Database migrations (`docs/migrations/`)

Every schema change — a new table, a new column, a new RLS policy — gets its own numbered file here (`001_...`, `002_...`, ...), same convention already proven in `degenbot_server/docs/migrations/`. Each file is self-contained: a header comment explaining what it does and why, `create table if not exists`/`create index if not exists` so it's safe to re-run, and any RLS policy the new table needs written right alongside it, not as an afterthought. DTO file comments (`lib/src/services/dto/*.dart`) point at the relevant migration file rather than repeating the SQL inline, so there's exactly one place the actual schema can drift from what the code expects.

**Going forward: whenever a new model or table is added to this project, a corresponding migration file belongs in this folder — not just the `.spy.yaml`/DTO/repository.**

## Phase 2a — Telegram channels

Every business connects **their own** Telegram bot (created via [@BotFather](https://t.me/BotFather) — the Telegram equivalent of "bring your own number" for WhatsApp in `docs/META_CONNECT_FLOW.md`), not a shared Kola-wide bot. That's why `lib/src/services/messaging/telegram/telegram_bot_registry.dart` runs one `TelegramService` per connected `Channel` row rather than one global bot the way `degenbot_server` does — see that file's header comment for the full reasoning.

**One-time setup:**

1. Generate the channel-credential encryption key (protects stored bot tokens at rest, same AES-256-GCM approach as Degenbot's wallet encryption). `dart -e` is **not** a real Dart CLI flag — found that out the hard way against a real install — so use Node instead:
   ```
   node -e "console.log(require('crypto').randomBytes(32).toString('base64url'))"
   ```
   No Node? PowerShell (Windows, no extra installs needed):
   ```
   $b=New-Object byte[] 32; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); ([Convert]::ToBase64String($b)).Replace('+','-').Replace('/','_').TrimEnd('=')
   ```
   Put the output in `.env` as `CHANNEL_CREDENTIAL_MASTER_KEY`.
2. Add `televerse` and `pointycastle` to your local pub cache: `dart pub get` (both are now in `pubspec.yaml`).
3. Re-run codegen if you haven't already — `ChannelEndpoint` is a new endpoint, same "run `dart run serverpod generate`" requirement as every other endpoint added by hand.

**Connecting a bot (once the server is running):**

1. In Telegram, message [@BotFather](https://t.me/BotFather), send `/newbot`, follow the prompts — you'll get back a token that looks like `123456789:AAH...`.
2. Call `ChannelEndpoint.connectTelegramChannel(accessToken, workspaceId, botId, botToken)` from the dashboard (or `dart run bin/main.dart` + a quick script while there's no dashboard UI for this yet). The endpoint probes the token against Telegram's real API before saving anything, so a bad paste fails immediately with a clear error instead of silently sitting in the DB.
3. On success, the channel is `connected`, its token is encrypted at rest, the bot is now `live`, and — with no server restart — messaging that bot on Telegram gets a real reply routed through this server. Phase 2a's reply was a hardcoded/simple response; as of the Phase 3 escalation feature (see below), replies now go through `InboundMessageHandler`/`BotKnowledgeService` — a real grounded AI answer, with automatic escalation to a human when the bot can't help.

**Local dev without a public URL:** leave `WEBHOOK_BASE_URL` empty in `.env` and every connected bot falls back to long-polling automatically — no ngrok required for day-to-day development. Set `WEBHOOK_BASE_URL` to an ngrok URL pointing at **webServer's port, not apiServer's** — see server.dart's header on why there are two separate ports. apiServer listens on whatever `SERVER_PORT` is set to in **your own** `.env` (the `.env.example` default is 8080, but override it and apiServer moves with it); webhook routes live on `SERVER_PORT + 1` (webServer) — always one above whatever apiServer's port actually is, computed at runtime in server.dart (`webServerPort = webPort + 1`), never a fixed number. So: check `SERVER_PORT` in your own `.env` first, then run `ngrok http <that value + 1>`. Pointing ngrok at `SERVER_PORT` itself (apiServer) will 404 on every `/webhooks/...` path, since that route doesn't exist on apiServer at all — this is the exact bug behind a 404 on `/webhooks/whatsapp` when ngrok's "Forwarding" line shows apiServer's port instead of apiServer's port + 1.

## Phase 2b — WhatsApp channels (manual connect)

**Every connected number now gets its own webhook route** (`/webhooks/whatsapp/<channelId>`), the same shape as Telegram's per-channel routes — Meta's "one callback URL per App" limit is per-App, not platform-wide, and Kola's manual-connect design already has each business register their own separate Meta App, so each one can be given a distinct URL. `WhatsAppBotRegistry.connectChannel`/`bootstrapFromDb` register this route automatically; the resulting URL is `WhatsAppBotRegistry.instance.webhookUrlFor(channelId)`.

**One shared legacy route (`/webhooks/whatsapp`, no channelId) is still registered too, deliberately** — the first channel ever connected is still verified against that exact URL in Meta's dashboard, and re-doing that handshake for zero functional gain isn't worth the churn. It dispatches by reading `metadata.phone_number_id` out of the payload (the original design), since it has no channel identity from its URL. See `whatsapp_bot_registry.dart` and `whatsapp_webhook_route.dart`'s file headers for the full "legacy mode" reasoning — safe to delete both the route registration in `server.dart` and the legacy code paths once every channel has migrated to its own per-channel URL.

**Two ways to connect a number**, both landing on the same `Channel` row/encrypted-credential shape:

1. **Manual** (built first, and the primary path — not a fallback): the business generates their own long-lived access token from their own Meta App via a System User with Standard Access, following `docs/WHATSAPP_MANUAL_SETUP.md` (a full non-technical walkthrough), then pastes the access token, phone number ID, WABA ID, App ID, and App Secret into Kola. `ChannelEndpoint.connectWhatsAppChannelManual` probes the token/number combination against Meta's real API before saving anything (same "fail loud on a bad paste" pattern as `connectTelegramChannel`), and also calls `WhatsAppService.debugToken` to warn — non-blocking — if the connected token is the short-lived temporary kind rather than a permanent System User token. This path needs **zero App Review approval on Kola's side**, since a WhatsApp access token's validity is checked against the token's own grants, not against which server calls the API (see `whatsapp_service.dart`'s header comment for the full auth-model reasoning) — so it's never blocked by anything outside the business's own control.
2. **Automatic** (Meta Embedded Signup) — not yet built. Reserved for later as a faster one-click alternative when Meta's weekly Embedded Signup allotment permits it; manual stays available regardless, since it doesn't share that cap.

**Why App ID/App Secret are collected, not just the three values needed to send:** every inbound webhook Meta delivers is signed with the App Secret of whichever Meta App owns the callback URL that received it. For a channel on its own per-channel route, the URL already tells you which channel — and therefore which one secret — to check (`WhatsAppBotRegistry.verifyWebhookSignatureForChannel`). The one remaining legacy shared route has no such URL-derived identity, so it still tries every currently-connected channel's stored App Secret against the `X-Hub-Signature-256` header (`verifyWebhookSignatureLegacy`) — both run on the raw request body, BEFORE any JSON parsing, and `whatsapp_webhook_route.dart` returns 403 immediately if the check fails. Without this, either route (neither URL is itself a secret) would accept a POST from anyone who found it. Channels connected before this field existed decode `appSecret` as `''` and simply never match — they keep sending fine, but can't pass signature verification until reconnected.

**One-time setup (per channel):**

1. Set `WHATSAPP_WEBHOOK_VERIFY_TOKEN` in `.env` — any string you choose, must exactly match the "Verify Token" you enter in Meta's App Dashboard → WhatsApp → Configuration → Webhooks once you're ready to receive inbound messages. This is one shared value across every business (it only proves URL ownership to Meta during setup, not message authenticity — that's the App Secret's job), not needed at all for a manually-connected number to *send* messages.
2. After connecting a channel, set its webhook **Callback URL** in that business's Meta dashboard to `WhatsAppBotRegistry.instance.webhookUrlFor(channelId)` — its own distinct URL, not the shared legacy one. Meta immediately sends a GET verification request; `whatsapp_webhook_route.dart` handles that handshake automatically as long as `WHATSAPP_WEBHOOK_VERIFY_TOKEN` matches. (No dashboard UI surfaces this URL to the business yet — see `tool/connect_whatsapp_manual_test.dart` for how it's obtained today.)
3. Re-run codegen if you haven't already since `connectWhatsAppChannelManual` was added to `ChannelEndpoint`.

**Nightly credential health check (task #82) — built.** `ChannelHealthCheckService` (`lib/src/services/messaging/channel_health_check_service.dart`) now proactively re-checks every connected Telegram/WhatsApp channel's credential — one real, cheap API probe each (`getMe()`/`probe()`) reusing the already-decrypted service each registry already holds in memory, no re-decryption from the DB. Runs once at server startup, then every 24 hours (`server.dart`), positioned after both registries finish connecting. A failing channel is marked disconnected and the workspace owner is notified through the same `OwnerNotificationDispatcher` the escalation feature uses — so an outage now surfaces as a heads-up notification, not just "messages silently stopped." Not yet verified via `dart analyze` or a live run — no Dart toolchain available in the environment that authored it, same caveat as the rest of this file's Phase 3+ work.

**Local dev without a public URL:** the webhook route only matters for *receiving* messages — sending, and the manual-connect flow itself, work over plain outbound HTTPS with no public URL needed at all. Use `ngrok http <SERVER_PORT + 1>` (webServer's port, not apiServer's `SERVER_PORT` — see the port note above) only once you want to test inbound message delivery.

**Phase 2b scope note (superseded — see the Phase 3 escalation feature section below):** `WhatsAppBotRegistry`'s original hardcoded/simple reply proved a real send/receive loop end to end. Text messages now route through the same `InboundMessageHandler` Telegram uses — a real grounded AI answer, with automatic escalation to a human when the bot can't help. Non-text inbound (image/location/etc.) still just gets a plain acknowledgement.

## Phase 3a — AI orchestrator

`AiOrchestrator` (`lib/src/services/ai/ai_orchestrator.dart`) is the one thing any bot logic or Errand execution should ever call for an AI answer — nothing else imports a provider class or calls a vendor API directly, same "pluggable behind one interface" rule messaging channels already follow.

**Providers, tried in this order, falling through to the next on any failure:**

1. **Groq** (`GROQ_API_KEY`) — fast, generous free tier, tried first.
2. **Gemini** (`GEMINI_API_KEY`) — fallback.
3. **OpenRouter** (`OPENROUTER_API_KEY`, free model only) — last resort.

Ported directly from `copycat`/`kopicat_server`'s `lib/ai.dart` cascade rather than reinvented — chosen specifically for cost efficiency (all three have real free tiers) by explicit product decision, with switching to a different provider or reordering priority left as a one-line change to `AiOrchestrator`'s constructor once real usage data justifies it. All three are fully working implementations, not stubs.

**Setup:** add at least one of the three API keys to `.env` (see `.env.example` for free-tier signup links), then:

```
dart run build_runner build --delete-conflicting-outputs
dart run tool/test_ai_orchestrator.dart
```

The server itself starts fine with all three keys empty — `AiOrchestrator` just has nothing to call until at least one is set, and throws a clear "no provider configured" error only when something actually tries to use it.

**Scope note (updated, task #134):** `complete()` is still plain text in/out, unchanged. Real function/tool-calling shipped alongside it as `completeWithTools()` — see Phase 3f below.

## Phase 3b — Errand system + grounded Q&A

**Errand, ErrandCredential, ErrandExecutionLog** (`lib/src/models/errand*.spy.yaml`, DTOs/repositories under `lib/src/services/{dto,repository}/errand*`) — an Errand is workspace-scoped, not bot-scoped (SRS.md §7.3: "scoped to a single workspace at creation"), registered via `ErrandEndpoint.createBuiltinErrand`. Every invocation is logged unconditionally (success or failure) by `ErrandExecutionLogRepository.logExecution`, which also redacts any input key listed in the Errand's `sensitiveInputKeysJson` before persisting — SRS.md §7.3's "inputs redacted per scope," actually implemented, not just documented as a goal.

**Built-in fulfillment only, at first:** `BuiltinErrandExecutor` (`lib/src/services/errand/builtin_errand_executor.dart`) has exactly one real handler — `escalateToHuman`, matching PRD.md §6's customer-care requirement to "escalate what it can't answer." Webhook and database-credential fulfillment (SRS.md §7.2's other two targets) shipped in Phase 3c below.

**Grounded Q&A, deliberately minimal:** `Bot.knowledgeSeed` (a single pasted-in text field) + `BotKnowledgeService.answerGrounded` inject that text whole into `AiOrchestrator`'s system prompt — satisfying Phase 3's "answer a question grounded in a manually-seeded piece of knowledge" bar without building SRS.md §8's real Document Parsing Engine (PDF/DOCX/CSV/XLSX upload, chunking, retrieval), which is separate, larger, later work. `BotEndpoint.setKnowledgeSeed` is the one write path for it.

**Test both without a UI:**
```
dart run tool/test_builtin_errand.dart --reason="customer wants a refund I can't approve"
dart run tool/test_grounded_qa.dart --seed="We're open 9am-6pm Mon-Sat." --question="What are your hours?"
```

## Phase 3c — Webhook + database-credential Errand types

The other two fulfillment targets from SRS.md §7.2, "in increasing order of platform trust required": a business's own HTTP endpoint (`webhook`), then a read-only-by-default connection to a business-supplied database (`dbCredential`), restricted to one pre-approved query per Errand — never an open SQL console.

**Webhook Errands** (`ErrandEndpoint.createWebhookErrand`, `lib/src/services/errand/webhook_errand_executor.dart`) — POSTs the Errand's input as JSON to a registered URL, with an optional single auth header (`webhook_errand_credential.dart`), and expects a JSON object back. The credential (URL + optional header) is AES-256-GCM-encrypted at rest via the same `ChannelCredentialEncryptionService` Telegram/WhatsApp tokens already use — SRS.md §6's own note that this is "the same pattern, different secret class," now actually reused rather than just described.

**Database-credential Errands** (`ErrandEndpoint.createDbCredentialErrand`, `lib/src/services/errand/db_credential_errand_executor.dart`) — a business supplies their own Postgres connection string (Supabase's own direct-Postgres URL works fine here — the same kind of database Kola itself runs on, just a different one) and exactly one pre-approved query template using `@name` syntax (`Errand.queryTemplateSql`). Execution runs that ONE template via `package:postgres`'s `Sql.named(...)`, filling in whatever named parameters the customer-facing input supplies — there is no path from an Errand invocation to arbitrary SQL. If `permissionScope` is `readOnly` (the default), both the create endpoint AND the executor independently verify the template starts with `SELECT`, rejecting anything else — a defense-in-depth check against the template being edited to something unsafe later without a matching upgrade to `readWrite`.

**Postgres only, for now:** SRS.md §7.2 also mentions MySQL — deliberately deferred, a separate driver/executor entirely rather than a small extension of this one, same "one real path now, defer the rest honestly" pattern as `SmsOwnerNotifier`.

**One execute method for every Errand type:** `ErrandEndpoint.executeErrand` dispatches by `errand.source` to whichever executor applies (builtin/webhook/dbCredential) — `executeBuiltinErrand` is kept alongside it for anything already calling that directly.

**Test both without a UI:**
```
dart run tool/test_webhook_errand.dart
dart run tool/test_db_credential_errand.dart --connection-string="postgresql://user:pass@host:5432/postgres"
```
(`test_webhook_errand.dart` spins up its own throwaway local HTTP server — no external service needed. `test_db_credential_errand.dart` needs a real Postgres connection string; defaults to a harmless `select @n::int as n` query if you don't want to point it at a real table yet.)

## Phase 3d — Security filter pass

SRS.md §10: "A security_filter pass (already prototyped in Asami) runs before any AI-suggested Errand call or any AI-drafted outbound message that touches money, personal data, or an external system — this is the seam Phase 3's full fraud-prevention engine plugs into." `SecurityFilter` (`lib/src/services/security/security_filter.dart`) is ported from `asami_server`'s prototype — reused, not reinvented — trimmed down to what actually applies here: Asami's version carries vendor/customer/admin role-based tool permissions with no Kola equivalent; kept are the pattern-based abuse detectors (prompt injection, SQL injection, XSS, credential leakage, phishing, spam/repetition) and rate limiting, which are generic.

**Three checkpoints, matching SRS.md §10's three trigger moments:**
- `checkInboundMessage` — every customer message, wired into `InboundMessageHandler` BEFORE it ever reaches `BotKnowledgeService`/`AiOrchestrator`. A blocked message never touches the AI; the customer gets the filter's own safe warning text back instead, and it does not count as an escalation.
- `checkErrandInput` — every Errand invocation's input, wired into `ErrandEndpoint.executeBuiltinErrand`/`executeErrand`, BEFORE any executor makes an external call. Deliberately redundant with `dbCredential`'s structural protection (`Sql.named` already prevents SQL injection by construction) — this is the one check that also covers webhook Errands, which have no equivalent structural protection over what gets forwarded in the JSON body.
- `checkOutboundText` — an AI-drafted reply, wired into `InboundMessageHandler` right after `BotKnowledgeService` returns, before the reply is sent or persisted. A blocked reply escalates to a human rather than being silently swapped for a fallback — the AI producing something unsafe is itself a "a human should look at this" situation.

**This is the MVP guardrail, not the fraud engine, on purpose:** plain pattern matching over text, same as Asami's prototype — no ML classifier, no behavioral scoring. SRS.md §10 explicitly frames this as the seam the real fraud-prevention engine plugs into later, not the engine itself.

**Test without a UI:**
```
dart run tool/test_security_filter.dart
```

## Phase 3 — Escalation feature: Conversation/Message + owner notifications

The full loop from "a bot can't answer" to "a human sees it and replies," built end to end this pass rather than staged — per explicit product direction. Bare-bones on purpose: no dashboard UI (matches "Kola Conversations.dc.html"'s eventual design conceptually, doesn't render it), no SMS provider wired in yet.

**Conversation/Message** (`lib/src/models/{conversation,message}.spy.yaml`) — one Conversation per (channel, customer) pair, found-or-created on every inbound message via `ConversationRepository.findOrCreate`. Status is a small state machine: `bot` (auto-replying normally) → `escalated` (a human is handling it, bot goes silent) → `closed` (resolved; a new message from the same customer reopens to `bot`, not back to `escalated`).

**How a message gets escalated (updated, task #134):** `InboundMessageHandler` (`lib/src/services/conversations/inbound_message_handler.dart`) — shared by both `TelegramBotRegistry` and `WhatsAppBotRegistry` — now calls `BotKnowledgeService.decide()` instead of `answerGrounded()`. The model can either answer directly or call a tool, including a reserved `escalate_to_human` tool that's always available regardless of what the workspace has configured. `InboundMessageHandler` flips the Conversation to `escalated` + fires the owner notification dispatcher whenever that tool (or a dispatch failure/security-filter block) triggers it. `answerGrounded`'s original sentinel-token mechanism (`[[ESCALATE_TO_HUMAN]]`) still exists, unchanged, for `answerGrounded`'s own remaining caller (`tool/test_grounded_qa.dart`) — see Phase 3f below for the full tool-calling engine.

**Owner notifications** (`lib/src/services/notifications/`) — `OwnerNotificationDispatcher` fans out to every channel a workspace's owner has enabled in `OwnerNotificationSettings` (set via `OwnerNotificationEndpoint.updateSettings`), skipping anything disabled/unconfigured/rate-limited:
- **WhatsApp** (`whatsapp_owner_notifier.dart`) — sent FROM the workspace's own connected WhatsApp channel, never a separate Kola number. Rate-limited per plan (`NotificationRateLimiter`: free 3/day, pro 20/day, business unlimited) because Meta bills per conversation.
- **Telegram** (`telegram_owner_notifier.dart` + `kola_notifier_bot.dart`) — a separate, Kola-owned, long-polling Telegram bot every workspace shares; an owner messages its `/start` once to get their chat_id. Uncapped — Telegram's Bot API has no per-message cost.
- **Email** (`email_owner_notifier.dart`) — plain SMTP via `package:mailer`, same technique already proven in `asami_server`. Rate-limited per plan (free 5/day, pro 50/day, business unlimited).
- **SMS** (`sms_owner_notifier.dart`) — architectural placeholder only, per explicit instruction ("bake in the architecture" without implementing it yet). `isReady()` always returns false; every interface/model/rate-limiter slot for it already exists so no future rework is needed once a provider (Termii, Africa's Talking, etc.) is chosen.

**ConversationEndpoint** (`lib/src/endpoints/conversation_endpoint.dart`) — the bare-bones inbox: `listEscalated`/`listAll`, `getMessages`, `sendHumanReply` (persists the reply AND actually sends it back to the customer over whichever platform the conversation is on, via that platform's registry — same `messagingFor(channelId)` adapters the bot itself uses), `closeConversation`.

**Setup:**
1. Run migration `006_conversations_and_notifications.sql` (see step 3 above).
2. Optionally set `KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN` and/or `SMTP_*` in `.env` (see `.env.example`) — the server starts fine with both unset, those channels are just unavailable until configured.
3. Call `OwnerNotificationEndpoint.updateSettings` for a workspace to actually receive escalation pings.

**Test the loop without a live Telegram/WhatsApp channel:**
```
dart run tool/test_escalation_loop.dart --seed="We're open 9am-6pm Mon-Sat." --question="I want to speak to a real person right now"
```

**Scope note:** superseded by Phase 3f below for the actual escalation path `InboundMessageHandler` now uses — the sentinel token itself is untouched, just no longer this file's escalation mechanism.

## Phase 3f — AI tool-calling Errand engine (task #134)

The real thing: a bot can now analyze what a customer asks for, decide which Errand (if any) fulfills it, infer the arguments from context, and execute it — SRS.md §7.2's tool-calling requirement, built end to end.

**`AiProvider.completeWithTools()`** (`lib/src/services/ai/ai_provider.dart`) — additive sibling to `complete()`, exactly as that file's original header promised. All three providers implement it: Groq/OpenRouter use OpenAI-compatible `tools`/`tool_calls`; Gemini uses its own `functionDeclarations`/`functionCall` shape. `AiOrchestrator.completeWithTools()` cascades across configured providers the same way `complete()` already did.

**`ErrandToolRegistry`** (`lib/src/services/errand/errand_tool_registry.dart`) — converts a workspace's active Errands (`ErrandRepository.listActiveByWorkspace`) into the `AiTool` list offered to the model. Builtin handlers get a hand-written JSON Schema per `builtinHandlerKey`; webhook/dbCredential Errands get one converted from their flat `inputSchemaJson`. Always includes a reserved `escalate_to_human` tool that isn't backed by any Errand row — escalation is a platform guarantee, not a business-configured feature that could be missing.

**`ErrandDispatchService`** (`lib/src/services/errand/errand_dispatch_service.dart`) — the same dispatch-by-`errand.source` logic `ErrandEndpoint.executeErrand` uses, extracted so it can run without a Session (same extraction pattern as task #128's `PaymentCheckoutService`).

**`BotKnowledgeService.decide()`** — the tool-aware sibling of `answerGrounded()` (untouched). Returns either a direct answer or a tool call. `InboundMessageHandler` merges in any context the model wasn't asked to supply (e.g. `conversationId`), runs `SecurityFilter.checkErrandInput` on the AI-inferred arguments, dispatches via `ErrandDispatchService`, and turns the result into a reply — a builtin handler's own `replyToCustomer` directly, or `BotKnowledgeService.summarizeToolResult()` (a second, tool-free AI call) for a webhook/dbCredential Errand's raw JSON.

**Also shipped:** `ErrandEndpoint.deleteErrand` — permanently deletes an Errand, but only once it's `disabled` (disable via `setErrandStatus` first).

**Test without a UI:** the existing `dart run tool/test_escalation_loop.dart` now exercises the tool-calling path end to end (its `escalate_to_human` call is the reserved platform tool, not a sentinel token).

## Phase 8a — Live payment collection (task #127)

Each workspace connects **its own** Paystack and/or Flutterwave account — money a customer pays always goes straight to that business, never through Kola (see `payment_gateway_credential.spy.yaml`'s header for why this is the deliberate choice over Asami's marketplace-wallet/escrow pattern).

**One-time setup (per workspace, per gateway):**
```dart
PaymentEndpoint().connectGateway(
  accessToken, workspaceId, 'paystack', 'sk_live_...',
);
// Flutterwave also needs the webhook secret hash set in ITS OWN dashboard
// (Settings > Webhooks) — pass it here too, or webhooks won't verify:
PaymentEndpoint().connectGateway(
  accessToken, workspaceId, 'flutterwave', 'FLWSECK_...',
  webhookSecret: 'whatever-you-set-in-flutterwave-dashboard',
);
```
Both probe a real, cheap authenticated call against the gateway before persisting anything — same "fail loud on a bad paste" rule as `connectTelegramChannel`.

**Starting a checkout:**
```dart
final txn = await PaymentEndpoint().initializeCheckout(
  accessToken, workspaceId, 'paystack', 500000, 'customer@example.com',
  // amountKobo is always the smallest currency unit regardless of gateway
);
// txn.checkoutUrl — send this to the customer
```

**Webhooks:** `/webhooks/paystack` and `/webhooks/flutterwave` — one shared route per gateway across every workspace (set once in each business's own gateway dashboard, since Paystack/Flutterwave have no Meta-style "one callback URL per App" limit). `PaymentWebhookHandler` looks up which workspace a webhook belongs to by the payload's own reference, then verifies the signature against THAT workspace's own stored credential before trusting anything — see `payment_webhook_handler.dart`'s header for why that ordering is safe.

**`holdInEscrow` is bookkeeping only** — a `held`/`released` status flag Kola tracks on the business's behalf (e.g. "don't ship until this is released"), not real fund custody. Kola's own gateway account (`Env.paystackSecretKey`/`flutterwaveSecretKey`, `dependency_injection.dart`) is unrelated to this feature — that pair still exists only for Kola's own future SaaS-subscription billing, a different direction of money entirely.

**Task #128 — wired into conversations.** A bot can now trigger this mid-conversation: register an Errand with `builtinHandlerKey: 'collectPayment'`, and its execution calls the exact same `PaymentCheckoutService` logic `PaymentEndpoint.initializeCheckout` uses, extracted out so both a Session-authenticated dashboard call and an already-trusted AI-orchestrated bot call share one implementation. Input shape: `{gateway, amountKobo, customerEmail, customerPhone?, holdInEscrow?, metadata?}` — see `builtin_errand_executor.dart`'s `_collectPayment` for the full contract. Still no dashboard form to CREATE one of these Errands (`errand_builder_page.dart` still only offers `escalateToHuman`) — API-registration only for now.

## Phase 8b — Complaint ticketing + SLA tracking (task #130)

A bot can log a customer complaint as a tracked `SupportTicket` mid-conversation, distinct from escalating to a human — a ticket means "resolve this by a deadline," escalation means "a human needs this thread right now." A bot can do either, both, or neither.

**Opening a ticket (from inside a conversation):** register an Errand with `builtinHandlerKey: 'createSupportTicket'`. Input: `{conversationId, subject, description, priority?}` (`priority` defaults to `'medium'`; one of `'low'|'medium'|'high'|'urgent'`). The SLA deadline is computed at creation from priority — see `support_ticket_repository.dart`'s `_slaDurationByPriority` table (2h/8h/24h/72h, illustrative defaults).

**Checking/resolving tickets:**
```dart
final open = await SupportTicketEndpoint().list(accessToken, workspaceId, status: 'open');
await SupportTicketEndpoint().setStatus(accessToken, workspaceId, ticketId, 'resolved');
```
No dashboard ticket queue yet (`SupportTicketEndpoint` API only — same "API-first, dashboard later" sequencing every other built-in Errand got before its own dashboard support existed).

**SLA breaches are detected, not enforced or auto-escalated.** `SupportTicketSlaSweepService` runs hourly (`server.dart`, same `Timer.periodic` shape as the trial sweep and channel health check — no FutureCall infrastructure needed) and notifies the workspace owner (via the same `OwnerNotificationDispatcher` escalations already use) the first time it sees a still-open ticket past its deadline. **Known v1 limitation, flagged honestly:** the "only notify once" dedupe is a bounded time window sized to the sweep interval, not a dedicated `notifiedAt` column — if the server is down long enough that a breach is first observed outside that window, it's silently treated as already-handled rather than notified late. See that file's own header for the full reasoning and the natural v2 fix.

Schema: `docs/migrations/011_support_tickets.sql`.

## Phase 8b — Birthday/anniversary campaigns (task #132)

A bot can save a customer's birthday and/or anniversary mid-conversation, and get a proactive greeting sent automatically on the day.

**Capturing a date (from inside a conversation):** register an Errand with `builtinHandlerKey: 'recordCustomerProfile'`. Input: `{conversationId, birthday?, anniversary?}` (each an ISO-8601 date string; at least one required). A field left out of input leaves any previously-saved value for that field untouched — this is a merge, not a replace, since a bot typically learns these facts one at a time across separate turns.

**Sending is automatic and daily, not something you call.** `CustomerCampaignSweepService` runs once a day (`server.dart`) and greets any profile whose saved date matches today, deduped by a `lastBirthdayGreetingYear`/`lastAnniversaryGreetingYear` pair so a customer gets exactly one greeting per calendar year no matter how many times the sweep runs.

**Real platform constraint, flagged rather than routed around: WhatsApp doesn't get a greeting today.** A birthday ping is business-initiated, outside any open WhatsApp customer-service window, and Meta's Cloud API requires a pre-approved message template for exactly that kind of proactive send — the same requirement Phase 8f exists to eventually satisfy. Sending a plain free-text message here (the way a live human reply does) would very likely get rejected by Meta or violate their policy, so `CustomerCampaignSweepService` only actually sends over **Telegram** (no such window/template rule there). A WhatsApp-platform customer's date is still saved — just not yet actioned. See `customer_profile.spy.yaml`'s header and `customer_campaign_sweep_service.dart`'s header for the full reasoning.

Schema: `docs/migrations/012_customer_profiles.sql`.

## Phase 8h — Slack owner-notification channel (task #129)

A fifth `OwnerNotifier` alongside WhatsApp/Telegram/Email/SMS — `SlackOwnerNotifier` posts to a business's own Slack **incoming webhook** URL, created in their own Slack workspace (Slack App → Incoming Webhooks → Add New Webhook to Workspace). Same BYO shape as every other integration here: Kola has no Slack App/OAuth relationship with any workspace, and the webhook URL itself is the only credential the mechanism uses.

**Setup:**
```dart
OwnerNotificationEndpoint().updateSettings(
  accessToken, workspaceId,
  slackWebhookUrl: 'https://hooks.slack.com/services/...',
  slackEnabled: true,
  // any other channel params omitted here are disabled — updateSettings
  // is create-or-replace, not a partial update (see its own header).
);
```
The URL is encrypted at rest via `ChannelCredentialEncryptionService` before it's persisted — unlike `ownerWhatsappNumber`/`telegramChatId` (plain recipient addresses), the URL itself grants posting rights to that Slack channel, so it's treated as a secret.

**Uncapped, on purpose:** Slack is left out of `NotificationRateLimiter`'s `_dailyLimits` table entirely — a channel absent from that table is unlimited by the rate limiter's own logic — same treatment as Telegram, since a Slack incoming webhook is free and workspace-owned, not a shared Kola resource.

No dashboard form yet for entering the webhook URL (`OwnerNotificationEndpoint` API only, matching the rest of Phase 8's escalation-settings surface). Schema: `docs/migrations/010_slack_owner_notifications.sql`.

## Deploying (task #125 / Phase 7a — Northflank)

```bash
cd kola_server
NORTHFLANK_API_TOKEN=... NORTHFLANK_PROJECT_ID=... NORTHFLANK_SERVICE_ID=... \
DOCKERHUB_USERNAME=... ./deploy.sh
```

Northflank (confirmed with the project owner — no hosting decision existed anywhere in `docs/` before this) normally builds from a linked git repository, which doesn't apply here yet (no `.git` in this repo). Instead, `deploy.sh` builds the existing `Dockerfile` locally, pushes it to Docker Hub, and tells Northflank to redeploy that image — see the script's own header for the one-time manual step this still needs (creating the deployment service once, in Northflank's dashboard, since its region/plan fields vary by account and weren't guessed at here) and for exactly which Northflank API call was checked against real docs before being scripted.

**After the first real deploy:** point `kola_dashboard`'s `KOLA_SERVER_URL` and every business's WhatsApp/Telegram webhook `WEBHOOK_BASE_URL` at this service's public Northflank URL (or your own domain once linked).
