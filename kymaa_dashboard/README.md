# kola_dashboard

The Kola product dashboard — a Jaspr client-mode web app, separate from
`kola_landing` (the public marketing site) and `kola_server` (the
Serverpod backend).

## Phase 4c — Dashboard shell (static)

This package initially shipped the **dashboard shell only**: the desktop
sidebar + home content layout, and the mobile top-bar + content +
bottom-tab-bar layout, matching
`Kola design system specs/Kola Dashboard Shell.dc.html` value-for-value
(colors, spacing, radii, font sizes, copy).

**Static shell, not wired up yet** — every piece of data on screen
(the workspace name "Aisha's Fashion House", the four quick actions,
the four Recent entries) is mock data defined directly in
`lib/pages/dashboard_home_page.dart`. There is no Supabase Auth, no
`kola_client`, no `http` dependency in this package yet — see
`pubspec.yaml`'s header comment. That's Phase 4e's job, once there are
real functional pages to load data into.

Two architectural decisions were made explicitly for this phase (both
confirmed with the project owner before building):

- **Static shell first** — build the layout against mock data now;
  wire real auth/data in once there's a second real page to test it
  against, rather than half-wiring auth for a shell with nothing to
  authenticate into yet.
- **New `kola_dashboard` package** — a fresh Jaspr client-mode package
  (same shape as `kola_landing`), not a repurposing of the unused
  `kola_flutter` Serverpod Flutter starter, which was never built out.

### Desktop vs. mobile

Both layouts are always in the DOM. Which one is visible is a plain CSS
media query (`web/styles.css`, mobile-first: mobile is the default,
desktop switches on at `min-width: 960px`) — not a JS breakpoint check,
not Dart state. The design file's own Desktop/Mobile and Dark/Light
toggle buttons are design-tool preview chrome and were deliberately not
carried into this build — see `web/styles.css` and `theme.dart`'s
header comments.

## Phase 4d — Chat Mode + Structured Mode (Bot Detail)

Added real multi-page routing via **`jaspr_router`** (confirmed with the
project owner as the approach for the rest of Phase 4 too, rather than a
manual state-based view switch that would need replacing once there are
5+ pages). Routes, defined in `lib/app.dart`:

```
/                 → DashboardHomePage        (Phase 4c)
/bots/:id         → BotDetailChatPage        (Chat Mode)
/bots/:id/code    → BotDetailDevPage         (Structured Mode)
```

This is SRS.md §11's "dual dashboard interface": Chat Mode is the
conversational surface (talk to Bot Mother, see a live plan panel +
WhatsApp preview); Structured Mode is the same bot's table/form/schema
view (Overview/Errands/Knowledge/Channels/Logs/API tabs). The "Plan"/
"Code" tabs in Chat Mode's header and the "Switch to Chat Mode" link in
Structured Mode's header are real `Link`s between the two routes —
matching `Kola Bot Detail Chat.dc.html` / `Kola Bot Detail Dev.dc.html`
exactly.

**Real interactive state, mock content.** Unlike almost everything else
in this shell, tab switching and errand-row selection in Structured Mode
are genuine client-side UI state (`BotDetailDevPage` is a
`StatefulComponent` for exactly this reason). What's still mock: the
actual bot/Errand/conversation content shown regardless of which `:id`
is in the URL — real per-bot data is Phase 4e+'s job once `kola_client`
wiring exists. `SidebarNav`/`BottomTabBar` render a real `Link` for any
href that resolves to a route above, and a plain inert `#` anchor for
everything else (`RecentItem`'s "Trading Bot for WhatsApp" now points at
`/bots/bot_8f2a1c`; "Check order status"/"Escalate to human" point at
`/bots/bot_8f2a1c/code`, per the design file's own destinations for
those two entries).

One added design token: `KolaDashboardColors.mutedSecondary` (`#9C9691`)
— the Bot Detail pages use a second, lighter muted tone alongside the
Dashboard Shell's existing `muted` (`#6B655E`), confirmed by both design
files using the two colors side by side for different emphasis levels.
Also added `KolaDashboardFonts.mono` (IBM Plex Mono) for bot ids, JSON
schema blocks, and curl snippets.

### Structure

```
lib/
  theme.dart              — color/font tokens
  models/
    nav_item.dart, recent_item.dart, quick_action.dart   — Phase 4c
    bot_summary.dart        — bot identity (icon/name/archetype/id)
    chat_message.dart        — one Chat Mode transcript bubble (3 variants)
    errand_chat_summary.dart — one Chat Mode plan-panel errand row
    errand_status.dart       — shared Live/Draft/Needs-input pill colors
    errand_row.dart          — one Structured Mode errands-table row + detail
    preview_message.dart     — one WhatsApp-preview bubble
    knowledge_doc_summary.dart, channel_card_summary.dart,
    log_entry.dart, overview_stat.dart                    — Structured Mode tabs
  components/
    sidebar_nav.dart, home_content.dart, composer.dart,
    quick_actions_grid.dart, quick_actions_list.dart,
    mobile_top_bar.dart, mobile_home_content.dart,
    bottom_tab_bar.dart                                   — Phase 4c
    bot_chat_header.dart, chat_transcript.dart,
    chat_suggestions.dart, chat_composer.dart,
    bot_plan_panel.dart, whatsapp_preview.dart             — Chat Mode
    bot_dev_header.dart, dev_tab_bar.dart,
    dev_overview_tab.dart, dev_errands_tab.dart,
    dev_knowledge_tab.dart, dev_channels_tab.dart,
    dev_logs_tab.dart, dev_api_tab.dart                    — Structured Mode
  pages/
    dashboard_home_page.dart  — '/'
    bot_detail_chat_page.dart — '/bots/:id'
    bot_detail_dev_page.dart  — '/bots/:id/code' (StatefulComponent)
  app.dart                 — jaspr_router root
  main.dart                — entry point
web/
  index.html
  styles.css               — mobile-first desktop/mobile switch only
```

