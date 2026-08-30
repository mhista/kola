# Instagram — the final Connections Backbone channel

Status: **BUILT.** Instagram DM, connected the same "manual connect,
probe before persisting, hot-connect immediately" way as WhatsApp,
using the shape Rev 5/6's own Gate 11 note anticipated: push-driven
(webhook + conversation threading), architecturally closer to the
WhatsApp/Telegram bot-registry pattern than to a `ConnectorAdapter`
`sync()` connector. Built last, per explicit instruction, after every
other gate in the roadmap.

## Research this was built against

Fetched live from Meta's own docs, 30 Aug 2026 (not from training-data
recall — Instagram's Messaging API has moved hosts and version numbers
more than once, so this was verified fresh):

- `developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api`
  — send endpoint, host (`graph.instagram.com`, NOT
  `graph.facebook.com`), required permissions
  (`instagram_business_basic`, `instagram_business_manage_messages`),
  the 24-hour messaging window, human-agent-tag escalation path.
- `developers.facebook.com/docs/instagram-platform/webhooks` —
  verification handshake mechanics (identical to WhatsApp's: hub.mode/
  hub.verify_token/hub.challenge, X-Hub-Signature-256 HMAC-SHA256),
  `subscribed_apps` per-account opt-in requirement, the full webhook
  field list.
- A real captured `messages` webhook payload shape (via web search,
  cross-checked against Meta's own "Test setup" section, which
  independently confirms the `is_echo`/`is_self` fields on the
  `messaging` array) — this is the one place Instagram's payload
  genuinely differs from WhatsApp's `changes[].value.messages[]`
  nesting, and getting it wrong would have meant a webhook route that
  silently processes nothing.

## What was built

1. **`instagram_credential.dart`** — `igUserId` + `accessToken` +
   `appSecret`, same JSON-blob-in-encrypted-column pattern as
   `whatsapp_credential.dart`, deliberately narrower (no `wabaId`
   equivalent — Instagram has no such concept; no `appId` — nothing in
   this build needs it, since the debug_token-equivalent check was cut,
   see below).
2. **`instagram_service.dart`** — low-level `graph.instagram.com`
   wrapper: `probe()` (validates token+account before persisting,
   mirroring `WhatsAppService.probe()`), `enableSubscription()` (the
   per-account `subscribed_apps` opt-in Meta's webhook docs require —
   genuinely new; WhatsApp has no equivalent step), `sendText()`,
   `sendImage()`.
