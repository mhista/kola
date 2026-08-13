-- ─────────────────────────────────────────────────────────────────────────────
-- Kola — Supabase schema (migration 032 — inbound message media)
--
-- Apply AFTER 031.
--
-- WRITTEN AFTER THE FACT. This was applied straight to the database and the
-- file was not created at the time — the same failure BUILD_AUDIT_5 §2.7
-- records for migration 025, which existed only in the database for weeks.
-- Recorded here so the schema can be rebuilt from this folder alone.
--
-- ── WHAT WAS MISSING ─────────────────────────────────────────────────────────
--
-- Message carried only `body: String`. A customer who sent a photo produced a
-- row with an empty body and nothing else — the image was dropped on the floor.
--
-- For a shop where "do you have this?" is answered by SENDING A PICTURE, that
-- is the most important message type there is, and it was the one type kola
-- could not see.
--
-- ── HOW THE BYTES GET HERE ───────────────────────────────────────────────────
--
-- Not the way dashboard uploads do. WhatsApp and Telegram hand the webhook a
-- media REFERENCE, and resolving it needs that channel's own credentials:
--
--   Telegram   file_id → getFile → file_path → download from
--              api.telegram.org/file/bot<TOKEN>/<path>
--   WhatsApp   media id → GET /<id> → a short-lived url that STILL needs an
--              Authorization: Bearer header to fetch
--
-- So kola_server downloads and re-uploads to ImageKit rather than letting
-- ImageKit fetch the source. Telegram's URL embeds the bot token, and handing
-- that to a third party would hand over the credential that can read and send
-- every message for that business. See ImageKitService.uploadBytes and
-- InboundMediaService.
--
-- ── media_kind SET WITH media_url NULL IS A REAL STATE ───────────────────────
--
-- It means: the customer sent a file, and kola could not store it.
--
-- Every method on the media path returns null instead of throwing, so a CDN
-- being briefly unreachable costs the picture and never the MESSAGE. The
-- conversation still routes, the owner still sees that something was sent.
-- Losing a customer's "do you have this?" because a CDN blinked would be far
-- worse than losing the image, so nothing downstream may treat this pairing as
-- an inconsistency to normalise away.
-- ─────────────────────────────────────────────────────────────────────────────

alter table messages
    add column if not exists media_kind text,
    add column if not exists media_url text,
    add column if not exists media_thumbnail_url text,
    add column if not exists media_imagekit_file_id text,
    add column if not exists media_mime_type text;

alter table messages
    add constraint messages_media_kind_check
    check (media_kind is null or media_kind in ('image', 'video', 'audio', 'document'));

comment on column messages.media_kind is
    'Set when the customer sent a file rather than only text. NULL means a '
    'plain text message.';
comment on column messages.media_url is
    'Permanent ImageKit CDN URL. NULL with a non-null media_kind means the '
    'file arrived but could not be stored — the message is still real and '
    'still shown.';
comment on column messages.media_imagekit_file_id is
    'ImageKit fileId, needed to delete the asset if the conversation is ever '
    'purged.';
