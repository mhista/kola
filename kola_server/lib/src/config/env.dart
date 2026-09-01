import 'dart:io';
import 'package:envied/envied.dart';

part 'env.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Env — type-safe environment variables via envied.
//
// HOW IT WORKS (same pattern as degenbot_server/asami_server — reused, not
// reinvented, per the "reuse before rebuilding" working convention):
//   1. Copy .env.example → .env  (never commit .env)
//   2. Fill in your real values
//   3. Run `dart run build_runner build` to generate env.g.dart
//   4. Access values as Env.supabaseUrl, Env.serverPort, etc.
//
// The @EnviedField(obfuscate: true) annotation bakes secret values into the
// compiled binary as obfuscated strings, so they don't sit in plaintext in
// a shipped executable. In production (Northflank/Render/Docker), if the
// obfuscated value isn't baked in at build time, we fall back to reading
// straight from Platform.environment at runtime — this lets the same code
// work whether secrets are injected at build time or at deploy time.
//
// PHASE SCOPE:
//   Grows one phase at a time, not speculatively — mirrors how Degenbot's
//   env.dart grew. Phase 1 (Supabase persistence, server networking, admin
//   override token), Phase 2 (Telegram/WhatsApp channel credentials),
//   Phase 3 (AI provider keys, owner notifications), Phase 5c
//   (Paystack/Flutterwave secret keys — see their section below; ImageKit
//   still has no Env fields, nothing uses it yet).
// ─────────────────────────────────────────────────────────────────────────────

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // ── Supabase (Phase 1b — persistence) ──────────────────────────────────────
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true, defaultValue: '')
  static final String supabaseUrl = _Env.supabaseUrl.isNotEmpty
      ? _Env.supabaseUrl
      : Platform.environment['SUPABASE_URL'] ?? '';

  // service_role key — server-only, bypasses Row Level Security because our
  // own repository layer enforces workspace isolation instead (see SRS §5).
  // NEVER expose this key to a client (dashboard, mobile app, docs site).
  @EnviedField(
    varName: 'SUPABASE_SERVICE_ROLE_KEY',
    obfuscate: true,
    defaultValue: '',
  )
  static final String supabaseServiceRoleKey =
      _Env.supabaseServiceRoleKey.isNotEmpty
      ? _Env.supabaseServiceRoleKey
      : Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ?? '';

  // ── Auth (Phase 1d, JWKS support added task #106) ───────────────────────────
  // Supabase project's legacy JWT secret (Project Settings > API > JWT
  // Settings). session_verifier.dart tries JWKS-based verification first
  // (no secret needed, works once the project has migrated to an
  // asymmetric signing key) and falls back to checking the signature
  // against THIS secret only when no matching JWKS key is found — see
  // that file's header for the full reasoning. Still required until this
  // project's Supabase instance completes that migration. NEVER expose
  // this value to a client.
  @EnviedField(
    varName: 'SUPABASE_JWT_SECRET',
    obfuscate: true,
    defaultValue: '',
  )
  static final String supabaseJwtSecret = _Env.supabaseJwtSecret.isNotEmpty
      ? _Env.supabaseJwtSecret
      : Platform.environment['SUPABASE_JWT_SECRET'] ?? '';

  // ── Server networking (Phase 1b) ────────────────────────────────────────────
  @EnviedField(varName: 'SERVER_PORT', defaultValue: '8080')
  static final String serverPort = _Env.serverPort.isNotEmpty
      ? _Env.serverPort
      : Platform.environment['SERVER_PORT'] ?? '8080';

  // Public base URL of this server, e.g. https://api.kola.app in production
  // or an ngrok URL for local webhook testing. Used to derive the public
  // hostname Serverpod advertises, and later (Phase 2+) to build webhook
  // callback URLs for Meta/Telegram/Paystack/Flutterwave.
  @EnviedField(varName: 'WEBHOOK_BASE_URL', defaultValue: '')
  static final String webhookBaseUrl = _Env.webhookBaseUrl.isNotEmpty
      ? _Env.webhookBaseUrl
      : Platform.environment['WEBHOOK_BASE_URL'] ?? '';

