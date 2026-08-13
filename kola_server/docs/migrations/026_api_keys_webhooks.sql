-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 026 — API keys + outbound webhooks)
--
-- Apply AFTER 025.
--
-- Backs Kola API Webhooks.dc.html: API keys with scope and last-used, and
-- webhook endpoints subscribed to named events.
--
-- ── THE KEY IS NEVER STORED ──────────────────────────────────────────────────
--
-- `key_hash` holds SHA-256 of the full key and nothing else. The plaintext
-- key is generated, shown to the owner EXACTLY ONCE at creation, and then
-- unrecoverable — which is why the design's create-key flow has a distinct
-- "here is your key" state (`newKeyValue`) rather than a row you can expand
-- later.
--
-- This is deliberately NOT the AES-encrypted approach used for channel
-- tokens and gateway secrets. Those must be decrypted to be USED — kola
-- calls Telegram with the bot token. An API key is only ever COMPARED: a
-- request arrives carrying a key, we hash it and look for a match. A
-- reversible secret we never need to reverse is a liability with no upside,
-- and it means a database leak does not hand over working credentials.
--
-- `last_four` exists purely so the UI can render `sk_live_••••8f2a` and the
-- owner can tell two keys apart. Four characters of a 32-byte random key is
-- not enough to narrow anything.
--
-- ── SCOPES ARE ENFORCED SERVER-SIDE, NOT DESCRIPTIVE ─────────────────────────
--
-- Values match the design's SCOPES list. They are stored snake_case and
-- rendered in the design's words:
--
--   full          'Full access'   read + write + execute errands
--   read_only     'Read-only'     GET only
--   errands_only  'Errands only'  execute a named errand, nothing else
--
-- The third exists because "let my Zapier action run one errand" should not
-- require a key that can also read every conversation.
--
-- ── WEBHOOK EVENTS ───────────────────────────────────────────────────────────
--
-- `events` is a text[] of the design's EVENT_TYPES, stored snake_case:
--   new_conversation · errand_executed · bot_published · payment_confirmed
--
-- An array rather than a join table: the set is small, fixed, and always
-- read whole. A join table here would be three queries to draw one chip row.
--
-- `encrypted_secret` IS reversible, unlike the API key, and that asymmetry is
-- the point: kola must sign every outgoing delivery with it, so it has to be
-- recoverable. Encrypted with ChannelCredentialEncryptionService (AES-256-GCM)
-- — the same service, not a second one.
--
-- ── WHAT THIS MIGRATION DELIBERATELY DOES NOT ADD ────────────────────────────
--
-- No request-counter table. The design shows "Requests today · 1,842", and
-- counting real requests needs either a log table or a counter incremented on
-- every authenticated call — a decision that should be made when the public
-- API actually serves traffic, not guessed at now. Until then the UI reports
-- that it is not measured rather than showing a number nothing produced.
--
-- ── RLS ──────────────────────────────────────────────────────────────────────
--
-- Enabled, no policies — deny-all to PostgREST. Matches channels,
-- payment_gateway_credentials, feature_flags, knowledge_documents and
-- workspace_connectors. The server reaches these over Serverpod's direct
-- postgres connection as table owner, which RLS does not apply to.
-- ─────────────────────────────────────────────────────────────────────────────

create table if not exists api_keys (
    id            bigserial primary key,
    workspace_id  bigint      not null references workspaces (id) on delete cascade,

    -- Owner-chosen label: "Production", "Staging".
    name          text        not null,

    -- 'sk_live' or 'sk_test'. Stored separately so the UI can render the
    -- prefix without holding the key.
    key_prefix    text        not null default 'sk_live'
                  check (key_prefix in ('sk_live', 'sk_test')),

    -- SHA-256 hex of the full plaintext key. UNIQUE: two keys hashing the
    -- same would mean a generator collision, and the constraint turns that
    -- into a loud failure instead of a silent authentication ambiguity.
    key_hash      text        not null unique,

    -- Display only. See the header.
    last_four     text        not null,

    scope         text        not null default 'full'
                  check (scope in ('full', 'read_only', 'errands_only')),

    -- Null until the key authenticates something. The design renders this
    -- as "last used 3m ago" / "never".
    last_used_at  timestamptz,

    -- Revocation is a TIMESTAMP, not a delete. A revoked key must stay
    -- visible long enough for an owner to understand what stopped working,
    -- and deleting the row would also delete the audit trail of a key that
    -- may have been leaked.
    revoked_at    timestamptz,

    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

create index if not exists api_key_workspace_idx on api_keys (workspace_id);

-- The authentication path: hash the presented key, find the row. Partial
-- index because a revoked key must never authenticate, so the lookup never
-- wants those rows.
create index if not exists api_key_hash_live_idx
    on api_keys (key_hash) where revoked_at is null;

alter table api_keys enable row level security;


create table if not exists webhook_endpoints (
    id              bigserial   primary key,
    workspace_id    bigint      not null references workspaces (id) on delete cascade,

    url             text        not null,

    -- Subscribed events. See the header on why an array.
    events          text[]      not null default '{}',

    status          text        not null default 'active'
                    check (status in ('active', 'paused', 'failing')),

    -- Reversible, unlike api_keys.key_hash — kola signs each delivery with
    -- it. AES-256-GCM via ChannelCredentialEncryptionService.
    encrypted_secret text,

    last_delivery_at timestamptz,

    -- Why the last delivery failed, in plain language. Drives the `failing`
    -- status, so an owner learns their endpoint is down from kola rather
    -- than from missing data.
    last_error       text,

    created_at       timestamptz not null default now(),
    updated_at       timestamptz not null default now()
);

create index if not exists webhook_endpoint_workspace_idx
    on webhook_endpoints (workspace_id);

-- One subscription per URL per workspace. Registering the same URL twice is
-- an edit, not a second endpoint — otherwise every event delivers twice and
-- the duplicate is invisible in the UI.
create unique index if not exists webhook_endpoint_unique_idx
    on webhook_endpoints (workspace_id, url);

alter table webhook_endpoints enable row level security;
