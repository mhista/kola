# kola_docs

Kola's developer documentation site — a static Jaspr (`mode: client`) app, same scaffolding pattern as `kola_landing`. No backend calls, no auth, no env vars: every page is static content describing the real, current shape of `kola_server`'s API.

## Pages

| Route | Page |
|---|---|
| `/` | Quickstart |
| `/authentication` | Authentication |
| `/errands` | Errands |
| `/webhooks` | Webhooks |
| `/channels` | Channels |
| `/channels/connect-whatsapp` | Connect your WhatsApp (full walkthrough) |
| `/rate-limits` | Rate limits & plans |
| `/sdks` | SDKs |

## Honesty notes (read before extending this site)

This site documents what actually exists in `kola_server` today, not the aspirational shape described in `docs/SRS.md`/`docs/PRD.md`. Two things flagged explicitly on-page rather than glossed over:

- **No workspace-scoped API keys.** SRS.md §12 describes them as the eventual programmatic-auth story; they don't exist. Today, calling the API programmatically means using a real user's Supabase session token. See the Authentication page.
- **No live payment checkout.** Paystack/Flutterwave service wrappers exist and are written against each provider's real documented API, but there's no exposed checkout endpoint, webhook route, or priced plan tier anywhere yet. See Rate limits & plans and Webhooks.
- **No real WhatsApp screenshots.** The Connect your WhatsApp page carries over `docs/WHATSAPP_MANUAL_SETUP.md`'s placeholder markers as real callout boxes rather than faking images (task #88 in the project's own tracker is what closes this gap).

If you add a page or a claim, verify it against the actual endpoint/service source before writing it down — every existing page was written that way, not from memory of what the docs *should* say.

## Build & deploy

```bash
./build.sh    # dart pub get + dart compile js -> web/main.dart.js
./deploy.sh   # build.sh + wrangler pages deploy (Cloudflare Pages)
```
