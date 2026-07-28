# WhatsApp/Facebook Connect Flow — Research & Adoption Plan

**Companion to:** `SRS.md` §12 (API & Developer Experience), `PRD.md` §7 (Feature List)
**Source:** live walkthrough of AppEdge's "Sabi" app (24 screenshots reviewed, saved in `/screenshots`), plus Meta's own developer documentation
**Status:** Draft v0.1 — this is a build-ready technical reference, not just competitive notes

---

**A note on how to use this document:** everything below is research into how a competitor built their product, not a spec to replicate verbatim. Sabi built theirs, we're building ours — the goal is to take the parts that are genuinely good ideas (the underlying Meta mechanism, the step-count/progress-bar pattern, the QR-code test step), phase them into our own architecture and voice, and deliberately do better where their execution is rough (the 1-hour hard cutoff, the ToS's blanket ban on broadcast). Every recommendation below says which parts to adopt as-is (mostly the Meta *mechanics*, since those are Meta's rules, not Sabi's design) versus which to reinterpret in our own way (the surrounding product UX, tone, and business model).

## 1. What we confirmed by walking through a competitor's real flow

You connected your own Facebook account and WhatsApp inside the Sabi app, and it turns out that's not a custom thing Sabi built — it's **Meta's own standard "Embedded Signup" flow** (part of the WhatsApp Business Platform / Cloud API), which any developer can integrate once approved. Sabi is registered with Meta as a **Tech Provider** under the business name "Appedge," and the entire connect experience you saw is a Meta-hosted webview, not Sabi's own UI — Sabi just triggers it and receives the result. This is very good news: it means the exact experience you were impressed by is fully available to us too, it isn't proprietary to them.

## 2. The flow, step by step (as observed)

1. **App-level login:** "Continue with Facebook" on Sabi's welcome screen — standard Facebook OAuth.
2. **Bot Setup wizard, Step 1 of 4 — Business Profile:** business/bot name, then a **knowledge source** choice (Website URL — auto-scrape, or Manual text — paste business info, with an "Upload Doc" option supporting PDF/Word/Text). This maps directly to our own Knowledge/document-parsing engine (SRS §8) — same idea, different entry point.
3. **Step 2 of 4 — Connect WhatsApp:** a single "Connect via Meta" button. Tapping it hands off to **Meta's Embedded Signup webview** (this is the part that isn't Sabi's own UI):
   - Facebook login screen (if not already signed in).
   - **"Review Sabi's access request"** — Meta's standard permission-grant screen, listing exactly what's being requested: receive email address, manage WhatsApp accounts, manage/access WhatsApp conversations — with a link to "Meta Business Tools" terms.
   - **Opt-in scope choice:** "Opt in to all current and future WhatsApp accounts" vs. "Opt in to current accounts only," followed by a checklist of the user's existing WhatsApp Business accounts/portfolios to select from (this account had several — a personal WABA sandbox habit worth noting).
   - **"Seamlessly connect your account to Appedge"** — an explainer screen ("You'll be able to: communicate with customers at scale, send messages with optimizations") with consent checkboxes for the **Marketing Messages API for WhatsApp Terms**, Meta Business Tools Terms, Meta Hosting Terms for Cloud API, and Meta Terms for WhatsApp Business.
   - **Business asset selection:** pick or create a Business Portfolio, pick or create a WhatsApp Business Account within it.
   - **Phone number step — "Add your WhatsApp phone number":** two real options, and this is the single most important technical finding —
     - **"Add a new number"** — the business's own dedicated phone number/SIM, verified once by SMS/voice OTP. Once registered this way, **that number can never be used in the regular WhatsApp or WhatsApp Business consumer app again** — it becomes API-only, permanently. Meta shows this as a plain warning, not a hidden gotcha.
     - **"Use a display name only"** — Meta issues a **shared/placeholder test number** (you saw `+1 555-468-0105` — a classic North-American fake-number pattern) where the customer only ever sees the business's display name, not a real number. This is explicitly a **testing/trial mechanism, not a production numbering solution** — it's what powers the "your bot will disconnect in 1 hour" test window later in the flow, not a free permanent number for every business. **Correcting our own earlier assumption:** Meta does not hand every business a free production number — a real business still needs a real dedicated line for production use. What Meta removes is the *manual Business Manager dashboard work*, not the *need for a number*.
   - **Business verification notice:** "Before you can begin messaging, Appedge will need to verify your business. You'll receive an email when this is complete" — plus a note that during review, **5 business-initiated test messages every 24 hours** are allowed, with full review taking up to 1 business day.
   - **Display name entry**, with Meta's display-name guidelines shown inline (must match the real business name, no all-caps, etc. — rejected names are a real failure mode to design for).
   - **Extra opt-ins:** "Turn on insights for your business," "Instruct Meta to automatically identify order and lead events" — both pre-checked, both linked to "see terms and details."
   - **"Add payment method" / "Finish"** — closes the Meta webview and returns control to Sabi.