3. **`instagram_service_adapter.dart`** — implements `IMessagingService`
   (`PlatformType.instagram`, added to `messaging_result.dart`'s enum).
   `sendText`/`sendMedia` (image only) are real; `sendButtons`/
   `sendList` fall back to a plain-text rendering of the same content
   rather than a lossy half-mapping onto Instagram's genuinely different
   quick-reply/template shapes; `sendLocation` returns an honest error
   (no sensible text fallback for a map pin); `markAsRead`/
   `sendTypingIndicator` return false/no-op, same "not supported this
   way" pattern `WhatsAppServiceAdapter.sendTypingIndicator` already
   established. Every one of these is named in the file's own header,
   not silently swallowed.
4. **`instagram_webhook_route.dart`** + **`instagram_bot_registry.dart`**
   — per-channel routes from day one
   (`/webhooks/instagram/<channelId>`), no legacy shared-route mode
   (unlike WhatsApp's transitional one — there's no pre-existing
   Instagram channel to carry forward). Reuses
   `WhatsAppSignatureVerifier` directly for the identical
   X-Hub-Signature-256 HMAC scheme rather than a renamed duplicate.
   Echo events (`message.is_echo == true` — this business's own
   outbound send, bounced back through the same webhook) are filtered
   before ever reaching `InboundMessageHandler`, which would otherwise
   reply to its own reply in an infinite loop.
5. **`channel_endpoint.dart`**'s new `connectInstagramChannelManual` —
   probes before persisting, calls `enableSubscription()` as a soft
   (non-blocking) step right after, reuses the exact
   `findByBotAndPlatform`/`create`/`setCredential`/hot-connect shape
   `connectWhatsAppChannelManual` already established. Hand-added to
   `kola_client`'s generated `client.dart` (same "no `serverpod
   generate` here" drill as every other gate this session that touched
   an endpoint signature).
6. **`server.dart`** — `InstagramBotRegistry.configure()` +
   `bootstrapFromDb()`, positioned right after WhatsApp's block, before
   `pod.start()`, same ordering reasoning as every other channel.
7. **`channel_health_check_service.dart`** — Instagram added to the
   nightly credential check's platform switch (`InstagramBotRegistry
   .checkHealth`), so a revoked/expired token gets caught and the
   owner notified the same way a dead WhatsApp/Telegram channel already
   is — free to wire in since the service was already built
   platform-agnostically.
8. **`inbound_message_handler.dart`** — zero code changes needed beyond
   a doc-comment update. `platformType` was already a free string, not
   an enum; the WhatsApp-vs-else identity-signal branch already routes
   Instagram into `normalizePlatformUser('instagram', igsid)` correctly
   (the same branch Telegram uses); the media-resolution ternary is
   simply never reached, since Instagram never passes media params in
   this build (see next section). This is the clearest evidence the
   original interface design (`messaging_service_interface.dart`'s own
   header: *"adding a platform... [is] an additive change instead of a
   rewrite"*) held up in practice, not just in intent.

## Real, named scope cuts

- **Text-only inbound.** An Instagram DM with an image/audio/etc
  attachment (no `message.text`) gets the same honest generic
  acknowledgement WhatsApp's own non-text fallback branch sends — it is
  never silently dropped, it just isn't run through
  `BotKnowledgeService`. A real `InboundMediaService.fromInstagram()`
  (mirroring `.fromWhatsApp()`/`.fromTelegram()`) is follow-up work.
- **No debug_token equivalent.** `WhatsAppService.debugToken()` warns a
  business up front if they've connected a temporary token. Meta's
  Instagram Messaging docs don't document an equivalently reachable
  affordance for this API family in what this pass fetched, and none
  was invented speculatively. A token that expires fails loudly at send
  time with a real Meta error — visible, not silent, just not
  pre-warned.
- **No interactive sends.** Buttons/lists degrade to plain text (see
  `instagram_service_adapter.dart` above) rather than mapping onto
  Instagram's genuinely different generic-template/quick-reply shapes.
- **No dashboard connect UI — and this is not unique to Instagram.**
  Investigated before assuming a gap: `connectWhatsAppChannelManual`
  and `connectTelegramChannel` have NO dashboard form wired to them
  either — `dev_channels_tab.dart`/`channel_card_summary.dart` are a
  read-only jaspr status-card component with no caller anywhere in this
  codebase (dead code, not the real Flutter dashboard), and no other
  file constructs a manual-connect form for any platform. Building one
  for Instagram alone, when its two sibling platforms don't have one
  either, would be scope creep beyond what this codebase's own pattern
  supports — named here rather than quietly worked around.
- **No `InstagramWebhookUrl` lookup endpoint.** Considered, then
  removed — WhatsApp has no equivalent either (see `.env.example`
  scope: businesses learn the callback-URL pattern from docs, not from
  an API call), and adding one only for Instagram would be inventing
  asymmetric surface area again.
- **`instagramWebhookVerifyToken` bypasses `envied`.** Every other
  secret in `env.dart` has a compile-time-obfuscated counterpart in
  `env.g.dart`, hand-generated by a real `build_runner` run against a
  real secret already in someone's `.env`. This one has no real value
  yet — no business has connected Instagram before this field existed
  — and no Dart toolchain here to run `build_runner` regardless.
  Fabricating XOR key/data byte arrays for a secret that doesn't exist
  would be inventing-to-look-done; it reads straight from
  `Platform.environment` instead, same runtime-fallback code path every
  other field already has, just without the compile-time-baked-in
  option. See `env.dart`'s own comment on this field.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. The webhook payload shape
(`entry[].messaging[]`, distinct from WhatsApp's
`entry[].changes[].value.messages[]`) was cross-checked against two
independent sources (a captured-payload search result and Meta's own
"Test setup" section naming `is_echo`/`is_self`) specifically because
getting this one wrong would have meant a route that returns 200 to
Meta while silently processing nothing — the worst kind of failure to
ship unverified. Everything else follows patterns already proven live
in this codebase (WhatsApp's per-channel webhook registration, its
signature verifier, `ConnectorRetry`, `InboundMessageHandler`) rather
than inventing new mechanics.
