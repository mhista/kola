# Landing Page Update Prompt — Add a Waitlist

**This is an update, not a redesign.** The landing page structure and visual direction are already specified in `DESIGN_PROMPT.md` §"1. Landing / Marketing Homepage" — paste that alongside this prompt (or reference it directly if your design tool retains context) and apply the following additions/changes on top of what's already there. Reason this exists: there's no live product yet and no waitlist today, and pre-launch traction is exactly what the pitch deck's "What We've Built" slide (`DECK_DESIGN_PROMPT.md` §Slide 12) is currently missing — a working waitlist gives that slide something real to point to.

## What Changes on the Existing Landing Page

### 1. Hero CTA — reframe from "try it now" to "join the waitlist"
The hero's natural-language input box ("Describe the bot you want...") was specified assuming a live product. Pre-launch, keep the same visual treatment (large rounded input, same placeholder-style prompt copy) but change its function and the button beside it:

- Placeholder text shifts to something like: *"Tell us what your business needs — we'll notify you the moment it's ready"* rather than implying an immediate live build.
- The send-arrow button becomes a two-field capture: **email (required) + WhatsApp or phone number (optional)** — phone number matters here specifically because the product is WhatsApp/Telegram-first, so capturing it now means the waitlist can later be contacted on the exact channel the product operates on, not just email.
- On submit, replace the input box in place with a short confirmation state (checkmark icon, "You're on the list — we'll message you as soon as it's your turn," no page reload/redirect) rather than navigating away from the landing page.

### 2. Add a dedicated waitlist section (new, insert after the "How it works" section)
A focused, standalone section — not just relying on the hero — since some visitors scroll past the hero without noticing the CTA:

- Short headline or reframed value prop pitch, e.g. *"Be first in line."* One line beneath it explaining why joining now matters (e.g. early access, founding-member pricing, or first access to the free trial once live — pick whichever incentive is actually true and decided, don't invent a specific perk that isn't real yet).
- A simple form: name (optional), email (required), business type (optional dropdown — Customer care / Ecommerce & catalog / Other — this data is genuinely useful later for prioritizing which bot archetype to polish first).
- A small, honest counter if and only if real signups exist ("Join 000+ businesses already on the list") — do not fabricate a starting number; either show a real count once there are signups, or omit the counter entirely until then.

### 3. Update the pricing section framing
The existing pricing cards (Free/Pro/Business per `DESIGN_PROMPT.md`) should get a small "Launching soon — join the waitlist to lock in this pricing" ribbon/badge rather than active "Start free" buttons, since there's nothing to sign up for live yet. This avoids a dead-end click where a visitor taps "Start free" and hits nothing.

### 4. Footer / closing section
Add a lightweight, secondary waitlist reminder near the footer for anyone who scrolled the whole page without converting — a single-line email input is enough here, doesn't need the full form from §2.

## What Does Not Change

Everything else specified in `DESIGN_PROMPT.md` — brand palette, typography, the "how it works" section, the integrations row, the dual-audience (no-code vs. developer) section, and the FAQ — stays exactly as designed. This is additive, not a rebuild.

## Data This Needs to Capture (for whoever builds the actual form)

At minimum: email. Ideally also: phone/WhatsApp number, and business-type selection. This data is what turns the pitch deck's traction slide from "nothing yet" into a real, citable number the moment the first signups come in — worth wiring up analytics/storage for this properly rather than treating it as a throwaway form.
