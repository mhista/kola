> **Not final, not legal advice.** Structured after reviewing a live competitor's published Privacy Policy (AppEdge's Sabi) for what a solid NDPR-compliant policy looks like in this exact product category, then adapted — not copied — to our own architecture (multi-channel, Errand database-credential access, multi-provider AI). Uses **"Kola"**, the confirmed final brand name. **Have a Nigerian lawyer review before publishing.**

# Kola Privacy Policy

Effective Date: [INSERT] · Last Updated: [INSERT]

This Privacy Policy explains how Kola ("we", "our", "us") collects, uses, stores, and protects personal data when you use our platform. We aim to comply with the Nigeria Data Protection Regulation (NDPR) 2019 and applicable data protection laws in any other jurisdiction we operate in.

## 1. Who We Are (Data Controller)

Business Name: [INSERT ENTITY NAME] · CAC Registration: [INSERT RC NUMBER] · Address: [INSERT] · Email: [INSERT]

We are the Data Controller for personal data collected through the Kola platform itself (your account, billing, usage). For data your customers send through your bot, see §4 — that relationship works differently.

## 2. Data We Collect

### 2.1 Data you provide directly
- **Account data:** name, email, profile photo (via OAuth or direct signup)
- **Business data:** business name, website URL (if provided for scraping), documents and text you upload to build your knowledge base, Errand configurations (including any database connection details or webhook URLs you provide)
- **Payment data:** subscription plan and billing history, payment references from Paystack/Flutterwave — we do not store your card details; these are handled entirely by our payment processors

### 2.2 Data collected automatically
- **Conversation data:** messages between your bot and your customers, delivery/read receipts, customer channel IDs (WhatsApp number or Business-Scoped ID, Telegram user ID), timestamps
- **Errand execution data:** inputs and results of Errand calls (redacted per the sensitivity you declare for that Errand), latency, success/failure, for debugging and abuse detection
- **Usage data:** feature usage, bot performance metrics, error logs and crash reports
- **Device data:** device type, OS, app version, push notification token

### 2.3 Data from third parties
- **From Meta/Facebook:** public profile info at login, your Meta Business Portfolio ID and WhatsApp Business Account ID, your WhatsApp phone number ID after connection
- **From Telegram:** your bot token and associated bot metadata
- **From your business website:** publicly available text content, used solely to build your knowledge base

## 3. How We Use Your Data

| Data | Purpose | Legal basis |
|---|---|---|
| Account data | Create/manage your account | Contract performance |
| Business data, knowledge base | Build and maintain your bot | Contract performance |
| Channel connection data | Connect and operate your bot on WhatsApp/Telegram | Contract performance |
| Errand credentials | Fulfil the specific capability you configured — never used beyond that Errand's declared scope | Contract performance |
| Conversation data | Deliver AI replies, analytics, human hand-off | Contract performance |
| Payment data | Process subscriptions, refunds | Contract performance |
| Usage data, error logs | Improve the product, fix bugs, detect abuse | Legitimate interest |

We do not use your data or your customers' data for advertising, profiling, or sale to third parties. We do not use conversation content to train AI models, and where our AI provider offers a no-training-on-API-data guarantee, we rely on it and disclose it here once a provider is finalized.

## 4. Your Customers' Data

When a customer messages your bot, they become a data subject whose personal data we process **on your instruction, not our own**:

- **You are the Data Controller** for your customers' data — you determine why their messages are processed.
- **We are the Data Processor** — we process customer messages only to deliver the service you've configured.

What we collect about your customers: their channel ID/phone number, message content, timestamps and delivery status. What we do not do: contact them directly outside your bot, share their data with other Kola workspaces, use their message content to train AI models, or sell their data.

**Your obligations:** you're responsible for having a lawful basis to process your customers' data via Kola, and we recommend disclosing to your customers that they're interacting with an AI assistant.

## 5. Errand Database and Webhook Credentials — Special Handling