4. **Back in Sabi, Step 4 of 4 — Test Your Bot:** a QR code plus a tappable "Open WhatsApp" button pointing at the connected (test) number, a live countdown banner — **"Your bot will disconnect in 1 hour. Upgrade to keep it running"** — with a "Pay Now" button inline, right next to the QR code. This is Sabi's monetization trigger point, and it's aggressive: an hour, hard stop, no soft landing (see §5 for how we're doing this differently).
5. Once paid, the Home dashboard shows a live bot card ("Bot is Live," the connected display name + number, an "AI Active" pill) plus usage stats (All-Time AI Usage against a plan cap, Messages/Active Leads/New Customers/Total Conversations, Recent Conversations).

## 3. What this means for our build

- **We should adopt the same pattern, in-app, at MVP1 — not defer it to Phase 2 as originally scoped.** The previous draft of `SRS.md`/`COMPETITIVE_FEATURES.md` treated a fully in-app, no-Business-Manager-visit connect flow as a Phase 2 nice-to-have requiring a BSP partnership. Having now seen a small, real competitor ship this exact experience, doing anything less at MVP1 (e.g., sending the owner off to Meta Business Manager manually) would be a visible step down from the market's current bar, not a differentiator.
- **We don't strictly need a BSP partner (360dialog/Gupshup/Twilio) to do this.** Sabi/AppEdge integrated directly against Meta's own Cloud API as a Meta **Tech Provider**, with their own Meta App. That's the leaner path: register our own Meta App, request the `whatsapp_business_management`, `whatsapp_business_messaging`, and `business_management` permissions, go through Meta's App Review, and implement Meta's Embedded Signup SDK/webview ourselves. A BSP remains a reasonable *fallback* if we'd rather offload Meta compliance/support to a partner, or later want faster multi-country rollout — but it's no longer a hard prerequisite, and shouldn't block MVP1.
- **The phone-number problem is only partly solved by this flow, and we should say so plainly in onboarding, not paper over it.** A business still needs one real, dedicated number they're willing to permanently retire from consumer WhatsApp. The Embedded Signup flow makes *connecting* that number effortless; it does not make the number appear out of nowhere. Our onboarding copy should set this expectation clearly (mirroring Meta's own plain warning) rather than let a business discover it mid-flow.
- **The "Marketing Messages API for WhatsApp"** consent shown in step 3 is a real, named Meta product (Meta calls it "MM Lite API," launched April 2025): a delivery-optimized channel purpose-built for outbound marketing/broadcast template messages, distinct from the standard two-way Cloud API. **This is the API to build our Phase 2 WhatsApp broadcast feature on** (`COMPETITIVE_FEATURES.md` §2.1), not raw template sends — it's what Meta itself steers Tech Providers toward for this exact use case.
- **Interesting asymmetry to exploit:** Sabi's own Terms of Service explicitly **prohibit users from sending bulk broadcast messages** ("You will not use Sabi to send spam, unsolicited messages, or bulk broadcast messages"). Whether that's a policy caution or a real product gap, broadcast is confirmed as something they deliberately don't offer today — reinforcing it as a genuine Phase 2 differentiator for us, not a feature we'd be copying.
- **Operational idea worth stealing outright:** Sabi's Privacy Policy describes a **nightly automated check on stored WhatsApp access tokens**, pushing a notification to the owner to re-authenticate if a token is invalid or expiring — this prevents the silent-failure mode where a bot quietly stops responding and nobody notices for days. Worth adding to `SRS.md` §13 (Non-Functional Requirements / Observability) as a concrete, cheap-to-build reliability feature.
- **Documentation implication:** once you send over your own screenshots of this same flow (or we capture fresh ones against our own Meta App once it exists), this becomes a dedicated "Connect your WhatsApp" walkthrough page on the developer/business docs site (`SRS.md` §12), written for a non-technical owner, step-by-step, screenshot-by-screenshot — the exact page a "Chioma" persona needs and currently has to figure out alone.

## 3a. Numbers at launch: bring-your-own only, and say so clearly

