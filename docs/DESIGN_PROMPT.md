# Design Generation Prompt
## For use with an HTML/CSS design-generation tool ("design labs")

Copy everything below the line into the design tool as a single brief. It assumes no prior context, so it restates brand, product, and every page needed for Phase 1. Written for the platform's confirmed final brand name, **Kola**.

---

## Brand & Tone

Design for **Kola**, a Bot-as-a-Service platform that lets any business — run by someone technical or not — describe what they want their WhatsApp/Telegram bot to do in plain language, and get a working, trained bot in minutes. The name "Kola" comes from the kola nut, a real, deeply-rooted West African symbol of welcome and hospitality — "bring the kola" is a literal, everyday welcoming ritual across Nigeria and much of West Africa. That gives the brand a warm, generous, host-like voice: closer to the sharp local friend who welcomes you in and gets things sorted, than to a sterile enterprise SaaS. It should feel credible to a solo vendor in Lagos launching their first bot *and* to a developer evaluating an API. Avoid: generic "AI startup" purple gradients, stock-photo diversity montages, and anything that reads as a template. Aim for: distinctive color, confident typography, a bit of personality in the copy and micro-illustrations, dark-mode-first for the working product (dashboard, docs), and a livelier, warmer light-mode-capable marketing site than typical B2B SaaS.

**Visual references to draw from (do not copy verbatim, use as a feel/structure reference):**

- The overall workspace shell of Claude's desktop app / Claude Code interface: a slim left sidebar (icon + label nav: Home, Projects/Workspaces, Activity, Templates), a "New chat"-style primary action at the top, and a warm, mostly-dark canvas with a centered greeting ("Hi there, [name]") and a large rounded input box as the primary call to action when nothing else is going on.
- CodeWords' landing page structure: a big serif/display headline over a dotted-grid background, a natural-language input box directly under the headline as the primary CTA ("Ask Kola to build a customer-care agent for..."), a strip of trusted-by logos, a numbered "how it works" section, an integrations row of channel/tool icons, and a pricing section with a monthly/yearly toggle and three tiered cards (Free / Pro / Business-style), most-popular tier visually emphasized with a colored border and a bonus-credit badge.
- CodeWords' in-app builder: a two-pane workspace — conversation transcript on the left, a live structured "Plan"/preview pane on the right showing what's being built as it's described, with a device-preview toggle (desktop/mobile icons) and a top bar with Plan/Code-style tabs, a Preview button, and Share/Publish actions on the right.

**Kola should feel like a fusion of these two patterns**, applied to our own object model (bots, Errands, Knowledge) instead of generic "agents" and "workflows," and re-skinned in Kola's own palette rather than the References' dark neutral/purple scheme.

## Mobile-First, Not Desktop-First

**This changes the priority order of everything below.** Most of the target users — a solo vendor managing their bot between customers — will use this product on a phone, not a laptop, confirmed directly by watching how AppEdge's Sabi (a real, working competitor) is built: it's a phone app, full stop, not a responsive website. Design every screen that a business owner actually lives in day-to-day — the onboarding wizard, the home dashboard, the conversations inbox, the Errand builder's non-dev entry point, billing/plan selection — **as a mobile screen first**, then adapt upward for desktop, not the other way around. The desktop/wide-screen treatment matters most for: the marketing landing page (often first seen on desktop via search/social), the developer-facing Structured/Dev Mode surface (a developer is far more likely to be at a laptop), and the public docs site. Everywhere else — assume one hand, one thumb, a mid-range Android phone, and a network that isn't always fast.

## Color, Type, Layout Direction

