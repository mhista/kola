# kymaa_landing

**This is a deployment copy of `kola_landing`, not a separate design.** Same content, same code — the only difference is where it's deployed. It exists so `kymaa.tech` (the company's own domain, currently being used to secure a grant) can show the Kola landing page without touching `kola_landing`'s existing Cloudflare Pages project/domain while the product goes through a restructuring. Once the restructured version is ready, `kymaa.tech` gets pointed at that instead — this copy is a stopgap, not a long-term fork. If the landing page's actual content/design changes going forward, keep both copies in sync manually (or fold this back into a single deployment with two custom domains once there's no reason to keep them separate).

Kola's marketing/landing page — a standalone Jaspr `mode: client` app (Phase 1e of `docs/DEVELOPMENT_PLAN.md`). Deliberately **not** a workspace member of the root `pubspec.yaml` — same standalone-app pattern already used for `degenbot_web`, since a Jaspr client app has different dependency needs than the Serverpod server/client/Flutter workspace.

Built from the finished design export (`Kola design system specs/Kola Landing.dc.html`) — copy, colors (`#FAF6EF` bg / `#C1552E` accent / `#1C1815` text), and structure all pulled directly from that file. See `lib/theme.dart` for the design tokens.

## Local development

```
dart pub get
dart run build_runner watch    # or: jaspr serve, if you have jaspr_cli installed
```

## Building for production

```
SUPABASE_URL=https://xxxx.supabase.co SUPABASE_ANON_KEY=eyJh... ./build.sh
```

## Required Supabase setup

The waitlist form talks **directly** to Supabase's REST API with the anon key — no server round-trip (see `lib/services/waitlist_api_service.dart`'s header comment for why this is the right call here, following the same pattern already proven in `degenbot_web`). Before this works, add:

Run `kola_server/docs/migrations/002_waitlist_signups.sql` against your Supabase project (Dashboard → SQL Editor) — it creates the `waitlist_signups` table and its anon-insert-only RLS policy in one file. See `kola_server/README.md`'s "Database migrations" section for the numbering convention this project follows for every schema change going forward.

## Deploying

`./deploy.sh` builds and pushes to Cloudflare Pages via `wrangler` — see the script's header comment for one-time setup steps.

## Waitlist mode vs. Launched mode

There is no on-page control for this — a page visitor should never be able to flip it. Mode is set purely at build time via the `LAUNCH_MODE` env var (see `lib/config/env.dart`), read into `_mode` in `lib/app.dart`. It defaults to `waitlist`. At real launch, rebuild/redeploy with `LAUNCH_MODE=launched` (e.g. `LAUNCH_MODE=launched SUPABASE_URL=... SUPABASE_ANON_KEY=... ./deploy.sh`) — no code changes required.
