# Kola — Build Audit 3

**Date:** July 27, 2026
**Picks up from:** `BUILD_AUDIT_2.md` (dated July 23, 2026), which covered Phase 3 (Errand engine, AI orchestrator, security filter, escalation), Phase 4 (dashboard through 4e), Phase 5 (billing/trial/metering), Phase 6 (docs site), and debt items #82/#86/#87/#88/#106/#107/#114/#121. Everything in Audit 1 and Audit 2 still stands — this one covers **everything built since**: Phase 7a (deploy script), the Phase 8 plan itself, and four real Phase 8 sub-features (8a payment collection, 8h Slack notifications, 8b complaint ticketing + birthday/anniversary campaigns, 8d workspace switcher). Same rules as before: nothing here is guessed, every claim traces to a real file, and anything fixable without your local machine or a decision only you can make has already been fixed, not left as a note.

---

## 1. What's built since Audit 2

### Phase 7a — Deployment scripts (done)

`kola_server/deploy.sh` — builds the existing Dockerfile locally, pushes to Docker Hub, then redeploys via Northflank's real, confirmed CLI (`northflank patch service deployment --input '{"deployment":{"external":{"imagePath":"..."}}}'` — verified against Northflank's own Patch Deployment Service API docs, not guessed). First-time service creation is a one-time manual step in Northflank's dashboard (documented in the script's own header and in `kola_server/README.md`'s new "Deploying" section) — Northflank has no "create from scratch, non-interactively, first time" CLI path the way `wrangler` does for Cloudflare Pages.

