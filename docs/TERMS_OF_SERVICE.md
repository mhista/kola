> **Not final, not legal advice.** This is a working first draft, structured after reviewing a live competitor's published Terms of Service (AppEdge's Sabi) and adapted to our own architecture (multi-channel, Errands, developer API, database-credential access). It uses **"Kola"**, the confirmed final brand name, throughout. **Have a Nigerian lawyer review this before publishing** — NDPR data-controller/processor obligations, Meta's platform terms, and Paystack/Flutterwave's own merchant requirements all impose specific, real obligations that need proper legal sign-off, not a best-effort draft.

# Kola Terms of Service

Effective Date: [INSERT] · Last Updated: [INSERT]

These Terms of Service ("Terms") govern your access to and use of Kola ("we", "our", or "us"), a platform that enables small and medium businesses, startups, and agencies to build and deploy AI-powered WhatsApp and Telegram assistants, with optional developer/API access for custom integrations. By creating an account, connecting a channel, or using Kola in any way, you agree to be bound by these Terms. If you do not agree, do not use the service.

## 1. Who We Are

Kola is operated by [ENTITY NAME], a business registered in Nigeria under the Corporate Affairs Commission (CAC), RC [INSERT RC NUMBER]. Registered address: [INSERT — Lagos, Nigeria]. Contact: [INSERT SUPPORT EMAIL].

## 2. Eligibility

To use Kola you must:

- Be at least 18 years old, or the age of legal majority in your jurisdiction if higher
- Be authorised to act on behalf of the business you are registering
- Have a valid Facebook account if connecting WhatsApp, and/or a Telegram account if connecting Telegram
- Have a dedicated phone number available for use as a WhatsApp Business number, if connecting WhatsApp (see §4 — connecting a number permanently removes it from the consumer WhatsApp app)
- Agree to and comply with Meta's WhatsApp Business Terms of Service and Acceptable Use Policy, and/or Telegram's Terms of Service, as applicable to the channels you connect
- Agree to and comply with these Terms

By creating a workspace, you represent that you meet all of the above.

## 3. What Kola Does

Kola is a software platform that:

- Builds a knowledge base for your bot from documents you upload (PDF, Word, plain text, spreadsheets) or a website you point us at
- Connects your WhatsApp and/or Telegram account(s) to an AI assistant
- Automatically responds to customer messages on your behalf using AI, grounded in the knowledge and capabilities ("Errands") you've configured
- Allows you to register custom Errands — capabilities that call your own webhook, database, or (in supported tiers) MCP endpoint — either by describing them in plain language or, if you're a developer, via our API
- Allows you to monitor conversations, take over manually, and manage your bot from the dashboard or your phone
- For developers: provides API keys, webhooks, and documentation to build and manage bots and Errands programmatically

Kola acts as a technology intermediary. We do not conduct business on your behalf, make commitments to your customers, or take responsibility for the content of conversations between your bot and your customers, or for the accuracy of results returned by Errands connected to systems you control.

## 4. Account Registration & Channel Connection

You may register using email/password or via Facebook/Google OAuth. Connecting a channel authorises Kola to:

- **WhatsApp:** access your public Facebook profile (name, email, profile photo) as needed for the connection flow; create or link a Meta Business Portfolio and WhatsApp Business Account (WABA) on your behalf during onboarding; register and verify your phone number on the WhatsApp Business Platform; generate and store an access token to send and receive messages on your behalf. **Connecting a phone number to Kola permanently removes it from the consumer WhatsApp/WhatsApp Business app** — this cannot be undone.
- **Telegram:** create and manage a Telegram bot under a token you provide or that we help you generate via Telegram's BotFather; send and receive messages on your behalf via that bot.

You are responsible for the security of the underlying Facebook/Telegram accounts used to connect a channel. Any action taken through your Kola account is your responsibility.

## 5. Errands and Third-Party System Access

Errands are the core extensibility feature of Kola. Specific terms apply because some Errands connect to systems you own:

- **Built-in and webhook-based Errands** call our own logic or an endpoint you control; we send the inputs you've configured and process the response solely to serve your bot.
- **Database-credential Errands:** if you provide database connection details so your bot can look up information (e.g. order status), you authorise us to execute only the specific, pre-approved query shapes configured for that Errand — never open-ended access — and you represent that you are authorised to grant this access. Credentials are encrypted at rest and used solely to fulfil the Errand you configured. You may revoke access at any time from the dashboard, which disables the Errand immediately.
- **Developer-registered Errands** (via API key) are subject to the same tenant-scoping and logging as dashboard-created ones — there is no privileged "developer bypass" of these protections.
- You are solely responsible for the accuracy, legality, and safety of any Errand you configure, and for any consequence of your bot calling a system you've connected.

## 6. AI-Generated Content

Kola uses one or more third-party AI model providers (disclosed in-app and in our Privacy Policy; the specific provider may change over time) to generate automated responses. You acknowledge that:

