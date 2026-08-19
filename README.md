# kolaa

**An AI operating system for small businesses.** [kolaa.co](https://kolaa.co)

---

## The problem this exists for

A shop owner in Lagos already has all the data anyone could want about her
business. It is in a WhatsApp thread with a supplier. It is in a notebook
under the counter. It is in her head — she knows the blue Ankara moves
before Christmas and the children's wrappers do not.

None of it is anywhere she can ask a question of.

So the same four things happen every week. A customer asks "do you have
this in red?" at 11pm and gets no answer until morning, by which time they
have bought it somewhere else. Something runs out and nobody notices until
a customer asks for it. An invoice goes unpaid because chasing it means
scrolling back through six weeks of chat. And at the end of the month she
knows roughly how it went, which is not the same as knowing.

The software that solves this exists. It is called an ERP, it costs more
than her rent, it assumes she has an IT person, and it assumes she wants
to type her business into forms for three weeks before it does anything
useful. That is not a price problem. It is a shape problem.

## What kolaa actually is

kolaa is the memory and judgement layer that small business has never had
— the part of an ERP that would have been useful, without the part that
requires a consultant.

Three things, in this order, because the order is the product:

**It remembers.** You give kolaa what you already have — a price list, a
supplier agreement, a photo of your delivery zones scrawled on paper, the
way you actually answer the question about returns. It reads them, keeps
them, and can cite which document an answer came from. Nothing is retyped
into a form.

**It answers.** Customers reach your business on WhatsApp and Telegram
because that is where they already are. kolaa answers them from what your
business knows, in your voice, at 11pm — and hands the conversation to a
human the moment it is out of its depth, rather than guessing.

**It notices.** This is the part that is not a chatbot. kolaa watches what
changes and tells you before you would have found out: what has gone out
of stock, who has been waiting on a reply for two days, which promise to a
named customer is about to be missed. You do not ask. It is on the screen
when you open it in the morning.

The value compounds. A business that has used kolaa for a year has a year
of its own operating knowledge inside it, and that is the thing that is
hard to leave — not the model underneath, which is replaceable by design.

## What it is not

- **Not a chatbot builder.** Answering customers is the doorway, not the
  product. If that were the whole thing, the value would live in whichever
  LLM is cheapest this quarter.
- **Not analytics.** A dashboard of charts hands the interpretation back
  to the owner. kolaa is supposed to have already done that part.
- **Not an AI that invents facts about your business.** Findings are
  computed from your rows by deterministic rules — "this product has 0
  stock" is either true or it is a bug. When a model does write something,
  it is marked, and it never sources a number: prices, stock and totals
  are read from the database at the moment they are displayed, never from
  prose.

## Design principles

These are load-bearing. Most of the architecture falls out of them.

1. **The LLM is replaceable. The business memory is not.** Providers are
   routed behind an interface; two model shutdowns during development
   changed nothing above that line.
2. **Never show a customer a number you are not sure of.** A blank price
   means "ask", not "free". Blank stock means "not something we keep",
   not "out of stock". Typing `0` in either is a false fact, not an empty
   one.
3. **Every answer can name its source.** If kolaa cannot say where it
   learned something, it should not be saying it.
4. **Nigeria first, not Nigeria only.** Money is stored in integer minor
   units with a per-row currency, prices are regional by purchasing power
   rather than one converted number, and the copy ships in five languages.
   Nothing in the product is country-specific.
5. **Offline is a normal condition, not an error state.** The connection
   drops mid-sale. That is Tuesday, not an exception to handle later.
6. **Silence is the enemy.** Nearly every serious bug found in this
   codebase failed silently — an upload that did nothing, a retrieval that
   returned nothing, a deploy that reported success and changed nothing.
   Prefer loud failure to a clean-looking screen.

## Where it is

Working: knowledge ingestion and retrieval with citations, WhatsApp and
Telegram channels with escalation to a human, product catalog with CSV
import, the answer layer, and the observation engine behind "Needs your
attention".

In flight: the sales counter, automations on the new UI, and the report
layer.

Deliberately not built yet: anything that would need to guess. The AI hook
that reasons *across* findings is designed and left unwired rather than
filled with something plausible.

---

## Repository

A Dart monorepo. Serverpod Mini for the API surface and code generation;
Supabase (Postgres) owns all persistence.

| Package | What it is |
|---|---|
| `kola_server` | The backend. Endpoints, AI orchestration, retrieval, channels, the observation engine. Schema lives in `docs/migrations/`. |
| `kola_dashboard` | The product. Jaspr client-mode web app — [dash.kolaa.co](https://dash.kolaa.co). |
| `kola_landing` | The marketing site — [kolaa.co](https://kolaa.co). |
| `kola_docs` | Public documentation. |
| `kola_client` | Generated Serverpod client. Not hand-edited. |
| `kola_flutter` | Scaffold for a future native app. Not on the critical path. |
| `kymaa_*` | Frozen. An earlier competition entry, kept for reference. |
| `docs/` | PRD, SRS, design briefs, build audits, legal. |
| `Kola design system specs/` | The design exports. **These are the specification** — where the server cannot serve what a design shows, the server is what is missing. |

### Architecture, briefly

- **Serverpod Mini** with the database feature disabled — no model carries
  a `table:` line. Supabase owns the schema; a DTO + repository layer
  bridges the two. Migrations are numbered SQL files, each self-contained
  and safe to re-run, with its RLS policy written alongside it.
- **RLS is enabled with no policies**, so the repository layer *is* the
  tenant isolation boundary rather than a second line of defence behind
  one. Every method takes a `workspaceId` and filters on it.
- **Jaspr client-mode** for both web front-ends — one language across the
  stack, and no server-side rendering to keep alive.
- **Money in integer minor units**, never doubles, with currency per row.

### Running it

Each package has its own README with the real detail. In short:

```bash
cd kola_server
cp .env.example .env          # Supabase URL, service_role key, JWT secret
dart pub get
dart run serverpod generate   # required before anything compiles
dart run build_runner build --delete-conflicting-outputs
dart bin/main.dart
```

Then apply everything in `kola_server/docs/migrations/` in order, via the
Supabase SQL editor.

The `service_role` key never leaves the server. The `anon` key is public
by design and is compiled into the browser bundles — RLS is what protects
the data, not secrecy of that key.

### Contributing notes

If you work on this, two habits matter more than any style rule:

- **Read the generated client signature before calling an endpoint.**
  Serverpod drops default values during generation — `bool x = false`
  becomes `required bool x`.
- **Say what you did not verify.** An unverified claim stated plainly is
  useful. An unverified claim stated confidently is the bug.

---

## Topics

For the repository sidebar — GitHub allows up to 20:

```
ai-agents  business-intelligence  small-business  smb  erp  dart  serverpod
jaspr  supabase  postgres  whatsapp-bot  telegram-bot  rag  vector-search
llm  multi-tenant  africa  nigeria  inventory-management  ai-assistant
```

If you want a shorter, sharper set, these six carry the most weight:
`ai-agents`, `small-business`, `dart`, `supabase`, `rag`, `whatsapp-bot`.

---

© kolaa. Nigeria.