Needs `NORTHFLANK_API_TOKEN`, `NORTHFLANK_PROJECT_ID`, `NORTHFLANK_SERVICE_ID`, `DOCKERHUB_USERNAME` as env vars at deploy time — none of these belong in `.env`/`.env.example` (they're deploy-time secrets for redeploying the server, not runtime config the server itself reads), so they're documented only in `deploy.sh`'s header and `kola_server/README.md`, not duplicated into the env file.

### Phase 8 planning (done)

`docs/DEVELOPMENT_PLAN.md` gained a full "Phase 8 — Product Phase 2: Commerce, Reach & Trust" section, mapping PRD.md §7's Phase 2 bullets (8a–8h) to engineering reality, each flagged **buildable now** or **externally gated** — same discipline Phase 2b's Meta Embedded Signup call already established. This audit reports on the four sub-items that moved from planned to built; the rest (8c, 8e, 8f, 8g) are addressed in §3 below.

### Phase 8a — Live payment collection Errand (done)

Each workspace connects **its own** Paystack and/or Flutterwave account — a deliberate rejection of Asami's marketplace-wallet/escrow model (checked directly against Asami's real `order_escrow.spy.yaml`/`escrow_automation_service.dart` before writing any code, not assumed from PRD.md's one-line mention). Kola is bot-as-a-service, not a marketplace; becoming a payment custodian the way Asami is would mean Transfer/Recipient API integration and real regulatory exposure — a business decision, not an engineering default.

**Built:**
- `PaymentGatewayCredential` + `PaymentTransaction` models (migration `009_payment_transactions.sql`).
- `PaymentEndpoint.connectGateway` — probes a real, cheap authenticated call before persisting (same "fail loud on a bad paste" rule as `ChannelEndpoint.connectTelegramChannel`); `initializeCheckout`, `getTransaction`, `releaseHold`.
- `PaymentWebhookHandler` + one real, live shared route per gateway (`/webhooks/paystack`, `/webhooks/flutterwave`, registered in `server.dart`) — dispatch happens by looking up the payload's own reference to find which workspace's stored credential to verify against, then an independent fresh call to the gateway's own verify endpoint before anything is ever marked `completed`. **This closes Audit 2's own §3 gap** ("No checkout endpoint or payment webhook route") — that gap is resolved, not still open.
- `holdInEscrow` is bookkeeping only — a `held`/`released` status flag, never real fund custody — flagged explicitly in code and docs to avoid the same kind of overstatement task #85 already caught and corrected elsewhere in this project.
- **Task #128, same day:** the checkout logic was extracted into a caller-agnostic `PaymentCheckoutService` (no Session/accessToken check itself — an AI-orchestrated bot's context never had one) and wired into `BuiltinErrandExecutor` as a new `collectPayment` handler, so a bot can trigger a real checkout mid-conversation, not only via `PaymentEndpoint`'s direct API surface.

**Still not done:** no dashboard UI for creating a `collectPayment` Errand (`errand_builder_page.dart` still only offers `escalateToHuman`); no real testing against live Paystack/Flutterwave sandbox keys (none available here) — same standing caveat as Phase 5c.

### Phase 8h — Slack owner-notification channel (done)

A fifth `OwnerNotifier`, alongside WhatsApp/Telegram/Email/SMS. Same BYO-credential shape as every other integration in this codebase: a business creates its own Slack "Incoming Webhook" URL in its own Slack workspace — Kola never has an OAuth relationship with any business's Slack account. The URL itself grants posting rights (unlike a plain phone number or chat ID), so it's encrypted at rest via `ChannelCredentialEncryptionService`, the same service every other secret in this codebase already reuses.

**Built:** `SlackOwnerNotifier` (`owner_notifier.dart`'s interface); `encryptedSlackWebhookUrl`/`slackEnabled` fields on `OwnerNotificationSettings` (migration `010_slack_owner_notifications.sql`); `OwnerNotificationEndpoint.updateSettings` accepts a plaintext `slackWebhookUrl` and encrypts it before persisting; registered in `OwnerNotificationDispatcher`'s default notifier list, so no caller wiring changed. Deliberately left out of `NotificationRateLimiter`'s daily-cap table entirely — a channel absent from that table is unlimited by the rate limiter's own logic — same treatment as Telegram, since an incoming webhook is free and workspace-owned, not a shared Kola resource anyone could exhaust.

**Still not done:** no dashboard form for entering the webhook URL — `OwnerNotificationEndpoint` API only, matching the rest of Phase 8's escalation-settings surface.

### Phase 8b — Templated Errand library: two of three sub-features done

**Complaint ticketing with SLA tracking — done.** A new `SupportTicket` model (migration `011_support_tickets.sql`), 1:1-ish with a Conversation, opened via a new `createSupportTicket` built-in Errand handler — a bot logs a complaint with a priority (`low`/`medium`/`high`/`urgent`), and `SupportTicketRepository.create` computes an `slaDeadline` from that priority (2h/8h/24h/72h — illustrative defaults, easy to retune). Deliberately distinct from escalation: a ticket means "resolve this by a deadline," escalation means "a human needs this thread right now" — a bot can do either, both, or neither for the same complaint. `SupportTicketSlaSweepService` runs hourly (`server.dart`, same `Timer.periodic` shape as the trial sweep) and notifies the owner via the existing `OwnerNotificationDispatcher` the first time it sees a still-open ticket past its deadline. **Known v1 limitation, flagged in the code, not hidden:** the "notify exactly once" dedupe is a bounded time window sized to the sweep interval, not a dedicated `notifiedAt` column — if the server is down long enough that a breach is first observed outside that window, it's treated as already-handled rather than notified late. A bare `SupportTicketEndpoint` (list + setStatus) gives a human enough surface to work tickets without a dashboard queue view yet.

**Birthday/anniversary campaigns — done, with one real platform constraint surfaced rather than routed around.** A new `CustomerProfile` model (migration `012_customer_profiles.sql`), 1:1 with a Conversation, holds an optional birthday/anniversary a bot captured via a new `recordCustomerProfile` built-in Errand handler — a merge-on-write, not a replace (a bot typically learns these facts one at a time across separate turns, so a plain upsert risked silently erasing whichever field wasn't mentioned this time). `CustomerCampaignSweepService` runs daily (day-granularity is all a birthday needs, unlike an hourly SLA/trial sweep) and sends a greeting on a matching date, deduped by a `lastBirthdayGreetingYear`/`lastAnniversaryGreetingYear` pair — a cleaner mechanism than the SLA sweep's bounded window, since "one greeting per calendar year" has a natural counter to key off.

**The constraint, and why it matters:** a birthday ping is business-initiated, outside any open WhatsApp customer-service window — Meta's Cloud API requires a pre-approved message template for exactly that kind of proactive send (the same requirement Phase 8f exists to eventually satisfy). Sending a plain free-text message here the way a live human reply does would very likely be rejected by Meta or violate their policy. **So this sweep only actually sends over Telegram today** (no equivalent window/template rule there) — a WhatsApp-platform customer's date is still saved, just not yet actioned. This is documented in three places (`customer_profile.spy.yaml`, `customer_campaign_sweep_service.dart`, and cross-referenced from Phase 8f's own `DEVELOPMENT_PLAN.md` entry) specifically so it isn't rediscovered later as a surprise bug report.

**OTP delivery — still not started.** Needs a real delivery channel; SMS specifically still waits on the same SMS-provider decision flagged as open since the escalation feature (`sms_owner_notifier.dart`) — unchanged since Audit 2.

### Phase 8d — Agency/reseller multi-workspace management: workspace switcher done

The server side (`WorkspaceMemberRepository.listByUser`, `WorkspaceEndpoint.listMyWorkspaces`) was already complete before this pass — the actual gap, found by reading `kola_dashboard/README.md`'s own "What's next" list, was purely UI: `app.dart` already fetched every workspace a user belongs to but unconditionally auto-selected `workspaces.first`, with no way to pick another.

**Built:** a real `<select>` switcher in `SidebarNav` (desktop) and `MobileTopBar` (mobile) — the only two components that render workspace identity in the whole dashboard, so no other page needed touching. Renders only when the signed-in user has 2+ workspaces; every single-workspace account (everyone today, pre-agency-tier) is visually unchanged. `app.dart._handleWorkspaceSwitch` is the one real handler, same shape as the existing `_handleWorkspaceCreated`. The choice persists across page reloads via `LocalStorage` (a second, much smaller use of that file, alongside the Supabase session it already persisted).

**Still not done:** no cross-workspace billing/summary view for an agency tier — a separate, larger, still-unscoped UI surface; the switcher itself doesn't imply it.

### Stale documentation caught and fixed while auditing (not previously flagged)

| File | What was stale | Fix |
|---|---|---|
| `kola_server/.env.example` | `PAYSTACK_SECRET_KEY`/`FLUTTERWAVE_SECRET_KEY`/`FLUTTERWAVE_WEBHOOK_SECRET_HASH` comments said "no checkout endpoint calls either service yet" / "required only once a webhook route exists" — both written before Phase 8a shipped a real, live checkout endpoint and webhook routes | Corrected to explain these three vars are a **separate**, still-genuinely-unused pair reserved for Kola's own future SaaS-subscription billing — Phase 8a's real payment path uses per-workspace credentials stored via `PaymentEndpoint.connectGateway` instead, never these global vars |
| `kola_dashboard/README.md` | "What's next" list claimed Conversations inbox, Integrations page, and the DashboardHomePage/BotDetailChatPage/BotDetailDevPage real-data rewire were all still pending — all three were done in earlier tasks (#109–113) | Rewritten to reflect what's actually done, with the real still-open item (cross-workspace billing view) called out separately |
| `kola_server/lib/src/services/errand/builtin_errand_executor.dart` | Header comment still said "ONE REAL HANDLER FOR NOW" after two more handlers (`collectPayment`, `createSupportTicket`) had already shipped | Corrected in place |
| `docs/DEVELOPMENT_PLAN.md` Phase 8f | Didn't mention that its own WhatsApp-template gate had already surfaced concretely in 8b | Added a cross-reference so the connection isn't lost when 8f is eventually built |

---

## 2. What you need to supply, and when

Everything in Audit 1's and Audit 2's §2 still applies unchanged. **Nothing new needs to go in `.env`/`.env.example` for this batch of work** — Slack/support-ticket/birthday-campaign features all reuse credentials/infrastructure that already existed (`ChannelCredentialEncryptionService`, the existing Telegram/WhatsApp registries, the existing `OwnerNotificationDispatcher`). The one new requirement is deploy-time, not runtime:

| Variable | Where to get it | Blocks what if missing |
|---|---|---|
| `NORTHFLANK_API_TOKEN` | Northflank dashboard → API tokens, "Update Deployment" permission | `deploy.sh` redeploys — the server itself runs fine without it once already deployed |
| `NORTHFLANK_PROJECT_ID` / `NORTHFLANK_SERVICE_ID` | Northflank dashboard, after the one-time manual service creation (see `deploy.sh`'s header) | Same — `deploy.sh` only |
| `DOCKERHUB_USERNAME` | Your own Docker Hub account | `deploy.sh`'s image push step |

**Migrations to run, in order** (Audit 2 covered through `008`; run these four in addition, against the same Supabase project):

```
009_payment_transactions.sql
010_slack_owner_notifications.sql
011_support_tickets.sql
012_customer_profiles.sql
```

**No new decisions needed from you for this batch** — every number/behavior choice in this pass (SLA duration-by-priority, the notify-window size, which channels are rate-limited) was either a direct carryover of an existing precedent in this codebase or explicitly flagged as an easy-to-retune illustrative default, not something requiring your sign-off the way the Phase 5 plan-limit numbers did.

---

## 3. Gaps — what's genuinely still open, and why

**Blocked on you specifically — unchanged from Audit 2, still cannot be closed from this side:**

- **Task #87 — remove the legacy shared WhatsApp webhook route.** Still not touched. Still waiting on your confirmation that Meta's dashboard Callback URL for the first-connected WhatsApp channel has been repointed to its per-channel URL.
- **Task #88 — real screenshots for `WHATSAPP_MANUAL_SETUP.md`.** Still needs your own live Meta/WhatsApp setup and physical screen captures.

**Closed since Audit 2 (listed there as open, resolved now):**

- ~~No checkout endpoint or payment webhook route~~ — Phase 8a. `PaymentEndpoint` + `/webhooks/paystack`/`/webhooks/flutterwave` are real and live.

**Genuinely still open, each with a real reason:**

| Gap | Why it's still open | What closes it |
|---|---|---|
| Birthday/anniversary greetings don't reach WhatsApp customers | Meta's Cloud API requires a pre-approved message template for any business-initiated proactive send outside an open customer-service window — a real platform rule, not a missing feature this codebase can route around | Phase 8f (WhatsApp template-based broadcast / MM Lite API) — once that ships, `CustomerCampaignSweepService`'s WhatsApp branch is the natural first caller |
| SupportTicketSlaSweepService's "notify once" dedupe has a known edge case | A bounded notify-window, not a dedicated `notifiedAt` column — if the server is down long enough that a breach is first observed outside the window, it's silently treated as already-handled | A dedicated `notifiedAt` column — a natural, small v2 fix, not attempted here without a concrete case forcing the question |
| No dashboard UI for `collectPayment`, `createSupportTicket`, or `recordCustomerProfile` Errands | `errand_builder_page.dart` still only offers `escalateToHuman` — same "API-first, dashboard later" sequencing every prior Errand type got before its own dashboard support existed | A form per Errand type, or one generic form once the input-schema shapes stabilize |
| No cross-workspace billing/summary view for an agency tier | The workspace *switcher* (task #131) is done; a view showing all of an agency's client workspaces' plans/usage at a glance is separate, larger, and still unscoped | Product scoping first — not a guess to make inline |
| 8c (WhatsApp/Telegram-native Bot Mother) | Needs its own product-design pass (what commands, what's editable this way vs. dashboard-only) before an engineering breakdown makes sense | Product scoping, same reasoning as the billing view above |
| 8e/8f (Facebook/Instagram catalog, WhatsApp template broadcast) | Both externally gated on Meta App Review / Marketing Messages API access — independent of engineering readiness | Meta's own approval timeline |
| 8g (BSP partnership evaluation) | A business/partnership research activity, not something to code | Revisit as a research task if/when prioritized |
| No real automated tests | Unchanged from Audit 2 — no Dart toolchain in this environment to write and run `dart test` against | Real test-writing once you can run `dart test` locally |
| SMS owner-notification channel is architecture-only | Unchanged from Audit 2 | Picking an SMS provider and wiring one method |
| Meta Embedded Signup still not built | Unchanged from Audit 2 — manual connect remains the primary path | A future, separate build |

---

## 4. Quick file map — new since Audit 2

| You want to... | Look at |
|---|---|
| Redeploy `kola_server` | `kola_server/deploy.sh`, `kola_server/README.md`'s "Deploying" section |
| Add a new payment gateway or change checkout logic | `services/billing/payment_checkout_service.dart` (caller-agnostic) → `endpoints/payment_endpoint.dart` (Session-gated) / `builtin_errand_executor.dart`'s `_collectPayment` (bot-triggered) |
| See how a payment webhook is verified without trusting the payload first | `services/billing/payment_webhook_handler.dart`'s header |
| Add a new owner-notification channel | `services/notifications/owner_notifier.dart` (interface) → register in `owner_notification_dispatcher.dart`'s `_notifiers` list |
| See why Slack has no daily cap | `services/notifications/notification_rate_limiter.dart`'s header |
| Add a new built-in Errand handler | `services/errand/builtin_errand_executor.dart` — now four real handlers: `escalateToHuman`, `collectPayment`, `createSupportTicket`, `recordCustomerProfile` |
| See the SLA-breach detection logic | `services/support/support_ticket_sla_sweep_service.dart` |
| See the birthday/anniversary send logic, and the WhatsApp constraint | `services/support/customer_campaign_sweep_service.dart`'s header |
| Change SLA durations or greeting message text | `support_ticket_repository.dart`'s `_slaDurationByPriority` / `customer_campaign_sweep_service.dart`'s `_maybeSend` |
| Edit the workspace switcher UI | `kola_dashboard/lib/components/sidebar_nav.dart` (desktop) / `mobile_top_bar.dart` (mobile) → wired from `kola_dashboard/lib/app.dart`'s `_handleWorkspaceSwitch` |
| See every sweep job and its interval | `kola_server/lib/server.dart` — search "Timer.periodic" (channel health: 24h, trial: 1h, SLA: 1h, customer campaign: 24h) |

---

## 5. Action checklist — what to actually do next

1. Run migrations `009` through `012` against your Supabase project (in order, after Audit 2's `005`–`008`).
2. If you plan to redeploy `kola_server`: set up the one-time Northflank service (dashboard, per `deploy.sh`'s header), then supply `NORTHFLANK_API_TOKEN`/`NORTHFLANK_PROJECT_ID`/`NORTHFLANK_SERVICE_ID`/`DOCKERHUB_USERNAME` at deploy time only.
3. Test the new payment loop end to end once you have real Paystack/Flutterwave sandbox keys: `PaymentEndpoint().connectGateway(...)` → `initializeCheckout(...)` → confirm the webhook actually flips the transaction to `completed`.
4. Test Slack notifications: create a Slack incoming webhook in any test Slack workspace, call `OwnerNotificationEndpoint().updateSettings(..., slackWebhookUrl: ..., slackEnabled: true)`, then trigger an escalation and confirm the message lands.
5. Test support tickets: register a `createSupportTicket` Errand, invoke it, then either wait for the hourly sweep or call `sweepOnce()` directly against a manually-backdated `slaDeadline` to confirm the owner gets notified.
6. Test birthday campaigns on Telegram specifically (WhatsApp won't send yet — see §3): register a `recordCustomerProfile` Errand with today's month/day, run the daily sweep, confirm the Telegram customer gets a greeting.
7. Try the workspace switcher: add a second `WorkspaceMember` row for the same Supabase user against a second workspace, reload the dashboard, confirm the `<select>` appears and switching actually changes every route's `workspaceId`.
8. When you're ready: confirm whether Meta's dashboard Callback URL for the first WhatsApp channel has been repointed — that single confirmation unblocks task #87.
9. When you have your own Meta/WhatsApp setup open: capture the real screenshots task #88 needs.
10. When ready to scope it: decide what a cross-workspace billing view for an agency tier should actually show, and what 8c's Bot Mother conversational-UI surface should support — both are explicitly waiting on a product decision, not an engineering guess.