Because Kola's Errand system can connect to a business's own database or webhook, this deserves explicit treatment beyond a typical SaaS privacy policy:

- Credentials you provide for a database- or webhook-backed Errand are **encrypted at rest** and used **solely** to execute the specific, pre-approved query or call shape configured for that Errand.
- We do not browse, export, or repurpose data reached through an Errand credential beyond fulfilling that Errand at the moment your bot calls it.
- You may revoke an Errand's access at any time from the dashboard; revocation takes effect immediately and the credential is deleted, not just disabled.
- If you grant read/write access, write actions are limited to the specific action you configured and confirmed — never open-ended.

## 6. Data Sharing and Third Parties

We share data with providers strictly to operate Kola: Meta (WhatsApp), Telegram, our AI model provider(s) (disclosed in-app; may include OpenAI, Anthropic, and/or Google depending on configuration), Supabase (database/auth), Paystack and Flutterwave (payments), and standard operational tooling (error monitoring, push notifications). We do not otherwise share your data except when required by law or valid court order, to protect someone's safety, or in connection with a merger/acquisition (with notice to you).

## 7. Data Storage and Security

- Data encrypted at rest (AES-256) and in transit (TLS 1.3)
- Access tokens and Errand credentials stored in an encrypted secrets manager, never in plaintext
- Row-Level Security enforced on all multi-tenant tables — no workspace can access another's data even in the event of an application bug
- **Nightly channel-credential health check:** we proactively validate stored WhatsApp/Telegram access tokens and notify you if one is invalid or expiring, so your bot doesn't silently go dark

## 8. Data Retention

Account data: retained until deletion + 30 days · Conversation messages: 90 days by default (configurable) · Knowledge base: until you delete/refresh it · Errand execution logs: retained for debugging/abuse detection per a defined window · Payment records: 7 years (Nigerian tax law) · Error logs: 30 days · Deleted account data: permanently deleted within 30 days.

## 9. Your Rights Under NDPR

You have the right to: access the personal data we hold about you; rectify inaccurate data; request erasure (honoured within 30 days except where retention is legally required); receive your data in a portable format; object to processing based on legitimate interest; withdraw consent where processing is consent-based; and lodge a complaint with Nigeria's National Information Technology Development Agency (NITDA). To exercise these rights, contact [INSERT EMAIL] — we aim to respond within 14 days.

## 10. Your Customers' Rights

Your customers also have data subject rights. As the Data Controller for their data (§4), you are responsible for handling their requests. If a customer contacts us directly, we will direct them to you.

## 11. International Data Transfers

Some providers (AI model providers, parts of our infrastructure) may be located outside Nigeria. Where we transfer data internationally, we use Standard Contractual Clauses or equivalent safeguards and process only the minimum data necessary.

## 12. Children's Privacy

Kola is intended for business owners and is not directed at persons under 18. We do not knowingly collect data from children; if you believe a child has provided us data, contact us and we will delete it.

## 13. Cookies and Tracking

We use only what's necessary to operate the service (session tokens, push notification tokens, error-reporting session IDs with no personally identifiable content) — no advertising trackers, analytics SDKs, or social media pixels.

## 14. AI and Automated Decision-Making

Our AI generates automated responses grounded in your knowledge base and configured Errands. It does not make decisions with legal or similarly significant effects on individuals; it cannot access anything outside what you've configured; and it's designed to escalate to a human when it can't confidently answer, though this can't be guaranteed in every case.

## 15. Changes to This Policy

We may update this policy; material changes are notified via email/in-app notice at least 14 days before taking effect.

## 16. Contact Us and Complaints

Email: [INSERT] · Address: [INSERT] · Response time: within 14 days.

To file a complaint with the supervisory authority: National Information Technology Development Agency (NITDA), Plot 28 Port Harcourt Crescent, Off Gimbiya Street, Garki, Abuja · nitda.gov.ng
