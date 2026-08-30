# Gate 12 — Public query API

Status: **BUILT**. `POST /v1/ai/query` — the public, API-key-authenticated
surface for the cross-source Q&A the owner dashboard's "Ask kola" box has
had since Gate 4's connector-aware AI layer. This gate was always about
exposing an *existing* capability publicly, not building a new one — the
Rev 6 roadmap's own note on Gate 12 says as much ("WorkspaceAnswerService
now answers cross-source questions... but only inside the owner
dashboard. No public POST /v1/ai/query HTTP surface").

## What was reused vs. built

Reused, unchanged:

- **`WorkspaceAnswerService.ask`** — the whole answering pipeline (memory
  retrieval, catalog/connector/sales digests, action-tool dispatch,
  citations). This route calls the exact same method the dashboard does.
- **`ApiKeyService`** — key generation, hashing, `verify()`. Already
  built and already had a real caller (`SendMessageRoute`, Gate 8).
- **`FeatureKeys.publicApi`** (`platform.public_api`) — already declared
  and already seeded (`locked`, confirmed live via SQL, not assumed).
  No migration needed.
- **The route shape itself** — `SendMessageRoute` (Gate 8) already
  established "custom `Route` on `webServer`, Bearer-token auth via
  `ApiKeyService`, real HTTP status codes instead of always-200" as this
  codebase's public-API pattern. `AiQueryRoute` follows it exactly rather
  than inventing a second convention.

Built new:

1. **`AiQueryRoute`** (new, `lib/src/services/assistant/ai_query_route.dart`)
   — `POST /v1/ai/query`, registered on `webServer` in `server.dart`
   alongside `SendMessageRoute`. Body: `{"question": "..."}`. Response:
   `{ok, answer, productIds, citations, generated, providerName}`.
2. **`WorkspaceAnswerService.ask`/`_askInner` gained `allowActions`**
   (default `true`, so every existing internal caller — the dashboard —
   keeps identical behavior). When `false`, the action-tool list is never
   built (an empty set is passed straight to the model, cheaper than
   building real tools and discarding them), so the model can only ever
   reply, never dispatch an Errand. This is the one real code change this
   gate required outside the new route file.

## The scope decision — the one real design choice in this gate

`ask()` can, by design (see that file's own header, rule 3), execute a
real action — book a calendar event, run an Errand — when the model
chooses to. That is a WRITE, the same class of capability
`SendMessageRoute` already restricts to `full`-scope keys. So an API
key's stored **scope** (not a request-body flag a caller could set
however they like) decides what this endpoint can do:

| Scope | Behavior |
|---|---|
| `full` | Complete capability — identical to what the dashboard gets, including action execution. |
| `read_only` | Real answers, real citations, but the model is never offered an action tool — a promise the platform enforces, not just a label. |
| `errands_only` | **Rejected outright, 403.** See below. |

**Why `errands_only` is rejected rather than mapped onto something:**
that scope's own name promises the opposite of this endpoint's default
shape (broad Q&A that *may* incidentally trigger an action) — a mode
that restricts queries to exactly one named errand is real, separate
work this pass didn't do. Guessing an interpretation (treat it as
`read_only`? as `full`?) would be inventing a security boundary rather
than building the one the name actually implies. Left honestly
unsupported, with a clear error, until it's built for real.

## Real, named scope cuts

- **No public documentation page.** `FeatureKeys.developerPortal`
  (`platform.public_api`'s sibling, `platform.developer_portal`) is
  still its own unbuilt gate per the roadmap — this pass ships the
  endpoint, not a docs site describing it. The dashboard's API key
  management screen (`api_webhooks_page.dart`, already built for Gate 8)
  was not changed to mention `/v1/ai/query` in-app; this status doc is
  the only place it's currently documented.
- **`WorkspaceAnswer.actions`** (dashboard navigation intents like
  `open_catalog`) is intentionally **not** included in the response —
  those routes only exist inside `kola_dashboard`'s own router and are
  meaningless to an external caller. An earlier draft of this route
  tried to report whether an action was actually *executed* by inventing
  an `executed` field on `WorkspaceAnswerAction` — checked against the
  real generated model (`workspace_answer.dart`) and that field does not
  exist; there is no clean boolean anywhere in `WorkspaceAnswer` that
  distinguishes "the model replied" from "the model executed an action
  and then replied with the result" — both look like ordinary prose in
  `answer.answer`. Rather than fabricate a signal the underlying service
  doesn't actually provide, the response omits the claim entirely. A
  real `actionExecuted` field is a `WorkspaceAnswerService`-level
  change, not something this route should paper over.
- **No incremental/streaming response.** One request, one complete JSON
  answer — matches `SendMessageRoute`'s own synchronous shape, and
  `WorkspaceAnswerService.ask` itself isn't built to stream.

## Verification note

Same limitation as every gate this session: no Dart toolchain here, so
none of this compiled locally. The `allowActions` parameter is additive
with a default that preserves existing call sites verbatim — the
dashboard's own "Ask kola" caller was not touched and needs no change —
but `dart pub get` is still required before this builds. No migration
was needed or applied; `platform.public_api` was already seeded
`locked` in the live database (confirmed via direct SQL query, not
assumed) — unlocking it in `kola_admin` is what makes this endpoint
usable for a given workspace, no deploy required, per this codebase's
own locked-release model.
