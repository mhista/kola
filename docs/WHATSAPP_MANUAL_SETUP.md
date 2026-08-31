# Connecting WhatsApp to Kola — Manual Setup

**Audience:** a business owner connecting their own WhatsApp number to their Kola bot, with no engineering help.
**Companion to:** `META_CONNECT_FLOW.md` (the automatic Embedded Signup path), `kola_server/lib/src/endpoints/channel_endpoint.dart` (`connectWhatsAppChannelManual`).
**Status:** primary connect path, not a fallback — see the note below on why.

---

## Why this exists, and why it's the main path (not a backup)

Kola can connect WhatsApp two ways: **automatically** via Meta's Embedded Signup (a one-click, Meta-hosted flow — see `META_CONNECT_FLOW.md`), or **manually**, where you go into your own Meta account, do a few one-time setup steps yourself, and paste three values into Kola. This document is the manual path.

Two honest reasons manual comes first, not as a last resort:

1. **Embedded Signup has a weekly usage cap** on Meta's side, shared across everyone using it through a given app. If that cap is hit in a busy week, automatic connect stops working for new businesses until it resets — manual connect doesn't share that cap, so it's always available as a way to get connected without waiting.
2. **A WhatsApp access token's validity is checked by Meta against the token's own permissions — not against which server sends the message.** A token you generate yourself, from your own small Meta App, works from Kola's servers exactly as it would from anywhere else. That means this path needs zero approval from Meta on Kola's side — nothing here is gated behind Kola's own App Review status, so it's never blocked by something outside your control.

If you'd rather use the one-click automatic flow and it's available, use that instead — this manual path exists so you're never stuck waiting on it.

---

## What you'll end up with

Five values, which you'll paste into Kola's "Connect WhatsApp" screen:

1. **Access Token** — a long string starting with letters/numbers, Meta's permission slip proving you can send messages from your number.
2. **Phone Number ID** — a numeric ID identifying your WhatsApp number inside Meta's system (not the phone number itself).
3. **WhatsApp Business Account ID (WABA ID)** — a numeric ID for the WhatsApp Business Account your number lives under.
4. **App ID** — a numeric ID identifying the Meta App you created in Step 1.
5. **App Secret** — a string from that same app's settings, used so Kola can verify that a message claiming to come from Meta actually did.