// Public base URL of the API server, e.g. https://api.kola.app in production
  // or an ngrok URL for local webhook testing. Used to derive the public
  // hostname Serverpod advertises, and later (Phase 2+) to build webhook
  // callback URLs for Meta/Telegram/Paystack/Flutterwave.
  @EnviedField(varName: 'API_BASE_URL', defaultValue: '')
  static final String apiBaseUrl = _Env.apiBaseUrl.isNotEmpty
      ? _Env.apiBaseUrl
      : Platform.environment['API_BASE_URL'] ?? '';

  // ── Admin override token (Phase 1d — auth) ──────────────────────────────────
  // A random secret that authorizes protected admin-only endpoints/routes.
  // Generate with: python3 -c "import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())"
  // NEVER commit this value — set it in .env locally and as a real secret
  // in production env vars.
  @EnviedField(varName: 'ADMIN_TOKEN', obfuscate: true, defaultValue: '')
  static final String adminToken = _Env.adminToken.isNotEmpty
      ? _Env.adminToken
      : Platform.environment['ADMIN_TOKEN'] ?? '';

  // ── Channel credentials (Phase 2a — messaging channels) ─────────────────────
  // AES-256-GCM master key protecting Channel.encryptedCredential (Telegram
  // bot tokens now, WhatsApp long-lived tokens in Phase 2b). Must decode to
  // exactly 32 bytes — see channel_credential_encryption_service.dart's
  // header comment for the exact generation command. NEVER commit this
  // value, and NEVER reuse it for anything else (a different secret class
  // than ADMIN_TOKEN or the Supabase keys above, even though they're all
  // "just strings" — rotating one should never require touching another).
  @EnviedField(
    varName: 'CHANNEL_CREDENTIAL_MASTER_KEY',
    obfuscate: true,
    defaultValue: '',
  )
  static final String channelCredentialMasterKey =
      _Env.channelCredentialMasterKey.isNotEmpty
      ? _Env.channelCredentialMasterKey
      : Platform.environment['CHANNEL_CREDENTIAL_MASTER_KEY'] ?? '';

  // ── ImageKit (product media) ────────────────────────────────────────────────
  // Product photos and video. Three values, and only ONE of them is a secret.
  //
  // The public key identifies the ImageKit account and is sent to the browser
  // deliberately — it authorises nothing on its own. The URL endpoint is in
  // every image's src attribute, so it is public by construction.
  //
  // The PRIVATE key never leaves this process. It signs one-shot upload
  // credentials (see ImageKitService.createUploadAuth) and authenticates
  // deletes, and those are the only two things it is used for. It is a
  // different secret class from CHANNEL_CREDENTIAL_MASTER_KEY — that one
  // protects data at rest in our own database, this one is a third-party
  // account credential — so they rotate independently and neither is ever
  // reused for the other.
  @EnviedField(varName: 'IMAGEKIT_PUBLIC_KEY', defaultValue: '')
  static final String imagekitPublicKey = _Env.imagekitPublicKey.isNotEmpty
      ? _Env.imagekitPublicKey
      : Platform.environment['IMAGEKIT_PUBLIC_KEY'] ?? '';

  @EnviedField(
    varName: 'IMAGEKIT_PRIVATE_KEY',
    obfuscate: true,
    defaultValue: '',
  )
  static final String imagekitPrivateKey = _Env.imagekitPrivateKey.isNotEmpty
      ? _Env.imagekitPrivateKey
      : Platform.environment['IMAGEKIT_PRIVATE_KEY'] ?? '';

  /// e.g. https://ik.imagekit.io/somtech — the CDN base every stored media
  /// URL sits under. Not a secret; it is visible in every rendered image.
  @EnviedField(varName: 'IMAGEKIT_URL_ENDPOINT', defaultValue: '')
  static final String imagekitUrlEndpoint = _Env.imagekitUrlEndpoint.isNotEmpty
      ? _Env.imagekitUrlEndpoint
      : Platform.environment['IMAGEKIT_URL_ENDPOINT'] ?? '';

  // ── WhatsApp webhook (Phase 2b — messaging channels) ────────────────────────
  // Whatever string you set as the "Verify Token" in Meta's App Dashboard →
  // WhatsApp → Configuration must match this exactly — it's how
  // whatsapp_webhook_route.dart proves an incoming GET verification
  // handshake really came from Meta and not a random request guessing the
  // callback URL. Unlike CHANNEL_CREDENTIAL_MASTER_KEY this isn't a
  // cryptographic key, just a shared secret string — any value works, it
  // just has to match on both sides.
  @EnviedField(
    varName: 'WHATSAPP_WEBHOOK_VERIFY_TOKEN',
    obfuscate: true,
    defaultValue: '',
  )
  static final String whatsappWebhookVerifyToken =
      _Env.whatsappWebhookVerifyToken.isNotEmpty
      ? _Env.whatsappWebhookVerifyToken
      : Platform.environment['WHATSAPP_WEBHOOK_VERIFY_TOKEN'] ?? '';

  // ── Instagram webhook (final gate — messaging channels) ─────────────────────
  // Same role as whatsappWebhookVerifyToken directly above, and the same
  // shared-Meta-webhook-infrastructure reasoning as
  // instagram_webhook_route.dart's header: whatever string is set as the
  // "Verify Token" for this Meta App's Webhooks product must match this
  // exactly.
  //
  // DELIBERATELY NOT AN @EnviedField, UNLIKE EVERY FIELD ABOVE — a real
  // difference from how this file normally grows, not an oversight. Every
  // other secret in this class has an obfuscated counterpart hand-generated
  // into env.g.dart by a real `dart run build_runner build` against a real
  // secret value already sitting in someone's .env. This one doesn't exist
  // yet — no business has connected Instagram before this field was added,
  // so there is no real value to obfuscate, and no Dart toolchain in this
  // environment to run build_runner even if there were. Fabricating XOR
  // key/data byte arrays for a secret that doesn't exist would be exactly
  // the kind of invented-to-look-done code this project's discipline exists
  // to avoid. This reads straight from Platform.environment instead — works
  // identically to every other field's runtime fallback path, just without
  // the compile-time-baked-in option. Safe to upgrade to a real
  // @EnviedField the next time someone runs build_runner for any other
  // reason — see .env.example for the INSTAGRAM_WEBHOOK_VERIFY_TOKEN entry
  // this expects.
  static final String instagramWebhookVerifyToken =
      Platform.environment['INSTAGRAM_WEBHOOK_VERIFY_TOKEN'] ?? '';

  // Messenger's webhook verification handshake uses the exact same
  // hub.verify_token mechanism as Instagram's above — same reasoning,
  // same fallback shape, same "safe to upgrade to @EnviedField later"
  // note. See .env.example for the MESSENGER_WEBHOOK_VERIFY_TOKEN entry
  // this expects.
  static final String messengerWebhookVerifyToken =
      Platform.environment['MESSENGER_WEBHOOK_VERIFY_TOKEN'] ?? '';

  // ── AI orchestrator (Phase 3a) ───────────────────────────────────────────────
  // Same cost-efficient cascade already proven in copycat/kopicat_server's
  // ai.dart, ported rather than reinvented: Groq first (fast, generous free
  // tier), Gemini next, OpenRouter's free model last. See
  // lib/src/services/ai/ai_orchestrator.dart for where these get read and
  // tried in that order. None are required for the server to start — an
  // empty key just means that provider is skipped, same as copycat's
  // Platform.environment-only version worked before this project had its
  // own Env pattern.
  @EnviedField(varName: 'GROQ_API_KEY', obfuscate: true, defaultValue: '')
  static final String groqApiKey = _Env.groqApiKey.isNotEmpty
      ? _Env.groqApiKey
      : Platform.environment['GROQ_API_KEY'] ?? '';

  // A SECOND Groq account's key, tried only after GROQ_API_KEY hits a 429
  // (quota exceeded) — see groq_provider.dart's header on why this exists
  // one level BELOW the Groq -> Gemini -> OpenRouter cascade above rather
  // than as a fourth provider: Groq's free tier is generous enough that a
  // second key buys real headroom before ever needing to degrade to a
  // different (slower/weaker) provider. Optional — if unset, GroqProvider
  // just has one key, same as before this field existed.
  @EnviedField(varName: 'GROQ_API_KEY_2', obfuscate: true, defaultValue: '')
  static final String groqApiKey2 = _Env.groqApiKey2.isNotEmpty
      ? _Env.groqApiKey2
      : Platform.environment['GROQ_API_KEY_2'] ?? '';

  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true, defaultValue: '')
  static final String geminiApiKey = _Env.geminiApiKey.isNotEmpty
      ? _Env.geminiApiKey
      : Platform.environment['GEMINI_API_KEY'] ?? '';

  // OPTIONAL, DELIBERATELY UNSET BY DEFAULT — root-cause diagnosis (2026-09,
  // see embedding_orchestrator.dart's header and
  // gemini_embedding_provider.dart's header) traced the recurring "Today's
  // limit for processing new knowledge has been reached" upload failure to
  // a real HTTP 429 from Google, NOT a per-workspace daily counter: EVERY
  // workspace on the platform shares ONE Gemini key (geminiApiKey above)
  // for BOTH high-volume chat traffic (AiOrchestrator/GeminiProvider) AND
  // low-volume embeddings (EmbeddingOrchestrator/GeminiEmbeddingProvider),
  // and chat traffic starves embeddings' share of the free-tier quota.
  //
  // This field lets a business (or Kola, platform-wide) supply a SEPARATE
  // key dedicated to embeddings only, isolating that traffic from chat's.
  // Until someone sets GEMINI_EMBEDDING_API_KEY, this stays empty and
  // EmbeddingOrchestrator falls back to the shared geminiApiKey — meaning
  // today's behavior is UNCHANGED by this field's mere existence. The
  // moment a real key is set in the deployment environment, embeddings
  // isolate from chat automatically, with no further code change needed.
  // Same @EnviedField/Platform.environment fallback shape as every other
  // optional key above (e.g. groqApiKey2) — nothing new invented here.
  @EnviedField(
    varName: 'GEMINI_EMBEDDING_API_KEY',
    obfuscate: true,
    defaultValue: '',
  )
  static final String geminiEmbeddingApiKey =
      _Env.geminiEmbeddingApiKey.isNotEmpty
      ? _Env.geminiEmbeddingApiKey
      : Platform.environment['GEMINI_EMBEDDING_API_KEY'] ?? '';

  @EnviedField(varName: 'OPENROUTER_API_KEY', obfuscate: true, defaultValue: '')
  static final String openRouterApiKey = _Env.openRouterApiKey.isNotEmpty
      ? _Env.openRouterApiKey
      : Platform.environment['OPENROUTER_API_KEY'] ?? '';

  // ── Owner escalation notifications (Phase 3 — escalation feature) ──────────
  // A SEPARATE Telegram bot from any business's own connected channel —
  // this one is Kola's, shared across every workspace, used ONLY to ping
  // an owner when a conversation escalates. An owner messages this bot's
  // /start once (see kola_notifier_bot.dart) to get the chat_id they then
  // paste into their notification settings. Not required for the server
  // to start — Telegram owner notifications are simply unavailable until
  // it's set.
  @EnviedField(
    varName: 'KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN',
    obfuscate: true,
    defaultValue: '',
  )
  static final String kolaNotifierTelegramBotToken =
      _Env.kolaNotifierTelegramBotToken.isNotEmpty
      ? _Env.kolaNotifierTelegramBotToken
      : Platform.environment['KOLA_NOTIFIER_TELEGRAM_BOT_TOKEN'] ?? '';

  // SMTP config for EmailOwnerNotifier (email_owner_notifier.dart). Any
  // real SMTP provider works (Gmail with an App Password, SendGrid,
  // Postmark, Mailgun, your own server) — this is deliberately generic,
  // not tied to one vendor's SDK, same "swap the provider without
  // touching calling code" instinct as every other pluggable interface
  // in this project. Not required for the server to start — email owner
  // notifications are simply unavailable until these are set.
  @EnviedField(varName: 'SMTP_HOST', defaultValue: '')
  static final String smtpHost = _Env.smtpHost.isNotEmpty
      ? _Env.smtpHost
      : Platform.environment['SMTP_HOST'] ?? '';

  @EnviedField(varName: 'SMTP_PORT', defaultValue: '587')
  static final String smtpPort = _Env.smtpPort.isNotEmpty
      ? _Env.smtpPort
      : Platform.environment['SMTP_PORT'] ?? '587';

  @EnviedField(varName: 'SMTP_USER', obfuscate: true, defaultValue: '')
  static final String smtpUser = _Env.smtpUser.isNotEmpty
      ? _Env.smtpUser
      : Platform.environment['SMTP_USER'] ?? '';

  @EnviedField(varName: 'SMTP_PASSWORD', obfuscate: true, defaultValue: '')
  static final String smtpPassword = _Env.smtpPassword.isNotEmpty
      ? _Env.smtpPassword
      : Platform.environment['SMTP_PASSWORD'] ?? '';

  @EnviedField(varName: 'SMTP_FROM_EMAIL', defaultValue: '')
  static final String smtpFromEmail = _Env.smtpFromEmail.isNotEmpty
      ? _Env.smtpFromEmail
      : Platform.environment['SMTP_FROM_EMAIL'] ?? '';

  @EnviedField(varName: 'SMTP_FROM_NAME', defaultValue: 'Kola')
  static final String smtpFromName = _Env.smtpFromName.isNotEmpty
      ? _Env.smtpFromName
      : Platform.environment['SMTP_FROM_NAME'] ?? 'Kola';

  // ── Payment gateways (Phase 5c — billing) ───────────────────────────────────
  // Secret keys for PaystackService/FlutterwaveService (lib/src/services/
  // billing/). Not required for the server to start — a workspace's own
  // per-customer checkout (PaymentEndpoint) never uses these, it uses
  // that workspace's OWN connected credential instead. As of task #148,
  // these ARE used for one thing: KolaBillingService, Kola's own SaaS
  // subscription checkout (₦10,000/month — CONFIRMED WITH THE USER
  // 2026-07-27). ALWAYS the secret key, never the public key — the
  // public key is safe for a client to hold, the secret key is not and
  // must never reach kola_dashboard.
  @EnviedField(varName: 'PAYSTACK_SECRET_KEY', obfuscate: true, defaultValue: '')
  static final String paystackSecretKey = _Env.paystackSecretKey.isNotEmpty
      ? _Env.paystackSecretKey
      : Platform.environment['PAYSTACK_SECRET_KEY'] ?? '';

  @EnviedField(varName: 'FLUTTERWAVE_SECRET_KEY', obfuscate: true, defaultValue: '')
  static final String flutterwaveSecretKey = _Env.flutterwaveSecretKey.isNotEmpty
      ? _Env.flutterwaveSecretKey
      : Platform.environment['FLUTTERWAVE_SECRET_KEY'] ?? '';

  /// KOLA'S OWN Stripe secret key — for charging workspaces outside the
  /// markets Paystack and Flutterwave serve. NOT a business's own key:
  /// those are per-workspace and encrypted at rest (see
  /// payment_gateway_credential.spy.yaml).
  @EnviedField(varName: 'STRIPE_SECRET_KEY', obfuscate: true, defaultValue: '')
  static final String stripeSecretKey = _Env.stripeSecretKey.isNotEmpty
      ? _Env.stripeSecretKey
      : Platform.environment['STRIPE_SECRET_KEY'] ?? '';

  // The arbitrary string configured as each gateway's webhook secret in
  // its own dashboard — see each service's verifyWebhookSignature() for
  // how it's actually used (HMAC key for Paystack, plain shared string
  // for Flutterwave). Not required until a webhook route exists.
  @EnviedField(varName: 'FLUTTERWAVE_WEBHOOK_SECRET_HASH', obfuscate: true, defaultValue: '')
  static final String flutterwaveWebhookSecretHash =
      _Env.flutterwaveWebhookSecretHash.isNotEmpty
      ? _Env.flutterwaveWebhookSecretHash
      : Platform.environment['FLUTTERWAVE_WEBHOOK_SECRET_HASH'] ?? '';

  // ── Google OAuth (Gate 4 — Sheets/Drive/Calendar) ───────────────────────────
  // One shared client for every Google-backed connector — see
  // docs/DESIGN_DELTA.md's "Google OAuth: one provider, one consent flow,
  // one refresh path, three scopes." google_oauth_service.dart is the only
  // thing that reads these. Not required for the server to start — every
  // Google-backed connector is simply unavailable until they're set.
  @EnviedField(varName: 'GOOGLE_OAUTH_CLIENT_ID', obfuscate: true, defaultValue: '')
  static final String googleOAuthClientId = _Env.googleOAuthClientId.isNotEmpty
      ? _Env.googleOAuthClientId
      : Platform.environment['GOOGLE_OAUTH_CLIENT_ID'] ?? '';

  @EnviedField(varName: 'GOOGLE_OAUTH_CLIENT_SECRET', obfuscate: true, defaultValue: '')
  static final String googleOAuthClientSecret =
      _Env.googleOAuthClientSecret.isNotEmpty
      ? _Env.googleOAuthClientSecret
      : Platform.environment['GOOGLE_OAUTH_CLIENT_SECRET'] ?? '';

  // Must exactly match an Authorized redirect URI registered on the OAuth
  // client in Google Cloud Console, or the callback is rejected outright.
  @EnviedField(varName: 'GOOGLE_OAUTH_REDIRECT_URI', defaultValue: '')
  static final String googleOAuthRedirectUri =
      _Env.googleOAuthRedirectUri.isNotEmpty
      ? _Env.googleOAuthRedirectUri
      : Platform.environment['GOOGLE_OAUTH_REDIRECT_URI'] ?? '';

  // Where GoogleOAuthCallbackRoute sends the browser back to once the
  // token exchange finishes — the DASHBOARD's own public origin, not
  // this API server's. Confirmed from kola_dashboard/deploy.sh, which
  // deploys to dash.kolaa.co (Cloudflare Pages) in production. Getting
  // this wrong means the OAuth flow "succeeds" server-side and then
  // redirects the owner's browser nowhere useful — worth its own env
  // var rather than reusing WEBHOOK_BASE_URL/API_BASE_URL, both of
  // which point at THIS server, not the dashboard.
  @EnviedField(varName: 'DASHBOARD_BASE_URL', defaultValue: 'https://dash.kolaa.co')
  static final String dashboardBaseUrl = _Env.dashboardBaseUrl.isNotEmpty
      ? _Env.dashboardBaseUrl
      : Platform.environment['DASHBOARD_BASE_URL'] ?? 'https://dash.kolaa.co';

  // ── Microsoft OAuth (Gate 4 — OneDrive/SharePoint Excel) ────────────────────
  // Second OAuth provider, same one-client-many-connectors shape as the
  // Google block above — microsoft_oauth_service.dart is the only thing
  // that reads these. Registered as an "App registration" in the Azure
  // portal (Entra ID), not Google Cloud Console. Not required for the
  // server to start — the OneDrive/SharePoint Excel connector is simply
  // unavailable until they're set.
  @EnviedField(varName: 'MICROSOFT_OAUTH_CLIENT_ID', obfuscate: true, defaultValue: '')
  static final String microsoftOAuthClientId =
      _Env.microsoftOAuthClientId.isNotEmpty
      ? _Env.microsoftOAuthClientId
      : Platform.environment['MICROSOFT_OAUTH_CLIENT_ID'] ?? '';

  @EnviedField(varName: 'MICROSOFT_OAUTH_CLIENT_SECRET', obfuscate: true, defaultValue: '')
  static final String microsoftOAuthClientSecret =
      _Env.microsoftOAuthClientSecret.isNotEmpty
      ? _Env.microsoftOAuthClientSecret
      : Platform.environment['MICROSOFT_OAUTH_CLIENT_SECRET'] ?? '';

  // Must exactly match a Redirect URI registered on the app registration
  // in the Azure portal, under Authentication → Web, or the callback is
  // rejected outright — same failure mode as Google's own redirect URI
  // mismatch.
  @EnviedField(varName: 'MICROSOFT_OAUTH_REDIRECT_URI', defaultValue: '')
  static final String microsoftOAuthRedirectUri =
      _Env.microsoftOAuthRedirectUri.isNotEmpty
      ? _Env.microsoftOAuthRedirectUri
      : Platform.environment['MICROSOFT_OAUTH_REDIRECT_URI'] ?? '';

  // 'organizations' by default — see microsoft_oauth_service.dart's header
  // on why a personal Microsoft account cannot use this connector at all
  // (the Excel workbook API does not support it), and why restricting the
  // sign-in screen itself to work/school accounts is a clearer failure
  // than letting the whole OAuth dance complete and only THEN discovering
  // Graph rejects every sync. Override to a specific tenant GUID for a
  // future single-tenant deployment; 'common' is deliberately not offered
  // as the default for the reason above.
  @EnviedField(varName: 'MICROSOFT_OAUTH_TENANT', defaultValue: 'organizations')
  static final String microsoftOAuthTenant = _Env.microsoftOAuthTenant.isNotEmpty
      ? _Env.microsoftOAuthTenant
      : Platform.environment['MICROSOFT_OAUTH_TENANT'] ?? 'organizations';

  // ── Dropbox / HubSpot / Meta OAuth (fix-properly pass) ──────────────────────
  // Three more single-client-many-... wait, one-client-per-provider OAuth
  // blocks, same shape as Google/Microsoft above. Deliberately NOT
  // @EnviedField like every field above this point — that annotation
  // needs a real `dart run build_runner build` against a real secret
  // already sitting in someone's .env to populate env.g.dart's
  // obfuscated counterpart, and neither exists yet: no business has
  // connected any of these three before this pass, and this environment
  // has no Dart toolchain to run build_runner even if one had. Same
  // reasoning and same fallback shape as instagramWebhookVerifyToken
  // above — reads straight from Platform.environment, safe to upgrade
  // to a real @EnviedField the next time build_runner runs for any
  // other reason. Not required for the server to start — each connector
  // is simply unavailable until its three values are set. See
  // .env.example for the matching entries.
  static final String dropboxClientId =
      Platform.environment['DROPBOX_CLIENT_ID'] ?? '';
  static final String dropboxClientSecret =
      Platform.environment['DROPBOX_CLIENT_SECRET'] ?? '';
  static final String dropboxRedirectUri =
      Platform.environment['DROPBOX_REDIRECT_URI'] ?? '';

  static final String hubspotClientId =
      Platform.environment['HUBSPOT_CLIENT_ID'] ?? '';
  static final String hubspotClientSecret =
      Platform.environment['HUBSPOT_CLIENT_SECRET'] ?? '';
  static final String hubspotRedirectUri =
      Platform.environment['HUBSPOT_REDIRECT_URI'] ?? '';

  // Shared by instagram_shop AND facebook_catalog — one Meta App, same
  // "one client, many connectors" shape as Google's block above. See
  // meta_oauth_service.dart's header.
  static final String metaAppId = Platform.environment['META_APP_ID'] ?? '';
  static final String metaAppSecret =
      Platform.environment['META_APP_SECRET'] ?? '';
  static final String metaOAuthRedirectUri =
      Platform.environment['META_OAUTH_REDIRECT_URI'] ?? '';

  // ── kola_admin (ADMIN_APP_SPEC.md, steps 1-2) ────────────────────────────────
  // Signs/verifies the short-lived JWT AdminAuthService issues on login —
  // completely separate from SUPABASE_JWT_SECRET above, on purpose: an
  // admin session must never be verifiable with the same key a customer
  // session is, or a bug conflating the two auth models becomes a
  // platform-wide compromise instead of a workspace-scoped one (see
  // admin_auth_service.dart's header).
  //
  // UPGRADED FROM A BARE Platform.environment READ to a real @EnviedField,
  // same shape as supabaseJwtSecret above — the original Platform.environment-
  // only version (matching instagramWebhookVerifyToken/the OAuth provider
  // blocks) existed only because no Dart toolchain was reachable to run
  // build_runner at the time. That constraint no longer holds, so this
  // now goes through the same obfuscated-at-build-time path as every other
  // real secret: reads .env via envied when build_runner has been run,
  // falls back to a live Platform.environment var otherwise (e.g. before
  // build_runner has ever been run, or when a deploy target injects the
  // var directly without baking it in).
  @EnviedField(
    varName: 'ADMIN_JWT_SECRET',
    obfuscate: true,
    defaultValue: '',
  )
  static final String adminJwtSecret = _Env.adminJwtSecret.isNotEmpty
      ? _Env.adminJwtSecret
      : Platform.environment['ADMIN_JWT_SECRET'] ?? '';

  // ── Admin MFA (migration 056) ───────────────────────────────────────────────
  // AES-256-GCM master key protecting admin_users.mfa_secret (an
  // enrolled admin's TOTP secret). Deliberately a THIRD distinct secret
  // class from both ADMIN_JWT_SECRET (signs session tokens) and
  // CHANNEL_CREDENTIAL_MASTER_KEY (protects customer channel
  // credentials) — same "rotating one should never require touching
  // another" discipline CHANNEL_CREDENTIAL_MASTER_KEY's own comment
  // states. Must decode to exactly 32 bytes; generate the same way (see
  // channel_credential_encryption_service.dart's header for the exact
  // command). Same fallback shape as adminJwtSecret above: works via a
  // bare Platform.environment read even before `dart run build_runner
  // build` has ever produced the obfuscated path.
  @EnviedField(
    varName: 'ADMIN_MFA_MASTER_KEY',
    obfuscate: true,
    defaultValue: '',
  )
  static final String adminMfaMasterKey = _Env.adminMfaMasterKey.isNotEmpty
      ? _Env.adminMfaMasterKey
      : Platform.environment['ADMIN_MFA_MASTER_KEY'] ?? '';
}