## Phase 4e — Real auth + Errand builder + Knowledge base

`lib/app.dart` is now a `StatefulComponent` holding a real Supabase
session, a `kola_client` `Client`, and the caller's selected
`Workspace` — every route builder closes over this live state instead
of static params. A single `redirect` callback on the root `Router`
gates access: unauthenticated visitors go to `/login`;
authenticated-but-workspace-less ones go to `/create-workspace`.

**Auth** talks directly to Supabase Auth's REST API via plain `http`
calls (`lib/services/auth_service.dart`) — not the `supabase` package,
whose realtime/storage/postgrest/functions surface isn't needed for
sign-in/sign-up/refresh alone. `kola_server` verifies the resulting
JWT locally (HS256) and has no login endpoint of its own. Sessions
persist across reloads via `window.localStorage`
(`lib/services/local_storage.dart`, `package:web`).

**Real routes added:**

```
/login              → LoginPage
/create-workspace    → CreateWorkspacePage
/errands             → ErrandBuilderPage   (real EndpointErrand data)
/knowledge           → KnowledgePage       (real EndpointBot data)
```

`ErrandBuilderPage` creates built-in Errands (`escalateToHuman` is the
only registered handler today) and lists/toggles existing ones —
scoped to what `EndpointErrand` actually supports, not the full DB-
query/webhook Errand types the design implies. `KnowledgePage` is a
deliberately minimal bot picker + textarea bound to
`Bot.knowledgeSeed` — the only knowledge storage that exists
server-side; there's no document upload/parsing backend to build a
richer UI against yet.

`DashboardHomePage`/`BotDetailChatPage`/`BotDetailDevPage` are still on
Phase 4c/4d's mock data — rewiring those to real data wasn't required
to unblock this phase's two new pages.

## Building

Requires `kola_client` to be a sibling package (`../kola_client`) and
this package's `resolution: workspace` membership in the repo root
`pubspec.yaml` — already set up, see `pubspec.yaml`'s header.

```bash
cd kola_dashboard
./build.sh
```

`Env` (`lib/config/env.dart`) reads `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
and `KOLA_SERVER_URL` via compile-time `-D` flags (`dart compile js`
has no `.env` file access) — pass them in `build.sh` for a real deploy;
`KOLA_SERVER_URL` defaults to `http://localhost:8080` for local dev.

## Deploying (task #107 — SPA fallback)

```bash
cd kola_dashboard
SUPABASE_URL=... SUPABASE_ANON_KEY=... KOLA_SERVER_URL=https://api.kola.app ./deploy.sh
```

This is a client-routed single-page app (`jaspr_router`) — a direct load or hard-refresh of e.g. `/errands` must serve `index.html` so the router can take over, not 404 on a missing static file. Cloudflare Pages (what `deploy.sh` deploys to) does this automatically for every deployment, no config needed — see `deploy.sh`'s own header for why a `web/_redirects` file is deliberately NOT added here (Cloudflare's build system treats the obvious `/* /index.html 200` rule as an infinite loop and ignores it).

**Testing this locally** needs a server that supports the same fallback — a plain `python3 -m http.server` will 404 on `/errands`. Use `npx serve -s web` instead (the `-s` flag rewrites every unmatched path to `index.html`).

## What's next

Stale as of task #131 — corrected rather than left inaccurate (all three items below were this section's long-standing "not done yet" list; each is done now):
- Conversations inbox, Integrations page — done (tasks #112/#113).
- `DashboardHomePage`/`BotDetailChatPage`/`BotDetailDevPage` rewired off
  mock data onto real `Client`/session/workspace calls — done
  (tasks #109-111).
- A real workspace switcher — done (task #131 / Phase 8d). See
  `app.dart`'s `_handleWorkspaceSwitch` and `components/sidebar_nav.dart`/
  `components/mobile_top_bar.dart` for the actual UI — a `<select>` in
  each that only renders once a signed-in user has 2+ workspaces
  (the agency/reseller case; everyone else sees no new chrome). The
  choice persists across reloads via `LocalStorage` (see `app.dart`'s
  `_selectedWorkspaceIdKey`).

**Still genuinely outstanding:** no cross-workspace billing/summary
view for an agency tier managing several client workspaces at once —
that's the other half of Phase 8d's "agency/reseller multi-workspace
management" bullet (`docs/DEVELOPMENT_PLAN.md`), not yet scoped let
alone built.