- AI-generated responses are grounded in the knowledge base and Errands you configure, but Kola makes no guarantee they are accurate, complete, or appropriate for every inquiry
- You are solely responsible for the accuracy of information you provide to build your knowledge base and configure your Errands
- You are solely responsible for all messages sent from your connected channels, whether AI-generated or sent manually by you or your staff
- Kola is designed to escalate to a human when it cannot confidently answer — but this cannot be guaranteed in every circumstance
- You should regularly review your bot's conversations and update your knowledge base and Errands accordingly

Kola is not liable for any loss, damage, or harm arising from AI-generated responses sent to your customers.

## 7. Subscription, Trial, and Payment

- **Trial:** new workspaces receive full-tier feature access for the first 48 hours, followed by a capped free-tier feature set for the remainder of a 14-day trial period, after which the workspace is paused pending a paid plan. Trial data is retained, not deleted, when a workspace is paused.
- **Plans:** Kola is offered on multiple paid plans; pricing is displayed in the app and on our website and may change with at least 30 days' notice before taking effect for existing subscribers.
- **Payment:** processed via Paystack and/or Flutterwave. By subscribing you authorise recurring charges on a monthly or annual basis via your chosen payment method.
- **Meta/Telegram platform fees:** Meta charges conversation fees for certain WhatsApp message types. These are passed through to you at cost, with no markup from Kola. You are responsible for understanding and managing your own conversation costs; usage and estimated fees are shown in your dashboard. Telegram does not currently charge platform fees for bot messaging.
- **Refunds:** you may request a full refund within 7 days of your first payment; requests after 7 days are reviewed case-by-case. Contact [INSERT SUPPORT EMAIL].
- **Cancellation:** cancel anytime from Settings; takes effect at the end of the current billing period. No partial refunds for unused time within a period.

## 8. Acceptable Use

You agree not to use Kola to:

- Violate any applicable law, including Nigeria's Cybercrimes Act and NDPR
- Send spam, unsolicited messages, or bulk broadcast messages except through features we explicitly provide for that purpose and in compliance with the relevant channel's policies (e.g. WhatsApp template/opt-in rules)
- Promote illegal goods or services, adult content, weapons, gambling, or financial scams
- Deceive, mislead, or defraud your customers
- Connect a phone number, Telegram bot token, or database you are not authorised to use
- Infringe on any third party's intellectual property rights, harass or harm any person, impersonate any person or entity, or distribute malware
- Reverse engineer, decompile, resell, or sublicense Kola without our written permission
- Use Kola to build a competing product

We reserve the right to suspend or terminate any account that violates these Terms, and Meta/Telegram may independently suspend your connected channel for violating their own policies — Kola is not responsible for such platform-level suspensions.

## 9. Intellectual Property

**Our property:** the Kola platform, code, design, branding, and AI orchestration systems belong to us. You receive a limited, non-exclusive, non-transferable licence to use Kola for its intended purpose during your subscription.

**Your property:** your business content, knowledge base, Errand configurations, and conversation data remain yours. You grant us a limited licence to process, store, and use this content solely to provide the service.

**Feedback:** if you give us feedback or suggestions, we may use them without restriction or compensation.

## 10. Third-Party Services

Kola integrates with third-party services including Meta (WhatsApp), Telegram, one or more AI model providers, Supabase, Paystack, and Flutterwave. Your use of these services through Kola is subject to their own terms and privacy policies; we are not responsible for their actions, availability, or data practices.

## 11. Limitation of Liability

To the maximum extent permitted by law: Kola is provided "as is," without warranty of uninterrupted or error-free operation; we are not liable for indirect, incidental, or consequential damages, or for loss of data, revenue, or business opportunities; our total liability for any claim shall not exceed the amount you paid us in the 3 months preceding the claim. Nothing here excludes liability for fraud, death, or personal injury caused by our negligence where such exclusion is prohibited under Nigerian law.

## 12. Indemnification

You agree to indemnify Kola, its founders, employees, and agents against claims arising from your use or misuse of Kola, your violation of these Terms or any third-party policy (including WhatsApp/Telegram policies), any Errand or system you connect, or any dispute between you and your customers.

## 13. Termination

You may delete your workspace at any time from Settings; data is scheduled for permanent deletion within 30 days. We may suspend or terminate your account for policy violations, legal/regulatory requirement, failed payment unresolved within 7 days, or a reasonable belief of security/legal risk. Data is retained for 30 days post-termination in case of dispute, then permanently deleted.

## 14. Governing Law and Disputes

These Terms are governed by the laws of the Federal Republic of Nigeria. Disputes shall first be attempted to be resolved through direct negotiation; if unresolved within 30 days, submitted to the Lagos Multi-Door Courthouse (LMDC) for mediation before litigation.

## 15. Changes to These Terms

We may update these Terms; material changes are notified via email/in-app notice at least 14 days before taking effect. Continued use after that constitutes acceptance.

## 16. Contact Us

Email: [INSERT] · Address: [INSERT] · CAC Registration: [INSERT RC NUMBER]
