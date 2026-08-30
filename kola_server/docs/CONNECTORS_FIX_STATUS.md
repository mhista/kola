# Fix-properly pass — connectors + KolaException crash

Scope: "fix all this things properly including the connectors and the
exceptions" (verbatim ask, following an earlier pass that only added an
honest "not wired up yet" message for 5 broken Connect buttons).

## Connectors

Five connectors were `ConnectorAuth.oauth` in the catalog with no real
flow behind them: `instagram_shop`, `facebook_catalog`, `dropbox`,
`hubspot`, `slack`. All five are now either genuinely connectable or
correctly routed to where they already work.

### Slack — recategorized, not rebuilt

Slack was never really an OAuth connector. `slack_owner_notifier.dart`
already sends escalations through a BYO Incoming Webhook URL, and the
Settings page already has a full, working form for it (owner
notifications section) — repository, DTO, and endpoint all already
existed. The catalog entry was simply wrong.

Fixed by recategorizing `slack` as `ConnectorAuth.manage` (an auth type
this catalog already has for exactly this shape — "already configured
elsewhere in the product") pointing at `/settings`, and teaching
`ConnectorService` to resolve slack's connected/available status from
`OwnerNotificationSettings` instead of the (always-empty, for slack)
generic `workspace_connectors` store.

Building a second, Kola-owned Slack App OAuth integration next to a
working BYO-webhook one would have been redundant, not a fix.

### Dropbox, HubSpot, Meta (instagram_shop + facebook_catalog) — real OAuth, built new

Genuinely new server infrastructure, following the exact shape
`google_oauth_service.dart` / `google_oauth_callback_route.dart`
established: a plain-HTTP `*OAuthService` (authorizationUrl /
exchangeCode / refresh), a `*OAuthCallbackRoute` (state verification,
token exchange, redirect back to `/integrations`), a `ConnectorEndpoint
.startXOAuth` method, a hand-added `kola_client` caller, and a real
dispatch branch in the dashboard's `_startOAuth`.

Provider mechanics were researched live (not assumed) against each
provider's own current docs:

- **Dropbox** — `developers.dropbox.com/oauth-guide`, cross-checked
  against `dropbox.tech`. `token_access_type=offline` for a real
  refresh token.
- **HubSpot** — `developers.hubspot.com/docs/guides/api/app-management/
  oauth-tokens`. `app.hubspot.com/oauth/authorize` +
  `api.hubapi.com/oauth/v1/token`.
- **Meta** (shared by both connectors — one Meta App, two scope sets)
  — `developers.facebook.com/docs/facebook-login/guides/advanced/
  manual-flow/`. No refresh token in this OAuth flow; a short-lived
  token is exchanged for a long-lived (~60 day) one immediately in the
  callback route — see `meta_oauth_service.dart`'s header for why
  there's no later "refresh" call the way Google/Dropbox/HubSpot have.

### What's still a manual, one-time step

None of these four work until someone:

1. Registers a real app with each provider (Dropbox App Console,
   HubSpot Developer account, Meta App Dashboard) and sets its 3
   env vars (`.env.example` has the full list, with the redirect URI
   each provider's app must be configured to accept).
2. For Meta specifically: adds `catalog_management`, `instagram_basic`,
   `pages_show_list`, `business_management` under App Review before
   anyone outside the app's own test users/roles can grant them.
3. **Redeploys kola_server** — see below, this is not optional.

The connectors are real and wired end-to-end in the source. They will
not do anything on the *currently running* server until it's rebuilt
and redeployed with this code, for the same reason described next.

## The KolaException serialization crash — root cause found: stale deployment, not a bug

Traced the exact crash (serverpod 3.4.12's own `Server._reportException`
→ `SerializationManager.encodeWithTypeForProtocol` →
`getClassNameForObject` returning null → `ArgumentError`) against this
app's own generated code. `KolaException` correctly implements
`SerializableException`, and `Protocol` (which `Server.serializationManager`
literally *is* — set from `Serverpod(args, Protocol(), ...)`) correctly
registers it in both `getClassNameForType` and `getClassNameForObject`.
There is no missing registration, no wrong class, nothing to patch —
the source that would need fixing is already correct.

That registration has existed since commit `e992c16` ("Make server
errors reach the owner"), **2026-08-13** — over two weeks before the
crash was reported. So why is a production server still failing on
code that's been fixed for two weeks?

`kola_server/deploy.sh`'s own header explains it: kola_server does not
auto-deploy on git push. Northflank's service is configured as an
**External image** source — someone has to run `docker build` → `docker
push` → `northflank patch service deployment` by hand (that's what
`deploy.sh` automates) for any code change, including this one, to
reach the running container. Nothing in this repo triggers that on a
commit.

**Conclusion: the running server is almost certainly compiled from a
build older than 2026-08-13, not from a defect in the current source.**

**Fix: run `kola_server/deploy.sh`** (see its header for the one-time
Northflank/Docker Hub setup if that hasn't happened yet) to build and
push the current source, including everything in this pass. That
single redeploy should resolve the KolaException crash AND bring the
connector fixes above online — there's no separate code change to make
for the exception.