We have no budget to buy or stock phone numbers right now, and the good news is MVP1 never needed one: the entire "Connect via Meta" build above is free (Meta doesn't charge for App Review, Tech Provider registration, or our own Business Verification — only engineering time). The only thing that costs money is the phone number itself, and at launch **that cost stays with the business, not us** — they bring their own existing number or buy a cheap SIM themselves.

What this means concretely:

- **MVP1 ships with zero numbers inventory, zero BSP relationship, zero NCC registration on our side.** All of that (§6 below) is real, but it's gated on having revenue to justify it — not a fixed calendar phase.
- **What we owe the business instead is honest, upfront disclosure**, since the number they connect is genuinely sacrificed. This has to happen *before* they commit, not as a surprise mid-flow (Meta's own screen does show this warning, but plainly, easy to skim past — ours should be unmissable). Required disclosure points, to appear as a dedicated screen or explicit checkbox before Step 2's "Connect via Meta" button (see `DESIGN_PROMPT.md`):
  1. "This number will stop working in the regular WhatsApp/WhatsApp Business app once connected — permanently." Plain language, not buried in a terms link.
  2. "Use a number you don't need for personal WhatsApp anymore, or buy a cheap SIM just for this."
  3. "Don't have a spare number yet? Start with Telegram instead — it's free and takes two minutes, no number required." — a real, honest off-ramp, not a dead end, especially valuable while we have no budget to smooth this over any other way.
- **Telegram becomes the practical zero-cost front door** for a business with no spare number or no Facebook account yet — genuinely $0, no Meta approval, no number sacrificed, live in minutes via a bot token. Onboarding copy and the channel-choice step in the wizard should present it as a legitimate first choice, not a fallback for people who "can't do WhatsApp properly."

## 4. Facebook/Instagram permissions worth scoping now, even if not built at MVP1

Since Meta's own tooling clearly goes further than just WhatsApp connection, it's worth listing what else is realistically reachable through the same Meta Business/Graph API relationship, so future phases aren't each starting a fresh Meta-permissions conversation:

| Capability | Meta mechanism | Where it fits |
|---|---|---|
| WhatsApp connect (this document) | Embedded Signup, Cloud API | MVP1 |
| WhatsApp template/marketing broadcast | Marketing Messages (MM Lite) API | Phase 2 (`COMPETITIVE_FEATURES.md` §2.1) |
| Facebook/Instagram catalog sync | Meta Commerce/Catalog API | Phase 2 (unchanged from PRD) |
| Instagram comment-to-DM lead capture | Instagram Graph API (requires Meta Business Partner review) | Phase 3, pull-forward candidate (`COMPETITIVE_FEATURES.md` §2.4) |
| Verified badge facilitation | Meta Business Verification + Meta Verified for Business | Phase 2 |
| "Automatically identify order and lead events" (seen as an opt-in checkbox in the connect flow) | Meta's own event/insights layer on top of Cloud API | Worth a Phase 2 investigation — this may give us partial lead/order signal detection "for free" from Meta's side rather than building it ourselves |

## 5. Trial model — how ours should differ from Sabi's

Sabi's model, observed directly: full functionality for exactly **1 hour** after connecting, then a hard disconnect and a "Pay Now" wall — no graceful step-down, no continued limited use.

Per your instruction, ours should be more generous and less abrupt — see `PRD.md` §6/§10 for the updated trial mechanics (full-featured for the first 48 hours, then a capped/limited mode for the remainder of a 14-day window, then paused pending payment). The reasoning: a 1-hour cliff barely lets a non-technical owner finish testing before being asked to pay, which risks feeling like a bait-and-switch; a 48-hour taste followed by a softer, still-functional 14-day evaluation window gives an owner enough real usage to trust the product before the ask.

## 6. Reference material: buying numbers ourselves — revenue-gated, not needed now

Kept here for when it's actually relevant, not before — **this whole section is explicitly out of scope until there's revenue to fund it**, per §3a above.

**Provider comparison, if/when we revisit this:**

| Provider | What it's good for | Finding |
|---|---|---|
| Africa's Talking | USSD-heavy enterprise use cases | Enterprise-priced fee structure (e.g. ₦53,750/month for shared USSD maintenance alone) — weakest fit for a lean, cost-sensitive rollout |
| Termii / Sendchamp | Nigeria-native messaging APIs, both offer WhatsApp channels | Pricing sits behind quote/JS-gated calculators; worth a direct sales conversation — may bundle number + WhatsApp BSP access together |
| Twilio | Global CPaaS | Sells real Nigerian local numbers, business-only (not individuals), mostly voice-capable, gated behind NCC paperwork; global DID pricing ~$1–15/month, Nigeria rate not published |
| Dedicated DID/VoIP resellers (DIDHub, Telnyx, CallHippo) | Just the number | Cheapest concrete pricing found: Lagos/Abuja DIDs from **$3.50/month** (DIDHub) up to ~$25/month elsewhere; voice-capable is enough for WhatsApp's OTP step |

**NCC paperwork, explained (two separate regulatory layers, both distinct from Meta's own approval process):**

1. **SIM/number registration and NIN linkage.** Every Nigerian number must be traceable to a real accountable entity. For a company acquiring numbers in bulk, this means designating a **Primary Telecom Master** — a named executive personally tied to every number registered under the company — and submitting the CAC Certificate of Incorporation, a Tax Clearance Certificate, a signed authorization letter naming the Telecom Master(s) with their NIN, and (for a batch) a CSV of the numbers. This is a one-time, company-level setup, not a per-number or per-SME process, and it applies to us only once we're the one acquiring numbers on a business's behalf.
2. **Bulk/automated messaging licensing.** Separately, NCC charges a ₦10 million license fee for companies sending bulk international A2P SMS *directly*, plus a Sender ID registration process (CAC cert, NIN, sample messages, sign-off from all four networks, 2–3 weeks). The right move is to **not become this** — route through an already-licensed provider (Termii, Sendchamp, a proper CPaaS) so they hold the license and we're just their customer. This only becomes our problem if we ever send bulk SMS/voice directly to Nigerian networks ourselves.

Neither layer is a launch blocker today, because MVP1 doesn't acquire any numbers on anyone's behalf. Revisit this section once there's a business case (paying customers asking for a "give me a number too" option) to fund it properly — and confirm current requirements directly with NCC/the chosen provider before acting on this summary, since these rules are updated periodically.