**Why Kola asks for App ID and App Secret, not just the three values Meta shows on the API Setup page by default:** those three are enough to *send* messages, but not enough to safely *receive* them. Every inbound message Meta delivers is signed with your App Secret — without it, Kola can't tell a real message from a forged one sent by someone who simply knows the webhook URL. App ID travels alongside it because Meta's dashboard always shows the two together, and Kola uses it to check whether a connected token is temporary or permanent (see Step 5's note) without asking you to look it up twice.

Kola encrypts and stores all five (AES-256-GCM, same protection used for Telegram bot tokens) and never displays them again in plain text once saved.

---

## Before you start

- A Facebook account (personal is fine — you'll create a separate Business app under it).
- A phone number you're willing to dedicate to WhatsApp API use. **Important:** once a number is registered this way, it can no longer be used in the regular WhatsApp or WhatsApp Business consumer app — this is a Meta rule, not a Kola one. Use a spare number or a cheap SIM, not your main line.
- About 15 minutes.

---

## Step 1 — Create a Meta App

1. Go to [developers.facebook.com](https://developers.facebook.com) and log in with your Facebook account.
2. Click **My Apps** (top right) → **Create App**.

   > *[Screenshot placeholder: My Apps page with "Create App" button highlighted]*

3. When asked what you want your app to do, choose **"Other"**, then **"Business"** as the app type.
4. Give it any name (e.g. "YourBusinessName Bot") and attach it to a Business Portfolio — Meta will offer to create one for you if you don't have one yet.

   > *[Screenshot placeholder: app creation form with name field and business portfolio dropdown]*

5. Click **Create App**. You'll land on your new app's dashboard.

---

## Step 2 — Add the WhatsApp product

1. On your app's dashboard, find the **"Add products to your app"** section and locate **WhatsApp**.

   > *[Screenshot placeholder: product list showing the WhatsApp card with a "Set up" button]*

2. Click **Set up**. Meta will walk you to the WhatsApp → Getting Started page inside your app.
3. If you don't already have a WhatsApp Business Account, Meta creates one for you automatically at this step, along with a **free test number** — useful for the next steps, but you'll add your real number in Step 3.

---

## Step 3 — Add and verify your real WhatsApp number

1. Still on the WhatsApp → Getting Started page, find **"Add phone number"**.

   > *[Screenshot placeholder: "Add phone number" button under the WhatsApp Business Account section]*

2. Enter the number you're dedicating to this bot, choose SMS or voice call for verification, and enter the code Meta sends you.
3. Give the number a **Display Name** — this is what customers see, and Meta reviews it for guideline compliance (must match your real business name, no all-caps, no promotional text). A mismatched display name is the single most common rejection here, so keep it plain and factual.

   > *[Screenshot placeholder: display name entry field with Meta's naming guidelines shown below it]*

4. Once verified, you'll land back on the WhatsApp dashboard with your number listed.

---

## Step 4 — Get your Phone Number ID and WABA ID

1. On the WhatsApp → **API Setup** page (left sidebar), you'll see a section called **"Send and receive messages."**

   > *[Screenshot placeholder: API Setup page showing "From" phone number dropdown with Phone number ID displayed beneath it]*

2. Your **Phone Number ID** is shown directly under the "From" number selector — a numeric string, not the phone number itself. Copy it.
3. Your **WhatsApp Business Account ID** is shown near the top of the same page, or under **WhatsApp Manager → Account Settings**. Copy it too.

Keep both somewhere temporarily — you'll paste them into Kola along with the access token in Step 6.

---

## Step 4a — Get your App ID and App Secret

1. In the left sidebar of your app's dashboard (not the WhatsApp section — the general app settings), click **App Settings → Basic**.

   > *[Screenshot placeholder: App Settings → Basic page showing App ID field and App Secret field with a "Show" button next to it]*

2. Your **App ID** is shown right at the top of this page. Copy it.
3. Your **App Secret** is next to it, hidden behind a **Show** button — you may be asked to re-enter your Facebook password to reveal it. Copy it once shown.

Keep these two alongside the Phone Number ID and WABA ID from Step 4 — all five values get pasted into Kola together in Step 6.

---

## Step 5 — Generate a permanent access token

The token Meta shows you by default on the API Setup page is **temporary — it expires in 24 hours.** For a bot that needs to keep working, you need a **permanent** token instead. This is the one step people most often get wrong, so follow it closely.

1. Go to **Business Settings** (from your Business Portfolio, not the app dashboard — [business.facebook.com/settings](https://business.facebook.com/settings)).
2. In the left sidebar, under **Users**, click **System Users**.

   > *[Screenshot placeholder: Business Settings sidebar with "System Users" highlighted under the Users section]*

3. Click **Add**, give it a name (e.g. "Kola Bot"), and set its role to **Admin**.
4. With your new System User selected, click **Add Assets**. Choose **Apps**, select the app you created in Step 1, and give it **Full Control**.
5. Still on the System User's page, click **Generate New Token**.

   > *[Screenshot placeholder: System User detail page with "Generate New Token" button]*

6. Select the app from Step 1, and under permissions check **`whatsapp_business_messaging`** and **`whatsapp_business_management`**.
7. Click **Generate Token**. Meta shows the token **exactly once** — copy it immediately and store it somewhere safe. If you lose it, you'll need to generate a new one (the old one keeps working until you revoke it, so there's no urgency to redo this if you already saved it correctly).

   > *[Screenshot placeholder: generated token dialog with the one-time "copy" warning visible]*

This is a **Standard Access** token, scoped only to assets your own System User controls — not the elevated "Advanced Access" tier that requires Meta's App Review. That's exactly what makes this path independent of Kola's own approval status (see the "Why this exists" note above).

**If you're only testing for now and connect with the default temporary token instead:** that's fine — Kola will still connect and will tell you (in the connection result) that it detected a temporary token and roughly when it expires, so you're not caught off guard. Just come back and follow this step properly, then reconnect with the permanent token, before that expiry hits.

---

## Step 6 — Connect it to Kola

1. In your Kola dashboard, go to **Integrations** and click the **WhatsApp** tile (Sell category). If you have more than one bot, you'll be asked which one this channel belongs to.
2. Paste in the five values you collected:
   - Access Token (Step 5, or the temporary one from Step 4a's page if you're just testing)
   - Phone Number ID (Step 4)
   - WhatsApp Business Account ID (Step 4)
   - App ID (Step 4a)
   - App Secret (Step 4a)
3. Kola verifies the token/phone number combination against Meta in real time before saving anything — if something's off (wrong token, mismatched IDs), you'll see a clear error immediately rather than a bot that silently never sends a message. It also checks whether your token is temporary or permanent and tells you either way.
4. Once verified, your channel shows as **Connected** and your bot goes **live** — no waiting, no server restart.

---

## Step 7 — Point Meta at your webhook URL

Connecting in Step 6 makes your bot able to *send* messages. To *receive* them, Meta needs to know where to deliver them — this step tells it.

1. Once connected, Kola gives you a **Callback URL** specific to your channel (it looks like `https://api.kola.app/webhooks/whatsapp/<a number>` — the number is unique to your bot, don't reuse someone else's).

   > *[Screenshot placeholder: Kola dashboard's Channels page showing the connected WhatsApp channel with its Callback URL displayed and a copy button]*

2. Back in your Meta App's dashboard, go to **WhatsApp → Configuration**, and find the **Webhooks** section.

   > *[Screenshot placeholder: WhatsApp Configuration page with the Webhooks card and "Edit" button visible]*

3. Paste your Callback URL from step 1 into the **Callback URL** field, and enter the **Verify Token** Kola gives you (a value you'll also see on the same Channels page) into the **Verify token** field.

   > *[Screenshot placeholder: Callback URL and Verify token fields filled in, with the "Verify and save" button highlighted]*

4. Click **Verify and save**. Meta sends one request to confirm the URL is real and the token matches — if it succeeds, the fields turn green; if not, double-check you copied both values exactly, with no extra spaces.
5. Still on this page, click **Manage** next to webhook fields and make sure **messages** is subscribed. This is the one field that actually delivers inbound WhatsApp messages to Kola — without it, your bot can send but will never receive.

   > *[Screenshot placeholder: webhook fields list with "messages" toggled on]*

**Honest gap, narrowed (2026-08-31):** Step 6 — connecting the channel itself — is now real and self-serve from the Integrations page (it wasn't before this date: the connect form existed but always failed with a "connected through its own flow, not here" error, a live bug now fixed). **Step 7 is still not self-serve.** Kola's dashboard has no screen displaying a channel's Callback URL or Verify Token yet, and the Verify Token itself is still a single value shared across the whole server (`WHATSAPP_WEBHOOK_VERIFY_TOKEN`), not a per-workspace one the way this walkthrough describes — so pasting a business's own invented phrase into Meta's Verify Token field would not actually match what Kola checks. Until both of those are built, Kola's team completes this step for you right after you finish Step 6. You won't need to do anything here yourself for now; this section documents what it'll look like once both pieces ship.

---

## Keeping it working

- **Don't revoke the System User's token** unless you're replacing it — revoking it disconnects your bot immediately.
- **If you ever see messages stop sending,** the most likely cause is an expired or revoked token. Regenerate one following Step 5 again and reconnect via Step 6 — your Phone Number ID and WABA ID don't change, only the token needs replacing.
- **Known gap, being honest about it:** Kola doesn't yet proactively check on a schedule whether a connected token has expired or been revoked — you'll find out the same way you'd notice any bot going quiet, by messages stopping. An automatic nightly check (so you get a heads-up instead of silence) is planned but not built yet; a temporary-token warning at connect time (Step 6) is what exists today.

---

## If you'd rather not deal with a spare number right now

Telegram is a genuinely free, zero-setup alternative — no phone number sacrificed, no Meta account needed, connected in under two minutes with a bot token from [@BotFather](https://t.me/BotFather). See your Kola dashboard's Channels page for that option. It's not a lesser choice — plenty of businesses run entirely on Telegram.