- **Palette:** move away from the generic indigo/violet AI-SaaS default. Suggest a warm, high-contrast pairing: a deep near-black background (`#0E0E10`–`#141416` range) for the app shell, with a single confident accent drawn from a warm terracotta/amber or a deep emerald — something that reads distinctly West-African-modern rather than Silicon-Valley-generic — used sparingly for primary actions, active states, and the logo mark. Neutral grays for text hierarchy; the accent should never be the majority color on a screen, only the "pay attention here" color.
- **Typography:** a confident serif or high-contrast display face for marketing headlines (echoing CodeWords' editorial serif headline treatment), paired with a clean, highly legible grotesque/sans for UI, body copy, and code. Generous size contrast between headline and body — the landing page headline should feel oversized and editorial, not a standard SaaS H1.
- **Layout:** on mobile (the primary target — see above), the dashboard is a single full-width column with a bottom tab bar (Home / Chats-Conversations / Settings, mirroring the proven 3-tab pattern confirmed in competitor testing) rather than a sidebar — a left rail only makes sense once we're at desktop width. On desktop/wide screens (marketing site, dev Structured Mode, docs site), use a fixed slim left rail (approx. 260–280px) with icon+label nav, collapsible to icon-only. Landing page is a classic long-scroll marketing page with generous vertical rhythm and a sticky top nav, designed mobile-first since a large share of traffic will arrive from a shared link on WhatsApp/Instagram on a phone.
- **Dark mode is the default and primary experience for the authenticated dashboard and docs site.** The marketing/landing site should work well in light mode (per the "livelier" brief) but may offer a dark hero if desired.

## Pages to Design

Design each of the following as a distinct, fully fleshed-out page/screen (not just a section), at desktop width primarily, with a note on how each adapts at mobile width where relevant.

### 1. Landing / Marketing Homepage

- Sticky top nav: logo, dropdown-style "Product" menu (mirroring the reference's dropdown pattern: e.g. "WhatsApp & Telegram bots," "Dashboard," "Templates," "Integrations"), "Resources," "Pricing," "Sign in," and a prominent "Start free" button.
- A thin announcement strip above the nav (dismissible), e.g. "Try Kola's WhatsApp customer-care bot free →".
- Hero: oversized editorial headline (something in the spirit of "Say it. Kola builds the bot." — write 2–3 real headline options), a one-line subhead explaining the value prop for a Nigerian SME owner specifically, and a large rounded natural-language input box as the primary CTA with placeholder text like "Describe the bot you want — e.g. 'Answer customer questions from my price list'" and a send arrow button, plus a mic/attach icon row underneath for parity with the reference.
- Below the hero: a row of quick-select pills / tag chips for common bot types (Customer care, Ecommerce/catalog, Order tracking, Complaints, Reminders) that pre-fill the input box.
- "Trusted by" or "Built for" logo strip — since this is a new product, frame it as industry chips instead of logos if no customers yet (e.g. "Fashion & beauty," "Food & logistics," "Services & agencies").
- "How it works" section: 3–4 numbered steps with small illustrations — Describe your business → Kola drafts your bot and Errands → Connect WhatsApp/Telegram → Go live — mirroring the reference's numbered "how it works" pattern but in our own product language.
- Integrations row: WhatsApp, Telegram, Paystack, Flutterwave, Facebook (marked "coming soon" if not live), Google Sheets/CSV upload, generic "your database" icon.
- "Built for WhatsApp & Telegram bots" feature section: a two-column layout — left column short copy blocks under three tabs (Conversational / Proactive / Notification, mirroring the reference's tab pattern) describing customer-care, sales/negotiation, and reminder/OTP use cases; right column a phone-mockup chat transcript illustrating the currently-selected tab's use case live.
- Dual-audience section ("Built for the whole team"): split panel — left half "No code needed" (owner describing a bot in chat, screenshot-style mock), right half "Built for developers" (an API key + code snippet mock) — this is the section that visually sells the Errand/dual-interface story from the PRD.
- Pricing section: monthly/yearly toggle, three cards (Free / Pro-equivalent "most popular" with a savings + bonus badge / Business-equivalent), priced in Naira with a small USD-equivalent note, feature checklists per tier consistent with PRD §10.
- FAQ accordion addressing Nigeria-specific concerns: "Do I need a developer?", "Can I use my own database?", "What happens after the 14-day trial?", "Does this work if my customers are on WhatsApp *and* Telegram?".
- Footer: sitemap columns (Resources, Product, Company, Legal), social icons, and a large closing wordmark treatment (mirroring the reference's oversized footer logo moment).

### 2. Sign up / Bot Mother Onboarding Wizard

Mobile-first, full-screen, no sidebar — this is the single highest-stakes flow in the product, and we now have a validated 4-step reference pattern from hands-on testing of a real competitor's app (`META_CONNECT_FLOW.md`), so follow its proven shape rather than inventing a new one:

- **Persistent chrome across all 4 steps:** a small step-name label top-left ("Business Profile," "Connect WhatsApp," "Plan," "Test Your Bot"), a pill badge top-right reading "Step X of 4," and a thin horizontal progress bar directly below reading e.g. "25% complete" — simple, and it visibly worked.
- **Step 1 — Business Profile:** "Let's start with the basics." A "Business or bot name" text field, then a **Knowledge Source** choice presented as two large selectable cards side by side — "Website URL — Auto-scrape your site" vs. "Manual text — Paste business info" — with the manual-text path revealing a large paste-area plus an "Upload Doc" button (supporting PDF/Word/Text, stated inline as a small caption). Primary CTA "Continue" as a full-width rounded button, disabled until required fields are filled.
- **Step 2 — Connect WhatsApp:** "Link your WhatsApp — connect your WhatsApp Business number to start automating your customer conversations." Before the connect button, an unmissable **disclosure card** (not a footnote, not a terms link) stating plainly: "Connecting a number here retires it from regular WhatsApp — permanently. Use a number you don't need for personal chats anymore, or a cheap spare SIM." Two clear paths below it, presented as equal, legitimate choices, not a primary-vs-fallback pair: **"I have a number ready" → Connect via Meta** (full-width button, Facebook glyph, hands off to Meta's own hosted Embedded Signup webview — we don't design the inside of that webview, it's Meta's UI, but add a lightweight "what to expect next" line above the button, e.g. "You'll log into Facebook and confirm a few permissions — takes about a minute," since that hand-off to an unfamiliar Meta-branded screen can otherwise feel like leaving the app) vs. **"I'd rather start with Telegram" → Set up Telegram instead** (no number needed, no Meta approval wait, live in minutes — routes to the equivalent Telegram bot-token step). On return from either path, show a success state confirming the connected number/display name or bot handle before advancing.
- **Step 3 — Plan:** trial framing front and center — "Try every feature free for 48 hours, then continue on a limited free plan until day 14" (per the revised trial model in `PRD.md` §10) — plan cards (Free / Pro-equivalent) with the same visual treatment as the pricing section on the landing page, and a clear, honest note about what happens at the 48-hour and 14-day marks so nothing feels like a surprise later.
- **Step 4 — Test Your Bot:** "100% complete." A prominent QR code centered on a card, "Send it a message!" heading, a line stating the connected number and inviting a scan or tap, and a full-width green "Open WhatsApp" button below it. Above the QR card, a countdown/status banner — ours should read something like "Full access for the next 48 hours" in a calm, positive tone (not competitor Sabi's abrupt orange "disconnects in 1 hour, Pay Now" framing) with a secondary "Upgrade anytime" link rather than a hard sell.

### 3. Dashboard Shell (authenticated home)

- Left sidebar: logo mark at top, a primary "New Bot" action, then icon+label nav: Home, Bots, Errands, Knowledge, Conversations, Integrations, API & Webhooks, Team, Billing. Below the nav, a "Recent" list — but repurposed from a generic chat history into a **recent activity list scoped to real objects**: recently edited bots, recently created Errands, recently uploaded knowledge docs — each row showing an icon for its type, not a generic chat bubble, since (per the brief) this is not a chatbot product even though it has chat-style interfaces within it. Bottom-of-sidebar account switcher (workspace name + plan badge + avatar).
- Main canvas default state: a centered greeting ("Evening, [owner name]" style), a large input box to talk to Bot Mother directly from home ("What do you want Kola to help with today?"), and beneath it a row of quick-action cards (Create a new Errand, Upload knowledge, Connect a channel, View this week's conversations).
- A persistent top-right toggle switching the whole workspace between **Chat mode** and **Structured mode** (see Kola's dual-interface concept) — visualize as a two-option pill switch, icons only (a speech-bubble icon vs. a table/grid icon).

### 4. Bot Detail — Chat Mode

- Two-pane layout mirroring the reference's builder: left pane is the live conversation with Bot Mother about *this specific bot* (transcript + input box at the bottom, with quick-suggestion chips like "Add an Errand," "Upload a price list," "Change the bot's tone"); right pane is a live-updating structured preview of the bot being described — its name, archetype, connected channels, and a running list of Errands with small status pills (Live / Draft / Needs your input), plus a device-preview toggle (desktop/mobile icon pair) showing a simulated WhatsApp or Telegram chat with this bot. Top bar: bot name + archetype badge, tabs for Plan/Preview equivalent to the reference, a "Publish" primary button top-right, secondary "Share" and history/undo icons.

### 5. Bot Detail — Structured/Dev Mode

- Same object, restyled for a developer: a tabbed page (Overview, Errands, Knowledge, Channels, Logs, API) with a dense, table-first layout. The Errands tab shows a sortable table (Name, Trigger description, Source: Built-in/Webhook/Database/MCP, Status, Last called) with a slide-over detail panel per Errand showing its raw input schema (JSON-schema style code block), fulfillment configuration, and permission scope — clearly a "for developers" visual register (monospace accents, code blocks, copyable IDs) versus Chat Mode's conversational warmth.

### 6. Errand Builder (modal or full page, used from either mode)

- Non-dev entry point: a chat-style single input, "Tell Kola what you want this Errand to do," with the AI proposing a structured draft below as it's described (name, trigger description, required inputs, and — if the Errand needs external data — a plain-language prompt asking where that data lives, with big friendly options: "I have a database," "I have a spreadsheet/document," "I have a developer who can help," each branching to the right next step).
- Dev entry point on the same screen (a toggle or tab within the same modal): a form/schema editor — name, description (used by the AI to decide when to call it), JSON-schema input editor, fulfillment type selector (Built-in / Webhook URL / Database credential / MCP endpoint — MCP marked "coming soon"), and a "Test this Errand" button that shows a sample call/response.

### 7. Knowledge Base Page

- A document library grid/list (cards showing file type icon, name, upload date, parse status: Processing/Ready/Needs attention), an upload dropzone at the top supporting PDF/DOCX/TXT/CSV/XLSX, and a detail view per document showing extracted chunks/preview so an owner can sanity-check what the bot learned.

### 8. Conversations / Inbox

- A two-pane inbox: conversation list on the left (customer name/number, channel icon, last message preview, unread indicator, a small tag for "Bot handled" vs. "Escalated to you"), transcript on the right with the ability to jump in and reply as a human, and a right-hand context rail showing which Errands fired during this conversation and any negotiated outcome (for catalog bots).

### 9. Integrations / Channels Page

- Cards for WhatsApp and Telegram (connect/connected states, with the pairing-code style connect flow from onboarding re-accessible here), a Paystack/Flutterwave card marked "Coming soon — payment infrastructure is ready, launching in a future update," and a Facebook Catalog card marked "Coming soon."

### 10. API & Webhooks (developer settings)

- API key management (create/revoke, scopes, last-used), webhook endpoint configuration for outbound events (new conversation, Errand executed, bot published), and a prominent link out to the public documentation site (Page 12).

### 11. Billing & Plans

- Current plan card with trial countdown if in trial, usage bars (messages this month, Errand calls, documents), the same three-tier pricing cards as the landing page but in an authenticated "manage/upgrade" context, and Naira-first pricing with invoices list.

### 12. Public Developer Documentation Site (Jaspr, SSR)

- A classic docs layout: left nav tree (Quickstart, Authentication, Errands, Webhooks, Channels, Rate limits & plans, SDKs), center content column with code blocks (Dart/cURL/JS tabs), right-hand "on this page" anchor nav. Top bar shares the same nav/brand chrome as the marketing site for continuity, plus a version switcher and a search box.
- Add a dedicated non-developer page under "Channels" — **"Connect your WhatsApp"** — a plain-language, numbered, screenshot-by-screenshot walkthrough of the Step 2 Embedded Signup flow from the onboarding wizard (see `META_CONNECT_FLOW.md` for the exact step sequence to illustrate: Facebook login → permission review → opt-in scope → business asset selection → phone number choice → business verification wait → display name entry). Real screenshots of our own flow to be supplied once available; placeholder callout boxes until then.

## Deliverable Format

Produce clean, semantic HTML/CSS (component-based where the tool supports it) for each page above, using a shared design-token set (colors, spacing scale, type scale) defined once and reused across every page so the marketing site, dashboard, and docs site feel like one product. Prioritize the Landing Page, the Dashboard Shell, Bot Detail — Chat Mode, and the Errand Builder first — these four best demonstrate the product's core differentiation (natural-language creation + dev/non-dev duality over one Errand registry) and should be the ones evaluated first before the remaining pages are built out.
