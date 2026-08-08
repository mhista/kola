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

  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true, defaultValue: '')
  static final String geminiApiKey = _Env.geminiApiKey.isNotEmpty
      ? _Env.geminiApiKey
      : Platform.environment['GEMINI_API_KEY'] ?? '';

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
}
